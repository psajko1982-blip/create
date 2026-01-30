package.path = "/?.lua;/lib/?.lua;" .. package.path

local net = require("lib.net")
local log = require("lib.log")

local known = {}  -- name -> id

local function showKnown()
  log.info("Kända workers:")
  for name, id in pairs(known) do
    print(" -", name, "=>", id)
  end
end

local function resolveTarget(x)
  if not x then return nil end
  local n = tonumber(x)
  if n then return n end
  return known[x]
end

log.info("Master online. id=" .. os.getComputerID())
log.info("Kommandon:")
log.info("  ping")
log.info("  list")
log.info("  on <name|id>")
log.info("  off <name|id>")
log.info("  alloff")

while true do
  write("> ")
  local line = read()
  local args = {}
  for w in string.gmatch(line, "%S+") do table.insert(args, w) end
  local cmd = args[1]

  if cmd == "ping" then
    known = {}
    net.broadcast({ cmd = "PING" })

    local t0 = os.clock()
    while os.clock() - t0 < 1.2 do
      local from, msg = net.receive(0.2)
      if from and type(msg) == "table" and msg.ok and msg.name then
        known[msg.name] = from
        log.info("pong:", msg.name, "id=" .. from, "out=" .. tostring(msg.output_side))
      end
    end

    showKnown()

  elseif cmd == "list" then
    showKnown()

  elseif cmd == "on" and args[2] then
    local id = resolveTarget(args[2])
    if not id then
      log.warn("Okänd target. Kör 'ping' först eller använd id.")
    else
      net.send(id, { cmd = "ON" })
      log.info("ON skickat till", args[2], "(id=" .. id .. ")")
    end

  elseif cmd == "off" and args[2] then
    local id = resolveTarget(args[2])
    if not id then
      log.warn("Okänd target. Kör 'ping' först eller använd id.")
    else
      net.send(id, { cmd = "OFF" })
      log.info("OFF skickat till", args[2], "(id=" .. id .. ")")
    end

  elseif cmd == "alloff" then
    net.broadcast({ cmd = "OFF" })
    log.warn("OFF skickat till alla")

  else
    log.warn("Kommandon: ping | list | on <name|id> | off <name|id> | alloff")
  end
end
