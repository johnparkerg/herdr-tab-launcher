#!/usr/bin/env bash
# One-keypress picker. Creates a focused tab in $TAB_LAUNCHER_CWD and runs the
# chosen command in its shell. Enter = plain shell, Esc/q = cancel (no tab).
set -uo pipefail
herdr="${HERDR_BIN_PATH:-herdr}"
cwd="${TAB_LAUNCHER_CWD:-$HOME}"

# Menu entries come from <plugin config dir>/menu.conf, one per line:
#   <key> <command...>
# Blank lines and lines starting with # are ignored.
config_dir="${HERDR_PLUGIN_CONFIG_DIR:-$("$herdr" plugin config-dir tab-launcher 2>/dev/null)}"
conf="$config_dir/menu.conf"
[ -f "$conf" ] || conf="$(dirname "${BASH_SOURCE[0]}")/menu.conf.example"

keys=(); cmds=()
while read -r key cmd; do
  case "$key" in ''|'#'*) continue ;; esac
  [ -n "$cmd" ] || continue
  keys+=("${key:0:1}"); cmds+=("$cmd")
done < "$conf"

printf '\n'
for i in "${!keys[@]}"; do
  printf '   \e[1m%s\e[0m  %s\n' "${keys[$i]}" "${cmds[$i]}"
done
printf '   \e[1m⏎\e[0m  shell\n\n'
printf '   \e[2mesc to cancel\e[0m'

while :; do
  IFS= read -rsn1 key || exit 0
  case "$key" in
    $'\e'|q) exit 0 ;;
    '') cmd=""; break ;;
  esac
  for i in "${!keys[@]}"; do
    [ "$key" = "${keys[$i]}" ] && { cmd="${cmds[$i]}"; break 2; }
  done
done

create=(tab create --cwd "$cwd" --focus)
[ -n "${TAB_LAUNCHER_WORKSPACE:-}" ] && create+=(--workspace "$TAB_LAUNCHER_WORKSPACE")
if ! out=$("$herdr" "${create[@]}" 2>&1); then
  printf '\n\n   tab create failed:\n%s\n' "$out"; read -rsn1; exit 1
fi
pane=$(jq -r '.result.root_pane.pane_id // empty' <<<"$out")

[ -n "$cmd" ] && [ -n "$pane" ] && "$herdr" pane run "$pane" "$cmd" >/dev/null
exit 0
