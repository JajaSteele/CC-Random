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

term.clear()

print("Enter Youtube ID:")
local id = io.read()

print("High Quality Mode? (y/n):")
print("(will double file size, requires x2 playback speed)")
local hq = io.read()
if hq == "true" or hq == "y" or hq == "1" or hq == "" then
    hq = true
else
    hq = false
end

local tape_size = tape.getSize()

local req = http.get("http://jajasteele.mooo.com:7277/?vidid="..id.."&hq="..tostring(hq))
local req_size = tonumber(req.getResponseHeaders()["content-length"])

print("Audio Size: "..bytesToString(req_size).." ("..secondsToDuration(req_size/6000)..")")
print("Tape Size: "..bytesToString(tape_size).." ("..secondsToDuration(tape_size/6000)..")")

if req_size > tape_size then
    print("Warning! Tape is too small")
end

tape.seek(-tape_size)

local wrote = tape.write(req.readAll())
print("Wrote "..bytesToString(wrote).." ("..secondsToDuration(wrote/6000)..") of audio data.")

req.close()