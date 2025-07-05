# -*- coding: utf-8 -*-


import os
import re
import protoname

modified_keys=[
    "ReqLoginAuth",
    "ResLoginAuth",
    "ReqSelectPlayer",
    "ResSelectPlayer",
    "ReqCreatePlayer",
    "ResCreatePlayer",
    "ReqEnterGame",
    "ResEnterGame", 
    "NotifyPlayerBaseData",
    "ResServerCloseClient",  
    "ReqHeartTick",
    "ResHeartTick",
    "ReqRegPlayerBaseInfo", 
    "NotifyCloseGame",   
    "NotifyServerCloseClient",   
    "NotifyServerForceCloseClient",
    "ReqUpdatePlayerBaseInfo",
    ]

lua = []




default_message_id_range = 100
activity_message_id_range=100


def process_proto_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        allline = [line.strip() for line in lines if line.strip()]
        maxLen = len(allline)
        for i, line in enumerate(allline):
            if i >= maxLen:
                continue
            luak = line[8:] 
            if line.startswith("message") and (luak.startswith("Req") or luak.startswith("//") or luak.startswith("Res") or luak.startswith("Notify")):
                pre = allline[i-1]
                luav = ""
                if pre.startswith("//"):
                    luav = pre[2:]
                luav = luav.strip()  
                dic = {luak:luav}
                #print(dic)
                lua.append(dic)


def process_proto_folder(folder_path):
    for key in protoname.seq_proto_list:
        file_path = os.path.join(folder_path, key+".proto", )
        #print("xxxxxxxxx",file_path)
        process_proto_file(file_path)
        #print("xxxxxxxxxxxxx",file_path)
        lua.append({"enposname":key})
        #print(lua)

process_proto_folder("./protobuf")

def is_element_in_list(element, lst):
    return element in lst

with open('./bin/common/msgdef.lua', 'w') as file:
    file.write('local cacheMsg = {}\n\n')
    file.write('local function regMsg(msgId, msgName, lang)\n')
    file.write('\tlocal name = cacheMsg[msgId]\n')
    file.write('\tif name and name == msgName then\n')
    file.write('\t\tprint("msgName repeated", msgId, msgName)\n')
    file.write('\t\treturn\n')
    file.write('\tend\n\n')
    file.write('\tcacheMsg[msgId] = msgName\n')
    file.write('\tgMainThread:cacheMessage(msgId, lang, msgName, "")\n')
    file.write('end\n\n')
    file.write('ProtoDef=\n{\n')
    index = 1
    pre_index = default_message_id_range
    for entry in lua:
        for key, value in entry.iteritems():
            if is_element_in_list(value, protoname.seq_proto_list):
                if value == "Active":
                    index = activity_message_id_range + pre_index
                else:
                    index = default_message_id_range + pre_index
                pre_index = index
                continue
            if value:
                if key in modified_keys:
                    file.write('\t{}={{id={},lang="cpp",name="{}"}}, -- {}\n'.format(key, index, key, value))
                else:
                    file.write('\t{}={{id={},lang="lua",name="{}"}}, -- {}\n'.format(key, index, key, value))
            else:
                file.write('\t{}={{id={},lang="lua",name="{}"}}, -- \n'.format(key, index, key))
            index += 1
            
    file.write('}\n\n')
    file.write('for k, v in pairs(ProtoDef) do\n')
    file.write('\tregMsg(v.id, k, v.lang)\n')
    file.write('end\n\n')
    file.write('function gGetCppProto()\n')
    file.write('\tlocal tab = {}\n')
    file.write('\tfor k, v in pairs(ProtoDef) do\n')    
    file.write("\t\tif v.lang == 'cpp' then tab[v.id]=k end\n")
    file.write("\tend\n")
    file.write("\treturn tab\n")
    file.write("end\n\n")
    file.write('cacheMsg = nil\n')
    









def convert_lua_to_cpp():
    input_file = "./bin/common/msgdef.lua"
    output_file = "../common/ProtoIdDef.h"

    protocols = []
    with open(input_file, 'r') as f:
        for line in f:
            val = line.strip()
            if val.startswith(("Req", "Res", "Notify")):
                match = re.search(r'^(\w+)\s*=\s*{id\s*=\s*(\d+),.*?},\s*--\s*(.*)$', line.strip())
                if match:
                    resName = match.group(1)
                    msg_id = match.group(2)
                    comment = match.group(3).strip()
                    protocols.append((resName, msg_id, comment))


    protocols.sort(key=lambda x: int(x[1]))
    

    enum_lines = []
    for i, (name, msg_id, comment) in enumerate(protocols):
        suffix = "" if i == len(protocols) - 1 else ","
        enum_lines.append("    {} = {}{}  // {}".format(name, msg_id, suffix, comment))
    
    enum_code = "#pragma once\nenum class ProtoIdDef :uint16_t \n{\n"
    enum_code += "\n".join(enum_lines)
    enum_code += "\n};"
    
    with open(output_file, 'w') as f:
        f.write(enum_code)


convert_lua_to_cpp()













