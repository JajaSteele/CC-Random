local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("jjs_sg_addressbook", tostring(os.getComputerID()))

    modem.open(2707)
end

local function getNearestGate()
    modem.transmit(2707, 2707, {protocol="jjs_sg_dialer_ping", message="request_ping"})

    local temp_gates = {}

    local failed_attempts = 0
    while true do
        local timeout_timer = os.startTimer(0.075)
        local event = {os.pullEvent()}

        if event[1] == "modem_message" then
            if type(event[5]) == "table" and event[5].protocol == "jjs_sg_dialer_ping" and event[5].message == "response_ping" then
                failed_attempts = 0
                os.cancelTimer(timeout_timer)
                if event[6] and event[6] < 50 then  
                    temp_gates[#temp_gates+1] = {
                        id = event[5].id,
                        distance = event[6] or math.huge,
                        label = event[5].label
                    }
                end
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

    table.sort(temp_gates, function(a,b) return (a.distance < b.distance) end)

    return temp_gates[1]
end

print(getNearestGate())