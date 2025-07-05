
local function parseArgs(...)
    local paramCount = select('#', ...)
    local txt = ''
    for i = 1, paramCount do
    	local data = tostring(select(i, ...))
        txt = txt .. data

        if i < paramCount then
            txt = txt .. " "
        end
    end
    return txt
end



function print( ... ) 
    local info = debug.getinfo(2) or {}
    
    local txt = string.format("%s [line]=%d:", info.source or "?", info.currentline or 0)
    txt = txt..parseArgs(...)
    if string.len(txt) >= 2097152 then
        return
    end
    
    luaLog(3, txt) 
end

function printTrace(...)
    print(debug.traceback(parseArgs(...))) 
end

