local proxy={proxy="127.0.0.1:8080"}
local component=require("component")
local internet=component.internet
local event=require("event")

local function split(str,s)
  local lines={}
  while 1 do
    local pos1,pos2=str:find(s)
    if pos1==nil then
      if str~="" then
        table.insert(lines,str)
      end
      break
    end
    table.insert(lines,str:sub(1,pos1-1))
    str=str:sub(pos2+1)
  end
  return lines
end

local function wait(socket)
  local _,id
  repeat
    socket.finishConnect()
    _,id=event.pull(0)
    print(_,id,socket.id())
  until socket.id()==id
end

function proxy.request(URL,postData,headers)
  if type(proxy.proxy)~="string" or not proxy.proxy:match("[^:]+:?%d*") then
    error("proxy is invalid.example: 127.0.0.1:8080")
  end
  local ip,port=proxy.proxy:match("([^:]+):?(%d*)")
  port=tonumber(port)
  if not port then
    port=80
  end
  local host,url=URL:match("http://([^/]+)(/?.*)")
  assert(host,"unsupported protocol")
  if url=="" then
    url="/"
  end
  headers=headers or {}
  headers["Host"]=host
  headers["Proxy-Connection"]="keep-alive"
  headers["Connection"]="close"
  if postData then
    headers["Content-Length"]=tostring(#postData)
  end
  local socket=assert(internet.connect(ip,port))
  local success,reason
  repeat
    success,reason=socket.finishConnect()
    assert(success~=nil,reason)
  until success
  local buffer=(postData==nil and "GET" or "POST").." "..url.." HTTP/1.1\r\n"
  for k,v in pairs(headers) do
    buffer=buffer..string.format("%s: %s\r\n",k,v)
  end
  buffer=buffer.."\r\n"..(postData or "")
  socket.write(buffer)
  os.sleep(1)--pcall(wait,socket)
  local chunk=""
  buffer=""
  repeat
    chunk=socket.read(math.huge)
    if chunk then
      buffer=buffer..chunk
    end
  until chunk=="" or not chunk
  local response=split(buffer,"\r\n")
  local code,status=string.match(table.remove(response,1),"HTTP/1.1 (%d%d%d) (.+)")
  headers={}
  while 1 do
    local line=table.remove(response,1)
    if not line or line=="" then
      break
    end
    local k,v=string.match(line,"(.+): (.+)")
    headers[k]={v}
  end
  data=table.concat(response,"\r\n")
  return {read=function(n) if n==nil then n=#data end local data1=data:sub(1,n) data=data:sub(n+1) return data1 end,
          finishConnect=function() return nil, "connection lost" end,
          close=socket.close,
          response=function() return tonumber(code),status,headers end}
end

return proxy
