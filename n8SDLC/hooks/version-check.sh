#!/bin/sh
# SessionStart: compare the project's recorded n8SDLC version with the installed plugin's.
# Silent outside n8SDLC projects and when they match. Never fails the session.
cfg="${CLAUDE_PROJECT_DIR:-$PWD}/.n8/config.yml"
[ -f "$cfg" ] || exit 0
plugin=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json" | head -n 1)
[ -n "$plugin" ] || exit 0
project=$(sed -n 's/^plugin_version: *["'\'']*\([^"'\'' #]*\).*/\1/p' "$cfg" | head -n 1)
[ "$project" = "$plugin" ] && exit 0

if [ -z "$project" ]; then
  msg="n8SDLC $plugin is installed; this project hasn't recorded an n8SDLC version, so it may be missing newer project-side setup. Run /n8-upgrade to check."
elif [ "$(printf '%s\n%s\n' "$project" "$plugin" | sort -V | tail -n 1)" = "$plugin" ]; then
  msg="n8SDLC was updated to $plugin; this project is set up for $project. Run /n8-upgrade to bring it current."
else
  msg="This project was upgraded with n8SDLC $project, but the installed plugin is $plugin. Update the plugin (/plugin) and restart."
fi
printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s If the user'"'"'s first request is unrelated, mention this once in a single line and continue; don'"'"'t run the upgrade unasked."}}\n' "$msg" "$msg"
