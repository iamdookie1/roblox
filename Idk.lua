local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- URLs
local DICT_URL = "https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt"
local DICT_URL_BACKUP = "https://raw.githubusercontent.com/raun/Scrabble/master/words.txt"
local BAD_WORDS_URL_1 = "https://raw.githubusercontent.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/en"
local BAD_WORDS_URL_2 = "https://raw.githubusercontent.com/RobertJGabriel/Google-profanity-words/master/list.txt"

-- Trap Words Injection
local TRAP_WORDS = [[
ingannation
yangtze
yangs
qaid
qat
qi
za
]]

-- Data Storage
local dictionary = {}
local index = {}
local blacklist = {}

-- State Flags
local isDictionaryReady = false
local isReloading = false

-- Forward declaration
local updateStatusLabel

-- Words per frame for processing
local WORDS_PER_FRAME = 8000

-- Theme Configuration
local themes = {
	Dark = {
		primary = Color3.fromRGB(15, 15, 15),
		secondary = Color3.fromRGB(25, 25, 25),
		accent = Color3.fromRGB(60, 60, 80),
		text = Color3.fromRGB(230, 230, 230),
		highlight = Color3.fromRGB(80, 255, 120),
		gradient1 = Color3.fromRGB(35, 35, 45),
		gradient2 = Color3.fromRGB(15, 15, 20)
	},
	Blue = {
		primary = Color3.fromRGB(10, 20, 35),
		secondary = Color3.fromRGB(20, 35, 55),
		accent = Color3.fromRGB(40, 80, 140),
		text = Color3.fromRGB(220, 235, 255),
		highlight = Color3.fromRGB(100, 180, 255),
		gradient1 = Color3.fromRGB(25, 45, 75),
		gradient2 = Color3.fromRGB(15, 25, 45)
	},
	Purple = {
		primary = Color3.fromRGB(20, 10, 30),
		secondary = Color3.fromRGB(35, 20, 50),
		accent = Color3.fromRGB(80, 40, 120),
		text = Color3.fromRGB(240, 220, 255),
		highlight = Color3.fromRGB(180, 100, 255),
		gradient1 = Color3.fromRGB(50, 30, 70),
		gradient2 = Color3.fromRGB(25, 15, 40)
	},
	Green = {
		primary = Color3.fromRGB(10, 25, 15),
		secondary = Color3.fromRGB(20, 40, 25),
		accent = Color3.fromRGB(40, 100, 60),
		text = Color3.fromRGB(220, 255, 230),
		highlight = Color3.fromRGB(100, 255, 150),
		gradient1 = Color3.fromRGB(30, 60, 40),
		gradient2 = Color3.fromRGB(15, 35, 20)
	},
	Red = {
		primary = Color3.fromRGB(30, 10, 10),
		secondary = Color3.fromRGB(45, 20, 20),
		accent = Color3.fromRGB(100, 40, 40),
		text = Color3.fromRGB(255, 220, 220),
		highlight = Color3.fromRGB(255, 100, 100),
		gradient1 = Color3.fromRGB(60, 30, 30),
		gradient2 = Color3.fromRGB(35, 15, 15)
	}
}

-- Fetching Data Helper with retry and timeout
local function fetchData(url)
	local maxRetries = 2
	
	for attempt = 1, maxRetries do
		local success, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		if success and res and #res > 100 then
			return res
		end
		if attempt < maxRetries then
			task.wait(0.5)
		end
	end
	warn("Failed to load URL after retries: " .. url)
	return ""
end

-- ==========================================
-- DICTIONARY LOADING LOGIC (OPTIMIZED)
-- ==========================================

