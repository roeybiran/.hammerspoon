#!/usr/bin/env python3

import glob
import os
import re

parent_dir = os.path.abspath(os.path.dirname(__file__))
docfile = os.path.join(parent_dir, "README.md")

output = []
files = sorted(glob.glob(os.path.join(parent_dir, "Spoons/*.spoon/init.lua")))
for file in files:
    with open(file, 'r') as file_object:
        contents = file_object.read()
        comment_blocks = re.findall(
            r"^---.+?^(?=[^-])", contents, flags=re.MULTILINE | re.DOTALL)
        for block_index, block in enumerate(comment_blocks):
            lines = block.split('\n')
            for line_index, line in enumerate(lines):
                line = re.sub(r"^---\s?", "", line)
                if block_index == 0:
                    if line_index == 0:
                        # the spoon's name
                        spoon_name = os.path.basename(os.path.dirname(file))
                        output.append(f"### {spoon_name}")
                    else:
                        output.append(line)
                else:
                    if line_index == 0:
                        # the API signature
                        output.append(f"#### {line}")
                    elif line_index == 2:
                        # the API kind (method, variable)
                        output.append(f"_{line}_")
                    else:
                        if line.startswith("Parameter") or line.startswith("Return"):
                            output.append(f"**{line}**")
                        else:
                            output.append(line)


with open(docfile, "r") as file_object:
    txt = file_object.read()

txt = re.sub(r"(?<=API\n).+(?=## To Do)", "\n".join(output) + "\n", txt, flags=re.DOTALL)

with open(docfile, "w") as file_object:
    file_object.write(txt)
