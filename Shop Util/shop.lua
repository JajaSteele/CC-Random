local completion = require("cc.completion")

local args = {...}

local config = {}

local shop_items = {}

local shop_cart = {}

local width, height = term.getSize()

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function getCartTotalPrice()
    local i = 0
    for k,v in pairs(shop_cart) do
        i = i + (shop_items[k].price*v)
    end
    return i
end

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

if args[1] == "setup" or not fs.exists("/price_shop.txt") then
    term.clear()
    term.setCursorPos(1,1)
    print("Welcome to the shop setup wizard!")

    sleep(2)

    for k,v in pairs(cargo_storage.list()) do
        term.clear()
        term.setCursorPos(1,1)
        print(v.name)
        term.write("Price: ")
        local old_price = ""
        if shop_items[v.name] then
            old_price = tostring(shop_items[v.name].price)
        end
        local new_price = tonumber(read(nil, nil, function(text) return completion.choice(text, {old_price}) end, old_price))

        term.write("Count: ")
        local old_count = ""
        if shop_items[v.name] then
            old_count = tostring(shop_items[v.name].price)
        end
        local new_count = tonumber(read(nil, nil, function(text) return completion.choice(text, {old_count}) end, old_count))

        shop_items[#shop_items+1] = {
            name = v.name,
            price = new_price,
            count = new_count
        }
    end

    local configfile = io.open("/price_shop.txt","w")
    configfile:write(textutils.serialise(shop_items))
    configfile:close()
else
    local configfile = io.open("/price_shop.txt","r")
    shop_items = textutils.unserialise(configfile:read("*a"))
    configfile:close()
end

if args[1] == "repl" then
    local text = [[input = peripheral.wrap("]]..config.input_storage..[[") storage = peripheral.wrap("]]..config.cargo_storage..[[")]]
    for i1=1, #text do
        os.queueEvent("char", text:sub(i1,i1))
    end
    os.queueEvent("key", keys.enter, false)
    shell.execute("lua")
    return
end

term.clear()

fill(1, 1, width, 1, colors.gray, colors.black, " ")
write(1,1, "Shop", colors.gray, colors.black)

local shifting = false

local scroll = 0

local text_scroll = 0

local cart_column = 2
local name_column = cart_column+3+3

local name_width = 28

local count_column = name_column+name_width+4

local price_column = count_column+4+3

local function drawMain()
    while true do
        write(cart_column-1, 2, "Cart", colors.black, colors.orange)

        write(name_column-2, 2, "|", colors.black, colors.red)
        write(name_column-1, 2, "Item Name", colors.black, colors.orange)

        write(count_column-2, 2, "|", colors.black, colors.red)
        write(count_column-1, 2, "Count", colors.black, colors.orange)

        write(price_column-2, 2, "|", colors.black, colors.red)
        write(price_column-1, 2, "Price", colors.black, colors.orange)

        for i1=1, height-3 do
            local entry = shop_items[i1+scroll]
            local print_y = 2+i1
            if entry then
                local name = entry.name
                fill(1, print_y, name_column-3, print_y, colors.black, colors.yellow, " ")
                if shifting then
                    write(cart_column-1, print_y, entry.count*(shop_cart[i1+scroll] or 0), colors.black, colors.yellow)
                else
                    write(cart_column, print_y, "x"..(shop_cart[i1+scroll] or 0), colors.black, colors.yellow)
                end

                write(name_column-2, print_y, "|", colors.black, colors.gray)

                local scroll = 1+(text_scroll%(#name-name_width))
                if #name > name_width then
                    write(name_column, print_y, name:sub(scroll, scroll+name_width), colors.black, colors.white)
                else
                    write(name_column, print_y, name, colors.black, colors.white)
                end

                write(count_column-2, print_y, "|", colors.black, colors.gray)

                write(count_column, print_y, entry.count, colors.black, colors.lightBlue)


                write(price_column-2, print_y, "|", colors.black, colors.gray)

                write(price_column, print_y, "\xA4", colors.black, colors.lime)
                write(price_column+1, print_y, entry.price, colors.black, colors.lightBlue)
            end
        end

        write(price_column-3, height, "Total Price:", colors.gray, colors.white, true)
        write(price_column-1, height, "\xA4", colors.gray, colors.lime, false)
        write(price_column, height, getCartTotalPrice(), colors.gray, colors.lightBlue, false)

        sleep(0.5)
        text_scroll = text_scroll + 1
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
                if shifting then
                    write(cart_column-1, y, entry.count*(shop_cart[entry_num] or 0), colors.black, colors.yellow)
                else
                    write(cart_column, y, "x"..(shop_cart[entry_num] or 0), colors.black, colors.yellow)
                end
            end
        elseif event[1] == "key" then
            if event[2] == keys.leftShift then
                shifting = true
            end
        elseif event[1] == "key_up" then
            if event[2] == keys.leftShift then
                shifting = false
            end
        end
    end
end

parallel.waitForAny(drawMain, inputMain)