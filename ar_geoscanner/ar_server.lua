local player_detector = peripheral.find("playerDetector")

local ar = peripheral.find("arController")

local vector = require("Vector")
local matrix = require("Matrix")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
end

local full_data = {
    data={
        {
            name="test_element",
            color=0xFF0000,
            blocks = {
                {pos={x=5,y=0,z=0}}
            }
        }
    },
    pos={x=-224, y=64, z=-393}
}
local geo_data = {}
local ready = false
local player_pos = {}
local player_name = ""

local function convertData(full_data)
    local result_data = {}

    local og_x, og_y, og_z = full_data.pos.x, full_data.pos.y, full_data.pos.z
    for k, entry in pairs(full_data.data) do
        local new_blocks = {}
        for k, block in pairs(entry.blocks) do
            new_blocks[#new_blocks+1] = {
                pos={
                    x=og_x+block.pos.x,
                    y=og_y+block.pos.y,
                    z=og_z+block.pos.z
                }
            }
        end
        result_data[#result_data+1] = {
            name=entry.name,
            color=entry.color,
            blocks=new_blocks
        }
    end
    return result_data
end

local function front_of_pos(_pos, pitch, yaw, _dist)
    local _rot = vector.vec3((math.sin(yaw)*math.cos(pitch))*-1, math.sin(pitch)*-1, math.cos(yaw)*math.cos(pitch) )
    _rot = _rot * _dist
    _pos = _pos + _rot
    return _pos
end

geo_data = convertData(full_data)

local function playerSetterThread()
    while true do
        local event, username = os.pullEvent("playerClick")

        player_name = username
        print("Set user to '"..username.."'")
    end
end

local function playerPosThread()
    while true do
        local new_pos = player_detector.getPlayerPos(player_name)
        if new_pos then
            player_pos = new_pos
            ready = true
        end
        sleep()
    end
end

local function dataReceiverThread()
    while true do
        local id, msg, prot = rednet.receive("jjs_ar_fulldata")

        if type(msg) == "table" and msg.data and msg.pos then
            geo_data = msg.data
        end
    end
end



local function arDrawingThread()
    while true do
        if ready then
            local camera_pos = vector.vec3(player_pos.x, player_pos.y+player_pos.eyeHeight, player_pos.z)
            local front_camera_pos = front_of_pos(camera_pos, math.rad(player_pos.pitch), math.rad(player_pos.yaw+180), 20)
            --COmplicated math stuff please just kill me i hate this
            local matproj = matrix.perspective(
                100,
                (1920/3)/(1080/3),
                0.1,
                (1136/1.1566)*2
            )
            local matlookat = matrix.lookat(
                camera_pos,
                front_camera_pos,
                vector.vec3(0,1,0)
            )
            --print(matlookat)
            
            --matlookat = matlookat + matrix.translate(camera_pos.x, camera_pos.y, camera_pos.z)
            --print(matlookat)

            --print("P "..player_pos.x, player_pos.y, player_pos.z)

            local matviewproj = matlookat * matproj
            ar.clear()
            for k,data in pairs(geo_data) do
                for k,block in pairs(data.blocks) do
                    --print("B "..block.pos.x, block.pos.y, block.pos.z)
                    local pos = block.pos
                    local screen_pos = matviewproj * vector.vec4(pos.x, pos.y, pos.z, 1.0)
                    screen_pos.x = (screen_pos.x / screen_pos.w)+camera_pos.x
                    screen_pos.y = (screen_pos.y / screen_pos.w)+camera_pos.y
                    screen_pos.z = (screen_pos.z / screen_pos.w)+camera_pos.z

                    ar.drawString((screen_pos.x).." "..(screen_pos.y).." "..(screen_pos.z), 50, 50, 0xFFFFFF)

                    local screen_pos_2 = {
                        x=((1920/2)+((screen_pos.x)*(1920/2)))/3,
                        y=((1080/2)+((screen_pos.y)*(1080/2)))/3
                    }

                    if tostring(screen_pos_2.x) ~= "nan" and tostring(screen_pos_2.y) ~= "nan" and screen_pos.z > 0 then
                        ar.drawString("X"..screen_pos_2.x.." Y"..screen_pos_2.y, 50, 70, 0xFFFFFF)
                        ar.fillCircle(screen_pos_2.x, screen_pos_2.y, 5, data.color)
                    end
                end
            end
        end
        sleep()
    end
end

--local stat, err = pcall(function()
    parallel.waitForAny(arDrawingThread, playerPosThread, playerSetterThread)
--end)

ar.clear()

--if not stat then error(err) end