local completion = require("cc.completion")
local shellcompletion = require "cc.shell.completion"
local complete = shellcompletion.build(
  { shellcompletion.choice, { "config", "setup", "repl", "safe" } }
)
shell.setCompletionFunction("shop.lua", complete)

local args = {...}

local config = {}

local shop_items = {}

local shop_items_count = {}

local shop_cart = {}

local width, height = term.getSize()

local function playSound(name, pitch, volume)
    local speaker = peripheral.find("speaker")
    if speaker then
        speaker.playSound(name, volume, pitch)
    end
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local startup_file = io.open("startup.lua", "w")
startup_file:write("shell.execute('shop.lua')")
startup_file:close()

local function fill(x,y,x1,y1,bg,fg,char)
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
end

local function rect(x,y,x1,y1,bg,fg,char)
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
end

local function write(x,y,text,bg,fg, rightAlign)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    if rightAlign then
        term.setCursorPos(x-(#text-1),y)
    else
        term.setCursorPos(x,y)
    end
    
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

if args[1] == "config" or not fs.exists("/config_shop.txt") then
    print("Welcome to the configuration wizard!")
    print("Emerald Input Storage:")
    config.input_storage = read(nil,nil, completion.peripheral)

    print("Cargo Storage:")
    config.cargo_storage = read(nil,nil, completion.peripheral)

    print("Emerald Safe Storage:")
    config.emerald_safe = read(nil,nil, completion.peripheral)

    print("Output Storage:")
    config.output_storage = read(nil,nil, completion.peripheral)

    print("Shop Secure Code:")
    config.secure_code = read(nil,nil)

    local configfile = io.open("/config_shop.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
else
    local configfile = io.open("/config_shop.txt","r")
    config = textutils.unserialise(configfile:read("*a"))
    configfile:close()
end

local input_storage = peripheral.wrap(config.input_storage)
local cargo_storage = peripheral.wrap(config.cargo_storage)
local emerald_safe = peripheral.wrap(config.emerald_safe)
local output_storage = peripheral.wrap(config.output_storage)

local function findItem(storage, item_name)
    local total_count = 0
    local found = {}
    for k,v in pairs(storage.list()) do
        if v.name == item_name then
            found[#found+1] = {
                slot=k,
                item=v
            }
            total_count = total_count + v.count
        end
    end
    return found, total_count
end

local function moveItem(from, to, name, count, noisy)
    local moved = 0
    repeat
        local item = findItem(from, name)[1]
        if not item then
            return false, "Item could not be found"
        end
        local res = from.pushItems(peripheral.getName(to), item.slot, count-moved)
        moved = moved + res
        if res == 0 then
            fill(1, height, width/2, height, colors.gray, colors.black, " ")
            write(1,height, "STANDBY! Can't move item!", colors.gray, colors.orange)
        end
        if noisy then
            playSound("block.lever.click", (moved/count)*2, 1)
        end
    until moved == count
    playSound("entity.player.levelup", 1.5, 1)
    return true
end

local function getCartTotalPrice()
    local i = 0
    for k,v in pairs(shop_cart) do
        i = i + (shop_items[k].price*v)
    end
    return i
end

local function updateShopCount()
    for k,v in pairs(shop_items) do
        local _, count = findItem(cargo_storage, v.name)
        shop_items_count[k] = count or 0
    end
end

local function getShopItem(name)
    for k,v in pairs(shop_items) do
        if v.name == name then
            return v
        end
    end
    return {}
end

if args[1] == "setup" or not fs.exists("/price_shop.txt") then
    local new_shop_items = {}
    if fs.exists("/price_shop.txt") then
        local configfile = io.open("/price_shop.txt","r")
        shop_items = textutils.unserialise(configfile:read("*a"))
        configfile:close()
    end
    term.clear()
    term.setCursorPos(1,1)
    print("Welcome to the shop setup wizard!")

    sleep(2)

    for k,v in pairs(cargo_storage.list()) do
        term.clear()
        term.setCursorPos(1,1)
        print(v.name)
        term.write("Price: ")

        local shop_item = getShopItem(v.name)

        local old_price = ""
        if shop_item then
            old_price = tostring(shop_item.price)
        end
        local new_price = tonumber(read(nil, nil, function(text) return completion.choice(text, {old_price}) end, old_price))

        term.write("Count: ")
        local old_count = ""
        if shop_item then
            old_count = tostring(shop_item.count)
        end
        local new_count = tonumber(read(nil, nil, function(text) return completion.choice(text, {old_count}) end, old_count))

        new_shop_items[#new_shop_items+1] = {
            name = v.name,
            price = new_price,
            count = new_count
        }
    end

    shop_items = new_shop_items

    local configfile = io.open("/price_shop.txt","w")
    configfile:write(textutils.serialise(shop_items))
    configfile:close()
else
    local configfile = io.open("/price_shop.txt","r")
    shop_items = textutils.unserialise(configfile:read("*a"))
    configfile:close()
end

if args[1] == "repl" then
    local text = [[input = peripheral.wrap("]]..config.input_storage..[[") storage = peripheral.wrap("]]..config.cargo_storage..[[") safe = peripheral.wrap("]]..config.emerald_safe..[[") output = peripheral.wrap("]]..config.output_storage..[[")]]
    for i1=1, #text do
        os.queueEvent("char", text:sub(i1,i1))
    end
    os.queueEvent("key", keys.enter, false)
    shell.execute("lua")
    return
end

if args[1] == "safe" then
    print("Enter Code:")
    local code = read("*")
    if code == config.secure_code then
        print("Select Mode:")
        print("1. Eject All Emeralds")
        print("2. Inject All Emeralds")

        local selected = tonumber(read())
        if not selected then
            error("Invalid Selection")
        else
            if selected == 1 then
                local _, emerald_count = findItem(emerald_safe, "minecraft:emerald")
                local stat, err = moveItem(emerald_safe, input_storage, "minecraft:emerald", emerald_count, true)
                if not stat then error(err) end
                return
            elseif selected == 2 then
                local _, emerald_count = findItem(input_storage, "minecraft:emerald")
                local stat, err = moveItem(input_storage, emerald_safe, "minecraft:emerald", emerald_count, true)
                if not stat then error(err) end
                return
            end
        end
    else
        error("Invalid Code!")
    end
end

term.clear()

fill(1, 1, width, 1, colors.gray, colors.black, " ")
write(1,1, "Shop", colors.gray, colors.lightGray)

fill(1, height, width, height, colors.gray, colors.black, " ")

local shifting = false
local ctrl_down = false

local scroll = 0

local text_scroll = 0

local cart_column = 2
local name_column = cart_column+3+3

local name_width = 28

local count_column = name_column+name_width+4

local price_column = count_column+4+3

local error_cooldown = 0

local filter = ""

local filter_input = false

local edit_mode = false

updateShopCount()

term.setPaletteColor(colors.blue, 0x2233AA)

local function drawMain()
    while true do
        if not filter_input then
            fill(1, 2, width, 2, colors.black, colors.orange)
            write(cart_column-1, 2, "Cart", colors.black, colors.orange)

            write(name_column-2, 2, "|", colors.black, colors.red)
            write(name_column-1, 2, "Item Name ["..filter.."]", colors.black, colors.orange)

            write(count_column-2, 2, "|", colors.black, colors.red)
            write(count_column-1, 2, "Count", colors.black, colors.orange)

            write(price_column-2, 2, "|", colors.black, colors.red)
            write(price_column-1, 2, "Price", colors.black, colors.orange)
        end

        for i1=1, height-3 do
            local entry = shop_items[i1+scroll]
            local print_y = 2+i1
            fill(1, print_y, width, print_y, colors.black, colors.white, " ")
            if entry then
                local name = entry.name..((shifting and " (x16)") or "")

                local item_bg = colors.black
                if filter ~= "" and entry.name:match(filter) then
                    item_bg = colors.blue
                end

                fill(1, print_y, name_column-3, print_y, colors.black, colors.yellow, " ")
                if not ctrl_down then
                    write(cart_column-1, print_y, entry.count*(shop_cart[i1+scroll] or 0), colors.black, (((shop_items_count[i1+scroll] or 0) >= (shop_cart[i1+scroll] or 0)*shop_items[i1+scroll].count) and colors.yellow) or colors.red)
                else
                    write(cart_column, print_y, "x"..(shop_cart[i1+scroll] or 0), colors.black, (((shop_items_count[i1+scroll] or 0) >= (shop_cart[i1+scroll] or 0)*shop_items[i1+scroll].count) and colors.yellow) or colors.red)
                end

                write(name_column-2, print_y, "|", colors.black, colors.gray)

                local draw_scroll = 1+(text_scroll%(#name-name_width))
                if #name > name_width then
                    write(name_column, print_y, name:sub(draw_scroll, draw_scroll+name_width), item_bg, (((i1+scroll)%2 == 0) and colors.white) or colors.lightGray)
                else
                    write(name_column, print_y, name, item_bg, (((i1+scroll)%2 == 0) and colors.white) or colors.lightGray)
                end

                write(count_column-2, print_y, "|", colors.black, colors.gray)


                write(count_column, print_y, entry.count*((shifting and 16) or 1), colors.black, colors.lightBlue)


                write(price_column-2, print_y, "|", colors.black, colors.gray)

                write(price_column, print_y, "\xA4", colors.black, colors.lime)
                write(price_column+1, print_y, entry.price*((shifting and 16) or 1), colors.black, colors.lightBlue)
            end
        end

        local _, emerald_count = findItem(input_storage, "minecraft:emerald")
        local total_price = getCartTotalPrice()

        write(price_column-3, height, "Total Price:", colors.gray, colors.white, true)
        write(price_column-1, height, "\xA4", colors.gray, colors.lime, false)
        write(price_column, height, total_price.."    ", colors.gray, ((total_price <= emerald_count and colors.lightBlue) or colors.red), false)

        if error_cooldown <= 0 then
            fill(1, height, (width/1.5)-2, height, colors.gray, colors.black, " ")

            write(1,height, "[- Finish Order -]", colors.gray, colors.lime)
        else
            error_cooldown = error_cooldown-1
        end

        sleep(0.1)

        text_scroll = text_scroll + 0.25
        if text_scroll > 5000 then
            text_scroll = 0
        end
    end
end

local function inputMain()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "mouse_click" then
            local button, x, y = event[2], event[3], event[4]
            if y == height then
                local errored = false
                local _, total_emerald_count = findItem(input_storage, "minecraft:emerald")
                local total_price = getCartTotalPrice()

                if total_price <= total_emerald_count then
                    write(width/2, 1, "Working..", colors.gray, colors.lime)
                    for k,v in pairs(shop_cart) do
                        if v > 0 then
                            local shop_item = shop_items[k]
                            local emerald_items, emerald_count = findItem(input_storage, "minecraft:emerald")
                            local emerald_item = emerald_items[1]
                            local sold_items, sold_count = findItem(cargo_storage, shop_item.name)
                            local sold_item = sold_items[1]
                            if sold_item and emerald_item then
                                if emerald_count >= (shop_item.price*v) and sold_count >= (shop_item.count*v) then
                                    local stat, err = moveItem(input_storage, emerald_safe, "minecraft:emerald", shop_item.price*v)
                                    if not stat then
                                        fill(1, height, width/2, height, colors.gray, colors.black, " ")
                                        write(1,height, "/!\\ "..err, colors.gray, colors.orange)
                                        error_cooldown = 10
                                        errored = true
                                        break
                                    end
                                    local stat2, err2 = moveItem(cargo_storage, output_storage, shop_item.name, shop_item.count*v)
                                    if not stat2 then
                                        fill(1, height, width/2, height, colors.gray, colors.black, " ")
                                        write(1,height, "/!\\ "..err2, colors.gray, colors.orange)
                                        error_cooldown = 10
                                        errored = true
                                        break
                                    end

                                    if stat and stat2 then
                                        shop_cart[k] = 0
                                    end
                                else
                                    fill(1, height, width/2, height, colors.gray, colors.black, " ")
                                    write(1,height, "/!\\ Invalid Count!", colors.gray, colors.red)
                                    error_cooldown = 10
                                    errored = true
                                end
                            else
                                fill(1, height, width/2, height, colors.gray, colors.black, " ")
                                write(1,height, "/!\\ Item Unavailable", colors.gray, colors.red)
                                error_cooldown = 10
                                errored = true
                            end
                        end
                    end
                    if not errored then
                        playSound("entity.player.levelup")
                    end
                    fill(width/2, 1, width, 1, colors.gray, colors.black, " ")
                else
                    fill(1, height, width/2, height, colors.gray, colors.black, " ")
                    write(1,height, "/!\\ Not enough emeralds!", colors.gray, colors.orange)
                    error_cooldown = 10
                end
            elseif y == 2 then
                if x > name_column and x < count_column-2 then
                    if button == 1 then
                        filter_input = true
                        fill(name_column-1, 2, count_column-2, 2, colors.black, colors.blue, " ")
                        term.setCursorPos(name_column, 2)
                        filter = read(nil, nil, function(text) return completion.choice(text, {"filter"}) end, filter)
                        filter_input = false
                    else
                        filter = ""
                    end
                end
            elseif y > 2 then
                local entry_num = (y-2)+scroll
                local entry = shop_items[entry_num]

                if entry then
                    local multiplier = 1
                    if shifting then multiplier = 16 end

                    if button == 1 then
                        shop_cart[entry_num] = clamp((shop_cart[entry_num] or 0) + multiplier, 0, 64)
                    elseif button == 2 then
                        shop_cart[entry_num] = clamp((shop_cart[entry_num] or 0) - multiplier, 0, 64)
                    end
                    fill(1, y, name_column-3, y, colors.black, colors.black, " ")
                    if not ctrl_down then
                        write(cart_column-1, y, entry.count*(shop_cart[entry_num] or 0), colors.black, (((shop_items_count[entry_num] or 0) >= (shop_cart[entry_num] or 0)*shop_items[entry_num].count) and colors.yellow) or colors.red)
                    else
                        write(cart_column, y, "x"..(shop_cart[entry_num] or 0), colors.black, (((shop_items_count[entry_num] or 0) >= (shop_cart[entry_num] or 0)*shop_items[entry_num].count) and colors.yellow) or colors.red)
                    end
                end
            end
        elseif event[1] == "key" then
            if event[2] == keys.leftShift then
                shifting = true
            end
            if event[2] == keys.leftCtrl then
                ctrl_down = true
            end
            if event[2] == keys.e and ctrl_down and shifting then
                edit_mode = true
                fill(1, height, width/2, height, colors.gray, colors.black, " ")
                write(1,height, "/!\\ EDIT MODE", colors.gray, colors.orange)
                error_cooldown = 10

                term.setCursorPos(1,1)
                term.write("SP: ")
                local code = read("*")

                if code == config.secure_code then
                    local event, button, x_two, y_two = os.pullEvent("mouse_click")
                    if y_two > 2 then
                        local entry_num = (y_two-2)+scroll
                        local entry = shop_items[entry_num]

                        term.setCursorPos(price_column, 1)
                        local new_price = tonumber(read(nil, nil, function(text) return completion.choice(text, {tostring(entry.price)}) end, tostring(entry.price)))
                        term.setCursorPos(count_column, 1)
                        local new_count = tonumber(read(nil, nil, function(text) return completion.choice(text, {tostring(entry.count)}) end, tostring(entry.count)))


                        shop_items[entry_num] = {
                            price = new_price,
                            count = new_count,
                            name = entry.name
                        }

                        local configfile = io.open("/price_shop.txt","w")
                        configfile:write(textutils.serialise(shop_items))
                        configfile:close()

                        os.reboot()
                    end
                end
            end
        elseif event[1] == "key_up" then
            if event[2] == keys.leftShift then
                shifting = false
            end
            if event[2] == keys.leftCtrl then
                ctrl_down= false
            end
        elseif event[1] == "mouse_scroll" then
            scroll = clamp(scroll+event[2], 0, clamp(#shop_items-(height-3), 0, #shop_items))
        end
    end
end

local function updateShopList()
    while true do
        updateShopCount()
        sleep(30)
    end
end

local stat_main, err_main = pcall(function()
    while true do
        local stat, err = pcall(function()
            parallel.waitForAny(drawMain, inputMain, updateShopList)
        end)
        if not stat then
            if err == "Terminated" then
                term.clear()
                term.setCursorPos(1,height/2)
                print("Enter Security Code:")
                local code = read("*")
                if code == config.secure_code then
                    break
                else
                    os.reboot()
                end
            else
                error(err)
            end
        end
    end
end)

if not stat_main then 
    if err_main == "Terminated" then
        os.reboot()
    else
        error(err_main)
    end
else
    term.clear()
    term.setCursorPos(1,1)
    print("Secure Code Accepted.")
end

-- test