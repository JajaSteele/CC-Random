local d = peripheral.find("statue_workbench")

local function hslToRgb(h, s, l, a)
    local r, g, b
    h,s,l = h/360, s/100, l/100
    a = a or 100

    local hue2rgb
  
    if s == 0 then
      r, g, b = l, l, l -- achromatic
    else
      function hue2rgb(p, q, t)
        if t < 0   then t = t + 1 end
        if t > 1   then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
      end
  
      local q
      if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
      local p = 2 * l - q
  
      r = hue2rgb(p, q, h + 1/3)
      g = hue2rgb(p, q, h)
      b = hue2rgb(p, q, h - 1/3)
    end
  
    return r * 255, g * 255, b * 255, a * 255
  end

local function hexToRgb(hex)
    hex = string.format("%x", hex)
    print("hexToRgb: "..hex)
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return r, g, b
end

local function rgbToHsl(r, g, b)
    r,g,b = r/255, g/255, b/255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max == min then
        -- Achromatic color (grey)
        h, s = 0, 0
    else
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)

        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        elseif max == b then
            h = (r - g) / d + 4
        end

        h = h / 6
    end

    return h*360, s*100, l*100
end


local function rgbToHex(r,g,b)
    local rgb = {r,g,b}
	local hexadecimal = '0X'

	for key, value in pairs(rgb) do
		local hex = ''

		while(value > 0)do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex			
		end

		if(string.len(hex) == 0)then
			hex = '00'

		elseif(string.len(hex) == 1)then
			hex = '0' .. hex
		end

		hexadecimal = hexadecimal .. hex
	end

    print("rgbToHex: "..hexadecimal)
	return hexadecimal
end

while true do
    local current_shape = d.getCubes()
    local new_shape = {}
    for k,v in pairs(current_shape) do
        local old_hex = v.tint
        print(old_hex)
        local old_r, old_g, old_b = hexToRgb(old_hex)
        local old_h, old_s, old_l = rgbToHsl(old_r, old_g, old_b)
        print("Old HSL: "..old_h, old_s, old_l)
        print("Old RGB: "..old_r, old_g, old_b)
        local new_h = (old_h+6)%360
        print("New HSL: "..new_h, old_s, old_l)
        local new_r, new_g, new_b = hslToRgb(new_h, old_s, old_l)
        print("New RGB: "..new_r, new_g, new_b)
        new_shape[#new_shape+1] = {
            x1=v.x1,
            x2=v.x2,
            y1=v.y1,
            y2=v.y2,
            z1=v.z1,
            z2=v.z2,
            tint = tonumber(rgbToHex(new_r, new_g, new_b))
        }
    end
    d.setCubes(new_shape)
    d.setLightLevel(15)
    redstone.setOutput("top", not redstone.getOutput("top"))
    sleep()
end

