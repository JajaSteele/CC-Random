local gate_list = {peripheral.find("advanced_crystal_interface")}

local monitor = peripheral.find("monitor")

monitor.setTextScale(0.5)

term.clear()
term.setCursorPos(1,1)
term.write("Testing Address:")

local gate_functions = {}

local abydos = {26,6,14,31,11,29}
local the_end = {13,24,2,19,3,30}
local nether = {27,23,4,34,12,28}

for k,v in pairs(gate_list) do
    gate_functions[k] = (function()
        while true do
            monitor.setCursorPos(1, k)
            monitor.clearLine()
            local gate = v
            for i1=1, 6 do
                monitor.setCursorPos(i1*3, k)
                symbol = math.random(1, 38)
                if symbol == abydos[i1] then
                    monitor.setTextColor(colors.yellow)
                elseif symbol == the_end[i1] then
                    monitor.setTextColor(colors.purple)
                elseif symbol == nether[i1] then
                    monitor.setTextColor(colors.red)
                else
                    monitor.setTextColor(colors.lightGray)
                end
                monitor.write(symbol)
                gate.engageSymbol(symbol)
            end
            gate.engageSymbol(0)
            sleep(0.1)
        end
    end)
end

parallel.waitForAny(table.unpack(gate_functions))