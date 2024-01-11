local error = 0

for i1=1, 38 do
    print(i1)
    for i2=1, 4 do
        rs.setAnalogOutput("front", 14)
        sleep()
        rs.setAnalogOutput("front", 0)
    end
    error = error+0.6153846153846
    if error > 1 then
        repeat
            rs.setAnalogOutput("front", 14)
            sleep()
            rs.setAnalogOutput("front", 0)
            error = error-1
        until error < 1
    end
    sleep(1)
end