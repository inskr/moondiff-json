#!/usr/bin/env bash
# Project-local Linux x64 tools only; no PATH/profile/system changes.
set -euo pipefail
[[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || { echo 'Linux x64 required.' >&2; exit 2; }
task_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
task_tools="$task_root/.tools"
task_downloads="$task_tools/downloads"
mkdir -p "$task_downloads" "$task_tools/moon-linux/lib"
for command in curl sha256sum tar unzip; do command -v "$command" >/dev/null || { echo "Missing prerequisite: $command" >&2; exit 2; }; done
get_archive() {
  local url="$1" file="$task_downloads/$2" sha="$3"
  if [[ ! -f "$file" ]]; then
    curl --fail --location --retry 3 "$url" --output "$file.part"
    mv -- "$file.part" "$file"
  fi
  printf '%s  %s\n' "$sha" "$file" | sha256sum --check --strict
}
get_archive 'https://cli.moonbitlang.com/binaries/0.10.14%2B7d59c7ec9/moonbit-linux-x86_64.tar.gz' moonbit-linux-x86_64.tar.gz 9226694de9ff978db1ecf820b7710c4224e84ec7a76b19a222d96f0cd4e31b6a
get_archive 'https://cli.moonbitlang.com/cores/core-0.10.14%2B7d59c7ec9.zip' core.zip 63e5b99991ac8fd49556b1e17bdcbdc662d797000250dd11ef090f38a2175e84
get_archive 'https://nodejs.org/dist/v22.23.3/node-v22.23.3-linux-x64.tar.xz' node-v22.23.3-linux-x64.tar.xz df450af89261115ef9f9e3830c3eeb2cc9213b63c720b1af623cb5dcbe2e02de
tar -xzf "$task_downloads/moonbit-linux-x86_64.tar.gz" -C "$task_tools/moon-linux"
# This official archive stores bin tools as 0664; restore execution before use.
chmod +x "$task_tools/moon-linux/bin/"*
unzip -oq "$task_downloads/core.zip" -d "$task_tools/moon-linux/lib"
tar -xJf "$task_downloads/node-v22.23.3-linux-x64.tar.xz" -C "$task_tools"
source "$task_root/scripts/moon-env.sh"
(cd "$MOON_HOME/lib/core" && moon bundle --target js --warn-list -a)
moon version --all
[[ "$(node --version)" == v22.23.3 ]] || { echo 'Unexpected Node version.' >&2; exit 2; }
echo 'Tools prepared. Next: source scripts/moon-env.sh'
