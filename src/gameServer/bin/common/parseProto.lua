




-- local lfs = require("lfs")



-- for val in lfs.dir( "../protobuf") do
--     if val ~= "." and val ~= ".." then
--         print(val)
--         gMainThread:parseProto(val)
--     end
-- end

local protoList = require "common.ProtoList"
for k,v in pairs(protoList) do
    
    gMainThread:parseProto(v..".proto")
end