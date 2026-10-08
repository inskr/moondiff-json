# Source this file from the repository root after setup-linux.sh.
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export MOON_HOME="$task_root/.tools/moon-linux"
export PATH="$task_root/.tools/node-v22.23.3-linux-x64/bin:$MOON_HOME/bin:$PATH"
if [[ ! -x "$MOON_HOME/bin/moon" || ! -x "$task_root/.tools/node-v22.23.3-linux-x64/bin/node" ]]; then
  echo 'Run bash scripts/setup-linux.sh first.' >&2
  return 1
fi
unset task_root
