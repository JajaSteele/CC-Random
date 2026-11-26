local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    local new_x, new_y = term.getCursorPos()

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
    return new_x, new_y
end

local function getArgs(fun)
  local args = {}
  local hook = debug.gethook()

  local argHook = function( ... )
    local info = debug.getinfo(3)
    if 'pcall' ~= info.name then return end

    for i = 1, math.huge do
      local name, value = debug.getlocal(2, i)
      if '(*temporary)' == name then
        debug.sethook(hook)
        error('')
        return
      end
      table.insert(args,name)
    end
  end

  debug.sethook(argHook, "c")
  pcall(fun)
  
  return args
end

local peripheral_wraps = peripheral.getNames()
local periphs = {}
for k,v in pairs(peripheral_wraps) do
    local periph = peripheral.wrap(v)
    local methods = peripheral.getMethods(v)
    table.sort(methods)
    periphs[#periphs+1] = {
        name=v,
        type=peripheral.getType(periph),
        peripheral = periph,
        methods=methods
    }
end

local threads = {}
local buttons = {}

local line_count = 0
local scroll = 0
local mode = 0
local selected_periph
local selected_method

local w,h = term.getSize()
local start_pos = 3
local end_pos = h-1

local arg_tests = {
    {
        data=0,
        type="num"
    },
    {
        data="",
        type="str"
    },
    {
        data=false,
        type="bol"
    },
    {
        data={},
        type="tbl"
    },
    {
        data=function()
        end,
        type="fun"
    }
}

threads[#threads+1] = function()
    while true do
        os.pullEvent("jjs_drawgui")

        term.clear()
        fill(1,1, w,1, colors.gray)
        write(1,1, "Peripheral Explorer", colors.gray, colors.white)
        local draw_pos = 0
        local index = 1
        buttons = {}
        if mode == 0 then
            line_count = 0
            while true do
                local periph = periphs[index+scroll]
                if periph then
                    local newx = write(3, start_pos+draw_pos, periph.type, colors.black, colors.yellow)
                    newx = write(newx+2, start_pos+draw_pos, "("..periph.name..")", colors.black, colors.lightGray)
                    buttons[start_pos+draw_pos] = function(button)
                        mode = 1
                        selected_periph = periph
                        scroll = 0
                        os.queueEvent("jjs_drawgui")
                    end
                    line_count = line_count + 1
                    draw_pos = draw_pos + 1
                    if start_pos+draw_pos > end_pos then
                        break
                    end
                end
                index = index + 1
                if index > #periphs then
                    break
                end
            end
        elseif mode == 1 then
            line_count = 0
            fill(1,1, w,1, colors.gray)
            local newx = write(1,1, selected_periph.type, colors.gray, colors.yellow)
            write(newx+1,1, "("..selected_periph.name..")", colors.gray, colors.orange)
            while true do
                local methods = selected_periph.methods
                local method = methods[index+scroll]
                if method then
                    local func = selected_periph.peripheral[method]
                    local funci = debug.getinfo(func)
                    local func_params
                    if funci.isvararg then
                        func_params = "? args"
                    else
                        func_params = funci.nparams.." args"
                    end
                    local newx = write(3, start_pos+draw_pos, method, colors.black, colors.lightBlue)
                    newx = write(newx+2, start_pos+draw_pos, "("..tostring(func_params)..")", colors.black, colors.blue)
                    buttons[start_pos+draw_pos] = function(button)
                        local height = start_pos+draw_pos
                        local newx = write(3, height, method, colors.black, colors.red)
                        newx = write(newx+2, height, "(PROBING)", colors.black, colors.brown)

                        local arg_count = 0

                        local output_args = {}
                        local args_list = {}
                        
                        while true do
                            --[[ local args = {}
                            local end_count = 0
                            for i1=1, arg_count do
                                local new = (args_list[i1] or 0) + 1
                                if new > #arg_tests then
                                    new = 1
                                elseif new == #arg_tests then
                                    end_count = end_count + 1
                                end
                                args_list[i1] = new
                            end
                            write(1, h, table.concat(args_list, ", "), colors.black, colors.red)
                            for k,v in ipairs(args_list) do
                                args[#args+1] = arg_tests[v].data
                            end
                            local stat, err = pcall(func, table.unpack(args))
                            --write(1, h, tostring(stat), colors.black, colors.red)
                            if not stat then
                                if end_count == arg_count then
                                    arg_count = arg_count + 1
                                end
                            else
                                for k,v in ipairs(args_list) do
                                    output_args[#output_args+1] = {
                                        type=arg_tests[v].type,
                                    }
                                end
                                break
                            end ]]
                            local args = {}
                            write(1, h, table.concat(args_list, ", "), colors.black, colors.red)
                            for k,v in ipairs(args_list) do
                                args[#args+1] = arg_tests[v].data
                            end
                            local stat, err = pcall(func, table.unpack(args))
                            if not stat then
                                if err:match("bad argument") then
                                    local 
                                end
                            end
                            sleep(1)
                        end

                        mode = 2
                        selected_method = {
                            name=method,
                            func=func,
                            data=output_args,
                        }
                        scroll = 0
                        os.queueEvent("jjs_drawgui")
                    end
                    line_count = line_count + 1
                    draw_pos = draw_pos + 1
                    if start_pos+draw_pos > end_pos then
                        break
                    end
                end
                index = index + 1
                if index > #methods then
                    break
                end
            end
        elseif mode == 2 then
            fill(1,1, w,1, colors.gray)
            write(1,1, selected_method.name, colors.gray, colors.lightBlue)
            while true do
                local arg = selected_method.data[index+scroll]
                if arg then
                    local newx = write(3, start_pos+draw_pos, arg.type, colors.black, colors.lightBlue)
                    buttons[start_pos+draw_pos] = function(button)
                        mode = 0
                        scroll = 0
                        os.queueEvent("jjs_drawgui")
                    end
                    line_count = line_count + 1
                    draw_pos = draw_pos + 1
                    if start_pos+draw_pos > end_pos then
                        break
                    end
                end
                index = index + 1
                if index > #selected_method.data then
                    break
                end
            end
        end
    end
end

threads[#threads+1] = function()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if button == 2 then
            mode = clamp(mode-1, 0, 100)
            os.queueEvent("jjs_drawgui")
        else
            if buttons[y] then
                buttons[y](button)
            end
        end
    end
end

threads[#threads+1] = function()
    while true do
        local event, dir, x, y = os.pullEvent("mouse_scroll")
        local old = scroll
        local max
        local page_size = end_pos-start_pos
        if mode == 0 then
            max = math.max(#periphs-(page_size), 0)
        elseif mode == 1 then
            max = math.max(#(selected_periph.methods)-(page_size), 0)
        elseif mode == 2 then
            max = math.max(#(selected_method.data_list)-(page_size), 0)
        end
        scroll = clamp(scroll + dir, 0, max)
        if scroll ~= old then
            os.queueEvent("jjs_drawgui")
        end
    end
end

os.queueEvent("jjs_drawgui")
parallel.waitForAll(table.unpack(threads))