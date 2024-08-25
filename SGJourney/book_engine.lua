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

local function write(x,y,text,bg,fg)
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
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

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

local list_of_books = {rednet.lookup("jjs_sg_addressbook")}

local merged_books = {}

for k,book_id in pairs(list_of_books) do
    rednet.send(book_id, "", "jjs_sg_sync_request")
    local attempts = 0
    local id, msg, protocol
    repeat
        id, msg, protocol = rednet.receive("jjs_sg_sync_data", 0.075)
        attempts = attempts+1
    until id == book_id or attempts >= 5
    if msg then
        for k,data in pairs(msg) do
            merged_books[#merged_books+1] = data
        end
    end
end

print("Raw: "..#merged_books)

local grouped_address = {}
local grouped_count = 0

for k, data in pairs(merged_books) do
    if not grouped_address[table.concat(data.address, "-")] then
        grouped_address[table.concat(data.address, "-")] = {data.name}
        grouped_count = grouped_count+1
    else
        grouped_address[table.concat(data.address, "-")][#grouped_address[table.concat(data.address, "-")]+1] = data.name
    end
end

print("Grouped: "..grouped_count)

while true do
    print("\nEnter your search pattern:")
    local search_match = read()
    local filtered_address = {}

    for address, names in pairs(grouped_address) do
        for k,name in pairs(names) do
            if name:lower():match(search_match) then
                filtered_address[#filtered_address+1] = {address=address, matched_name = name}
                break
            end
        end
    end

    print("Filtered: "..#filtered_address)

    local scroll = 0

    while true do
        local line_count = 0
        term.clear()

        for k,v in ipairs(filtered_address) do
            write(4, 1+line_count)
        end
    end
end