local automata = peripheral.find("weakAutomata") or peripheral.find("endAutomata")

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

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

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

local width, height = term.getSize()
local fuel_limit = turtle.getFuelLimit()

if automata then
    turtle.select(1)
    term.clear()
    term.setCursorPos(1,1)
    term.write("Energy Level:")
    fill(1, 2, width, 2, colors.black, colors.gray, "\x7F")
    while true do
        local stat, num = automata.chargeTurtle()
        write(15, 1, string.format("%.1f%%", (turtle.getFuelLevel()/fuel_limit)*100), colors.black, colors.yellow)
        fill(1, 2, width*(turtle.getFuelLevel()/fuel_limit), 2, colors.red, colors.orange, "\x7F")
        write(1,3, "Added "..string.format("%.2f%%", ((num or 0)/fuel_limit)*100), colors.black, colors.white)
        if not stat then
            error(num)
        else
            if num == 0 then
                break
            end
        end
    end
end

write(1, 6, "Fully Charged! Exiting..", colors.black, colors.lime)
sleep(0.5)
term.setCursorPos(1, height)
for i1=1, 5 do
    print("")
    sleep(0.125)
end

term.setCursorPos(1, 3)