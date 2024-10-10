local d = peripheral.find("statue_workbench")
if not fs.exists("/png.lua") or not fs.exists("/deflate.lua") or not fs.exists("/stream.lua") then
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/png.lua /png.lua")
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/deflate.lua /deflate.lua")
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/stream.lua /stream.lua")
end

local completion = require "cc.completion"

local function rgbToHex(r,g,b)
    local rgb = {r,g,b}
	local hexadecimal = '0X'

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

    print("rgbToHex: "..hexadecimal)
	return hexadecimal
end

local png = require("png")

print("Drop PNG file here")

local _, files = os.pullEvent("file_transfer")
local file = files.getFiles()[1]
local file_name = file.getName()
local handle = fs.open("/"..file_name, "wb")
local data = file.readAll()

handle.write(data)
handle.close()
file.close()
print("Received "..#data.." b")

print("Enter thickness in pixels (0-16)")
local thickness = tonumber(read()) or 1

print("Brightness (0-100)")
local brightness = (tonumber(read()) or 100)/100

print("Height Border Size (1-8 for full)")
local y_border = tonumber(read()) or 8
print("Width Border Size (1-8 for full)")
local x_border = tonumber(read()) or 8

print("Orientation")
local sides = {
    "north",
    "south",
    "east",
    "west",
    "up",
    "down"
}
local rotation = read(nil, nil, function(text) return completion.choice(text, sides) end, nil)
if rotation == "" then rotation = "north" end

local image = png("/"..file_name, nil)

local cubes = {}
for y=1, 16 do
    for x=1, 16 do
        if (x > 16-x_border or x <= x_border) or (y > 16-y_border or y <= y_border) then
            local pixel = image:get_pixel(x,y)
            if pixel then
                pixel.R = pixel.r*255
                pixel.G = pixel.g*255
                pixel.B = pixel.b*255
                pixel.A = pixel.a*255
                local pixel_hex = rgbToHex(pixel.R*brightness, pixel.G*brightness, pixel.B*brightness)
                print(x, y)
                if rotation == "south" then
                    cubes[#cubes+1] = {
                        x1=17-(x+1),
                        x2=17-x,
                        y1=17-(y+1),
                        y2=17-y,
                        z1=16-thickness,
                        z2=16,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                elseif rotation == "north" then
                    cubes[#cubes+1] = {
                        x1=17-(x+1),
                        x2=17-x,
                        y1=17-(y+1),
                        y2=17-y,
                        z1=0,
                        z2=0+thickness,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                elseif rotation == "east" then
                    cubes[#cubes+1] = {
                        x1=16-thickness,
                        x2=16,
                        y1=17-(y+1),
                        y2=17-y,
                        z1=17-(x+1),
                        z2=17-x,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                elseif rotation == "west" then
                    cubes[#cubes+1] = {
                        x1=0,
                        x2=0+thickness,
                        y1=17-(y+1),
                        y2=17-y,
                        z1=17-(x+1),
                        z2=17-x,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                elseif rotation == "down" then
                    cubes[#cubes+1] = {
                        x1=17-(y+1),
                        x2=17-y,
                        y1=0,
                        y2=0+thickness,
                        z1=17-(x+1),
                        z2=17-x,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                elseif rotation == "up" then
                    cubes[#cubes+1] = {
                        x1=17-(y+1),
                        x2=17-y,
                        y1=16-thickness,
                        y2=16,
                        z1=17-(x+1),
                        z2=17-x,
                        tint=tonumber(pixel_hex),
                        opacity=pixel.A/255
                    }
                end
            end
        end
    end
    print(string.format((y/image.height)*100, "%.1f%%"))
    sleep()
end

local to_remove = {}
for k,cube in pairs(cubes) do
    if cube.opacity <= 0 then
        to_remove[#to_remove+1] = k
    end
end
for k, value in pairs(to_remove) do
    cubes[value] = nil
end

fs.delete("/"..file_name)


while true do
    if not d.isPresent() then
        sleep()
    else
        d.setCubes(cubes)
        sleep(0.2)
    end
end