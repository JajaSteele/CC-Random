
getStatus = function ( override)
    if override.charging then
        return 'Charging'
    elseif not override.expect_incoming and not override.expect_outgoing and not override.incoming_wormhole and not override.outgoing_wormhole and not override.open and not override.dhd_dial then
        return 'Idle'
    elseif override.incoming_wormhole and not override.expect_incoming and not override.open then
        return 'Unknown Incoming'
    elseif override.incoming_wormhole and not override.expect_incoming and override.open then
        return 'Unknown Incoming Established'
    elseif (override.expect_incoming and not override.incoming_wormhole and not override.open) or (override.expect_incoming and override.incoming_wormhole and not override.open) then
        return 'Scheduled Incoming'
    elseif override.expect_incoming and override.incoming_wormhole and override.open then
        return 'Scheduled Incoming Established'
    elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and override.dhd_dial then
        return 'Local DHD Dialing'
    elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and override.dhd_dial then
        return 'Local DHD Established'
    elseif override.outgoing_wormhole and not override.expect_outgoing and not override.open and not override.dhd_dial then
        return 'Unknown Outgoing'
    elseif override.outgoing_wormhole and not override.expect_outgoing and override.open and not override.dhd_dial  then
        return 'Unknown Outgoing Established'
    elseif override.outgoing_wormhole and override.expect_outgoing and not override.open and not override.dhd_dial then
        return 'Scheduled Outgoing'
    elseif override.outgoing_wormhole and override.expect_outgoing and override.open and not override.dhd_dial then
        return 'Scheduled Outgoing Established'
    else 
        return 'Error : No match state found'
    end
end


