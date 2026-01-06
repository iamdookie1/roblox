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
local dictionary, index, blacklist = {}, {}, {}
local typedWords, skippedWords, failedWords, favoredWords = {}, {}, {}, {}
local isDictionaryReady, isReloading = false, false
local updateStatusLabel
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
	autoTypeV2MoreRandom = false,
	autoTypeV2MoreHuman = false,
	humanStartPauseChance = 0.20,
	humanStartPauseMult = 2.5,
	humanMidPauseChance = 0.15,
	humanMidPauseMult = 2.0,
	humanEndPauseChance = 0.10,
	humanEndPauseMult = 1.8,
	humanStartFlowChance = 0.05,
	humanStartFlowMult = 0.8,
	humanMidFlowChance = 0.10,
	humanMidFlowMult = 0.7,
	humanEndFlowChance = 0.15,
	humanEndFlowMult = 0.6,
	minWordLength = 3,
	endingIn = "",
	theme = "Dark",
	transparency = 0.05,
	acrylic = false
}

local usedWords = {}
local typedCount = 0
local isTypingInProgress = false
local autoTypePrefixTime = 0
local lastV2TypeTimes = {}
local currentMatches = {}
local matchIndex = 1
local longest = false
local lastPrefix = ""
local autoTypePending = false
local autoTypeWaitCoroutine = nil
local currentHistoryTab = "Typed"
local currentHistoryPage = 1
local historyItemsPerPage = 10
local currentInfoPage = 1
local lastUpdate = 0
local updateInterval = 0.12
local draggingTransparency = false
local themeDropdownExpanded = false

-- Fetching Data Helper
local function fetchData(url)
	for attempt = 1, 2 do
		local success, res = pcall(function() return game:HttpGet(url, true) end)
		if success and res and #res > 100 then return res end
		if attempt < 2 then task.wait(0.5) end
	end
	warn("Failed to load URL: " .. url)
	return ""
end

-- Dictionary Loading
local function buildDictionaryStructure(dText1, dText2, bText1, bText2)
	dictionary, index, blacklist = {}, {}, {}
	local maxPerFrame = WORDS_PER_FRAME
	local processedCount = 0
	local seen = {}

	local function addToBlacklist(str)
		if not str or #str == 0 then return end
		for word in str:gmatch("[^\r\n]+") do
			local w = word:lower():gsub("%s+", "")
			if #w > 0 then blacklist[w] = true end
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
				index[f] = index[f] or {}
				table.insert(index[f], w)
				table.insert(dictionary, w)
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

local function loadDictionaries()
	if isReloading then return end
	isReloading = true
	isDictionaryReady = false
	if updateStatusLabel then updateStatusLabel("Downloading...") end

	task.spawn(function()
		local results = {}
		task.spawn(function() results[1] = fetchData(DICT_URL) end)
		task.spawn(function() results[2] = fetchData(DICT_URL_BACKUP) end)
		task.spawn(function() results[3] = fetchData(BAD_WORDS_URL_1) end)
		task.spawn(function() results[4] = fetchData(BAD_WORDS_URL_2) end)
		
		local elapsed = 0
		while (not results[1] or not results[2] or not results[3] or not results[4]) and elapsed < 10 do
			task.wait(0.1)
			elapsed = elapsed + 0.1
		end
		
		local dt1 = results[1] or ""
		local dt2 = results[2] or ""
		local bt1 = results[3] or ""
		local bt2 = results[4] or ""
		
		if dt1 == "" and dt2 == "" then
			if updateStatusLabel then updateStatusLabel("FAILED TO LOAD") end
			dt1 = "apple\nbanana\ncat\ndog\nelephant"
		end
		
		buildDictionaryStructure(dt1, dt2, bt1, bt2)
		isDictionaryReady = true
		isReloading = false
		if updateStatusLabel then updateStatusLabel("Ready") end
	end)
end

local function addCustomWords(str)
	for w in str:gmatch("[^,%s]+") do
		w = w:lower()
		if #w > 0 and not blacklist[w] then
			table.insert(dictionary, w)
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

local function getMatches(prefix, anti, used, minLen, ending)
	if not isDictionaryReady then return {} end
	prefix = prefix:lower():gsub("%s+", "")
	if #prefix == 0 then return {} end
	local f = prefix:sub(1,1)
	local list = index[f]
	if not list then return {} end

	local out, unique = {}, {}
	local endingProvided = ending and #ending > 0

	for i = 1, #list do
		local w = list[i]
		if (#w >= (minLen or 3)) and w:find(prefix, 1, true) == 1 and w ~= prefix then
			if not unique[w] and (not anti or not used[w]) then
				if not endingProvided or w:sub(-#ending) == ending then
					table.insert(out, w)
					unique[w] = true
				end
			end
		end
	end
	return out
end

local function getSuggestion(prefix, isLongest, anti, used, minLen, ending)
	if not isDictionaryReady then return "Loading...", {} end
	local endingVal = sanitizeEndingInput(ending or "")
	local m = getMatches(prefix, anti, used, minLen, endingVal ~= "" and endingVal or "")
	if endingVal ~= "" and #m == 0 then
		m = getMatches(prefix, anti, used, minLen, "")
	end
	
	local favoredMatches, normalMatches = {}, {}
	for i = 1, #m do
		if favoredWords[m[i]] then
			table.insert(favoredMatches, m[i])
		else
			table.insert(normalMatches, m[i])
		end
	end
	
	local function sortFunc(a,b)
		if #a == #b then return a < b end
		if isLongest then return #a > #b else return #a < #b end
	end
	
	table.sort(favoredMatches, sortFunc)
	table.sort(normalMatches, sortFunc)
	
	local combined = {}
	for i = 1, #favoredMatches do table.insert(combined, favoredMatches[i]) end
	for i = 1, #normalMatches do table.insert(combined, normalMatches[i]) end
	
	if #combined == 0 then return "No Match", {} end
	return combined[1], combined
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
	if folder then
		for _, c in ipairs(folder:GetChildren()) do
			if c:IsA("Model") and c:FindFirstChild("Billboard") then
				table.insert(out, c)
			end
		end
		if #out > 0 then return out end
	end
	for _, c in ipairs(workspace:GetChildren()) do
		if c:IsA("Model") and c:FindFirstChild("Billboard") then
			table.insert(out, c)
		end
	end
	if #out > 0 then return out end
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc.Name == "Billboard" and desc.Parent and desc.Parent:IsA("Model") then
			if not table.find(out, desc.Parent) then
				table.insert(out, desc.Parent)
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
		local pos = getModelPosition(models[i])
		if pos then
			local d = (pos - hrp.Position).Magnitude
			if d < dist then
				dist = d
				best = models[i]
			end
		end
	end
	return best
end

-- GUI Creation
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Name = "WordHelperUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 420)
frame.Position = UDim2.new(0.7, 0, 0.1, 0)
frame.BackgroundColor3 = themes[config.theme].primary
frame.BackgroundTransparency = config.transparency
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 12)

local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = themes[config.theme].accent
frameStroke.Thickness = 1
frameStroke.Transparency = 0.5

local blur = Instance.new("UIGradient", frame)
blur.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, themes[config.theme].gradient1),
	ColorSequenceKeypoint.new(1, themes[config.theme].gradient2)
}
blur.Rotation = 45

local acrylicBlur
if config.acrylic then
	acrylicBlur = Instance.new("BlurEffect")
	acrylicBlur.Size = 24
	acrylicBlur.Name = "WordHelperAcrylicBlur"
	acrylicBlur.Enabled = true
	acrylicBlur.Parent = frame
end

local topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 2

local function newButton(parent, text, size)
	local b = Instance.new("TextButton", parent)
	b.Text = text
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 12
	b.BackgroundColor3 = themes[config.theme].secondary
	b.AutoButtonColor = false
	b.TextColor3 = themes[config.theme].text
	b.BorderSizePixel = 0
	b.Size = size or UDim2.new(1, 0, 0, 28)
	b.ZIndex = 2
	
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = themes[config.theme].accent
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = themes[config.theme].accent}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = themes[config.theme].secondary}):Play()
	end)
	return b
end

local navButtons = {}
for i, name in ipairs({"Main", "Settings", "History", "Config", "Info"}) do
	local btn = newButton(topBar, name)
	btn.Size = UDim2.new(0.18, 0, 1, 0)
	btn.Position = UDim2.new((i-1) * 0.19, 0, 0, 0)
	btn.TextSize = 11
	navButtons[name] = btn
end

local contentContainer = Instance.new("Frame", frame)
contentContainer.Size = UDim2.new(1, 0, 1, -40)
contentContainer.Position = UDim2.new(0, 0, 0, 40)
contentContainer.BackgroundTransparency = 1
contentContainer.ZIndex = 2

