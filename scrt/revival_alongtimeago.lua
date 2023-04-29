local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/d2ae612bc4fc1cc0c8790d75784ffea436c81914/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
    local monitor = peripheral.find('monitor')
]]

filmText = filmText..file.readAll()

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.75)

local stat, err = pcall(load(filmText))

if not stat then print(err) end
