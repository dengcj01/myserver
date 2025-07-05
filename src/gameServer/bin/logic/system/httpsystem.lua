
local tools = require "common.tools"

local httpsystem = {}

local http = require "common.socket.http"
local ltn12 = require "common.socket.ltn12"
local socket = require "common.socket.socket"

function httpsystem.sendGetMessage(params)
    if not gMainThread:checkNetworkConnection("gm-zhujiange.scszsj.com") then
        return
    end
    
    local url = "http://gm-zhujiange.scszsj.com/log_login?"
    url = url..params
    local response_body = {}
    local _M, e, a, b, c = http.request {
                    url = url,
                    method = "GET",
                    source = ltn12.source.string(params),
                    sink = ltn12.sink.table(response_body) -- 将响应体存储到table中

    }

    -- print(_M, e, a, b, c)
    tools.ss(response_body)
end



function httpsystem.sendPostMessage(params, addr)
    if not gParseConfig:isDevelopServer() then
        print("111111111111111111111111111111111111111111111111")
        if not gMainThread:checkNetworkConnection("gm-zhujiange.scszsj.com") then
            print("222222222222222222222222222222222222222222222222")
            return
        end
        print("33333333333333333333333333333333333333333333333333333")
    
        local url = "http://gm-zhujiange.scszsj.com/"
        url = url..addr
        local response_body = {}
    
        local headers = 
        {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Content-Length"] = #params
        }
        --print("url:", url)
        local _M, e, a, b, c = http.request {
                        url = url,
                        method = "POST",
                        headers = headers,
                        source = ltn12.source.string(params),
                        sink = ltn12.sink.table(response_body) -- 将响应体存储到table中
    
        }
    
        -- print(_M)
        -- print(e)
        -- print(a)
        -- print(b)
        -- print(c)
    
        --tools.ss(response_body)

    end


end

return httpsystem