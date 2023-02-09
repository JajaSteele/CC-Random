local pl_d = peripheral.find("playerDetector")

function front_of_pos(_posx,_posz,_rot,_dist)
    x = _posx + math.cos(_rot) * _dist
    z = _posz + math.sin(_rot) * _dist
    return {x=x,z=z}
end

print("Make the compass face toward destination,\nthen enter the distance:")
local dist = tonumber(read())

term.clear()
term.setCursorPos(1,1)

local players = pl_d.getPlayersInRange(1)
local curr_pos = pl_d.getPlayerPos(players[1])

local dist_pos = front_of_pos(curr_pos.x,curr_pos.z,curr_pos.yaw,dist)

print("Result:")
print("X: "..dist_pos.x, "Z: "..dist_pos.z)