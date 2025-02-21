local ply = peripheral.find("playerDetector")
local function rotate_point(cx, cy, angle, px, py)
    local absangl = math.abs(angle);
    local s = math.sin(absangl * (math.pi/180));
    local c = math.cos(absangl * (math.pi/180));

    -- translate point back to origin:
    px = px - cx
    py = py - cy

    -- rotate point
    local xnew
    local ynew
    if (angle > 0) then
        xnew = px * c - py * s
        ynew = px * s + py * c
    else 
        xnew = px * c + py * s;
        ynew = -px * s + py * c;
    end

    -- translate point back:
    px = xnew + cx;
    py = ynew + cy;
    return px, py
end

local pos = ply.getPlayerPos("JajaSteele")

print("Angle: "..pos.yaw%360)
print("Pos: "..(pos.x).." "..(pos.z))

local x, z = rotate_point(pos.x, pos.z, (pos.yaw+90)%360, pos.x+10, pos.z)

print("Result: "..x.." "..z)