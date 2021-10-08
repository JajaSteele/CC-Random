function timeColor(t1)
    time = os.time(t1)

    if time > 4.24 and time < 6.10 then
        bg = colors.orange
    end
    if time > 18.05 and time < 19.5 then
        bg = colors.orange
    end
    if time > 6.10 and time < 18.05 then
        bg = colors.lightBlue
    end

    if time > 0 and time < 4.24 then
        bg = colors.gray
    end
    if time < 0 and time > 19.5 then
        bg = colors.gray
    end
    return bg
end