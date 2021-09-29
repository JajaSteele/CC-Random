if fs.exists("/rscheck/programs.lua") == false then
    if fs.exists("/rscheck") == false then
        fs.makeDir("/rscheck")
    end
    pgfile1 = fs.open("/rscheck/programs.lua", "w")
    pgfile1.write([[
local args = {...}
if args[1] ~= nil then
    if args[1] == "bottom" then -- Bottom Start
    end -- Bottom End

    if args[1] == "top" then -- Top Start
    end -- Top End

    if args[1] == "back" then -- Back Start
    end -- Back End

    if args[1] == "front" then -- Front Start
    end -- Front End

    if args[1] == "right" then -- Right Start
    end -- Right End

    if args[1] == "left" then -- Left Start
    end -- Left End
else
    print("Error! No side argument! Usage: rscheck/programs.lua <side>")
end
    ]])
    pgfile1.close()
end

function runSideProgram(x1)
    if x1 ~= nil then
        shell.run("/rscheck/programs.lua "..x1)
    end
    coroutine.yield()
end

while true do
    os.pullEvent("redstone")
    inputs1 = {}
    term.clear()
    term.setCursorPos(1,1)
    for i = 1, #rs.getSides() do
        side1 = rs.getSides()[i]
        table.insert(inputs1,rs.getInput(side1))
        term.setCursorPos(1,i)
        if rs.getInput(side1) then
            term.setTextColor(colors.lime)
        else
            term.setTextColor(colors.red)
        end
        term.write(tostring(rs.getInput(side1)))
        term.write(" > "..rs.getSides()[i])
        if rs.getInput(side1) then
            parallel.waitForAny(runSideProgram(side1))
        end
    end
end