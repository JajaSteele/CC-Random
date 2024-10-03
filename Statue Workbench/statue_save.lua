local d = peripheral.find("statue_workbench")

local curr_cubes = d.getCubes()

local file = io.open(".saved_statue.data", "w")
file:write(textutils.serialize(curr_cubes, {compact=true}))
file:close()