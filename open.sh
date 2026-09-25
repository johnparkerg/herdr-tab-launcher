#!/usr/bin/env bash
# Resolve where the user is (workspace + cwd of the focused pane), then open the
# picker popup (popups always open over the active pane, so no --workspace;
# the workspace goes to menu.sh via env, which creates the tab there).
set -uo pipefail
herdr="${HERDR_BIN_PATH:-herdr}"

ctx="${HERDR_PLUGIN_CONTEXT_JSON:-}"
[ -n "${TAB_LAUNCHER_DEBUG:-}" ] && printf '%s\n' "$ctx" > "${TMPDIR:-/tmp}/tab-launcher-ctx.json"

ws=$(printf '%s' "$ctx" | jq -r '.workspace_id // empty' 2>/dev/null)
cwd=$(printf '%s' "$ctx" | jq -r '.focused_pane_cwd // .workspace_cwd // empty' 2>/dev/null)

if [ -z "$ws" ] || [ -z "$cwd" ]; then
  focused=$("$herdr" pane list 2>/dev/null | jq -c 'first(.result.panes[] | select(.focused)) // empty' 2>/dev/null)
  [ -z "$ws" ]  && ws=$(printf '%s' "$focused"  | jq -r '.workspace_id // empty' 2>/dev/null)
  [ -z "$cwd" ] && cwd=$(printf '%s' "$focused" | jq -r '.foreground_cwd // .cwd // empty' 2>/dev/null)
fi
[ -d "$cwd" ] || cwd="$HOME"

# No --cwd: the manifest runs `bash menu.sh` relative to the pane cwd, so it must
# stay the plugin root. The target dir travels via env instead.
args=(plugin pane open --plugin tab-launcher --entrypoint menu --placement popup --focus --env "TAB_LAUNCHER_CWD=$cwd")
[ -n "$ws" ] && args+=(--env "TAB_LAUNCHER_WORKSPACE=$ws")
exec "$herdr" "${args[@]}"
