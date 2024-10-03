local d = peripheral.find("statue_workbench")

local file = io.open(".saved_statue.data", "r")
local cubes = textutils.unserialize(file:read("*a"))
file:close()

d.setCubes(cubes)