local function buildDictionaryStructure(dText1, dText2, bText1, bText2)
	dictionary = {}
	index = {}
	blacklist = {}

	local maxPerFrame = tonumber(WORDS_PER_FRAME) or 8000
	local processedCount = 0
	local seen = {}

	local function addToBlacklist(str)
		if not str or #str == 0 then return end
		for word in str:gmatch("[^\r\n]+") do
			local w = word:lower():gsub("%s+", "")
			if #w > 0 then
				blacklist[w] = true
			end
		end
	end

	addToBlacklist(bText1)
	addToBlacklist(bText2)

	local function processDict(str, label)
		if not str or #str == 0 then return end

		local countThisFrame = 0

		for word in str:gmatch("[^\r\n]+") do
			processedCount = processedCount + 1
			countThisFrame = countThisFrame + 1

			local w = word:lower():gsub("%s+", "")
			if #w > 0 and not blacklist[w] and not seen[w] then
				seen[w] = true

				local f = w:sub(1, 1)
				local bucket = index[f]
				if not bucket then
					bucket = {}
					index[f] = bucket
				end

				bucket[#bucket + 1] = w
				dictionary[#dictionary + 1] = w
			end

			if countThisFrame >= maxPerFrame then
				countThisFrame = 0

				if updateStatusLabel then
					updateStatusLabel(label .. " (" .. math.floor(processedCount / 1000) .. "k)")
				end

				RunService.Heartbeat:Wait()
			end
		end
	end

	processDict(dText1, "Processing Main")
	processDict(dText2, "Processing Backup")
	processDict(TRAP_WORDS, "Finalizing")
end

local loadConfigFromFile  -- Forward declaration

local function loadDictionaries()
	if isReloading then return end
	isReloading = true
	isDictionaryReady = false

	if updateStatusLabel then updateStatusLabel("Downloading...") end

	task.spawn(function()
		local dt1, dt2, bt1, bt2
		local results = {}
		
		task.spawn(function() results[1] = fetchData(DICT_URL) end)
		task.spawn(function() results[2] = fetchData(DICT_URL_BACKUP) end)
		task.spawn(function() results[3] = fetchData(BAD_WORDS_URL_1) end)
		task.spawn(function() results[4] = fetchData(BAD_WORDS_URL_2) end)
		
		local maxWait = 10
		local elapsed = 0
		while (not results[1] or not results[2] or not results[3] or not results[4]) and elapsed < maxWait do
			task.wait(0.1)
			elapsed = elapsed + 0.1
		end
		
		dt1 = results[1] or ""
		dt2 = results[2] or ""
		bt1 = results[3] or ""
		bt2 = results[4] or ""
		
		if not dt1 or #dt1 < 100 then
			warn("Main Dictionary failed to load or is empty.")
			dt1 = ""
		end
		if not dt2 or #dt2 < 100 then
			warn("Backup Dictionary failed to load or is empty.")
			dt2 = ""
		end

		if dt1 == "" and dt2 == "" then
			if updateStatusLabel then updateStatusLabel("FAILED TO LOAD") end
			warn("CRITICAL: No dictionary sources loaded.")
			dt1 = "apple\nbanana\ncat\ndog\nelephant\nfish\ngrape\nhat\nice\njump\nkite\nlion\nmoon\nno\norange"
		end
		
		buildDictionaryStructure(dt1, dt2, bt1, bt2)
		
		isDictionaryReady = true
		isReloading = false
		if updateStatusLabel then updateStatusLabel("Ready") end
		
		-- Auto-load config after dictionary is ready
		if config and config.autoLoadConfig then
			task.wait(0.3)
			if loadConfigFromFile then
				loadConfigFromFile(true)  -- Silent load
			end
		end
	end)
end

local function addCustomWords(str)
	for w in str:gmatch("[^,%s]+") do
		w = w:lower()
		if #w > 0 and not blacklist[w] then
			dictionary[#dictionary+1] = w
			local f = w:sub(1,1)
			index[f] = index[f] or {}
			if not table.find(index[f], w) then
				table.insert(index[f], w)
			end
		end
	end
end

local function sanitizeEndingInput(s)
	if not s then return "" end
	s = s:lower():gsub("%s+", "")
	if #s == 0 then return "" end
	if #s > 2 then s = s:sub(-2) end
	if s:match("^[a-z]+$") then return s end
	return ""
end

-- ==========================================
-- CONFIG & MATCHING
-- ==========================================

local config = {
	typingDelay = 0.15,
	startDelay = 0.5,
	randomizeTyping = false,
	autoDone = true,
	autoDoneMin = 0.1,
	autoDoneMax = 0.2,
	antiDupe = false,
	instantType = false,
	autoType = false,
	autoTypeV2 = false,
	autoTypeV2Min = 0.05,
	autoTypeV2Max = 0.2,
	
	-- Enhanced Human Typing Settings
	humanTyping = false,
	humanBaseSpeed = 0.15,
	humanVariation = 0.10,
	humanPauseChance = 0.12,
	humanPauseMin = 0.3,
	humanPauseMax = 0.8,
	humanBurstChance = 0.15,
	humanBurstSpeed = 0.6,
	humanFatigue = false,
	humanFatigueRate = 0.02,
	
	minWordLength = 3,
	endingIn = "",
	theme = "Dark",
	transparency = 0.05,
	acrylic = false,
	autoLoadConfig = false
}

local usedWords = {}
local typedCount = 0
local isTypingInProgress = false
local autoTypePrefixTime = 0
local lastV2TypeTimes = {}

local function getMatches(prefix, anti, used, minLen, ending)
	if not isDictionaryReady then return {} end

	prefix = prefix:lower():gsub("%s+", "")
	if #prefix == 0 then return {} end

	local f = prefix:sub(1,1)
	local list = index[f]

	if not list then return {} end

	local out = {}
	local unique = {}
	local endingProvided = ending and #ending > 0

	for i = 1, #list do
		local w = list[i]
		if (#w >= (minLen or 3)) and w:find(prefix, 1, true) == 1 and w ~= prefix then
			if not unique[w] then
				if not anti or not used[w] then
					if endingProvided then
						if w:sub(-#ending) == ending then
							out[#out+1] = w
							unique[w] = true
						end
					else
						out[#out+1] = w
						unique[w] = true
					end
				end
			end
		end
	end
	return out
end

local function getSuggestion(prefix, longest, anti, used, minLen, ending)
	if not isDictionaryReady then return "Loading...", {} end

	local endingVal = sanitizeEndingInput(ending or "")
	local m = {}
	if endingVal ~= "" then
		m = getMatches(prefix, anti, used, minLen, endingVal)
		if #m == 0 then
			m = getMatches(prefix, anti, used, minLen, "")
		end
	else
		m = getMatches(prefix, anti, used, minLen, "")
	end
	
	table.sort(m, function(a,b)
		if #a == #b then return a < b end
		if longest then return #a > #b else return #a < #b end
	end)
	
	if #m == 0 then return "No Match", {} end
	return m[1], m
end

local function getHRP()
	local char = player.Character or player.CharacterAdded:Wait()
	return char:WaitForChild("HumanoidRootPart")
end

local function getModelPosition(model)
	if model.PrimaryPart then return model.PrimaryPart.Position end
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("BasePart") then return v.Position end
	end
end

local function findBillboardModels()
	local out = {}
	local folder = workspace:FindFirstChild("Tables")
	if folder and folder:GetChildren() then
		for i = 1, #folder:GetChildren() do
			local c = folder:GetChildren()[i]
			if c and c:IsA("Model") and c:FindFirstChild("Billboard") then
				out[#out+1] = c
			end
		end
		if #out > 0 then return out end
	end
	for i = 1, #workspace:GetChildren() do
		local c = workspace:GetChildren()[i]
		if c and c:IsA("Model") and c:FindFirstChild("Billboard") then
			out[#out+1] = c
		end
	end
	if #out > 0 then return out end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc.Name == "Billboard" and desc:IsA("Model") and desc.Parent and desc.Parent:IsA("Model") then
			out[#out+1] = desc.Parent
		elseif desc.Name == "Billboard" and (not desc:IsA("Model")) and desc.Parent and desc.Parent:IsA("Model") then
			if not table.find(out, desc.Parent) then
				out[#out+1] = desc.Parent
			end
		end
	end
	return out
end

local function getClosestTable()
	local ok, hrp = pcall(getHRP)
	if not ok or not hrp then return nil end
	local models = findBillboardModels()
	if not models or #models == 0 then return nil end
	local best, dist = nil, math.huge
	for i = 1, #models do
		local t = models[i]
		local pos = getModelPosition(t)
		if pos then
			local d = (pos - hrp.Position).Magnitude
			if d < dist then
				dist = d
				best = t
			end
		end
	end
	return best
end

-- ==========================================
-- GUI CREATION (IMPROVED & SMALLER)
-- ==========================================

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Name = "WordHelperUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 380)
frame.Position = UDim2.new(0.72, 0, 0.12, 0)
frame.BackgroundColor3 = themes[config.theme].primary
frame.BackgroundTransparency = config.transparency
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 14)

local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = themes[config.theme].accent
frameStroke.Thickness = 2
frameStroke.Transparency = 0.3

local blur = Instance.new("UIGradient", frame)
blur.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, themes[config.theme].gradient1),
	ColorSequenceKeypoint.new(1, themes[config.theme].gradient2)
}
blur.Rotation = 45

-- Acrylic effect (only blurs UI, not full screen)
local acrylicFrame
if config.acrylic then
	acrylicFrame = Instance.new("Frame", frame)
	acrylicFrame.Size = UDim2.new(1, 0, 1, 0)
	acrylicFrame.Position = UDim2.new(0, 0, 0, 0)
	acrylicFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	acrylicFrame.BackgroundTransparency = 0.92
	acrylicFrame.BorderSizePixel = 0
	acrylicFrame.ZIndex = 1
	
	local acrylicCorner = Instance.new("UICorner", acrylicFrame)
	acrylicCorner.CornerRadius = UDim.new(0, 14)
	
	local acrylicBlur = Instance.new("BlurEffect", acrylicFrame)
	acrylicBlur.Size = 8
end

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 2

local function newButton(parent, text, size)
	local b = Instance.new("TextButton", parent)
	b.Text = text
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.BackgroundColor3 = themes[config.theme].secondary
	b.AutoButtonColor = false
	b.TextColor3 = themes[config.theme].text
	b.BorderSizePixel = 0
	b.Size = size or UDim2.new(1, 0, 0, 26)
	b.ZIndex = 2
	
	local corner = Instance.new("UICorner", b)
	corner.CornerRadius = UDim.new(0, 7)
	
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = themes[config.theme].accent
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = themes[config.theme].accent}):Play()
	end)
	
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = themes[config.theme].secondary}):Play()
	end)
	
	return b
end

local navButtons = {}
local navButtonNames = {"Main", "Settings", "Human", "Config", "Info"}
local buttonWidth = 0.19

for i, name in ipairs(navButtonNames) do
	local btn = newButton(topBar, name)
	btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
	btn.Position = UDim2.new((i-1) * (buttonWidth + 0.005) + 0.005, 0, 0, 0)
	btn.TextSize = 10
	navButtons[name] = btn
end

local contentContainer = Instance.new("Frame", frame)
contentContainer.Size = UDim2.new(1, 0, 1, -36)
contentContainer.Position = UDim2.new(0, 0, 0, 36)
contentContainer.BackgroundTransparency = 1
contentContainer.ZIndex = 2

local function createPage()
	local pg = Instance.new("ScrollingFrame", contentContainer)
	pg.Size = UDim2.new(1, -6, 1, -6)
	pg.Position = UDim2.new(0, 3, 0, 3)
	pg.BackgroundTransparency = 1
	pg.ScrollBarThickness = 3
	pg.ScrollBarImageColor3 = themes[config.theme].accent
	pg.CanvasSize = UDim2.new(0, 0, 0, 0)
	pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pg.Visible = false
	pg.BorderSizePixel = 0
	pg.ZIndex = 2
	
	local layout = Instance.new("UIListLayout", pg)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)
	
	local pad = Instance.new("UIPadding", pg)
	pad.PaddingLeft = UDim.new(0, 5)
	pad.PaddingRight = UDim.new(0, 5)
	pad.PaddingTop = UDim.new(0, 5)
	
	return pg
end

local mainPage = createPage()
mainPage.Visible = true
local settingsPage = createPage()
local humanPage = createPage()
local configPage = createPage()
local infoPage = createPage()

local function addSpacer(parent, height)
	local f = Instance.new("Frame", parent)
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, height or 5)
	return f
end

local function newLabel(parent, text, size)
	local l = Instance.new("TextLabel", parent)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = themes[config.theme].text
	l.TextSize = size
	l.Size = UDim2.new(1, 0, 0, size + 10)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = 2
	return l
end

local function newBox(parent, text, height)
	local b = Instance.new("TextBox", parent)
	b.BackgroundColor3 = themes[config.theme].secondary
	b.TextColor3 = themes[config.theme].text
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 12
	b.Text = text or ""
	b.Size = UDim2.new(1, 0, 0, height or 26)
	b.BorderSizePixel = 0
	b.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	b.ZIndex = 2
	
	local corner = Instance.new("UICorner", b)
	corner.CornerRadius = UDim.new(0, 7)
	
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = themes[config.theme].accent
	stroke.Thickness = 1
	stroke.Transparency = 0.6
	
	return b
end

-- ==========================================
-- MAIN PAGE UI
-- ==========================================

local title = newLabel(mainPage, "Word Helper Pro", 15)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextColor3 = themes[config.theme].highlight

local wordLabel = Instance.new("TextLabel", mainPage)
wordLabel.Size = UDim2.new(1, 0, 0, 42)
wordLabel.BackgroundColor3 = themes[config.theme].secondary
wordLabel.TextColor3 = themes[config.theme].highlight
wordLabel.Font = Enum.Font.GothamBold
wordLabel.TextSize = 17
wordLabel.Text = "Waiting..."
wordLabel.BorderSizePixel = 0
wordLabel.ZIndex = 2

local wordCorner = Instance.new("UICorner", wordLabel)
wordCorner.CornerRadius = UDim.new(0, 9)

local wordStroke = Instance.new("UIStroke", wordLabel)
wordStroke.Color = themes[config.theme].accent
wordStroke.Thickness = 2
wordStroke.Transparency = 0.4

updateStatusLabel = function(txt)
	wordLabel.Text = txt
end

local nextButton = newButton(mainPage, "Next Word")
nextButton.Size = UDim2.new(1, 0, 0, 30)

