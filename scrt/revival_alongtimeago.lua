local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/352dc92cec0cb0e2de11e511d1ecb497a6c60105/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
    local monitor = peripheral.find('monitor')
]]

filmText = filmText..file.readAll()

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.75)

local stat, err = pcall(load(filmText))

if not stat then print(err) end
