httpMgr = {}

local http = require("socket.http")
local ltn12 = require("ltn12")

function sendPostMessage(param)
				-- 发送HTTP GET请求
				local url = "http://192.168.5.199/entrance/base/entrance_list?"

				-- 定义请求参数
				local params = "game_code=fo&id=1"

				-- 发送GET请求
				local response_body = {}
				local _M, e, a, b, c = http.request {
								url = url .. params,
								method = "GET",
								sink = ltn12.sink.table(response_body) -- 将响应体存储到table中

				}

				print(_M, e, a, b, c)
				toolsMgr.ss(response_body)
end
