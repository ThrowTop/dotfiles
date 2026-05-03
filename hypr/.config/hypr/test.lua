local hlc = require("hlc")

-- exec_sync test: runs at config load, result available immediately
local kernel = hlc.exec_sync("uname -r")
hlc.notify("exec_sync: kernel = " .. (kernel or "nil"))

-- exec_async test: non-blocking, result arrives via callback
hlc.exec_async("uname -r", function(result)
    hlc.notify("exec_async: kernel = " .. (result.stdout or "nil") .. " (code " .. result.code .. ")")
end)

-- exec_async bind test: non-blocking, notification arrives after 3s but compositor stays responsive
hl.bind("SUPER + SHIFT + G", function()
    hlc.notify("async: started")
    hlc.exec_async("sleep 3 && brightnessctl get", function(result)
        hlc.notify("async: brightness = " .. (result.stdout or "?") .. " (code " .. result.code .. ")")
    end)
end)

-- exec_sync bind test: blocks compositor for 3s before notification fires
hl.bind("SUPER + SHIFT + H", function()
    hlc.notify("sync: started")
    local out = hlc.exec_sync("sleep 3 && brightnessctl get")
    hlc.notify("sync: brightness = " .. (out or "?"))
end)


