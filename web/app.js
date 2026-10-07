import { AnalysisRunner } from './runner.js';
import { examples } from './examples.js';

const $ = id => document.getElementById(id);
const sides = ['options', 'old', 'new'];
const files = Object.fromEntries(sides.map(side => [side, { token: 0, pending: false, error: null }]));
const pageSize = 100;
let rawReport = null;
let report = null;
let pageNumber = 0;
let requestedOptions = '{}';

function node(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text !== undefined) element.textContent = text;
  return element;
}
function location(path) {
  if (path === null) return '<不存在>';
  return path === '' ? '""（根）' : path;
}
function status(state, text) {
  $('status').dataset.state = state;
  $('status').textContent = text;
}
function updateActions(running = false) {
  $('compare').disabled = sides.some(side => files[side].pending);
  $('compare').textContent = running ? '重新比较' : '比较 JSON';
  $('cancel').disabled = !running;
}
function clearReport() {
  rawReport = null;
  report = null;
  $('download').disabled = true;
  $('results').hidden = true;
  $('changes').replaceChildren();
}
function showError(code, message) {
  $('error-title').textContent = code;
  $('error-detail').textContent = message;
  $('error-panel').hidden = false;
}
function hideError() { $('error-panel').hidden = true; }
function drawChanges() {
  const kind = $('filter-kind').value;
  const changes = report.changes.filter(change => kind === 'all' || change.kind === kind);
  const pages = Math.max(1, Math.ceil(changes.length / pageSize));
  pageNumber = Math.min(pageNumber, pages - 1);
  const start = pageNumber * pageSize;
  const fragment = document.createDocumentFragment();
  for (const change of changes.slice(start, start + pageSize)) {
    const item = node('li', `change change--${change.kind}`);
    const heading = node('div', 'change-heading');
    heading.append(node('span', 'kind', change.kind));
    if (change.identity) {
      const id = change.identity;
      heading.append(node('p', 'identity', `身份 ${id.key} = ${id.value_json} · OLD ${location(id.array_old_path)} · NEW ${location(id.array_new_path)}`));
    }
    const values = node('div', 'change-values');
    for (const [label, path, slot] of [['OLD · BEFORE', change.old_path, change.before], ['NEW · AFTER', change.new_path, change.after]]) {
      const column = node('div', 'slot');
      column.append(node('div', 'slot-label', label), node('div', 'path', location(path)),
        // json_text is already faithful MoonBit output. Never parse the fragment.
        node('pre', slot.present ? 'value' : 'value absent', slot.present ? slot.json_text : '<absent>'));
      values.append(column);
    }
    item.append(heading, values);
    fragment.append(item);
  }
  $('changes').replaceChildren(fragment);
  $('visible-count').textContent = changes.length === 0 ? '显示 0 条' : `显示 ${start + 1}–${Math.min(start + pageSize, changes.length)} / 共 ${changes.length} 条`;
  $('empty-result').hidden = changes.length !== 0;
  $('empty-result').textContent = report.equal ? '指定策略下相等，没有变化。' : '没有符合筛选条件的变化。';
  $('pagination').hidden = pages <= 1;
  $('previous').disabled = pageNumber === 0;
  $('next').disabled = pageNumber + 1 === pages;
  $('page-label').textContent = `${pageNumber + 1} / ${pages}`;
}
function receiveReport(text) {
  try {
    // Only the returned envelope is parsed in JS, never documents or options.
    const envelope = JSON.parse(text);
    if (envelope.schema_version !== '1.0' || typeof envelope.ok !== 'boolean') throw new Error('报告协议无效');
    if (envelope.ok && (!Array.isArray(envelope.changes) || !envelope.summary)) throw new Error('报告字段缺失');
    rawReport = text;
    report = envelope;
    $('results').hidden = false;
    $('download').disabled = false;
    document.querySelector('.summary').hidden = !report.ok;
    document.querySelector('.applied').hidden = !report.ok;
    document.querySelector('.filter-row').hidden = !report.ok;
    $('ignored-note').hidden = !report.ok;
    $('applied-options').textContent = requestedOptions;
    if (!report.ok) {
      const e = report.error;
      showError(e.code, `${e.message}\n侧别: ${e.side ?? '—'}\n路径: ${e.path === null ? '—' : location(e.path)}\n位置: ${e.line === null ? '—' : `行 ${e.line}，列 ${e.column}`}`);
      status('error', '输入或配置有误，比较未完成。');
      $('result-title').textContent = '错误报告';
      $('changes').replaceChildren();
      $('empty-result').hidden = true;
      $('pagination').hidden = true;
      return;
    }
    hideError();
    status('done', report.equal ? '指定策略下相等。' : '比较完成，有结构变化。');
    $('result-title').textContent = report.equal ? '指定策略下相等' : '结构发生变化';
    for (const kind of ['added', 'removed', 'modified', 'reordered']) $('count-' + kind).textContent = String(report.summary[kind]);
    $('ignored-note').textContent = `实际忽略 ${report.summary.ignored_subtrees} 个子树；筛选只影响显示，下载包含完整报告。`;
    $('filter-kind').value = 'all';
    pageNumber = 0;
    drawChanges();
  } catch (error) {
    runner.fail('WORKER_ERROR', `无法读取核心报告：${error.message}`);
  }
}
const runner = new AnalysisRunner({
  onReady: ready => {
    $('engine').dataset.ready = String(ready);
    $('engine').textContent = ready ? '核心就绪' : '等待核心';
  },
  onReport: receiveReport,
  onState: state => {
    updateActions(state.status === 'running');
    if (state.status === 'running') { hideError(); status('busy', '正在比较，可取消或开始新的比较…'); }
    if (state.status === 'cancelled') { clearReport(); hideError(); status('cancelled', '已取消，可再次比较。'); }
    if (state.status === 'error') { clearReport(); showError(state.code, state.message); status('error', '比较中止，可再次比较。'); }
  },
});

