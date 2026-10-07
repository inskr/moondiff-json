# Execution ledger — plan: F:/MOONBit/docs/plan.md

Scope: tasks 1–3 authorized by the user in sequence.

Task 1: complete.
Task 2: complete (base 30f08a6).
Task 3: complete (base 1802b89).
Tasks 4–8: pending.

Pre-flight interfaces:
- 1 → 2/5: parser must preserve raw number tokens, reject duplicate decoded keys and limit depth during parsing; verified API will determine adapter types.
- 1 → 6/7: stable dist module must export string functions usable in Node and browser module Worker; no guessed build filename.
- 2 → 3/4/5: shared Document, NumberKey, Pointer and error types must precede comparison and report implementation.
- 3/4 → 5: diff must preserve both paths, validate identities before whole-array additions, and honor deterministic ordering.
- 5 → 6/7/8: identical analyze report bytes feed both clients and acceptance; format_text remains MoonBit-owned.

Ruling: Work in the designated, previously empty project directory on a new local task branch. No existing implementation or user changes are replaced; no additional worktree is needed.
Ruling: The supplied spec and plan are approved. Do not repeat brainstorming approval or create a competing plan. Current-agent sequential execution overrides skill suggestions to delegate.
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
