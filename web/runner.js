export class AnalysisRunner {
  constructor({
    createWorker = () => new Worker(new URL('./worker.js', import.meta.url), { type: 'module' }),
    timeoutMs = 5000, onState, onReport, onReady = () => {},
  }) {
    Object.assign(this, { createWorker, timeoutMs, onState, onReport, onReady });
    this.worker = null;
    this.sequence = 0;
    this.pending = null;
    this.timer = null;
    this.closed = false;
    this.ensureWorker();
  }

  ensureWorker() {
    if (this.worker || this.closed) return;
    try {
      const worker = this.createWorker();
      this.worker = worker;
      this.onReady(false);
      worker.addEventListener('message', ({ data }) => {
        if (worker !== this.worker || this.closed) return;
        if (data?.type === 'ready') { this.onReady(true); return; }
        if (this.pending === null || data?.request_id !== this.pending) return;
        if (data.type === 'result' && typeof data.report_text === 'string') {
          const id = this.pending;
          this.finish();
          this.onState({ status: 'complete', request_id: id });
          this.onReport(data.report_text, id);
        } else {
          this.fail('WORKER_ERROR', data.message ?? 'Worker 返回了无效消息');
        }
      });
      worker.addEventListener('error', event => {
        if (worker !== this.worker || this.closed) return;
        event.preventDefault();
        this.fail('WORKER_ERROR', event.message || '无法载入或运行比较核心，请检查本地构建');
      });
      worker.addEventListener('messageerror', () => {
        if (worker === this.worker && !this.closed) this.fail('WORKER_ERROR', '无法接收 Worker 结果');
      });
    } catch (error) {
      this.fail('WORKER_ERROR', error.message);
    }
  }

  start(message) {
    if (this.closed) throw new Error('Comparison runner is closed');
    if (this.pending !== null) this.stopWorker();
    this.finish();
    const id = ++this.sequence;
    this.pending = id;
    this.onState({ status: 'running', request_id: id });
    this.ensureWorker();
    if (this.pending !== id || !this.worker) return id;
    this.timer = setTimeout(() => {
      if (this.pending === id) this.fail('WORKER_TIMEOUT', '比较超过 5 秒，已停止。可调整输入后再次比较。');
    }, this.timeoutMs);
    try { this.worker.postMessage({ ...message, request_id: id }); }
    catch (error) { this.fail('WORKER_ERROR', error.message); }
    return id;
  }

  finish() {
    clearTimeout(this.timer);
    this.timer = null;
    this.pending = null;
  }

  stopWorker() {
    this.worker?.terminate();
    this.worker = null;
    this.onReady(false);
  }

  fail(code, message) {
    const id = this.pending;
    this.finish();
    this.stopWorker();
    this.onState({ status: 'error', code, message, request_id: id });
  }

  cancel() {
    ++this.sequence;
    const running = this.pending !== null;
    this.finish();
    if (running) this.stopWorker();
    this.onState({ status: 'cancelled' });
  }

  close() {
    this.closed = true;
    ++this.sequence;
    this.finish();
    this.stopWorker();
  }
}
