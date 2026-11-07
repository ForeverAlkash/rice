-- Prism autostart for Hyprland (Lua config, 0.55+).
-- install.sh loads this from the end of ~/.config/hypr/hyprland.lua with
--   dofile("<home>/.config/quickshell/hypr/prism.lua")
-- Each daemon is only started if it isn't already running, so it's safe next to
-- your own autostart.

local shell = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/quickshell"

hl.on("hyprland.start", function()
    -- wallpaper daemon; show the last wallpaper (Prism keeps a copy in .state/)
    hl.exec_cmd("pidof awww-daemon >/dev/null || awww-daemon")
    hl.exec_cmd("sleep 1; awww restore 2>/dev/null || awww img '" .. shell .. "/.state/wallpaper' --transition-type fade")
    hl.exec_cmd("pidof quickshell >/dev/null || quickshell")
    -- Bluetooth pairing agent; without it headphones drop on passkey requests
    hl.exec_cmd("pgrep -x bt-agent >/dev/null || bt-agent -c NoInputNoOutput")
    -- pgrep -f here would match this sh -c line itself; -x matches by exact
    -- process name instead, then grep picks the text/image watcher apart
    hl.exec_cmd("pgrep -ax wl-paste | grep -F -- '--type text' >/dev/null || wl-paste --type text --watch cliphist store")
    hl.exec_cmd("pgrep -ax wl-paste | grep -F -- '--type image' >/dev/null || wl-paste --type image --watch cliphist store")
    hl.exec_cmd("throne", { workspace = "special:magic silent" })
    hl.exec_cmd("Telegram", { workspace = "3 silent" })
    hl.exec_cmd("firefox", { workspace = "1" })
    hl.exec_cmd("hyprsunset -t 5500")
    -- touchpad swipe -> mouse4/5 (self-deduping: exits if already running)
    hl.exec_cmd("libinput-gestures")
    
end)
