local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local detector = peripheral.find("playerDetector")

local security_timer = 0

local kill_mode = false
local old_kill_mode = ""

local blacklist = {
    "Nathabe"
}

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local tts_address = "http://jajasteele.mooo.com:2456/"
local voice = "Microsoft Zira Desktop"

local speaker = peripheral.wrap("back")

local function playAudio(link)
    local request = http.get(link,nil,true)
    while true do
        local chunk = request.read(16*1024)
        if chunk == nil then break end
        local buffer = decoder(chunk)
        
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    request.close()
end

local function playTTS(msg, voice_name)
    playAudio(tts_address.."?tts="..textutils.urlEncode(msg).."&voice="..textutils.urlEncode(voice_name or voice))
end

local function isInsideTable(name, table_to_search)
    for k,v in pairs(table_to_search) do
        if v == name then
            return true
        end
    end
    return false
end

local function mainThread()
    while true do
        local event = {os.pullEvent()}
        if kill_mode then
            if event[1] == "stargate_reconstructing_entity" or event[1] == "mouse_click" then
                if isInsideTable(event[3], blacklist) or event[2] == 3 then
                    security_timer = 15
                    print("Blacklisted Entity Detected!")
                    playTTS("Blacklisted entity detected! Security engaged")
                end
            elseif event[1] == "stargate_disconnected" or event[1] == "stargate_reset" or (event[1] == "mouse_click" and event[2] == 1) then
                security_timer = 2
            end
        else
            if event[1] == "stargate_reconstructing_entity" or event[1] == "mouse_click" then
                if isInsideTable(event[3], blacklist) or event[2] == 3 then
                    security_timer = 8
                    print("Blacklisted Entity Detected!")
                    playTTS("Blacklisted entity detected! Security engaged")
                end
            elseif event[1] == "stargate_disconnected" or event[1] == "stargate_reset" or (event[1] == "mouse_click" and event[2] == 1) then
                if security_timer > 0 then
                    security_timer = 1
                end
            end
        end

        if event[1] == "redstone" then
            old_kill_mode = kill_mode
            kill_mode = rs.getInput("top")
            print("Security kill mode set to: "..tostring(kill_mode))
            if kill_mode ~= old_kill_mode then
                if kill_mode then
                    playTTS("Security is now in kill mode", voice)
                else
                    playTTS("Security is now in safe mode", voice)
                end
            end
        end
    end
end

local function detectorThread()
    while true do
        if interface.isStargateConnected() or security_timer > 0 then
            local player_list
            if kill_mode then
                player_list = detector.getPlayersInCoords({x=7271, y=71, z=-23027}, {x=7275, y=75, z=-23041})
            else
                player_list = detector.getPlayersInCoords({x=7277, y=71, z=-23036}, {x=7269, y=78, z=-23030})
            end
            for k,v in pairs(player_list) do
                if isInsideTable(v, blacklist) then
                    security_timer = 3
                end
            end
        end
        sleep()
    end
end

local function redstoneThread()
    while true do
        if kill_mode then
            rs.setOutput("front", false)
            if security_timer > 0 then
                rs.setOutput("right", true)
                security_timer = security_timer-1
            else
                rs.setOutput("right", false)
            end
        else
            rs.setOutput("right", false)
            if security_timer > 0 then
                rs.setOutput("front", true)
                security_timer = security_timer-1
            else
                rs.setOutput("front", false)
            end
        end
        sleep(1)
    end
end

print("Blacklisted Players:")
print(textutils.serialize(blacklist))

old_kill_mode = kill_mode
kill_mode = rs.getInput("top")
print("Security kill mode set to: "..tostring(kill_mode))
if kill_mode then
    playTTS("Security is now in kill mode", voice)
else
    playTTS("Security is now in safe mode", voice)
end

parallel.waitForAll(mainThread, detectorThread, redstoneThread)