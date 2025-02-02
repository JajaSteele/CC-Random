local phyto_list = {peripheral.find("thermal:machine_insolator")}
local drawer = peripheral.find("functionalstorage:framed_1")
local completion = require("cc.completion")

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

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

term.clear()
term.setCursorPos(1,1)
local width, height = term.getSize()

print("Select a mode:")
print("1. Import seeds")
print("2. Export seeds")

local mode = tonumber(read())

if mode == 1 then
    term.clear()
    term.setCursorPos(1,1)
    write(1,2, "[")
    write(width,2, "]")

    local current_count = (drawer.getItemDetail(1) or {count=-1}).count
    
    local thread_test = {}

    local available_phytos = {}
    local progress = 0
    for k, phyto in pairs(phyto_list) do
        thread_test[#thread_test+1] = function ()
            local item = phyto.getItemDetail(1)
            if not item then
                available_phytos[#available_phytos+1] = phyto
            end
            progress=progress+1
            fill(2,2,1+(width*(progress/#phyto_list))-2,2, colors.black, colors.blue, "#")
            write(1,1, "Scanning for free machines.. ("..progress.."/"..(#phyto_list)..")")
            sleep(0.1)
        end
    end

    parallel.waitForAll(table.unpack(thread_test))

    term.setCursorPos(1,4)
    print("Available machines: "..#available_phytos)

    print("Confirm import? (y/n)")
    if #available_phytos < current_count then
        print("(Warning, not enough available machines to import all)")
    end
    local confirm = read():lower()

    if confirm == "y" or confirm == "yes" or confirm == "true" or confirm == "1" then
        term.clear()
        term.setCursorPos(1,1)
        print("Importing seeds..")
        write(1,2, "[")
        write(width,2, "]")

        local transfer_progress = 0
        for k,phyto in pairs(available_phytos) do
            local stat = phyto.pullItems(peripheral.getName(drawer), 1, 1, 1)
            if stat > 0 then 
                transfer_progress = transfer_progress+1
            end
            fill(2,2,1+(width*(transfer_progress/#available_phytos))-2,2, colors.black, colors.blue, "#")
            if transfer_progress >= current_count then
                break
            end
        end
        term.setCursorPos(1,4)
        print("Finished!")
    end
elseif mode == 2 then
    term.clear()
    term.setCursorPos(1,1)

    if drawer.getItemDetail(1) then
        print("Warning, items still inside drawer!")
        sleep(2)
        term.clear()
        term.setCursorPos(1,1)
    end

    write(1,2, "[")
    write(width,2, "]")

    local phyto_map = {}

    local thread_test = {}

    local used_phytos = 0
    local item_types_temp = {}
    local progress = 0
    for k, phyto in pairs(phyto_list) do
        thread_test[#thread_test+1] = function ()
            local item = phyto.getItemDetail(1)
            if item then
                if not phyto_map[item.name] then
                    phyto_map[item.name] = {phyto}
                else
                    phyto_map[item.name][#phyto_map[item.name]+1] = phyto
                end
                used_phytos = used_phytos + 1
                item_types_temp[item.name] = 1
            end
            progress=progress+1
            fill(2,2,1+(width*(progress/#phyto_list))-2,2, colors.black, colors.blue, "#")
            write(1,1, "Scanning machines.. ("..progress.."/"..(#phyto_list)..")")
        end
    end

    parallel.waitForAll(table.unpack(thread_test))

    local item_types = {}
    for name, v  in pairs(item_types_temp) do
        item_types[#item_types+1] = name
    end

    term.setCursorPos(1,4)
    print("Used machines: "..used_phytos)
    print("Different seed types: "..#item_types)

    print("Select a seed to export:")
    local selected = read(nil, nil, function(text) return completion.choice(text, item_types) end, "")
    local selected_data = phyto_map[selected] or {}

    print("Select an amount to export:")
    local export_size = tonumber(read(nil, nil, function(text) return completion.choice(text, {tostring(#selected_data)}) end, tostring(#selected_data))) or #selected_data
    if selected_data then
        term.clear()
        term.setCursorPos(1,1)
        print("Exporting seeds..")
        write(1,2, "[")
        write(width,2, "]")

        local transfer_progress = 0
        for k,phyto in pairs(selected_data) do
            local stat = phyto.pushItems(peripheral.getName(drawer), 1, 1, 1)
            if stat > 0 then 
                transfer_progress = transfer_progress+1
            end
            fill(2,2,1+(width*(transfer_progress/export_size))-2,2, colors.black, colors.blue, "#")
            if transfer_progress >= export_size then
                break
            end
        end
        term.setCursorPos(1,4)
        print("Finished! Exported "..transfer_progress.." seeds!")
    end
end