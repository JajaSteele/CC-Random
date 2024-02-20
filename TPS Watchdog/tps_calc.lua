local function clamp(x,min,max)
    if x > max then
        return max
    elseif x < min then
        return min
    else
        return x
    end
end

local function get_tps(sample_ms)
    local old_time = os.epoch("utc")
    sleep(sample_ms/1000)
    local new_time = os.epoch("utc")

    local delta = math.abs(new_time-old_time)
    
    return clamp(((sample_ms)/delta)*20, 0, 20)
end


local function sum(x)
  local s = 0
  for _, v in pairs(x) do s = s + v end
  return s
end

function math.log10(x)
    return math.log(x) / math.log(10)
end

local function midrange_mean(x)
  local sump = 0
  return 0.5 * (math.min(table.unpack(x)) + math.max(table.unpack(x)))
end

local function energetic_mean(x)
  local s = 0
  for _,v in ipairs(x) do s = s + (10 ^ (v / 10)) end
  return 10 * math.log10((1 / #x) * s)
end

local function weighted_mean(x, w)
  local sump = 0
  for i, v in ipairs (x) do sump = sump + (v * w[i]) end
  return sump / sum(w)
end

local last_tps = {}
local last_tps_weight = {}

local send_average_time = os.epoch("utc")+30000

while true do
    local tps = get_tps(500)
    term.clear()
    term.setCursorPos(1,1)

    table.insert(last_tps, 1, tonumber(string.format("%.2f", tps)))
    table.insert(last_tps_weight, 1, 1+(((tonumber(string.format("%.2f", tps))/20)-1)*-1))
    if #last_tps > 60 then
        table.remove(last_tps, 61)
        table.remove(last_tps_weight, 61)
    end

    print("TPS: \n"..string.format("%.1f", tps))
    print("")
    print("\nAverage TPS ("..#last_tps.." samples): \n"..string.format("%.1f", weighted_mean(last_tps, last_tps_weight)))
    print("")
    if #last_tps < 60 then
        print("Building Samples.."..string.format("%.0f%%",(#last_tps/60)*100))
    end

    if os.epoch("utc") >= send_average_time and #last_tps >= 60 then
        print("Sent Average")
        send_average_time = os.epoch("utc")+30000
    else
        print("Sending Average in "..string.format("%.0f", (send_average_time - os.epoch("utc"))/1000).."s")
    end
end