local row1 = Instance.new("Frame", mainPage)
row1.Size = UDim2.new(1, 0, 0, 30)
row1.BackgroundTransparency = 1
row1.ZIndex = 2
local typeButton = newButton(row1, "Type")
typeButton.Size = UDim2.new(0.48, 0, 1, 0)
local autoTypeButton = newButton(row1, "Auto V1: Off")
autoTypeButton.Position = UDim2.new(0.52, 0, 0, 0)
autoTypeButton.Size = UDim2.new(0.48, 0, 1, 0)

local row2 = Instance.new("Frame", mainPage)
row2.Size = UDim2.new(1, 0, 0, 30)
row2.BackgroundTransparency = 1
row2.ZIndex = 2
local copyButton = newButton(row2, "Copy")
copyButton.Size = UDim2.new(0.48, 0, 1, 0)
local forceFindButton = newButton(row2, "Force Find")
forceFindButton.Position = UDim2.new(0.52, 0, 0, 0)
forceFindButton.Size = UDim2.new(0.48, 0, 1, 0)

local row3 = Instance.new("Frame", mainPage)
row3.Size = UDim2.new(1, 0, 0, 30)
row3.BackgroundTransparency = 1
row3.ZIndex = 2
local longestLabel = newLabel(row3, "Longest First", 12)
longestLabel.Size = UDim2.new(0.5, 0, 1, 0)
longestLabel.TextYAlignment = Enum.TextYAlignment.Center
local longestToggle = newButton(row3, "Off")
longestToggle.Size = UDim2.new(0.48, 0, 1, 0)
longestToggle.Position = UDim2.new(0.52, 0, 0, 0)

local autoTypeV2Row = Instance.new("Frame", mainPage)
autoTypeV2Row.Size = UDim2.new(1, 0, 0, 30)
autoTypeV2Row.BackgroundTransparency = 1
autoTypeV2Row.ZIndex = 2
local autoTypeV2Label = newLabel(autoTypeV2Row, "Auto Type V2", 12)
autoTypeV2Label.Size = UDim2.new(0.5, 0, 1, 0)
autoTypeV2Label.TextYAlignment = Enum.TextYAlignment.Center
local autoTypeV2Toggle = newButton(autoTypeV2Row, "Off")
autoTypeV2Toggle.Size = UDim2.new(0.48, 0, 1, 0)
autoTypeV2Toggle.Position = UDim2.new(0.52, 0, 0, 0)

local v2MinMaxRow = Instance.new("Frame", mainPage)
v2MinMaxRow.Size = UDim2.new(1, 0, 0, 30)
v2MinMaxRow.BackgroundTransparency = 1
v2MinMaxRow.Visible = false
v2MinMaxRow.ZIndex = 2
local v2mml = newLabel(v2MinMaxRow, "V2 Min/Max", 11)
v2mml.Size = UDim2.new(0.36, 0, 1, 0)
v2mml.TextYAlignment = Enum.TextYAlignment.Center
local v2MinInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Min), 30)
v2MinInput.Size = UDim2.new(0.29, 0, 1, 0)
v2MinInput.Position = UDim2.new(0.38, 0, 0, 0)
local v2MaxInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Max), 30)
v2MaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v2MaxInput.Position = UDim2.new(0.69, 0, 0, 0)

-- ==========================================
-- SETTINGS PAGE UI
-- ==========================================

local function createSettingRow(parent, name, inputObj)
	local f = Instance.new("Frame", parent)
	f.Size = UDim2.new(1, 0, 0, 30)
	f.BackgroundTransparency = 1
	f.ZIndex = 2

	local l = newLabel(f, name, 11)
	l.Size = UDim2.new(0.52, 0, 1, 0)
	l.TextYAlignment = Enum.TextYAlignment.Center

	inputObj.Parent = f
	inputObj.Size = UDim2.new(0.46, 0, 1, 0)
	inputObj.Position = UDim2.new(0.54, 0, 0, 0)
	return f
end

createSettingRow(settingsPage, "Typing Delay", newBox(nil, tostring(config.typingDelay)))
local delayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "Start Delay", newBox(nil, tostring(config.startDelay)))
local startDelayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

local randomRow = Instance.new("Frame", settingsPage)
randomRow.Size = UDim2.new(1, 0, 0, 30)
randomRow.BackgroundTransparency = 1
randomRow.ZIndex = 2
local rl = newLabel(randomRow, "Random Speed", 11)
rl.Size = UDim2.new(0.52, 0, 1, 0)
rl.TextYAlignment = Enum.TextYAlignment.Center
local randomToggleButton = newButton(randomRow, "Off")
randomToggleButton.Size = UDim2.new(0.46, 0, 1, 0)
randomToggleButton.Position = UDim2.new(0.54, 0, 0, 0)

local autoDoneRow = Instance.new("Frame", settingsPage)
autoDoneRow.Size = UDim2.new(1, 0, 0, 30)
autoDoneRow.BackgroundTransparency = 1
autoDoneRow.ZIndex = 2
local adl = newLabel(autoDoneRow, "Auto Done", 11)
adl.Size = UDim2.new(0.52, 0, 1, 0)
adl.TextYAlignment = Enum.TextYAlignment.Center
local autoDoneButton = newButton(autoDoneRow, "On")
autoDoneButton.Size = UDim2.new(0.46, 0, 1, 0)
autoDoneButton.Position = UDim2.new(0.54, 0, 0, 0)

local minMaxRow = Instance.new("Frame", settingsPage)
minMaxRow.Size = UDim2.new(1, 0, 0, 30)
minMaxRow.BackgroundTransparency = 1
minMaxRow.ZIndex = 2
local mml = newLabel(minMaxRow, "Done Min/Max", 11)
mml.Size = UDim2.new(0.36, 0, 1, 0)
mml.TextYAlignment = Enum.TextYAlignment.Center
local minInput = newBox(minMaxRow, tostring(config.autoDoneMin))
minInput.Size = UDim2.new(0.29, 0, 1, 0)
minInput.Position = UDim2.new(0.38, 0, 0, 0)
local maxInput = newBox(minMaxRow, tostring(config.autoDoneMax))
maxInput.Size = UDim2.new(0.29, 0, 1, 0)
maxInput.Position = UDim2.new(0.69, 0, 0, 0)

local antiDupeRow = Instance.new("Frame", settingsPage)
antiDupeRow.Size = UDim2.new(1, 0, 0, 30)
antiDupeRow.BackgroundTransparency = 1
antiDupeRow.ZIndex = 2
local adl2 = newLabel(antiDupeRow, "Anti Dupe", 11)
adl2.Size = UDim2.new(0.52, 0, 1, 0)
adl2.TextYAlignment = Enum.TextYAlignment.Center
local antiDupeToggle = newButton(antiDupeRow, "Off")
antiDupeToggle.Size = UDim2.new(0.46, 0, 1, 0)
antiDupeToggle.Position = UDim2.new(0.54, 0, 0, 0)

createSettingRow(settingsPage, "Min Length", newBox(nil, tostring(config.minWordLength)))
local shortInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

local instantRow = Instance.new("Frame", settingsPage)
instantRow.Size = UDim2.new(1, 0, 0, 30)
instantRow.BackgroundTransparency = 1
instantRow.ZIndex = 2
local il = newLabel(instantRow, "Instant Type", 11)
il.Size = UDim2.new(0.52, 0, 1, 0)
il.TextYAlignment = Enum.TextYAlignment.Center
local instantToggle = newButton(instantRow, "Off")
instantToggle.Size = UDim2.new(0.46, 0, 1, 0)
instantToggle.Position = UDim2.new(0.54, 0, 0, 0)

createSettingRow(settingsPage, "Custom Words", newBox(nil, ""))
local customInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "End In (1-2)", newBox(nil, ""))
local endingInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

addSpacer(settingsPage, 8)

local resetButton = newButton(settingsPage, "Reset Used Words")
resetButton.Size = UDim2.new(1, 0, 0, 30)

-- ==========================================
-- HUMAN TYPING PAGE UI
-- ==========================================

local humanTitle = newLabel(humanPage, "Human Typing Settings", 14)
humanTitle.TextXAlignment = Enum.TextXAlignment.Center
humanTitle.TextColor3 = themes[config.theme].highlight

addSpacer(humanPage, 3)

local humanToggleRow = Instance.new("Frame", humanPage)
humanToggleRow.Size = UDim2.new(1, 0, 0, 30)
humanToggleRow.BackgroundTransparency = 1
humanToggleRow.ZIndex = 2
local humanToggleLabel = newLabel(humanToggleRow, "Enable Human Typing", 12)
humanToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
humanToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
local humanToggle = newButton(humanToggleRow, "Off")
humanToggle.Size = UDim2.new(0.38, 0, 1, 0)
humanToggle.Position = UDim2.new(0.62, 0, 0, 0)

local humanSettingsContainer = Instance.new("Frame", humanPage)
humanSettingsContainer.Size = UDim2.new(1, 0, 0, 10)
humanSettingsContainer.BackgroundTransparency = 1
humanSettingsContainer.Visible = false
humanSettingsContainer.ZIndex = 2
humanSettingsContainer.AutomaticSize = Enum.AutomaticSize.Y

