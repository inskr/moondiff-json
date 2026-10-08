# Execution ledger — plan: F:/MOONBit/docs/plan.md

Scope: tasks 1–8 authorized by the user in sequence; local development, tests, materials and small commits only.

Task 1: complete.
Task 2: complete (base 30f08a6).
Task 3: complete (base 1802b89).
Task 4: complete (base 9cf462a).
Task 5: complete (base 2621e4d).
Task 6: complete (base df9d62a).
Task 7: complete (base b98131d).
Task 8: complete (base 217e924; first increment 9c0d4dd; final material/evidence commit follows).

Pre-flight interfaces:
- 1 → 2/5: parser must preserve raw number tokens, reject duplicate decoded keys and limit depth during parsing; verified API will determine adapter types.
- 1 → 6/7: stable dist module must export string functions usable in Node and browser module Worker; no guessed build filename.
- 2 → 3/4/5: shared Document, NumberKey, Pointer and error types must precede comparison and report implementation.
- 3/4 → 5: diff must preserve both paths, validate identities before whole-array additions, and honor deterministic ordering.
- 5 → 6/7/8: identical analyze report bytes feed both clients and acceptance; format_text remains MoonBit-owned.

Ruling: Work in the designated, previously empty project directory on a new local task branch. No existing implementation or user changes are replaced; no additional worktree is needed.
Ruling: The supplied spec and plan are approved. Do not repeat brainstorming approval or create a competing plan. Current-agent sequential execution overrides skill suggestions to delegate.

Task 8: complete (base 217e924). Unified npm acceptance passed at root and fresh source directory: 101 core, 49 CLI, 7 Worker lifecycle, 34 actual-page, 225 fixed-seed properties; 15 golden and 15 generated reports byte-equal across bridge/CLI/Worker. Nine benchmark cases each actually ran 5 warmups/20 measurements, with raw results retained: about 1 MiB per side, 10000 records, 10 fields changed; positional/keyed median 77.559/99.421 ms. Fresh snapshot 9c0d4dd rebuilt using only hash-checked cached tool download archives, no dependency/build outputs copied; core JS SHA256 identical. Actual re-recorded video verified at 150.92s, 1440x1080, seven decoded scenes and six exact golden downloads; keyed paths/precision/errors visually checked. CI with pinned tools/dependencies/browser revision/action SHAs prepared, not remotely executed. MIT/runtime license texts, ecosystem, AI-use, one-pager and demo materials complete. Current-agent inline review and final npm acceptance passed; no core precision/feature/report changes. Preserve all three user supplemental documents. Linux and remote CI untested; public push/deploy/package/tag/submission await explicit authorization. Evidence: docs/validation/task8-*.log, task8-review.md, bench/results.json, docs/demo/recording.json and playback-verification.json.
Ruling: Adapt Bash-only skill bookkeeping to the existing PowerShell environment and keep a tracked ledger here; do not install an extra shell for bookkeeping.

Initial environment: Node v24.19.0, npm 11.17.0, Git 2.50.1.windows.1; moon not found. Need project-local official toolchain and target Node 22.
Network: sandbox curl could not connect. Escalated read of official download page succeeded. An initially guessed obsolete installer URL returned HTTP 403; the actual download page specifies /install/powershell.ps1, now retrieved and inspected.

Task 1 decisions:
- Fixed moonc/core 0.10.14+7d59c7ec9, moon 0.1.20260920, Node 22.23.3, moonjson 0.4.0 and playwright-core 1.63.0. Version pins and hashes are in docs/environment.md and package-lock.json.
- Use the installed moonjson strict API with duplicates=Reject and root-zero parse-time depth. Raw numeric repr is preserved; never compare the Double payload or builtin Json equality in later tasks.
- Use a clearly named probe_document string export for task 1. Do not fabricate the future analyze/report implementation; task 5 owns that complete contract.
- Exact bridge output discovered: _build/js/release/build/src/bridge/bridge.js; a build script provides dist/moondiff-json.mjs to both Node and browser.
- Terminal and CUA initialization failed after Git initialization. Escalated commands were approved and worked; browser testing uses installed Chrome through Playwright, without extra browser downloads.
- Port 4173 failed because Windows reserves 4124–4223; use a system-selected localhost port. Chrome virtual-time dump-dom caused a probe timeout; real-clock browser verification passed.

