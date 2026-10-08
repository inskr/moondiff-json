# Task 8 review and evidence

Current-agent sequential review; no parallel reviewer, in accordance with the approved execution ledger.
Base: 217e924. First reviewable increment: 9c0d4dd. The original three untracked supplemental user documents
remain untouched and excluded. No core semantic, precision, feature or public API changes in this phase.

- Unified acceptance truly ran check/fmt/test/release build, constructor boundary, golden fixtures, Node/CLI,
  real Chrome product page and Worker, cancellation/stale IDs/timeout recovery, and fixed-seed properties.
  Result: 101 core, 49 CLI, 7 lifecycle, 34 webpage, 225 property cases; 15 golden and 15 generated cases have
  byte-equal reports across bridge/CLI/Worker. The generated cases also check symmetry, self equality,
  object order, decimal notation, keyed reorder invariance, determinism and RFC 6901 escapes.
- Deliberately returning an always-equal report was rejected for adjacent large integers. Saved sample and
  --replay evidence are retained. Product compare/report code was not replaced by a JS oracle.
- First benchmark had a wrong expected node/depth error code; corrected the harness to actual NODE_LIMIT
  and DEPTH_LIMIT. No product fix or relaxed limit. Second run measured all nine cases, each 5 warmups and
  20 samples; returned envelopes and repeated report bytes checked outside timing. Raw samples and hashes
  retained. Main positional/keyed medians: 77.559/99.421 ms; no claimed cross-library superiority.
- CI is configured for Windows 2022 with hash-checked pinned tools, lockfile, pinned Playwright Chromium
  revision and resolved action SHAs. Bench is independent, no timing gate. Remote CI is not claimed run.
- Clean source snapshot 9c0d4dd: fresh dist/_build/node_modules/.mooncakes, official downloaded tool archives
  alone reused and SHA256 checked again. README setup/npm ci/moon update/acceptance/prepare ran successfully.
  Core JS SHA256 in both directories: 6be681196f48475b38e301b7d30e552d54dd48dfb5829698529e2ac26c3128b7.
- Runtime license texts and complete core NOTICE retained. Source MIT applies to original code only.
  Tools/browser/recorder are development dependencies, not shipped runtime binaries.
- Actual recording includes six byte-verified golden downloads. Initial browser seek verification lacked
  HTTP Range responses in its test route and kept returning initial bytes; independent FFmpeg decoding
  proved the mid-video scene existed. Correct Range responses fixed the verifier. Captions were moved away
  from values and the video re-recorded. Final video: 150.92 seconds, 1440x1080, seven distinct decoded frames;
  actual keyed paths, exact integers and error frames visually checked. No generated imagery/voice/speedup.
- Local source/runtime deliverables, README, ecosystem/AI/one-pager/demo materials prepared. Namespace remains
  local/moondiff-json; Linux and remote CI untested. Toolchain download expiry is disclosed. Public push,
  deployment, package publication, tag and contest submission await separate explicit user authorization.

No unresolved task-8 implementation defect found. Final property wait guards were tested with the same
225 cases and 15 real Worker/CLI parity cases after the first clean snapshot. See task8-properties-final.log.
