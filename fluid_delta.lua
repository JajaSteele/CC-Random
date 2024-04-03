local tank = peripheral.wrap("back")

local old = 0
local new = 0

while true do
    old = new
    new = tank.tanks()[1].amount
    print(((new-old)/20).."mb/t")
    sleep(1)
end