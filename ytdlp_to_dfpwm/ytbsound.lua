local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")
local completion = require("cc.completion")

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function write(x,y,text,bg,fg, clearline)
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
    if clearline then
        term.clearLine()
    end
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

local function fill(x,y,x1,y1,bg,fg,char)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i2=1, (y1-y)+1 do
        term.setCursorPos(x,y+i2-1)
        term.write(string.rep(char or " ", (x1-x)+1))
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

local width, height = term.getSize()
local is_playing = false
local skip_mode = false
local is_paused = false

local function playAudio(link)
    local count = 0
    local request = http.get(link,nil,true)
    if request then
        local headers = request.getResponseHeaders()
        local size = headers["content-length"]
        fill(1, height, width, height, colors.black, colors.lightBlue, " ")
        while is_playing and not skip_mode do
            while is_paused do
                sleep(0.1)
            end
            write(1,height, string.rep("-", (width*(count/size))-1).."\x07", colors.black, colors.lightBlue)
            local chunk = request.read(2*1024)
            if chunk == nil then break end
            count = count+#chunk
            local buffer = decoder(chunk)

            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end
        end
        request.close()
    end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local playlist = {}
local play_position = 1
local scroll = 0


local function mainThread()
    while true do
        fill(1, 1, width, 1, colors.gray, colors.white, " ")
        write(1,1, "Youtube Audio Player", colors.gray, colors.red)

        fill(1,2, width, height-3, colors.black, colors.white, " ")

        local write_count = 0
        for i1=1, height-4 do
            local entry_num = i1+scroll
            local entry = playlist[entry_num]
            if entry then
                if entry_num == play_position and is_playing then
                    if is_paused then
                        write(1, 2+write_count, entry_num..". "..entry, colors.black, colors.orange)
                    else
                        write(1, 2+write_count, entry_num..". "..entry, colors.black, colors.lime)
                    end
                else
                    write(1, 2+write_count, entry_num..". "..entry, colors.black, colors.white)
                end
                write_count = write_count+1
            end
        end
        os.pullEvent("redrawPlaylist")
        
        --if youtube_url:lower() == "play" then
        --    for k,youtube_id in ipairs(playlist) do
        --        fill(1,2, width, height, colors.black, colors.white, " ")
        --        write(1,2, "("..k.."/"..#playlist..") "..youtube_id, colors.black, colors.yellow)
        --        write(1,4, "! SERVER IS LOADING !", colors.black, colors.blue)
        --        write(1,5, "(Or at least it should be)", colors.black, colors.blue)
    --
        --        playAudio("http://jajasteele.duckdns.org:7277/?vidid="..textutils.urlEncode(youtube_id))
        --    end
    end
end

local function inputThread()
    while true do
        write(1, height-2, "Command:", colors.black, colors.white, true)
        term.setCursorPos(1, height-1)
        term.clearLine()
        term.setTextColor(colors.orange)
        term.write("> ")
        term.setTextColor(colors.white)
        local input_raw = read()
        local input = split(input_raw, " ")

        if input[1] == "add" then
            local youtube_url
            if not input[2] then
                write(1, height-2, "Video URL:", colors.black, colors.white)
                term.setCursorPos(1, height-1)
                term.clearLine()
                term.setTextColor(colors.orange)
                term.write("> ")
                term.setTextColor(colors.white)
                youtube_url = read()
            else
                youtube_url = input[2]
            end
            local youtube_id 
            if youtube_url:match(".+//(%w+%.%w+)") == "youtu.be" then
                youtube_id = youtube_url:match("https://.-/(...........)")
            else
                youtube_id = youtube_url:match("[?&]v=(...........)")
            end
        
            if youtube_id then
                table.insert(playlist, tonumber(input[2]) or #playlist+1, youtube_id)
            end
        elseif input[1] == "edit" and tonumber(input[2]) then
            local entry = playlist[tonumber(input[2])]
            if entry then
                write(1, height-2, "Video URL:", colors.black, colors.white)
                term.setCursorPos(1, height-1)
                term.clearLine()
                term.setTextColor(colors.orange)
                term.write("> ")
                term.setTextColor(colors.white)
                local youtube_url = read(nil, nil, function(text) return completion.choice(text, {"https://youtu.be/"..entry}) end, "https://youtu.be/"..entry)
                local youtube_id 
                if youtube_url:match(".+//(%w+%.%w+)") == "youtu.be" then
                    youtube_id = youtube_url:match("https://.-/(...........)")
                else
                    youtube_id = youtube_url:match("[?&]v=(...........)")
                end
            
                if youtube_id then
                    playlist[tonumber(input[2])] = youtube_id
                end
            end
        elseif input[1] == "remove" and tonumber(input[2]) then
            local entry = playlist[tonumber(input[2])]
            if entry then
                table.remove(playlist, tonumber(input[2]))
            end
        elseif input[1] == "export" then
            if not fs.exists("/playlists") then
                fs.makeDir("/playlists")
            end
            local export_file
            if input[2] then
                export_file = io.open("/playlists/"..input[2]..".txt", "w")
            else
                local list = fs.list("/playlists")
                write(1, height-2, "Export File Name:", colors.black, colors.white)
                term.setCursorPos(1, height-1)
                term.clearLine()
                term.setTextColor(colors.orange)
                term.write("> ")
                term.setTextColor(colors.white)
                local name = read(nil, nil, function(text) return completion.choice(text,  list) end)
                export_file = io.open("/playlists/"..name, "w")
            end
            export_file:write(textutils.serialize(playlist))
            export_file:close()
        elseif input[1] == "import" then
            if not fs.exists("/playlists") then
                fs.makeDir("/playlists")
            end
            local import_file
            if input[2] then
                import_file = io.open("/playlists/"..input[2]..".txt", "r")
            else
                local list = fs.list("/playlists")
                write(1, height-2, "Import File Name:", colors.black, colors.white)
                term.setCursorPos(1, height-1)
                term.clearLine()
                term.setTextColor(colors.orange)
                term.write("> ")
                term.setTextColor(colors.white)
                local name = read(nil, nil, function(text) return completion.choice(text,  list) end)
                import_file = io.open("/playlists/"..name, "r")
            end
            playlist = textutils.unserialize(import_file:read("*a"))
            import_file:close()
        elseif input[1] == "play" then
            if not is_playing then
                is_playing = true
                os.queueEvent("startPlaying")
            else
                if is_paused then
                    is_paused = false
                end
            end
        elseif input[1] == "stop" then
            is_playing = false
            os.queueEvent("stopPlaying")
            write(1, height, "Stopped", colors.black, colors.red, true)
        elseif input[1] == "skip" then
            skip_mode = true
            if tonumber(input[2]) then
                play_position = clamp(tonumber(input[2]), 1, #playlist)
            else
                play_position = clamp(play_position+1, 1, #playlist)
            end
        elseif input[1] == "pause" then
            is_paused = true
        elseif input[1] == "playlist" then
            write(1, height-2, "Playlist Link:", colors.black, colors.white)
            term.setCursorPos(1, height-1)
            term.clearLine()
            term.setTextColor(colors.orange)
            term.write("> ")
            term.setTextColor(colors.white)
            local playlist_url = read(nil, nil, nil)
            local playlist_id = playlist_url:match("[&?]list=([^&]+)")
            local youtube_id
            if playlist_url:match(".+//(%w+%.%w+)") == "youtu.be" then
                youtube_id = playlist_url:match("https://.-/(...........)")
            else
                youtube_id = playlist_url:match("[?&]v=(...........)")
            end
            local playlist_req = http.get("http://jajasteele.duckdns.org:7277/?playlist="..playlist_id.."&vidid="..youtube_id, nil, nil)
            local playlist_list = {}
            if playlist_req then
                playlist_list = split(playlist_req:readAll(), "\n")
                playlist_req:close()
            end
            for k,v in ipairs(playlist_list) do
                local youtube_url = v
                local youtube_id 
                if youtube_url:match(".+//(%w+%.%w+)") == "youtu.be" then
                    youtube_id = youtube_url:match("https://.-/(...........)")
                else
                    youtube_id = youtube_url:match("[?&]v=(...........)")
                end
            
                if youtube_id and youtube_id ~= "dQw4w9WgXcQ" then
                    table.insert(playlist, #playlist+1, youtube_id)
                end
            end
        elseif input[1] == "mass" then
            while true do
                write(1, height-2, "Waiting for CTRL+V..", colors.black, colors.yellow, true)
                local event = {os.pullEvent()}
                if event[1] == "paste" then
                    local youtube_url = event[2]
                    local youtube_id 
                    if youtube_url:match(".+//(%w+%.%w+)") == "youtu.be" then
                        youtube_id = youtube_url:match("https://.-/(...........)")
                    else
                        youtube_id = youtube_url:match("[?&]v=(...........)")
                    end
                
                    if youtube_id then
                        table.insert(playlist, tonumber(input[2]) or #playlist+1, youtube_id)
                    end
                    os.queueEvent("redrawPlaylist")
                elseif event[1] == "mouse_click" then
                    local entry_num = event[4]-1
                    write(1, height-2, "Deleting "..entry_num, colors.black, colors.red, true)
                    local entry = playlist[entry_num]
                    if entry then
                        table.remove(playlist, entry_num)
                        os.queueEvent("redrawPlaylist")
                    end
                elseif event[1] == "key" and (event[2] == keys.enter or event[2] == keys.numPadEnter) then
                    break
                end
            end
        end
        os.queueEvent("redrawPlaylist")
    end
end

local function scrollThread()
    while true do
        local event, scroll_input, x, y = os.pullEvent("mouse_scroll")
        scroll = math.ceil(clamp(scroll+(scroll_input*1), 0, #playlist))
        os.queueEvent("redrawPlaylist")
    end
end

local function audioThread()
    while true do
        local event = {os.pullEvent()}

        if event[1] == "startPlaying" then
            while is_playing do
                local current_id = playlist[play_position]
                if current_id then
                    write(1, height, "Loading..", colors.black, colors.blue, true)
                    playAudio("http://jajasteele.duckdns.org:7277/?vidid="..textutils.urlEncode(current_id))
                    if not skip_mode then
                        play_position = play_position+1
                        os.queueEvent("redrawPlaylist")
                    else
                        skip_mode = false
                        os.queueEvent("redrawPlaylist")
                    end
                    if play_position > #playlist then
                        is_playing = false
                        os.queueEvent("redrawPlaylist")
                        os.queueEvent("stopPlaying")
                        write(1, height, "Stopped", colors.black, colors.red, true)
                        break
                    end
                else
                    is_playing = false
                end
            end
        elseif event[1] == "stopPlaying" then
            write(1, height, "Stopped", colors.black, colors.red, true)
        end
    end
end

parallel.waitForAll(mainThread, scrollThread, inputThread, audioThread)