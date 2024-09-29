local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local speakers = {peripheral.find("speaker")}
local completion = require("cc.completion")

local modems = {peripheral.find("modem")}
local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

settings.define("sg_tts.addressbook_id", {
    description = "The AddressBook computer ID to use when doing a lookup",
    default = nil,
    type = number,
})

if modem then
    rednet.open(peripheral.getName(modem))
    if not settings.get("sg_tts.addressbook_id") then
        print("Select ID of addressbook to use:")
        local list_of_books = {rednet.lookup("jjs_sg_addressbook")}
        
        for k,v in pairs(list_of_books) do
            list_of_books[k] = tostring(v)
        end
        
        settings.set("sg_tts.addressbook_id", tonumber(read(nil, nil, function(text) return completion.choice(text, list_of_books) end, "")) or -1)
        settings.save()
    end
end

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local tts_address = "http://jajasteele.duckdns.org:2456/"
local voice = "Microsoft Michelle Online"

local speaker_audio_threads = {}

local function playAudio(link)
    local request = http.get(link,nil,true)
    if request then
        while true do
            local chunk = request.read(2*1024)
            if chunk == nil then break end
            local buffer = decoder(chunk)

            speaker_audio_threads = {}
            for k,speaker in pairs(speakers) do
                speaker_audio_threads[#speaker_audio_threads+1] = function()
                    local name = peripheral.getName(speaker)
                    while not speaker.playAudio(buffer, 3) do
                        repeat 
                            local event, ev_name = os.pullEvent("speaker_audio_empty")
                        until ev_name == name
                    end
                end
            end
            parallel.waitForAll(table.unpack(speaker_audio_threads))
        end
        request.close()
    else
        print("Couldn't reach TTS Server")
    end
end

local function playTTS(msg, voice_name)
    playAudio(tts_address.."?tts="..textutils.urlEncode(msg).."&voice="..textutils.urlEncode(voice_name or voice))
end

local feedback_blacklist = {
    {code=-26, name="interrupted_by_incoming_connection"}
}
local is_energy_reached = false
local has_announced_energy = false

local function checkFeedbackBlacklist(code)
    if type(code) == "number" then
        for k,v in pairs(feedback_blacklist) do
            if code == v.code then
                return false
            end
        end
    elseif type(code) == "string" then
        for k,v in pairs(feedback_blacklist) do
            if code == v.name then
                return false
            end
        end
    end
    return true
end

local function addressLookup(lookup_value)
    if modem then
        if not lookup_value then
            return {name="Unknown Address"}
        end

        local id_to_send = settings.get("sg_tts.addressbook_id")
        if type(lookup_value) == "string" then
            rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_name")
        elseif type(lookup_value) == "table" then
            rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_address")
        end

        for i1=1, 5 do
            local id, msg, protocol = rednet.receive(nil, 0.25)
            if id == id_to_send then
                if protocol == "jjs_sg_lookup_return" then
                    return msg
                else
                    return {name="Unknown Address"}
                end
            end
        end
    end
    return {name="Unknown Address"}
end

local is_active = false
local passed_entities = 0

playTTS("Gate TTS is now online.")
print("Gate TTS is now online, address book id: "..(settings.get("sg_tts.addressbook_id") or "NO MODEM"))

local function mainTTS()
    while true do
        local event = {os.pullEvent()}

        if event[1] == "stargate_chevron_engaged" then
            print("stargate_chevron_engaged")
            if not is_active then
                is_active = true
                playTTS("Gate activation detected.")
            end
        elseif event[1] == "stargate_incoming_wormhole" or event[1] == "stargate_outgoing_wormhole" then
            sleep(1.5)
            print("stargate_wormhole")
            if event[1] == "stargate_incoming_wormhole" then
                playTTS("Incoming gate connection from "..(addressLookup(event[2]) or {name="UNKNOWN ADDRESS"}).name)
            else
                playTTS("Gate successfully connected to "..(addressLookup(event[2]) or {name="UNKNOWN ADDRESS"}).name)
            end
            passed_entities = 0
        elseif event[1] == "stargate_disconnected" then
            sleep(1.5)
            print("stargate_disconnected")
            is_active = false
            playTTS("Gate is now closed.")
            if passed_entities > 0 then
                playTTS(passed_entities.." entit"..(((passed_entities > 1) and "ies have") or "y has").." used the gate.")
            else
                playTTS("No entities have used the gate")
            end
            passed_entities = 0
        elseif event[1] == "stargate_reset" then
            if checkFeedbackBlacklist(event[3]) then
                sleep(1.5)
                print("stargate_reset")
                is_active = false
                playTTS("Gate failure detected; "..event[3]:gsub("_"," "))
                if passed_entities > 0 then
                    playTTS(passed_entities.." entit"..(((passed_entities > 1) and "ies have") or "y has").." used the gate.")
                end
            end
            passed_entities = 0
        elseif event[1] == "stargate_energy_full" then
            print("stargate_energy_full")
            playTTS("Gate successfully charged to energy target")
        end
    end
end

local function entityCounter()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "stargate_deconstructing_entity" or event[1] == "stargate_reconstructing_entity" then
            print("entity passed")
            passed_entities = passed_entities+1
        end
    end
end

local function energyCounter()
    while true do
        if interface.getStargateEnergy() >= interface.getEnergyTarget() then
            is_energy_reached = true
            if not has_announced_energy and is_energy_reached then
                has_announced_energy = true
                os.queueEvent("stargate_energy_full")
            end
        else
            is_energy_reached = false
            has_announced_energy = false
        end
        sleep(1)
    end
end

local function speaker_refresh()
    while true do
        local event = os.pullEvent()
        if event == "peripheral" or event == "peripheral_detach" then
            speakers = {peripheral.find("speaker")}
        end
    end
end

parallel.waitForAll(mainTTS, entityCounter, energyCounter, speaker_refresh)