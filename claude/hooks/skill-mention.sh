#!/usr/bin/env python3
# A /skill only loads when it starts the message. This loads one named anywhere else in it,
# including skills hidden from the model (disable-model-invocation).
import json, os, re, sys

prompt = json.load(sys.stdin).get("prompt", "")
roots = [os.path.expanduser("~/.claude/skills"), os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", "."), ".claude/skills")]
first = re.match(r"\s*/([\w-]+)", prompt)

for name in dict.fromkeys(re.findall(r"(?:^|\s)/([\w-]+)\b", prompt)):
    if first and first.group(1) == name:
        continue
    for root in roots:
        path = os.path.join(root, name, "SKILL.md")
        if os.path.isfile(path):
            print(f"The user invoked the /{name} skill in this message. Read {path} now and follow it, as if invoked directly.")
            break
