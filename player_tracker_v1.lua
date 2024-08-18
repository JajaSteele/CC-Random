local detector = peripheral.find("playerDetector")
local completion = require("cc.completion")

print("Select a player:")
local player = read(nil, nil, function(text) return completion.choice(text, detector.getOnlinePlayers()) end, "")

local display_window = window.create(term.current(), 1,1, term.getSize())

term.redirect(display_window)
local stat, err = pcall(function()
    while true do
        display_window.setVisible(false)
        term.clear()
        term.setCursorPos(1,1)
        print("-=# PLAYER TRACKER #=-")
        print("Username: "..player)
        print("")
        print("Pos: ")
        local data = detector.getPlayer(player)
        print(data.x.." "..data.y.." "..data.z)
        print(data.dimension)
        print("")
        print("Rotation: ")
        print(string.format("P: %.1f, Y: %.1f", data.pitch, data.yaw))
        print("")
        print("-- DETAILS --")
        print("HP: "..data.health.."/"..data.maxHeatlh)
        print("Air: "..data.airSupply)
        print("")
        if data.respawnPosition then
            print("-- RESPAWN --")
            print("Pos: ")
            print(data.respawnPosition.x.." "..data.respawnPosition.y.." "..data.respawnPosition.z)
            print(data.respawnDimension)
        end
        display_window.setVisible(true)
        sleep(0.25)
    end
end)


if not stat then
    term.redirect(term.native())
    error(err)
end