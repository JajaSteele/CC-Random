local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))

    modem.open(2707)
end

local gates = {}

local hosts
for i1=1, 2 do
    hosts = {rednet.lookup("jjs_sg_remotedial")}
    if hosts[1] then
        break
    end
    sleep(0.1)
end

local problematic_gates = {}

for k,v in ipairs(hosts) do
    rednet.send(v, "", "jjs_sg_getlabel")
    local id, name
    for i1=1, 3 do
        id, name = rednet.receive("jjs_sg_sendlabel", 1)
        if name then break end
        if i1 > 1 then
            print("Fetching Gates.. (x"..i1..")")
        end
    end
    if not name then
        problematic_gates[#problematic_gates+1] = v
    end
    gates[name or "unknown"] = id
    sleep(0.1)
end

modem.transmit(2707, 2707, {protocol="jjs_sg_dialer_ping", message="request_ping"})
local failed_attempts = 0
local temp_gates = {}
while true do
    local timeout_timer = os.startTimer(0.075)
    local event = {os.pullEvent()}

    if event[1] == "modem_message" then
        if type(event[5]) == "table" and event[5].protocol == "jjs_sg_dialer_ping" and event[5].message == "response_ping" then
            failed_attempts = 0
            os.cancelTimer(timeout_timer)
            temp_gates[event[5].id] = {
                id = event[5].id,
                distance = event[6] or "Other Dim",
                label = event[5].label
            }
        end
    elseif event[1] == "timer" then
        if event[2] == timeout_timer then
            failed_attempts = failed_attempts+1
        else
            os.cancelTimer(timeout_timer)
        end
    end

    if failed_attempts > 4 then
        break
    end
end

print("Erroring Gates:")
for k,v in ipairs(problematic_gates) do
    local distance
    if temp_gates[v] then
        distance = temp_gates[v].distance
    else
        distance = "No Reply"
    end
    print("ID: "..v.." D: "..distance)
end

local gate_distances = {}

local function isProblematic(id)
    for k,v in pairs(problematic_gates) do
        if id == v then
            return true
        end
    end
end

local function distanceThread()
    while true do
        rednet.broadcast({sType = "lookup", sProtocol = "jjs_sg_remotedial"}, "dns")
        modem.open(os.getComputerID())

        local timer = os.startTimer(0.1)
        while true do
            local event_raw = {os.pullEvent()}
            if event_raw[1] == "modem_message" then
                local event, side, channel, replyChannel, message, distance = table.unpack(event_raw)
                if type(message) == "table" and message.sProtocol == "dns" then
                    local rednet_data = message.message
                    if rednet_data.sType == "lookup response" and channel == os.getComputerID() and isProblematic(message.nSender) then
                        gate_distances[message.nSender] = distance or -1
                        os.cancelTimer(timer)
                        timer = os.startTimer(0.1)
                    end
                end
            elseif event_raw[1] == "timer" and event_raw[2] == timer then
                break
            end
        end
        os.queueEvent("refresh_distance")
    end
end

local function drawThread()
    while true do
        os.pullEvent("refresh_distance")
        for k,v in pairs(gate_distances) do
            term.clear()
            term.setCursorPos(1,1)
            if v < 0 then v = "XX" else v = string.format("%.1f", v) end
            print("ID: "..k.." DIST: "..v)
        end
    end
end

parallel.waitForAll(distanceThread, drawThread)