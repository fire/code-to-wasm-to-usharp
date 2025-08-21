#!/usr/bin/python3
import re
import sys

path = sys.argv[2]
with open(path, "r") as f:
	wat = f.read()

used_funcs = []
inputs = wat.split("\n  (")
for chunk in inputs:
	if chunk.startswith("func "):
		m = re.match(r"func (\S+)", chunk)
		used_funcs.append(m[1])

path = sys.argv[1]
with open(path, "r") as f:
	wat = f.read()

outputs = []
inputs = wat.split("\n  (")
stripped = []
for chunk in inputs:
	if chunk.startswith("func "):
		m = re.match(r"func (\S+)", chunk)
		if m[1] not in used_funcs:
			lines = chunk.split("\n")
			if len(lines) > 1:
				chunk = lines[0] + "\n    unreachable)"
				stripped.append(m[1])
	outputs.append(chunk)

print(f"stripped {len(stripped)} functions")
with open(path, "w") as f:
	f.write("\n  (".join(outputs))