local humanSettingsLayout = Instance.new("UIListLayout", humanSettingsContainer)
humanSettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
humanSettingsLayout.Padding = UDim.new(0, 5)

-- Base Speed
local baseSpeedRow = Instance.new("Frame", humanSettingsContainer)
baseSpeedRow.Size = UDim2.new(1, 0, 0, 30)
baseSpeedRow.BackgroundTransparency = 1
baseSpeedRow.ZIndex = 2
local baseSpeedLabel = newLabel(baseSpeedRow, "Base Speed (s)", 11)
baseSpeedLabel.Size = UDim2.new(0.52, 0, 1, 0)
baseSpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
local baseSpeedInput = newBox(baseSpeedRow, tostring(config.humanBaseSpeed), 30)
baseSpeedInput.Size = UDim2.new(0.46, 0, 1, 0)
baseSpeedInput.Position = UDim2.new(0.54, 0, 0, 0)

-- Variation
local variationRow = Instance.new("Frame", humanSettingsContainer)
variationRow.Size = UDim2.new(1, 0, 0, 30)
variationRow.BackgroundTransparency = 1
variationRow.ZIndex = 2
local variationLabel = newLabel(variationRow, "Speed Variation", 11)
variationLabel.Size = UDim2.new(0.52, 0, 1, 0)
variationLabel.TextYAlignment = Enum.TextYAlignment.Center
local variationInput = newBox(variationRow, tostring(config.humanVariation), 30)
variationInput.Size = UDim2.new(0.46, 0, 1, 0)
variationInput.Position = UDim2.new(0.54, 0, 0, 0)

-- Pause Chance
local pauseChanceRow = Instance.new("Frame", humanSettingsContainer)
pauseChanceRow.Size = UDim2.new(1, 0, 0, 30)
pauseChanceRow.BackgroundTransparency = 1
pauseChanceRow.ZIndex = 2
local pauseChanceLabel = newLabel(pauseChanceRow, "Pause Chance (%)", 11)
pauseChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
pauseChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
local pauseChanceInput = newBox(pauseChanceRow, tostring(config.humanPauseChance * 100), 30)
pauseChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
pauseChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

-- Pause Duration
local pauseDurationRow = Instance.new("Frame", humanSettingsContainer)
pauseDurationRow.Size = UDim2.new(1, 0, 0, 30)
pauseDurationRow.BackgroundTransparency = 1
pauseDurationRow.ZIndex = 2
local pauseDurationLabel = newLabel(pauseDurationRow, "Pause Min/Max", 11)
pauseDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
pauseDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
local pauseMinInput = newBox(pauseDurationRow, tostring(config.humanPauseMin), 30)
pauseMinInput.Size = UDim2.new(0.29, 0, 1, 0)
pauseMinInput.Position = UDim2.new(0.38, 0, 0, 0)
local pauseMaxInput = newBox(pauseDurationRow, tostring(config.humanPauseMax), 30)
pauseMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
pauseMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

-- Burst Chance
local burstChanceRow = Instance.new("Frame", humanSettingsContainer)
burstChanceRow.Size = UDim2.new(1, 0, 0, 30)
burstChanceRow.BackgroundTransparency = 1
burstChanceRow.ZIndex = 2
local burstChanceLabel = newLabel(burstChanceRow, "Burst Chance (%)", 11)
burstChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
burstChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
local burstChanceInput = newBox(burstChanceRow, tostring(config.humanBurstChance * 100), 30)
burstChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
burstChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

-- Burst Speed
local burstSpeedRow = Instance.new("Frame", humanSettingsContainer)
burstSpeedRow.Size = UDim2.new(1, 0, 0, 30)
burstSpeedRow.BackgroundTransparency = 1
burstSpeedRow.ZIndex = 2
local burstSpeedLabel = newLabel(burstSpeedRow, "Burst Multiplier", 11)
burstSpeedLabel.Size = UDim2.new(0.52, 0, 1, 0)
burstSpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
local burstSpeedInput = newBox(burstSpeedRow, tostring(config.humanBurstSpeed), 30)
burstSpeedInput.Size = UDim2.new(0.46, 0, 1, 0)
burstSpeedInput.Position = UDim2.new(0.54, 0, 0, 0)

-- Fatigue
local fatigueRow = Instance.new("Frame", humanSettingsContainer)
fatigueRow.Size = UDim2.new(1, 0, 0, 30)
fatigueRow.BackgroundTransparency = 1
fatigueRow.ZIndex = 2
local fatigueLabel = newLabel(fatigueRow, "Fatigue Effect", 11)
fatigueLabel.Size = UDim2.new(0.52, 0, 1, 0)
fatigueLabel.TextYAlignment = Enum.TextYAlignment.Center
local fatigueToggle = newButton(fatigueRow, config.humanFatigue and "On" or "Off")
fatigueToggle.Size = UDim2.new(0.46, 0, 1, 0)
fatigueToggle.Position = UDim2.new(0.54, 0, 0, 0)

-- Fatigue Rate
local fatigueRateRow = Instance.new("Frame", humanSettingsContainer)
fatigueRateRow.Size = UDim2.new(1, 0, 0, 30)
fatigueRateRow.BackgroundTransparency = 1
fatigueRateRow.Visible = config.humanFatigue
fatigueRateRow.ZIndex = 2
local fatigueRateLabel = newLabel(fatigueRateRow, "Fatigue Rate", 11)
fatigueRateLabel.Size = UDim2.new(0.52, 0, 1, 0)
fatigueRateLabel.TextYAlignment = Enum.TextYAlignment.Center
local fatigueRateInput = newBox(fatigueRateRow, tostring(config.humanFatigueRate), 30)
fatigueRateInput.Size = UDim2.new(0.46, 0, 1, 0)
fatigueRateInput.Position = UDim2.new(0.54, 0, 0, 0)

-- ==========================================
-- CONFIG PAGE UI
-- ==========================================

local configTitle = newLabel(configPage, "Configuration", 14)
configTitle.TextXAlignment = Enum.TextXAlignment.Center
configTitle.TextColor3 = themes[config.theme].highlight

addSpacer(configPage, 4)

local saveRow = Instance.new("Frame", configPage)
saveRow.Size = UDim2.new(1, 0, 0, 30)
saveRow.BackgroundTransparency = 1
saveRow.ZIndex = 2
local saveConfigButton = newButton(saveRow, "Save Config")
saveConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
local loadConfigButton = newButton(saveRow, "Load Config")
loadConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
loadConfigButton.Position = UDim2.new(0.52, 0, 0, 0)

addSpacer(configPage, 4)

local autoLoadRow = Instance.new("Frame", configPage)
autoLoadRow.Size = UDim2.new(1, 0, 0, 30)
autoLoadRow.BackgroundTransparency = 1
autoLoadRow.ZIndex = 2
local autoLoadLabel = newLabel(autoLoadRow, "Auto Load Config", 11)
autoLoadLabel.Size = UDim2.new(0.52, 0, 1, 0)
autoLoadLabel.TextYAlignment = Enum.TextYAlignment.Center
local autoLoadToggle = newButton(autoLoadRow, config.autoLoadConfig and "On" or "Off")
autoLoadToggle.Size = UDim2.new(0.46, 0, 1, 0)
autoLoadToggle.Position = UDim2.new(0.54, 0, 0, 0)

addSpacer(configPage, 8)

local themeLabel = newLabel(configPage, "Theme", 12)
themeLabel.Size = UDim2.new(1, 0, 0, 18)

local themeDropdownFrame = Instance.new("Frame", configPage)
themeDropdownFrame.Size = UDim2.new(1, 0, 0, 30)
themeDropdownFrame.BackgroundColor3 = themes[config.theme].secondary
themeDropdownFrame.BorderSizePixel = 0
themeDropdownFrame.ZIndex = 2

local themeDropdownCorner = Instance.new("UICorner", themeDropdownFrame)
themeDropdownCorner.CornerRadius = UDim.new(0, 7)

local themeDropdownStroke = Instance.new("UIStroke", themeDropdownFrame)
themeDropdownStroke.Color = themes[config.theme].accent
themeDropdownStroke.Thickness = 1
themeDropdownStroke.Transparency = 0.6

local themeDropdownButton = Instance.new("TextButton", themeDropdownFrame)
themeDropdownButton.Size = UDim2.new(1, 0, 1, 0)
themeDropdownButton.BackgroundTransparency = 1
themeDropdownButton.Text = config.theme
themeDropdownButton.TextColor3 = themes[config.theme].text
themeDropdownButton.Font = Enum.Font.GothamSemibold
themeDropdownButton.TextSize = 12
themeDropdownButton.ZIndex = 3

local themeDropdownExpanded = false
local themeDropdownList = Instance.new("ScrollingFrame", gui)
themeDropdownList.Size = UDim2.new(0, 248, 0, 0)
themeDropdownList.Position = themeDropdownFrame.Position
themeDropdownList.BackgroundColor3 = themes[config.theme].secondary
themeDropdownList.BorderSizePixel = 0
themeDropdownList.Visible = false
themeDropdownList.ZIndex = 100
themeDropdownList.ScrollBarThickness = 3

