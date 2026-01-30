-- lib/log.lua
local M = {}

function M.info(...)
  print("[INFO]", ...)
end

function M.warn(...)
  print("[WARN]", ...)
end

function M.err(...)
  print("[ERR ]", ...)
end

return M
