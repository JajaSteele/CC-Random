local d = peripheral.find("statue_workbench")
if not fs.exists("/png.lua") or not fs.exists("/deflatelua.lua") then
    shell.run("wget https://raw.githubusercontent.com/Didericis/png-lua/refs/heads/master/png.lua /png.lua")
    shell.run("wget https://raw.githubusercontent.com/Didericis/png-lua/refs/heads/master/deflatelua.lua /deflatelua.lua")
end

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
local thickness = tonumber(read())

print("Brightness (0-100)")
local brightness = tonumber(read())/100

local image = png("/"..file_name, nil, true, false)

local cubes = {}
for y, row in pairs(image.pixels) do
    for x, pixel in pairs(row) do
        local pixel_hex = rgbToHex(pixel.R*brightness, pixel.G*brightness, pixel.B*brightness)
        print(x, y)
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