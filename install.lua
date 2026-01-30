-- install.lua
-- Laddar ner projektfiler från GitHub (raw) och rebootar.

local function download(url, path)
  print("Downloading:", url)

  local res = http.get(url)
  if not res then
    error("Failed to fetch " .. url)
  end

  local data = res.readAll()
  res.close()

  -- Skapa mappar om de behövs
  local dir = fs.getDir(path)
  if dir and dir ~= "" then
    fs.makeDir(dir)
  end

  local file = fs.open(path, "w")
  file.write(data)
  file.close()
end

local function install()
  -- ===== CONFIG =====
  local USER   = "psajkol982-blip"
  local REPO   = "create"
  local BRANCH = "main"   -- byt till "master" om din default-branch heter det
  local BASE   = ("https://raw.githubusercontent.com/%s/%s/%s/"):format(USER, REPO, BRANCH)
  -- ==================

  -- Alla filer som ska ner (lägg till fler här när projektet växer)
  local FILES = {
    "startup.lua",
    "main.lua",

    "lib/log.lua",
    "lib/net.lua",

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

-- Kör install direkt när du kör programmet
install()
