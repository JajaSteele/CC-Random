local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/3db7a9101f748cba9bc21489e70537d02ceea0cd/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
    local monitor = peripheral.find('monitor')
]]

filmText = filmText..file.readAll()

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.75)

local stat, err = pcall(load(filmText))

if not stat then print(err) end