local function createPage()
	local pg = Instance.new("ScrollingFrame", contentContainer)
	pg.Size = UDim2.new(1, -8, 1, -8)
	pg.Position = UDim2.new(0, 4, 0, 4)
	pg.BackgroundTransparency = 1
	pg.ScrollBarThickness = 4
	pg.ScrollBarImageColor3 = themes[config.theme].accent
	pg.CanvasSize = UDim2.new(0, 0, 0, 0)
	pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pg.Visible = false
	pg.BorderSizePixel = 0
	pg.ZIndex = 2
	
	Instance.new("UIListLayout", pg).Padding = UDim.new(0, 6)
	local pad = Instance.new("UIPadding", pg)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 6)
	return pg
end

local pages = {
	Main = createPage(),
	Settings = createPage(),
	History = createPage(),
	Config = createPage(),
	Info = createPage()
}
pages.Main.Visible = true

local infoPage2 = createPage()

local function addSpacer(parent, height)
	local f = Instance.new("Frame", parent)
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, height or 6)
	return f
end

local function newLabel(parent, text, size)
	local l = Instance.new("TextLabel", parent)
	l.BackgroundTransparency = 1
	l.Text = text
	l.Font = Enum.Font.GothamBold
	l.TextColor3 = themes[config.theme].text
	l.TextSize = size
	l.Size = UDim2.new(1, 0, 0, size + 12)
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextWrapped = true
	l.ZIndex = 2
	return l
end

local function newBox(parent, text, height)
	local b = Instance.new("TextBox", parent)
	b.BackgroundColor3 = themes[config.theme].secondary
	b.TextColor3 = themes[config.theme].text
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 13
	b.Text = text or ""
	b.Size = UDim2.new(1, 0, 0, height or 28)
	b.BorderSizePixel = 0
	b.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
	b.ZIndex = 2
	
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = themes[config.theme].accent
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	return b
end

-- MAIN PAGE UI
local title = newLabel(pages.Main, "Word Helper Pro", 16)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextColor3 = themes[config.theme].highlight

local wordLabel = Instance.new("TextLabel", pages.Main)
wordLabel.Size = UDim2.new(1, 0, 0, 45)
wordLabel.BackgroundColor3 = themes[config.theme].secondary
wordLabel.TextColor3 = themes[config.theme].highlight
wordLabel.Font = Enum.Font.GothamBold
wordLabel.TextSize = 18
wordLabel.Text = "Waiting..."
wordLabel.BorderSizePixel = 0
wordLabel.ZIndex = 2
Instance.new("UICorner", wordLabel).CornerRadius = UDim.new(0, 10)
local wordStroke = Instance.new("UIStroke", wordLabel)
wordStroke.Color = themes[config.theme].accent
wordStroke.Thickness = 2
wordStroke.Transparency = 0.5

updateStatusLabel = function(txt) wordLabel.Text = txt end

local nextButton = newButton(pages.Main, "Next Word")
nextButton.Size = UDim2.new(1, 0, 0, 32)

-- Create rows using tables to reduce locals
local mainButtons = {}
do
	local row1 = Instance.new("Frame", pages.Main)
	row1.Size = UDim2.new(1, 0, 0, 32)
	row1.BackgroundTransparency = 1
	row1.ZIndex = 2
	mainButtons.type = newButton(row1, "Type")
	mainButtons.type.Size = UDim2.new(0.48, 0, 1, 0)
	mainButtons.autoType = newButton(row1, "Auto V1: Off")
	mainButtons.autoType.Position = UDim2.new(0.52, 0, 0, 0)
	mainButtons.autoType.Size = UDim2.new(0.48, 0, 1, 0)

	local row2 = Instance.new("Frame", pages.Main)
	row2.Size = UDim2.new(1, 0, 0, 32)
	row2.BackgroundTransparency = 1
	row2.ZIndex = 2
	mainButtons.copy = newButton(row2, "Copy")
	mainButtons.copy.Size = UDim2.new(0.48, 0, 1, 0)
	mainButtons.forceFind = newButton(row2, "Force Find")
	mainButtons.forceFind.Position = UDim2.new(0.52, 0, 0, 0)
	mainButtons.forceFind.Size = UDim2.new(0.48, 0, 1, 0)

	local row3 = Instance.new("Frame", pages.Main)
	row3.Size = UDim2.new(1, 0, 0, 32)
	row3.BackgroundTransparency = 1
	row3.ZIndex = 2
	local longestLabel = newLabel(row3, "Longest First", 13)
	longestLabel.Size = UDim2.new(0.5, 0, 1, 0)
	longestLabel.TextYAlignment = Enum.TextYAlignment.Center
	mainButtons.longest = newButton(row3, "Off")
	mainButtons.longest.Size = UDim2.new(0.48, 0, 1, 0)
	mainButtons.longest.Position = UDim2.new(0.52, 0, 0, 0)
end

-- V2 Controls
local v2Controls = {}
do
	local autoTypeV2Row = Instance.new("Frame", pages.Main)
	autoTypeV2Row.Size = UDim2.new(1, 0, 0, 32)
	autoTypeV2Row.BackgroundTransparency = 1
	autoTypeV2Row.ZIndex = 2
	local autoTypeV2Label = newLabel(autoTypeV2Row, "Auto Type V2", 13)
	autoTypeV2Label.Size = UDim2.new(0.5, 0, 1, 0)
	autoTypeV2Label.TextYAlignment = Enum.TextYAlignment.Center
	v2Controls.toggle = newButton(autoTypeV2Row, "Off")
	v2Controls.toggle.Size = UDim2.new(0.48, 0, 1, 0)
	v2Controls.toggle.Position = UDim2.new(0.52, 0, 0, 0)

	v2Controls.minMaxRow = Instance.new("Frame", pages.Main)
	v2Controls.minMaxRow.Size = UDim2.new(1, 0, 0, 32)
	v2Controls.minMaxRow.BackgroundTransparency = 1
	v2Controls.minMaxRow.Visible = false
	v2Controls.minMaxRow.ZIndex = 2
	local v2mml = newLabel(v2Controls.minMaxRow, "V2 Min/Max", 12)
	v2mml.Size = UDim2.new(0.38, 0, 1, 0)
	v2mml.TextYAlignment = Enum.TextYAlignment.Center
	v2Controls.minInput = newBox(v2Controls.minMaxRow, tostring(config.autoTypeV2Min), 32)
	v2Controls.minInput.Size = UDim2.new(0.28, 0, 1, 0)
	v2Controls.minInput.Position = UDim2.new(0.40, 0, 0, 0)
	v2Controls.maxInput = newBox(v2Controls.minMaxRow, tostring(config.autoTypeV2Max), 32)
	v2Controls.maxInput.Size = UDim2.new(0.28, 0, 1, 0)
	v2Controls.maxInput.Position = UDim2.new(0.70, 0, 0, 0)

	v2Controls.moreRandomRow = Instance.new("Frame", pages.Main)
	v2Controls.moreRandomRow.Size = UDim2.new(1, 0, 0, 32)
	v2Controls.moreRandomRow.BackgroundTransparency = 1
	v2Controls.moreRandomRow.Visible = false
	v2Controls.moreRandomRow.ZIndex = 2
	local v2mrl = newLabel(v2Controls.moreRandomRow, "More Random", 12)
	v2mrl.Size = UDim2.new(0.5, 0, 1, 0)
	v2mrl.TextYAlignment = Enum.TextYAlignment.Center
	v2Controls.moreRandom = newButton(v2Controls.moreRandomRow, "Off")
	v2Controls.moreRandom.Size = UDim2.new(0.48, 0, 1, 0)
	v2Controls.moreRandom.Position = UDim2.new(0.52, 0, 0, 0)

	v2Controls.moreHumanRow = Instance.new("Frame", pages.Main)
	v2Controls.moreHumanRow.Size = UDim2.new(1, 0, 0, 32)
	v2Controls.moreHumanRow.BackgroundTransparency = 1
	v2Controls.moreHumanRow.Visible = false
	v2Controls.moreHumanRow.ZIndex = 2
	local v2mhl = newLabel(v2Controls.moreHumanRow, "More Human", 12)
	v2mhl.Size = UDim2.new(0.5, 0, 1, 0)
	v2mhl.TextYAlignment = Enum.TextYAlignment.Center
	v2Controls.moreHuman = newButton(v2Controls.moreHumanRow, "Off")
	v2Controls.moreHuman.Size = UDim2.new(0.48, 0, 1, 0)
	v2Controls.moreHuman.Position = UDim2.new(0.52, 0, 0, 0)
end

-- Human Settings Container
local humanSettings = Instance.new("Frame", pages.Main)
humanSettings.BackgroundTransparency = 1
humanSettings.Visible = false
humanSettings.ZIndex = 2
humanSettings.Size = UDim2.new(1, 0, 0, 0)
humanSettings.AutomaticSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", humanSettings).Padding = UDim.new(0, 6)