local themeDropdownListCorner = Instance.new("UICorner", themeDropdownList)
themeDropdownListCorner.CornerRadius = UDim.new(0, 7)

local themeDropdownListStroke = Instance.new("UIStroke", themeDropdownList)
themeDropdownListStroke.Color = themes[config.theme].accent
themeDropdownListStroke.Thickness = 1
themeDropdownListStroke.Transparency = 0.6

local themeDropdownLayout = Instance.new("UIListLayout", themeDropdownList)
themeDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeDropdownLayout.Padding = UDim.new(0, 2)

addSpacer(configPage, 4)

local transparencyLabel = newLabel(configPage, "Transparency", 12)
transparencyLabel.Size = UDim2.new(1, 0, 0, 18)

local transparencySliderFrame = Instance.new("Frame", configPage)
transparencySliderFrame.Size = UDim2.new(1, 0, 0, 36)
transparencySliderFrame.BackgroundColor3 = themes[config.theme].secondary
transparencySliderFrame.BorderSizePixel = 0
transparencySliderFrame.ZIndex = 2

local transparencySliderCorner = Instance.new("UICorner", transparencySliderFrame)
transparencySliderCorner.CornerRadius = UDim.new(0, 7)

local transparencySliderStroke = Instance.new("UIStroke", transparencySliderFrame)
transparencySliderStroke.Color = themes[config.theme].accent
transparencySliderStroke.Thickness = 1
transparencySliderStroke.Transparency = 0.6

local transparencySliderBar = Instance.new("Frame", transparencySliderFrame)
transparencySliderBar.Size = UDim2.new(0.85, 0, 0, 5)
transparencySliderBar.Position = UDim2.new(0.075, 0, 0.5, -2.5)
transparencySliderBar.BackgroundColor3 = themes[config.theme].accent
transparencySliderBar.BorderSizePixel = 0
transparencySliderBar.ZIndex = 3

local transparencySliderBarCorner = Instance.new("UICorner", transparencySliderBar)
transparencySliderBarCorner.CornerRadius = UDim.new(1, 0)

local transparencySliderHandle = Instance.new("TextButton", transparencySliderBar)
transparencySliderHandle.Size = UDim2.new(0, 18, 0, 18)
transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -9, 0.5, -9)
transparencySliderHandle.BackgroundColor3 = themes[config.theme].highlight
transparencySliderHandle.BorderSizePixel = 0
transparencySliderHandle.Text = ""
transparencySliderHandle.ZIndex = 4

local transparencySliderHandleCorner = Instance.new("UICorner", transparencySliderHandle)
transparencySliderHandleCorner.CornerRadius = UDim.new(1, 0)

local transparencyValueLabel = newLabel(transparencySliderFrame, string.format("%.2f", config.transparency), 10)
transparencyValueLabel.Size = UDim2.new(1, 0, 1, 0)
transparencyValueLabel.TextXAlignment = Enum.TextXAlignment.Center
transparencyValueLabel.TextYAlignment = Enum.TextYAlignment.Center
transparencyValueLabel.ZIndex = 3

addSpacer(configPage, 4)

local acrylicRow = Instance.new("Frame", configPage)
acrylicRow.Size = UDim2.new(1, 0, 0, 30)
acrylicRow.BackgroundTransparency = 1
acrylicRow.ZIndex = 2
local acrylicLabel = newLabel(acrylicRow, "Acrylic Effect", 11)
acrylicLabel.Size = UDim2.new(0.52, 0, 1, 0)
acrylicLabel.TextYAlignment = Enum.TextYAlignment.Center
local acrylicToggle = newButton(acrylicRow, config.acrylic and "On" or "Off")
acrylicToggle.Size = UDim2.new(0.46, 0, 1, 0)
acrylicToggle.Position = UDim2.new(0.54, 0, 0, 0)

addSpacer(configPage, 8)

local reloadDictButton = newButton(configPage, "Reload Dictionary")
reloadDictButton.Size = UDim2.new(1, 0, 0, 30)

-- ==========================================
-- INFO PAGE UI
-- ==========================================

local infoTitle = newLabel(infoPage, "Definition Search", 14)
infoTitle.TextXAlignment = Enum.TextXAlignment.Center
infoTitle.TextColor3 = themes[config.theme].highlight

local meaningInput = newBox(infoPage, "Enter word...")
meaningInput.PlaceholderText = "Enter word..."

local meaningSearchButton = newButton(infoPage, "Search Definition")
meaningSearchButton.Size = UDim2.new(1, 0, 0, 30)

local copyDefButton = newButton(infoPage, "Copy Definition")
copyDefButton.Size = UDim2.new(1, 0, 0, 30)

local meaningOutputFrame = Instance.new("Frame", infoPage)
meaningOutputFrame.Size = UDim2.new(1, 0, 0, 140)
meaningOutputFrame.BackgroundColor3 = themes[config.theme].secondary
meaningOutputFrame.BorderSizePixel = 0
meaningOutputFrame.ZIndex = 2

local meaningOutputCorner = Instance.new("UICorner", meaningOutputFrame)
meaningOutputCorner.CornerRadius = UDim.new(0, 7)

local meaningOutputStroke = Instance.new("UIStroke", meaningOutputFrame)
meaningOutputStroke.Color = themes[config.theme].accent
meaningOutputStroke.Thickness = 1
meaningOutputStroke.Transparency = 0.6

local meaningOutput = newLabel(meaningOutputFrame, "Definition will appear here...", 10)
meaningOutput.Size = UDim2.new(1, -10, 1, -10)
meaningOutput.Position = UDim2.new(0, 5, 0, 5)
meaningOutput.TextWrapped = true
meaningOutput.TextYAlignment = Enum.TextYAlignment.Top
meaningOutput.TextXAlignment = Enum.TextXAlignment.Left
meaningOutput.ZIndex = 3

-- ==========================================
-- THEME SYSTEM
-- ==========================================

local function applyTheme(themeName)
	local theme = themes[themeName]
	if not theme then return end
	
	config.theme = themeName
	
	frame.BackgroundColor3 = theme.primary
	blur.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, theme.gradient1),
		ColorSequenceKeypoint.new(1, theme.gradient2)
	}
	frameStroke.Color = theme.accent
	
	local function updateElement(element)
		if element:IsA("TextButton") then
			element.BackgroundColor3 = theme.secondary
			element.TextColor3 = theme.text
			local stroke = element:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = theme.accent end
		elseif element:IsA("TextLabel") then
			element.TextColor3 = theme.text
		elseif element:IsA("TextBox") then
			element.BackgroundColor3 = theme.secondary
			element.TextColor3 = theme.text
			local stroke = element:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = theme.accent end
		elseif element:IsA("Frame") and element.BackgroundTransparency < 1 then
			if element.Name:find("Container") or element.Name:find("Output") or element.Name:find("List") or element == meaningOutputFrame then
				element.BackgroundColor3 = theme.secondary
				local stroke = element:FindFirstChildOfClass("UIStroke")
				if stroke then stroke.Color = theme.accent end
			end
		elseif element:IsA("ScrollingFrame") then
			element.ScrollBarImageColor3 = theme.accent
			if element.BackgroundTransparency < 1 then
				element.BackgroundColor3 = theme.secondary
			end
		end
	end
	
	for _, desc in ipairs(gui:GetDescendants()) do
		updateElement(desc)
	end
	
	wordLabel.TextColor3 = theme.highlight
	wordLabel.BackgroundColor3 = theme.secondary
	wordStroke.Color = theme.accent
	title.TextColor3 = theme.highlight
	humanTitle.TextColor3 = theme.highlight
	configTitle.TextColor3 = theme.highlight
	infoTitle.TextColor3 = theme.highlight
	
	themeDropdownButton.Text = themeName
	themeDropdownButton.TextColor3 = theme.text
	themeDropdownFrame.BackgroundColor3 = theme.secondary
	themeDropdownList.BackgroundColor3 = theme.secondary
	transparencySliderHandle.BackgroundColor3 = theme.highlight
end

-- Dropdown positioning update function
local function updateDropdownPosition()
	local absPos = themeDropdownFrame.AbsolutePosition
	themeDropdownList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 32)
end

