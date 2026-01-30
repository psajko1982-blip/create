local net = require("lib.net")
local log = require("lib.log")

local function loadWorkerConfig()
  -- 1) config/worker.lua (rekommenderat)
  if fs.exists("config/worker.lua") then
    local ok, cfg = pcall(dofile, "config/worker.lua")
    if ok and type(cfg) == "table" then
      return cfg
    end
  end

  -- 2) fallback: datorns label (om du satt den)
  local lbl = os.getComputerLabel()
  if lbl and lbl ~= "" then
    return { name = lbl, output_side = "back" }
  end

  -- 3) fallback: anonym
  return { name = ("worker_%d"):format(os.getComputerID()), output_side = "back" }
end

local cfg = loadWorkerConfig()
local OUT = cfg.output_side or "back"
local NAME = cfg.name or ("worker_%d"):format(os.getComputerID())

log.info("Worker online. id=" .. os.getComputerID() .. " name=" .. NAME)
log.info("Output side:", OUT)
log.info("Listening on protocol 'factory'...")

while true do
  local from, msg = net.receive()
  if type(msg) == "table" and msg.cmd then
    if msg.cmd == "PING" then
      net.send(from, {
        ok = true,
        id = os.getComputerID(),
        name = NAME,
        output_side = OUT,
      })

    elseif msg.cmd == "ON" then
      redstone.setOutput(OUT, true)
      net.send(from, { ok = true, cmd = "ON", name = NAME })

    elseif msg.cmd == "OFF" then
      redstone.setOutput(OUT, false)
      net.send(from, { ok = true, cmd = "OFF", name = NAME })

    else
      net.send(from, { ok = false, err = "unknown cmd", name = NAME })
    end
  end
end