RED observed: adapter 7 failed / 0 passed; Node bridge empty-string assertion failed. Saved under docs/validation.
GREEN observed: MoonBit 7 passed / 0 failed; Node 12 cases and deterministic repeat; real Chrome module Worker 12 outputs identical to Node bytes.
Review: current-agent inline scope check; no parallel reviewer per explicit execution constraint. No reduction in precision or core features and no change to final report semantics. Remaining resource limits and final reports are explicitly deferred to their planned tasks, not claimed complete.

Task 1: complete (base 531ff57; implementation commit includes this entry). Validation: scripts/setup-windows.ps1, pinned npm ci, scripts/verify-task1.ps1 → exit 0. Final check/test/build passed without compiler warnings; 7 MoonBit tests passed; 12 Node cases and 12 identical Chrome Worker outputs passed. Logs saved in docs/validation. No public push, deployment, package publication or submission.

Task 2 decisions:
- Keep shared error/side/limit types in model/base; input owns read-only exact NumberKey and controlled Document; model re-exports the public contract. This avoids circular dependencies without changing the report schema.
- Convert parsed Json into a Value tree that has no Double. Only parse_document constructs Document; root() copies mutable containers to protect the stored validated tree.
- Enforce input byte/node/depth and number limits at Document construction now, so it already fulfills its validation invariant; task 5 still owns options JSON and report/change-limit integration.
- Validate standalone raw numeric syntax, bound explicit exponent accumulation before overflow, and preserve the original token independently of the canonical key.
- Source inspection confirms builtin String comparison is not Unicode codepoint lexical ordering. Explicit codepoint sorting is required in tasks 3/5; do not reuse probe dumps(sort=true) for final reports.
- The constructor boundary probe initially expected an unqualified diagnostic type name; actual compiler rejection uses the fully qualified Document name. Corrected only the probe's match; the encapsulation already worked.

Task 2 RED: 7 new primitive cases failed (8 existing/negative cases passed); model phase 6 failed, 16 passed. Full logs will be retained in docs/validation.

Task 2 review: invalid Pointer text was being stored as error.path. Added a regression assertion, observed Some("x") != None, then changed this unknown location to None. A future options parser can attach a known valid configuration Pointer. No error envelope or comparison semantics changed.

Task 2: complete (base 30f08a6; implementation commit includes this entry). scripts/verify-task2.ps1 → exit 0: JS check with deny-warn, 22/22 MoonBit tests, compiler rejection of unchecked external Document construction, release build, 12 Node cases and identical 12 real Chrome Worker outputs. RED and final logs saved in docs/validation. Current-agent inline review completed; no parallel agents or public operations. Next: task 3 object/position comparison and ignore rules with explicit Unicode codepoint ordering.

Task 3 decisions:
- Implement codepoint ordering and faithful ValueSlot fragments in src/report now because whole-subtree changes need them. The final envelope/text renderer and analyze remain task 5; no report schema changes.
- Validate all ignore paths against both snapshots before applying a trie. Parent ignores cannot hide invalid child paths. Traverse only compared nodes: whole-subtree changes do not expand descendants merely to find nested ignore rules.
- Keep a temporary explicit INVALID_OPTIONS guard for any array_rules instead of silently falling back to positional matching; task 4 replaces it.
- Enforce max_changes during collection already. No partial report is returned on overflow; options JSON and comprehensive limit integration remain task 5.
- Store hand-derived cases and generate formatted executable tests using the actual moonfmt stdin API. JavaScript reads only test fixture metadata, not product input documents.

Task 3 RED: initial test wiring used unqualified re-exported constructors, then corrected to real base constructors. One draft fixture exceeded the explicit exponent limit; replaced by mathematically equal valid tokens. Runnable RED saved: 25 failed, 26 passed, 51 total. Minimal implementation GREEN: 51/51.

