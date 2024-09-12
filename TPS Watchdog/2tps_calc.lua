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
    local curr_epoch = os.epoch("utc")
    local target = curr_epoch+sample_ms
    local old_time = os.epoch("ingame")/3600
    repeat
        sleep()
    until os.epoch("utc") >= target
    local new_time = os.epoch("ingame")/3600

    local delta = math.abs(new_time-old_time)
    
    return clamp((delta*(1000/sample_ms)), 0, 60), delta
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

local function getTickTime(tps)
    return (20/tps)*50
end

while true do
    local tps = get_tps(1000)
    term.clear()
    term.setCursorPos(1,1)

    table.insert(last_tps, 1, tonumber(string.format("%.2f", tps)))
    table.insert(last_tps_weight, 1, 1+(((tonumber(string.format("%.2f", tps))/20)-1)*-1))
    if #last_tps > 60 then
        table.remove(last_tps, 61)
        table.remove(last_tps_weight, 61)
    end

    print("TPS: \n"..string.format("%.2f (%.1fms)", tps, getTickTime(tps)))
    print("")
    local average = midrange_mean(last_tps)
    print("\nAverage TPS ("..#last_tps.." samples): \n"..string.format("%.2f (%.1fms)", average, getTickTime(average)))
    print("")
    if #last_tps < 60 then
        print("Building Samples.."..string.format("%.0f%%",(#last_tps/60)*100))
    end
end