function clear()
    term.clear()
    term.setCursorPos(1,1)
end

nameToNum = {
    zero="0",
    one="1",
    two="2",
    three="3",
    four="4",
    five="5",
    six="6",
    seven="7",
    eight="8",
    nine="9",
    numPad0="0",
    numPad1="1",
    numPad2="2",
    numPad3="3",
    numPad4="4",
    numPad5="5",
    numPad6="6",
    numPad7="7",
    numPad8="8",
    numPad9="9"
}

function changeColor(c)
    if c then
        if c["fg"] then
            term.setTextColor(c["fg"])
        end
        if c["bg"] then
            term.setBackgroundColor(c["bg"])
        end
    end
end

function numRead(p,s,cp,cv,cs)
    local inputText = ""
    local cX,cY = term.getCursorPos()
    local oldBG = term.getBackgroundColor()
    local oldFG = term.getTextColor()
    while true do
        term.setCursorPos(cX,cY)
        term.clearLine()
        if p ~= nil then
            changeColor(cp)
            term.write(p)
        end
        changeColor(cv)
        term.write(inputText)
        if s ~= nil then
            changeColor(cs)
            term.write(s)
        end

        local _, key, is_held = os.pullEvent("key")
        charname = keys.getName(key)
        char = nameToNum[charname]

        if char and char:gsub("%D","") ~= "" then
            inputText = inputText..char
        end
        if charname == "backspace" then
            inputText = inputText:sub(1,inputText:len()-1)
        end
        term.setTextColor(oldFG)
        term.setBackgroundColor(oldBG)
        if charname == "enter" or charname == "numPadEnter" then
            break
        end
    end
    return tonumber(inputText)
end

function boolRead(p,s,cp,cv,cs)
    local inputText = ""
    local cX,cY = term.getCursorPos()
    local oldBG = term.getBackgroundColor()
    local oldFG = term.getTextColor()
    while true do
        term.setCursorPos(cX,cY)
        term.clearLine()
        if p ~= nil then
            changeColor(cp)
            term.write(p)
        end
        changeColor(cv)
        term.write(inputText)
        if s ~= nil then
            changeColor(cs)
            term.write(s)
        end

        local _, key, is_held = os.pullEvent("key")
        charname = keys.getName(key)

        if charname == "y" or charname == "n" and inputText:len() == 0 then
            inputText = inputText..charname
        end
        if charname == "backspace" then
            inputText = inputText:sub(1,inputText:len()-1)
        end
        term.setTextColor(oldFG)
        term.setBackgroundColor(oldBG)
        if charname == "enter" or charname == "numPadEnter" then
            break
        end
    end
    if inputText == "y" then
        return true
    else
        return false
    end
end


print("Hello, welcome to mine.lua by JJS-Corp")
os.sleep(0.5)
clear()
print("--Size Settings--\n")
mineLength = numRead("Length (Forward): "," blocks",nil,{fg=colors.lightGray},{fg=colors.lightGray})
print("\n")

mineWidth = numRead("Width (Right): "," blocks",nil,{fg=colors.lightGray},{fg=colors.lightGray})
print("\n")

mineHeight = numRead("Height (Down): "," blocks",nil,{fg=colors.lightGray},{fg=colors.lightGray})
print("\n")

mineReturn = boolRead("Return after finished? "," (y/n)",nil,{fg=colors.lightGray},nil)
print("\n")

for i1=1, mineHeight do
    for i2=1, mineWidth do
        for i3=1, mineLength do
            turtle.digDown()
            if i3 ~= mineLength then
                turtle.dig()
                turtle.forward()
            end
        end
        if mineWidth > 1 and i2 ~= mineWidth then
            if not (i2 % 2 == 0) then
                turtle.turnRight()
                turtle.dig()
                turtle.forward()
                turtle.turnRight()
            else
                turtle.turnLeft()
                turtle.dig()
                turtle.forward()
                turtle.turnLeft()
            end
        end
    end
    if (mineWidth % 2 == 0) then
        turtle.turnRight()
        for k1=1, mineWidth-1 do
            turtle.forward()
        end
        turtle.turnRight()
    else
        for k1=1, mineLength-1 do
            turtle.back()
        end
        turtle.turnLeft()
        for k1=1, mineWidth-1 do
            turtle.forward()
        end
        turtle.turnRight()
    end
    if mineHeight > 1 then
        turtle.down()
    end
end
if mineReturn then
    for i1=1, mineHeight do
        turtle.up()
    end
    turtle.back()
end