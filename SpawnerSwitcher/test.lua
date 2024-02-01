local block = peripheral.find("blockReader")

local function pulseColor(side, color, time)
    rs.setBundledOutput(side, color)
    sleep(time)
    rs.setBundledOutput(side, 0)
    sleep(time/2)
end

local function nextBlock()
    pulseColor("back", colors.white, 0.275)
    pulseColor("back", colors.lightGray, 0.275)
    pulseColor("back", colors.gray, 0.275)
    pulseColor("back", colors.black, 0.275)
end

print("Enter selected mob:")
local mob = read()

repeat
    nextBlock()
    local mob_id = (block.getBlockData() or {SpawnData={entity={id="NONE"}}}).SpawnData.entity.id
    print(mob_id)
until mob_id == mob