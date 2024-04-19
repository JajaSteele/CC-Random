if peripheral.find("advanced_crystal_interface") ~= nil then
	interface = peripheral.find("advanced_crystal_interface")
elseif peripheral.find("crystal_interface") ~= nil then
	interface = peripheral.find("crystal_interface")
elseif peripheral.find("basic_interface") ~= nil then
	interface = peripheral.find("basic_interface")
else
	print("Could not find Interface.")
end

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

modem.open(2707) --Jaja's nearest-gate port
modem.open(1204) --Aspect's nearest-gate port

LastAddress = {}
rednet.open(peripheral.getName(modem))
addressLength = nil
sendId = 61
receiveId = 10
local dialType = 1
fastDialing = false

if interface.rotateClockwise == nil then
	dialType = 2
else
	dialType = 1
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function prettyEnergy(energy)
    if energy > 1000000000000 then
        return string.format("%.2f", energy/1000000000000).." TFE"
    elseif energy > 1000000000 then
        return string.format("%.2f", energy/1000000000).." GFE"
    elseif energy > 1000000 then
        return string.format("%.2f", energy/1000000).." MFE"
    elseif energy > 1000 then
        return string.format("%.2f", energy/1000).." kFE"
    else
        return string.format("%.2f", energy).." FE"
    end
end

local beginDialing = false
local dialGoal = {}

local function dial(address)
	beginDialing = true
	dialGoal = address or {}
	addressLength = address
	redstone.setOutput("back", true)
end
function dhdOrigin()
	while true do
		id, message = rednet.receive()
		if id == dhdId then
			if message == "encodeOrigin" then
				interface.engageSymbol(0)
			end
		end
	end
end


function dhdInput()
	while true do
		id, message = rednet.receive()
		if id == dhdId then
			if message.type == "customAddress" then
				term.setCursorPos(1,1)
				local newSymbol
				local temp_address = split(message.data, "-")
				local new_address = {}
				for k,v in ipairs(temp_address) do -- Turns the table of strings into a table of numbers, that i use to dial
					if tonumber(v) then
						new_address [#new_address +1] = tonumber(v)
						newSymbol = tonumber(v)
					end
				end
				new_address[#new_address+1] = 0
				print(textutils.tabulate(new_address))
				--dial(new_address)
				interface.engageSymbol(newSymbol)
			end
		end
	end
end

function wirelessDialInput()
	while true do
		id, message, protocol = rednet.receive()
		if protocol == "jjs_sg_startdial" then
			local temp = split(message, "-")
			local to_dial = {}
			for k,v in ipairs(temp) do
				if tonumber(v) then
					to_dial[#to_dial+1] = tonumber(v)
				end
			end

			to_dial[#to_dial+1] = 0

			dialType = 2
			dial(to_dial)
		elseif protocol == "jjs_sg_disconnect" then
			fastDialing = false
			interface.disconnectStargate()
			beginDialing = true
			dialGoal = {}
			if interface.rotateAntiClockwise then
				interface.rotateAntiClockwise(0)
			end
		else
			if message.type == "dial" then
				if interface.getStargateType() == "sgjourney:milky_way_stargate" then 
                    dialType = 1
                else
                    dialType = 2
                end
				local newaddress = message.data.code
				dial(newaddress)
			elseif message.type == "dialfast" then
				if interface ~= peripheral.find("basic_interface") then 
                    fastDialing = false
                    dialType = 2
                    local newaddress = message.data.code
					dial(newaddress)
                end
			elseif message == "close" then
				fastDialing = false
				interface.disconnectStargate()
				beginDialing = true
				dialGoal = {}
				if interface.rotateAntiClockwise then
					interface.rotateAntiClockwise(0)
				end
			elseif message == "lastAddress" then
				dialType = 1
				dial(lastAddress)
			elseif message == "lastAddressFast" then
				dialType = 2
				dial(lastAddress)
			end
		end
	end
end

local function dialerNearestPing()
    while true do
        local event, side, channel, reply_channel, message, distance = os.pullEvent("modem_message")
        if type(message) == "table" then
			print("Received msg from"..channel)
			print(textutils.serialize(message))
            if message.protocol == "jjs_sg_dialer_ping" and message.message == "request_ping" then
                modem.transmit(reply_channel, 2707, {protocol="jjs_sg_dialer_ping", message="response_ping", id=os.getComputerID(), label="Gate Bugger "..os.getComputerID()})
			elseif message.protocol == "aspect_sg_ping" and message.message == "request_ping" then
                modem.transmit(reply_channel, 1204, {protocol="aspect_sg_ping", message="response_ping", id=os.getComputerID(), label="Gate Bugger "..os.getComputerID()})
            end
        end
    end
end

function getLastAddress()
    while true do
        local event, address = os.pullEvent()
        if (event == "stargate_incoming_wormhole" and address ~= {}) or event == "stargate_outgoing_wormhole" then
            lastAddress = address
			lastAddress[#lastAddress+1] = 0
        end
    end
end

local function attemptDialSymbol(symbol)
	local chevron = interface.getChevronsEngaged()
	if dialType == 1 then
		if chevron % 2 == 0 then
			interface.rotateClockwise(symbol)
		else
			interface.rotateAntiClockwise(symbol)
		end
		while (not interface.isCurrentSymbol(symbol))
		do
			if beginDialing then
				return
			end
			interface.getRecentFeedback()
			sleep(0)
		end
		interface.endRotation()
		sleep(.7)
		interface.openChevron()
		sleep(0.3)
		interface.encodeChevron()
		sleep(0.3)
		interface.closeChevron()
	 	sleep(0.5)
	elseif dialType == 2 then
		interface.engageSymbol(symbol)
	end
end
local function dialAttempter()
	while true do
		if beginDialing then
			beginDialing = false
			if interface.getChevronsEngaged() > 0 then
				interface.disconnectStargate()
			end
			if not (#dialGoal == 1 and dialGoal[1] == 0) then
				for i, v in ipairs(dialGoal) do
					if not beginDialing then
						attemptDialSymbol(v)
					end
				end
			end
		end
		sleep(0.05)
	end
end

parallel.waitForAll(wirelessDialInput,getLastAddress, dhdInput, dhdOrigin, dialAttempter, dialerNearestPing)
