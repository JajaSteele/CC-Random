player_dt = peripheral.find("playerDetector")

modem = peripheral.find("modem")
rednet.open("right")

local completion = require "cc.shell.completion"
local complete = completion.build(
  { completion.choice, { "config", "update_startup" } },
  completion.dir
)

shell.setCompletionFunction(shell.getRunningProgram(), complete)

args = {...}

rs = redstone
c = colors

bundled_bottom = 0

soundPlay = {}

speaker = peripheral.find("speaker")

audiolist = {
    "https://github.com/JJS-Laboratories/CC-Random/raw/main/Security%20System/audio/accessdenied.dfpwm",
    "https://github.com/JJS-Laboratories/CC-Random/raw/main/Security%20System/audio/accessgranted.dfpwm",
    "https://github.com/JJS-Laboratories/CC-Random/raw/main/Security%20System/audio/timeoutcheck.dfpwm",
    "https://github.com/JJS-Laboratories/CC-Random/raw/main/Security%20System/audio/timeoutid.dfpwm"
}
audiopaths = {
    "/audio/accessdenied.dfpwm",
    "/audio/accessgranted.dfpwm",
    "/audio/timeoutcheck.dfpwm",
    "/audio/timeoutid.dfpwm"
}

whitelist_lv1 = {
    "JajaSteele"
}

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end
local function clearline()
    oldX,oldY = term.getCursorPos()
    term.write(string.rep(" ",mX))
    term.setCursorPos(oldX,oldY)
end
local function setpos(x,y)
    term.setCursorPos(x,y)
end
local function sethome(x,y)
    term.setCursorPos(x,y)
    homeX = x
    homeY = y
end
local function down()
    currX,currY = term.getCursorPos()
    term.setCursorPos(homeX,currY+1)
end
local function w(t)
    term.write(t)
end
local function wd(t)
    term.write(t)
    down()
end
local function sc(c)
    term.setTextColor(c)
end
local function sbc(c)
    term.setBackgroundColor(c)
end
local function wdc(t)
    term.write(t)
    clearline()
    down()
end
local function wc(t)
    term.write(t)
    clearline()
end

c = colors

mX,mY = term.getSize()

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

if not fs.exists("/audio") then
    fs.makeDir("/audio")
    for i1=1, #audiolist do
        shell.run("wget "..audiolist[i1].." "..audiopaths[i1])
    end
end

if args[1] == "config" then
    newConfig = {}
    clear()
    w("Security Config Editor")
    sethome(2,2)
    wc("Required Rank: ")
    newConfig["required_rank"] = io.read()
    down()
    wc("Open Time (seconds): ")
    newConfig["open_time"] = tonumber(io.read())
    down()
    wc("Access Name: ")
    newConfig["access_name"] = io.read()
    wc("Execute on Startup? (y/n)")
    res = io.read()
    if res == "y" then
        newConfig["startup"] = 1
    else
        newConfig["startup"] = 0
    end
    down()
    fileconfig1 = io.open("/security.cfg","w")
    fileconfig1:write(textutils.serialise(newConfig))
    fileconfig1:close()
    clear()
    return
end

if fs.exists("/security.cfg") then
    fileconfig2 = io.open("/security.cfg","r")
    access_config = textutils.unserialise(fileconfig2:read("*a"))
    fileconfig2:close()
else
    print("No Config! Run \""..shell.getRunningProgram().." config\" to add one.")
    return
end

if args[1] == "update_startup" or (fs.exists("/security.lua") and access_config["startup"] == 1) then
    shell.run("delete /startup.lua")
    os.sleep(1)
    shell.run("move /security.lua /startup.lua")
    print("Done! Rebooting..")
    os.sleep(1)
    os.reboot()
end

if access_config["startup"] == 1 and not fs.exists("/startup.lua") then
    shell.run("move "..shell.getRunningProgram().." /startup.lua")
end


local function compare(t1,value)
    local result = false
    for k,v in pairs(t1) do
        if v == value then
            result = true
            break
        end
    end
    return result
end

function playAudio(t)
    for chunk in io.lines("/audio/"..t..".dfpwm", 16 * 1024) do
        local buffer = decoder(chunk)
    
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function getServer()
    loop = 0
    repeat
        rednet.broadcast("give_server_id","security_part1")
        id, msg = rednet.receive("security_part2",0.25)
        loop = loop+1
    until id ~= nil or loop == 20
    if loop == 20 then
        playAudio("timeoutid")
    elseif id ~= nil then
        print("Successfully Linked to "..id)
    end
    return id
end

serverID = getServer()

function audioThread()
    while true do
        if #soundPlay > 0 then
            for k,v in pairs(soundPlay) do
                playAudio(v)
            end
            soundPlay = {}
        end
        os.sleep(0.25)
    end
end

function clickThread()
    while true do
        local event , username = os.pullEvent("playerClick")

        req_rank = access_config["required_rank"]
        acc_name = access_config["access_name"]

        loopcount = 0
        repeat
            rednet.send(serverID,textutils.serialise({username,req_rank,acc_name}),"check_user")
            print("Checking "..username)
            id, check_msg = rednet.receive("check_user_result",2)
            loopcount = loopcount+1
        until id == serverID or loopcount == 3
        if loopcount == 3 then
            table.insert(soundPlay,"timeoutcheck")
        end
        if check_msg ~= nil then
            print("Result: "..check_msg)
            if tostring(check_msg) == "granted" then
                table.insert(soundPlay,"accessgranted")
                bundled_bottom = c.combine(bundled_bottom,c.white)
                os.sleep(access_config["open_time"])
                bundled_bottom = c.subtract(bundled_bottom,c.white)
            else
                table.insert(soundPlay,"accessdenied")
            end
        else
            table.insert(soundPlay,"accessdenied")
        end
    end
end

function rsThread()
    while true do
        rs.setBundledOutput("bottom",bundled_bottom)
        os.sleep(0.25)
    end
end

function rebootThread()
    while true do
        repeat
            id, check_msg = rednet.receive("reboot_protocol")
        until check_msg ~= nil
        if check_msg == "reboot_now" then
            math.randomseed(os.getComputerID())
            os.sleep(math.random(1.25,5))
            os.sleep(math.random(0.25,3))
            os.reboot()
        end
        if check_msg == "update_now" then
            shell.run("delete "..shell.getRunningProgram())
            shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Security%20System/security.lua "..shell.getRunningProgram())
            math.randomseed(os.getComputerID())
            os.sleep(math.random(1.25,5))
            os.sleep(math.random(0.25,3))
            os.reboot()
        end
        if check_msg == "open_all" then
            math.randomseed(os.getComputerID())
            os.sleep(math.random(1.25,3))
            os.sleep(math.random(0.25,2))
            bundled_bottom = c.combine(bundled_bottom,c.white)
        end
        if check_msg == "close_all" then
            math.randomseed(os.getComputerID())
            os.sleep(math.random(1.25,3))
            os.sleep(math.random(0.25,2))
            bundled_bottom = c.subtract(bundled_bottom,c.white)
        end
    end
end

parallel.waitForAll(rsThread,clickThread,audioThread,rebootThread)