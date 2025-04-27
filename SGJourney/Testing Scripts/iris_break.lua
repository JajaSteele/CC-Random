local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local trans = peripheral.find("transceiver")

print("Awaiting Outgoing")
os.pullEvent("stargate_outgoing_wormhole")
print("Received Outgoing")

print("Getting other side's percentage")
trans.checkConnectedShielding()