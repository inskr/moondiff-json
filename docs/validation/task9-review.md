# Task 9 final review and validation record

Date: 2026-10-08 (Asia/Shanghai). Baseline: 1ca2e88. Implementation: 00a093c.
This record covers local preparation, not a remote Actions run or Linux runtime pass.

A separate read-only reviewer examined CI failure propagation, Linux setup/archive layout,
tracked revision packaging, standalone runtime, byte assertions, diagnostics retention and dispatch prerequisites.
Two findings were fixed:

- P1: official pinned MoonBit Linux tar entries moon/moonc/moonfmt/mooncake are mode 0664.
  Python tarfile confirmed the original metadata; setup restores bin execution before its -x check/bundle.
  Bash setup/env and Linux CI run-block syntax pass on Windows Git Bash. Linux execution remains untested.
- P2: checking only tracked changes could allow untracked MoonBit files into runtime but exclude them
  from git archive. Packaging now also rejects untracked files except the three known user supplement .md
  files. An actual temporary untracked .mbt sentinel was rejected before build and then removed.
  Passing a runtime destination outside work/release was also rejected before mutation.

No remaining blocking findings or deferred minor findings. The protected user documents were never edited/staged.
Keep the existing local task branch and user checkout; push/deploy/release/submission were not authorized or performed.

## Commands actually run

| Command | Actual result |
| --- | --- |
| npm.cmd ci; moon.exe update | Both exit 0, pinned dependencies installed |
| npm.cmd run acceptance (root) | Exit 0; 101 core, 49 CLI, 7 Worker, 34 real-page, 225 properties |
| node scripts/verify-release.mjs (old runtime) | Expected exit 1: missing independent npm serve command |
| npm.cmd run prepare:local; npm.cmd run verify:release | Exit 0; 19 file hashes, 15 JSON/text CLI fixtures with 0/1/2, standalone HTTP/page/Worker/download |
| npm.cmd run prepare:release (dirty tracked source) | Expected rejection before build |
| npm.cmd run prepare:release (committed 00a093c) | Exit 0; source/runtime tar.gz; staged and extracted runtime pass; exact commit/SHA256 manifest |
| setup-windows.ps1; npm.cmd ci; moon.exe update; npm.cmd run acceptance (fresh source archive) | Exit 0; same full counts and report byte parity; new dependency/build outputs |
| Compare fresh/root core JS SHA256 | Equal: 6be681196f48475b38e301b7d30e552d54dd48dfb5829698529e2ac26c3128b7 |
| Python yaml BaseLoader structure checks; bash -n setup/env/all Linux run blocks | Pass, static checks on Windows only |
| Python tarfile mode/hash inspection | Official archive mode 0664 confirmed; fixed SHA matches downloaded archive |
| node scripts/package-local.mjs with temporary untracked .mbt | Expected nonzero; named sentinel rejected before build |
| node scripts/prepare-local.mjs F:\MOONBit\web | Expected nonzero; outside output rejected before mutation |
| git diff --check / cached diff inspection | Pass; original user supplements excluded |
| wsl --list --verbose; Docker version/context; Podman/SSH availability checks | No currently usable Linux execution environment |

Source archive clean-rebuild tested code is 00a093c; the completion commit changes only documents/evidence.
Final HEAD is repackaged after committing this record so source/runtime share the manifest revision.
Evidence: task9-dependencies.log, task9-acceptance.log, task9-runtime-red.log,
task9-runtime-green.log, task9-static.log, task9-package.log and task9-clean-rebuild.log.
Final package execution log is work/task9-release-final.log (ignored generated output).

Linux 尚未实测. Remote CI 尚未运行. No remote is configured, so authorized destination and push
permission are required before remote execution. The configuration itself is ready for that next step.
