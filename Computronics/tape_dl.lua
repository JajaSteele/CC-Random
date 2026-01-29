local tape = peripheral.find("tape_drive")

local function secondsToDuration(seconds)
    local sec = math.floor(seconds%60)
    local min = math.floor((seconds/60)%60)
    local hour = math.floor(min/60)

    local output = string.format("%.0f:%02d", min, sec)
    if hour > 0 then
        output = string.format("%.0f", hour)..output
    end

    return output
end

local function bytesToString(bytes)
    if bytes > 1000000 then
        return string.format("%.2f MB", bytes/1000000)
    elseif bytes > 1000 then
        return string.format("%.2f KB", bytes/1000)
    else
        return string.format("%.2f B", bytes)
    end
end

local tape_sizes = {
    2,
    4,
    6,
    8,
    16,
    32,
    64,
    128
}

term.clear()

print("Enter Youtube ID:")
local id = io.read()

print("")

print("High quality mode allows to have better song quality, but requires a tape twice the size/length of the song")
print("High Quality Mode? (Y/N):")

local hq = io.read():lower()
if hq == "true" or hq == "y" or hq == "1" or hq == "" then
    hq = true
else
    hq = false
end

local tape_size = tape.getSize()

local req = http.get("http://jajasteele.mooo.com:7277/?vidid="..id.."&hq="..tostring(hq), nil, true)
local req_size = tonumber(req.getResponseHeaders()["content-length"])

print("")

print("Audio Size: "..bytesToString(req_size).." ("..secondsToDuration(req_size/6000)..")")
for k, v in ipairs(tape_sizes) do
    if v*60 >= (req_size/6000) then
        print("Cassette size required: "..v.." minutes")
        break
    end
end
print("Insert cassette in the drive, then enter a label:")
local label = io.read()
local item_label = ""
if hq then
    item_label = "\xA76"..label
else
    item_label = "\xA77"..label
end

print("")

tape.seek(-tape_size+5)

print("Erasing tape data..")

tape.write(string.rep(string.char(0), tape_size))

tape.seek(-tape_size+5)

print("Writing song to tape..")

local wrote = tape.write(req.readAll())
print("Wrote "..bytesToString(wrote).." ("..secondsToDuration(wrote/6000)..") of audio data.")

tape.setLabel(item_label)

print("")

tape.seek(-tape_size)
print("Tape '"..label.."' rewinded and ready to use!")
if hq then
    print("Don't forget to play this tape (or any tape with a gold label) at 200% speed!")
end

req.close()