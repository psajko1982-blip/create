package.path = "/?.lua;/lib/?.lua;" .. package.path

local net = require("net")
local log = require("log")

local function loadWorkerConfig()
  if fs.exists("config/worker.lua") then
    local ok, cfg = pcall(dofile, "config/worker.lua")
    if ok and type(cfg) == "table" then
      return cfg
    end
  end

  local lbl = os.getComputerLabel()
  if lbl and lbl ~= "" then
    return { name = lbl, output_side = "back", active_low = true }
  end

  return { name = ("worker_%d"):format(os.getComputerID()), output_side = "back", active_low = true }
end

local cfg = loadWorkerConfig()
local OUT = cfg.output_side or "back"
local NAME = cfg.name or ("worker_%d"):format(os.getComputerID())
local ACTIVE_LOW = (cfg.active_low == true)

-- Maskinläge -> redstone
-- active_low=true  => redstone ON betyder maskin OFF
-- maskin ON  -> redstone false
-- maskin OFF -> redstone true
local function setMachine(isOn)
  local rs
  if ACTIVE_LOW then
    rs = not isOn
  else
    rs = isOn
  end
  redstone.setOutput(OUT, rs)
  return rs
end

log.info("Worker online. id=" .. os.getComputerID() .. " name=" .. NAME)
log.info("Output side:", OUT, "active_low:", tostring(ACTIVE_LOW))
log.info("Listening on protocol 'factory'...")

while true do
  local from, msg = net.receive()

  if type(msg) == "table" and msg.cmd then
    local ok, err = pcall(function()
      if msg.cmd == "PING" then
        net.send(from, {
          ok = true,
          id = os.getComputerID(),
          name = NAME,
          output_side = OUT,
          active_low = ACTIVE_LOW,
        })

      elseif msg.cmd == "ON" then
        local rs = setMachine(true)
        net.send(from, { ok = true, cmd = "ON", name = NAME, redstone = rs, active_low = ACTIVE_LOW })

      elseif msg.cmd == "OFF" then
        local rs = setMachine(false)
        net.send(from, { ok = true, cmd = "OFF", name = NAME, redstone = rs, active_low = ACTIVE_LOW })

      else
        net.send(from, { ok = false, err = "unknown cmd", name = NAME })
      end
    end)

    if not ok then
      -- Krascha aldrig workers på dåliga kommandon: logga och fortsätt
      log.error("CMD failed:", tostring(err))
      net.send(from, { ok = false, err = tostring(err), name = NAME })
    end
  end
end
