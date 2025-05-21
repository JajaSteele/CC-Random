local d = peripheral.find("statue_workbench")
if not fs.exists("/png.lua") or not fs.exists("/deflate.lua") or not fs.exists("/stream.lua") then
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/png.lua /png.lua")
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/deflate.lua /deflate.lua")
    shell.run("wget https://raw.githubusercontent.com/9551-Dev/pngLua/refs/heads/master/stream.lua /stream.lua")
end

local completion = require "cc.completion"

local png = require("png")

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

    --print("rgbToHex: "..hexadecimal)
	return hexadecimal
end

local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local sides = {
    "north",
    "south",
    "east",
    "west",
    "up",
    "down"
}

local width, height = term.getSize()
local native = term.current()
local win = window.create(native, 1,1, width, height, true)
term.redirect(win)

local thickness = 16
local brightness = 1
local rotation = 1
local light_level = 0
local auto_update = false

local auto_timer = -1

local scroll_modifier = 1

local borders = {
    x1=8,
    x2=8,
    y1=8,
    y2=8,
}

local cubes = {}

local file_name
local image

local function updateTimer()
    while true do
        if auto_timer > -1 then
            auto_timer = auto_timer-1
        end
        if auto_timer == 0 and auto_update then
            os.queueEvent("recalc_output")
        end
        sleep(0.05)
    end
end

local function renderThread()
    while true do
        os.pullEvent("redraw")
        win.setVisible(false)
        term.clear()
        fill(1,1, width, 1, colors.gray)
        write(1,1, "Panel Maker", colors.gray, colors.white)

        write(2,3, "File: "..(file_name or "No File"), colors.black, colors.yellow)
        write(2,5, "Rotation: "..sides[rotation], colors.black, colors.lightGray)
        write(2,6, "Brightness: "..string.format("%.0f" ,brightness*100).."%", colors.black, colors.lightGray)
        write(2,7, "Thickness: "..string.format("%.1f" ,thickness).."px", colors.black, colors.lightGray)

        write(2,9, "Borders Width:", colors.black, colors.yellow)
        write(3,10, "X1: "..borders.x1.."px", colors.black, colors.lightGray)
        write(3,11, "X2: "..borders.x2.."px", colors.black, colors.lightGray)
        write(3,12, "Y1: "..borders.y1.."px", colors.black, colors.lightGray)
        write(3,13, "Y2: "..borders.y2.."px", colors.black, colors.lightGray)

        write(2,15, "Light Level: "..light_level, colors.black, colors.lightGray)

        write(2,height-2, "Auto Submit: "..tostring(auto_update), colors.black, colors.orange)
        write(2,height-1, "Submit Changes", colors.black, colors.lime)
        win.setVisible(true)
    end
end

local function inputThread()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "file_transfer" then
            if file_name then
                fs.delete("/"..file_name)
            end
            local files = event[2]
            local file = files.getFiles()[1]
            file_name = file.getName()
            local handle = fs.open("/"..file_name, "wb")
            local data = file.readAll()

            handle.write(data)
            handle.close()
            file.close()

            image = png("/"..file_name, nil)

            os.queueEvent("redraw")
            if auto_update then auto_timer = 5 end
        elseif event[1] == "mouse_scroll" then
            local _, dir, x, y = table.unpack(event)
            if y == 5 then
                rotation = rotation+dir
                if rotation > #sides then
                    rotation = 1
                elseif rotation <= 0 then
                    rotation = #sides
                end
            elseif y == 6 then
                brightness = clamp(brightness-(dir/100)*scroll_modifier, 0, 2)
            elseif y == 7 then
                thickness = clamp(thickness-(dir/10)*scroll_modifier, 0.1, 16)
            elseif y == 10 then
                borders.x1 = clamp(borders.x1-(dir), 0, 8)
            elseif y == 11 then
                borders.x2 = clamp(borders.x2-(dir), 0, 8)
            elseif y == 12 then
                borders.y1 = clamp(borders.y1-(dir), 0, 8)
            elseif y == 13 then
                borders.y2 = clamp(borders.y2-(dir), 0, 8)
            elseif y == 15 then
                light_level = clamp(light_level-(dir), 0, 15)
            end
            os.queueEvent("redraw")
            if auto_update then auto_timer = 5 end
        elseif event[1] == "mouse_click" then
            local _, bt, x, y = table.unpack(event)
            if y == height-1 then
                os.queueEvent("recalc_output")
            elseif y == height-2 then
                auto_update = not auto_update
                os.queueEvent("redraw")
            end
        elseif event[1] == "key" and not event[3] then
            if event[2] == keys.leftShift then
                scroll_modifier = 10
            end
        elseif event[1] == "key_up" then
            if event[2] == keys.leftShift then
                scroll_modifier = 1
            end
        end
    end
end

local function statueThread()
    while true do
        os.pullEvent("recalc_output")
        cubes = {}

        for y=1, 16 do
            for x=1, 16 do
                if (x > 16-borders.x1 or x <= borders.x2) or (y > 16-borders.y1 or y <= borders.y2) then
                    local pixel
                    if file_name and image then
                        pixel = image:get_pixel(x,y)
                    else
                        pixel = {r=brightness, g=brightness, b=brightness, a=1}
                    end
                    if pixel then
                        pixel.R = pixel.r*255
                        pixel.G = pixel.g*255
                        pixel.B = pixel.b*255
                        pixel.A = pixel.a*255
                        local pixel_hex = rgbToHex(pixel.R*brightness, pixel.G*brightness, pixel.B*brightness)
                        if sides[rotation] == "south" then
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
                        elseif sides[rotation] == "north" then
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
                        elseif sides[rotation] == "east" then
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
                        elseif sides[rotation] == "west" then
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
                        elseif sides[rotation] == "down" then
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
                        elseif sides[rotation] == "up" then
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
            --print(string.format((y/image.height)*100, "%.1f%%"))
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

        if d.isPresent() then
            d.setCubes(cubes)
            d.setLightLevel(light_level)
        end
    end
end

local stat, err = pcall(function()
    os.queueEvent("redraw")
    parallel.waitForAll(renderThread, inputThread, statueThread, updateTimer)
end)
term.redirect(native)
if file_name then
    fs.delete("/"..file_name)
end
if not stat then
    --textutils.pagedPrint(textutils.serialise(cubes))
    error(err)
end