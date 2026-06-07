# Unknown UI Library

A feature-rich Roblox executor UI library with 8 built-in themes, mobile support, config saving, element locking, connected-card layouts, per-element animations, typed notifications, and live window controls.

---

## Table of Contents

- [Loading](#loading)
- [Window](#window)
  - [MakeWindow Options](#makewindow-options)
  - [Window Methods](#window-methods)
- [Tabs](#tabs)
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

```lua
local Window = unknown:MakeWindow({
    -- Identity
    Name              = "My Script",
    IntroEnabled      = true,
    IntroText         = "My Script",
    IntroIcon         = "rbxassetid://8834748103",
    ShowIcon          = false,
    Icon              = "rbxassetid://8834748103",

    -- Theme & visuals
    Theme             = "Default",
    Transparent       = false,
    TransparencyAmount = 0.3,
    Blur              = false,

    -- Layout
    DefaultTab        = "Main",
    ConnectedElements = false,
    BetterAnimations  = false,
    MinSize           = Vector2.new(400, 280),
    MaxSize           = Vector2.new(900, 600),

    -- Config
    SaveConfig        = false,
    ConfigFolder      = "MyScript",
    ConfigName        = "default",

    -- Callbacks
    CloseCallback     = function() end,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Unknown Library"` | Window title |
| `IntroEnabled` | bool | `true` | Show animated splash on start |
| `IntroText` | string | `"Unknown Library"` | Splash text |
| `IntroIcon` | string | built-in | Splash icon asset ID |
| `ShowIcon` | bool | `false` | Show icon beside window title |
| `Icon` | string | built-in | Top-bar icon asset ID |
| `Theme` | string | `"Default"` | Starting theme name |
| `Transparent` | bool | `false` | Enable window background transparency |
| `TransparencyAmount` | number | `0` | Transparency 0.0–0.7 (never fully invisible) |
| `Blur` | bool | `false` | BlurEffect on Lighting while window is open. Auto-removed on close, restored on reopen. |
| `DefaultTab` | string | `nil` | Tab to open first; falls back to first tab if nil or wrong name |
| `ConnectedElements` | bool | `false` | Merge adjacent elements into connected card groups |
| `BetterAnimations` | bool | `false` | Smoother tab fades, button scale press, toggle bounce |
| `MinSize` | Vector2 | `(400, 280)` | Minimum resize dimensions |
| `MaxSize` | Vector2 | `(900, 600)` | Maximum resize dimensions |
| `SaveConfig` | bool | `false` | Enable config persistence |
| `ConfigFolder` | string | `Name` | Folder for config files |
| `ConfigName` | string | `game.GameId` | Config filename (no extension) |
| `CloseCallback` | function | `function()end` | Called when close button pressed |

**Resize:** Drag handle at the bottom-right corner. Clamps to `MinSize`/`MaxSize`. Works on mouse and touch.

**Close/Reopen:** Close button hides the window. **RightShift** reopens it. Blur is removed on hide and restored on reopen.

**ConnectedElements:** Adjacent elements (Button, Toggle, Slider, etc.) visually merge — shared borders are hidden and a subtle 1px line replaces the gap. `Separator` elements always break the chain. Works with Sections too.

**BetterAnimations:**
- Tab switch: fade out old container (0.1s), fade in new (0.14s)
- Button: scales down on press (0.08s), springs back (0.14s Back)
- Toggle: checkbox squeezes then bounces back on state change

---

### Window Methods

```lua
-- Tab navigation
Window:SetTab("Settings")

-- Lock the window (hide close/minimize, disable drag)
Window:WindowLocked(true)
Window:WindowLocked(false)

-- Live theme/visual changes (no recreation needed)
Window:ChangeTheme("Midnight")
Window:SetBlur(true)
Window:SetTransparent(true)
Window:SetTransparencyAmount(0.4)
```

| Method | Description |
|---|---|
| `:SetTab(name)` | Switch to named tab; falls back to first tab if name is invalid |
| `:WindowLocked(bool)` | Lock or unlock dragging and close/minimize buttons |
| `:ChangeTheme(name)` | Switch theme live — updates every themed object instantly |
| `:SetBlur(bool)` | Enable or disable Lighting blur |
| `:SetTransparent(bool)` | Enable or disable window transparency |
| `:SetTransparencyAmount(0–0.7)` | Set transparency level while transparent mode is on |

---

## Tabs

```lua
local Tab = Window:MakeTab({
    Name   = "Main",
    Icon   = "home",     -- Lucide icon name or rbxassetid://
    Locked = false,
})
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Tab"` | Tab label |
| `Icon` | string | `""` | Lucide icon name or asset ID |
| `Locked` | bool | `false` | Lock on creation |

**Icons:** Pass any name from [lucide.dev](https://lucide.dev) as a plain string (e.g. `"home"`, `"settings"`, `"sword"`). The library fetches the Lucide icon database from `icons.rest` on first use and caches it. Asset IDs (`rbxassetid://...`) also work.

**Locked tab behaviour:** The tab dims to 70%, shows a lock icon, blocks clicks, and skips config loading for its flags. Call `:SetLocked(false)` to unlock.

```lua
Tab:SetLocked(true)   -- lock
Tab:SetLocked(false)  -- unlock (also triggers config load for this tab's flags)
```

---

## Elements

All elements are created via methods on a `Tab` or `Section` object.

---

### Label

```lua
local Lbl = Tab:AddLabel("Status: Ready")
Lbl:Set("Status: Running")
```

| Returns | |
|---|---|
| `:Set(text)` | Update label text |

---

### Paragraph

```lua
local Para = Tab:AddParagraph("Title", "Body text here.")
Para:Set("Updated body.")
```

| Returns | |
|---|---|
| `:Set(text)` | Update body content |

---

### Button

```lua
local Btn = Tab:AddButton({
    Name     = "Click Me",
    Locked   = false,
    Icon     = "rbxassetid://3944703587",
    Callback = function() print("clicked") end,
})

Btn:Set("New Label")
Btn:ButtonLocked(true)   -- darken + block + lock icon
Btn:ButtonLocked(false)  -- revert
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Button"` | Label |
| `Callback` | function | `function()end` | Fired on click |
| `Icon` | string | built-in | Right-side icon |
| `Locked` | bool | `false` | Lock on creation |

| Returns | |
|---|---|
| `:Set(text)` | Update label |
| `:ButtonLocked(bool)` | Lock or unlock |
| `.Locked` | Current lock state |

---

### Toggle

```lua
local Toggle = Tab:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Color    = Color3.fromRGB(9, 99, 195),
    Locked   = false,
    Flag     = "godMode",
    Save     = true,
    OnLoad   = function(v) end,
    Callback = function(v) end,
})

Toggle:Set(true)
Toggle:ToggleLocked(true)   -- darken + disable
Toggle:ToggleLocked(false)  -- revert
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Toggle"` | Label |
| `Default` | bool | `false` | Starting state |
| `Color` | Color3 | Blue | Checkbox color when on |
| `Locked` | bool | `false` | Lock on creation |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Persist in config |
| `OnLoad` | function | `nil` | Called after config loads this value |
| `Callback` | function | `function()end` | Called on state change |

| Returns | |
|---|---|
| `:Set(bool)` | Set state |
| `:ToggleLocked(bool)` | Lock or unlock |
| `.Value` | Current state |
| `.Locked` | Lock state |

---

### Slider

```lua
local Slider = Tab:AddSlider({
    Name      = "Walk Speed",
    Min       = 16,
    Max       = 250,
    Default   = 16,
    Increment = 2,
    ValueName = "stud/s",
    Color     = Color3.fromRGB(9, 149, 98),
    Flag      = "walkSpeed",
    Save      = true,
    OnLoad    = function(v) end,
    Callback  = function(v) end,
})

Slider:Set(100)
print(Slider.Value)
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Slider"` | Label |
| `Min` | number | `0` | Minimum |
| `Max` | number | `100` | Maximum |
| `Default` | number | `50` | Starting value |
| `Increment` | number | `1` | Snap step |
| `ValueName` | string | `""` | Suffix after number |
| `Color` | Color3 | Green | Fill color |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Persist |
| `OnLoad` | function | `nil` | Called after config load |
| `Callback` | function | `function()end` | Called on change |

| Returns | |
|---|---|
| `:Set(number)` | Set value |
| `.Value` | Current value |

---

### Dropdown

```lua
-- Single select
local DD = Tab:AddDropdown({
    Name            = "Mode",
    Options         = {"Easy", "Normal", "Hard", "Debug"},
    Default         = "Normal",
    DisabledOptions = {"Debug"},
    IsMulti         = false,
    Flag            = "mode",
    Save            = true,
    OnLoad          = function(v) end,
    Callback        = function(v) print(v) end,
})

-- Multi select
local Multi = Tab:AddDropdown({
    Name     = "Features",
    Options  = {"ESP", "Aimbot", "Speed", "Fly"},
    IsMulti  = true,
    Callback = function(tbl)
        for k in pairs(tbl) do print(k) end
    end,
})

DD:Set("Hard")
Multi:Set({"ESP", "Fly"})
DD:Refresh({"Easy","Normal"}, true)
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Dropdown"` | Label |
| `Options` | table | `{}` | Option strings |
| `Default` | string | `""` | Pre-selected (single mode) |
| `DisabledOptions` | table | `{}` | Greyed-out, unclickable options |
| `IsMulti` | bool | `false` | Multi-select mode |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Persist |
| `OnLoad` | function | `nil` | After config load |
| `Callback` | function | `function()end` | On change |

**Single value:** `string`. **Multi value:** `{ [option] = true }` dictionary.

| Returns | |
|---|---|
| `:Set(value)` | String for single, array for multi |
| `:Refresh(options, deleteOld)` | Replace or append options |

---

### Bind

```lua
local Bind = Tab:AddBind({
    Name     = "Toggle Fly",
    Default  = Enum.KeyCode.F,
    Hold     = false,
    Flag     = "flyBind",
    Save     = true,
    Callback = function() end,
    -- Hold mode: Callback = function(holding) end
})

Bind:Set(Enum.KeyCode.G)
print(Bind.Value)  -- "G"
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Bind"` | Label |
| `Default` | KeyCode/UIT | `Unknown` | Default key |
| `Hold` | bool | `false` | Fire on hold start and release |
| `Flag` | string | `nil` | Config key |
| `Save` | bool | `false` | Persist |
| `Callback` | function | `function()end` | On press (or hold/release) |

**Blacklisted keys:** WASD, arrows, Slash, Tab, Backspace, Escape, Unknown.

| Returns | |
|---|---|
| `:Set(key)` | Set key |
| `.Value` | Current key name |
| `.Binding` | `true` while awaiting input |

---

### Textbox

```lua
local TB = Tab:AddTextbox({
    Name          = "Player Name",
    Default       = "",
    TextDisappear = false,
    Callback      = function(text) end,
})

TB:Set("Roblox")
print(TB:Get())
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Textbox"` | Label |
| `Default` | string | `""` | Pre-filled text |
| `TextDisappear` | bool | `false` | Clear on focus lost |
| `Callback` | function | `function()end` | On focus lost |

| Returns | |
|---|---|
| `:Set(text)` | Set text |
| `:Get()` | Get current text |

---

### Colorpicker

```lua
local CP = Tab:AddColorpicker({
    Name     = "ESP Color",
    Default  = Color3.fromRGB(255, 50, 50),
    Flag     = "espColor",
    Save     = true,
    OnLoad   = function(c) end,
    Callback = function(c) end,
})

CP:Set(Color3.fromRGB(0, 255, 100))
print(CP.Value)
```

Supports mouse and touch drag. Left panel = saturation/value, right strip = hue.

| Returns | |
|---|---|
| `:Set(Color3)` | Set color |
| `.Value` | Current `Color3` |

---

### Separator

A horizontal divider. With a label the line breaks around the text.

```lua
local S1 = Tab:AddSeparator({})
local S2 = Tab:AddSeparator({ Name = "Advanced" })
S2:Set("Expert Only")
```

Separators always **break** the `ConnectedElements` chain — elements above and below a separator are in separate groups.

| Returns | |
|---|---|
| `:Set(text)` | Update label |

---

### ProgressBar

```lua
local Bar = Tab:AddProgressBar({
    Name    = "Loading",
    Steps   = { "Connecting", "Fetching", "Applying", "Done" },
    Default = 1,
})

Tab:AddButton({ Name = "Next →",  Callback = function() Bar:SetStep(Bar.Value + 1) end })
Tab:AddButton({ Name = "← Prev",  Callback = function() Bar:SetStep(Bar.Value - 1) end })
Tab:AddButton({ Name = "Finish",  Callback = function() Bar:SetStep(4) end })

Bar:SetName("Installing")
```

The fill bar color automatically matches the current theme's accent (`Stroke`) color.

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `""` | Title (required for display) |
| `Steps` | table | `{}` | Step name strings |
| `Default` | number | `1` | Starting step (1-based) |

| Returns | |
|---|---|
| `:SetStep(n)` | Animate to step n |
| `:SetName(text)` | Update title |
| `.Value` | Current step index |

---

### ThemeSwitcher

```lua
Tab:AddThemeSwitcher()
```

Auto-populated dropdown of all themes (built-in + custom). Switches the UI live. No config needed.

---

### Section

```lua
local Sec = Tab:AddSection({ Name = "Visuals" })
Sec:AddToggle({ Name = "ESP", Callback = function(v) end })
Sec:AddColorpicker({ Name = "ESP Color", Callback = function(c) end })
```

All element methods available inside a section. Sections participate in `ConnectedElements` independently (their own chain).

---

## Notifications

```lua
local n = unknown:MakeNotification({
    Name    = "Done",
    Content = "Operation completed.",
    Image   = "rbxassetid://4384403532",
    Time    = 5,
    Type    = "Success",
})

n:Close()    -- dismiss early
n:Dismiss()  -- alias
```

| Option | Type | Default | Description |
|---|---|---|---|
| `Name` | string | `"Notification"` | Bold title |
| `Content` | string | `"Test"` | Body text (word-wrapped) |
| `Image` | string | built-in | Icon asset ID |
| `Time` | number | `15` | Auto-dismiss after N seconds |
| `Type` | string | `"Info"` | Accent color type |

### Types

| Type | Left border color | Use for |
|---|---|---|
| `"Info"` | Blue `(0,120,255)` | General |
| `"Success"` | Green `(0,180,80)` | Completed |
| `"Warning"` | Orange `(255,160,0)` | Caution |
| `"Error"` | Red `(220,50,50)` | Failure |

---

## Themes

### Built-in themes

| Name | Style |
|---|---|
| `Default` | Dark grey |
| `Midnight` | Near-black with vivid blue accent |
| `Rose` | Dark wine with crimson accent |
| `Ocean` | Deep navy with cyan accent |
| `Forest` | Dark pine with bright green accent |
| `Ember` | Charcoal with molten orange accent |
| `Slate` | Steel blue-grey |
| `Mocha` | Dark espresso with caramel accent |

Each theme has 7 color keys:

| Key | Used for |
|---|---|
| `Main` | Window background |
| `Second` | Element backgrounds, sidebar |
| `Stroke` | Sidebar dividers, notification strips, progress bar fill |
| `Divider` | ScrollFrame scrollbar |
| `Text` | Primary text, icons |
| `TextDark` | Secondary/dim text |
| `Border` | Element UIStroke outlines (subtle, never vibrant) |

### Custom theme

```lua
unknown.Themes.Neon = {
    Main     = Color3.fromRGB(10, 10, 10),
    Second   = Color3.fromRGB(18, 18, 18),
    Stroke   = Color3.fromRGB(0, 255, 120),   -- vibrant accent
    Divider  = Color3.fromRGB(0, 255, 120),
    Text     = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(0, 200, 100),
    Border   = Color3.fromRGB(15, 40, 25),    -- subtle outline
}
```

All 7 keys required. Appears in `AddThemeSwitcher()` automatically.

### Switching themes

```lua
unknown:MakeWindow({ Theme = "Midnight" })  -- on creation
Window:ChangeTheme("Ocean")                  -- live, no recreation
Tab:AddThemeSwitcher()                       -- user-facing dropdown
```

---

## Config System

### Setup

```lua
local Window = unknown:MakeWindow({
    SaveConfig   = true,
    ConfigFolder = "MyScript",
    ConfigName   = "default",
})
```

### Flag elements

Add `Flag` and `Save = true` to Toggle, Slider, Dropdown, Bind, or Colorpicker:

```lua
Tab:AddToggle({
    Name     = "Feature",
    Flag     = "myFeature",
    Save     = true,
    Callback = function(v) end,
})
```

### OnLoad

Called after config restores a flag's value:

```lua
Tab:AddToggle({
    Flag   = "myFeature",
    Save   = true,
    OnLoad = function(v) print("Restored:", v) end,
    Callback = function(v) end,
})
```

> OnLoad does not fire for flags inside locked tabs until `Tab:SetLocked(false)`.

### Auto-load

```lua
unknown:Init()  -- call after all tabs and elements are created
```

### Reset

```lua
unknown:ResetConfig()  -- calls :Set(Default) on every flagged element
```

---

## Global Methods

| Method | Returns | Description |
|---|---|---|
| `unknown:MakeWindow(config)` | `Window` | Create the main window |
| `unknown:MakeNotification(config)` | `handle` | Show a toast notification |
| `unknown:Init()` | — | Load saved config, fire OnLoad callbacks |
| `unknown:ResetConfig()` | — | Reset all flags to defaults |
| `unknown:Destroy()` | — | Destroy UI and disconnect everything |
| `unknown:IsRunning()` | `bool` | `true` if UI ScreenGui is active |

---

## Full Example

```lua
local unknown = loadstring(game:HttpGetAsync("YOUR_RAW_URL"))()

-- Optional custom theme (add BEFORE MakeWindow)
unknown.Themes.Neon = {
    Main     = Color3.fromRGB(10, 10, 10),
    Second   = Color3.fromRGB(18, 18, 18),
    Stroke   = Color3.fromRGB(0, 255, 120),
    Divider  = Color3.fromRGB(0, 255, 120),
    Text     = Color3.fromRGB(255, 255, 255),
    TextDark = Color3.fromRGB(0, 200, 100),
    Border   = Color3.fromRGB(15, 40, 25),
}

local Window = unknown:MakeWindow({
    Name              = "Unknown Script",
    Theme             = "Midnight",
    DefaultTab        = "Main",
    IntroEnabled      = true,
    IntroText         = "Unknown Script",
    ShowIcon          = false,
    ConnectedElements = true,     -- merge adjacent elements visually
    BetterAnimations  = true,     -- smoother transitions and press effects
    SaveConfig        = true,
    ConfigFolder      = "UnknownScript",
    ConfigName        = "default",
    Transparent       = false,
    Blur              = false,
    MinSize           = Vector2.new(430, 300),
    MaxSize           = Vector2.new(800, 520),
    CloseCallback     = function()
        print("Hidden — RightShift to reopen")
    end,
})

-- ══════════════════════════════════════
--   MAIN TAB
-- ══════════════════════════════════════
local Main = Window:MakeTab({ Name = "Main", Icon = "home" })

Main:AddLabel("Welcome to Unknown Script")
Main:AddParagraph("About", "All settings save automatically. Use the Settings tab to change themes, keybinds, or reset config.")

Main:AddSeparator({ Name = "Player" })

local GodToggle = Main:AddToggle({
    Name     = "God Mode",
    Default  = false,
    Color    = Color3.fromRGB(255, 60, 60),
    Flag     = "godMode",
    Save     = true,
    OnLoad   = function(v) print("[Config] God Mode →", v) end,
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
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
    Callback  = function(v)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = v end
    end,
})

Main:AddSlider({
    Name      = "Jump Power",
    Min       = 0,
    Max       = 200,
    Default   = 50,
    Increment = 5,
    ValueName = "power",
    Flag      = "jumpPower",
    Save      = true,
    Callback  = function(v)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = v end
    end,
})

Main:AddSeparator({ Name = "Actions" })

Main:AddButton({
    Name     = "Teleport to Spawn",
    Callback = function()
        local root = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then root.CFrame = CFrame.new(0, 5, 0) end
    end,
})

Main:AddButton({
    Name     = "Respawn",
    Callback = function()
        game.Players.LocalPlayer:LoadCharacter()
    end,
})

local LockedBtn = Main:AddButton({
    Name     = "Admin Only",
    Locked   = true,
    Callback = function() print("Admin action!") end,
})

Main:AddSeparator({})

local NameBox = Main:AddTextbox({
    Name          = "Chat Message",
    Default       = "",
    TextDisappear = true,
    Callback      = function(text)
        if #text > 0 then
            game.Players.LocalPlayer:Chat(text)
        end
    end,
})

-- ══════════════════════════════════════
--   COMBAT TAB
-- ══════════════════════════════════════
local Combat = Window:MakeTab({ Name = "Combat", Icon = "sword" })

local AimbotSec = Combat:AddSection({ Name = "Aimbot" })

AimbotSec:AddToggle({
    Name = "Aimbot", Default = false, Flag = "aimbot", Save = true,
    Callback = function(v) print("Aimbot:", v) end,
})

AimbotSec:AddSlider({
    Name = "FOV", Min = 10, Max = 500, Default = 120, Increment = 5,
    ValueName = "px", Flag = "aimbotFOV", Save = true,
    Callback = function(v) print("FOV:", v) end,
})

AimbotSec:AddDropdown({
    Name = "Aim Part",
    Options = { "Head", "Torso", "HumanoidRootPart" },
    Default = "Head",
    Flag = "aimPart", Save = true,
    Callback = function(v) print("Aiming:", v) end,
})

local ESPSec = Combat:AddSection({ Name = "ESP" })

ESPSec:AddToggle({
    Name = "ESP", Default = false, Flag = "esp", Save = true,
    Callback = function(v) print("ESP:", v) end,
})

ESPSec:AddColorpicker({
    Name = "ESP Color", Default = Color3.fromRGB(255, 50, 50),
    Flag = "espColor", Save = true,
    OnLoad = function(c) print("[Config] ESP color loaded") end,
    Callback = function(c) print("ESP color:", c) end,
})

ESPSec:AddDropdown({
    Name            = "Show Info",
    Options         = { "Name", "Health", "Distance", "Weapon", "Debug" },
    IsMulti         = true,
    DisabledOptions = { "Debug" },
    Callback        = function(tbl)
        for k in pairs(tbl) do print("Showing:", k) end
    end,
})

-- ══════════════════════════════════════
--   NOTIFICATIONS TAB
-- ══════════════════════════════════════
local Notifs = Window:MakeTab({ Name = "Notifications", Icon = "bell" })

Notifs:AddLabel("Tap a button to preview each type.")
Notifs:AddSeparator({ Name = "Types" })

Notifs:AddButton({
    Name = "Info",
    Callback = function()
        unknown:MakeNotification({ Name = "Info", Content = "Informational message.", Time = 4, Type = "Info" })
    end,
})

Notifs:AddButton({
    Name = "Success",
    Callback = function()
        unknown:MakeNotification({ Name = "Success!", Content = "Operation completed.", Time = 4, Type = "Success" })
    end,
})

Notifs:AddButton({
    Name = "Warning",
    Callback = function()
        unknown:MakeNotification({ Name = "Warning", Content = "Something may not work.", Time = 4, Type = "Warning" })
    end,
})

Notifs:AddButton({
    Name = "Error (auto-closes in 2s)",
    Callback = function()
        local n = unknown:MakeNotification({
            Name = "Error", Content = "Something went wrong.", Time = 10, Type = "Error"
        })
        task.delay(2, function() n:Dismiss() end)
    end,
})

-- ══════════════════════════════════════
--   PROGRESS BAR TAB
-- ══════════════════════════════════════
local Progress = Window:MakeTab({ Name = "Progress", Icon = "loader" })

Progress:AddLabel("Step through the progress bar with the buttons below.")

local Bar = Progress:AddProgressBar({
    Name    = "Loading Assets",
    Steps   = { "Connecting", "Loading textures", "Building world", "Spawning entities", "Done!" },
    Default = 1,
})

Progress:AddSeparator({ Name = "Controls" })

Progress:AddButton({
    Name = "Next Step →",
    Callback = function()
        if Bar.Value < 5 then Bar:SetStep(Bar.Value + 1) end
    end,
})

Progress:AddButton({
    Name = "← Prev Step",
    Callback = function()
        if Bar.Value > 1 then Bar:SetStep(Bar.Value - 1) end
    end,
})

Progress:AddButton({
    Name = "Jump to Done",
    Callback = function()
        Bar:SetStep(5)
        unknown:MakeNotification({ Name = "Complete", Content = "All steps finished!", Time = 3, Type = "Success" })
    end,
})

Progress:AddButton({
    Name = "Reset",
    Callback = function()
        Bar:SetStep(1)
        Bar:SetName("Loading Assets")
    end,
})

Progress:AddButton({
    Name = "Rename Bar",
    Callback = function()
        Bar:SetName("Step " .. Bar.Value .. " of 5")
    end,
})

-- ══════════════════════════════════════
--   SETTINGS TAB
-- ══════════════════════════════════════
local Settings = Window:MakeTab({ Name = "Settings", Icon = "settings" })

Settings:AddThemeSwitcher()
Settings:AddSeparator({ Name = "Keybinds" })

Settings:AddBind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Hold     = false,
    Flag     = "uiBind",
    Save     = true,
    Callback = function() print("UI bind triggered") end,
})

Settings:AddBind({
    Name    = "Sprint (Hold)",
    Default = Enum.KeyCode.LeftShift,
    Hold    = true,
    Flag    = "sprintBind",
    Save    = true,
    Callback = function(holding)
        local hum = game.Players.LocalPlayer.Character
            and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = holding and 50 or SpeedSlider.Value
        end
    end,
})

Settings:AddSeparator({ Name = "Display" })

Settings:AddButton({
    Name = "Switch to Ocean Theme",
    Callback = function()
        Window:ChangeTheme("Ocean")
    end,
})

Settings:AddButton({
    Name = "Toggle Blur",
    Callback = function()
        Window:SetBlur(not game:GetService("Lighting"):FindFirstChild("UnknownUIBlur"))
    end,
})

Settings:AddSeparator({ Name = "Config" })

Settings:AddButton({
    Name = "Reset All Settings",
    Callback = function()
        unknown:ResetConfig()
        unknown:MakeNotification({ Name = "Reset", Content = "All settings restored.", Time = 3, Type = "Info" })
    end,
})

-- ══════════════════════════════════════
--   LOCKED TAB EXAMPLE
-- ══════════════════════════════════════
local Admin = Window:MakeTab({ Name = "Admin", Icon = "shield", Locked = true })

Admin:AddToggle({
    Name = "Kill All", Flag = "killAll", Save = false,
    Callback = function(v) print("Kill all:", v) end,
})

Admin:AddButton({
    Name = "Shutdown Server",
    Callback = function() print("Shutdown!") end,
})

-- Unlock Admin from Settings
Settings:AddButton({
    Name = "Unlock Admin Tab",
    Callback = function()
        Admin:SetLocked(false)
        LockedBtn:ButtonLocked(false)
        unknown:MakeNotification({ Name = "Unlocked", Content = "Admin tab is now accessible.", Time = 3, Type = "Success" })
    end,
})

-- ══════════════════════════════════════
--   INIT
-- ══════════════════════════════════════
unknown:Init()
```
