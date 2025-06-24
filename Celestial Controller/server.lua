local env_detector = peripheral.find("environmentDetector")
local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("jjs_weather_server", tostring(os.getComputerID()))
end

print("Hosting 'Weather Control Server' on ID "..os.getComputerID())

local config = {}

local function loadConfig()
	if fs.exists(".celestial_config.txt") then
		local file = io.open(".celestial_config.txt", "r")
		config = textutils.unserialise(file:read("*a"))
		file:close()
	end
end
local function writeConfig()
	local file = io.open(".celestial_config.txt", "w")
	file:write(textutils.serialise(config))
	file:close()
end

loadConfig()

config.status = config.status or {}
config.status.always_day = config.status.always_day or false
config.status.always_night = config.status.always_night or false

config.status.always_weather = config.status.always_weather or 0

writeConfig()

local action_table = {
    {
        color=colors.yellow,
        displayName = "Sunny",
		name = "clear",
		group = "Weather"
    },
    {
        color=colors.lightBlue,
        displayName = "Rainy",
		name = "rain",
		group = "Weather"
    },
    {
        color=colors.blue,
        displayName = "Stormy",
		name = "thunder",
		group = "Weather"
    },
    {
        color=colors.white,
        displayName = "Morning",
		name = "sunrise",
		group = "Time"
    },
    {
        color=colors.lightGray,
        displayName = "Noon",
		name = "noon",
		group = "Time"
    },
    {
        color=colors.gray,
        displayName = "Evening",
		name = "sunset",
		group = "Time"
    },

    {
        color=colors.brown,
        displayName = "Moon Rise",
		name = "moonrise",
		group = "Time"
    },
    {
        color=colors.orange,
        displayName = "Midnight",
		name = "midnight",
		group = "Time"
    },
    {
        color=colors.red,
        displayName = "Moon Set",
		name = "moonset",
		group = "Time"
    },
	{
        color=nil,
        displayName = "Set Regular Time",
		name = "time_regular",
		group = "Auto Time",
		func = function()
			config.status.always_day = false
			config.status.always_night = false
			writeConfig()
		end
    },
	{
        color=nil,
        displayName = "Set Always-Day",
		name = "time_day",
		group = "Auto Time",
		func = function()
			config.status.always_day = true
			config.status.always_night = false
			writeConfig()
		end
    },
    {
        color=nil,
        displayName = "Set Always-Night",
		name = "time_night",
		group = "Auto Time",
		func = function()
			config.status.always_day = false
			config.status.always_night = true
			writeConfig()
		end
    },
	{
        color=nil,
        displayName = "Set Regular Weather",
		name = "weather_regular",
		group = "Auto Weather",
		func = function()
			config.status.always_weather = 0
			writeConfig()
		end
    },
	{
        color=nil,
        displayName = "Set Always-Clear",
		name = "weather_sunny",
		group = "Auto Weather",
		func = function()
			config.status.always_weather = 1
			writeConfig()
		end
    },
	{
        color=nil,
        displayName = "Set Always-Rain",
		name = "weather_rainy",
		group = "Auto Weather",
		func = function()
			config.status.always_weather = 2
			writeConfig()
		end
    },
}
local action_lookup = {}
for k,v in pairs(action_table) do
	action_lookup[v.name] = v
end

local weather_queue = {}

local function autoControl()
	while true do
		if config.status.always_day or config.status.always_night then
			local ingame_time = os.time("ingame")
			if config.status.always_day and (ingame_time > 18 and ingame_time < 24) or (ingame_time > 0 and ingame_time < 5.75) then
				print("Auto-Control: Setting to day")
				weather_queue[#weather_queue+1] = {
					action="sunrise"
				}
				os.queueEvent("weather_command")
				repeat
					sleep(1)
					ingame_time = os.time("ingame")
				until ingame_time > 5.75 and ingame_time < 18
				print("Auto-Control finished")
			end
			if config.status.always_night and (ingame_time > 4.75 and ingame_time < 19) then
				print("Auto-Control: Setting to night")
				weather_queue[#weather_queue+1] = {
					action="moonrise"
				}
				os.queueEvent("weather_command")
				repeat
					sleep(1)
					ingame_time = os.time("ingame")
				until ingame_time > 19 or ingame_time < 4.75
				print("Auto-Control finished")
			end
		end

		if config.status.always_weather > 0 then
			if config.status.always_weather == 1 and not env_detector.isSunny() then
				print("Auto-Control: Setting to sunny")
				weather_queue[#weather_queue+1] = {
					action="clear"
				}
				os.queueEvent("weather_command")
				repeat
					sleep(1)
				until env_detector.isSunny()
				print("Auto-Control finished")
			elseif config.status.always_weather == 2 and not env_detector.isRaining() then
				print("Auto-Control: Setting to rainy")
				weather_queue[#weather_queue+1] = {
					action="rain"
				}
				os.queueEvent("weather_command")
				repeat
					sleep(1)
				until env_detector.isRaining()
				print("Auto-Control finished")
			end
		end
		sleep(1)
	end
end

local function modemThread()
	while true do
		local sender, msg, protocol = rednet.receive()
		if protocol:match("jjs_weather") then
			print("Received signal from "..sender.." with protocol: "..protocol)
			if protocol == "jjs_weather_fetch" then
				print("Fetching info..")
				rednet.send(sender, {
					actions = action_table,
					status = config.status
				}, "jjs_weather_fetch")
			elseif protocol == "jjs_weather_command" and type(msg) == "table" then
				print("Queuing command: "..msg.action)
				if action_lookup[msg.action] then
					rednet.send(sender, "", "jjs_weather_command_confirm")
					weather_queue[#weather_queue+1] = msg
					os.queueEvent("weather_command")
				else
					print("Invalid command!")
				end
			end
		end
	end
end

local function controlThread()
	while true do
		local command = weather_queue[1]
		if command then
			local entry = action_lookup[command.action]
			print("Executing '"..entry.displayName.."'")
			if entry.func then
				entry.func()
			else
				rs.setBundledOutput("top", entry.color)
				sleep(0.25)
				rs.setBundledOutput("top", 0)
			end
			table.remove(weather_queue, 1)
		else
			os.pullEvent("weather_command")
		end
	end
end

parallel.waitForAny(modemThread, controlThread, autoControl)