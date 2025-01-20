while true do
    local exist, data = turtle.inspectUp()

    if exist and data.name == "sgjourney:classic_stargate" then
        print("Mining gate..")
        turtle.digUp()
    end
    
    sleep(0.1)
end