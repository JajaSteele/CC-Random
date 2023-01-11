local dfpwm = require("cc.audio.dfpwm")
speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()

local buttons = {}
local playlist = {}

local isPlaying = false
local playing = 0
local start_play = 1
local isSkipping = false
local startSong = false

local debug_print = false

local width,height = term.getSize()

local info_bar = {
    {value=0,name="Current: "},
    {value=1,name="Start At: "},
}
local info_active = 1

local timer = 0

function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end


local function debug(text)
    if debug_print then
        local old_posx,old_posy = term.getCursorPos()
        term.setCursorPos(1,height)
        print(text)
        term.setCursorPos(old_posx,old_posy)
    end
end

local function playAudio(link)
    request = http.get(link,nil,true)
    while true do
        local chunk = request.read(16*1024)
        if chunk == nil then break end
        local buffer = decoder(chunk)

        if not isPlaying or isSkipping then speaker.stop() request.close() debug("loop1 exit") return end

        while not speaker.playAudio(buffer) and isPlaying and not isSkipping do
            os.pullEvent("speaker_audio_empty")
        end
    end
    request.close()
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
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

local function rect(x,y,x1,y1,bg,fg,char)
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
end

local function add_button(name,x,y,x1,y1,bg,fg,func)
    fill(x,y,x1,y1,bg,fg)
    
    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    local old_posx,old_posy = term.getCursorPos()

    term.setCursorPos(x,y)

    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.write(name)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)

    buttons[name] = {
        name=name,
        x=x,
        y=y,
        x1=x1,
        y1=y1,
        func=func
    }
    term.setCursorPos(old_posx,old_posy)
end

local function write(x,y,text,bg,fg)
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
end


fill(1,1,width,height,colors.yellow)
fill(1+1,1+2,width-1,height-5,colors.black,nil," ")

rect(1,1+1,width,height-4,colors.orange)

add_button("X",1,1,1,1,colors.red,colors.yellow,function()
    os.reboot()
end)

add_button("Play",1,height-3,4,height-3,colors.lime,colors.white,function()
    playing = start_play
    isPlaying = true
    startSong = true
end)

add_button("Stop",6,height-3,9,height-3,colors.red,colors.white,function()
    isPlaying = false
    startSong = false
    playing = 0
end)

add_button("Set",11,height-3,13,height-3,colors.orange,colors.white,function()
    isPlaying = false
    startSong = false
    term.setCursorPos(15,height-3)
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.yellow)
    local newStart = read()
    newStart = newStart:gsub("%D","")
    write(15,height-3,"Set: "..newStart.."     ",colors.yellow,colors.green)
    if newStart ~= "" then
        start_play = tonumber(newStart)
    end
    info_bar[2].value = start_play
    os.sleep(1)
    fill(15,height-3,width,height-3,colors.yellow)
end)


