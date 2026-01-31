package.path = "/?.lua;/lib/?.lua;" .. package.path

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
local ACTIVE_LOW = cfg.active_low == true

local function setMachine(isOn)
  -- isOn=true betyder "maskinen ska vara PÅ"
  -- active_low=true betyder: redstone=ON => maskin=OFF
  local rs
  if ACTIVE_LOW then
    rs = not isOn      -- ON -> false, OFF -> true
  else
    rs = isOn          -- ON -> true,  OFF -> false
  end
  redstone.setOutput(OUT, rs)
end


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
        setMachine(true)
        net.send(from, { ok = true, cmd = "ON", name = NAME, active_low = ACTIVE_LOW })

    elseif msg.cmd == "OFF" then
        setMachine(false)
        net.send(from, { ok = true, cmd = "OFF", name = NAME, active_low = ACTIVE_LOW })
    else
      net.send(from, { ok = false, err = "unknown cmd", name = NAME })
    end
  end
end

