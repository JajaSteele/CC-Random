local script_version = "1.1"
-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/Celestial%20Controller/celestial.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local completion = require("cc.completion")
local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
	if v.isWireless() == true then
		modem = modems[k]
	end
end

if modem then
	rednet.open(peripheral.getName(modem))
end

local function fill(x,y,x1,y1,bg,fg,char, target)
	local curr_term = term.current()
	term.redirect(target or curr_term)
	local old_bg = term.getBackgroundColor()
	local old_fg = term.getTextColor()
	local old_posx,old_posy = term.getCursorPos()
	if bg then
		term.setBackgroundColor(bg)
	end
	if fg then
		term.setTextColor(fg)
	end
	for i1=1, (x1-x)+1 do
		for i2=1, (y1-y)+1 do
			term.setCursorPos(x+i1-1,y+i2-1)
			term.write(char or " ")
		end
	end
	term.setTextColor(old_fg)
	term.setBackgroundColor(old_bg)
	term.setCursorPos(old_posx,old_posy)
	term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
	local curr_term = term.current()
	term.redirect(target or curr_term)
	local old_bg = term.getBackgroundColor()
	local old_fg = term.getTextColor()
	local old_posx,old_posy = term.getCursorPos()
	if bg then
		term.setBackgroundColor(bg)
	end
	if fg then
		term.setTextColor(fg)
	end
	
	local sizeX=(x1-x)+1
	local sizeY=(y1-y)+1
	
	for i1=1, sizeX do
		for i2=1, sizeY do
			if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
				term.setCursorPos(x+i1-1,y+i2-1)
				if char == "keep" then
					term.write()
				else
					term.write(char or " ")
				end
			end
		end
	end
	term.setTextColor(old_fg)
	term.setBackgroundColor(old_bg)
	term.setCursorPos(old_posx,old_posy)
	term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
	local curr_term = term.current()
	term.redirect(target or curr_term)
	local old_posx,old_posy = term.getCursorPos()
	local old_bg = term.getBackgroundColor()
	local old_fg = term.getTextColor()
	
	if bg then
		term.setBackgroundColor(bg)
	end
	if fg then
		term.setTextColor(fg)
	end
	
	term.setCursorPos(x,y)
	term.write(text)
	
	term.setTextColor(old_fg)
	term.setBackgroundColor(old_bg)
	term.setCursorPos(old_posx,old_posy)
	term.redirect(curr_term)
end

local function split(s, delimiter)
	local result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

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
term.clear()
term.setCursorPos(1,1)

if not config.server_id then
	print("Not connected to a server!")
	print("Fetching servers..")
	local celestial_servers = {rednet.lookup("jjs_weather_server")}
	for k,v in pairs(celestial_servers) do
		celestial_servers[k] = tostring(v)
	end
	print("Choose a celestial server ID:")  
	local server = read(nil, nil, function(text) return completion.choice(text, celestial_servers) end, nil)
	if server and tonumber(server) then
		config.server_id = tonumber(server)
	end
	
	writeConfig()
	term.clear()
	term.setCursorPos(1,1)
end

local action_table = nil
local status = {}
print("Fetching actions..")
for i1=1, 5 do
	rednet.send(config.server_id, "", "jjs_weather_fetch")
	local sender, msg, prot = rednet.receive("jjs_weather_fetch", 1)
	if sender == config.server_id and type(msg) == "table" then
		print("Success!")
		action_table = msg.actions
		status = msg.status
		break
	end
end
if not action_table then
	error("Invalid fetched actions!")
end

for k,v in pairs(action_table) do
	v.highlight = colors.lightGray
end

term.clear()
term.setCursorPos(1,1)

local width, height = term.getSize()
local max_scroll = #action_table
local scroll = 0

local click_map = {}

local toast_queue = {}
local toast_display = ""
local toast_fg = colors.white
local toast_timer = 3

local function receiveFiltered(protocol_filter, sender_filter, timeout)
	local target_time = os.epoch("utc")+(timeout*1000)
	while true do
		local sender, msg, protocol = rednet.receive(protocol_filter, (target_time-os.epoch("utc"))/1000)
		if sender == sender_filter then
			return sender, msg, protocol
		end
		if os.epoch("utc") >= target_time then
			return
		end
	end
end

local function queueToast(text, fg)
	toast_queue[#toast_queue+1] = {
		text=text,
		fg=fg
	}
	os.queueEvent("new_toast")
end

local function toastDisplayThread()
	while true do
		local last_toast = toast_queue[1]
		if last_toast then			
			if toast_timer <= 0 then
				table.remove(toast_queue, 1)
				toast_timer = 3
			end
			toast_display = last_toast.text
			toast_fg = last_toast.fg
			os.queueEvent("draw")
			sleep(1)
			toast_timer = toast_timer-1
		else
			toast_display = ""
			os.queueEvent("draw")
			os.pullEvent("new_toast")
		end
	end
end

local function drawThread()
	while true do
		os.pullEvent("draw")
		local pos = 1
		local index = 1
		local curr_group = ""
		click_map = {}
		term.clear()
		for i1=1, height-1 do
			local entry = action_table[index+scroll]
			if entry then
				if entry.group ~= curr_group then
					curr_group = entry.group
					write(2, 2+pos, entry.group, colors.black, colors.white)
					pos = pos+1
				else
					write(3, 2+pos, entry.displayName, colors.black, entry.highlight)
					click_map[2+pos] = entry
					pos = pos+1
					index = index+1
				end
			end
			if 2+pos > height-1 then
				break
			end
		end
		write(1, 1, "Celestial Controller", colors.black, colors.yellow)

		fill(width,1,width,height-1,colors.black,colors.gray, "\x3A")
		write(width, clamp((height-1)*(scroll/max_scroll),1,height-1), "\x12", colors.black, colors.lightGray)

		write(1,height,toast_display, colors.black, toast_fg)
	end
end

local function inputThread()
	while true do
		local ev = {os.pullEvent()}
		if ev[1] == "mouse_scroll" then
			local event, direction, x, y = table.unpack(ev)
			scroll = clamp(scroll+direction, 0, max_scroll)
			os.queueEvent("draw")
		elseif ev[1] == "mouse_click" then
			local event, button, x, y = table.unpack(ev)
			if x == width then
				if button == 1 then
					scroll = math.floor((y/height)*max_scroll)
					os.queueEvent("draw")
				end
			elseif y > 2 and y < height-1 then
				local entry = click_map[y]
				if entry then
					entry.highlight = colors.blue
					os.queueEvent("draw")
					sleep(0.5)
					rednet.send(config.server_id, {action=entry.name}, "jjs_weather_command")
					local sender = receiveFiltered("jjs_weather_command_confirm", config.server_id, 5)
					if not sender then
						queueToast("No response from server.", colors.red)
						entry.highlight = colors.red
						os.queueEvent("draw")
					elseif sender == config.server_id then
						queueToast("Command queued!", colors.lime)
						entry.highlight = colors.green
						os.queueEvent("draw")
					end
					sleep(0.5)
					entry.highlight = colors.lightGray
					os.queueEvent("draw")
				end
			end
		end
	end
end

os.queueEvent("draw")
parallel.waitForAll(drawThread, inputThread, toastDisplayThread)