#!/bin/bash
# `@` suggestions: tracked and untracked files, plus the local-only paths gitignore
# hides from the built-in picker (agent-docs, CLAUDE.local.md, and whatever the
# clone lists in .git/info/exclude). Reads {"query": ...} on stdin, prints <= 15 paths.

query=$(jq -r '.query // ""')
cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0

list() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard
    local extra=(agent-docs CLAUDE.local.md)
    local exclude
    exclude=$(git rev-parse --git-path info/exclude)
    [ -f "$exclude" ] && while IFS= read -r line; do extra+=("$line"); done \
      < <(grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$exclude")
    git ls-files --others --ignored --exclude-standard -- "${extra[@]}" 2>/dev/null
    # agent-docs is a symlink to ~/agent-docs/<repo>; git lists only the link.
    [ -e agent-docs ] && find -L agent-docs -name node_modules -prune -o -type f -print
  else
    find . -type f -not -path '*/.git/*' | sed 's|^\./||'
  fi
}

list | grep -v -e '/node_modules/' -e '^node_modules/' | sort -u |
  awk -v q="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')" '
    # Every parent directory is a suggestion too, as the built-in picker offers.
    { emit($0); n = split($0, part, "/"); d = ""
      for (i = 1; i < n; i++) { d = d part[i] "/"; if (!(d in seen)) { seen[d] = 1; emit(d) } } }
    function emit(p,   lp, base, j, k) {
      lp = tolower(p); base = lp; sub(/\/$/, "", base); sub(/.*\//, "", base)
      if (q == "")               { print 3 "\t" length(p) "\t" p; return }
      if (index(base, q))        { print 0 "\t" length(p) "\t" p; return }
      if (index(lp, q))          { print 1 "\t" length(p) "\t" p; return }
      # Fuzzy: the query letters appear in order.
      k = 1
      for (j = 1; j <= length(lp) && k <= length(q); j++)
        if (substr(lp, j, 1) == substr(q, k, 1)) k++
      if (k > length(q))         { print 2 "\t" length(p) "\t" p }
    }' |
  sort -t $'\t' -k1,1n -k2,2n | head -15 | cut -f3