function invalidate(message = '输入已修改，请重新比较。') {
  runner.cancel();
  clearReport();
  hideError();
  status('dirty', message);
  updateActions();
}
function firstFileError() { return sides.map(side => files[side].error).find(Boolean); }
function compare() {
  if (sides.some(side => files[side].pending)) return;
  clearReport();
  hideError();
  requestedOptions = $('options-text').value;
  const error = firstFileError();
  runner.start(error ? { type: 'client_error', ...error } : {
    type: 'analyze', old_text: $('old-text').value, new_text: $('new-text').value,
    options_text: requestedOptions,
  });
}
for (const side of sides) {
  $('' + side + '-text').addEventListener('input', () => {
    files[side].token++;
    files[side].pending = false;
    files[side].error = null;
    $(side + '-file-note').textContent = '已编辑文本 · 原始文本';
    $(side + '-file-note').dataset.error = 'false';
    invalidate();
  });
  $(side + '-file').addEventListener('change', async event => {
    const file = event.target.files[0];
    if (!file) return;
    event.target.value = '';
    const token = ++files[side].token;
    files[side].pending = true;
    files[side].error = null;
    $(side + '-file-note').textContent = `正在读取 ${file.name}…`;
    $(side + '-file-note').dataset.error = 'false';
    invalidate('正在读取文件，请稍候。');
    let text, error;
    try {
      const bytes = await file.arrayBuffer();
      try { text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(bytes); }
      catch { error = { code: 'ENCODING_ERROR', message: `Invalid UTF-8 in ${JSON.stringify(file.name)}`, side }; }
    } catch {
      error = { code: 'IO_ERROR', message: `Cannot read ${JSON.stringify(file.name)}`, side };
    }
    // A newer file, example or text edit owns the field now.
    if (files[side].token !== token) return;
    files[side].pending = false;
    files[side].error = error ?? null;
    $(side + '-file-note').dataset.error = String(Boolean(error));
    $(side + '-file-note').textContent = error ? error.message : `${file.name} · UTF-8 原始文本`;
    if (!error) $(side + '-text').value = text;
    updateActions();
    if (!sides.some(name => files[name].pending)) {
      if (firstFileError()) compare();
      else status('dirty', '文件已载入，请比较。');
    }
  });
}
for (const button of document.querySelectorAll('[data-example]')) button.addEventListener('click', () => {
  const sample = examples[button.dataset.example];
  for (const side of sides) {
    files[side].token++;
    files[side].pending = false;
    files[side].error = null;
    $(side + '-text').value = sample[side];
    $(side + '-file-note').textContent = '演示输入 · 原始文本';
    $(side + '-file-note').dataset.error = 'false';
  }
  invalidate('示例已载入，请比较。');
});
$('compare').addEventListener('click', compare);
$('cancel').addEventListener('click', () => runner.cancel());
$('filter-kind').addEventListener('change', () => { pageNumber = 0; if (report?.ok) drawChanges(); });
$('previous').addEventListener('click', () => { pageNumber--; drawChanges(); });
$('next').addEventListener('click', () => { pageNumber++; drawChanges(); });
$('download').addEventListener('click', () => {
  if (rawReport === null) return;
  const url = URL.createObjectURL(new Blob([rawReport], { type: 'application/json;charset=utf-8' }));
  const link = node('a');
  link.href = url;
  link.download = 'moondiff-json-report.json';
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
window.addEventListener('pagehide', event => { if (event.persisted) runner.cancel(); else runner.close(); });
