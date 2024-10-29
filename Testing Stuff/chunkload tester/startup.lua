local function log_to_file(txt)
    local data = ""
    local old_io = io.open(".debug.log", "r")
    if old_io then
        data = old_io:read("*a")
        old_io:close()
    end
    data = data .. os.date("\n[%H.%M.%S] > ") .. txt
    local new_io = io.open(".debug.log", "w")
    new_io:write(data)
    new_io:close()
end

log_to_file("Loaded!")