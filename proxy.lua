local proxy={proxy="http://127.0.0.1:8080"}
local component=require("component")
local internet=component.internet

function proxy.request(URL,postData,headers)
  if type(proxy.proxy)~="string" or not proxy.proxy:match("^https?://[^/]+$") then
    error("proxy is invalid.example: http://127.0.0.1:8080")
  end
  local host,url=URL:match("http://([^/]+)(/?.*)")
  assert(host,"unsupported protocol")
  if url=="" then
    url="/"
  end
  url=proxy.proxy..url
  headers=headers or {}
  headers["Host"]=host
  headers["Proxy-Connection"]="keep-alive"
  headers["Connection"]="close"
  return internet.request(url,postData,headers)
end

return proxy