local humanInputs = {}
local function createCompactSettingRow(parent, labelText, val1, val2)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.ZIndex = 2
	local lbl = newLabel(row, labelText, 10)
	lbl.Size = UDim2.new(0.35, 0, 1, 0)
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	local input1 = newBox(row, tostring(val1), 28)
	input1.Size = UDim2.new(0.28, 0, 1, 0)
	input1.Position = UDim2.new(0.37, 0, 0, 0)
	input1.TextSize = 11
	local input2 = newBox(row, tostring(val2), 28)
	input2.Size = UDim2.new(0.28, 0, 1, 0)
	input2.Position = UDim2.new(0.69, 0, 0, 0)
	input2.TextSize = 11
	return input1, input2
end

do
	local startLabel = newLabel(humanSettings, "Start (20%)", 10)
	startLabel.Size = UDim2.new(1, 0, 0, 18)
	startLabel.TextColor3 = themes[config.theme].accent
	humanInputs.startPauseChance, humanInputs.startPauseMult = createCompactSettingRow(humanSettings, "Pause %/x", config.humanStartPauseChance * 100, config.humanStartPauseMult)
	humanInputs.startFlowChance, humanInputs.startFlowMult = createCompactSettingRow(humanSettings, "Flow %/x", config.humanStartFlowChance * 100, config.humanStartFlowMult)
	
	addSpacer(humanSettings, 4)
	
	local midLabel = newLabel(humanSettings, "Middle (60%)", 10)
	midLabel.Size = UDim2.new(1, 0, 0, 18)
	midLabel.TextColor3 = themes[config.theme].accent
	humanInputs.midPauseChance, humanInputs.midPauseMult = createCompactSettingRow(humanSettings, "Pause %/x", config.humanMidPauseChance * 100, config.humanMidPauseMult)
	humanInputs.midFlowChance, humanInputs.midFlowMult = createCompactSettingRow(humanSettings, "Flow %/x", config.humanMidFlowChance * 100, config.humanMidFlowMult)
	
	addSpacer(humanSettings, 4)
	
	local endLabel = newLabel(humanSettings, "End (20%)", 10)
	endLabel.Size = UDim2.new(1, 0, 0, 18)
	endLabel.TextColor3 = themes[config.theme].accent
	humanInputs.endPauseChance, humanInputs.endPauseMult = createCompactSettingRow(humanSettings, "Pause %/x", config.humanEndPauseChance * 100, config.humanEndPauseMult)
	humanInputs.endFlowChance, humanInputs.endFlowMult = createCompactSettingRow(humanSettings, "Flow %/x", config.humanEndFlowChance * 100, config.humanEndFlowMult)
end