add_button("Add",1,height-1,3,height-1,colors.lime,colors.white,function()
    write(1,height,"Press CTRL+V",colors.yellow,colors.red)
    local event, text = os.pullEvent("paste")
    playlist[#playlist+1] = text
    fill(1,height,12,height,colors.yellow)
end)

add_button("Del",5,height-1,7,height-1,colors.red,colors.white,function()
    write(1,height,"Click the song to delete",colors.yellow,colors.red)
    local event, button, x, y = os.pullEvent("mouse_click")
    if y < 16 and y > 2 then
        table.remove(playlist,y-2)
        fill(1,height,width,height,colors.yellow)
        write(1,height,"Deleted Song "..(y-2),colors.yellow,colors.red)
        os.sleep(2)
    else
        fill(1,height,width,height,colors.yellow)
        write(1,height,"Error",colors.yellow,colors.red)
        os.sleep(2)
    end
    
    fill(1,height,width,height,colors.yellow)
end)

add_button("Exp",9,height-1,11,height-1,colors.orange,colors.white,function()
    local export_file = io.open("/exported_playlist.txt","w")
    export_file:write(textutils.serialise(playlist))
    export_file:close()
    fill(1,height,width,height,colors.yellow)
    write(1,height,"Exported the Playlist",colors.yellow,colors.green)
    os.sleep(2)
    fill(1,height,width,height,colors.yellow)
end)

add_button("Imp",13,height-1,15,height-1,colors.orange,colors.white,function()
    local import_file = io.open("/exported_playlist.txt","r")
    playlist = textutils.unserialise(import_file:read("*a") or "{}")
    import_file:close()
    fill(1,height,width,height,colors.yellow)
    write(1,height,"Imported the Playlist",colors.yellow,colors.green)
    os.sleep(2)
    fill(1,height,width,height,colors.yellow)
end)

function button_events()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        for k,v in pairs(buttons) do
            if x >= v.x and x <= v.x1 and y >= v.y and y <= v.y1 then
                local stat, err = pcall(v.func)
                if not stat then error(err) end
            end
        end
        coroutine.yield()
    end
end

function playlist_view()
    while true do
        local old_posx,old_posy = term.getCursorPos()
        local old_bg = term.getBackgroundColor()
        local old_fg = term.getTextColor()
        for i1=1, 13 do
            v = playlist[i1]
            if v and v ~= "" then
                term.setCursorPos(2,2+i1)
                if isPlaying and i1 == playing then
                    term.setBackgroundColor(colors.green)
                else
                    if math.mod(i1,2) == 0 then
                        term.setBackgroundColor(colors.gray)
                    else
                        term.setBackgroundColor(colors.black)
                    end
                end
                term.setTextColor(colors.white)
                local text
                if i1 >= 10 then
                    text = split(v, "/")
                    text1 = text[#text]:gsub("%%20"," ")
                    text1 = text1:sub(1,20)
                    term.write(i1..". "..text1..string.rep(" ",20-text1:len()))
                else
                    text = split(v, "/")
                    text1 = text[#text]:gsub("%%20"," ")
                    text1 = text1:sub(1,21)
                    term.write(i1..". "..text1..string.rep(" ",21-text1:len()))
                end
            else
                if math.mod(i1,2) == 0 then
                    term.setBackgroundColor(colors.gray)
                else
                    term.setBackgroundColor(colors.black)
                end
                fill(2,2+i1,width-1,2+i1)
            end
        end

        if isSkipping then
            rect(1,1+1,width,height-4,colors.orange,colors.red,"\127")
            write(1,height-2,"Skipping, might be slow",colors.yellow,colors.red)
        else
            rect(1,1+1,width,height-4,colors.orange)
            fill(1,height-2,24,height-2,colors.yellow)
        end

        if isPlaying then
            write(1,height-4,"Playing",colors.orange,colors.black)
        else
            write(1,height-4,"Stopped",colors.orange,colors.black)
        end

        term.setCursorPos(3,1)
        term.setBackgroundColor(colors.yellow)
        term.setTextColor(colors.red)

        local v = info_bar[info_active]
        term.write(v.name..v.value.." ")

        term.setCursorPos(old_posx,old_posy)
        term.setTextColor(old_fg)
        term.setBackgroundColor(old_bg)
        coroutine.yield()
    end
end

function player()
    while true do
        if isPlaying then
            isSkipping = false
            if startSong then
                info_bar[1].value = playing
                debug("starting song")
                startSong = false
                if playlist[playing] then
                    debug("playing song")
                    playAudio(playlist[playing])
                    debug("stopped playing song")
                else
                    isPlaying = false
                    startSong = false
                    playing = 0
                end
                coroutine.yield()
            end
        end
        coroutine.yield()
    end
end

local function timerstuff()
    while true do
        timer = timer+1
        if timer > 60 then
            timer = 0
            if info_active < #info_bar then
                info_active = info_active+1
            else
                info_active = 1
            end
        end
        os.sleep(0)
    end
end


parallel.waitForAny(player,button_events,playlist_view,timerstuff)