Task 3 review: current-agent inline review of scalar/whole-subtree branching, Unicode ordering, dual paths, snapshot immutability, complete ignore prevalidation and bounded collection. No subagents per sequential scope. No precision reduction, feature deletion or report-semantic change; no deferred review findings.

Task 3: complete (base 1802b89; implementation commit includes this entry). scripts/verify-task3.ps1 → exit 0: 15 saved fixtures match executable assertions, JS check with deny-warn, 51/51 MoonBit tests, external Document constructor rejection, release build, 12 Node parsing cases and identical 12 real Chrome module Worker outputs. Logs saved in docs/validation. Final report byte comparisons and performance benchmarks are not claimed. No public operations. Next: task 4 explicit unique-key arrays.

Task 4 decisions:
- Replace the temporary keyed-array guard with prevalidation and per-side Map indexes. Validate rule duplicates first; then targets and identities, including rules below whole added/removed ancestors.
- Preserve each original index and propagate the nearest identity through nested object/position-array changes. Common identity labels use the old-side raw token; added identities use the new-side raw token. Reorder sequences use each side's raw identity tokens; equality/sorting use exact canonical keys only.
- Fix the integer sort representation as N:<+ or ->:<digits>:<exponent>; strings use S:<decoded text>. Codepoint sorting is deterministic, not numeric magnitude ordering.
- Follow the specification's explicit overlap exception: an ignored array/ancestor skips keyed data checks, including target existence, but duplicate rule configuration is still rejected and Document input validation is never skipped. Task 5 validates JSON option syntax/types before input parsing.
- Keep whole-array additions/removals in the general branch after prevalidation, and use the shared bounded change collector for all four kinds.

Task 4 RED: 76 total, 25 failed and 51 passed, saved in docs/validation/task4-red.log. Cross-package Identity record construction required an explicit type annotation during compilation; no API or report semantic changes. GREEN: 76/76.

Task 4 review: current-agent inline review of exact typed keys, per-side duplicate rejection, old/new index propagation, common-order projection, absent/whole-array target checks, ignored overlaps, immutable snapshots and deterministic ordering. Index loops use Map operations; no all-pairs scan. No precision reduction or deleted core functionality. User's three untracked supplemental documents remain untouched and outside the implementation commit.

Task 4: complete (base 9cf462a; implementation commit includes this entry). scripts/verify-task4.ps1 → exit 0: 15 basic and 15 keyed saved fixtures verified, JS deny-warn check, 76/76 core tests, standalone 10000-identity reverse test 1/1 (568.1 ms command wall time including test runner, not formal benchmark), external Document construction rejection, JS release build, 12 Node parsing cases and 12 identical real Chrome Worker outputs. Versions/CPU/OS and RED/final logs retained. No public operations. Next: task 5 strict options, resource boundaries and final reports/analyze.

Task 5 decisions:
- Move reusable Pointer and codepoint order into model/base while preserving diff/report public facades, so model can parse options without circular dependencies. Parse options through controlled Document at default limits, then apply lower limits to old/new.
- Use NumberKey bounded integer conversion for limits and report counters; never use a float or an overflowing parse to decide valid integral values. Strictly reject unknown fields, bad types, missing rule properties, malformed/root ignores and duplicate decoded rule paths.
- Render fixed success/error JSON envelopes and text in MoonBit. Text report decoding validates counts, paths, slot consistency and JSON fragments. Document byte/node limits do not incorrectly constrain report envelope metadata; 10000-change reports remain readable.
- Ruling: The actual JS backend exposes raising exports as internal result objects. Keep report.format_text raising DiffError internally, but bridge catches expected failures and uses an exception-only JS FFI carrying MoonBit error report bytes. Actual Node success-string and exception assertions confirm the external protocol. Cost if the backend changes: replace a small transport adapter; comparison/report semantics are unchanged.
- Ruling: Actual compilation rejects #export_name on optional-argument functions. Keep the three-string MoonBit analyze export and add a tiny JS facade supplying {} only when options is omitted. Build copies discovered compiler output to moondiff-json-core.mjs and the facade to the stable moondiff-json.mjs; Node and Worker share both. Cost: two distribution files instead of one; downstream packaging must include both. No schema/precision/core-feature adjustment.

