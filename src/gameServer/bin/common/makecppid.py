# -*- coding: utf-8 -*-
import re

def convert_lua_to_cpp(input_file, output_file):
    protocols = []
    with open(input_file, 'r') as f:
        for line in f:
            val = line.strip()
            if val.startswith(("Req", "Res", "Notify")):
                match = re.search(r'^(\w+)\s*=\s*{id\s*=\s*(\d+),.*?},\s*--\s*(.*)$', line.strip())
                if match:
                    name = match.group(1)
                    msg_id = match.group(2)
                    comment = match.group(3).strip()
                    protocols.append((name, msg_id, comment))


    protocols.sort(key=lambda x: int(x[1]))
    

    enum_lines = []
    for i, (name, msg_id, comment) in enumerate(protocols):
        suffix = "" if i == len(protocols) - 1 else ","
        enum_lines.append("    {} = {}{}  // {}".format(name, msg_id, suffix, comment))
    
    enum_code = "enum ProtoIdDef \n{\n"
    enum_code += "\n".join(enum_lines)
    enum_code += "\n};"
    
    with open(output_file, 'w') as f:
        f.write(enum_code)


if __name__ == "__main__":
    input_file = "./bin/common/msgdef.lua"  # 输入的Lua文件路径
    output_file = "../../../common/ProtoIdDef.h"  # 输出的C++头文件路径
    convert_lua_to_cpp(input_file, output_file)