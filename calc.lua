
args = {...}


result = string.format("%.0f",tonumber(args[1])/64)
result = result.." Stacks and "..tostring(math.mod(tonumber(args[1]),64)).." Items"

print(result)