Task 5 RED: 96 total, 20 failed/76 passed. Actual dependency-signature compile error was corrected to the already verified parse_input adapter, without claiming compilation success prematurely. Review regression: invalid embedded json_text accepted by formatter; watched 1 failed/97 passed, then validated fragments and restored 98/98. External JS RED first showed missing new exports in the old artifact, then the actual raising-result mismatch, then omitted-options failure. Genuine logs retained under docs/validation/task5-*.log.

Task 5 review: current-agent inline pass over option/input validation precedence, exact bounded conversion, snapshot/ignore behavior, deterministic field order, null versus absent, root paths, error-only envelopes and actual JS exception/default transport. No subagents or public operations; user supplemental documents remain untouched. No pending review findings or feature/precision reduction.

Task 5: complete (base 2621e4d; implementation commit includes this entry). scripts/verify-task5.ps1 → exit 0: 15 basic + 15 keyed + 7 full-report fixtures verified, 98/98 tests, JS deny-warn check and release build, controlled Document boundary rejection, legacy 12 Node/Worker parsing cases, 15 complete Node/real Chrome Worker reports and text outputs byte-identical. Default/downward bytes/nodes/depth/number/change boundaries truly exercised, including 10000 versus 10001 changes. Exact toolchain/CPU/OS/browser versions are in task5-final.log. Core MVP reached; CLI, product website, formal benchmark, CI and final materials remain tasks 6–8. Next: task 6 Node CLI and exit codes 0/1/2.

Task 6 decisions:
- Ruling: Keep all error-envelope serialization in MoonBit, including client IO/encoding/argument failures. Add the narrow client_error(code, message, side) string export; reject unsupported transport metadata rather than inventing a fake diff. Cost: one additional public bridge helper; analyze/report semantics are unchanged.
- Keep user file bytes intact through fatal UTF-8 decoding with ignoreBOM=true, so MoonBit strips exactly one BOM and counts its original bytes. Read options before document files, and pass all three strings directly to analyze. JSON.parse is used only for package metadata and returned report envelopes.
- JSON stdout is exactly the core report string, with no appended newline; text and stderr error diagnostics use the shared MoonBit formatter. Exit status derives only from ok/equal. Runtime failures without a loadable core return 2 and useful stderr, with empty stdout.
- Strictly reject unknown, duplicate and missing-value flags and wrong file counts; support an option terminator for input filenames. --help and --version are standalone and work without build artifacts, independently of the current directory. Register the local bin name while keeping package private.

Task 6 RED: compileable CLI stub produced 48 failed/1 passed out of 49 real process tests; raw log task6-cli-red.log. New client-error adapter stub produced 3 failed/98 passed out of 101 core tests; runnable RED in task6-error-red.log. Test wiring was corrected from map indexing (Json result) to get (Option result) using existing tested APIs. The first implementation run exposed an incorrect new text expectation (existing side strings are quoted); corrected that expectation without changing the renderer.

Task 6 review: current-agent inline check of strict file decoding, BOM preservation, error-side/unknown-location handling, no user-document JSON.parse or writes, stable imports, stdout/stderr separation, actual process exit codes and all fixture bytes. No subagents, public operations, precision reduction or core feature removal. User supplemental documents remain untouched; no pending review finding.

README verification: the committed examples/config files produced one timeout change and one ignored subtree in text and JSON, both with the expected exit 1; actual output saved in task6-readme-demo.log. npm run cli:smoke also executed successfully with 49/49 process tests after package script registration.

