# Hyprland Lua API — Comprehensive Reference

> Source of truth: C++ source files in `src/config/lua/`.
> Every function entry includes the defining file and line number.

---

## Table of Contents

1. [Overview & Architecture](#overview--architecture)
2. [Execution Model & Timeouts](#execution-model--timeouts)
3. [Global `hl` Table — Top-Level Functions](#global-hl-table--top-level-functions)
4. [Configuration Functions](#configuration-functions)
5. [Query Functions](#query-functions)
6. [Dispatcher Functions (`hl.dsp`)](#dispatcher-functions-hldsp)
7. [Notification API (`hl.notification`)](#notification-api-hlnotification)
8. [Event System (`hl.on`)](#event-system-hlon)
9. [Objects Reference](#objects-reference)
   - [HL.Window](#hlwindow)
   - [HL.Workspace](#hlworkspace)
   - [HL.Monitor](#hlmonitor)
   - [HL.LayerSurface](#hllayersurface)
   - [HL.Notification](#hlnotification-object)
   - [HL.Timer](#hltimer)
   - [HL.Keybind](#hlkeybind)
   - [HL.EventSubscription](#hleventsubscription)
   - [HL.WindowRule](#hlwindowrule)
   - [HL.LayerRule](#hllayerrule)
10. [Window Rule Effects](#window-rule-effects)
11. [Layer Rule Effects](#layer-rule-effects)
12. [Workspace Rule Fields](#workspace-rule-fields)
13. [Monitor Rule Fields](#monitor-rule-fields)
14. [Device Configuration Fields](#device-configuration-fields)
15. [Selector Syntax](#selector-syntax)
16. [print() Override](#print-override)

---

## Overview & Architecture

The Lua API is rooted in a single global table `hl`. It is populated in:

**`src/config/lua/bindings/LuaBindingsRegistration.cpp:29`** — `registerBindingsImpl()`

The registration order is:

1. All object metatables (Window, Workspace, Monitor, LayerSurface, Timer, EventSubscription, WindowRule, LayerRule, Keybind, Notification) are registered.
2. The `__lua` keybind dispatcher is wired into `g_pKeybindManager`.
3. The `hl` table is created and populated by calling:
   - `registerConfigRuleBindings()` — `hl.config`, `hl.monitor`, `hl.window_rule`, etc.
   - `registerToplevelBindings()` — `hl.bind`, `hl.on`, `hl.timer`, etc.
   - `registerQueryBindings()` — `hl.get_windows`, `hl.get_monitor`, etc.
   - `registerDispatcherBindings()` — the `hl.dsp` sub-table.
   - `registerNotificationBindings()` — the `hl.notification` sub-table.
4. The global `print` function is replaced with a version that logs to Hyprland's logger.

The `hl` table is set as a global with `lua_setglobal(L, "hl")` at **`LuaBindingsRegistration.cpp:62`**.

---

## Execution Model & Timeouts

**`src/config/lua/ConfigManager.hpp:96–102`**

All Lua callbacks are run through a watchdog that fires every 10,000 VM instructions and kills the execution if the timeout is exceeded. The per-context timeouts are:

| Context                  | Timeout |
| ------------------------ | ------- |
| Config reload            | 1500 ms |
| Event callback (`hl.on`) | 50 ms   |
| Keybind callback         | 100 ms  |
| Timer callback           | 50 ms   |
| `hl.dispatch` / submap   | 100 ms  |
| `hl.eval`                | 250 ms  |

Recursive event callbacks are suppressed (with a warning logged) to prevent infinite loops.

---

## Global `hl` Table — Top-Level Functions

### `hl.bind(keys, fn, opts?)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:112`**

Registers a keybind. Returns a `HL.Keybind` object.

- `keys` — string. Key specification in the form `"MODIFIER+key"` (e.g., `"SUPER+Q"`, `"CTRL+ALT+Return"`, `"SUPER+mouse:273"`). Modifiers: `SHIFT`, `CAPS`, `CTRL`/`CONTROL`, `ALT`/`MOD1`, `MOD2`, `MOD3`, `SUPER`/`WIN`/`LOGO`/`MOD4`/`META`, `MOD5`. Special keys: `mouse_down`, `mouse_up`, `mouse_left`, `mouse_right`, `switch:...`, `mouse:...`. The special string `"catchall"` matches any key (only valid inside a submap).
- `fn` — function or dispatcher closure (e.g., `hl.dsp.window.close()`).
- `opts` — optional table:
  - `repeating` (bool) — fire repeatedly while held.
  - `locked` (bool) — active even when session is locked.
  - `release` (bool) — fire on key release instead of press.
  - `non_consuming` (bool) — do not consume the key event.
  - `transparent` (bool) — pass the key through.
  - `ignore_mods` (bool) — ignore modifier state.
  - `dont_inhibit` (bool) — do not inhibit shortcuts.
  - `long_press` (bool) — fire after a long press. Mutually exclusive with `repeat`.
  - `submap_universal` (bool) — active in all submaps.
  - `description`/`desc` (string) — human-readable description.
  - `click` (bool) — treat as a mouse click (implies `release = true`). Mutually exclusive with `drag`.
  - `drag` (bool) — treat as a mouse drag (implies `release = true`). Mutually exclusive with `click`.
  - `device` (table) — device filter:
    - `inclusive` (bool, default true)
    - `list` (array of strings) — device name list.

```lua
local kb = hl.bind("SUPER+Q", function()
    print("Hello!")
end, { description = "Say hello", repeating = false })
```

---

### `hl.define_submap(name, [reset_key], fn)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:233`**

Defines a keybind submap. All `hl.bind()` calls inside `fn` are registered under the submap `name`. Returns nothing.

- `name` — string, submap name.
- `reset_key` — optional string, key to return to the default submap.
- `fn` — function, called immediately during config evaluation; all binds inside it belong to this submap.

```lua
hl.define_submap("resize", "Escape", function()
    hl.bind("H", hl.dsp.window.resize({ x = -20, y = 0 }), { repeating = true })
    hl.bind("L", hl.dsp.window.resize({ x = 20, y = 0 }), { repeating = true })
end)
```

---

### `hl.unbind(mods, key)` / `hl.unbind("all")`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:328`**

Removes a keybind or all keybinds.

- `hl.unbind("all")` — removes every registered keybind.
- `hl.unbind(mods, key)` — removes the keybind for the given modifier mask and key. Key can be a keysym name, a numeric keycode string (e.g. `"65"` or `"code:65"`), or `"catchall"`.

---

### `hl.on(event, callback)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:303`**

Subscribes to a Hyprland event. Returns a `HL.EventSubscription` object.

- `event` — string, event name. See [Event System](#event-system-hlon) for the full list.
- `callback` — function. Arguments depend on the event.

```lua
local sub = hl.on("window.open", function(win)
    print("Opened: " .. win.class)
end)
```

---

### `hl.timer(fn, opts)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:354`**

Creates a recurring or one-shot timer. Returns a `HL.Timer` object.

- `fn` — function, called on each tick.
- `opts` — required table:
  - `timeout` (number, required) — interval in milliseconds. Must be > 0.
  - `type` (string, required) — `"repeat"` or `"oneshot"`.

```lua
local t = hl.timer(function()
    print("tick")
end, { timeout = 1000, type = "repeat" })
```

---

### `hl.dispatch(dispatcher)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:283`**

Immediately executes a dispatcher closure. Unlike binding a dispatcher to a key, this calls it right now.

- `dispatcher` — a dispatcher closure created by an `hl.dsp.*` function.

```lua
hl.dispatch(hl.dsp.window.close())
```

---

### `hl.version()`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:262`**

Returns the Hyprland version string (the `HYPRLAND_VERSION` compile-time constant).

```lua
print(hl.version())
```

---

### `hl.exec_cmd(cmd, rule?)`

**`src/config/lua/bindings/LuaBindingsToplevel.cpp:267`**

Spawns a command with optional window rule effects applied to the spawned window. Returns nothing (runs asynchronously).

- `cmd` — string, shell command to execute.
- `rule` — optional table of window rule effects (same keys as `hl.window_rule` effects).

```lua
hl.exec_cmd("kitty")
hl.exec_cmd("kitty", { workspace = "special:scratch", float = true })
```

---

## Configuration Functions

### `hl.config(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:812`**

Sets Hyprland configuration values. The table is a nested structure mirroring the config namespace hierarchy (keys joined with `.`). Unknown keys produce a config error.

```lua
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
    },
    decoration = {
        rounding = 10,
    },
})
```

---

### `hl.get_config(key)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:861`**

Reads a configuration value by key. The key uses dot notation (e.g., `"general.gaps_in"`). Colons (`:`) are also accepted and converted to dots. Returns the current value, or `nil, "error message"` if not found.

```lua
local gaps = hl.get_config("general.gaps_in")
```

---

### `hl.device(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:883`**

Configures an input device. The `name` field (required, string) identifies the device; spaces in the name are normalized to hyphens. See [Device Configuration Fields](#device-configuration-fields) for all accepted keys.

```lua
hl.device({
    name = "my-keyboard",
    kb_layout = "us,se",
    kb_options = "grp:alt_shift_toggle",
    repeat_rate = 30,
    repeat_delay = 400,
})
```

---

### `hl.monitor(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:945`**

Declares or updates a monitor rule. The `output` field (required) identifies the monitor by name (e.g., `"eDP-1"`, `"HDMI-A-1"`, or `","` for all). See [Monitor Rule Fields](#monitor-rule-fields).

```lua
hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    scale = 1.5,
    position = "0x0",
})
```

---

### `hl.window_rule(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:1016`**

Creates or updates a window rule. Returns a `HL.WindowRule` object.

- `name` (string, optional) — named rules can be updated by calling `hl.window_rule` again with the same name.
- `enabled` (bool, optional, default true) — enable or disable the rule.
- `match` (table, optional) — match conditions. Keys are match property names (e.g., `class`, `title`, `floating`, `xwayland`, `workspace`, `monitor`, `tag`, `pid`, `initialClass`, `initialTitle`, `fullscreen`, `pinned`, `focus`, `onWorkspace`, `onMonitor`). Values are strings, booleans, or numbers.
- All [Window Rule Effects](#window-rule-effects) as additional keys.

```lua
local rule = hl.window_rule({
    name = "float-pavucontrol",
    match = { class = "pavucontrol" },
    float = true,
    size = "800 600",
    center = true,
})
-- Disable it later:
hl.window_rule({ name = "float-pavucontrol", enabled = false })
```

---

### `hl.layer_rule(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:1129`**

Creates or updates a layer surface rule. Returns a `HL.LayerRule` object.

- `name` (string, optional) — named rules can be updated.
- `enabled` (bool, optional, default true).
- `match` (table, optional) — match conditions (same keys as window rule match).
- All [Layer Rule Effects](#layer-rule-effects) as additional keys.

```lua
hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
    blur_popups = true,
})
```

---

### `hl.workspace_rule(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:550`**

Declares a workspace rule. See [Workspace Rule Fields](#workspace-rule-fields).

- `workspace` (string, required) — workspace selector string.
- `enabled` (bool, optional, default true).
- `layout_opts` (table, optional) — layout-specific options as string/bool/number key-value pairs.

```lua
hl.workspace_rule({
    workspace = "1",
    monitor = "eDP-1",
    default = true,
    gaps_in = "5 5 5 5",
})
```

---

### `hl.env(name, value, dbus?)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:413`**

Sets an environment variable. On first launch it exports it; on reload it only re-exports if the value changed.

- `name` — string, variable name. Must not be empty.
- `value` — string, variable value.
- `dbus` — optional bool. If true, also exports via `dbus-update-activation-environment` (and `systemctl --user import-environment` if systemd is available). The DBus export runs once on first launch.

```lua
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct", true)
```

---

### `hl.permission(binary, type, mode)` / `hl.permission({binary, type, mode})`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:491`**

Declares a permission rule for a binary. Only takes effect on first launch.

- `binary`/`target` — string, binary path or name.
- `type` — string: `"screencopy"`, `"cursorpos"`, `"plugin"`, `"keyboard"`/`"keeb"`.
- `mode` — string: `"ask"`, `"allow"`, `"deny"`.

Can be called as `hl.permission(binary, type, mode)` (three positional args) or as a table `hl.permission({ binary = "...", type = "...", mode = "..." })`.

```lua
hl.permission("obs", "screencopy", "allow")
hl.permission({ binary = "wl-mirror", type = "screencopy", mode = "ask" })
```

---

### `hl.plugin.load(path)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:472`**

Registers a plugin `.so` file to be loaded on startup.

```lua
hl.plugin.load("~/.config/hypr/plugins/myplugin.so")
```

---

### `hl.curve(name, table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:280`**

Defines a named bezier curve for use in animations.

- `name` — string, curve name.
- `table`:
  - `type` — string, must be `"bezier"`.
  - `points` — array of exactly 2 points, each a `{x, y}` array (float values).

```lua
hl.curve("myBezier", {
    type = "bezier",
    points = { {0.05, 0.9}, {0.1, 1.05} },
})
```

---

### `hl.animation(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:344`**

Configures an animation node.

- `leaf` (string, required) — animation tree node name (e.g., `"global"`, `"windows"`, `"fade"`, `"workspaces"`).
- `enabled` (bool, required).
- `speed` (number, required if enabled) — animation speed. Must be > 0.
- `bezier` (string, required if enabled) — bezier curve name.
- `style` (string, optional) — animation style variant.

```lua
hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "fade", enabled = false })
```

---

### `hl.gesture(table)`

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:675`**

Registers a trackpad gesture.

- `fingers` (integer, 2–9, required).
- `direction` (string, required) — direction string accepted by the trackpad system.
- `action` (string or function, required) — one of `"workspace"`, `"resize"`, `"move"`, `"special"`, `"close"`, `"float"`, `"fullscreen"`, `"cursorZoom"`, `"unset"`, or a Lua function for custom behavior.
- `mods` (string, optional) — modifier mask string.
- `scale` (number 0.1–10, optional, default 1.0) — delta scale multiplier.
- `disable_inhibit` (bool, optional) — ignore gesture inhibition.
- `workspace_name` (string, optional) — workspace name for `"special"` action.
- `mode` (string, optional) — mode string for `"float"`, `"fullscreen"`, `"cursorZoom"`.
- `zoom_level` (string, optional) — zoom level for `"cursorZoom"`.

```lua
hl.gesture({ fingers = 3, direction = "right", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", action = function(delta)
    print("Custom gesture delta: " .. tostring(delta))
end })
```

---

## Query Functions

All query functions are on the `hl` global table.

### `hl.get_windows([filter])`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:106`**

Returns an array of `HL.Window` objects for all currently mapped windows. The optional `filter` table supports:

- `monitor` — HL.Monitor or selector string.
- `workspace` — HL.Workspace or selector string.
- `floating` (bool).
- `mapped` (bool, default true).
- `class` (string) — exact class match.
- `title` (string) — exact title match.
- `tag` (string) — tag match.

---

### `hl.get_window(selector)`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:132`**

Returns a single `HL.Window` matching the selector string, or `nil`. The selector is passed to `g_pCompositor->getWindowByRegex` (supports Hyprland's regex window selectors).

---

### `hl.get_active_window()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:121`**

Returns the currently focused `HL.Window`, or `nil`.

---

### `hl.get_urgent_window()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:143`**

Returns the urgent `HL.Window`, or `nil`.

---

### `hl.get_workspaces()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:154`**

Returns an array of all non-inert `HL.Workspace` objects.

---

### `hl.get_workspace(selector)`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:167`**

Returns a single `HL.Workspace` by selector string or HL.Workspace object, or `nil`.

---

### `hl.get_active_workspace([monitor])`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:178`**

Returns the active `HL.Workspace` on the specified monitor (or the focused monitor if no argument). Returns `nil` if none.

---

### `hl.get_active_special_workspace([monitor])`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:189`**

Returns the active special `HL.Workspace` on the specified monitor, or `nil`.

---

### `hl.get_monitors()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:200`**

Returns an array of all `HL.Monitor` objects.

---

### `hl.get_monitor(selector)`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:210`**

Returns a single `HL.Monitor` by selector, or `nil`.

---

### `hl.get_active_monitor()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:221`**

Returns the currently focused `HL.Monitor`, or `nil`.

---

### `hl.get_monitor_at(x, y)` / `hl.get_monitor_at({x, y})`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:232`**

Returns the `HL.Monitor` at the given global coordinates, or `nil`. Can be called with two numeric arguments or a table `{x = ..., y = ...}`.

---

### `hl.get_monitor_at_cursor()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:259`**

Returns the `HL.Monitor` currently under the cursor, or `nil`.

---

### `hl.get_layers([filter])`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:331`**

Returns an array of `HL.LayerSurface` objects. Optional filter table:

- `monitor` — HL.Monitor or selector.
- `namespace` (string) — exact namespace match.

---

### `hl.get_workspace_windows(workspace)`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:364`**

Returns an array of mapped `HL.Window` objects on the given workspace (HL.Workspace or selector).

---

### `hl.get_cursor_pos()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:270`**

Returns a table `{ x = number, y = number }` with the cursor's current global position, or `nil` if the input manager is unavailable.

---

### `hl.get_last_window()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:286`**

Returns the most recently focused mapped `HL.Window` that is not the current focus, or `nil` if history is empty.

---

### `hl.get_last_workspace([monitor])`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:306`**

Returns the previously active `HL.Workspace` on the given monitor (or focused monitor). Returns `nil` if no history.

---

### `hl.get_current_submap()`

**`src/config/lua/bindings/LuaBindingsQuery.cpp:375`**

Returns the name of the currently active submap as a string. Returns `""` when in the default submap.

---

## Dispatcher Functions (`hl.dsp`)

Dispatcher functions **return closures** — they do not execute immediately. Pass the returned closure to `hl.bind()` or `hl.dispatch()`.

All dispatchers that accept a `window` field in their table argument accept either an `HL.Window` object or a window selector string.

### Cursor Dispatchers

#### `hl.dsp.cursor.move_to_corner(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:58`**

Moves the cursor to a corner of a window.

- `corner` (number, required) — corner index (0=top-left, 1=top-right, 2=bottom-left, 3=bottom-right).
- `window` (optional) — target window.

---

#### `hl.dsp.cursor.move(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:68`**

Moves the cursor to absolute coordinates.

- `x` (number, required).
- `y` (number, required).

---

### Group Dispatchers

#### `hl.dsp.group.toggle([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:78`**

Toggles window grouping for a window.

- `window` (optional).

---

#### `hl.dsp.group.next([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:84`**

Cycles to the next window in the group.

- `window` (optional).

---

#### `hl.dsp.group.prev([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:91`**

Cycles to the previous window in the group.

- `window` (optional).

---

#### `hl.dsp.group.move_window([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:98`**

Moves the current window forward or backward in its group.

- `forward` (bool, optional, default true).

---

#### `hl.dsp.group.active(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:110`**

Sets the active window in a group by index.

- `index` (number, required).
- `window` (optional).

---

#### `hl.dsp.group.lock([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:120`**

Locks or unlocks all groups.

- `action` (string, optional) — `"toggle"` (default), `"enable"`/`"on"`, `"disable"`/`"off"`.

---

#### `hl.dsp.group.lock_active([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:128`**

Locks or unlocks the active group.

- `action` (string, optional) — same as above.

---

### Window Dispatchers

#### `hl.dsp.window.close([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:664`**

Sends a close request to a window.

- `window` (optional, in table).

---

#### `hl.dsp.window.kill([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:670`**

Force-kills a window.

- `window` (optional, in table).

---

#### `hl.dsp.window.signal(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:676`**

Sends a POSIX signal to a window's process.

- `signal` (number, required) — signal number.
- `window` (optional).

---

#### `hl.dsp.window.float([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:686`**

Toggles, enables, or disables floating for a window.

- `action` (string, optional) — `"toggle"`, `"enable"`/`"on"`, `"disable"`/`"off"`.
- `window` (optional).

---

#### `hl.dsp.window.fullscreen([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:695`**

Toggles/sets/unsets fullscreen for a window.

- `mode` (string, optional) — `"fullscreen"` (default) or `"maximized"`.
- `action` (string, optional) — `"toggle"` (default), `"set"`, `"unset"`.
- `window` (optional).

---

#### `hl.dsp.window.fullscreen_state(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:733`**

Sets the fullscreen state for both internal and client representations.

- `internal` (number, required) — internal fullscreen mode enum.
- `client` (number, required) — client fullscreen mode enum.
- `action` (string, optional) — `"toggle"`, `"set"` (default), `"unset"`.
- `window` (optional).

---

#### `hl.dsp.window.pseudo([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:762`**

Toggles pseudo-tiling for a window.

- `action` (string, optional) — `"toggle"`, `"enable"`, `"disable"`.
- `window` (optional).

---

#### `hl.dsp.window.move(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:771`**

Moves a window. Accepts one of several movement modes:

- `direction` (string) — `"left"`/`"l"`, `"right"`/`"r"`, `"up"`/`"u"`/`"t"`, `"down"`/`"d"`/`"b"`. Optional: `group_aware` (bool) for group-aware movement.
- `x`, `y` (numbers) — move to or by absolute/relative coordinates. Optional: `relative` (bool).
- `workspace` (workspace selector) — move to workspace. Optional: `follow` (bool, default true; set to false for silent move).
- `monitor` (monitor selector) — move to monitor's active workspace.
- `into_group` (direction string) — move into an adjacent group.
- `into_or_create_group` (direction string) — move into adjacent group or create new.
- `out_of_group` (direction string or bool) — move out of current group.
- `window` (optional, in any variant).

---

#### `hl.dsp.window.swap(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:871`**

Swaps a window with another. Modes:

- `direction` (string) — swap with adjacent tiled window in direction.
- `target`/`with`/`other` (window selector) — swap with specific window.
- `next` (bool, true) — swap with next window in focus history.
- `prev` (bool, true) — swap with previous window.
- `window` (optional).

---

#### `hl.dsp.window.center([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:918`**

Centers a floating window on its monitor.

- `window` (optional, in table).

---

#### `hl.dsp.window.cycle_next([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:924`**

Cycles focus to the next/previous window.

- `next` (bool, optional, default true) — direction.
- `tiled` (bool, optional) — restrict to tiled only.
- `floating` (bool, optional) — restrict to floating only.
- `window` (optional).

---

#### `hl.dsp.window.tag(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:947`**

Tags a window.

- `tag` (string, required).
- `window` (optional).

---

#### `hl.dsp.window.toggle_swallow()`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:958`**

Toggles window swallowing.

---

#### `hl.dsp.window.pin([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:979`**

Pins/unpins a window (shows on all workspaces).

- `action` (string, optional) — `"toggle"`, `"enable"`, `"disable"`.
- `window` (optional).

---

#### `hl.dsp.window.bring_to_top()`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:988`**

Brings the focused window to the top of the Z-order.

---

#### `hl.dsp.window.alter_zorder(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:993`**

Alters the Z-order of a window.

- `mode` (string, required) — Z-order mode string (e.g., `"top"`, `"bottom"`).
- `window` (optional).

---

#### `hl.dsp.window.set_prop(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1004`**

Sets a window property at runtime.

- `prop` (string, required) — property name.
- `value` (string, required) — property value.
- `window` (optional).

---

#### `hl.dsp.window.deny_from_group([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1017`**

Denies the current/specified window from being added to groups.

- `action` (string, optional) — `"toggle"`, `"enable"`, `"disable"`.

---

#### `hl.dsp.window.drag()`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1025`**

Starts a mouse drag on the focused window.

---

#### `hl.dsp.window.resize([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1030`**

With no arguments: starts a mouse resize. With a table: resizes to exact dimensions.

- `x` (number, required) — width or delta.
- `y` (number, required) — height or delta.
- `relative` (bool, optional) — interpret as delta rather than absolute size.
- `window` (optional).

---

### Workspace Dispatchers

#### `hl.dsp.workspace.rename(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1211`**

Renames a workspace.

- `id` (workspace selector, required).
- `name` (string, optional) — new name; omit to clear.

---

#### `hl.dsp.workspace.move(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1227`**

Moves a workspace to a monitor, or moves the current workspace.

- `monitor` (monitor selector, required).
- `id` (workspace selector, optional) — specific workspace to move; if omitted, moves the current workspace.

---

#### `hl.dsp.workspace.swap_monitors(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1246`**

Swaps the active workspaces between two monitors.

- `monitor1` (monitor selector, required).
- `monitor2` (monitor selector, required).

---

#### `hl.dsp.workspace.toggle_special([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1205`**

Toggles a special workspace.

- `name` (string, optional, in table) — special workspace name (without the `special:` prefix). Defaults to the default special workspace.

---

### Focus Dispatcher

#### `hl.dsp.focus(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:1086`**

Focuses a window, monitor, or workspace. Accepts one of:

- `direction` (string) — focus in direction: `"left"`, `"right"`, `"up"`, `"down"`.
- `monitor` (monitor selector) — focus a monitor.
- `window` (window selector) — focus a specific window.
- `workspace` (workspace selector) — change to workspace. Optional: `on_current_monitor` (bool) — focus workspace on current monitor without moving focus.
- `urgent_or_last` (bool, true) — focus the urgent window or last focused.
- `last` (bool, true) — focus the previously focused window.

---

### System Dispatchers

#### `hl.dsp.exec_cmd(cmd, [rule])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:222`**

Returns a dispatcher that spawns a command. The optional `rule` is a table of window rule effects.

```lua
hl.bind("SUPER+Return", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER+E", hl.dsp.exec_cmd("nemo", { float = true, size = "900 600" }))
```

---

#### `hl.dsp.exec_raw(cmd)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:237`**

Returns a dispatcher that spawns a raw shell command without any Hyprland processing.

---

#### `hl.dsp.exit()`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:243`**

Returns a dispatcher that exits Hyprland.

---

#### `hl.dsp.submap(name)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:248`**

Returns a dispatcher that activates a named submap.

```lua
hl.bind("SUPER+R", hl.dsp.submap("resize"))
```

---

#### `hl.dsp.pass(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:254`**

Returns a dispatcher that passes the keybind event to a specific window.

- `window` (window selector, required).

---

#### `hl.dsp.send_shortcut(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:393`**

Returns a dispatcher that sends a keyboard shortcut to a window.

- `mods` (string, required) — modifier string.
- `key` (string, required) — key name.
- `window` (window selector, optional).

---

#### `hl.dsp.send_key_state(table)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:407`**

Returns a dispatcher that sends a specific key state event.

- `mods` (string, required).
- `key` (string, required).
- `state` (string, required) — `"down"`, `"up"`, or `"repeat"`.
- `window` (optional).

---

#### `hl.dsp.layout(message)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:264`**

Returns a dispatcher that sends a message to the current layout.

---

#### `hl.dsp.dpms([table])`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:270`**

Returns a dispatcher that controls DPMS (display power).

- `action` (string, optional, in table) — `"toggle"`, `"enable"`, `"disable"`.
- `monitor` (monitor selector, optional).

---

#### `hl.dsp.event(name)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:286`**

Returns a dispatcher that fires a named event on the Hyprland event bus.

---

#### `hl.dsp.global(name)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:292`**

Returns a dispatcher that triggers a global keybind (passes to a wayland global shortcut).

---

#### `hl.dsp.force_renderer_reload()`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:298`**

Returns a dispatcher that forces a renderer reload.

---

#### `hl.dsp.force_idle(time)`

**`src/config/lua/bindings/LuaBindingsDispatchers.cpp:303`**

Returns a dispatcher that forces the idle inhibitor for a given time (float, seconds).

---

## Notification API (`hl.notification`)

### `hl.notification.create(table)`

**`src/config/lua/bindings/LuaBindingsNotification.cpp:65`**

Creates and displays a notification. Returns a `HL.Notification` object.

- `text` (string, required) — notification text.
- `duration`/`timeout`/`time` (number, required) — display duration in milliseconds.
- `icon` (string or number, optional) — icon name or enum value. Valid names: `"warning"`/`"warn"`, `"info"`, `"hint"`, `"error"`/`"err"`, `"confused"`/`"question"`, `"ok"`, `"none"`.
- `color` (string or number, optional) — ARGB color as a string or integer. Default 0 (uses icon color).
- `font_size` (number > 0, optional, default 13) — font size in points.

```lua
local notif = hl.notification.create({
    text = "Config reloaded!",
    duration = 3000,
    icon = "ok",
    color = "0xFF55FF55",
})
```

---

### `hl.notification.get()`

**`src/config/lua/bindings/LuaBindingsNotification.cpp:117`**

Returns an array of all currently displayed `HL.Notification` objects.

---

## Event System (`hl.on`)

**`src/config/lua/LuaEventHandler.cpp:201`**

All known events and their callback signatures:

| Event                       | Callback signature                                 | Notes                                            |
| --------------------------- | -------------------------------------------------- | ------------------------------------------------ |
| `window.open`               | `fn(window: HL.Window)`                            | Window has been mapped                           |
| `window.open_early`         | `fn(window: HL.Window)`                            | Window created, before rules applied             |
| `window.close`              | `fn(window: HL.Window)`                            | Window close requested                           |
| `window.destroy`            | `fn(window: HL.Window)`                            | Window fully destroyed                           |
| `window.kill`               | `fn(window: HL.Window)`                            | Window killed                                    |
| `window.active`             | `fn(window: HL.Window, reason: integer)`           | Focus changed; `reason` is a `eFocusReason` enum |
| `window.urgent`             | `fn(window: HL.Window)`                            | Window set urgent                                |
| `window.title`              | `fn(window: HL.Window)`                            | Window title changed                             |
| `window.class`              | `fn(window: HL.Window)`                            | Window class changed                             |
| `window.pin`                | `fn(window: HL.Window)`                            | Window pinned/unpinned                           |
| `window.fullscreen`         | `fn(window: HL.Window)`                            | Fullscreen state changed                         |
| `window.update_rules`       | `fn(window: HL.Window)`                            | Window rules re-evaluated                        |
| `window.move_to_workspace`  | `fn(window: HL.Window, workspace: HL.Workspace)`   | Window moved to a different workspace            |
| `layer.opened`              | `fn(surface: HL.LayerSurface)`                     | Layer surface created/mapped                     |
| `layer.closed`              | `fn(surface: HL.LayerSurface)`                     | Layer surface closed                             |
| `monitor.added`             | `fn(monitor: HL.Monitor)`                          | Monitor connected                                |
| `monitor.removed`           | `fn(monitor: HL.Monitor)`                          | Monitor disconnected                             |
| `monitor.focused`           | `fn(monitor: HL.Monitor)`                          | Monitor focus changed                            |
| `monitor.layout_changed`    | `fn()`                                             | Monitor layout recalculated                      |
| `workspace.active`          | `fn(workspace: HL.Workspace)`                      | Active workspace changed                         |
| `workspace.created`         | `fn(workspace: HL.Workspace)`                      | New workspace created                            |
| `workspace.removed`         | `fn(workspace: HL.Workspace)`                      | Workspace destroyed                              |
| `workspace.move_to_monitor` | `fn(workspace: HL.Workspace, monitor: HL.Monitor)` | Workspace moved to a monitor                     |
| `config.reloaded`           | `fn()`                                             | Config reload completed                          |
| `keybinds.submap`           | `fn(submap: string)`                               | Active submap changed; `""` = default            |
| `screenshare.state`         | `fn(active: bool, type: integer, name: string)`    | Screen capture state changed                     |
| `hyprland.start`            | `fn()`                                             | Hyprland fully initialized                       |
| `hyprland.shutdown`         | `fn()`                                             | Hyprland shutting down                           |

---

## Objects Reference

All objects are Lua userdata with read-only properties (attempting to assign to one produces a no-op error). Expired objects return `nil` for all property accesses with a debug log warning.

### HL.Window

**`src/config/lua/objects/LuaWindow.cpp`**

Metatable name: `"HL.Window"`. Wraps a `PHLWINDOWREF` (weak pointer).

`tostring` → `"HL.Window(0xADDR)"` or `"HL.Window(expired)"`

**Read-only properties** (accessed via `window.key`):

| Property            | Type                | Source line | Description                                                                                                                                                                                                                                        |
| ------------------- | ------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `address`           | string              | L:69        | Pointer as `"0x..."` hex string                                                                                                                                                                                                                    |
| `mapped`            | bool                | L:71        | Whether the window is currently mapped                                                                                                                                                                                                             |
| `hidden`            | bool                | L:73        | Whether the window is hidden                                                                                                                                                                                                                       |
| `at`                | `{x, y}`            | L:74        | Window position (goal state), integer pixels                                                                                                                                                                                                       |
| `size`              | `{x, y}`            | L:80        | Window size (goal state), integer pixels                                                                                                                                                                                                           |
| `workspace`         | HL.Workspace \| nil | L:86        | The workspace this window is on                                                                                                                                                                                                                    |
| `floating`          | bool                | L:91        | Whether the window is floating                                                                                                                                                                                                                     |
| `monitor`           | HL.Monitor \| nil   | L:93        | The monitor this window is on                                                                                                                                                                                                                      |
| `class`             | string              | L:99        | WM class                                                                                                                                                                                                                                           |
| `title`             | string              | L:101       | Window title                                                                                                                                                                                                                                       |
| `initial_class`     | string              | L:103       | Class at window creation                                                                                                                                                                                                                           |
| `initial_title`     | string              | L:105       | Title at window creation                                                                                                                                                                                                                           |
| `pid`               | integer             | L:107       | Process ID                                                                                                                                                                                                                                         |
| `xwayland`          | bool                | L:109       | True if this is an XWayland (X11) window                                                                                                                                                                                                           |
| `pinned`            | bool                | L:111       | True if pinned (shown on all workspaces)                                                                                                                                                                                                           |
| `fullscreen`        | integer             | L:113       | Internal fullscreen mode enum value                                                                                                                                                                                                                |
| `fullscreen_client` | integer             | L:115       | Client-reported fullscreen mode enum value                                                                                                                                                                                                         |
| `over_fullscreen`   | bool                | L:117       | Created over a fullscreen window                                                                                                                                                                                                                   |
| `group`             | table \| nil        | L:119       | Group info, or nil if not in a group. Fields: `locked` (bool), `denied` (bool), `size` (integer), `current_index` (integer, 1-based), `current` (HL.Window), `members` (array of HL.Window)                                                        |
| `tags`              | array of string     | L:157       | Applied tag names                                                                                                                                                                                                                                  |
| `swallowing`        | HL.Window \| nil    | L:165       | The window being swallowed by this one                                                                                                                                                                                                             |
| `focus_history_id`  | integer             | L:171       | Position in focus history (0 = most recent, -1 = not in history)                                                                                                                                                                                   |
| `inhibiting_idle`   | bool                | L:173       | True if this window inhibits idle                                                                                                                                                                                                                  |
| `xdg_tag`           | string \| nil       | L:175       | XDG tag from the client                                                                                                                                                                                                                            |
| `xdg_description`   | string \| nil       | L:181       | XDG description from the client                                                                                                                                                                                                                    |
| `content_type`      | string              | L:187       | Content type string                                                                                                                                                                                                                                |
| `stable_id`         | integer             | L:189       | Stable window ID (persists through workspace changes)                                                                                                                                                                                              |
| `layout`            | table \| nil        | L:191       | Layout info. `nil` if floating or no tiled algo. Always has `name` (string). For master: `is_master` (bool), `perc_master` (number), `perc_size` (number). For scrolling: `column` table with `index`, `width`, `windows`, plus `index_in_column`. |
| `active`            | bool                | L:261       | True if this is the currently focused window                                                                                                                                                                                                       |

---

### HL.Workspace

**`src/config/lua/objects/LuaWorkspace.cpp`**

Metatable: `"HL.Workspace"`. Wraps `PHLWORKSPACEREF`.

`tostring` → `"HL.Workspace(ID:name)"` or `"HL.Workspace(expired)"`

**Read-only properties:**

| Property          | Type              | Source line | Description                         |
| ----------------- | ----------------- | ----------- | ----------------------------------- |
| `id`              | integer           | L:47        | Workspace ID (negative for special) |
| `name`            | string            | L:49        | Workspace name                      |
| `monitor`         | HL.Monitor \| nil | L:50        | Monitor this workspace is on        |
| `windows`         | integer           | L:56        | Number of windows                   |
| `visible`         | bool              | L:58        | Whether visible on any monitor      |
| `special`         | bool              | L:60        | True if this is a special workspace |
| `active`          | bool              | L:62        | True if active on its monitor       |
| `has_urgent`      | bool              | L:65        | True if any window is urgent        |
| `fullscreen_mode` | integer           | L:67        | Fullscreen mode enum value          |
| `has_fullscreen`  | bool              | L:69        | True if a fullscreen window exists  |
| `is_persistent`   | bool              | L:71        | True if the workspace is persistent |

---

### HL.Monitor

**`src/config/lua/objects/LuaMonitor.cpp`**

Metatable: `"HL.Monitor"`. Wraps `PHLMONITORREF`.

`tostring` → `"HL.Monitor(ID:name)"` or `"HL.Monitor(expired)"`

**Read-only properties:**

| Property                   | Type                | Source line | Description                              |
| -------------------------- | ------------------- | ----------- | ---------------------------------------- |
| `id`                       | integer             | L:47        | Monitor ID                               |
| `name`                     | string              | L:49        | Output name (e.g., `"eDP-1"`)            |
| `description`              | string              | L:51        | Short description                        |
| `width`                    | integer             | L:53        | Pixel width                              |
| `height`                   | integer             | L:55        | Pixel height                             |
| `refresh_rate`             | number              | L:57        | Refresh rate in Hz                       |
| `x`                        | integer             | L:59        | Global X position                        |
| `y`                        | integer             | L:61        | Global Y position                        |
| `active_workspace`         | HL.Workspace \| nil | L:62        | Currently active workspace               |
| `active_special_workspace` | HL.Workspace \| nil | L:67        | Currently active special workspace       |
| `position`                 | `{x, y}`            | L:72        | Same as x/y but as a table               |
| `size`                     | `{width, height}`   | L:78        | Same as width/height as a table          |
| `scale`                    | number              | L:84        | DPI scale factor                         |
| `transform`                | integer             | L:86        | `wl_output_transform` enum value         |
| `dpms_status`              | bool                | L:88        | True if display is on                    |
| `vrr_active`               | bool                | L:90        | True if VRR/FreeSync is currently active |
| `is_mirror`                | bool                | L:92        | True if mirroring another monitor        |
| `mirrors`                  | array of HL.Monitor | L:94        | Monitors that mirror this one            |
| `focused`                  | bool                | L:106       | True if this is the focused monitor      |

---

### HL.LayerSurface

**`src/config/lua/objects/LuaLayerSurface.cpp`**

Metatable: `"HL.LayerSurface"`. Wraps `PHLLSREF`.

`tostring` → `"HL.LayerSurface(0xADDR)"` or `"HL.LayerSurface(expired)"`

**Read-only properties:**

| Property           | Type              | Source line | Description                                                                 |
| ------------------ | ----------------- | ----------- | --------------------------------------------------------------------------- |
| `address`          | string            | L:47        | Pointer as `"0x..."` hex string                                             |
| `x`                | integer           | L:49        | X position                                                                  |
| `y`                | integer           | L:51        | Y position                                                                  |
| `w`                | integer           | L:53        | Width                                                                       |
| `h`                | integer           | L:55        | Height                                                                      |
| `namespace`        | string            | L:57        | Layer namespace (e.g., `"waybar"`)                                          |
| `pid`              | integer           | L:59        | Process ID                                                                  |
| `monitor`          | HL.Monitor \| nil | L:60        | Monitor this surface is on                                                  |
| `mapped`           | bool              | L:66        | Whether currently mapped                                                    |
| `layer`            | integer           | L:68        | `zwlr_layer_shell_v1` layer enum (0=background, 1=bottom, 2=top, 3=overlay) |
| `interactivity`    | integer           | L:70        | Input interactivity mode enum                                               |
| `above_fullscreen` | bool              | L:72        | Whether above fullscreen windows                                            |

---

### HL.Notification (object)

**`src/config/lua/objects/LuaNotification.cpp`**

Metatable: `"HL.Notification"`.

`tostring` → `"HL.Notification(0xADDR)"` or `"HL.Notification(expired)"`

**Methods** (accessed as `notif:method()`):

| Method                         | Source line | Description                                  |
| ------------------------------ | ----------- | -------------------------------------------- |
| `pause()`                      | L:101       | Pauses the dismiss timer                     |
| `resume()`                     | L:116       | Resumes the dismiss timer                    |
| `set_paused(bool)`             | L:131       | Set pause state                              |
| `is_paused()`                  | L:141       | Returns bool (or nil if expired)             |
| `set_text(string)`             | L:154       | Change the notification text                 |
| `set_timeout(number)`          | L:164       | Change duration in ms (must be >= 0)         |
| `set_color(color)`             | L:177       | Change color (string or ARGB integer)        |
| `set_icon(icon)`               | L:190       | Change icon (name string or integer)         |
| `set_font_size(number)`        | L:203       | Change font size (must be > 0)               |
| `dismiss()`                    | L:216       | Remove/dismiss the notification              |
| `get_text()`                   | L:225       | Returns current text string                  |
| `get_timeout()`                | L:238       | Returns current duration in ms               |
| `get_color()`                  | L:251       | Returns ARGB color as integer                |
| `get_icon()`                   | L:264       | Returns icon as integer enum                 |
| `get_font_size()`              | L:277       | Returns font size                            |
| `get_elapsed()`                | L:290       | Returns ms elapsed since last reset/creation |
| `get_elapsed_since_creation()` | L:303       | Returns ms elapsed since first creation      |
| `is_alive()`                   | L:316       | Returns bool, false if dismissed/expired     |

When a paused `HL.Notification` is garbage-collected, it is automatically unlocked (resumed).

---

### HL.Timer

**`src/config/lua/objects/LuaTimer.cpp`**

Metatable: `"HL.Timer"`.

`tostring` → `"HL.Timer(0xADDR)"` or `"HL.Timer(expired)"`

**Methods:**

| Method                | Source line | Description                                                                 |
| --------------------- | ----------- | --------------------------------------------------------------------------- |
| `set_enabled(bool)`   | L:37        | Enable or disable the timer                                                 |
| `is_enabled()`        | L:72        | Returns bool (or nil if expired)                                            |
| `set_timeout(number)` | L:53        | Set timeout in ms (must be >= 1). Updates `timeoutMs` used for re-enabling. |

Note: `set_enabled(false)` removes the timer from the event loop without destroying it. `set_enabled(true)` restores it with the stored timeout.

---

### HL.Keybind

**`src/config/lua/objects/LuaKeybind.cpp`**

Metatable: `"HL.Keybind"`.

`tostring` → `"HL.Keybind(0xADDR)"` or `"HL.Keybind(expired)"`

**Methods:**

| Method                  | Source line | Description                                     |
| ----------------------- | ----------- | ----------------------------------------------- |
| `set_enabled(bool)`     | L:46        | Enable or disable the keybind                   |
| `is_enabled()`          | L:57        | Returns bool (or nil if expired)                |
| `remove()` / `unbind()` | L:68        | Removes the keybind and unrefs the Lua callback |

**Read-only properties:**

| Property           | Source line | Description                                                |
| ------------------ | ----------- | ---------------------------------------------------------- |
| `enabled`          | L:116       | bool                                                       |
| `has_description`  | L:118       | bool                                                       |
| `description`      | L:120       | string or nil                                              |
| `display_key`      | L:122       | Original key string as passed to `hl.bind`                 |
| `submap`           | L:124       | Name of the submap this bind belongs to                    |
| `handler`          | L:126       | Handler type (e.g., `"__lua"`)                             |
| `arg`              | L:128       | Handler argument (for `__lua`: Lua registry ref as string) |
| `modmask`          | L:130       | Modifier bitmask integer                                   |
| `key`              | L:132       | Key name string                                            |
| `keycode`          | L:134       | Keycode integer                                            |
| `catchall`         | L:136       | bool                                                       |
| `repeating`        | L:138       | bool                                                       |
| `locked`           | L:140       | bool                                                       |
| `release`          | L:142       | bool                                                       |
| `non_consuming`    | L:144       | bool                                                       |
| `transparent`      | L:146       | bool                                                       |
| `ignore_mods`      | L:148       | bool                                                       |
| `long_press`       | L:150       | bool                                                       |
| `dont_inhibit`     | L:152       | bool                                                       |
| `click`            | L:154       | bool                                                       |
| `drag`             | L:156       | bool                                                       |
| `submap_universal` | L:158       | bool                                                       |
| `mouse`            | L:160       | bool                                                       |
| `device_inclusive` | L:162       | bool                                                       |
| `devices`          | L:164       | array of device name strings                               |

---

### HL.EventSubscription

**`src/config/lua/objects/LuaEventSubscription.cpp`**

Metatable: `"HL.EventSubscription"`.

`tostring` → `"HL.EventSubscription(handle,active)"` or `"HL.EventSubscription(handle,inactive)"`

**Methods:**

| Method        | Source line | Description                                                        |
| ------------- | ----------- | ------------------------------------------------------------------ |
| `remove()`    | L:34        | Unregisters the event subscription. The Lua callback ref is freed. |
| `is_active()` | L:45        | Returns bool, whether still subscribed                             |

---

### HL.WindowRule

**`src/config/lua/objects/LuaWindowRule.cpp`**

Metatable: `"HL.WindowRule"`. Opaque handle returned by `hl.window_rule()`. No public methods or properties beyond equality (`==`) and tostring. Used only to hold a reference to prevent GC of the rule.

---

### HL.LayerRule

**`src/config/lua/objects/LuaLayerRule.cpp`**

Metatable: `"HL.LayerRule"`. Opaque handle returned by `hl.layer_rule()`. Same as WindowRule — no exposed methods.

---

## Window Rule Effects

**`src/config/lua/bindings/LuaBindingsInternal.hpp:44`**

Used as keys in `hl.window_rule({ ... })` and in the `rule` argument of `hl.exec_cmd()` / `hl.dsp.exec_cmd()`.

| Key                    | Type            | Default | Description                                              |
| ---------------------- | --------------- | ------- | -------------------------------------------------------- |
| `float`                | bool            | false   | Force floating                                           |
| `tile`                 | bool            | false   | Force tiled                                              |
| `fullscreen`           | bool            | false   | Force fullscreen                                         |
| `maximize`             | bool            | false   | Force maximized                                          |
| `center`               | bool            | false   | Center the window                                        |
| `pseudo`               | bool            | false   | Enable pseudo-tiling                                     |
| `no_initial_focus`     | bool            | false   | Skip initial focus                                       |
| `pin`                  | bool            | false   | Pin to all workspaces                                    |
| `fullscreen_state`     | string          | `""`    | Override fullscreen state encoding                       |
| `move`                 | string          | `""`    | Override position (e.g., `"100 200"`)                    |
| `size`                 | string          | `""`    | Override size (e.g., `"800 600"`)                        |
| `monitor`              | string          | `""`    | Force to monitor                                         |
| `workspace`            | string          | `""`    | Force to workspace                                       |
| `group`                | string          | `""`    | Group configuration string                               |
| `suppress_event`       | string          | `""`    | Suppress named event                                     |
| `content`              | string          | `""`    | Content type override                                    |
| `no_close_for`         | integer         | 0       | Prevent closing for N ms                                 |
| `scrolling_width`      | float           | 0       | Scrolling layout column width                            |
| `rounding`             | integer (0–20)  | 0       | Corner rounding radius                                   |
| `border_size`          | integer         | 0       | Border width in pixels                                   |
| `rounding_power`       | float (1–10)    | 2       | Rounding superellipse power                              |
| `scroll_mouse`         | float (0.01–10) | 1       | Mouse scroll factor                                      |
| `scroll_touchpad`      | float (0.01–10) | 1       | Touchpad scroll factor                                   |
| `animation`            | string          | `""`    | Override animation style                                 |
| `idle_inhibit`         | string          | `""`    | Idle inhibit mode                                        |
| `opacity`              | string          | `""`    | Opacity override (e.g., `"0.8"` or `"0.9 override 0.7"`) |
| `tag`                  | string          | `""`    | Apply tag                                                |
| `max_size`             | Vec2            | `{0,0}` | Maximum size                                             |
| `min_size`             | Vec2            | `{0,0}` | Minimum size                                             |
| `border_color`         | gradient        | black   | Border color gradient                                    |
| `persistent_size`      | bool            | false   | Remember floating size                                   |
| `allows_input`         | bool            | false   | Allow input even when not focused                        |
| `dim_around`           | bool            | false   | Dim everything behind this window                        |
| `decorate`             | bool            | true    | Show window decorations                                  |
| `focus_on_activate`    | bool            | false   | Focus when activated                                     |
| `keep_aspect_ratio`    | bool            | false   | Keep aspect ratio when resizing                          |
| `nearest_neighbor`     | bool            | false   | Use nearest-neighbor scaling                             |
| `no_anim`              | bool            | false   | Disable animations                                       |
| `no_blur`              | bool            | false   | Disable blur                                             |
| `no_dim`               | bool            | false   | Disable dim                                              |
| `no_focus`             | bool            | false   | Never focus                                              |
| `no_follow_mouse`      | bool            | false   | Cursor hover does not focus                              |
| `no_max_size`          | bool            | false   | Ignore max_size constraint                               |
| `no_shadow`            | bool            | false   | Disable shadow                                           |
| `no_shortcuts_inhibit` | bool            | false   | Prevent shortcut inhibition                              |
| `opaque`               | bool            | false   | Render as opaque                                         |
| `force_rgbx`           | bool            | false   | Force RGBX color format                                  |
| `sync_fullscreen`      | bool            | false   | Sync client/internal fullscreen                          |
| `immediate`            | bool            | false   | Disable frame scheduling delay                           |
| `xray`                 | bool            | false   | Enable X-ray (see-through) rendering                     |
| `render_unfocused`     | bool            | false   | Render even when unfocused                               |
| `no_screen_share`      | bool            | false   | Hide from screen capture                                 |
| `no_vrr`               | bool            | false   | Disable VRR for this window                              |
| `stay_focused`         | bool            | false   | Prevent focus from leaving                               |

---

## Layer Rule Effects

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:173`**

Used as keys in `hl.layer_rule({ ... })`.

| Key               | Type          | Default | Description                                       |
| ----------------- | ------------- | ------- | ------------------------------------------------- |
| `no_anim`         | bool          | false   | Disable animations                                |
| `blur`            | bool          | false   | Enable blur behind the layer                      |
| `blur_popups`     | bool          | false   | Blur popups from this layer                       |
| `ignore_alpha`    | float (0–1)   | 0       | Threshold below which pixels are ignored for blur |
| `dim_around`      | bool          | false   | Dim everything behind this layer                  |
| `xray`            | bool          | false   | X-ray rendering                                   |
| `animation`       | string        | `""`    | Animation style override                          |
| `order`           | integer       | 0       | Z-order within layer                              |
| `above_lock`      | integer (0–2) | 0       | Render above lock screen (0=no, 1=yes, 2=always)  |
| `no_screen_share` | bool          | false   | Hide from screen capture                          |

---

## Workspace Rule Fields

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:188`**

Used as keys in `hl.workspace_rule({ ... })`.

| Key                | Type    | Default | Description                                         |
| ------------------ | ------- | ------- | --------------------------------------------------- |
| `monitor`          | string  | `""`    | Bind workspace to this monitor                      |
| `default`          | bool    | false   | Make this the default workspace on its monitor      |
| `persistent`       | bool    | false   | Keep the workspace alive when empty                 |
| `gaps_in`          | CSS gap | 5       | Inner gaps                                          |
| `gaps_out`         | CSS gap | 20      | Outer gaps                                          |
| `float_gaps`       | CSS gap | 0       | Gaps applied only to floating windows               |
| `border_size`      | integer | -1      | Border width (-1 = inherit)                         |
| `no_border`        | bool    | false   | Disable borders                                     |
| `no_rounding`      | bool    | false   | Disable rounding                                    |
| `decorate`         | bool    | true    | Show decorations                                    |
| `no_shadow`        | bool    | false   | Disable shadows                                     |
| `on_created_empty` | string  | `""`    | Command to run when workspace first opens empty     |
| `default_name`     | string  | `""`    | Rename workspace to this on creation                |
| `layout`           | string  | `""`    | Force a specific layout                             |
| `animation`        | string  | `""`    | Override animation style                            |
| `layout_opts`      | table   | —       | Layout-specific options (string/bool/number values) |

CSS gap fields accept a single number (uniform gap) or a string `"top right bottom left"` (CSS shorthand).

---

## Monitor Rule Fields

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:72`**

Used as keys in `hl.monitor({ output = "...", ... })`.

| Key                          | Type           | Default       | Description                                                              |
| ---------------------------- | -------------- | ------------- | ------------------------------------------------------------------------ |
| `mode`                       | string         | `"preferred"` | Resolution and rate (e.g., `"1920x1080@60"`, `"preferred"`, `"highres"`) |
| `position`                   | string         | `"auto"`      | Monitor position (e.g., `"0x0"`, `"auto"`, `"auto-right"`)               |
| `scale`                      | string         | `"auto"`      | DPI scale (e.g., `"1.5"`, `"auto"`)                                      |
| `reserved` / `reserved_area` | CSS gap        | 0             | Reserved screen area for panels                                          |
| `disabled`                   | bool           | false         | Disable this monitor                                                     |
| `transform`                  | integer (0–7)  | 0             | `wl_output_transform` value                                              |
| `mirror`                     | string         | `""`          | Mirror another output by name                                            |
| `bitdepth`                   | integer        | 8             | Bit depth (8 or 10)                                                      |
| `cm`                         | string         | `"srgb"`      | Color management profile                                                 |
| `sdr_eotf`                   | string         | `"default"`   | SDR transfer function                                                    |
| `sdrbrightness`              | float          | 1.0           | SDR brightness multiplier                                                |
| `sdrsaturation`              | float          | 1.0           | SDR saturation multiplier                                                |
| `vrr`                        | integer (0–3)  | 0             | VRR mode (0=off, 1=on, 2=fullscreen-only, 3=game-only)                   |
| `icc`                        | string         | `""`          | ICC profile file path                                                    |
| `supports_wide_color`        | integer (-1–1) | 0             | Wide color support override (-1=auto)                                    |
| `supports_hdr`               | integer (-1–1) | 0             | HDR support override (-1=auto)                                           |
| `sdr_min_luminance`          | float          | 0.2           | Minimum SDR luminance                                                    |
| `sdr_max_luminance`          | integer        | 80            | Maximum SDR luminance (nits)                                             |
| `min_luminance`              | float          | -1            | Display minimum luminance (-1=auto)                                      |
| `max_luminance`              | integer        | -1            | Display maximum luminance (-1=auto)                                      |
| `max_avg_luminance`          | integer        | -1            | Display max average luminance (-1=auto)                                  |

---

## Device Configuration Fields

**`src/config/lua/bindings/LuaBindingsConfigRules.cpp:221`**

Used as keys in `hl.device({ name = "...", ... })`.

| Key                        | Type             | Default | Description                                   |
| -------------------------- | ---------------- | ------- | --------------------------------------------- |
| `sensitivity`              | float (-1–1)     | 0       | Pointer acceleration sensitivity              |
| `accel_profile`            | string           | `""`    | Acceleration profile (`"adaptive"`, `"flat"`) |
| `rotation`                 | integer (0–359)  | 0       | Device rotation in degrees                    |
| `kb_file`                  | string           | `""`    | Path to XKB keymap file                       |
| `kb_layout`                | string           | `"us"`  | XKB layout(s)                                 |
| `kb_variant`               | string           | `""`    | XKB variant                                   |
| `kb_options`               | string           | `""`    | XKB options                                   |
| `kb_rules`                 | string           | `""`    | XKB rules                                     |
| `kb_model`                 | string           | `""`    | XKB model                                     |
| `repeat_rate`              | integer (0–200)  | 25      | Key repeat rate (keys/sec)                    |
| `repeat_delay`             | integer (0–2000) | 600     | Key repeat delay (ms)                         |
| `natural_scroll`           | bool             | false   | Natural scroll direction                      |
| `tap_button_map`           | string           | `""`    | Tap button mapping                            |
| `numlock_by_default`       | bool             | false   | Enable numlock on startup                     |
| `resolve_binds_by_sym`     | bool             | false   | Resolve keybinds by symbol not keycode        |
| `disable_while_typing`     | bool             | true    | Disable touchpad while typing                 |
| `clickfinger_behavior`     | bool             | false   | Clickfinger mode                              |
| `middle_button_emulation`  | bool             | false   | Emulate middle button with left+right         |
| `tap-to-click`             | bool             | true    | Tap to click                                  |
| `tap-and-drag`             | bool             | true    | Tap and drag                                  |
| `drag_lock`                | integer (0–2)    | 0       | Drag lock mode                                |
| `left_handed`              | bool             | false   | Left-handed mode                              |
| `scroll_method`            | string           | `""`    | Scroll method                                 |
| `scroll_button`            | integer (0–300)  | 0       | Scroll button keycode                         |
| `scroll_button_lock`       | bool             | false   | Lock scroll button state                      |
| `scroll_points`            | string           | `""`    | Custom scroll points                          |
| `scroll_factor`            | float (0–100)    | 1       | Scroll speed multiplier                       |
| `transform`                | integer          | -1      | Output transform override                     |
| `output`                   | string           | `""`    | Restrict to specific output                   |
| `enabled`                  | bool             | true    | Enable/disable the device                     |
| `region_position`          | Vec2             | `{0,0}` | Input region offset                           |
| `absolute_region_position` | bool             | false   | Region position is absolute                   |
| `region_size`              | Vec2             | `{0,0}` | Input region size                             |
| `relative_input`           | bool             | false   | Use relative input mode                       |
| `active_area_position`     | Vec2             | `{0,0}` | Active area offset                            |
| `active_area_size`         | Vec2             | `{0,0}` | Active area size                              |
| `flip_x`                   | bool             | false   | Flip X axis                                   |
| `flip_y`                   | bool             | false   | Flip Y axis                                   |
| `drag_3fg`                 | integer (0–2)    | 0       | 3-finger drag mode                            |
| `keybinds`                 | bool             | true    | Process keybinds from this device             |
| `share_states`             | integer (0–2)    | 0       | Share keyboard state mode                     |
| `release_pressed_on_close` | bool             | false   | Release keys when surface closes              |

---

## Selector Syntax

Several API functions accept a "selector" — either an object (`HL.Window`, `HL.Workspace`, `HL.Monitor`) or a string that is resolved internally.

**`src/config/lua/bindings/LuaBindingsInternal.cpp:60`**

- **Window selector**: passed to `g_pCompositor->getWindowByRegex()`. Accepts Hyprland's full window regex syntax: `address:0x...`, `pid:123`, `class:regex`, `title:regex`, `floating`, `tiled`, `active`, `special`, `workspace:name`, etc.
- **Workspace selector**: passed to `g_pCompositor->getWorkspaceByString()`. Accepts workspace IDs, names, `special:name`, relative references (`+1`, `-1`, `previous`).
- **Monitor selector**: passed to `g_pCompositor->getMonitorFromString()`. Accepts monitor name, ID, `current`, `next`, `previous`.

When an object is passed instead of a string, its internal pointer or ID is used directly, bypassing string parsing.

---

## print() Override

**`src/config/lua/bindings/LuaBindingsRegistration.cpp:14`**

The global `print` function is replaced with a version that logs to Hyprland's logger at `INFO` level, prefixed with `[Lua]`. Multiple arguments are tab-separated (same as standard Lua `print`). This output appears in `journalctl` and `hyprctl log`.

```lua
print("Hello from Lua!")          -- → [Lua] Hello from Lua!
print("x =", 42, "y =", 100)      -- → [Lua] x =    42    y =    100
```