themeDropdownButton.MouseButton1Click:Connect(function()
	themeDropdownExpanded = not themeDropdownExpanded
	
	if themeDropdownExpanded then
		updateDropdownPosition()
		themeDropdownList.Visible = true
		
		for _, child in ipairs(themeDropdownList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		
		local themeCount = 0
		for _ in pairs(themes) do themeCount = themeCount + 1 end
		
		themeDropdownList.Size = UDim2.new(0, 248, 0, themeCount * 30)
		themeDropdownList.CanvasSize = UDim2.new(0, 0, 0, themeCount * 30)
		
		for themeName, _ in pairs(themes) do
			local themeOption = Instance.new("TextButton", themeDropdownList)
			themeOption.Size = UDim2.new(1, -6, 0, 28)
			themeOption.BackgroundColor3 = themes[config.theme].secondary
			themeOption.TextColor3 = themes[config.theme].text
			themeOption.Text = themeName
			themeOption.Font = Enum.Font.GothamSemibold
			themeOption.TextSize = 11
			themeOption.BorderSizePixel = 0
			themeOption.ZIndex = 101
			
			local optCorner = Instance.new("UICorner", themeOption)
			optCorner.CornerRadius = UDim.new(0, 5)
			
			themeOption.MouseButton1Click:Connect(function()
				applyTheme(themeName)
				themeDropdownExpanded = false
				themeDropdownList.Visible = false
			end)
			
			themeOption.MouseEnter:Connect(function()
				themeOption.BackgroundColor3 = themes[config.theme].accent
			end)
			
			themeOption.MouseLeave:Connect(function()
				themeOption.BackgroundColor3 = themes[config.theme].secondary
			end)
		end
	else
		themeDropdownList.Visible = false
	end
end)

-- Fixed Transparency Slider Logic (only works when on Config page AND actively dragging)
local draggingTransparency = false

transparencySliderHandle.MouseButton1Down:Connect(function()
	if configPage.Visible then
		draggingTransparency = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingTransparency = false
	end
end)

-- Monitor page changes to stop dragging
for pageName, btn in pairs(navButtons) do
	btn.MouseButton1Click:Connect(function()
		draggingTransparency = false
	end)
end

RunService.RenderStepped:Connect(function()
	if draggingTransparency and configPage.Visible then
		local mousePos = UserInputService:GetMouseLocation()
		local barPos = transparencySliderBar.AbsolutePosition
		local barSize = transparencySliderBar.AbsoluteSize
		
		local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
		local newTransparency = 1 - relativeX
		
		config.transparency = newTransparency
		frame.BackgroundTransparency = newTransparency
		
		transparencySliderHandle.Position = UDim2.new(relativeX, -9, 0.5, -9)
		transparencyValueLabel.Text = string.format("%.2f", newTransparency)
	end
end)

-- Fixed Acrylic Toggle
acrylicToggle.MouseButton1Click:Connect(function()
	config.acrylic = not config.acrylic
	acrylicToggle.Text = config.acrylic and "On" or "Off"
	
	if config.acrylic then
		if not acrylicFrame then
			acrylicFrame = Instance.new("Frame", frame)
			acrylicFrame.Size = UDim2.new(1, 0, 1, 0)
			acrylicFrame.Position = UDim2.new(0, 0, 0, 0)
			acrylicFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			acrylicFrame.BackgroundTransparency = 0.92
			acrylicFrame.BorderSizePixel = 0
			acrylicFrame.ZIndex = 1
			
			local acrylicCorner = Instance.new("UICorner", acrylicFrame)
			acrylicCorner.CornerRadius = UDim.new(0, 14)
			
			local acrylicBlur = Instance.new("BlurEffect", acrylicFrame)
			acrylicBlur.Size = 8
		end
		acrylicFrame.Visible = true
	else
		if acrylicFrame then
			acrylicFrame.Visible = false
		end
	end
end)

-- Auto Load Toggle
autoLoadToggle.MouseButton1Click:Connect(function()
	config.autoLoadConfig = not config.autoLoadConfig
	autoLoadToggle.Text = config.autoLoadConfig and "On" or "Off"
end)

-- Human Typing Toggle
humanToggle.MouseButton1Click:Connect(function()
	config.humanTyping = not config.humanTyping
	humanToggle.Text = config.humanTyping and "On" or "Off"
	humanSettingsContainer.Visible = config.humanTyping
end)

-- Human Settings Input Handlers
baseSpeedInput.FocusLost:Connect(function()
	local v = tonumber(baseSpeedInput.Text)
	if v and v >= 0 then config.humanBaseSpeed = v end
	baseSpeedInput.Text = tostring(config.humanBaseSpeed)
end)

variationInput.FocusLost:Connect(function()
	local v = tonumber(variationInput.Text)
	if v and v >= 0 then config.humanVariation = v end
	variationInput.Text = tostring(config.humanVariation)
end)

pauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(pauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanPauseChance = v / 100
	end
	pauseChanceInput.Text = tostring(config.humanPauseChance * 100)
end)

pauseMinInput.FocusLost:Connect(function()
	local v = tonumber(pauseMinInput.Text)
	if v and v >= 0 then config.humanPauseMin = v end
	pauseMinInput.Text = tostring(config.humanPauseMin)
end)

pauseMaxInput.FocusLost:Connect(function()
	local v = tonumber(pauseMaxInput.Text)
	if v and v >= 0 then config.humanPauseMax = v end
	pauseMaxInput.Text = tostring(config.humanPauseMax)
end)

burstChanceInput.FocusLost:Connect(function()
	local v = tonumber(burstChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanBurstChance = v / 100
	end
	burstChanceInput.Text = tostring(config.humanBurstChance * 100)
end)

burstSpeedInput.FocusLost:Connect(function()
	local v = tonumber(burstSpeedInput.Text)
	if v and v > 0 and v <= 1 then config.humanBurstSpeed = v end
	burstSpeedInput.Text = tostring(config.humanBurstSpeed)
end)

fatigueToggle.MouseButton1Click:Connect(function()
	config.humanFatigue = not config.humanFatigue
	fatigueToggle.Text = config.humanFatigue and "On" or "Off"
	fatigueRateRow.Visible = config.humanFatigue
end)

fatigueRateInput.FocusLost:Connect(function()
	local v = tonumber(fatigueRateInput.Text)
	if v and v >= 0 and v <= 1 then config.humanFatigueRate = v end
	fatigueRateInput.Text = tostring(config.humanFatigueRate)
end)

-- ==========================================
-- LOGIC
-- ==========================================

loadDictionaries()

local pages = {
	Main = mainPage,
	Settings = settingsPage,
	Human = humanPage,
	Config = configPage,
	Info = infoPage
}

for pageName, btn in pairs(navButtons) do
	btn.MouseButton1Click:Connect(function()
		for name, page in pairs(pages) do
			page.Visible = (name == pageName)
		end
	end)
end

reloadDictButton.MouseButton1Click:Connect(function()
	loadDictionaries()
end)

local function fetchMeaning(wordRaw)
	local w = wordRaw:gsub("%s+", ""):lower()
	if #w == 0 then
		meaningOutput.Text = "Please enter a valid word."
		return
	end
	meaningOutput.Text = "Searching..."
	task.spawn(function()
		local url1 = "https://api.dictionaryapi.dev/api/v2/entries/en/" .. w
		local success1, res1 = pcall(function() return game:HttpGet(url1) end)
		if success1 then
			local decodedOk, data = pcall(function() return HttpService:JSONDecode(res1) end)
			if decodedOk and type(data) == "table" and data[1] and data[1].meanings then
				local def = data[1].meanings[1].definitions[1].definition
				meaningOutput.Text = def
				return
			end
		end
		meaningOutput.Text = "No definition found."
	end)
end

meaningSearchButton.MouseButton1Click:Connect(function() 
	fetchMeaning(meaningInput.Text) 
end)

copyDefButton.MouseButton1Click:Connect(function() 
	pcall(function() setclipboard(meaningOutput.Text) end) 
end)

local currentMatches = {}
local matchIndex = 1
local longest = false
local lastPrefix = ""
local autoTypePending = false
local autoTypeWaitCoroutine = nil
local charTypedCount = 0
local keyboardCache = nil
local lastKeyboardCheck = 0

-- Optimized keyboard getter with caching
local function safeGetKeyboard()
	local now = tick()
	if keyboardCache and (now - lastKeyboardCheck) < 0.5 then
		return keyboardCache
	end
	
	local ok, overbar = pcall(function() return player.PlayerGui.Overbar end)
	if not ok or not overbar then 
		keyboardCache = nil
		return nil 
	end
	local fr = overbar:FindFirstChild("Frame")
	if not fr then 
		keyboardCache = nil
		return nil 
	end
	local kb = fr:FindFirstChild("Keyboard")
	
	keyboardCache = kb
	lastKeyboardCheck = now
	return kb
end

local function pressDelete()
	local kb = safeGetKeyboard()
	if not kb then return end
	local del = kb:FindFirstChild("Delete")
	if del and del:IsA("TextButton") then
		pcall(function() firesignal(del.MouseButton1Click) end)
	end
end

local function clearTypedContinuation()
	if typedCount <= 0 then return end
	for i = 1, typedCount do
		pressDelete()
	end
	typedCount = 0
end

-- Cached letter buttons for faster access
local letterButtonCache = {}
local lastCacheUpdate = 0

local function pressLetter(c)
	local kb = safeGetKeyboard()
	if not kb then return end
	
	c = c:upper()
	
	-- Rebuild cache every 2 seconds
	local now = tick()
	if now - lastCacheUpdate > 2 then
		letterButtonCache = {}
		for _, rowName in ipairs({"1","2","3"}) do
			local row = kb:FindFirstChild(rowName)
			if row then
				for _, btn in ipairs(row:GetChildren()) do
					if btn:IsA("TextButton") then
						local t = (btn.Text or ""):upper()
						local n = (btn.Name or ""):upper()
						if #t == 1 then
							letterButtonCache[t] = btn
						elseif #n == 1 then
							letterButtonCache[n] = btn
						end
					end
				end
			end
		end
		lastCacheUpdate = now
	end
	
	local btn = letterButtonCache[c]
	if btn then
		pcall(function() firesignal(btn.MouseButton1Click) end)
	end
end

local function pressDone()
	local kb = safeGetKeyboard()
	if not kb then return end
	local done = kb:FindFirstChild("Done")
	if done and done:IsA("TextButton") then
		pcall(function() firesignal(done.MouseButton1Click) end)
	end
end

local function schedulePressDone()
	task.spawn(function()
		local minv = config.autoDoneMin
		local maxv = config.autoDoneMax
		if maxv <= minv then
			task.wait(minv)
		else
			task.wait(minv + math.random() * (maxv - minv))
		end
		pressDone()
	end)
end

local function getV2TypeDelay()
	local minv = config.autoTypeV2Min
	local maxv = config.autoTypeV2Max
	
	if maxv <= minv then
		return minv
	end
	
	return minv + math.random() * (maxv - minv)
end

local function getHumanTypeDelay()
	local baseSpeed = config.humanBaseSpeed
	local variation = config.humanVariation
	
	local delay = baseSpeed + (math.random() * 2 - 1) * variation
	
	if math.random() < config.humanPauseChance then
		local pauseDuration = config.humanPauseMin + 
			math.random() * (config.humanPauseMax - config.humanPauseMin)
		delay = delay + pauseDuration
	end
	
	if math.random() < config.humanBurstChance then
		delay = delay * config.humanBurstSpeed
	end
	
	if config.humanFatigue then
		local fatigueMultiplier = 1 + (charTypedCount * config.humanFatigueRate)
		delay = delay * fatigueMultiplier
	end
	
	return math.max(delay, 0.01)
end

local function typeContinuation(full, prefix, useV2Speed)
	if isTypingInProgress then return end
	isTypingInProgress = true

	clearTypedContinuation()
	full = full:lower()
	prefix = prefix:lower()
	local start = #prefix + 1
	if start > #full then
		isTypingInProgress = false
		return
	end

	local cont = full:sub(start)
	charTypedCount = 0

	if config.instantType then
		for i = 1, #cont do
			pressLetter(cont:sub(i,i))
		end
		typedCount = #cont
	else
		for i = 1, #cont do
			pressLetter(cont:sub(i,i))
			typedCount = typedCount + 1
			charTypedCount = charTypedCount + 1
			
			local delay
			if config.humanTyping then
				delay = getHumanTypeDelay()
			elseif useV2Speed then
				delay = getV2TypeDelay()
			else
				delay = config.typingDelay
				if config.randomizeTyping then
					delay = math.random() * delay * 2
				end
			end
			
			if delay > 0 then task.wait(delay) end
		end
	end

	isTypingInProgress = false
end

delayInput.FocusLost:Connect(function()
	local v = tonumber(delayInput.Text)
	if v and v > 0 then config.typingDelay = v end
	delayInput.Text = tostring(config.typingDelay)
end)

startDelayInput.FocusLost:Connect(function()
	local v = tonumber(startDelayInput.Text)
	if v and v >= 0 then config.startDelay = v end
	startDelayInput.Text = tostring(config.startDelay)
end)

randomToggleButton.MouseButton1Click:Connect(function()
	config.randomizeTyping = not config.randomizeTyping
	randomToggleButton.Text = config.randomizeTyping and "On" or "Off"
	if config.randomizeTyping then
		config.instantType = false
		instantToggle.Text = "Off"
	end
end)

autoDoneButton.MouseButton1Click:Connect(function()
	config.autoDone = not config.autoDone
	autoDoneButton.Text = config.autoDone and "On" or "Off"
end)

minInput.FocusLost:Connect(function()
	local v = tonumber(minInput.Text)
	if v and v >= 0 then config.autoDoneMin = v end
	minInput.Text = tostring(config.autoDoneMin)
end)

maxInput.FocusLost:Connect(function()
	local v = tonumber(maxInput.Text)
	if v and v >= 0 then config.autoDoneMax = v end
	maxInput.Text = tostring(config.autoDoneMax)
end)

antiDupeToggle.MouseButton1Click:Connect(function()
	config.antiDupe = not config.antiDupe
	antiDupeToggle.Text = config.antiDupe and "On" or "Off"
end)

shortInput.FocusLost:Connect(function()
	local v = tonumber(shortInput.Text)
	if v and v >= 1 then
		config.minWordLength = math.floor(v)
	end
	shortInput.Text = tostring(config.minWordLength)
end)

resetButton.MouseButton1Click:Connect(function()
	usedWords = {}
end)

instantToggle.MouseButton1Click:Connect(function()
	if config.randomizeTyping then return end
	config.instantType = not config.instantType
	instantToggle.Text = config.instantType and "On" or "Off"
end)

customInput.FocusLost:Connect(function()
	local str = customInput.Text
	if #str > 0 then
		addCustomWords(str)
	end
	customInput.Text = ""
end)

endingInput.FocusLost:Connect(function()
	local s = sanitizeEndingInput(endingInput.Text)
	config.endingIn = s
	endingInput.Text = s
end)

autoTypeButton.MouseButton1Click:Connect(function()
	config.autoType = not config.autoType
	autoTypeButton.Text = config.autoType and "Auto V1: On" or "Auto V1: Off"
	
	if config.autoType and config.autoTypeV2 then
		config.autoTypeV2 = false
		autoTypeV2Toggle.Text = "Off"
		v2MinMaxRow.Visible = false
	end
	
	if not config.autoType then
		clearTypedContinuation()
	end
end)

autoTypeV2Toggle.MouseButton1Click:Connect(function()
	config.autoTypeV2 = not config.autoTypeV2
	autoTypeV2Toggle.Text = config.autoTypeV2 and "On" or "Off"
	
	v2MinMaxRow.Visible = config.autoTypeV2
	
	if config.autoTypeV2 and config.autoType then
		config.autoType = false
		autoTypeButton.Text = "Auto V1: Off"
	end
	
	if not config.autoTypeV2 then
		clearTypedContinuation()
	end
end)

v2MinInput.FocusLost:Connect(function()
	local v = tonumber(v2MinInput.Text)
	if v and v >= 0 then config.autoTypeV2Min = v end
	v2MinInput.Text = tostring(config.autoTypeV2Min)
end)

v2MaxInput.FocusLost:Connect(function()
	local v = tonumber(v2MaxInput.Text)
	if v and v >= 0 then config.autoTypeV2Max = v end
	v2MaxInput.Text = tostring(config.autoTypeV2Max)
end)

nextButton.MouseButton1Click:Connect(function()
	if #currentMatches > 0 then
		matchIndex = matchIndex + 1
		if matchIndex > #currentMatches then matchIndex = 1 end
		wordLabel.Text = currentMatches[matchIndex]
		clearTypedContinuation()
	end
end)

typeButton.MouseButton1Click:Connect(function()
	if #currentMatches == 0 or lastPrefix == "" then return end
	local word = currentMatches[matchIndex]
	task.spawn(function()
		typeContinuation(word, lastPrefix, config.autoTypeV2)
		if config.antiDupe then usedWords[word] = true end
		if config.autoDone then schedulePressDone() end
	end)
end)

copyButton.MouseButton1Click:Connect(function()
	if #currentMatches > 0 then
		pcall(function() setclipboard(currentMatches[matchIndex]) end)
	end
end)

longestToggle.MouseButton1Click:Connect(function()
	longest = not longest
	longestToggle.Text = longest and "On" or "Off"
	if lastPrefix ~= "" then
		local sug, m = getSuggestion(lastPrefix, longest, config.antiDupe and true or false, usedWords, config.minWordLength, config.endingIn)
		currentMatches = m
		matchIndex = 1
		wordLabel.Text = sug
		clearTypedContinuation()
	end
end)

local function toHex(str)
	return (str:gsub('.', function (c)
		return string.format('%02X', string.byte(c))
	end))
end

local function fromHex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16))
	end))
