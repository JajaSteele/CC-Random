local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/a21ab5612fbea8ab13e5a3080651121896949cfb/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
    local monitor = peripheral.find('monitor')
]]

filmText = filmText..file.readAll()

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.75)

local stat, err = pcall(load(filmText))

if not stat then print(err) end
