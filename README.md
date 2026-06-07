# Unknown UI Library

A lightweight, feature-rich Roblox UI library designed for script interfaces. Supports theming, mobile drag, config saving, element locking, multi-select dropdowns, progress bars, notifications with types, and more.

---

## Table of Contents

- [Loading](#loading)
- [Window](#window)
  - [MakeWindow Options](#makewindow-options)
  - [Window Methods](#window-methods)
- [Tabs](#tabs)
  - [MakeTab Options](#maketab-options)
  - [Tab Methods](#tab-methods)
- [Elements](#elements)
  - [Label](#label)
  - [Paragraph](#paragraph)
  - [Button](#button)
  - [Toggle](#toggle)
  - [Slider](#slider)
  - [Dropdown](#dropdown)
  - [Bind](#bind)
  - [Textbox](#textbox)
  - [Colorpicker](#colorpicker)
  - [Separator](#separator)
  - [ProgressBar](#progressbar)
  - [ThemeSwitcher](#themeswitcher)
  - [Section](#section)
- [Notifications](#notifications)
- [Themes](#themes)
- [Config System](#config-system)
- [Global Methods](#global-methods)

---

## Loading

Load the library via `loadstring` from wherever you host `source.txt` / the compiled file:

```lua
local unknown = loadstring(game:HttpGetAsync("YOUR_RAW_URL_HERE"))()
```

---

## Window

### MakeWindow Options

Creates the main UI window. Returns a `TabFunction` object used to create tabs and call window methods.

```lua
local Window = unknown:MakeWindow({
    Name              = "My Script",       -- Window title shown in the top bar
    IntroEnabled      = true,              -- Show the animated intro splash on open
    IntroText         = "My Script",       -- Text shown during the intro sequence
    IntroIcon         = "rbxassetid://...",-- Icon shown during the intro sequence
    ShowIcon          = false,             -- Show an icon next to the title in the top bar
    Icon              = "rbxassetid://...",-- Icon asset shown in top bar (requires ShowIcon = true)
    Theme             = "Default",         -- Starting theme name (see Themes section)
    DefaultTab        = "Main",            -- Tab name to open on start; falls back to first tab if nil or invalid
    SaveConfig        = false,             -- Enable config auto-save/load
    ConfigFolder      = "MyScript",        -- Folder name used to store config files
    ConfigName        = "12345678",        -- Config file name (defaults to game.GameId)
    Transparent       = false,             -- Enable background transparency
    TransparencyAmount = 0.3,             -- Transparency level (0.0 = opaque, 0.7 = max allowed)
    Blur              = false,             -- Add a BlurEffect to Lighting when window opens
    MinSize           = Vector2.new(400, 280), -- Minimum window size when resizing
    MaxSize           = Vector2.new(900, 600), -- Maximum window size when resizing
    CloseCallback     = function() end,    -- Called when the close button is pressed
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Unknown Library"` | Window title |
| `IntroEnabled` | bool | `true` | Show splash intro |
| `IntroText` | string | `"Unknown Library"` | Intro splash text |
| `IntroIcon` | string | built-in | Asset ID for intro icon |
| `ShowIcon` | bool | `false` | Show icon in top bar |
| `Icon` | string | built-in | Top bar icon asset ID |
| `Theme` | string | `"Default"` | Starting theme |
| `DefaultTab` | string | `nil` | Tab to activate on open |
| `SaveConfig` | bool | `false` | Enable config persistence |
| `ConfigFolder` | string | `Name` | Save folder name |
| `ConfigName` | string | `game.GameId` | Config file name |
| `Transparent` | bool | `false` | Window transparency |
| `TransparencyAmount` | number | `0` | 0.0–0.7 transparency level |
| `Blur` | bool | `false` | Blur background via Lighting |
| `MinSize` | Vector2 | `(400, 280)` | Minimum resize dimensions |
| `MaxSize` | Vector2 | `(900, 600)` | Maximum resize dimensions |
| `CloseCallback` | function | `function()end` | Fired on window close |

**Resize:** A drag handle appears at the bottom-right corner of the window. Drag it to resize between `MinSize` and `MaxSize`. Works on both mouse and touch.

**Close / Reopen:** The close button hides the window. Press **RightShift** to reopen it.

**Minimize:** The minimize button collapses the window to just the title bar.

---

### Window Methods

Methods are called on the `Window` object returned by `MakeWindow`.

#### `Window:SetTab(name)`
Switches the active tab to the one with the given name. If the name does not match any tab, the first tab is selected instead.
```lua
Window:SetTab("Settings")
```

#### `Window:WindowLocked(locked)`
When `true`, hides the close and minimize buttons and disables dragging. When `false`, restores them.
```lua
Window:WindowLocked(true)   -- lock
Window:WindowLocked(false)  -- unlock
```

---

## Tabs

### MakeTab Options

Creates a tab in the left sidebar. Returns an element function table used to add elements.

```lua
local Tab = Window:MakeTab({
    Name   = "Main",           -- Tab label
    Icon   = "home",           -- Lucide icon name or rbxassetid:// string
    Locked = false,            -- Lock the tab on creation (dims it, blocks access)
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Tab"` | Tab label |
| `Icon` | string | `""` | Lucide icon name or asset ID |
| `Locked` | bool | `false` | Lock the tab by default |

**Icons:** Pass any [Lucide](https://lucide.dev) icon name as a string (e.g. `"home"`, `"settings"`, `"shield"`). Asset IDs (`"rbxassetid://..."`) are also supported.

**Locked tabs:** When a tab is locked, its label and icon are dimmed to 70% transparency, a lock icon appears on the right, and clicking it does nothing. Elements inside a locked tab cannot be interacted with. Config values for flags inside a locked tab are not loaded until the tab is unlocked.

---

### Tab Methods

#### `Tab:SetLocked(locked)`
Lock or unlock the tab at runtime.
- `true` — dims the tab, blocks access, hides config loading for its flags
- `false` — restores the tab, re-enables interaction, triggers a config load for its flags
```lua
Tab:SetLocked(true)   -- lock
Tab:SetLocked(false)  -- unlock (triggers config load for this tab's flags)
```

---

## Elements

All elements are added by calling methods on a `Tab` or `Section` object.

---

### Label

A read-only text row.

```lua
local Label = Tab:AddLabel("Hello World")
```

**Returns:**

| Method | Description |
|---|---|
| `Label:Set(text)` | Update the label text |

---

### Paragraph

A two-line display with a bold title and wrapped body text.

```lua
local Para = Tab:AddParagraph("Title", "This is the body content.")
```

| Parameter | Type | Description |
|---|---|---|
| `Text` | string | Bold title text |
| `Content` | string | Body text (word-wrapped, auto-sizes) |

**Returns:**

| Method | Description |
|---|---|
| `Para:Set(text)` | Update the body content text |

---

### Button

A clickable row that fires a callback.

```lua
local Btn = Tab:AddButton({
    Name     = "Click Me",
    Callback = function()
        print("Clicked!")
    end,
    Icon     = "rbxassetid://3944703587",  -- optional right-side icon
    Locked   = false,                       -- lock the button on creation
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Button"` | Button label |
| `Callback` | function | `function()end` | Fired when clicked |
| `Icon` | string | built-in | Right-side icon asset ID |
| `Locked` | bool | `false` | Locked on creation |

**Returns:**

| Method | Description |
|---|---|
| `Btn:Set(text)` | Update the button label |
| `Btn:ButtonLocked(bool)` | Lock (`true`) or unlock (`false`) the button at runtime |

**Locking:** When locked, the button darkens, a lock icon appears, and the callback is blocked. Unlocking reverts all of this.

---

### Toggle

An on/off toggle with an animated checkbox.

```lua
local Toggle = Tab:AddToggle({
    Name     = "Enable Feature",
    Default  = false,
    Color    = Color3.fromRGB(9, 99, 195),  -- checkbox color when on
    Locked   = false,                        -- lock the toggle on creation
    Flag     = "myToggle",                   -- key used for config saving
    Save     = false,                        -- persist value in config
    OnLoad   = function(value)               -- called when config loads this flag
        print("Loaded:", value)
    end,
    Callback = function(value)
        print("Toggle is now:", value)
    end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Toggle"` | Toggle label |
| `Default` | bool | `false` | Starting state |
| `Color` | Color3 | Blue | Checkbox color when enabled |
| `Locked` | bool | `false` | Locked on creation |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Save to config |
| `OnLoad` | function | `nil` | Fired after config loads this value |
| `Callback` | function | `function()end` | Fired on state change |

**Returns:**

| Method / Property | Description |
|---|---|
| `Toggle:Set(bool)` | Set the toggle state programmatically |
| `Toggle:ToggleLocked(bool)` | Lock (`true`) darkens and disables; unlock (`false`) reverts and re-enables |
| `Toggle.Value` | Current boolean state |
| `Toggle.Locked` | Whether the toggle is currently locked |

**Locking:** When locked, the toggle frame darkens, the checkbox dims, and clicking does nothing. Config loading is blocked for this flag while locked.

---

### Slider

A draggable value slider with a colored fill bar.

```lua
local Slider = Tab:AddSlider({
    Name      = "Speed",
    Min       = 0,
    Max       = 100,
    Default   = 50,
    Increment = 1,
    ValueName = "studs/s",               -- appended to the displayed value
    Color     = Color3.fromRGB(9, 149, 98),
    Flag      = "speedSlider",
    Save      = false,
    OnLoad    = function(value) end,
    Callback  = function(value)
        print("Speed:", value)
    end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Slider"` | Slider label |
| `Min` | number | `0` | Minimum value |
| `Max` | number | `100` | Maximum value |
| `Default` | number | `50` | Starting value |
| `Increment` | number | `1` | Snap interval |
| `ValueName` | string | `""` | Suffix shown after the number |
| `Color` | Color3 | Green | Fill bar color |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Save to config |
| `OnLoad` | function | `nil` | Fired after config loads this value |
| `Callback` | function | `function()end` | Fired on value change |

**Returns:**

| Method / Property | Description |
|---|---|
| `Slider:Set(number)` | Set the slider value programmatically |
| `Slider.Value` | Current value |

---

### Dropdown

An expandable option list. Supports single-select and multi-select modes. Individual options can be disabled.

```lua
-- Single select
local DD = Tab:AddDropdown({
    Name            = "Choose Mode",
    Options         = {"Option A", "Option B", "Option C"},
    Default         = "Option A",
    DisabledOptions = {"Option C"},    -- greyed out, unclickable
    IsMulti         = false,
    Flag            = "modeDropdown",
    Save            = false,
    OnLoad          = function(value) end,
    Callback        = function(value)
        print("Selected:", value)
    end,
})

-- Multi select
local DDMulti = Tab:AddDropdown({
    Name    = "Select Items",
    Options = {"Sword", "Shield", "Bow"},
    IsMulti = true,
    Callback = function(tbl)
        -- tbl is a dictionary: { ["Sword"] = true, ["Bow"] = true }
        for item in pairs(tbl) do
            print("Selected:", item)
        end
    end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Dropdown"` | Dropdown label |
| `Options` | table | `{}` | List of option strings |
| `Default` | string | `""` | Pre-selected option (single mode) |
| `DisabledOptions` | table | `{}` | Options to grey out and block |
| `IsMulti` | bool | `false` | Enable multi-select mode |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Save to config |
| `OnLoad` | function | `nil` | Fired after config loads this value |
| `Callback` | function | `function()end` | Fired on selection change |

**Single-select value:** a `string`.
**Multi-select value:** a dictionary `{ [optionName] = true }` for each selected option. The header shows `"N selected"` when more than one option is active.

**Returns:**

| Method | Description |
|---|---|
| `DD:Set(value)` | Set selected value — string for single, table array for multi |
| `DD:Refresh(options, deleteOld)` | Replace or append options. `deleteOld = true` clears existing options first |

---

### Bind

A keybind element. Click it to enter binding mode, then press any key or mouse button to assign.

```lua
local Bind = Tab:AddBind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Hold     = false,      -- if true, callback fires on hold start and hold end
    Flag     = "uiBind",
    Save     = false,
    Callback = function()
        print("Bind triggered!")
    end,
    -- Hold mode callback receives a bool:
    -- Callback = function(holding) print(holding) end
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Bind"` | Bind label |
| `Default` | KeyCode / UserInputType | `Unknown` | Default key |
| `Hold` | bool | `false` | Fire callback on hold and release instead of tap |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Save to config |
| `Callback` | function | `function()end` | Fired on key press (or hold/release if `Hold = true`) |

**Blacklisted keys** (cannot be bound): W, A, S, D, arrow keys, Slash, Tab, Backspace, Escape, Unknown.

**Returns:**

| Method / Property | Description |
|---|---|
| `Bind:Set(key)` | Set the bind key (KeyCode or UserInputType) |
| `Bind.Value` | Current bound key name string |
| `Bind.Binding` | `true` while waiting for a key press to assign |

---

### Textbox

An inline text input that expands as text grows.

```lua
Tab:AddTextbox({
    Name          = "Player Name",
    Default       = "",
    PlaceholderText = "Input",      -- shown when empty
    TextDisappear = false,          -- clear text after focus lost
    Callback      = function(text)
        print("Entered:", text)
    end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Textbox"` | Label |
| `Default` | string | `""` | Pre-filled text |
| `TextDisappear` | bool | `false` | Clear text on focus lost |
| `Callback` | function | `function()end` | Fired when focus is lost |

---

### Colorpicker

An expandable HSV color picker with a saturation/value field and a hue strip. Supports mouse and touch drag.

```lua
local CP = Tab:AddColorpicker({
    Name     = "Highlight Color",
    Default  = Color3.fromRGB(255, 0, 0),
    Flag     = "highlightColor",
    Save     = false,
    OnLoad   = function(color) end,
    Callback = function(color)
        print("Color:", color)
    end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Colorpicker"` | Label |
| `Default` | Color3 | White | Starting color |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Save to config |
| `OnLoad` | function | `nil` | Fired after config loads this value |
| `Callback` | function | `function()end` | Fired on color change |

Click the row to expand/collapse the picker. Drag the left panel for saturation/value, drag the right strip for hue.

**Returns:**

| Method / Property | Description |
|---|---|
| `CP:Set(Color3)` | Set the color programmatically |
| `CP.Value` | Current `Color3` value |

---

### Separator

A thin horizontal divider line with an optional centered label.

```lua
-- Plain line
local Sep = Tab:AddSeparator({})

-- Labeled line
local Sep = Tab:AddSeparator({
    Name = "Advanced Options"
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `nil` | Optional centered label text |

**Returns:**

| Method | Description |
|---|---|
| `Sep:Set(text)` | Update the separator label text |

---

### ProgressBar

A fill bar with optional named steps and a current-action label.

```lua
local Bar = Tab:AddProgressBar({
    Name    = "Loading Assets",          -- required — displayed above the bar
    Steps   = {                          -- optional step names (shown below bar)
        "Connecting to server",
        "Fetching data",
        "Applying changes",
        "Done"
    },
    Default = 1,                         -- starting step index (1-based)
})

-- Advance steps
Bar:SetStep(2)   -- "Fetching data", bar fills to 33%
Bar:SetStep(4)   -- "Done", bar fills to 100%

-- Update title
Bar:SetName("Installing Mods")
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `""` | Title shown above the bar |
| `Steps` | table | `{}` | Array of step name strings |
| `Default` | number | `1` | Starting step index |

**Returns:**

| Method / Property | Description |
|---|---|
| `Bar:SetStep(n)` | Move to step `n` (1-based). Tweens the fill and updates the step label. |
| `Bar:SetName(text)` | Update the title label |
| `Bar.Value` | Current step index |

If `Steps` is empty, the bar still works — call `SetStep` with a 0–1 fraction manually by omitting the Steps table and driving `SetStep` yourself, or simply use it as a display-only bar with `SetName`.

---

### ThemeSwitcher

A pre-built dropdown that lists all available themes and switches the UI theme live on select.

```lua
Tab:AddThemeSwitcher()
```

No configuration required. The dropdown is automatically populated with all theme names and updates the entire UI when a new theme is selected.

---

### Section

A labeled group container. Visually separates elements within a tab. Elements added inside a section behave identically to elements added directly to a tab.

```lua
local Section = Tab:AddSection({
    Name = "Combat Settings"
})

-- All normal element methods are available on a Section:
Section:AddToggle({ Name = "Auto-Parry", ... })
Section:AddSlider({ Name = "Attack Speed", ... })
Section:AddButton({ Name = "Reset", ... })
-- etc.
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Section"` | Section header label |

Sections support: `AddLabel`, `AddParagraph`, `AddButton`, `AddToggle`, `AddSlider`, `AddDropdown`, `AddBind`, `AddTextbox`, `AddColorpicker`, `AddSeparator`, `AddProgressBar`, `AddThemeSwitcher`.

---

## Notifications

Display a temporary toast notification in the bottom-right corner.

```lua
local notif = unknown:MakeNotification({
    Name    = "Success!",
    Content = "The operation completed successfully.",
    Image   = "rbxassetid://4384403532",  -- optional icon
    Time    = 5,                           -- seconds before auto-dismiss
    Type    = "Success",                   -- "Info" | "Success" | "Warning" | "Error"
})

-- Dismiss early
notif:Close()    -- or: notif:Dismiss()
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Notification"` | Bold title |
| `Content` | string | `"Test"` | Body text (word-wrapped) |
| `Image` | string | built-in | Left icon asset ID |
| `Time` | number | `15` | Seconds until auto-dismiss |
| `Type` | string | `"Info"` | Notification type — sets accent color |

### Notification Types

| Type | Accent Color |
|---|---|
| `"Info"` | Blue `(0, 120, 255)` |
| `"Success"` | Green `(0, 180, 80)` |
| `"Warning"` | Orange `(255, 160, 0)` |
| `"Error"` | Red `(220, 50, 50)` |

The accent color is shown as a 3px left border strip on the notification frame.

**Returns:**

| Method | Description |
|---|---|
| `notif:Close()` | Immediately start the fade-out and slide-off animation |
| `notif:Dismiss()` | Alias for `Close()` |

---

## Themes

### Built-in Themes

| Name | Style |
|---|---|
| `Default` | Dark grey |
| `Midnight` | Deep blue-black |
| `Rose` | Dark with pink/rose accents |
| `Ocean` | Dark navy/teal |
| `Forest` | Dark muted green |
| `Ember` | Dark orange/amber |
| `Slate` | Cool blue-grey |
| `Mocha` | Warm dark brown |

### Setting a Theme

**On window creation:**
```lua
unknown:MakeWindow({ Theme = "Midnight", ... })
```

**At runtime via ThemeSwitcher element:**
```lua
Tab:AddThemeSwitcher()
```

### Adding a Custom Theme

Add entries to `unknown.Themes` before calling `MakeWindow`:

```lua
unknown.Themes.Neon = {
    Main     = Color3.fromRGB(10, 10, 10),
    Second   = Color3.fromRGB(18, 18, 18),
    Stroke   = Color3.fromRGB(0, 255, 120),
    Divider  = Color3.fromRGB(0, 255, 120),
    Text     = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(0, 200, 100),
}
```

All six keys are required. Once added, `"Neon"` will appear in `AddThemeSwitcher()` automatically.

---

## Config System

The config system serializes all flagged element values to a JSON file and loads them on the next session.

### Enabling Config

```lua
local Window = unknown:MakeWindow({
    SaveConfig   = true,
    ConfigFolder = "MyScript",    -- folder created in the executor's workspace
    ConfigName   = "profile1",   -- filename (without .txt); defaults to game.GameId
})
```

### Flagging Elements

Add `Flag` and `Save = true` to any element that supports it:

```lua
Tab:AddToggle({
    Name    = "God Mode",
    Flag    = "godMode",    -- unique string key
    Save    = true,
    Callback = function(v) ... end,
})
```

Supported by: Toggle, Slider, Dropdown, Bind, Colorpicker.

### OnLoad Callback

Fires immediately after config loads a specific flag's value:

```lua
Tab:AddToggle({
    Flag   = "godMode",
    Save   = true,
    OnLoad = function(loadedValue)
        print("Loaded godMode as:", loadedValue)
    end,
    Callback = function(v) ... end,
})
```

> OnLoad is not called for flags inside **locked tabs** until the tab is unlocked.

### Auto-loading Config

Call `unknown:Init()` after all windows and tabs are created:

```lua
unknown:Init()
```

This checks if a save file exists for the current `ConfigName` and loads it automatically, then shows an Info notification.

### Resetting Config

Resets all flagged elements to their `Default` values:

```lua
unknown:ResetConfig()
```

---

## Global Methods

Methods called directly on the `unknown` object.

### `unknown:MakeWindow(config)` → `TabFunction`
Create the main window. See [Window](#window).

### `unknown:MakeNotification(config)` → `handle`
Show a notification. See [Notifications](#notifications).

### `unknown:Init()`
Load saved config (if `SaveConfig = true`) and fire a notification. Call this after all tabs and elements are set up.

### `unknown:ResetConfig()`
Reset all flagged elements to their default values.

### `unknown:Destroy()`
Destroy the entire UI and clean up all connections.

### `unknown:IsRunning()` → `bool`
Returns `true` if the UI ScreenGui is still parented and active.

---

## Full Example

```lua
local unknown = loadstring(game:HttpGetAsync("YOUR_RAW_URL"))()

local Window = unknown:MakeWindow({
    Name         = "My Script",
    Theme        = "Midnight",
    DefaultTab   = "Main",
    IntroEnabled = true,
    IntroText    = "My Script",
    SaveConfig   = true,
    ConfigFolder = "MyScript",
    ConfigName   = "default",
    Transparent  = false,
    Blur         = false,
    MinSize      = Vector2.new(400, 280),
    MaxSize      = Vector2.new(800, 500),
    CloseCallback = function()
        print("UI closed")
    end,
})

-- Main tab
local Main = Window:MakeTab({
    Name = "Main",
    Icon = "home",
})

Main:AddLabel("Welcome to My Script")

Main:AddSeparator({ Name = "Toggles" })

local GodMode = Main:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Flag     = "godMode",
    Save     = true,
    Callback = function(v)
        print("God Mode:", v)
    end,
})

Main:AddSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 200,
    Default   = 16,
    Increment = 1,
    ValueName = "stud/s",
    Flag      = "walkSpeed",
    Save      = true,
    Callback  = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

Main:AddDropdown({
    Name    = "Team",
    Options = {"Red", "Blue", "Green"},
    Default = "Red",
    Callback = function(v)
        print("Team:", v)
    end,
})

Main:AddButton({
    Name     = "Reset Character",
    Callback = function()
        game.Players.LocalPlayer.Character.Humanoid.Health = 0
    end,
})

-- Settings tab
local Settings = Window:MakeTab({
    Name = "Settings",
    Icon = "settings",
})

Settings:AddThemeSwitcher()

Settings:AddBind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Flag     = "uiToggle",
    Save     = true,
    Callback = function()
        print("UI toggled")
    end,
})

-- Locked tab example
local Premium = Window:MakeTab({
    Name   = "Premium",
    Icon   = "lock",
    Locked = true,
})

-- Unlock later:
-- Premium:SetLocked(false)

-- Notifications example
local n = unknown:MakeNotification({
    Name    = "Ready",
    Content = "Script loaded successfully.",
    Time    = 4,
    Type    = "Success",
})

-- Start config auto-load
unknown:Init()
```

---

## Notes

- **Mobile support** — Window drag and colorpicker pickers both respond to touch input (`UserInputType.Touch`).
- **Lucide icons** — Any icon name from [lucide.dev](https://lucide.dev) can be used as a string for tab and element icons. Falls back gracefully if the icon is not found.
- **Flags must be unique** — Using the same `Flag` key for two elements will cause one to overwrite the other in config.
- **Locked tab + config** — If `SaveConfig = true` and a tab is locked on load, its flags will not be restored until `Tab:SetLocked(false)` is called.
- **ThemeSwitcher** — Always reflects all themes in `unknown.Themes`, including custom ones added after the library loads.