end

saveConfigButton.MouseButton1Click:Connect(function()
	local saveData = {}
	for k, v in pairs(config) do
		saveData[k] = v
	end
	saveData.longest_setting = longest

	local json = HttpService:JSONEncode(saveData)
	local encoded = toHex(json)

	pcall(function()
		writefile("WordHelperConfig.txt", encoded)
	end)

	saveConfigButton.Text = "Saved!"
	task.delay(1, function()
		saveConfigButton.Text = "Save Config"
	end)
end)

loadConfigFromFile = function(silent)
	local success, result = pcall(function()
		return readfile("WordHelperConfig.txt")
	end)

	if success and result then
		local json = fromHex(result)
		local decoded = nil
		pcall(function() decoded = HttpService:JSONDecode(json) end)

		if decoded and type(decoded) == "table" then
			for k, v in pairs(decoded) do
				if k == "longest_setting" then
					longest = v
				elseif config[k] ~= nil then
					config[k] = v
				end
			end
			
			-- Update all UI elements
			delayInput.Text = tostring(config.typingDelay)
			startDelayInput.Text = tostring(config.startDelay)
			randomToggleButton.Text = config.randomizeTyping and "On" or "Off"
			autoDoneButton.Text = config.autoDone and "On" or "Off"
			minInput.Text = tostring(config.autoDoneMin)
			maxInput.Text = tostring(config.autoDoneMax)
			antiDupeToggle.Text = config.antiDupe and "On" or "Off"
			shortInput.Text = tostring(config.minWordLength)
			instantToggle.Text = config.instantType and "On" or "Off"
			endingInput.Text = config.endingIn
			autoTypeButton.Text = config.autoType and "Auto V1: On" or "Auto V1: Off"
			autoTypeV2Toggle.Text = config.autoTypeV2 and "On" or "Off"
			v2MinInput.Text = tostring(config.autoTypeV2Min)
			v2MaxInput.Text = tostring(config.autoTypeV2Max)
			longestToggle.Text = longest and "On" or "Off"
			v2MinMaxRow.Visible = config.autoTypeV2
			acrylicToggle.Text = config.acrylic and "On" or "Off"
			autoLoadToggle.Text = config.autoLoadConfig and "On" or "Off"
			
			humanToggle.Text = config.humanTyping and "On" or "Off"
			humanSettingsContainer.Visible = config.humanTyping
			baseSpeedInput.Text = tostring(config.humanBaseSpeed)
			variationInput.Text = tostring(config.humanVariation)
			pauseChanceInput.Text = tostring(config.humanPauseChance * 100)
			pauseMinInput.Text = tostring(config.humanPauseMin)
			pauseMaxInput.Text = tostring(config.humanPauseMax)
			burstChanceInput.Text = tostring(config.humanBurstChance * 100)
			burstSpeedInput.Text = tostring(config.humanBurstSpeed)
			fatigueToggle.Text = config.humanFatigue and "On" or "Off"
			fatigueRateInput.Text = tostring(config.humanFatigueRate)
			fatigueRateRow.Visible = config.humanFatigue
			
			applyTheme(config.theme)
			frame.BackgroundTransparency = config.transparency
			transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -9, 0.5, -9)
			transparencyValueLabel.Text = string.format("%.2f", config.transparency)
			
			if config.acrylic then
				if not acrylicFrame then
					acrylicFrame = Instance.new("Frame", frame)
					acrylicFrame.Size = UDim2.new(1, 0, 1, 0)
					acrylicFrame.Position = UDim2.new(0, 0, 0, 0)
					acrylicFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					acrylicFrame.BackgroundTransparency = 0.92
					acrylicFrame.BorderSizePixel = 0
					acrylicFrame.ZIndex = 1
					
					local acrylicCorner = Instance.new("UICorner", acrylicFrame)
					acrylicCorner.CornerRadius = UDim.new(0, 14)
					
					local acrylicBlur = Instance.new("BlurEffect", acrylicFrame)
					acrylicBlur.Size = 8
				end
				acrylicFrame.Visible = true
			else
				if acrylicFrame then
					acrylicFrame.Visible = false
				end
			end
			
			if not silent then
				loadConfigButton.Text = "Loaded!"
				task.delay(1, function()
					loadConfigButton.Text = "Load Config"
				end)
			end
		else
			if not silent then
				loadConfigButton.Text = "Fail"
				task.delay(1, function() loadConfigButton.Text = "Load Config" end)
			end
		end
	else
		if not silent then
			loadConfigButton.Text = "No File"
			task.delay(1, function() loadConfigButton.Text = "Load Config" end)
		end
	end
