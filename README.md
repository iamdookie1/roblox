# Unknown UI Library

A lightweight, feature-rich Roblox UI library designed for executor script interfaces. Supports 8 built-in themes, mobile drag, config saving, element locking, multi-select dropdowns, progress bars, typed notifications, and more.

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
- [Full Example](#full-example)

---

## Loading

```lua
local unknown = loadstring(game:HttpGetAsync("YOUR_RAW_URL_HERE"))()
```

---

## Window

### MakeWindow Options

Creates the main UI window. Returns a `Window` object used to create tabs and call window-level methods.

```lua
local Window = unknown:MakeWindow({
    Name              = "My Script",
    IntroEnabled      = true,
    IntroText         = "My Script",
    IntroIcon         = "rbxassetid://8834748103",
    ShowIcon          = false,
    Icon              = "rbxassetid://8834748103",
    Theme             = "Default",
    DefaultTab        = "Main",
    SaveConfig        = true,
    ConfigFolder      = "MyScript",
    ConfigName        = "profile1",
    Transparent       = false,
    TransparencyAmount = 0.3,
    Blur              = false,
    MinSize           = Vector2.new(400, 280),
    MaxSize           = Vector2.new(900, 600),
    CloseCallback     = function() end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Unknown Library"` | Window title in the top bar |
| `IntroEnabled` | bool | `true` | Play the animated intro splash on open |
| `IntroText` | string | `"Unknown Library"` | Text shown during the intro |
| `IntroIcon` | string | built-in | Asset ID for the intro icon |
| `ShowIcon` | bool | `false` | Show an icon beside the window title |
| `Icon` | string | built-in | Top-bar icon asset ID (requires `ShowIcon = true`) |
| `Theme` | string | `"Default"` | Starting theme — see [Themes](#themes) |
| `DefaultTab` | string | `nil` | Tab name to open first; falls back to first tab if nil or invalid |
| `SaveConfig` | bool | `false` | Enable config auto-save/load |
| `ConfigFolder` | string | `Name` | Folder name used to store config files |
| `ConfigName` | string | `game.GameId` | Config filename (without `.txt`) |
| `Transparent` | bool | `false` | Enable window background transparency |
| `TransparencyAmount` | number | `0` | Transparency level: `0.0` (solid) to `0.7` (max, never fully invisible) |
| `Blur` | bool | `false` | Apply a `BlurEffect` to Lighting while the window is open. Removed automatically on close, restored on reopen. |
| `MinSize` | Vector2 | `(400, 280)` | Minimum window size when resizing |
| `MaxSize` | Vector2 | `(900, 600)` | Maximum window size when resizing |
| `CloseCallback` | function | `function()end` | Called when the close button is pressed |

**Resize:** A drag handle sits at the bottom-right corner. Drag it to resize between `MinSize` and `MaxSize`. Works on mouse and touch.

**Close / Reopen:** Pressing the close (×) button hides the window. Press **RightShift** to reopen it. Blur is removed on hide and restored on reopen.

**Minimize:** The minimize button collapses the window to the title bar.

---

### Window Methods

```lua
Window:SetTab("Settings")       -- switch to a tab by name
Window:WindowLocked(true)       -- hide close/minimize and disable drag
Window:WindowLocked(false)      -- restore close/minimize and drag
```

#### `Window:SetTab(name)`
Switches the active tab to the one matching `name`. If the name doesn't match any tab or the tab is locked, the first accessible tab is used instead.

#### `Window:WindowLocked(bool)`
`true` — hides close and minimize buttons and disables window dragging.  
`false` — restores them.

---

## Tabs

### MakeTab Options

```lua
local Tab = Window:MakeTab({
    Name   = "Main",
    Icon   = "home",
    Locked = false,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Tab"` | Tab label shown in the sidebar |
| `Icon` | string | `""` | Lucide icon name (e.g. `"home"`, `"settings"`) or `rbxassetid://...` |
| `Locked` | bool | `false` | Lock the tab on creation |

**Icons:** Pass any name from [lucide.dev](https://lucide.dev) as a plain string. Asset IDs work too.

**Locked tab behaviour:** The tab is dimmed to 70% transparency, a lock icon appears on the right, clicking it does nothing, and config values for flags inside it are not loaded until unlocked.

---

### Tab Methods

```lua
Tab:SetLocked(true)    -- lock: dims tab, blocks access, pauses config load
Tab:SetLocked(false)   -- unlock: restores tab, triggers config load for its flags
```

---

## Elements

All elements are created by calling methods on a `Tab` or `Section` object.

---

### Label

Read-only text row.

```lua
local Lbl = Tab:AddLabel("Status: Ready")

Lbl:Set("Status: Running")
```

| Returns | Description |
|---|---|
| `:Set(text)` | Update the label text |

---

### Paragraph

Bold title with a word-wrapped body below.

```lua
local Para = Tab:AddParagraph("How to use", "Press the buttons below to activate features. Hold Q to sprint.")

Para:Set("Updated description.")
```

| Parameter | Description |
|---|---|
| `Text` | Bold title |
| `Content` | Body text (word-wrapped, auto-sizes height) |

| Returns | Description |
|---|---|
| `:Set(text)` | Update the body content |

---

### Button

Clickable row that fires a callback. Supports locking.

```lua
local Btn = Tab:AddButton({
    Name     = "Teleport to Spawn",
    Callback = function()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame =
            CFrame.new(0, 5, 0)
    end,
    Icon   = "rbxassetid://3944703587",
    Locked = false,
})

Btn:Set("New Label")
Btn:ButtonLocked(true)   -- darken, show lock icon, block callback
Btn:ButtonLocked(false)  -- revert
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Button"` | Button label |
| `Callback` | function | `function()end` | Fired on click |
| `Icon` | string | built-in | Right-side icon asset ID |
| `Locked` | bool | `false` | Lock on creation |

| Returns | Description |
|---|---|
| `:Set(text)` | Update the button label |
| `:ButtonLocked(bool)` | Lock or unlock at runtime |
| `.Locked` | Current lock state |

---

### Toggle

On/off toggle with an animated checkbox. Supports locking.

```lua
local Toggle = Tab:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Color    = Color3.fromRGB(9, 99, 195),
    Locked   = false,
    Flag     = "godMode",
    Save     = true,
    OnLoad   = function(v) print("Loaded god mode:", v) end,
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.MaxHealth = v and math.huge or 100
    end,
})

Toggle:Set(true)
Toggle:ToggleLocked(true)   -- darken + disable
Toggle:ToggleLocked(false)  -- revert + re-enable
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Toggle"` | Label |
| `Default` | bool | `false` | Starting state |
| `Color` | Color3 | Blue | Checkbox color when enabled |
| `Locked` | bool | `false` | Lock on creation |
| `Flag` | string | `nil` | Config save key |
| `Save` | bool | `false` | Persist in config |
| `OnLoad` | function | `nil` | Called when config loads this value |
| `Callback` | function | `function()end` | Called on state change |

| Returns | Description |
|---|---|
| `:Set(bool)` | Set state programmatically |
| `:ToggleLocked(bool)` | Lock or unlock at runtime |
| `.Value` | Current state |
| `.Locked` | Current lock state |

---

### Slider

Draggable value bar with a colored fill.

```lua
local Slider = Tab:AddSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 250,
    Default   = 16,
    Increment = 1,
    ValueName = "stud/s",
    Color     = Color3.fromRGB(9, 149, 98),
    Flag      = "walkSpeed",
    Save      = true,
    OnLoad    = function(v) print("Loaded speed:", v) end,
    Callback  = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

Slider:Set(100)
print(Slider.Value)
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Slider"` | Label |
| `Min` | number | `0` | Minimum value |
| `Max` | number | `100` | Maximum value |
| `Default` | number | `50` | Starting value |
| `Increment` | number | `1` | Snap interval |
| `ValueName` | string | `""` | Suffix shown after the number |
| `Color` | Color3 | Green | Fill bar color |
| `Flag` | string | `nil` | Config save key |
| `Save` | bool | `false` | Persist in config |
| `OnLoad` | function | `nil` | Called when config loads this value |
| `Callback` | function | `function()end` | Called on value change |

| Returns | Description |
|---|---|
| `:Set(number)` | Set value programmatically |
| `.Value` | Current value |

---

### Dropdown

Expandable option list. Supports single-select, multi-select, and disabled options.

```lua
-- Single select
local DD = Tab:AddDropdown({
    Name            = "Game Mode",
    Options         = {"Normal", "Hard", "Extreme", "Debug"},
    Default         = "Normal",
    DisabledOptions = {"Debug"},
    IsMulti         = false,
    Flag            = "gameMode",
    Save            = true,
    Callback        = function(selected)
        print("Mode:", selected)
    end,
})

-- Multi select
local MultiDD = Tab:AddDropdown({
    Name    = "Active Hacks",
    Options = {"Aimbot", "ESP", "Speed", "Fly"},
    IsMulti = true,
    Callback = function(tbl)
        for hack in pairs(tbl) do
            print("Active:", hack)
        end
    end,
})

DD:Set("Hard")
MultiDD:Set({"ESP", "Fly"})
DD:Refresh({"Normal", "Hard"}, true)  -- replace options
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Dropdown"` | Label |
| `Options` | table | `{}` | Array of option strings |
| `Default` | string | `""` | Pre-selected option (single mode only) |
| `DisabledOptions` | table | `{}` | Options to grey out — unclickable |
| `IsMulti` | bool | `false` | Multi-select mode |
| `Flag` | string | `nil` | Config save key |
| `Save` | bool | `false` | Persist in config |
| `OnLoad` | function | `nil` | Called when config loads this value |
| `Callback` | function | `function()end` | Called on change |

**Single-select value:** `string`.  
**Multi-select value:** `{ [option] = true }` dictionary. Header shows `"N selected"` for N > 1.

| Returns | Description |
|---|---|
| `:Set(value)` | Set selected value — string for single, array table for multi |
| `:Refresh(options, deleteOld)` | Replace or append options; `deleteOld = true` clears existing first |

---

### Bind

Keybind element. Click to enter binding mode, press any key or mouse button to assign.

```lua
local Bind = Tab:AddBind({
    Name     = "Toggle Fly",
    Default  = Enum.KeyCode.F,
    Hold     = false,
    Flag     = "flyBind",
    Save     = true,
    Callback = function()
        print("Fly toggled")
    end,
    -- For Hold mode:
    -- Callback = function(holding) print("Holding:", holding) end
})

Bind:Set(Enum.KeyCode.G)
print(Bind.Value)  -- "G"
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Bind"` | Label |
| `Default` | KeyCode / UserInputType | `Unknown` | Default key |
| `Hold` | bool | `false` | Fires callback with `true` on hold start, `false` on release |
| `Flag` | string | `nil` | Config save key |
| `Save` | bool | `false` | Persist in config |
| `Callback` | function | `function()end` | Fired on press (or hold/release if `Hold = true`) |

**Blacklisted keys (cannot be bound):** WASD, arrow keys, Slash, Tab, Backspace, Escape, Unknown.

| Returns | Description |
|---|---|
| `:Set(key)` | Set bind key (KeyCode or UserInputType) |
| `.Value` | Current bound key name |
| `.Binding` | `true` while waiting for input |

---

### Textbox

Inline text input box that grows with content.

```lua
local TB = Tab:AddTextbox({
    Name          = "Target Player",
    Default       = "",
    TextDisappear = false,
    Callback      = function(text)
        print("Entered:", text)
    end,
})

TB:Set("Roblox")
print(TB:Get())
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Textbox"` | Label |
| `Default` | string | `""` | Pre-filled text |
| `TextDisappear` | bool | `false` | Clear text after focus is lost |
| `Callback` | function | `function()end` | Called when focus is lost |

| Returns | Description |
|---|---|
| `:Set(text)` | Set the textbox value |
| `:Get()` | Get the current text |

---

### Colorpicker

Expandable HSV color picker. Supports mouse and touch drag.

```lua
local CP = Tab:AddColorpicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(255, 50, 50),
    Flag     = "espColor",
    Save     = true,
    OnLoad   = function(c) print("Loaded color:", c) end,
    Callback = function(color)
        -- update ESP color
    end,
})

CP:Set(Color3.fromRGB(0, 255, 100))
print(CP.Value)
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Colorpicker"` | Label |
| `Default` | Color3 | White | Starting color |
| `Flag` | string | `nil` | Config save key |
| `Save` | bool | `false` | Persist in config |
| `OnLoad` | function | `nil` | Called when config loads this value |
| `Callback` | function | `function()end` | Called on color change |

Click the row to expand or collapse the picker. Left panel = saturation/value, right strip = hue.

| Returns | Description |
|---|---|
| `:Set(Color3)` | Set the color programmatically |
| `.Value` | Current `Color3` |

---

### Separator

A thin horizontal divider. With a label the line breaks around it — left segment, text, right segment.

```lua
-- Plain line
local Sep1 = Tab:AddSeparator({})

-- Labeled line — line breaks around the text
local Sep2 = Tab:AddSeparator({ Name = "Advanced" })

Sep2:Set("Expert Only")
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `nil` | Optional centered label — the line splits around it |

| Returns | Description |
|---|---|
| `:Set(text)` | Update the label text at runtime |

---

### ProgressBar

Fill bar with optional named steps and a current-step label.

```lua
local Bar = Tab:AddProgressBar({
    Name    = "Loading",
    Steps   = { "Connecting", "Fetching data", "Applying", "Done" },
    Default = 1,
})

-- Advance with buttons
Tab:AddButton({ Name = "Next Step", Callback = function() Bar:SetStep(Bar.Value + 1) end })
Tab:AddButton({ Name = "Reset",     Callback = function() Bar:SetStep(1) end })

Bar:SetStep(3)            -- "Applying" — bar fills to 66%
Bar:SetName("Installing") -- update title
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `""` | Title shown above the bar (required for display) |
| `Steps` | table | `{}` | Array of step name strings shown below the bar |
| `Default` | number | `1` | Starting step index (1-based) |

| Returns | Description |
|---|---|
| `:SetStep(n)` | Move to step n — tweens fill, updates step label |
| `:SetName(text)` | Update the title label |
| `.Value` | Current step index |

---

### ThemeSwitcher

Pre-built dropdown that lists all themes and switches the UI live on select.

```lua
Tab:AddThemeSwitcher()
```

No configuration needed. Automatically includes all built-in and custom themes.

---

### Section

A labeled group inside a tab. All element methods work identically inside a section.

```lua
local Sec = Tab:AddSection({ Name = "Visuals" })

Sec:AddToggle({ Name = "ESP",   Callback = function(v) end })
Sec:AddColorpicker({ Name = "ESP Color", Callback = function(c) end })
Sec:AddSlider({ Name = "ESP Range", Min = 10, Max = 1000, Default = 500, Callback = function(v) end })
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Section"` | Section header label |

Sections support all elements: Label, Paragraph, Button, Toggle, Slider, Dropdown, Bind, Textbox, Colorpicker, Separator, ProgressBar, ThemeSwitcher.

---

## Notifications

Toast notifications stacked in the bottom-right corner.

```lua
local n = unknown:MakeNotification({
    Name    = "Done",
    Content = "Operation completed successfully.",
    Image   = "rbxassetid://4384403532",
    Time    = 5,
    Type    = "Success",
})

n:Close()    -- dismiss early
n:Dismiss()  -- same as Close()
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Notification"` | Bold title |
| `Content` | string | `"Test"` | Body text (word-wrapped) |
| `Image` | string | built-in | Left icon asset ID |
| `Time` | number | `15` | Seconds before auto-dismiss |
| `Type` | string | `"Info"` | Accent type — sets left border color |

### Notification Types

| Type | Color | Use for |
|---|---|---|
| `"Info"` | Blue `(0, 120, 255)` | General information |
| `"Success"` | Green `(0, 180, 80)` | Operation completed |
| `"Warning"` | Orange `(255, 160, 0)` | Potential issue |
| `"Error"` | Red `(220, 50, 50)` | Failure / critical |

| Returns | Description |
|---|---|
| `:Close()` | Start fade-out and slide-off animation immediately |
| `:Dismiss()` | Alias for `Close()` |

---

## Themes

### Built-in Themes

| Name | Style |
|---|---|
| `Default` | Dark grey — neutral baseline |
| `Midnight` | Near-black with vivid blue glow |
| `Rose` | Dark wine with crimson glow |
| `Ocean` | Deep navy with cyan glow |
| `Forest` | Dark pine with vivid green glow |
| `Ember` | Charcoal with molten orange glow |
| `Slate` | Steel blue-grey |
| `Mocha` | Dark espresso with caramel glow |

### Setting a Theme

```lua
-- On window creation:
unknown:MakeWindow({ Theme = "Midnight" })

-- Via ThemeSwitcher element (live switching):
Tab:AddThemeSwitcher()
```

### Adding a Custom Theme

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

All six keys are required. Custom themes automatically appear in `AddThemeSwitcher()`.

---

## Config System

Serialises all flagged element values to JSON and reloads them on the next session.

### Setup

```lua
local Window = unknown:MakeWindow({
    SaveConfig   = true,
    ConfigFolder = "MyScript",
    ConfigName   = "default",
})
```

### Flagging Elements

```lua
Tab:AddToggle({
    Name     = "Feature",
    Flag     = "myFeature",   -- unique key
    Save     = true,
    Callback = function(v) end,
})
```

Supported: Toggle, Slider, Dropdown, Bind, Colorpicker.

### OnLoad

Fires after config restores a specific flag's value:

```lua
Tab:AddToggle({
    Flag   = "myFeature",
    Save   = true,
    OnLoad = function(loaded)
        print("Restored:", loaded)
    end,
    Callback = function(v) end,
})
```

> **Note:** `OnLoad` does not fire for flags inside locked tabs until `Tab:SetLocked(false)` is called.

### Auto-Loading

Call `unknown:Init()` **after** all tabs and elements are created:

```lua
unknown:Init()
```

Checks for a save file matching `ConfigName` and loads it, then shows an Info notification.

### Reset All to Defaults

```lua
unknown:ResetConfig()
```

Calls `:Set(Default)` on every flagged element that has a `Default` value.

---

## Global Methods

| Method | Returns | Description |
|---|---|---|
| `unknown:MakeWindow(config)` | `Window` | Create the main window |
| `unknown:MakeNotification(config)` | `handle` | Show a toast notification |
| `unknown:Init()` | — | Load saved config and fire OnLoad callbacks |
| `unknown:ResetConfig()` | — | Reset all flags to their defaults |
| `unknown:Destroy()` | — | Destroy the UI and disconnect all connections |
| `unknown:IsRunning()` | `bool` | `true` if the UI is still active |

---

## Full Example

This example covers every element, shows notification type demos via buttons, advances a progress bar via buttons, uses sections, locked tabs, multi-select dropdown, keybinds, config saving, and custom theme.

```lua
local unknown = loadstring(game:HttpGetAsync("YOUR_RAW_URL"))()

-- Optional: add a custom theme before MakeWindow
unknown.Themes.Neon = {
    Main     = Color3.fromRGB(10, 10, 10),
    Second   = Color3.fromRGB(18, 18, 18),
    Stroke   = Color3.fromRGB(0, 255, 120),
    Divider  = Color3.fromRGB(0, 255, 120),
    Text     = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(0, 200, 100),
}

local Window = unknown:MakeWindow({
    Name              = "Unknown Script",
    Theme             = "Midnight",
    DefaultTab        = "Main",
    IntroEnabled      = true,
    IntroText         = "Unknown Script",
    ShowIcon          = false,
    SaveConfig        = true,
    ConfigFolder      = "UnknownScript",
    ConfigName        = "default",
    Transparent       = false,
    Blur              = false,
    MinSize           = Vector2.new(430, 300),
    MaxSize           = Vector2.new(800, 520),
    CloseCallback     = function()
        print("UI hidden — RightShift to reopen")
    end,
})

-- ══════════════════════════════════════
--   MAIN TAB
-- ══════════════════════════════════════
local Main = Window:MakeTab({ Name = "Main", Icon = "home" })

Main:AddLabel("Welcome to Unknown Script")
Main:AddParagraph("Read me", "This UI is fully themeable and supports config saving. Use the Settings tab to switch themes or remap keys.")

Main:AddSeparator({ Name = "Player" })

local GodToggle = Main:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Color    = Color3.fromRGB(255, 60, 60),
    Flag     = "godMode",
    Save     = true,
    OnLoad   = function(v) print("[Config] God Mode loaded as:", v) end,
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character and
                    game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.MaxHealth = v and math.huge or 100
            hum.Health    = v and math.huge or 100
        end
    end,
})

local SpeedSlider = Main:AddSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 250,
    Default   = 16,
    Increment = 2,
    ValueName = "stud/s",
    Color     = Color3.fromRGB(9, 149, 98),
    Flag      = "walkSpeed",
    Save      = true,
    OnLoad    = function(v) print("[Config] Walk speed loaded as:", v) end,
    Callback  = function(v)
        local hum = game.Players.LocalPlayer.Character and
                    game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

local JumpSlider = Main:AddSlider({
    Name      = "Jump Power",
    Min       = 0,
    Max       = 200,
    Default   = 50,
    Increment = 5,
    ValueName = "power",
    Color     = Color3.fromRGB(60, 120, 220),
    Flag      = "jumpPower",
    Save      = true,
    Callback  = function(v)
        local hum = game.Players.LocalPlayer.Character and
                    game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

Main:AddSeparator({ Name = "Actions" })

Main:AddButton({
    Name     = "Teleport to Spawn",
    Callback = function()
        local root = game.Players.LocalPlayer.Character and
                     game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(0, 5, 0) end
    end,
})

Main:AddButton({
    Name     = "Respawn Character",
    Callback = function()
        game.Players.LocalPlayer:LoadCharacter()
    end,
})

-- Locked button example
local LockedBtn = Main:AddButton({
    Name     = "Admin Only Action",
    Locked   = true,
    Callback = function()
        print("Admin action fired!")
    end,
})
-- To unlock later: LockedBtn:ButtonLocked(false)

Main:AddSeparator({})  -- plain divider

local NameBox = Main:AddTextbox({
    Name          = "Chat Message",
    Default       = "",
    TextDisappear = true,
    Callback      = function(text)
        if #text > 0 then
            game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                and game.Players.LocalPlayer:Chat(text)
        end
    end,
})

-- ══════════════════════════════════════
--   COMBAT TAB
-- ══════════════════════════════════════
local Combat = Window:MakeTab({ Name = "Combat", Icon = "sword" })

local CombatSec = Combat:AddSection({ Name = "Aimbot" })

local AimbotToggle = CombatSec:AddToggle({
    Name     = "Aimbot",
    Default  = false,
    Flag     = "aimbot",
    Save     = true,
    Callback = function(v) print("Aimbot:", v) end,
})

CombatSec:AddSlider({
    Name      = "Aimbot FOV",
    Min       = 10,
    Max       = 500,
    Default   = 120,
    Increment = 5,
    ValueName = "px",
    Flag      = "aimbotFOV",
    Save      = true,
    Callback  = function(v) print("FOV:", v) end,
})

CombatSec:AddDropdown({
    Name    = "Aim Part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Flag    = "aimPart",
    Save    = true,
    Callback = function(v) print("Aiming at:", v) end,
})

local VisualsSec = Combat:AddSection({ Name = "ESP" })

local ESPToggle = VisualsSec:AddToggle({
    Name     = "ESP",
    Default  = false,
    Flag     = "esp",
    Save     = true,
    Callback = function(v) print("ESP:", v) end,
})

local ESPColor = VisualsSec:AddColorpicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(255, 50, 50),
    Flag     = "espColor",
    Save     = true,
    OnLoad   = function(c) print("[Config] ESP color loaded") end,
    Callback = function(c) print("ESP color changed:", c) end,
})

VisualsSec:AddDropdown({
    Name            = "ESP Info",
    Options         = { "Name", "Health", "Distance", "Weapon", "Debug" },
    IsMulti         = true,
    DisabledOptions = { "Debug" },
    Callback        = function(tbl)
        for k in pairs(tbl) do print("Show:", k) end
    end,
})

-- ══════════════════════════════════════
--   NOTIFICATIONS TAB
-- ══════════════════════════════════════
local Notifs = Window:MakeTab({ Name = "Notifications", Icon = "bell" })

Notifs:AddLabel("Press a button to preview each notification type.")
Notifs:AddSeparator({ Name = "Types" })

Notifs:AddButton({
    Name     = "Info Notification",
    Callback = function()
        unknown:MakeNotification({
            Name    = "Information",
            Content = "This is an informational message.",
            Time    = 4,
            Type    = "Info",
        })
    end,
})

Notifs:AddButton({
    Name     = "Success Notification",
    Callback = function()
        unknown:MakeNotification({
            Name    = "Success!",
            Content = "The operation completed without errors.",
            Time    = 4,
            Type    = "Success",
        })
    end,
})

Notifs:AddButton({
    Name     = "Warning Notification",
    Callback = function()
        unknown:MakeNotification({
            Name    = "Warning",
            Content = "Something might not work correctly.",
            Time    = 4,
            Type    = "Warning",
        })
    end,
})

Notifs:AddButton({
    Name     = "Error Notification",
    Callback = function()
        local n = unknown:MakeNotification({
            Name    = "Error",
            Content = "A critical error occurred. Check your input.",
            Time    = 6,
            Type    = "Error",
        })
        -- Dismiss it early after 2 seconds
        task.delay(2, function() n:Dismiss() end)
    end,
})

Notifs:AddSeparator({ Name = "Early Dismiss" })

Notifs:AddButton({
    Name     = "Show + Auto-dismiss in 1.5s",
    Callback = function()
        local n = unknown:MakeNotification({
            Name    = "Quick",
            Content = "This will disappear in 1.5 seconds.",
            Time    = 10,
            Type    = "Info",
        })
        task.delay(1.5, function() n:Close() end)
    end,
})

-- ══════════════════════════════════════
--   PROGRESS BAR TAB
-- ══════════════════════════════════════
local Progress = Window:MakeTab({ Name = "Progress", Icon = "loader" })

Progress:AddLabel("Use the buttons below to step through the progress bar.")

local Bar = Progress:AddProgressBar({
    Name    = "Loading Assets",
    Steps   = {
        "Connecting to server",
        "Loading textures",
        "Building world",
        "Spawning entities",
        "Finalising",
        "Done!",
    },
    Default = 1,
})

Progress:AddSeparator({ Name = "Controls" })

Progress:AddButton({
    Name     = "Next Step →",
    Callback = function()
        if Bar.Value < 6 then
            Bar:SetStep(Bar.Value + 1)
        end
    end,
})

Progress:AddButton({
    Name     = "← Previous Step",
    Callback = function()
        if Bar.Value > 1 then
            Bar:SetStep(Bar.Value - 1)
        end
    end,
})

Progress:AddButton({
    Name     = "Jump to Done",
    Callback = function()
        Bar:SetStep(6)
        unknown:MakeNotification({
            Name    = "Complete",
            Content = "All steps finished!",
            Time    = 3,
            Type    = "Success",
        })
    end,
})

Progress:AddButton({
    Name     = "Reset Bar",
    Callback = function()
        Bar:SetStep(1)
        Bar:SetName("Loading Assets")
    end,
})

Progress:AddButton({
    Name     = "Rename Bar",
    Callback = function()
        Bar:SetName("Installing Mods — Step " .. Bar.Value)
    end,
})

-- ══════════════════════════════════════
--   SETTINGS TAB
-- ══════════════════════════════════════
local Settings = Window:MakeTab({ Name = "Settings", Icon = "settings" })

Settings:AddThemeSwitcher()
Settings:AddSeparator({ Name = "Keybinds" })

Settings:AddBind({
    Name     = "Toggle UI Visibility",
    Default  = Enum.KeyCode.RightShift,
    Hold     = false,
    Flag     = "uiBind",
    Save     = true,
    Callback = function()
        print("UI toggle triggered via bind")
    end,
})

Settings:AddBind({
    Name     = "Sprint (Hold)",
    Default  = Enum.KeyCode.LeftShift,
    Hold     = true,
    Flag     = "sprintBind",
    Save     = true,
    Callback = function(holding)
        local hum = game.Players.LocalPlayer.Character and
                    game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = holding and 40 or SpeedSlider.Value
        end
    end,
})

Settings:AddSeparator({ Name = "Config" })

Settings:AddButton({
    Name     = "Reset All Settings",
    Callback = function()
        unknown:ResetConfig()
        unknown:MakeNotification({
            Name    = "Reset",
            Content = "All settings restored to defaults.",
            Time    = 3,
            Type    = "Info",
        })
    end,
})

Settings:AddDropdown({
    Name    = "Config Profile",
    Options = { "default", "pvp", "pve", "stealth" },
    Default = "default",
    Callback = function(profile)
        print("Switched to profile:", profile)
    end,
})

-- ══════════════════════════════════════
--   LOCKED TAB EXAMPLE
-- ══════════════════════════════════════
local Admin = Window:MakeTab({
    Name   = "Admin",
    Icon   = "shield",
    Locked = true,
})

-- Elements inside a locked tab still load but their config values
-- are NOT restored until the tab is unlocked.
Admin:AddToggle({
    Name     = "Kill All",
    Flag     = "killAll",
    Save     = false,
    Callback = function(v) print("Kill all:", v) end,
})

Admin:AddButton({
    Name     = "Shutdown Server",
    Callback = function() print("Shutdown!") end,
})

-- Unlock from another tab:
Settings:AddButton({
    Name     = "Unlock Admin Tab",
    Callback = function()
        Admin:SetLocked(false)
        unknown:MakeNotification({
            Name    = "Admin Unlocked",
            Content = "The Admin tab is now accessible.",
            Time    = 3,
            Type    = "Success",
        })
    end,
})

-- ══════════════════════════════════════
--   INIT (load config)
-- ══════════════════════════════════════
unknown:Init()
```
