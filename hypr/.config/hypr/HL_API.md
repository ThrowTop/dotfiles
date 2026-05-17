# `hl` Query API

Read-only query functions on the global `hl` table.
Type stubs live in `/usr/share/hypr/stubs/hl.meta.lua`.

---

## Selectors

Several functions accept *selector* arguments that can be passed in multiple forms:

| Selector type | Accepted values |
|---|---|
| `HL.WindowSelector` | window object · `string` address/class · `integer` stable_id |
| `HL.WorkspaceSelector` | workspace object · `string` name · `integer` id |
| `HL.MonitorSelector` | monitor object · `string` name (e.g. `"eDP-1"`) · `integer` id |

---

## Functions

### Config

| method | description |
|---|---|
| `get_config(key)` | Returns the current value of a config key. `key` is a `HL.ConfigKey` dot-path string (e.g. `"general.gaps_in"`). Returns `value, err?` - the value and an optional error string if the key is unknown. |

### Windows

| method | description |
|---|---|
| `get_active_window()` | Returns the focused `HL.Window`, or `nil`. |
| `get_last_window()` | Returns the previously focused `HL.Window` (second in focus history), or `nil`. |
| `get_urgent_window()` | Returns the most recent `HL.Window` that set the urgent hint, or `nil`. |
| `get_window(selector)` | Looks up a single `HL.Window` by `HL.WindowSelector`, or `nil`. |
| `get_windows(filters?)` | Returns `HL.Window[]` - all mapped windows, narrowed by an optional `HL.WindowQueryFilter`. |
| `get_workspace_windows(workspace)` | Returns `HL.Window[]` - all windows on the given `HL.WorkspaceSelector`. |

### Workspaces

| method | description |
|---|---|
| `get_active_workspace(monitor?)` | Returns the active `HL.Workspace` on `monitor` (defaults to focused monitor), or `nil`. |
| `get_active_special_workspace(monitor?)` | Returns the currently shown special `HL.Workspace` on `monitor`, or `nil` if none is open. |
| `get_last_workspace(monitor?)` | Returns the previously active `HL.Workspace` on `monitor` (defaults to focused monitor), or `nil`. |
| `get_workspace(selector)` | Looks up a single `HL.Workspace` by `HL.WorkspaceSelector`, or `nil`. |
| `get_workspaces()` | Returns `HL.Workspace[]` - all workspaces, including special ones. |

### Monitors

| method | description |
|---|---|
| `get_active_monitor()` | Returns the focused `HL.Monitor`, or `nil`. |
| `get_monitor(selector)` | Looks up a single `HL.Monitor` by `HL.MonitorSelector`, or `nil`. |
| `get_monitor_at(x, y?)` | Returns the `HL.Monitor` at the given compositor-space position. Accepts `(x, y)` as two numbers, or a single `HL.Vec2` (e.g. `{ x = 100, y = 200 }`). Returns `nil` if no monitor covers that point. |
| `get_monitor_at_cursor()` | Returns the `HL.Monitor` under the current cursor, or `nil`. |
| `get_monitors()` | Returns `HL.Monitor[]` - all connected monitors. |

### Layers

| method | description |
|---|---|
| `get_layers(filters?)` | Returns `HL.LayerSurface[]` - all layer surfaces (bars, overlays, etc.), narrowed by an optional `HL.LayerQueryFilter`. |

### Input

| method | description |
|---|---|
| `get_cursor_pos()` | Returns the cursor position as `HL.Vec2` (`{ x, y }`) in compositor space, or `nil`. |
| `get_current_submap()` | Returns the active submap name as a `string`. Empty string `""` when no submap is active. |

### Misc

| method | description |
|---|---|
| `version()` | Returns a table with Hyprland version info (tag, commit, branch, dirty, flags). Exact shape is unspecified. |
| `exec_cmd(cmd, rules?)` | Spawns `cmd` asynchronously via Hyprland's process manager. `rules` is an optional `table<string, string\|number\|boolean>` of window rules to apply to the spawned process. Does not capture output - use `hlc.exec_async` or `hlc.exec_sync` when you need stdout. |
| `get_loaded_plugins()` | Not present in the current stubs. Plugins are accessed via `hl.plugin` - use `hl.plugin.load(path)` to load one. |

---

## Filter types

### `HL.WindowQueryFilter`

Passed to `get_windows()`. All fields are optional and ANDed together.

| field | type | description |
|---|---|---|
| `class` | `string` | Match window class (glob) |
| `title` | `string` | Match window title (glob) |
| `tag` | `string` | Match window tag |
| `floating` | `boolean` | Filter to floating or tiled only |
| `mapped` | `boolean` | Filter to mapped or unmapped only |
| `monitor` | `HL.MonitorSelector` | Only windows on this monitor |
| `workspace` | `HL.WorkspaceSelector` | Only windows on this workspace |

