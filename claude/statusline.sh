#!/bin/bash
# Status line: model, context use, and the plan's 5-hour / 7-day usage.
# Also saves that usage to ~/.cache/claude-usage.json for scripts outside a session (orchestrators).
input=$(cat)

limits=$(jq -c '.rate_limits // empty' <<<"$input")
if [ -n "$limits" ]; then
  cache=~/.cache/claude-usage.json
  mkdir -p ~/.cache
  jq --argjson updated_at "$(date +%s)" '. + {updated_at: $updated_at}' <<<"$limits" >"$cache.$$" && mv "$cache.$$" "$cache"
fi

jq -r '
  def window($name; $w):
    if $w then " · \($name) \($w.used_percentage | floor)% (resets \($w.resets_at | strflocaltime("%a %H:%M")))" else "" end;
  "\(.model.display_name) · context \(.context_window.used_percentage // 0 | floor)%"
    + window("5h"; .rate_limits.five_hour) + window("7d"; .rate_limits.seven_day)' <<<"$input"
