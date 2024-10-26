local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local completion = require "cc.completion"

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local config = {}

local sides = {
    "front",
    "back",
    "left",
    "right",
    "top",
    "bottom"
}

local function isValidSide(side)
    for k,v in pairs(sides) do
        if side == v then
            return true
        end
    end
end

if fs.exists("cfg_rs_sg.txt") then
    local cfg_file = io.open("cfg_rs_sg.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Outgoing Side?")
    config.outgoing = read(nil, nil, completion.side)

    print("Incoming Side?")
    config.incoming = read(nil, nil, completion.side)

    print("Idle Side?")
    config.idle = read(nil, nil, completion.side)

    print("Charge Side?")
    config.charge = read(nil, nil, completion.side)

    print("Generation Side?")
    config.gen = read(nil, nil, completion.side)

    print("Wait until wormhole is open? (y/n)")
    local temp = read(nil, nil, nil)
    if temp == "y" or temp == "yes" or temp == "true" then
        config.await_wormhole = true
    else
        config.await_wormhole = false
    end

    local cfg_file = io.open("cfg_rs_sg.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

print("")
print("-= Current Config =-")
print("Outgoing = "..config.outgoing)
print("Incoming = "..config.incoming)
print("Idle = "..config.idle)
print("Charge = "..config.charge)
print("Await Wormhole = "..tostring(config.await_wormhole))
print("")

if interface.isStargateConnected and interface.isStargateConnected() then
    if interface.isStargateDialingOut() then
        if config.await_wormhole then
            repeat
                sleep()
            until interface.isWormholeOpen()
        end
        rs.setOutput(config.outgoing, true)
        rs.setOutput(config.incoming, false)
        rs.setOutput(config.idle, false)
        print("New State: outgoing")
    else
        if config.await_wormhole then
            repeat
                sleep()
            until interface.isWormholeOpen()
        end
        rs.setOutput(config.incoming, true)
        rs.setOutput(config.outgoing, false)
        rs.setOutput(config.idle, false)
        print("New State: incoming")
    end
else
    rs.setOutput(config.idle, true)
    rs.setOutput(config.outgoing, false)
    rs.setOutput(config.incoming, false)
    print("New State: idle")
end

local function eventThread()
    while true do
        local event = {os.pullEvent()}

        if event[1] == "stargate_incoming_wormhole" then
            if config.await_wormhole then
                repeat
                    sleep()
                until interface.isWormholeOpen()
            end
            rs.setOutput(config.incoming, true)
            rs.setOutput(config.outgoing, false)
            rs.setOutput(config.idle, false)
            print("New State: incoming")
        elseif event[1] == "stargate_outgoing_wormhole" then
            if config.await_wormhole then
                repeat
                    sleep()
                until interface.isWormholeOpen()
            end
            rs.setOutput(config.outgoing, true)
            rs.setOutput(config.incoming, false)
            rs.setOutput(config.idle, false)
            print("New State: outgoing")
        elseif event[1] == "stargate_disconnected" or event[1] == "stargate_reset" then
            rs.setOutput(config.idle, true)
            rs.setOutput(config.outgoing, false)
            rs.setOutput(config.incoming, false)
            print("New State: idle")
        end
    end
end

local last_charge = 0

local function checkThread()
    while true do
        if isValidSide(config.charge) and interface.getStargateEnergy then
            local charge = interface.getStargateEnergy()
            local target = interface.getEnergyTarget()

            local charge_output = clamp(15*(charge/target), 0, 15)
            if charge_output ~= last_charge then
                print("Set charge to "..charge_output)
                last_charge = charge_output
            end
            rs.setAnalogOutput(config.charge, charge_output)
        end

        if isValidSide(config.gen) then
            local stat, err = pcall(function()
                rs.setAnalogOutput(config.gen, interface.getStargateGeneration() or 15)
            end)
            if not stat and err then
                rs.setAnalogOutput(config.gen, 15)
            end
        end
        sleep(0.5)
    end
end

print("Starting RS Threads")
parallel.waitForAll(checkThread, eventThread)