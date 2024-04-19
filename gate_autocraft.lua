while true do
    local exist, data = turtle.inspect()

    if exist and data.name == "sgjourney:classic_stargate" then
        print("Mining gate..")
        turtle.dig()
    end
    
    sleep(1)
end