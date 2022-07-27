
cafeState = true

cafeNames = {
    "Sandra",
    "Kamel"
}

function down()
    currx,curry = term.getCursorPos()
    term.setCursorPos(currx-1,curry+1)
end
function newline()
    currx,curry = term.getCursorPos()
    term.setCursorPos(1,curry+1)
end
function write(x,y,t)
    term.setCursorPos(x,y)
    term.write(t)
end


function writeOutline()
    if cafeState then
        term.setTextColor(colors.lightBlue)
    else
        term.setTextColor(colors.lime)
    end
    term.setCursorPos(1,1)
    for i1=1, y do
        term.write("|")
        down()
    end
    term.setCursorPos(1,1)
    for i1=1, x do
        term.write("-")
    end
    term.setCursorPos(x,1)
    for i1=1, y do
        term.write("|")
        down()
    end
    term.setCursorPos(1,y)
    for i1=1, x do
        term.write("-")
    end
    write(1,1,string.char(0x07))
    write(x,1,string.char(0x07))
    write(1,y,string.char(0x07))
    write(x,y,string.char(0x07))
end
x,y = term.getSize()

while true do
    if cafeState then
        cafeName = cafeNames[1]
    else
        cafeName = cafeNames[2]
    end
    term.clear()
    term.setCursorPos((x/2)-(cafeName:len()/2),y/2)
    term.setTextColor(colors.orange)
    term.write(cafeName)
    writeOutline()
    local event, button, x, y = os.pullEvent("mouse_click")
    if button == 1 then
        cafeState = not cafeState
    end
    if button == 2 then
        term.clear()
        term.setCursorPos(1,1)
        break
    end
end