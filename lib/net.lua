-- lib/net.lua
local M = {}

local function openModem()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "modem" then
      if not rednet.isOpen(side) then rednet.open(side) end
      return side
    end
  end
  return nil
end

function M.ensure()
  local side = openModem()
  if not side then error("No modem found") end
  return side
end

function M.send(toId, msg)
  M.ensure()
  rednet.send(toId, msg, "factory")
end

function M.broadcast(msg)
  M.ensure()
  rednet.broadcast(msg, "factory")
end

function M.receive(timeout)
  M.ensure()
  local id, msg, proto = rednet.receive("factory", timeout)
  return id, msg, proto
end

return M
