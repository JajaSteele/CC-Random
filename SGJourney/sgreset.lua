local interfaces = {peripheral.find("advanced_crystal_interface")}

for k,v in pairs(interfaces) do
    v.disconnectStargate()
end