local config = {}

if fs.exists("cfg_item_clearer.txt") and arg[1] ~= "config" then
    local config_file = io.open("cfg_item_clearer.txt", "r")
    config = textutils.unserialise(config_file:read("*a"))
    config_file:close()
    print("Successfully loaded config!")
else
    print("Welcome! Starting config mode..")
    os.sleep(0.25)
    term.clear()
    term.setCursorPos(1,1)
    print("Max Items Entities Count? (Recommended : 200)")

    config.max = tonumber(read())

    term.clear()
    term.setCursorPos(1,1)

    print("Auto-Startup this program? (Y/N) (Y is Recommended)")
    if fs.exists("startup.lua") then
        print("(Will delete the current startup.lua file)")
    end
    config.startup = read():lower():sub(1,1)

    print("Thanks!")

    print("Writing config file..")
    local config_file = io.open("cfg_item_clearer.txt", "w")
    config_file:write(textutils.serialise(config))
    config_file:close()
    print("Done!")
    print("Tip: You can run the program with the 'config' argument to open this screen again!")
    os.sleep(2)
    term.clear()
end

if ({commands.exec("/scoreboard players get JJS entities")})[2][1]:match("Unknown") then
    print("Missing scoreboard! Creating it..")
    commands.exec("/scoreboard objectives add entities dummy")
    commands.exec("/scoreboard players set JJS entities 0")
    
    if ({commands.exec("/scoreboard players get JJS entities")})[2][1]:match("Unknown") == nil then
        print("Successfully created the scoreboard!")
    else
        error("Couldn't create the scoreboard")
    end
else
    print("Scoreboard Objective successfully detected.")
end

if config.startup == "y" and fs.getName(shell.getRunningProgram()) ~= "startup.lua" then
    local path = shell.getRunningProgram()
    local name = fs.getName(path)
    local dir = fs.getDir(path)

    if fs.exists("startup.lua") then
        fs.delete("startup.lua")
    end

    fs.move(path, dir.."/".."startup.lua")
end

os.sleep(0.5)
term.clear()

print("Starting..")

local del_timer = 0
local pause_timer = 0

os.sleep(0.5)

local function item_detect()
    while true do
        if del_timer > 0 and pause_timer == 0 then
            del_timer = del_timer-1
            if del_timer == 20 then
                commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Items on the ground will be deleted in ","color":"yellow"},{"text":"20s","underlined":true,"color":"light_purple"},{"text":" !","color":"yellow"}] ]])
            elseif del_timer == 5 then
                commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Items on the ground will be deleted in ","color":"red"},{"text":"5s","underlined":true,"color":"dark_red"},{"text":" !!","color":"red"}] ]])
            elseif del_timer == 0 then
                local _, _, num = commands.exec("/kill @e[type=item]")
                commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Successfully deleted ","color":"green"},{"text":"]]..num..[[","color":"light_purple"},{"text":" items!","color":"green"}] ]])
                print("Deletion Done! Count: "..num)
            end
        end

        if pause_timer > 0 then
            pause_timer = pause_timer-1
            del_timer = 0
            if pause_timer == 0 then
                commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Item auto-removal unpaused after 30s!","color":"green"}] ]])
            end
        end

        local _,_, ent_count = commands.exec("/execute store result score JJS entities if entity @e[type=item]")

        term.setTextColor(colors.white)
        term.clear()
        term.setCursorPos(1, 2)
        term.write("Current Items Count: "..ent_count.." / "..config.max)

        if del_timer > 0 then
            term.setCursorPos(1,4)
            term.setTextColor(colors.orange)
            term.write("Deleting "..ent_count.." Items in "..del_timer.." seconds!")
        end

        if pause_timer > 0 then
            term.setCursorPos(1,5)
            term.setTextColor(colors.lime)
            term.write("Auto-Removal paused for "..pause_timer.." seconds!")
        end

        if ent_count > config.max and del_timer == 0 and pause_timer == 0 then
            del_timer = 45
            print("Triggered Auto-Delete! Count: "..ent_count)
            commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Items on the ground will be deleted in ","color":"yellow"},{"text":"45s","underlined":true,"color":"light_purple"},{"text":" !!","color":"yellow"}] ]])
        end

        os.sleep(1)
    end
end

local function chat_detect()
    while true do
        local event, ply, msg = os.pullEvent("chat")
        if msg == "NODELETE" or msg == "NOREMOVE" or (msg == "STOP" and pause_timer < 10) then
            pause_timer = 30
            commands.exec([[/tellraw @a ["",{"text":"[","color":"gold"},{"text":"JJS AL","bold":false,"underlined":false,"color":"#FF00F4","clickEvent":{"action":"suggest_command","value":"NOREMOVE"},"hoverEvent":{"action":"show_text","contents":"Tip: You can say \"NOREMOVE\" or \"NODELETE\" in chat to pause item removal for 30s."}},{"text":"] ","color":"gold"},{"text":"Item-Removal paused for ","color":"yellow"},{"text":"30s","color":"red"},{"text":"! Requested by ]]..ply..[[","color":"yellow"}] ]])
        end
    end
end

parallel.waitForAny(item_detect, chat_detect)