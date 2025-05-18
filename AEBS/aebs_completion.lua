local completion = require "cc.shell.completion"
local choices = {}
if fs.exists("/.aebs_export") and fs.isDir("/.aebs_export") then
    local files = fs.list("/.aebs_export")
    for k,v in pairs(files) do
        choices[#choices+1] = v:match("(.+)%.aebs")
    end
end
local complete = completion.build(
  { completion.choice, choices }
)
shell.setCompletionFunction("aebs.lua", complete)