end

loadConfigButton.MouseButton1Click:Connect(function()
	loadConfigFromFile(false)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.T then
		if #currentMatches == 0 or lastPrefix == "" or isTypingInProgress then return end
		local word = currentMatches[matchIndex]
		if config.antiDupe and usedWords[word] then return end
		task.spawn(function()
			typeContinuation(word, lastPrefix, config.autoTypeV2 or config.humanTyping)
			if config.antiDupe then usedWords[word] = true end
			if config.autoDone then schedulePressDone() end
		end)
	end
end)

local function checkInGameAutoCondition()
	local inGame = player.PlayerGui:FindFirstChild("InGame")
	if not inGame then return false end
	local fr = inGame:FindFirstChild("Frame")
	if not fr then return false end
	local typ = fr:FindFirstChild("Type")
	if not typ then return false end
	local txt = tostring(typ.Text or "")
	if txt == "" then return false end
	if string.find(txt, player.Name, 1, true) or (player.DisplayName ~= "" and string.find(txt, player.DisplayName, 1, true)) then
		return true
	end
	return false
end

local updateSuggestionFromClosestTable

local function startAutoTypeIfNeeded()
	if not (config.autoType or config.autoTypeV2) or autoTypePending or isTypingInProgress then return end
	if not checkInGameAutoCondition() then return end

	autoTypePending = true
	autoTypeWaitCoroutine = coroutine.create(function()
		if config.startDelay > 0 then
			task.wait(config.startDelay)
		end
		
		updateSuggestionFromClosestTable(true)
		
		local word = currentMatches[matchIndex]
		if not word or lastPrefix == "" then autoTypePending = false return end
		
		local remaining = #word - #lastPrefix
		local waitTime = (remaining <= 3) and (0.5 + math.random()) or (1 + math.random()*0.9)
		
		task.wait(waitTime)
		
		if not (config.autoType or config.autoTypeV2) then autoTypePending = false return end
		if not checkInGameAutoCondition() then autoTypePending = false return end
		if config.antiDupe and usedWords[word] then autoTypePending = false return end
		
		typeContinuation(word, lastPrefix, config.autoTypeV2 or config.humanTyping)
		
		if config.antiDupe then usedWords[word] = true end
		if config.autoDone then schedulePressDone() end
		autoTypePending = false
	end)
	coroutine.resume(autoTypeWaitCoroutine)
end

local lastUpdate = 0
local updateInterval = 0.12

local function extractPrefixFromGui(guiObj)
	if not guiObj then return "" end

	local function isValidPrefix(str)
		if not str then return false end
		local s = str:gsub("%s+", "")
		return #s > 0 and s:match("^[A-Za-z]+$")
	end

	local starting = guiObj:FindFirstChild("Starting")
	if starting and (starting:IsA("TextLabel") or starting:IsA("TextBox")) then
		local txt = tostring(starting.Text or "")
		if isValidPrefix(txt) then
			return txt:gsub("%s+", ""):lower()
		end
	end

	for _, v in ipairs(guiObj:GetDescendants()) do
		if (v:IsA("TextLabel") or v:IsA("TextBox")) and v.Text then
			local txt = tostring(v.Text or "")
			if isValidPrefix(txt) and v.Name ~= "Timer" then
				return txt:gsub("%s+", ""):lower()
			end
		end
	end
	return ""
end

updateSuggestionFromClosestTable = function(forced)
	if isTypingInProgress and not forced then return end
	if not isDictionaryReady then
		if wordLabel.Text == "Ready" then wordLabel.Text = "Processing..." end
		return
	end

	local tbl = getClosestTable()
	if not tbl then
		if wordLabel.Text ~= "No table" then wordLabel.Text = "No table" end
		currentMatches = {}
		matchIndex = 1
		lastPrefix = ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local bb = tbl:FindFirstChild("Billboard") or tbl:FindFirstChildWhichIsA("Model") or tbl:FindFirstChildWhichIsA("Folder")
	if not bb then
		wordLabel.Text = "Waiting..."
		currentMatches = {}
		matchIndex = 1
		lastPrefix = ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local guiObj = bb:FindFirstChild("Gui")
	if not guiObj then
		for _, v in ipairs(bb:GetDescendants()) do
			if v.Name == "Gui" and (v:IsA("Folder") or v:IsA("Model") or v:IsA("ScreenGui") or v:IsA("Frame")) then
				guiObj = v
				break
			end
		end
	end

	if not guiObj then
		guiObj = bb:FindFirstChildOfClass("Folder") or bb:FindFirstChildOfClass("Model")
	end

	local prefix = extractPrefixFromGui(guiObj)
	if prefix == "" then
		wordLabel.Text = "Waiting..."
		currentMatches = {}
		matchIndex = 1
		lastPrefix = ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	if not forced and prefix == lastPrefix then return end
	autoTypePrefixTime = tick()
	lastPrefix = prefix

	local sug, m = getSuggestion(prefix, longest, config.antiDupe and true or false, usedWords, config.minWordLength, config.endingIn)
	currentMatches = m
	matchIndex = 1
	wordLabel.Text = sug
	if not isTypingInProgress then clearTypedContinuation() end

	if (config.autoType or config.autoTypeV2) and not forced then
		startAutoTypeIfNeeded()
	end
end

forceFindButton.MouseButton1Click:Connect(function()
	updateSuggestionFromClosestTable(true)
end)

RunService.RenderStepped:Connect(function()
	local now = tick()
	if now - lastUpdate >= updateInterval then
		lastUpdate = now
		updateSuggestionFromClosestTable()
	end
	if (config.autoType or config.autoTypeV2) and not autoTypePending then
		if checkInGameAutoCondition() then
			startAutoTypeIfNeeded()
		end
	end
end)

print("Word Helper Pro loaded successfully!")
