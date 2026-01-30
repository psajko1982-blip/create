-- install.lua (robust)
-- Hämtar filer från GitHub raw med retries + tydliga fel.

local function http_get_with_retry(url, tries)
  tries = tries or 6

  for i = 1, tries do
    local res, err = http.get(url)

    if res then
      return res
    end

    print(("HTTP fail (%d/%d): %s"):format(i, tries, tostring(err)))
    -- enkel backoff: 0.8s, 1.6s, 2.4s, ...
    sleep(0.8 * i)
  end

  return nil, "all retries failed"
end

local function download(url, path)
  print("Downloading:", url)

  local res, err = http_get_with_retry(url, 6)
  if not res then
    error("Failed to fetch " .. url .. " | " .. tostring(err))
  end

  local data = res.readAll()
  res.close()

  local dir = fs.getDir(path)
  if dir and dir ~= "" then
    fs.makeDir(dir)
  end

  local file = fs.open(path, "w")
  file.write(data)
  file.close()

  print("Saved:", path, "(" .. tostring(#data) .. " bytes)")
end

local function install()
  -- ===== CONFIG =====
  local USER   = "psajko1982-blip"
  local REPO   = "create"
  local BRANCH = "main"
  local BASE   = "https://raw.githubusercontent.com/" .. USER .. "/" .. REPO .. "/" .. BRANCH .. "/"
  -- ==================

  local FILES = {
    "startup.lua",
    "main.lua",
    "lib/log.lua",
    "lib/net.lua",
    "lib/ui.lua",
    "master/app.lua",
    "workers/worker.lua",
    "config/worker.lua",

  }

  print("== Factory deploy ==")
  print("Repo:", USER .. "/" .. REPO, "branch:", BRANCH)
  print("Files:", #FILES)
  print("")

  for i, p in ipairs(FILES) do
    print(("[%d/%d] %s"):format(i, #FILES, p))
    download(BASE .. p, p)
  end

  print("")
  print("Install complete. Rebooting...")
  sleep(1)
  os.reboot()
end

install()
