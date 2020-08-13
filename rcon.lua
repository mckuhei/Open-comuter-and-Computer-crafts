local rcon={utils={}}

function rcon.Packet(ident,kind,payload)
  return {ident=ident,kind=kind,payload=payload}
end

function rcon.IncompletePacket(minimum)
  return setmetatable({minimum=minimum},{__tostring=function(tbl) return string.format("IncompletePacket(%s)",tbl.minimum) end})
end

function rcon.utils.encodePacket(packet)
  assert(type(packet)=="table")
  local data=string.pack("<ii",packet.ident, packet.kind)..packet.payload.."\0\0"
  return string.pack("<i",#data)..data
end

function rcon.utils.decodePacket(data)
  if #data<14 then
    error(rcon.IncompletePacket(14))
  end
  local lenght=string.unpack("<i",data:sub(1,4))+4
  if #data < lenght then
    error(rcon.IncompletePacket(lenght))
  end
  local ident, kind = string.unpack("<ii", data:sub(4,12))
  local payload, padding = data:sub(12,lenght-1), data:sub(lenght-1,lenght)
  assert(padding == "\x00\x00")
  return rcon.Packet(ident, kind, payload), data:sub(lenght,#data)
end

function rcon.receive_packet(s)
  local data=''
  while 1 do
    local ok,d=pcall(rcon.utils.decodePacket,data)
    if not ok then
      if d.minimum~=nil then
        local a=s.read(d.minimum-#data)
        data=data..a
      else
        error(d)
      end
    else
      return table.pack(d)[1]
    end
  end
end

function rcon.send_packet(s,packet)
  local p=rcon.utils.encodePacket(packet)
  s.write(p)
end

function rcon.login(s,password)
  rcon.send_packet(s,rcon.Packet(0, 3, password))
  local packet = rcon.receive_packet(s)
  return packet.ident == 0
end

function rcon.command(s,text)
  rcon.send_packet(s,rcon.Packet(0, 2, text))
  rcon.send_packet(s,rcon.Packet(1, 0, ""))
  local response = ""
  while 1 do
    local packet=rcon.receive_packet(s)
    if packet.ident ~= 0 then
      break
    end
    response=response..packet.payload
  end
  return response
end

return rcon