Task 6: complete (base df9d62a; implementation commit includes this entry). scripts/verify-task6.ps1 → exit 0: 101/101 MoonBit tests, deny-warn JS check, release build, controlled Document boundary rejection, legacy 12 Node/real Chrome Worker parsing cases, 49/49 CLI smoke tests, 15 complete success/error JSON and text reports byte-identical across direct bridge, CLI and actual Chrome 154.0.8037.98 module Worker. Windows 11 x64 10.0.22631, i7-12700H, Node 22.23.3, moon 0.1.20260920, moonc/core 0.10.14+7d59c7ec9; real RED/GREEN/final logs saved under docs/validation/task6-*.log. Linux remains untested and no formal performance result is claimed. Next: task 7 static product website with Worker timeout/cancel/stale-result handling.

Task 7 decisions:
- Use native HTML/CSS/ES modules and a preloaded module Worker importing the same stable dist facade. Main-thread JS handles file IO, lifecycle, DOM and downloads; only returned report envelopes are parsed. Options and user documents remain raw strings.
- Ruling: Display at most 100 changes per page with an explicit range while retaining the exact full report for download and all summary counters. Cost: pagination controls; there is no core limit reduction, hidden truncation or report-semantic change.
- Runtime WORKER_TIMEOUT/WORKER_ERROR remain visible client failures, without fabricated core JSON. Input/option/IO/encoding failures use the same MoonBit report. Cancellation/new comparison/draft edits invalidate request IDs; active workers terminate and next comparison rebuilds them. Idle workers stay loaded for offline comparison.
- Each file read has a side-specific token. Edits/new files/examples invalidate late reads; pending imports block comparison, and failed UTF-8 files stay errors until corrected. Preserve exactly one removable BOM and original numeric tokens by fatal decoding with ignoreBOM=true.
- Use a localhost-only explicit static asset allowlist, GET/HEAD only, relative module paths, and no runtime CDN/upload/storage/telemetry. Keep the approved non-PWA offline scope; terminated workers rebuild from the local service.
- Adapt the Playwright skill's Bash CLI-first workflow to the existing pinned playwright-core driver and the plan's executable browser smoke script on Windows. Real Chrome is used; no extra browser or CLI installation, no @playwright/test, no product test hooks. User-supplied sequential execution and approved plan remain binding.

Task 7 RED: Worker state stub 0/7; server stub 404 instead of 200; real-page first fixture 0/1; full page stub 1/34 with 33 behavior failures. The initially passing file-race test did not prove a read began, so added a pending-read/disabled-compare assertion and observed 0/1 RED. One test-call parenthesis error was corrected before claiming runnable browser RED. Logs preserve actual failing and passing runs.

Task 7 review: current-agent inline review of raw strings, worker/request guards, actual terminate/recovery, timer cancellation, file-read ownership, dirty-report invalidation, original report download bytes, absent/null/numeric display, raw options context, text-node rendering, bounded view pagination and static allowlist. Actual 1440px desktop and 390px narrow screenshots inspected; no layout or horizontal-overflow issue. No subagents/public operations/precision reduction/core deletions. Three user supplemental files remain untouched and outside the commit. No pending review findings.

Task 7: complete (base b98131d; implementation commit includes this entry). scripts/verify-task7.ps1 → exit 0: JS deny-warn check, release build, 101/101 core tests, Document boundary rejection, legacy 12 Node/Worker parsing cases, 49/49 CLI smoke, 7/7 Worker state tests, read-only static-server smoke, 34/34 actual product-page Chrome smoke. 15 downloaded reports match direct bridge/CLI exact bytes; three demos work under browser network offline. Actual 5-second controlled stall timed out at 5048.4202 ms and recovered; this is a client protection test, not a performance benchmark. 284 localhost GET requests, zero remote/upload requests in product-page smoke. Environment: Windows 11 x64 10.0.22631, i7-12700H, Node 22.23.3, Chrome 154.0.8037.98, moon 0.1.20260920, moonc/core 0.10.14+7d59c7ec9. RED/final logs and raw browser results preserved under docs/validation; reproducible visual artifacts under ignored output/playwright. Task 7 functional scope frozen; Linux untested. Next: task 8 genuine benchmarks, CI, clean rebuild and hackathon materials.