-- SETTINGS PAGE
local settingsInputs = {}
do
	local function createSettingRow(parent, name, inputObj)
		local f = Instance.new("Frame", parent)
		f.Size = UDim2.new(1, 0, 0, 32)
		f.BackgroundTransparency = 1
		f.ZIndex = 2
		local l = newLabel(f, name, 12)
		l.Size = UDim2.new(0.55, 0, 1, 0)
		l.TextYAlignment = Enum.TextYAlignment.Center
		inputObj.Parent = f
		inputObj.Size = UDim2.new(0.43, 0, 1, 0)
		inputObj.Position = UDim2.new(0.57, 0, 0, 0)
		return f
	end

	createSettingRow(pages.Settings, "Typing Delay", newBox(nil, tostring(config.typingDelay)))
	settingsInputs.delay = pages.Settings:GetChildren()[#pages.Settings:GetChildren()]:FindFirstChildOfClass("TextBox")
	
	createSettingRow(pages.Settings, "Start Delay", newBox(nil, tostring(config.startDelay)))
	settingsInputs.startDelay = pages.Settings:GetChildren()[#pages.Settings:GetChildren()]:FindFirstChildOfClass("TextBox")
	
	local randomRow = Instance.new("Frame", pages.Settings)
	randomRow.Size = UDim2.new(1, 0, 0, 32)
	randomRow.BackgroundTransparency = 1
	randomRow.ZIndex = 2
	local rl = newLabel(randomRow, "Random Speed", 12)
	rl.Size = UDim2.new(0.55, 0, 1, 0)
	rl.TextYAlignment = Enum.TextYAlignment.Center
	settingsInputs.randomToggle = newButton(randomRow, "Off")
	settingsInputs.randomToggle.Size = UDim2.new(0.43, 0, 1, 0)
	settingsInputs.randomToggle.Position = UDim2.new(0.57, 0, 0, 0)
	
	local autoDoneRow = Instance.new("Frame", pages.Settings)
	autoDoneRow.Size = UDim2.new(1, 0, 0, 32)
	autoDoneRow.BackgroundTransparency = 1
	autoDoneRow.ZIndex = 2
	local adl = newLabel(autoDoneRow, "Auto Done", 12)
	adl.Size = UDim2.new(0.55, 0, 1, 0)
	adl.TextYAlignment = Enum.TextYAlignment.Center
	settingsInputs.autoDone = newButton(autoDoneRow, "On")
	settingsInputs.autoDone.Size = UDim2.new(0.43, 0, 1, 0)
	settingsInputs.autoDone.Position = UDim2.new(0.57, 0, 0, 0)
	
	local minMaxRow = Instance.new("Frame", pages.Settings)
	minMaxRow.Size = UDim2.new(1, 0, 0, 32)
	minMaxRow.BackgroundTransparency = 1
	minMaxRow.ZIndex = 2
	local mml = newLabel(minMaxRow, "Done Min/Max", 12)
	mml.Size = UDim2.new(0.38, 0, 1, 0)
	mml.TextYAlignment = Enum.TextYAlignment.Center
	settingsInputs.doneMin = newBox(minMaxRow, tostring(config.autoDoneMin))
	settingsInputs.doneMin.Size = UDim2.new(0.28, 0, 1, 0)
	settingsInputs.doneMin.Position = UDim2.new(0.40, 0, 0, 0)
	settingsInputs.doneMax = newBox(minMaxRow, tostring(config.autoDoneMax))
	settingsInputs.doneMax.Size = UDim2.new(0.28, 0, 1, 0)
	settingsInputs.doneMax.Position = UDim2.new(0.70, 0, 0, 0)
	
	local antiDupeRow = Instance.new("Frame", pages.Settings)
	antiDupeRow.Size = UDim2.new(1, 0, 0, 32)
	antiDupeRow.BackgroundTransparency = 1
	antiDupeRow.ZIndex = 2
	local adl2 = newLabel(antiDupeRow, "Anti Dupe", 12)
	adl2.Size = UDim2.new(0.55, 0, 1, 0)
	adl2.TextYAlignment = Enum.TextYAlignment.Center
	settingsInputs.antiDupe = newButton(antiDupeRow, "Off")
	settingsInputs.antiDupe.Size = UDim2.new(0.43, 0, 1, 0)
	settingsInputs.antiDupe.Position = UDim2.new(0.57, 0, 0, 0)
	
	createSettingRow(pages.Settings, "Min Length", newBox(nil, tostring(config.minWordLength)))
	settingsInputs.minLength = pages.Settings:GetChildren()[#pages.Settings:GetChildren()]:FindFirstChildOfClass("TextBox")
	
	local instantRow = Instance.new("Frame", pages.Settings)
	instantRow.Size = UDim2.new(1, 0, 0, 32)
	instantRow.BackgroundTransparency = 1
	instantRow.ZIndex = 2
	local il = newLabel(instantRow, "Instant Type", 12)
	il.Size = UDim2.new(0.55, 0, 1, 0)
	il.TextYAlignment = Enum.TextYAlignment.Center
	settingsInputs.instant = newButton(instantRow, "Off")
	settingsInputs.instant.Size = UDim2.new(0.43, 0, 1, 0)
	settingsInputs.instant.Position = UDim2.new(0.57, 0, 0, 0)
	
	createSettingRow(pages.Settings, "Custom Words", newBox(nil, ""))
	settingsInputs.custom = pages.Settings:GetChildren()[#pages.Settings:GetChildren()]:FindFirstChildOfClass("TextBox")
	
	createSettingRow(pages.Settings, "End In (1-2)", newBox(nil, ""))
	settingsInputs.ending = pages.Settings:GetChildren()[#pages.Settings:GetChildren()]:FindFirstChildOfClass("TextBox")
	
	addSpacer(pages.Settings, 10)
	
	settingsInputs.reset = newButton(pages.Settings, "Reset Used Words")
	settingsInputs.reset.Size = UDim2.new(1, 0, 0, 32)
end

-- HISTORY PAGE
local historyElements = {}
do
	local historyTitle = newLabel(pages.History, "Word History", 15)
	historyTitle.TextXAlignment = Enum.TextXAlignment.Center
	historyTitle.TextColor3 = themes[config.theme].highlight
	
	local historyTabBar = Instance.new("Frame", pages.History)
	historyTabBar.Size = UDim2.new(1, 0, 0, 35)
	historyTabBar.BackgroundTransparency = 1
	historyTabBar.ZIndex = 2
	
	historyElements.tabButtons = {}
	for i, tabName in ipairs({"Typed", "Skipped", "Failed"}) do
		local btn = newButton(historyTabBar, tabName)
		btn.Size = UDim2.new(0.32, 0, 1, 0)
		btn.Position = UDim2.new((i-1) * 0.34, 0, 0, 0)
		btn.TextSize = 11
		historyElements.tabButtons[tabName] = btn
	end
	
	historyElements.container = Instance.new("Frame", pages.History)
	historyElements.container.Size = UDim2.new(1, 0, 0, 220)
	historyElements.container.BackgroundColor3 = themes[config.theme].secondary
	historyElements.container.BorderSizePixel = 0
	historyElements.container.ZIndex = 2
	Instance.new("UICorner", historyElements.container).CornerRadius = UDim.new(0, 8)
	local historyStroke = Instance.new("UIStroke", historyElements.container)
	historyStroke.Color = themes[config.theme].accent
	historyStroke.Thickness = 1
	historyStroke.Transparency = 0.7
	
	historyElements.scrollFrame = Instance.new("ScrollingFrame", historyElements.container)
	historyElements.scrollFrame.Size = UDim2.new(1, -8, 1, -8)
	historyElements.scrollFrame.Position = UDim2.new(0, 4, 0, 4)
	historyElements.scrollFrame.BackgroundTransparency = 1
	historyElements.scrollFrame.ScrollBarThickness = 4
	historyElements.scrollFrame.ScrollBarImageColor3 = themes[config.theme].accent
	historyElements.scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	historyElements.scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	historyElements.scrollFrame.BorderSizePixel = 0
	historyElements.scrollFrame.ZIndex = 3
	
	Instance.new("UIListLayout", historyElements.scrollFrame).Padding = UDim.new(0, 4)
	local historyPadding = Instance.new("UIPadding", historyElements.scrollFrame)
	historyPadding.PaddingLeft = UDim.new(0, 4)
	historyPadding.PaddingRight = UDim.new(0, 4)
	historyPadding.PaddingTop = UDim.new(0, 4)
	historyPadding.PaddingBottom = UDim.new(0, 4)
	
	historyElements.pageInfo = newLabel(pages.History, "Page 1", 11)
	historyElements.pageInfo.TextXAlignment = Enum.TextXAlignment.Center
	
	local paginationRow = Instance.new("Frame", pages.History)
	paginationRow.Size = UDim2.new(1, 0, 0, 28)
	paginationRow.BackgroundTransparency = 1
	paginationRow.ZIndex = 2
	historyElements.prevBtn = newButton(paginationRow, "<")
	historyElements.prevBtn.Size = UDim2.new(0.48, 0, 1, 0)
	historyElements.nextBtn = newButton(paginationRow, ">")
	historyElements.nextBtn.Size = UDim2.new(0.48, 0, 1, 0)
	historyElements.nextBtn.Position = UDim2.new(0.52, 0, 0, 0)
end

-- CONFIG PAGE
local configElements = {}
do
	local configTitle = newLabel(pages.Config, "Configuration", 15)
	configTitle.TextXAlignment = Enum.TextXAlignment.Center
	configTitle.TextColor3 = themes[config.theme].highlight
	
	addSpacer(pages.Config, 5)
	
	local saveRow = Instance.new("Frame", pages.Config)
	saveRow.Size = UDim2.new(1, 0, 0, 32)
	saveRow.BackgroundTransparency = 1
	saveRow.ZIndex = 2
	configElements.save = newButton(saveRow, "Save Config")
	configElements.save.Size = UDim2.new(0.48, 0, 1, 0)
	configElements.load = newButton(saveRow, "Load Config")
	configElements.load.Size = UDim2.new(0.48, 0, 1, 0)
	configElements.load.Position = UDim2.new(0.52, 0, 0, 0)
	
	addSpacer(pages.Config, 10)
	
	newLabel(pages.Config, "Theme", 13).Size = UDim2.new(1, 0, 0, 20)
	
	configElements.themeFrame = Instance.new("Frame", pages.Config)
	configElements.themeFrame.Size = UDim2.new(1, 0, 0, 32)
	configElements.themeFrame.BackgroundColor3 = themes[config.theme].secondary
	configElements.themeFrame.BorderSizePixel = 0
	configElements.themeFrame.ZIndex = 2
	Instance.new("UICorner", configElements.themeFrame).CornerRadius = UDim.new(0, 8)
	local themeStroke = Instance.new("UIStroke", configElements.themeFrame)
	themeStroke.Color = themes[config.theme].accent
	themeStroke.Thickness = 1
	themeStroke.Transparency = 0.7
	
	configElements.themeBtn = Instance.new("TextButton", configElements.themeFrame)
	configElements.themeBtn.Size = UDim2.new(1, 0, 1, 0)
	configElements.themeBtn.BackgroundTransparency = 1
	configElements.themeBtn.Text = config.theme
	configElements.themeBtn.TextColor3 = themes[config.theme].text
	configElements.themeBtn.Font = Enum.Font.GothamSemibold
	configElements.themeBtn.TextSize = 13
	configElements.themeBtn.ZIndex = 3
	
	configElements.themeList = Instance.new("ScrollingFrame", gui)
	configElements.themeList.Size = UDim2.new(0, 268, 0, 0)
	configElements.themeList.BackgroundColor3 = themes[config.theme].secondary
	configElements.themeList.BorderSizePixel = 0
	configElements.themeList.Visible = false
	configElements.themeList.ZIndex = 100
	configElements.themeList.ScrollBarThickness = 4
	Instance.new("UICorner", configElements.themeList).CornerRadius = UDim.new(0, 8)
	local themeListStroke = Instance.new("UIStroke", configElements.themeList)
	themeListStroke.Color = themes[config.theme].accent
	themeListStroke.Thickness = 1
	themeListStroke.Transparency = 0.7
	Instance.new("UIListLayout", configElements.themeList).Padding = UDim.new(0, 2)
	
	addSpacer(pages.Config, 5)
	
	newLabel(pages.Config, "Transparency", 13).Size = UDim2.new(1, 0, 0, 20)
	
	configElements.transparencyFrame = Instance.new("Frame", pages.Config)
	configElements.transparencyFrame.Size = UDim2.new(1, 0, 0, 40)
	configElements.transparencyFrame.BackgroundColor3 = themes[config.theme].secondary
	configElements.transparencyFrame.BorderSizePixel = 0
	configElements.transparencyFrame.ZIndex = 2
	Instance.new("UICorner", configElements.transparencyFrame).CornerRadius = UDim.new(0, 8)
	local transStroke = Instance.new("UIStroke", configElements.transparencyFrame)
	transStroke.Color = themes[config.theme].accent
	transStroke.Thickness = 1
	transStroke.Transparency = 0.7
	
	configElements.transparencyBar = Instance.new("Frame", configElements.transparencyFrame)
	configElements.transparencyBar.Size = UDim2.new(0.85, 0, 0, 6)
	configElements.transparencyBar.Position = UDim2.new(0.075, 0, 0.5, -3)
	configElements.transparencyBar.BackgroundColor3 = themes[config.theme].accent
	configElements.transparencyBar.BorderSizePixel = 0
	configElements.transparencyBar.ZIndex = 3
	Instance.new("UICorner", configElements.transparencyBar).CornerRadius = UDim.new(1, 0)
	
	configElements.transparencyHandle = Instance.new("TextButton", configElements.transparencyBar)
	configElements.transparencyHandle.Size = UDim2.new(0, 20, 0, 20)
	configElements.transparencyHandle.Position = UDim2.new(1 - config.transparency, -10, 0.5, -10)
	configElements.transparencyHandle.BackgroundColor3 = themes[config.theme].highlight
	configElements.transparencyHandle.BorderSizePixel = 0
	configElements.transparencyHandle.Text = ""
	configElements.transparencyHandle.ZIndex = 4
	Instance.new("UICorner", configElements.transparencyHandle).CornerRadius = UDim.new(1, 0)
	
	configElements.transparencyValue = newLabel(configElements.transparencyFrame, string.format("%.2f", config.transparency), 11)
	configElements.transparencyValue.Size = UDim2.new(1, 0, 1, 0)
	configElements.transparencyValue.TextXAlignment = Enum.TextXAlignment.Center
	configElements.transparencyValue.TextYAlignment = Enum.TextYAlignment.Center
	configElements.transparencyValue.ZIndex = 3
	
	addSpacer(pages.Config, 5)
	
	local acrylicRow = Instance.new("Frame", pages.Config)
	acrylicRow.Size = UDim2.new(1, 0, 0, 32)
	acrylicRow.BackgroundTransparency = 1
	acrylicRow.ZIndex = 2
	local acrylicLabel = newLabel(acrylicRow, "Acrylic Effect", 12)
	acrylicLabel.Size = UDim2.new(0.55, 0, 1, 0)
	acrylicLabel.TextYAlignment = Enum.TextYAlignment.Center
	configElements.acrylic = newButton(acrylicRow, config.acrylic and "On" or "Off")
	configElements.acrylic.Size = UDim2.new(0.43, 0, 1, 0)
	configElements.acrylic.Position = UDim2.new(0.57, 0, 0, 0)
	
	addSpacer(pages.Config, 10)
	
	configElements.reloadDict = newButton(pages.Config, "Reload Dictionary")
	configElements.reloadDict.Size = UDim2.new(1, 0, 0, 32)
end

-- INFO PAGES
local infoElements = {}
do
	local infoTitle = newLabel(pages.Info, "Definition Search", 15)
	infoTitle.TextXAlignment = Enum.TextXAlignment.Center
	infoTitle.TextColor3 = themes[config.theme].highlight
	
	infoElements.meaningInput = newBox(pages.Info, "Enter word...")
	infoElements.meaningInput.PlaceholderText = "Enter word..."
	
	infoElements.searchBtn = newButton(pages.Info, "Search Definition")
	infoElements.searchBtn.Size = UDim2.new(1, 0, 0, 32)
	
	infoElements.copyBtn = newButton(pages.Info, "Copy Definition")
	infoElements.copyBtn.Size = UDim2.new(1, 0, 0, 32)
	
	local outputFrame = Instance.new("Frame", pages.Info)
	outputFrame.Size = UDim2.new(1, 0, 0, 150)
	outputFrame.BackgroundColor3 = themes[config.theme].secondary
	outputFrame.BorderSizePixel = 0
	outputFrame.ZIndex = 2
	Instance.new("UICorner", outputFrame).CornerRadius = UDim.new(0, 8)
	local outputStroke = Instance.new("UIStroke", outputFrame)
	outputStroke.Color = themes[config.theme].accent
	outputStroke.Thickness = 1
	outputStroke.Transparency = 0.7
	
	infoElements.output = newLabel(outputFrame, "Definition will appear here...", 11)
	infoElements.output.Size = UDim2.new(1, -12, 1, -12)
	infoElements.output.Position = UDim2.new(0, 6, 0, 6)
	infoElements.output.TextWrapped = true
	infoElements.output.TextYAlignment = Enum.TextYAlignment.Top
	infoElements.output.TextXAlignment = Enum.TextXAlignment.Left
	infoElements.output.ZIndex = 3
	
	addSpacer(pages.Info, 10)
	
	local paginationRow = Instance.new("Frame", pages.Info)
	paginationRow.Size = UDim2.new(1, 0, 0, 28)
	paginationRow.BackgroundTransparency = 1
	paginationRow.ZIndex = 2
	infoElements.pageLabel = newLabel(paginationRow, "Page 1/2", 11)
	infoElements.pageLabel.Size = UDim2.new(0.3, 0, 1, 0)
	infoElements.pageLabel.TextXAlignment = Enum.TextXAlignment.Center
	infoElements.pageLabel.TextYAlignment = Enum.TextYAlignment.Center
	infoElements.prevBtn = newButton(paginationRow, "<")
	infoElements.prevBtn.Size = UDim2.new(0.33, 0, 1, 0)
	infoElements.prevBtn.Position = UDim2.new(0.34, 0, 0, 0)
	infoElements.nextBtn = newButton(paginationRow, ">")
	infoElements.nextBtn.Size = UDim2.new(0.33, 0, 1, 0)
	infoElements.nextBtn.Position = UDim2.new(0.67, 0, 0, 0)
	
	-- Info Page 2
	local infoTitle2 = newLabel(infoPage2, "Usage Guide", 14)
	infoTitle2.TextXAlignment = Enum.TextXAlignment.Center
	infoTitle2.TextColor3 = themes[config.theme].highlight
	
	addSpacer(infoPage2, 5)
	
	local guideText = [[
• Auto V1: Basic auto-type with start delay
• Auto V2: Advanced with random/human modes
• More Random: Varies delay each keystroke
• More Human: Simulates natural typing patterns

Human Typing Sections:
- Start (20%): First part of word
- Middle (60%): Main body of word
- End (20%): Final characters

Settings per section:
• Pause %: Chance of longer delay
• Pause x: Multiplier for pause delay
• Flow %: Chance of faster typing
• Flow x: Multiplier for flow speed

Tips:
- Higher pause % = more hesitation
- Lower flow mult = smoother typing
- Adjust per section for realism
- Save configs to preserve settings

Features:
• Anti Dupe: Avoids repeated words
• Ending In: Filter by word endings
• Custom Words: Add your own
• History: Track typed/skipped/failed
• Longest First: Prioritize long words
• Instant Type: No delay typing
• Random Speed: Randomize base delay
]]
	
	local guideLabel = newLabel(infoPage2, guideText, 9)
	guideLabel.TextXAlignment = Enum.TextXAlignment.Left
	guideLabel.TextYAlignment = Enum.TextYAlignment.Top
	guideLabel.Size = UDim2.new(1, 0, 0, 600)
	
	addSpacer(infoPage2, 10)
	
	local paginationRow2 = Instance.new("Frame", infoPage2)
	paginationRow2.Size = UDim2.new(1, 0, 0, 28)
	paginationRow2.BackgroundTransparency = 1
	paginationRow2.ZIndex = 2
	infoElements.pageLabel2 = newLabel(paginationRow2, "Page 2/2", 11)
	infoElements.pageLabel2.Size = UDim2.new(0.3, 0, 1, 0)
	infoElements.pageLabel2.TextXAlignment = Enum.TextXAlignment.Center
	infoElements.pageLabel2.TextYAlignment = Enum.TextYAlignment.Center
	infoElements.prevBtn2 = newButton(paginationRow2, "<")
	infoElements.prevBtn2.Size = UDim2.new(0.33, 0, 1, 0)
	infoElements.prevBtn2.Position = UDim2.new(0.34, 0, 0, 0)
	infoElements.nextBtn2 = newButton(paginationRow2, ">")
	infoElements.nextBtn2.Size = UDim2.new(0.33, 0, 1, 0)
	infoElements.nextBtn2.Position = UDim2.new(0.67, 0, 0, 0)
end

-- THEME SYSTEM
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
			element.BackgroundColor3 = theme.secondary
			local stroke = element:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = theme.accent end
		elseif element:IsA("ScrollingFrame") then
			element.ScrollBarImageColor3 = theme.accent
		end
	end
	
	for _, desc in ipairs(gui:GetDescendants()) do updateElement(desc) end
	wordLabel.TextColor3 = theme.highlight
	title.TextColor3 = theme.highlight
	configElements.themeBtn.Text = themeName
	configElements.transparencyHandle.BackgroundColor3 = theme.highlight
end

-- HISTORY FUNCTIONS
local function addToHistory(word, category)
	if category == "Typed" and not table.find(typedWords, word) then
		table.insert(typedWords, 1, word)
	elseif category == "Skipped" and not table.find(skippedWords, word) then
		table.insert(skippedWords, 1, word)
	elseif category == "Failed" and not table.find(failedWords, word) then
		table.insert(failedWords, 1, word)
	end
end

local function getHistoryList(category)
	if category == "Typed" then return typedWords
	elseif category == "Skipped" then return skippedWords
	elseif category == "Failed" then return failedWords end
	return {}
end

local function sendToChat(message)
	pcall(function() setclipboard(message) end)
	local chatBar = player.PlayerGui:FindFirstChild("Chat")
	if chatBar then
		local chatInput = chatBar:FindFirstChild("Frame", true) and 
			chatBar.Frame:FindFirstChild("ChatBarParentFrame", true) and
			chatBar.Frame.ChatBarParentFrame:FindFirstChild("Frame", true) and
			chatBar.Frame.ChatBarParentFrame.Frame:FindFirstChild("BoxFrame", true) and
			chatBar.Frame.ChatBarParentFrame.Frame.BoxFrame:FindFirstChild("Frame", true) and
			chatBar.Frame.ChatBarParentFrame.Frame.BoxFrame.Frame:FindFirstChild("ChatBar")
		if chatInput and chatInput:IsA("TextBox") then
			chatInput.Text = message
			task.wait(0.05)
			chatInput:CaptureFocus()
		end
	end
end

local function createHistoryItem(word)
	local item = Instance.new("Frame", historyElements.scrollFrame)
	item.Size = UDim2.new(1, 0, 0, 60)
	item.BackgroundColor3 = themes[config.theme].secondary
	item.BorderSizePixel = 0
	item.ZIndex = 4
	Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)
	local itemStroke = Instance.new("UIStroke", item)
	itemStroke.Color = themes[config.theme].accent
	itemStroke.Thickness = 1
	itemStroke.Transparency = 0.8
	
	local wordLbl = Instance.new("TextLabel", item)
	wordLbl.Size = UDim2.new(1, -10, 0, 20)
	wordLbl.Position = UDim2.new(0, 5, 0, 5)
	wordLbl.BackgroundTransparency = 1
	wordLbl.Text = word
	wordLbl.Font = Enum.Font.GothamBold
	wordLbl.TextColor3 = themes[config.theme].highlight
	wordLbl.TextSize = 13
	wordLbl.TextXAlignment = Enum.TextXAlignment.Left
	wordLbl.ZIndex = 5
	
	local btnSize = UDim2.new(0.18, 0, 0, 22)
	local buttons = {
		{name = "BL", pos = 0.02, func = function() blacklist[word] = true end},
		{name = "Fav", pos = 0.21, func = function() favoredWords[word] = true end},
		{name = "Rem", pos = 0.40, func = function() usedWords[word] = nil end},
		{name = "UBL", pos = 0.59, func = function() blacklist[word] = nil end},
		{name = "Chat", pos = 0.78, func = function() sendToChat(word) end}
	}
	
	for _, btnData in ipairs(buttons) do
		local btn = newButton(item, btnData.name)
		btn.Size = btnSize
		btn.Position = UDim2.new(btnData.pos, 0, 0, 30)
		btn.TextSize = 9
		btn.ZIndex = 5
		btn.MouseButton1Click:Connect(function()
			btnData.func()
			btn.Text = "✓"
		end)
	end
end

local function refreshHistoryList()
	for _, child in ipairs(historyElements.scrollFrame:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	local list = getHistoryList(currentHistoryTab)
	local startIdx = (currentHistoryPage - 1) * historyItemsPerPage + 1
	local endIdx = math.min(startIdx + historyItemsPerPage - 1, #list)
	for i = startIdx, endIdx do
		if list[i] then createHistoryItem(list[i]) end
	end
	local totalPages = math.max(1, math.ceil(#list / historyItemsPerPage))
	historyElements.pageInfo.Text = string.format("Page %d / %d", currentHistoryPage, totalPages)
end

-- TYPING LOGIC
local function safeGetKeyboard()
	local ok, overbar = pcall(function() return player.PlayerGui.Overbar end)
	if not ok or not overbar then return nil end
	local fr = overbar:FindFirstChild("Frame")
	if not fr then return nil end
	return fr:FindFirstChild("Keyboard")
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
	for i = 1, typedCount do pressDelete() end
	typedCount = 0
end

local function pressLetter(c)
	local kb = safeGetKeyboard()
	if not kb then return end
	c = c:upper()
	for _, rowName in ipairs({"1","2","3"}) do
		local row = kb:FindFirstChild(rowName)
		if row then
			for _, btn in ipairs(row:GetChildren()) do
				if btn:IsA("TextButton") then
					local t = (btn.Text or ""):upper()
					local n = (btn.Name or ""):upper()
					if t == c or n == c then
						pcall(function() firesignal(btn.MouseButton1Click) end)
						return
					end
				end
			end
		end
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
		local minv, maxv = config.autoDoneMin, config.autoDoneMax
		task.wait(maxv <= minv and minv or (minv + math.random() * (maxv - minv)))
		pressDone()
	end)
end

local function getV2TypeDelay(position, totalLength)
	local minv, maxv = config.autoTypeV2Min, config.autoTypeV2Max
	if maxv <= minv then return minv end
	
	if config.autoTypeV2MoreHuman then
		local baseDelay = minv + math.random() * (maxv - minv)
		local startThreshold = math.ceil(totalLength * 0.20)
		local endThreshold = math.ceil(totalLength * 0.80)
		local pauseChance, pauseMult, flowChance, flowMult
		
		if position <= startThreshold then
			pauseChance, pauseMult = config.humanStartPauseChance, config.humanStartPauseMult
			flowChance, flowMult = config.humanStartFlowChance, config.humanStartFlowMult
		elseif position > endThreshold then
			pauseChance, pauseMult = config.humanEndPauseChance, config.humanEndPauseMult
			flowChance, flowMult = config.humanEndFlowChance, config.humanEndFlowMult
		else
			pauseChance, pauseMult = config.humanMidPauseChance, config.humanMidPauseMult
			flowChance, flowMult = config.humanMidFlowChance, config.humanMidFlowMult
		end
		
		if math.random() < pauseChance then baseDelay = baseDelay * pauseMult end
		if math.random() < flowChance then baseDelay = baseDelay * flowMult end
		return math.clamp(baseDelay, minv, maxv * 2)
	elseif config.autoTypeV2MoreRandom then
		local range = maxv - minv
		local lastDelay = lastV2TypeTimes[#lastV2TypeTimes]
		if lastDelay then
			local newDelay, attempts = nil, 0
			repeat
				newDelay = minv + math.random() * range
				attempts = attempts + 1
			until math.abs(newDelay - lastDelay) > range * 0.15 or attempts > 10
			table.insert(lastV2TypeTimes, newDelay)
			if #lastV2TypeTimes > 5 then table.remove(lastV2TypeTimes, 1) end
			return newDelay
		else
			local delay = minv + math.random() * range
			table.insert(lastV2TypeTimes, delay)
			return delay
		end
	else
		return minv + math.random() * (maxv - minv)
	end
end

local function typeContinuation(full, prefix, useV2Speed)
	if isTypingInProgress then return end
	isTypingInProgress = true
	clearTypedContinuation()
	full, prefix = full:lower(), prefix:lower()
	local start = #prefix + 1
	if start > #full then
		isTypingInProgress = false
		addToHistory(full, "Failed")
		return
	end

	local cont = full:sub(start)
	local totalLength = #cont

	if config.instantType then
		for i = 1, #cont do pressLetter(cont:sub(i,i)) end
		typedCount = #cont
	else
		for i = 1, #cont do
			pressLetter(cont:sub(i,i))
			typedCount = typedCount + 1
			local delay = useV2Speed and getV2TypeDelay(i, totalLength) or 
				(config.randomizeTyping and math.random() * config.typingDelay * 2 or config.typingDelay)
			if delay > 0 then task.wait(delay) end
		end
	end

	isTypingInProgress = false
	addToHistory(full, "Typed")
end

-- AUTO TYPE LOGIC
local function checkInGameAutoCondition()
	local inGame = player.PlayerGui:FindFirstChild("InGame")
	if not inGame then return false end
	local fr = inGame:FindFirstChild("Frame")
	if not fr then return false end
	local typ = fr:FindFirstChild("Type")
	if not typ then return false end
	local txt = tostring(typ.Text or "")
	if txt == "" then return false end
	return string.find(txt, player.Name, 1, true) or 
		(player.DisplayName ~= "" and string.find(txt, player.DisplayName, 1, true))
end

local updateSuggestionFromClosestTable

local function startAutoTypeIfNeeded()
	if not (config.autoType or config.autoTypeV2) or autoTypePending or isTypingInProgress then return end
	if not checkInGameAutoCondition() then return end

	autoTypePending = true
	task.spawn(function()
		if config.startDelay > 0 then task.wait(config.startDelay) end
		updateSuggestionFromClosestTable(true)
		local word = currentMatches[matchIndex]
		if not word or lastPrefix == "" then autoTypePending = false return end
		local remaining = #word - #lastPrefix
		task.wait((remaining <= 3) and (0.5 + math.random()) or (1 + math.random()*0.9))
		if not (config.autoType or config.autoTypeV2) or not checkInGameAutoCondition() then 
			autoTypePending = false return 
		end
		if config.antiDupe and usedWords[word] then autoTypePending = false return end
		typeContinuation(word, lastPrefix, config.autoTypeV2)
		if config.antiDupe then usedWords[word] = true end
		if config.autoDone then schedulePressDone() end
		autoTypePending = false
	end)
end

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
		if isValidPrefix(txt) then return txt:gsub("%s+", ""):lower() end
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
		currentMatches, matchIndex, lastPrefix = {}, 1, ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local bb = tbl:FindFirstChild("Billboard") or tbl:FindFirstChildWhichIsA("Model") or tbl:FindFirstChildWhichIsA("Folder")
	if not bb then
		wordLabel.Text = "Waiting..."
		currentMatches, matchIndex, lastPrefix = {}, 1, ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local guiObj = bb:FindFirstChild("Gui")
	if not guiObj then
		for _, v in ipairs(bb:GetDescendants()) do
			if v.Name == "Gui" then guiObj = v break end
		end
	end
	if not guiObj then guiObj = bb:FindFirstChildOfClass("Folder") or bb:FindFirstChildOfClass("Model") end

	local prefix = extractPrefixFromGui(guiObj)
	if prefix == "" then
		wordLabel.Text = "Waiting..."
		currentMatches, matchIndex, lastPrefix = {}, 1, ""
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	if not forced and prefix == lastPrefix then return end
	autoTypePrefixTime = tick()
	lastPrefix = prefix

	local sug, m = getSuggestion(prefix, longest, config.antiDupe, usedWords, config.minWordLength, config.endingIn)
	currentMatches, matchIndex = m, 1
	wordLabel.Text = sug
	if not isTypingInProgress then clearTypedContinuation() end
	if (config.autoType or config.autoTypeV2) and not forced then startAutoTypeIfNeeded() end
end

-- EVENT HANDLERS
for pageName, btn in pairs(navButtons) do
	btn.MouseButton1Click:Connect(function()
		for name, page in pairs(pages) do page.Visible = (name == pageName) end
		infoPage2.Visible = false
		if pageName == "History" then refreshHistoryList()
		elseif pageName == "Info" then
			currentInfoPage = 1
			pages.Info.Visible = true
			infoPage2.Visible = false
		end
	end)
end

nextButton.MouseButton1Click:Connect(function()
	if #currentMatches > 0 then
		if currentMatches[matchIndex] then addToHistory(currentMatches[matchIndex], "Skipped") end
		matchIndex = matchIndex + 1
		if matchIndex > #currentMatches then matchIndex = 1 end
		wordLabel.Text = currentMatches[matchIndex]
		clearTypedContinuation()
	end
end)

mainButtons.type.MouseButton1Click:Connect(function()
	if #currentMatches == 0 or lastPrefix == "" then return end
	task.spawn(function()
		typeContinuation(currentMatches[matchIndex], lastPrefix, false)
		if config.antiDupe then usedWords[currentMatches[matchIndex]] = true end
		if config.autoDone then schedulePressDone() end
	end)
end)

mainButtons.copy.MouseButton1Click:Connect(function()
	if #currentMatches > 0 then pcall(function() setclipboard(currentMatches[matchIndex]) end) end
end)

mainButtons.forceFind.MouseButton1Click:Connect(function()
	updateSuggestionFromClosestTable(true)
end)

mainButtons.longest.MouseButton1Click:Connect(function()
	longest = not longest
	mainButtons.longest.Text = longest and "On" or "Off"
	if lastPrefix ~= "" then
		local sug, m = getSuggestion(lastPrefix, longest, config.antiDupe, usedWords, config.minWordLength, config.endingIn)
		currentMatches, matchIndex = m, 1
		wordLabel.Text = sug
		clearTypedContinuation()
	end
end)

mainButtons.autoType.MouseButton1Click:Connect(function()
	config.autoType = not config.autoType
	mainButtons.autoType.Text = config.autoType and "Auto V1: On" or "Auto V1: Off"
	if config.autoType and config.autoTypeV2 then
		config.autoTypeV2 = false
		v2Controls.toggle.Text = "Off"
		v2Controls.minMaxRow.Visible = false
		v2Controls.moreRandomRow.Visible = false
		v2Controls.moreHumanRow.Visible = false
		humanSettings.Visible = false
	end
	if not config.autoType then clearTypedContinuation() end
end)

v2Controls.toggle.MouseButton1Click:Connect(function()
	config.autoTypeV2 = not config.autoTypeV2
	v2Controls.toggle.Text = config.autoTypeV2 and "On" or "Off"
	v2Controls.minMaxRow.Visible = config.autoTypeV2
	v2Controls.moreRandomRow.Visible = config.autoTypeV2
	v2Controls.moreHumanRow.Visible = config.autoTypeV2
	if config.autoTypeV2 and config.autoType then
		config.autoType = false
		mainButtons.autoType.Text = "Auto V1: Off"
	end
	if not config.autoTypeV2 then
		clearTypedContinuation()
		humanSettings.Visible = false
	end
end)

v2Controls.minInput.FocusLost:Connect(function()
	local v = tonumber(v2Controls.minInput.Text)
	if v and v >= 0 then config.autoTypeV2Min = v end
	v2Controls.minInput.Text = tostring(config.autoTypeV2Min)
end)

v2Controls.maxInput.FocusLost:Connect(function()
	local v = tonumber(v2Controls.maxInput.Text)
	if v and v >= 0 then config.autoTypeV2Max = v end
	v2Controls.maxInput.Text = tostring(config.autoTypeV2Max)
end)

v2Controls.moreRandom.MouseButton1Click:Connect(function()
	config.autoTypeV2MoreRandom = not config.autoTypeV2MoreRandom
	v2Controls.moreRandom.Text = config.autoTypeV2MoreRandom and "On" or "Off"
	lastV2TypeTimes = {}
	if config.autoTypeV2MoreRandom and config.autoTypeV2MoreHuman then
		config.autoTypeV2MoreHuman = false
		v2Controls.moreHuman.Text = "Off"
		humanSettings.Visible = false
	end
end)

v2Controls.moreHuman.MouseButton1Click:Connect(function()
	config.autoTypeV2MoreHuman = not config.autoTypeV2MoreHuman
	v2Controls.moreHuman.Text = config.autoTypeV2MoreHuman and "On" or "Off"
	humanSettings.Visible = config.autoTypeV2MoreHuman
	if config.autoTypeV2MoreHuman and config.autoTypeV2MoreRandom then
		config.autoTypeV2MoreRandom = false
		v2Controls.moreRandom.Text = "Off"
	end
end)

-- Human typing inputs
for key, input in pairs(humanInputs) do
	input.FocusLost:Connect(function()
		local v = tonumber(input.Text)
		if key:find("Chance") and v and v >= 0 and v <= 100 then
			config["human" .. key:sub(1,1):upper() .. key:sub(2)] = v / 100
		elseif key:find("Mult") and v and v >= 0 then
			config["human" .. key:sub(1,1):upper() .. key:sub(2)] = v
		end
		input.Text = tostring(key:find("Chance") and 
			config["human" .. key:sub(1,1):upper() .. key:sub(2)] * 100 or 
			config["human" .. key:sub(1,1):upper() .. key:sub(2)])
	end)
end

-- Settings inputs
settingsInputs.delay.FocusLost:Connect(function()
	local v = tonumber(settingsInputs.delay.Text)
	if v and v > 0 then config.typingDelay = v end
	settingsInputs.delay.Text = tostring(config.typingDelay)
end)

settingsInputs.startDelay.FocusLost:Connect(function()
	local v = tonumber(settingsInputs.startDelay.Text)
	if v and v >= 0 then config.startDelay = v end
	settingsInputs.startDelay.Text = tostring(config.startDelay)
end)

settingsInputs.randomToggle.MouseButton1Click:Connect(function()
	config.randomizeTyping = not config.randomizeTyping
	settingsInputs.randomToggle.Text = config.randomizeTyping and "On" or "Off"
	if config.randomizeTyping then
		config.instantType = false
		settingsInputs.instant.Text = "Off"
	end
end)

settingsInputs.autoDone.MouseButton1Click:Connect(function()
	config.autoDone = not config.autoDone
	settingsInputs.autoDone.Text = config.autoDone and "On" or "Off"
end)

settingsInputs.doneMin.FocusLost:Connect(function()
	local v = tonumber(settingsInputs.doneMin.Text)
	if v and v >= 0 then config.autoDoneMin = v end
	settingsInputs.doneMin.Text = tostring(config.autoDoneMin)
end)

settingsInputs.doneMax.FocusLost:Connect(function()
	local v = tonumber(settingsInputs.doneMax.Text)
	if v and v >= 0 then config.autoDoneMax = v end
	settingsInputs.doneMax.Text = tostring(config.autoDoneMax)
end)

settingsInputs.antiDupe.MouseButton1Click:Connect(function()
	config.antiDupe = not config.antiDupe
	settingsInputs.antiDupe.Text = config.antiDupe and "On" or "Off"
end)

settingsInputs.minLength.FocusLost:Connect(function()
	local v = tonumber(settingsInputs.minLength.Text)
	if v and v >= 1 then config.minWordLength = math.floor(v) end
	settingsInputs.minLength.Text = tostring(config.minWordLength)
end)

settingsInputs.instant.MouseButton1Click:Connect(function()
	if config.randomizeTyping then return end
	config.instantType = not config.instantType
	settingsInputs.instant.Text = config.instantType and "On" or "Off"
end)

settingsInputs.custom.FocusLost:Connect(function()
	if #settingsInputs.custom.Text > 0 then
		addCustomWords(settingsInputs.custom.Text)
		settingsInputs.custom.Text = ""
	end
end)

settingsInputs.ending.FocusLost:Connect(function()
	config.endingIn = sanitizeEndingInput(settingsInputs.ending.Text)
	settingsInputs.ending.Text = config.endingIn
end)

settingsInputs.reset.MouseButton1Click:Connect(function() usedWords = {} end)

-- History events
for tabName, btn in pairs(historyElements.tabButtons) do
	btn.MouseButton1Click:Connect(function()
		currentHistoryTab = tabName
		currentHistoryPage = 1
		refreshHistoryList()
	end)
end

historyElements.prevBtn.MouseButton1Click:Connect(function()
	if currentHistoryPage > 1 then
		currentHistoryPage = currentHistoryPage - 1
		refreshHistoryList()
	end
end)

historyElements.nextBtn.MouseButton1Click:Connect(function()
	local list = getHistoryList(currentHistoryTab)
	local totalPages = math.ceil(#list / historyItemsPerPage)
	if currentHistoryPage < totalPages then
		currentHistoryPage = currentHistoryPage + 1
		refreshHistoryList()
	end
end)

-- Config events
configElements.themeBtn.MouseButton1Click:Connect(function()
	themeDropdownExpanded = not themeDropdownExpanded
	if themeDropdownExpanded then
		local absPos = configElements.themeFrame.AbsolutePosition
		configElements.themeList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 35)
		configElements.themeList.Visible = true
		for _, child in ipairs(configElements.themeList:GetChildren()) do
			if child:IsA("TextButton") then child:Destroy() end
		end
		local count = 0
		for _ in pairs(themes) do count = count + 1 end
		configElements.themeList.Size = UDim2.new(0, 268, 0, count * 32)
		configElements.themeList.CanvasSize = UDim2.new(0, 0, 0, count * 32)
		for themeName in pairs(themes) do
			local opt = Instance.new("TextButton", configElements.themeList)
			opt.Size = UDim2.new(1, -8, 0, 30)
			opt.BackgroundColor3 = themes[config.theme].secondary
			opt.TextColor3 = themes[config.theme].text
			opt.Text = themeName
			opt.Font = Enum.Font.GothamSemibold
			opt.TextSize = 12
			opt.BorderSizePixel = 0
			opt.ZIndex = 101
			Instance.new("UICorner", opt).CornerRadius = UDim.new(0, 6)
			opt.MouseButton1Click:Connect(function()
				applyTheme(themeName)
				themeDropdownExpanded = false
				configElements.themeList.Visible = false
			end)
		end
	else
		configElements.themeList.Visible = false
	end
end)

configElements.transparencyHandle.MouseButton1Down:Connect(function() draggingTransparency = true end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingTransparency = false end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingTransparency and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UserInputService:GetMouseLocation()
		local barPos = configElements.transparencyBar.AbsolutePosition
		local barSize = configElements.transparencyBar.AbsoluteSize
		local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
		config.transparency = 1 - relativeX
		frame.BackgroundTransparency = config.transparency
		configElements.transparencyHandle.Position = UDim2.new(relativeX, -10, 0.5, -10)
		configElements.transparencyValue.Text = string.format("%.2f", config.transparency)
	end
end)

configElements.acrylic.MouseButton1Click:Connect(function()
	config.acrylic = not config.acrylic
	configElements.acrylic.Text = config.acrylic and "On" or "Off"
	if config.acrylic then
		if not acrylicBlur then
			acrylicBlur = Instance.new("BlurEffect")
			acrylicBlur.Size = 24
			acrylicBlur.Name = "WordHelperAcrylicBlur"
			acrylicBlur.Parent = frame
		end
		acrylicBlur.Enabled = true
	else
		if acrylicBlur then acrylicBlur.Enabled = false end
	end
end)

configElements.reloadDict.MouseButton1Click:Connect(loadDictionaries)

-- Save/Load config
local function toHex(str)
	return (str:gsub('.', function (c) return string.format('%02X', string.byte(c)) end))
end

local function fromHex(str)
	return (str:gsub('..', function (cc) return string.char(tonumber(cc, 16)) end))
end

configElements.save.MouseButton1Click:Connect(function()
	local saveData = {}
	for k, v in pairs(config) do saveData[k] = v end
	saveData.longest_setting = longest
	pcall(function() writefile("WordHelperConfig.txt", toHex(HttpService:JSONEncode(saveData))) end)
	configElements.save.Text = "Saved!"
	task.delay(1, function() configElements.save.Text = "Save Config" end)
end)

configElements.load.MouseButton1Click:Connect(function()
	local success, result = pcall(function() return readfile("WordHelperConfig.txt") end)
	if success and result then
		local decoded
		pcall(function() decoded = HttpService:JSONDecode(fromHex(result)) end)
		if decoded and type(decoded) == "table" then
			for k, v in pairs(decoded) do
				if k == "longest_setting" then longest = v
				elseif config[k] ~= nil then config[k] = v end
			end
			-- Update all UI elements with loaded values
			settingsInputs.delay.Text = tostring(config.typingDelay)
			settingsInputs.startDelay.Text = tostring(config.startDelay)
			settingsInputs.randomToggle.Text = config.randomizeTyping and "On" or "Off"
			settingsInputs.autoDone.Text = config.autoDone and "On" or "Off"
			settingsInputs.doneMin.Text = tostring(config.autoDoneMin)
			settingsInputs.doneMax.Text = tostring(config.autoDoneMax)
			settingsInputs.antiDupe.Text = config.antiDupe and "On" or "Off"
			settingsInputs.minLength.Text = tostring(config.minWordLength)
			settingsInputs.instant.Text = config.instantType and "On" or "Off"
			settingsInputs.ending.Text = config.endingIn
			mainButtons.autoType.Text = config.autoType and "Auto V1: On" or "Auto V1: Off"
			v2Controls.toggle.Text = config.autoTypeV2 and "On" or "Off"
			v2Controls.minInput.Text = tostring(config.autoTypeV2Min)
			v2Controls.maxInput.Text = tostring(config.autoTypeV2Max)
			v2Controls.moreRandom.Text = config.autoTypeV2MoreRandom and "On" or "Off"
			v2Controls.moreHuman.Text = config.autoTypeV2MoreHuman and "On" or "Off"
			mainButtons.longest.Text = longest and "On" or "Off"
			v2Controls.minMaxRow.Visible = config.autoTypeV2
			v2Controls.moreRandomRow.Visible = config.autoTypeV2
			v2Controls.moreHumanRow.Visible = config.autoTypeV2
			humanSettings.Visible = config.autoTypeV2MoreHuman
			configElements.acrylic.Text = config.acrylic and "On" or "Off"
			-- Update human typing inputs
			for key, input in pairs(humanInputs) do
				input.Text = tostring(key:find("Chance") and 
					config["human" .. key:sub(1,1):upper() .. key:sub(2)] * 100 or 
					config["human" .. key:sub(1,1):upper() .. key:sub(2)])
			end
			applyTheme(config.theme)
			frame.BackgroundTransparency = config.transparency
			configElements.transparencyHandle.Position = UDim2.new(1 - config.transparency, -10, 0.5, -10)
			configElements.transparencyValue.Text = string.format("%.2f", config.transparency)
			if config.acrylic then
				if not acrylicBlur then
					acrylicBlur = Instance.new("BlurEffect")
					acrylicBlur.Size = 24
					acrylicBlur.Name = "WordHelperAcrylicBlur"
					acrylicBlur.Parent = frame
				end
				acrylicBlur.Enabled = true
			else
				if acrylicBlur then acrylicBlur.Enabled = false end
			end
			configElements.load.Text = "Loaded!"
			task.delay(1, function() configElements.load.Text = "Load Config" end)
		else
			configElements.load.Text = "Fail"
			task.delay(1, function() configElements.load.Text = "Load Config" end)
		end
	else
		configElements.load.Text = "No File"
		task.delay(1, function() configElements.load.Text = "Load Config" end)
	end
end)

-- Info page events
local function fetchMeaning(wordRaw)
	local w = wordRaw:gsub("%s+", ""):lower()
	if #w == 0 then infoElements.output.Text = "Please enter a valid word." return end
	infoElements.output.Text = "Searching..."
	task.spawn(function()
		local success, res = pcall(function() return game:HttpGet("https://api.dictionaryapi.dev/api/v2/entries/en/" .. w) end)
		if success then
			local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
			if ok and type(data) == "table" and data[1] and data[1].meanings then
				infoElements.output.Text = data[1].meanings[1].definitions[1].definition
				return
			end
		end
		infoElements.output.Text = "No definition found."
	end)
end

infoElements.searchBtn.MouseButton1Click:Connect(function() fetchMeaning(infoElements.meaningInput.Text) end)
infoElements.copyBtn.MouseButton1Click:Connect(function() pcall(function() setclipboard(infoElements.output.Text) end) end)

local function updateInfoPage(pageNum)
	currentInfoPage = pageNum
	pages.Info.Visible = (pageNum == 1)
	infoPage2.Visible = (pageNum == 2)
end

infoElements.prevBtn.MouseButton1Click:Connect(function()
	if currentInfoPage > 1 then updateInfoPage(currentInfoPage - 1) end
end)

infoElements.nextBtn.MouseButton1Click:Connect(function()
	if currentInfoPage < 2 then updateInfoPage(currentInfoPage + 1) end
end)

infoElements.prevBtn2.MouseButton1Click:Connect(function()
	if currentInfoPage > 1 then updateInfoPage(currentInfoPage - 1) end
end)

infoElements.nextBtn2.MouseButton1Click:Connect(function()
	if currentInfoPage < 2 then updateInfoPage(currentInfoPage + 1) end
end)

-- Keyboard shortcut
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode ~= Enum.KeyCode.T then return end
	if #currentMatches == 0 or lastPrefix == "" or isTypingInProgress then return end
	local word = currentMatches[matchIndex]
	if config.antiDupe and usedWords[word] then return end
	task.spawn(function()
		typeContinuation(word, lastPrefix, false)
		if config.antiDupe then usedWords[word] = true end
		if config.autoDone then schedulePressDone() end
	end)
end)

-- Main update loop
RunService.RenderStepped:Connect(function()
	local now = tick()
	if now - lastUpdate >= updateInterval then
		lastUpdate = now
		updateSuggestionFromClosestTable()
	end
	if (config.autoType or config.autoTypeV2) and not autoTypePending and checkInGameAutoCondition() then
		startAutoTypeIfNeeded()
	end
end)

-- Initialize
loadDictionaries()
print("Word Helper Pro - Fully Loaded!")
