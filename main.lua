-- main.lua
local function readRole()
  if fs.exists("role.txt") then
    local f = fs.open("role.txt", "r")
    local role = f.readLine()
    f.close()
    return role
  end
  return "worker"
end

local role = readRole()

if role == "master" then
  shell.run("master/app.lua")
else
  shell.run("workers/worker.lua")
end
