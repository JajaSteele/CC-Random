local disk_drive = peripheral.wrap("bottom")

local startup_program = ([[
    print("Starting Program '&p' in ]]..(0.5)..[[s")
    sleep(]]..(0.5)..[[)
    shell.execute("&p")
]])

if disk_drive.isDiskPresent() and disk_drive.hasData() then
    print("-Standalone Pocket Maker-")
    sleep(1)
    local dial_disk_mount = disk_drive.getMountPath()

    print("Copying Address Book..")
    local address_disk_mount = disk_drive.getMountPath()
    local addressbook_file = io.open("address_book.lua", "r")
    local addressbook = addressbook_file:read("*a")
    addressbook_file:close()

    print("Pasting Address Book..")
    local addressbook_local = io.open(dial_disk_mount.."/address_book.lua", "w")
    addressbook_local:write(addressbook)
    addressbook_local:close()



    print("Writing Startup..")
    local startup = startup_program:gsub("&p", "address_book.lua")
    local dial_startup_file = io.open(address_disk_mount.."/startup.lua", "w")
    dial_startup_file:write(startup)
    dial_startup_file:close()



    print("Copying Base Addresses..")
    local addresslist_disk_mount = disk_drive.getMountPath()
    local addresslist_file = io.open("saved_address.txt", "r")
    local addresslist = addresslist_file:read("*a")
    addresslist_file:close()

    print("Pasting Base Addresses..")
    local addresslist_local = io.open(dial_disk_mount.."/saved_address.txt", "w")
    addresslist_local:write(addresslist)
    addresslist_local:close()



    print("Copying Base Config..")
    local addressconfig_disk_mount = disk_drive.getMountPath()
    local addressconfig_file = io.open("saved_config.txt", "r")
    local addressconfig = addressconfig_file:read("*a")
    addressconfig_file:close()

    print("Pasting Base Config..")
    local addressconfig_local = io.open(dial_disk_mount.."/saved_config.txt", "w")
    addressconfig_local:write(addressconfig)
    addressconfig_local:close()
end