function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function formatAddress(input, reverse)
    if not reverse then
        local output_string = ""
        for i, v in ipairs(input) do
            if i == #input then
                output_string = output_string .. "-".. v .. "-"
            else 
                output_string = output_string .. "-" .. v
            end
        end
        return output_string
    else
        local output_table = {}
        local temp_addr = split(input, "-")
        for k,v in ipairs(temp_addr) do
            if tonumber(v) then
                output_table[#output_table+1] = tonumber(v)
            end
        end
        return output_table
    end
end

function generateBar( percentage, bar_points )
    -- Calculate the number of filled points and empty points
    local filled_points = math.floor(percentage / 100 * bar_points)
    local empty_points = bar_points - filled_points
    -- Generate the bar string
    local bar = "[" .. string.rep("|", filled_points) .. string.rep("-", empty_points) .. "]"
    return bar
end

function formatFe( fe_value )
    local prefixes = {"", "k", "M", "G"}
    local prefix_index = 1

    while fe_value >= 1000 and prefix_index < #prefixes do
        fe_value = fe_value / 1000
        prefix_index = prefix_index + 1
    end
    local prefix = prefixes[prefix_index]
    local suffix 
    if prefix == "" then
        suffix = " FE"
    else
        suffix = "FE"
    end

    return fe_value, prefix .. suffix
end

function pad_string(str,length, char, dots)
    if not char then
        char = " "  -- Default padding character is space
    end

    if dots then
        local maxLength = length - 3 -- Account for the length of '...'
        if #str > maxLength then
            return string.sub(str, 1, maxLength) .. "..."
        end
    else
        if #str > length then
            return string.sub(str, 1, length)
        end
    end

    local padding = length - #str
    return str .. string.rep(char, padding)
end


string.startswith = function(self, str) 
    return self:find('^' .. str) ~= nil
end

GateController = {
    new = function( self , inter, address, name)
        local interface = peripheral.find(inter)
        local address = address or interface.getLocalAddress() or error('interface not found')
        if #address == 8 then
            table.insert(address, 0)
        end
        local internal = { 

            interface = interface,
            network = nil,
            monitor = nil,
            type = inter,
            address = address,
            name = name or os.getComputerLabel(),
            id = os.getComputerID(),
            addresses_book = {},
            dial_queue = {},
            current_dial = {},
            last_outgoing_address = {},
            outgoing_wormhole = false,
            incoming_wormhole = false,
            expect_incoming = false,
            expect_outgoing = false,
            dialing_out = false,
            abort_dial = false,
            open = false,
            dhd_dial = false,
            charging = false,
            travelers = {},
            refreshPeriod = 3,

            -- gate/interface values
            interface.setEnergyTarget(200000000),
            interfaceEnergyBuffer = interface.getEnergy(),
            maxInterfaceEnergyBuffer = interface.getEnergyCapacity(),
            stargateEnergyTarget = interface.getEnergyTarget(),
            stargateEnergy = interface.getStargateEnergy(),
            gateGeneration = interface.getStargateGeneration(),

            -- long term data should be saved in file
            --- stats
            totalTravelersIn = 0,
            totalTravelersOut = 0,
            totalIncomingWormholes = 0,
            totalOutgoingWormholes = 0,
            --- configs
            fast_dial = false,
            gate_network = 0,
            delay = 1,

        }
        self.__index = self
        return setmetatable( internal, self )
    end,

    setNetworkController = function ( self, networkC )
        self.network = networkC
        if type(self.network) == type({}) then
            return true
        else return false end
    end,

    setMonitorController = function ( self, monitorC )
        self.monitor = monitorC
    end,

    saveConfig = function ( self , dir )
        local dir2 = dir or "stargateData.json"
        fs.delete(dir2)
        local file = fs.open(dir2, 'w')

        local toWrite = {   
            totalTravelersIn = self.totalTravelersIn,
            totalTravelersOut = self.totalTravelersOut,
            totalIncomingWormholes = self.totalIncomingWormholes,
            totalOutgoingWormholes = self.totalOutgoingWormholes,

            fast_dial = self.fast_dial,
            gate_network = self.gate_network,
            refreshPeriod = self.refreshPeriod,
            delay = self.delay,
        }
        file.write(textutils.serialiseJSON(toWrite))
        file.close()
    end,

    loadConfig = function ( self , dir )
        local dir2 = dir or "stargateData.json"
        if not fs.exists(dir2) then
            return
        end
        local file = fs.open(dir2, 'r')
        local config = textutils.unserialiseJSON(file.readLine())
        file.close()
        self.totalTravelersIn = config.totalTravelersIn
        self.totalTravelersOut = config.totalTravelersOut
        self.totalIncomingWormholes = config.totalIncomingWormholes
        self.totalOutgoingWormholes = config.totalOutgoingWormholes

        self.fast_dial = config.fast_dial
        self.gate_network = config.gate_network
        self.refreshPeriod = config.refreshPeriod
        self.delay = config.delay

    end,

    tick = function ( self )
    --function handles gate events and queues next dial once last is done.'
        local count = 0
        local timerId = os.startTimer(self.refreshPeriod)
        local timerId_for_reset_because_chevrons_were_left = 0
        local sent = false
        while true do
            local event, p1, p2, p3, p4, p5 = os.pullEvent()
            if event == 'timer' then
                if p1 == timerId then
                    self:refresh()
                    timerId = os.startTimer(self.refreshPeriod)
                elseif p1 == timerId_for_reset_because_chevrons_were_left then
                    self:resetGate()
                    timerId_for_reset_because_chevrons_were_left = 0
                end
                goto end_tick
            end

            self.interfaceEnergyBuffer = self.interface.getEnergy()
            self.maxInterfaceEnergyBuffer = self.interface.getEnergyCapacity()
            self.stargateEnergyTarget = self.interface.getEnergyTarget()
            self.stargateEnergy = self.interface.getStargateEnergy()

            if event:startswith('stargate') then
                
                if event == 'stargate_chevron_engaged' then
                    if timerId_for_reset_because_chevrons_were_left == 0 then
                        timerId_for_reset_because_chevrons_were_left = os.startTimer(10)
                    else
                        os.cancelTimer(timerId_for_reset_because_chevrons_were_left)
                        timerId_for_reset_because_chevrons_were_left = os.startTimer(10)
                    end

                    if p3 then
                        -- do stuff when a chevron is engaged from a incoming wormhole
                        self.incoming_wormhole = true
                        if sent == false then
                            self.network:Broadcast(self:getState(), self.network._STATE_UPDATE)
                            sent = true
                        end
                    elseif not p3 then
                        -- do stuff when a chevron is engaged from the local dialer pc or dhd
                        self.outgoing_wormhole = true
                        if not next(self.current_dial) then
                            -- do stuff when a dhd is dialing happens for every chevron
                            self.expect_outgoing = false
                            self.dhd_dial = true
                        else
                            -- the dial pc is dialing and not a dhd
                            
                            if self.current_dial.unknown == true then
                                self.expect_outgoing = false
                            else 
                                self.expect_outgoing = true
                            end
                        end

                        if sent == false then
                            self.network:Broadcast(self:getState(), self.network._STATE_UPDATE)
                            sent = true
                        end
                    end
                elseif event == 'stargate_deconstructing_entity' then
                    self.totalTravelersOut = self. totalTravelersOut + 1
                    local traveler = p1
                    local name = p2
                    local uuid = p3
                    local gone = p4
                    local trav = {dir = 'out', traveler = traveler, name = name, uuid = uuid, gone = gone}
                    self:addTraveler(trav)

                elseif event == 'stargate_reconstructing_entity' then
                    self.totalTravelersIn = self.totalTravelersIn + 1
                    local traveler = p1
                    local name = p2
                    local uuid = p3
                    local trav = {dir = 'in', traveler = traveler, name = name, uuid = uuid, gone = gone}
                    self:addTraveler(trav)

                elseif event == 'stargate_incoming_wormhole' then
                    os.cancelTimer(timerId_for_reset_because_chevrons_were_left)
                    self.outgoing_wormhole = false
                    self.totalIncomingWormholes = self.totalIncomingWormholes + 1
                    self.incoming_wormhole = true
                    self.open = true
                    self.network:Broadcast(self:getState() , self.network._STATE_UPDATE) -- let network know this gate is busy with 
                elseif event == 'stargate_outgoing_wormhole' then
                    os.cancelTimer(timerId_for_reset_because_chevrons_were_left)
                    self.incoming_wormhole = false
                    self.totalOutgoingWormholes = self.totalOutgoingWormholes + 1
                    self.open = true
                    self.outgoing_wormhole = true
                    self.last_outgoing_address = self.current_dial
                    self.network:Broadcast(self:getState() , self.network._STATE_UPDATE)

                elseif event == 'stargate_disconnected' then
                    sent = false
                    self.dhd_dial = false
                    self.open = false
                    self.abort_dial = false
                    if self.incoming_wormhole then
                        self.incoming_wormhole = false --make false because remote gate is no longer connected
                        self.expect_incoming = false
                        self.incoming_address = {}
                    elseif self.outgoing_wormhole then
                        self.expect_outgoing = false
                        self.outgoing_wormhole = false
                        self.current_dial = {}
                    end
                    self.network:Broadcast(self:getState() , self.network._STATE_UPDATE)

                elseif event == 'stargate_reset' then
                    --find out what the difference is here from disconnect
                    sent = false
                    if p2 == 'interrupted_by_incoming_connection' then
                        self.incoming_wormhole = true
                        self.expect_outgoing = false
                        self.outgoing_wormhole = false
                    else
                        sent = false
                        self.abort_dial = false
                        self.dhd_dial = false
                        self.open = false
                        self.incoming_wormhole = false --make false because remote gate is no longer connected
                        self.expect_incoming = false
                        self.expect_outgoing = false
                        self.outgoing_wormhole = false
                        self.current_dial = {}
                        self.incoming_address = {}
                    end

                    self.network:Broadcast(self:getState() , self.network._STATE_UPDATE)
                end
            end
            ::end_tick::
        end
    end,

    tickDialer = function ( self )
        -- this function dials the gate when a `current_dial` exists
        while true do
            sleep(0.1)
            if #self.dial_queue > 0 and #self.current_dial == 0 then
                print(textutils.serialize(self.dial_queue))
                self.current_dial = table.remove(self.dial_queue, 1)
                print("Current Dial after remove: \n", self.current_dial)
            else 
                goto skip_to_end_gate_d
            end

            if not self.current_dial.unknown then
                --self.network:Send(self.current_dial.id, self:getState(), self.network._DIAL_INIT)  -- emit an outgoing to the next gate program
            end

            if self.current_dial.delayed then
                sleep(self.current_dial.delayed)
            end
            sleep(0.3)

            if self.current_dial.chargeTo then
                if self.current_dial.chargeTo > self.interface.getStargateEnergy() then
                    self.charging = true
                    self:setEnergyTarget(self.current_dial.chargeTo)
                    while self.current_dial.chargeTo > self.interface.getStargateEnergy() do
                        sleep(0.3)
                    end
                end
                self:setEnergyTarget(200000000)
                self.charging = false
            end
            print(self)
            print(self.current_dial)
            print(self.current_dial.address)
            for idx,val in ipairs(self.current_dial.address) do

                if self.incoming_wormhole or self.abort_dial then
                    self.current_dial = {}
                    self.outgoing_wormhole = false
                    goto skip_to_end_gate_d
                end
                if self.fast_dial or self.gateGeneration == 3 or self.gateGeneration == 0 then
                    sleep(0.1)
                    self.interface.engageSymbol(val)
                    if self.delay then
                        sleep(self.delay)
                    else
                        sleep(1)
                    end
                else
                    
                    if (val-self.interface.getCurrentSymbol()) % 39 < 19 then
                        self.interface.rotateAntiClockwise(val)
                    else
                        self.interface.rotateClockwise(val)
                    end
                    repeat
                        sleep()
                    until self.interface.getCurrentSymbol() == val
                    self.interface.openChevron()
                    sleep(0.25)
                    self.interface.closeChevron()
                    sleep(0.1)
                end
            end
            print("2nd print")
            print(self)
            print(self.current_dial)
            print(self.current_dial.address)
            ::skip_to_end_gate_d::
        end
    end,


    getAddress = function( self )
        -- this fucntion returns the gates address
        return self.address
    end,

    dialAddress  = function ( self , data)
        --function will queue up a dial for the gate, address = shared_gate_obj, unknown = bool if address is in addresses book. 
        -- returns false if failed, or index of dial
        if #self.dial_queue > 8 then
            return false
        else
            table.insert(self.dial_queue, data)
            return #self.dial_queue
        end
    end,

    resetGate = function ( self )
        --resets gate, TODO: handle gate types
        if self.gateGeneration ~= 3 and self.gateGeneration ~= 0 then
            self.interface.closeChevron()
        end
        self.interface.disconnectStargate()
        os.queueEvent('stargate_reset', "soft")
    end,

    addAddress = function ( self , sharable)
    --``` addAddress ( sharableL Object - Shared Gate) - adds address to local address book
    -- returns if new gate in book
        for idx, Tgate in ipairs(self.addresses_book) do
            if textutils.serialiseJSON(Tgate['address']) == textutils.serialiseJSON(sharable['address']) then
                self:updateAddressData( sharable )
                return false
            end
        end
        table.insert(self.addresses_book, sharable)
        return true
    end,

    updateAddressData = function(self, shareable)
        for _, element in ipairs(self.addresses_book) do
            if textutils.serialiseJSON(element['address']) == textutils.serialiseJSON(shareable['address']) then
                for key, newValue in pairs(shareable) do
                    if element[key] ~= newValue then
                        element[key] = newValue
                    end
                end
                break
            end
        end
    end,

    getState = function ( self )
        --returns a shared gate object of the local gate
        return {
            address = self.address, 
            name = self.name, 
            id = self.id, 
            last_outgoing = self.last_outgoing_address,
            current_dial = self.current_dial,
            dial_count = #self.dial_queue,
            incoming_wormhole = self.incoming_wormhole,
            outgoing_wormhole = self.outgoing_wormhole,
            expect_incoming = self.expect_incoming,
            expect_outgoing = self.expect_outgoing,
            fast_dial = self.fast_dial,
            dhd_dial = self.dhd_dial,
            charging = self.charging,
            open = self.open,
            unknown = false,
            priority = self.priority,
            interfaceEnergyBuffer = self.interfaceEnergyBuffer,
            stargateEnergyTarget = self.stargateEnergyTarget,
            gateGeneration = self.gateGeneration,
            travelers = self.travelers,
            distance = nil -- filled out by receiving side
        }
    end,

    getGateInfo = function ( self )
        --returns a shared gate object of the local gate
        return {address = self.address, name = self.name, id = self.id, last_dial = self.last_outgoing_address}
    end,

    expectIncoming = function ( self , shared)
        self.expect_incoming = true
        self.incoming_address = shared
    end,

    orderAddresses = function ( self ) 
        local function sortingFunction(pri1, pri2) 
            return pri1.priority < pri2.priority
        end

        table.sort(self.addresses_book, sortingFunction)
    end,

    refresh = function ( self )
        self.interfaceEnergyBuffer = self.interface.getEnergy()
        self.network:Broadcast(self:getState(), self.network._PING)

        self:saveConfig()
    end,

    setEnergyTarget = function ( self , target)
        self.stargateEnergyTarget = target
        self.interface.setEnergyTarget(target)
    end,

    updateOne = function ( self, one , newValue)
        self[one] = newValue
    end,

    addTraveler = function ( self, traveler )
        if #self.travelers > 10 then
            table.remove(self.travelers, 1)
        end
        table.insert(self.travelers, traveler)
    end,

    outTerminal = function ( self )
        while true do
            local tra, traType
            if #self.travelers > 0 then
                tra = self.travelers[#self.travelers].name
                traType = self.travelers[#self.travelers].traveler
            else
                tra = "None"
                traType = 'None'
            end
            local percent = math.floor((self.interfaceEnergyBuffer / self.maxInterfaceEnergyBuffer) * 100)

            
            local formated_fe_v, formated_fe_v_prefix = formatFe(self.interfaceEnergyBuffer)
            local formated_fe, formated_fe_prefix = formatFe(self.maxInterfaceEnergyBuffer)

            local formated_fe_gate_v, formated_fe_gate_prefix = formatFe(self.stargateEnergy)
            local formated_fe_gateT_v, formated_fe_gateT_prefix = formatFe(self.stargateEnergyTarget)
            local status = getStatus(self:getState())

            if status == 'Charging' then
                if self.current_dial.unknown == false then
                    status = 'Charging for:'.. pad_string(self.current_dial.name, 11, " ") .. " " .. string.format("%.2f", formated_fe_gate_v) .. formated_fe_gate_prefix .. "/" .. string.format("%.2f", formated_fe_gateT_v) .. formated_fe_gateT_prefix
                else
                    status = 'Charging for:' .. pad_string('Unknown', 11, " ") .. string.format("%.2f", formated_fe_gate_v) .. formated_fe_gate_prefix .. "/" .. string.format("%.2f", formated_fe_gateT_v) .. formated_fe_gateT_prefix
                end
            end
            --print("---------------------------------------------------")
            --print("| Status:" .. status)
            --print("---------------------------------------------------")
            --print("|----- Gate Info ----------------------------------")
            --print("| Addr  :" .. formatAddress(self:getAddress()))
            --print("| Name  :" .. self.name)
            --print("| ID    :" .. self.id)
            --print("| Energy:" .. string.format("%.2f", formated_fe_v) .. formated_fe_v_prefix .. "/" .. string.format("%.2f", formated_fe) .. formated_fe_prefix .. " | " .. string.format("%.2f", formated_fe_gate_v) .. formated_fe_gate_prefix .. "/" .. string.format("%.2f", formated_fe_gateT_v) .. formated_fe_gateT_prefix)
            --print("------ Travelers Info -----------------------------")
            --print("| Last  :" .. tra .. " : " .. traType)
            --print("| In    :" .. self.totalTravelersIn)
            --print("| Out   :" .. self.totalTravelersOut)
            --print("| Total :" .. (self.totalTravelersOut + self.totalTravelersIn))
            --print("------ Wormhole Info ------------------------------")
            --print("| In    :" .. self.totalIncomingWormholes)
            --print("| Out   :" .. self.totalOutgoingWormholes)
            --print("| Total :" .. (self.totalOutgoingWormholes + self.totalIncomingWormholes))
            --print("---------------------------------------------------")
            --write(tostring(self.expect_incoming))
            --write(tostring(self.incoming_wormhole))
            --write(tostring(self.expect_outgoing))
            --write(tostring(self.outgoing_wormhole))
            --write(tostring(self.open))
            --write(tostring(self.dhd_dial))
            --write('Dialing: ' .. textutils.serialise(self.current_dial.address) )
            sleep(0.1)
        end
    end,

}
-- end gate object ----------------------------------------------------------------------
-- start network controller object ------------------------------------------------------
networkController = {
    new = function( self , modem)
        local id = os.getComputerID()
        local internal = { 

            modem = peripheral.find(modem) or error('No modem found',1),
            address = {},
            name = os.getComputerLabel(),
            id = id,

            me = {address = address, name = name, id = id},

            _MESSAGE_CHANNEL = id,
            _BROADCAST_CHANNEL = 24325,

            _STATE_UPDATE = 'rai_bc_state_update',
            _UPDATE_ONE = 'rai_update_one',

            --advertisement idenifiers
            _ADVERTISE_ADJ_GATE = "rai_advert_network_gate",
            _RENEW_GATE_ADVERTISEMENT_ALL = 'rai_network_renew_all',
            _RENEW_GATE_ADVERTISEMENT = 'rai_network_renew',

            -- emit gate events

            _REMOTE_SHUTDOWN = 'rai_stargate_c_remote_shutdown',
            _REMOTE_DIAL_OUT = 'rai_stargate_c_remote_dialout',

            _OUTGOING_DIAL = 'rai_msg_outgoing_dial',
            _PING = 'rai_ping',
            _DIAL_INIT = 'rai_dial_init',
        }
        self.__index = self
        return setmetatable( internal, self )
    end,

    setGateController = function ( self, gateC )
        self.gate = gateC
        self.address = self.gate:getAddress()
    end,

    setMonitorController = function ( self, monitorC )
        self.monitor = monitorC
    end,

    tickNetwork = function ( self )
        while true do
            -- only get modem data events
            local id, data, protocol, distance, isBroadcast = self:Receive()
            
            if protocol == "jjs_sg_startdial" then
                local address = formatAddress(data, true)
                print("Address:")
                print(textutils.serialize(address))

                address[#address+1] = 0
                local dial = {unknown = true, address = address,name = "Jaja Dialer"}
                self.gate:dialAddress(dial)
            end

            if protocol == "jjs_sg_dialer_ping" and data == "request_ping" then
                self.modem.transmit(id, 2707, {protocol="jjs_sg_dialer_ping", message="response_ping", id=os.getComputerID(), label=(os.getComputerLabel() or ("Gate "..os.getComputerID()))})
            end


            if isBroadcast then
                if protocol == self._RENEW_GATE_ADVERTISEMENT_ALL then
                    -- data to renew adj gate from remote
                    self:Broadcast(self.gate:getState(), self._ADVERTISE_ADJ_GATE)
    
                elseif protocol == self._ADVERTISE_ADJ_GATE then
                    -- incoming gate advert from remote if its a new gate send ours
                    if self.gate:addAddress(data) then
                        self:Broadcast(self.gate:getState(), self._ADVERTISE_ADJ_GATE)
                    end
                elseif protocol == self._STATE_UPDATE then
                    -- a gate emitted a disconnect, we are gonna update the known data
                    data.distance = distance
                    self.gate:updateAddressData(data)
                end


            elseif not isBroadcast then
                if protocol == self._REMOTE_DIAL_OUT or protocol == "jjs_sg_startdial" then
                    --adj gate got a remote protocol to dial out, probably log it so webui can do stuff
                    --index = self.gate:dialAddress(data) -- data here is of shared gate obj type it ques to to be dialed, and returns the index of dial
                elseif protocol == self._REMOTE_SHUTDOWN then
                    self.gate:resetGate()

                elseif protocol == self._DIAL_INIT then
                    --called when a gate sends out DIAL_INIT if its coming to us prepare
                    self.gate:expectIncoming(data)
                    self:Broadcast(self.gate:getState(), self._STATE_UPDATE)

                elseif protocol == self._UPDATE_ONE then
                    self.gate:updateOne(data['key'], data['value'])
                end
            end
            ::messageHandler_end::
        end
    end,

    run = function ( self, ...)
        -- this function runs the gate routines and others passed to it
        local args = {...}
        self.modem.open(self.id)
        self.modem.open(self._BROADCAST_CHANNEL)
        self.modem.open(2707)
        self.gate:loadConfig()

        self.gate:resetGate()

        self:Broadcast(self.gate:getState(), self._ADVERTISE_ADJ_GATE)
        parallel.waitForAll(function() self.gate:tick() end, function() self.gate:outTerminal() end, function() self.gate:tickDialer() end, function() self:tickNetwork() end, unpack(args))
    end,

    Send = function (self,to, data, protocol)
        local block = {
            data=data,
            protocol=protocol,
        }

        self.modem.transmit(to, self._MESSAGE_CHANNEL , block)
    end,

    Broadcast = function (self, data, protocol)
        local block = {
            data=data,
            protocol=protocol,
        }
        self.modem.transmit(self._BROADCAST_CHANNEL, self.id, block)
    end,

    Receive = function ( self , protocol) 
        local Got = false
        local isBroadcast = false
        while true do 
            local event, side, channel, replyChannel, data, distance = os.pullEvent('modem_message')
            print(event, textutils.serialise(data))

            if channel == self.id then
                if data.sProtocol then
                    --got rednet message
                    return replyChannel, data.message, data.sProtocol, distance
                
                elseif protocol and data.protocol == protocol then
                    return replyChannel, data.data, data.protocol, distance
                elseif not protocol then
                    return replyChannel, data.data, data.protocol, distance
                end
            elseif channel == self._BROADCAST_CHANNEL or channel == 2707  then
                if data.message then
                    -- got message from jajas stuff
                    if protocol and  data.protocol == protocol  then
                        return replyChannel, data.message, data.protocol, distance
                    elseif not protocol then
                        return replyChannel, data.message, data.protocol, distance
                    end
                end
                isBroadcast = true
                return replyChannel, data.data, data.protocol, distance, isBroadcast
            end
        end
    end,     

    remoteDial = function ( self , who , address)
        self:Send(who, address, self.network._REMOTE_DIAL_OUT)
    end

}
-- end network controller object ------------------------------------------------------

local gateContr = GateController:new('advanced_crystal_interface', nil, os.getComputerLabel())
local networkContr = networkController:new('modem')



function startup()	-- eventHandler, handles all events from the computer

    networkContr:setGateController(gateContr)

    gateContr:setNetworkController(networkContr)
    
    term.clear()

end

-- parallel setup stuff

startup()

networkContr:run()