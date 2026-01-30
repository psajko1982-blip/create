-- master/app.lua (GUI)
package.path = "/?.lua;/lib/?.lua;" .. package.path

local net = require("net")
local log = require("log")
local ui  = require("ui")

local known = {}   -- name -> { id=, out= }
local state = {}   -- name -> "ON"|"OFF"|"?"

-- ==== DISPLAY SETUP ====
local display = term.current()

local function findMonitor()
  for _, side in ipairs(peripheral.getNames()) do
    if peripheral.getType(side) == "monitor" then
      return peripheral.wrap(side)
    end
  end
  return nil
end

local mon = findMonitor()
if mon then
  mon.setTextScale(1.0)   -- justera vid behov: 0.5–2.0
  display = mon
end

term.redirect(display)


local function discover()
  known = {}
  net.broadcast({ cmd = "PING" })

  local t0 = os.clock()
  while os.clock() - t0 < 1.2 do
    local from, msg = net.receive(0.2)
    if from and type(msg) == "table" and msg.ok and msg.name then
      known[msg.name] = { id = from, out = msg.output_side }
      if not state[msg.name] then state[msg.name] = "?" end
    end
  end
end

local function namesSorted()
  local t = {}
  for name, _ in pairs(known) do table.insert(t, name) end
  table.sort(t)
  return t
end

local function sendCmd(name, cmd)
  local row = known[name]
  if not row then return end
  net.send(row.id, { cmd = cmd })
  state[name] = cmd -- vi sätter status optimistiskt; kan förbättras med ack sen
end

local function toggle(name)
  local s = state[name] or "?"
  if s == "ON" then
    sendCmd(name, "OFF")
  else
    sendCmd(name, "ON")
  end
end

local function draw(selected)
  ui.clear()
  local w, h = term.getSize()

  ui.center(1, "FACTORY MASTER", colors.yellow)
  term.setCursorPos(1, 2)
  term.write(("ID: %d   R=refresh   Click=toggle   Q=quit"):format(os.getComputerID()))

  ui.box(1, 3, w, h - 3, " Machines ", colors.black, colors.lightGray)

  local list = namesSorted()
  local y = 4
  for i, name in ipairs(list) do
    if y > h then break end

    local id = known[name].id
    local s = state[name] or "?"
    local bg = colors.lightGray
    local fg = colors.black

    if i == selected then
      bg = colors.gray
    end

    term.setCursorPos(2, y)
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.write(string.rep(" ", w - 2))

    term.setCursorPos(3, y)
    term.write(("%-14s"):format(name))

    term.setCursorPos(18, y)
    term.write(("(id=%d)"):format(id))

    -- status badge
    local badgeBg = colors.orange
    local badgeTxt = " ? "
    if s == "ON" then badgeBg = colors.lime; badgeTxt = " ON "
    elseif s == "OFF" then badgeBg = colors.red; badgeTxt = "OFF"
    end

    term.setCursorPos(w - 6, y)
    term.setBackgroundColor(badgeBg)
    term.setTextColor(colors.black)
    term.write(badgeTxt)

    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)

    y = y + 1
  end

  term.setCursorPos(1, h)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
end

-- MAIN LOOP
log.info("Master GUI online. id=" .. os.getComputerID())
discover()

local selected = 1
local lastPing = os.clock()

while true do
  draw(selected)

  -- auto-refresh var 5:e sekund
  if os.clock() - lastPing > 5 then
    discover()
    lastPing = os.clock()
    selected = math.max(1, math.min(selected, #namesSorted()))
  end

  local ev = { os.pullEvent() }
  local e = ev[1]

  if e == "key" then
    local key = ev[2]
    if key == keys.q then
      ui.clear()
      print("Bye.")
      return
    elseif key == keys.r then
      discover()
      lastPing = os.clock()
    elseif key == keys.up then
      selected = math.max(1, selected - 1)
    elseif key == keys.down then
      selected = selected + 1
    elseif key == keys.enter then
      local list = namesSorted()
      local name = list[selected]
      if name then toggle(name) end
    end

  elseif e == "mouse_click" then
    local btn, mx, my = ev[2], ev[3], ev[4]
    -- list börjar på rad 4
    local idx = my - 3
    local list = namesSorted()
    if idx >= 1 and idx <= #list then
      selected = idx
      local name = list[selected]
      if name then toggle(name) end
    end
  end
end