### `HL.LayerQueryFilter`

Passed to `get_layers()`. All fields are optional.

| field | type | description |
|---|---|---|
| `monitor` | `HL.MonitorSelector` | Only layers on this monitor |
| `namespace` | `string` | Only layers with this namespace (glob) |

---

## Return types

### `HL.Window`

| field | type | description |
|---|---|---|
| `address` | `string` | Unique hex address |
| `class` | `string` | App class (e.g. `"foot"`) |
| `title` | `string` | Window title |
| `initial_class` | `string` | Class at open time |
| `initial_title` | `string` | Title at open time |
| `pid` | `integer` | Process ID |
| `stable_id` | `integer` | Stable numeric ID (survives workspace moves) |
| `monitor` | `HL.Monitor\|nil` | Monitor the window is on |
| `workspace` | `HL.Workspace\|nil` | Workspace the window is on |
| `at` | `table` | Position `{x, y}` |
| `size` | `table` | Size `{w, h}` |
| `floating` | `boolean` | Is the window floating |
| `fullscreen` | `integer` | Fullscreen state: `0` = none, `1` = maximized, `2` = fullscreen |
| `fullscreen_client` | `integer` | Client-requested fullscreen mode |
| `pinned` | `boolean` | Pinned across all workspaces |
| `hidden` | `boolean` | Hidden (e.g. sent to a special workspace) |
| `mapped` | `boolean` | Whether the surface is currently mapped |
| `active` | `boolean\|nil` | Is the currently focused window |
| `over_fullscreen` | `boolean` | Rendered above a fullscreen window |
| `inhibiting_idle` | `boolean` | Is inhibiting the idle timer |
| `xwayland` | `boolean` | Is an XWayland window |
| `focus_history_id` | `integer` | Position in focus history (`0` = most recent) |
| `swallowing` | `HL.Window\|nil` | Window being swallowed by this one |
| `tags` | `string\|table` | Tags assigned to the window |
| `content_type` | `string` | Wayland content type hint |
| `xdg_tag` | `string\|nil` | XDG tag |
| `xdg_description` | `string\|nil` | XDG description |

### `HL.Workspace`

| field | type | description |
|---|---|---|
| `id` | `integer` | Workspace ID (negative = special) |
| `name` | `string` | Workspace name |
| `monitor` | `HL.Monitor\|nil` | Monitor it resides on |
| `windows` | `integer` | Number of windows |
| `active` | `boolean` | Is the active workspace on its monitor |
| `visible` | `boolean` | Is visible on any monitor |
| `special` | `boolean` | Is a special workspace |
| `has_fullscreen` | `boolean` | Contains a fullscreen window |
| `has_urgent` | `boolean` | Contains an urgent window |
| `fullscreen_mode` | `integer` | Active fullscreen mode |
| `is_persistent` | `boolean\|nil` | Is persistent (won't be removed when empty) |

### `HL.Monitor`

| field | type | description |
|---|---|---|
| `id` | `integer` | Monitor ID |
| `name` | `string` | Output name (e.g. `"eDP-1"`) |
| `description` | `string` | Full connector description string |
| `x` | `integer` | X position in compositor space |
| `y` | `integer` | Y position in compositor space |
| `width` | `integer` | Width in logical pixels |
| `height` | `integer` | Height in logical pixels |
| `scale` | `number` | HiDPI scale factor |
| `refresh_rate` | `number` | Refresh rate in Hz |
| `transform` | `integer` | Output transform (0–7) |
| `focused` | `boolean\|nil` | Is the currently focused monitor |
| `dpms_status` | `boolean` | DPMS state (display on/off) |
| `vrr_active` | `boolean` | Variable refresh rate is active |
| `is_mirror` | `boolean` | Is mirroring another monitor |
| `mirrors` | `HL.Monitor\|table` | The monitor being mirrored |
| `active_workspace` | `HL.Workspace\|nil` | Currently active workspace |
| `active_special_workspace` | `HL.Workspace\|nil` | Active special workspace, if any |

### `HL.LayerSurface`

| field | type | description |
|---|---|---|
| `address` | `string` | Unique hex address |
| `namespace` | `string` | Layer namespace (e.g. `"waybar"`) |
| `monitor` | `HL.Monitor\|nil` | Monitor it is on |
| `pid` | `integer` | Process ID |
| `x` | `integer` | X position |
| `y` | `integer` | Y position |
| `w` | `integer` | Width |
| `h` | `integer` | Height |
| `layer` | `integer` | Layer level: `0` = background, `1` = bottom, `2` = top, `3` = overlay |
| `mapped` | `boolean` | Is the surface currently mapped |
| `interactivity` | `integer` | Keyboard interactivity mode |
| `above_fullscreen` | `boolean\|nil` | Renders above fullscreen windows |

### `HL.Vec2`

| field | type |
|---|---|
| `x` | `number` |
| `y` | `number` |
