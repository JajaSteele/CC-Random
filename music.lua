speaker = peripheral.find("speaker")

if speaker == nil then
    pocket.unequipBack()
    os.sleep(0.5)
    pocket.equipBack("speaker")
    speaker = peripheral.find("speaker")
    if speaker == nil then
        print("No Speaker Found!")
        return
    end
end

homeX = 1
homeY = 1

c = colors

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end
local function setpos(x,y)
    term.setCursorPos(x,y)
end
local function sethome(x,y)
    term.setCursorPos(x,y)
    homeX = x
    homeY = y
end
local function down()
    currX,currY = term.getCursorPos()
    term.setCursorPos(homeX,currY+1)
end
local function w(t)
    term.write(t)
end
local function wd(t)
    term.write(t)
    down()
end
local function sc(c)
    term.setTextColor(c)
end
local function sbc(c)
    term.setBackgroundColor(c)
end

list = 1

listnames = {
    "Vanilla Disc",
    "Vanilla Music",
    "Modded 1"
}

vanilla_disc_list = {
    "13",
    "cat",
    "blocks",
    "chirp",
    "far",
    "mall",
    "mellohi",
    "stal",
    "strad",
    "ward",
    "11",
    "wait",
    "pigstep"
}

vanilla_music_list = {
    "creative",
    "credits",
    "dragon",
    "end",
    "game",
    "menu",
    "under_water",
    "nether.basalt_deltas",
    "nether.crimson_forest",
    "nether.nether_wastes",
    "nether.soul_sand_valley",
    "nether.warped_forest"
}

modded_1_list = {
    "quark:music.endermosh",
    "quark:ambient.chatter",
    "quark:ambient.clock",
    "quark:ambient.crickets",
    "quark:ambient.drips",
    "quark:ambient.fire",
    "quark:ambient.ocean",
    "quark:ambient.rain",
    "quark:ambient.wind"
}

mX,mY = term.getSize()

playing = 0
playinglist = 1

drawUItoggle = true

customsound = ""

function drawUI()
    while true do
        if drawUItoggle == true then
            clear()
            setpos(1,1)
            w("Select Music:")
            sethome(2,2)
            sc(c.red)
            w(listnames[list])
            sc(c.gray)
            w(" ("..list.."/"..#listnames..")")
            sc(c.white)
            sethome(3,3)
            if list == 1 then
                for i1=1, #vanilla_disc_list do
                    if i1 == playing and playinglist == list then
                        sc(c.lime)
                    else
                        sc(c.white)
                    end
                    wd(vanilla_disc_list[i1])
                end
            end
            if list == 2 then
                for i1=1, #vanilla_music_list do
                    if i1 == playing and playinglist == list then
                        sc(c.lime)
                    else
                        sc(c.white)
                    end
                    wd(vanilla_music_list[i1])
                end
            end
            if list == 3 then
                for i1=1, #modded_1_list do
                    if i1 == playing and playinglist == list then
                        sc(c.lime)
                    else
                        sc(c.white)
                    end
                    wd(modded_1_list[i1])
                end
            end
            setpos(1,mY)
            sc(c.red)
            w("STOP")
            setpos(mX-3,mY)
            w("EXIT")
            sc(c.white)
            setpos(1,mY-1)
            w(customsound)
            setpos(6,mY)
            w("CUSTOM PLAY")
        end
        os.sleep(0.5)
    end
end

function clickListener()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")

        if y == 2 then
            if list < #listnames and button == 1 then
                list = list+1
            elseif list > 1 and button == 2 then
                list = list-1
            end
        end

        if y == (mY) and x < 5 then
            speaker.stop()
            playing = 0
        end
        if y == (mY) and x > (mX-4) then
            os.reboot()
        end
        if y == (mY) and x > 5 and x < 10 then
            drawUItoggle = false
            os.sleep(0.5)
            setpos(1,mY-1)
            term.clearLine()
            customsound = io.read()
            drawUItoggle = true
        end
        if y == (mY) and x > 12 and x < 12+5 then
            speaker.stop()
            os.sleep(0.5)
            speaker.playSound(customsound)
        end
        if y > 2 then
            selected = y-2
            if list == 1 and vanilla_disc_list[selected] ~= nil then
                speaker.stop()
                os.sleep(0.25)
                speaker.playSound("minecraft:music_disc."..vanilla_disc_list[selected])
                playing = selected
                playinglist = 1
            end

            if list == 2 and vanilla_music_list[selected] ~= nil then
                speaker.stop()
                os.sleep(0.25)
                speaker.playSound("minecraft:music."..vanilla_music_list[selected])
                playing = selected
                playinglist = 2
            end

            if list == 3 and modded_1_list[selected] ~= nil then
                speaker.stop()
                os.sleep(0.25)
                speaker.playSound(modded_1_list[selected])
                playing = selected
                playinglist = 3
            end
        end
    end
end

parallel.waitForAny(clickListener,drawUI)