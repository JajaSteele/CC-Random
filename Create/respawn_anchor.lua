local link = peripheral.find("Create_DisplayLink")
local book = peripheral.find("minecraft:lectern")

local config = {
    example_name = {
        action="delete"
    },
    example_name2 = {
        action="transfer",
        target="example_name3"
    }
}
local function loadConfig()
    if fs.exists(".respawn_config.txt") then
        local file = io.open(".respawn_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".respawn_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()
writeConfig()

local name_to_entry = {}
local pending_transfer = {}

local raw_list = {}
local height, width = link.getSize()

local function displayLinkThread()
    while true do
        raw_list = {}
        local raw_data = book.getText()
        for k, page in ipairs(raw_data) do
            for player, count in page:gmatch("(.-) (%d+)%s?[\n]?") do
                raw_list[#raw_list+1] = {
                    name=player,
                    count=tonumber(count)
                }
                name_to_entry[player] = #raw_list

                local data = config[player]
                if data then
                    print("Config detected for "..player.."\nType: "..data.action)
                    if data.action == "delete" then
                        table.remove(raw_list, name_to_entry[player])
                        name_to_entry[player] = nil
                    elseif data.action == "transfer" and data.target then
                        local tar_entry = name_to_entry[data.target]
                        if tar_entry then
                            raw_list[tar_entry].count = raw_list[tar_entry].count + raw_list[name_to_entry[player]].count
                        else
                            if pending_transfer[data.target] then
                                pending_transfer[data.target] = pending_transfer[data.target] + raw_list[player].count
                            else
                                pending_transfer[data.target] = raw_list[player].count
                            end
                        end
                        table.remove(raw_list, name_to_entry[player])
                        name_to_entry[player] = nil
                    end
                end

                if pending_transfer[player] and name_to_entry[player] then
                    raw_list[name_to_entry[player]].count = raw_list[name_to_entry[player]].count + pending_transfer[player]
                    pending_transfer[player] = nil
                end

                if #raw_list >= height then
                    break
                end
                
            end
        end

        table.sort(raw_list, function(a,b) return a.count > b.count end)

        link.clear()
        for pos,entry in pairs(raw_list) do
            link.setCursorPos(1, pos)
            link.write(entry.name) 
            link.setCursorPos(width-(#tostring(entry.count)-1), pos)
            link.write(tostring(entry.count))
        end
        for pos=#raw_list+1, height do
            link.setCursorPos(1, pos)
            link.write(string.rep(" ", width)) 
            link.setCursorPos(1, pos)
            link.write("\xA78\xA7kNONE") 
        end
        link.update()
        sleep(1)
    end
end

parallel.waitForAll(displayLinkThread)