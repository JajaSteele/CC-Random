local gate_list = {peripheral.find("advanced_crystal_interface")}

local monitor = peripheral.find("monitor")

monitor.setTextScale(0.5)

term.clear()
term.setCursorPos(1,1)
term.write("Testing Address:")

local mon_win = window.create(monitor,1,1,monitor.getSize())

local gate_functions = {}

local gate_advancement = {
    1,
    1,
    1,
    1,
    1,
    1
}

local function advance()
    gate_advancement[1] = gate_advancement[1]+1
    for i1=1, 6 do
        if gate_advancement[i1] >= 38 then
            gate_advancement[i1] = 1
            gate_advancement[i1+1] = (gate_advancement[i1+1] or 0)+1
        end
    end
end

for k,v in pairs(gate_list) do
    gate_functions[k] = (function()
        while true do
            mon_win.setCursorPos(1, k)
            mon_win.clearLine()
            mon_win.setVisible(false)
            local gate = v
            local offset = 0
            for i1=1, 6 do
                mon_win.setCursorPos(i1*3, k)
                if gate_advancement[i1-1] == gate_advancement[i1] then
                    offset = offset+1
                end
                local symbol = gate_advancement[i1]+offset
                mon_win.write(symbol)
                gate.engageSymbol(symbol)
            end
            mon_win.setVisible(true)
            gate.engageSymbol(0)
            advance()
        end
    end)
end

local function monitorBar()
    local w, h = mon_win.getSize()
    while true do
        mon_win.setVisible(false)
        mon_win.setCursorPos(1, h-1)
        mon_win.clearLine()
        mon_win.write(string.format("%.2f%%", (gate_advancement[6]/38)*100))
        mon_win.setCursorPos(1, h)
        mon_win.clearLine()
        mon_win.write(string.rep("#", gate_advancement[6]/38))
        mon_win.setVisible(true)
        sleep()
    end
end

parallel.waitForAny(monitorBar, table.unpack(gate_functions))