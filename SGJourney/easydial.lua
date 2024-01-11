local sg = peripheral.find("basic_interface")

local address = {}
local display_address = {}

local input_text = ""

local function inputThread()
    while true do
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        print("Address:")
        for k,v in ipairs(address) do
            term.setTextColor(colors.white)
            term.write("-")
            if v.dialed then
                term.setTextColor(colors.orange)
            elseif v.dialing then
                term.setTextColor(colors.lightGray)
            else
                term.setTextColor(colors.gray)
            end
            term.write(v.num)
        end
        term.setTextColor(colors.white)
        term.write("-")
        term.setTextColor(colors.lightGray)
        term.write(input_text)

        local event = {os.pullEvent()}

        if event[1] == "char" then
            if event[2]:match("%d") then
                input_text = input_text..event[2]
            end
        end
        if event[1] == "key" then
            if event[2] == keys.backspace then
                input_text = input_text:sub(1, #input_text-1)
                if #input_text == 0 then
                    input_text = tostring(address[#address].num)

                    table.remove(address, #address)
                    table.remove(display_address, #display_address)
                end
            elseif event[2] == keys.enter or event[2] == keys.numPadEnter then
                if #input_text > 0 then
                    address[#address+1] = {
                        num=tonumber(input_text),
                        dialed=false
                    }
                    display_address[#display_address+1] = tonumber(input_text)
                    input_text = ""
                end
                address[#address+1] = {
                    num=0,
                    dialed=false,
                    dialing=false
                }
                display_address[#display_address+1] = 0
                while true do
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.white)
                    print("Address:")
                    local display_text = ""
                    for k,v in ipairs(address) do
                        if v.num ~= 0 then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.orange)
                            elseif v.dialing then
                                term.setTextColor(colors.lightGray)
                            else
                                term.setTextColor(colors.gray)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        elseif v.num == 0 and (v.dialing or v.dialed) then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.yellow)
                            else
                                term.setTextColor(colors.red)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        end
                    end
                    term.setTextColor(colors.white)
                    term.write("-")

                    if address[#address].dialed and sg.isStargateConnected() then
                        term.setTextColor(colors.orange)
                        term.setCursorPos(1,4)
                        term.write("Dialing Successful!")
                        term.setCursorPos(1,8)
                        return
                    end
                    
                    sleep(0.5)
                end
            elseif event[2] == keys.space then
                address[#address+1] = {
                    num=tonumber(input_text),
                    dialed=false
                }
                display_address[#display_address+1] = tonumber(input_text)
                input_text = ""
            end
        end
    end
end

local function dialThread()
    while true do
        for k,v in ipairs(address) do
            if not v.dialed then
                address[k].dialing = true
                if (v.num-sg.getCurrentSymbol()) % 39 < 19 then
                    sg.rotateAntiClockwise(v.num)
                else
                    sg.rotateClockwise(v.num)
                end
                
                repeat
                    sleep()
                until sg.getCurrentSymbol() == v.num
                sleep(0.25)
                sg.raiseChevron()
                sleep(0.25)
                sg.lowerChevron()
                address[k].dialing = false
                address[k].dialed = true
            end
            sleep(0.25)
        end
        sleep()
    end
end

parallel.waitForAny(inputThread, dialThread)