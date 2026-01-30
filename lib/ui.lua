-- lib/ui.lua
local M = {}

function M.clear()
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1, 1)
end

function M.center(y, text, fg, bg)
  local w, _ = term.getSize()
  local x = math.max(1, math.floor((w - #text) / 2) + 1)
  if bg then term.setBackgroundColor(bg) end
  if fg then term.setTextColor(fg) end
  term.setCursorPos(x, y)
  term.write(text)
  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
end

function M.box(x, y, w, h, title, fg, bg)
  fg = fg or colors.white
  bg = bg or colors.gray

  term.setBackgroundColor(bg)
  term.setTextColor(fg)

  for yy = y, y + h - 1 do
    term.setCursorPos(x, yy)
    term.write(string.rep(" ", w))
  end

  if title and #title > 0 then
    term.setCursorPos(x + 2, y)
    term.write(title)
  end

  term.setTextColor(colors.white)
  term.setBackgroundColor(colors.black)
end

return M
