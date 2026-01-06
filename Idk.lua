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

-- History Storage
local typedWords = {}
local skippedWords = {}
local failedWords = {}
local favoredWords = {}

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
	autoTypeV2MoreRandom = false,
	autoTypeV2MoreHuman = false,
	-- Enhanced Human Typing Settings
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
	
	local favoredMatches = {}
	local normalMatches = {}
	for i = 1, #m do
		if favoredWords[m[i]] then
			table.insert(favoredMatches, m[i])
		else
			table.insert(normalMatches, m[i])
		end
	end
	
	table.sort(favoredMatches, function(a,b)
		if #a == #b then return a < b end
		if longest then return #a > #b else return #a < #b end
	end)
	
	table.sort(normalMatches, function(a,b)
		if #a == #b then return a < b end
		if longest then return #a > #b else return #a < #b end
	end)
	
	local combined = {}
	for i = 1, #favoredMatches do
		table.insert(combined, favoredMatches[i])
	end
	for i = 1, #normalMatches do
		table.insert(combined, normalMatches[i])
	end
	
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
-- GUI CREATION (MODERN REDESIGN)
-- ==========================================

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

-- Acrylic blur container (fixed to not blur full screen)
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
	
	local corner = Instance.new("UICorner", b)
	corner.CornerRadius = UDim.new(0, 8)
	
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
local navButtonNames = {"Main", "Settings", "History", "Config", "Info"}
local buttonWidth = 0.18

for i, name in ipairs(navButtonNames) do
	local btn = newButton(topBar, name)
	btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
	btn.Position = UDim2.new((i-1) * (buttonWidth + 0.01) + 0.01, 0, 0, 0)
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
	
	local layout = Instance.new("UIListLayout", pg)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	
	local pad = Instance.new("UIPadding", pg)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingTop = UDim.new(0, 6)
	
	return pg
end

local mainPage = createPage()
mainPage.Visible = true
local settingsPage = createPage()
local historyPage = createPage()
local configPage = createPage()
local infoPage = createPage()
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
	
	local corner = Instance.new("UICorner", b)
	corner.CornerRadius = UDim.new(0, 8)
	
	local stroke = Instance.new("UIStroke", b)
	stroke.Color = themes[config.theme].accent
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	
	return b
end

-- ==========================================
-- MAIN PAGE UI (REDESIGNED)
-- ==========================================

local title = newLabel(mainPage, "Word Helper Pro", 16)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextColor3 = themes[config.theme].highlight

local wordLabel = Instance.new("TextLabel", mainPage)
wordLabel.Size = UDim2.new(1, 0, 0, 45)
wordLabel.BackgroundColor3 = themes[config.theme].secondary
wordLabel.TextColor3 = themes[config.theme].highlight
wordLabel.Font = Enum.Font.GothamBold
wordLabel.TextSize = 18
wordLabel.Text = "Waiting..."
wordLabel.BorderSizePixel = 0
wordLabel.ZIndex = 2

local wordCorner = Instance.new("UICorner", wordLabel)
wordCorner.CornerRadius = UDim.new(0, 10)

local wordStroke = Instance.new("UIStroke", wordLabel)
wordStroke.Color = themes[config.theme].accent
wordStroke.Thickness = 2
wordStroke.Transparency = 0.5

updateStatusLabel = function(txt)
	wordLabel.Text = txt
end

local nextButton = newButton(mainPage, "Next Word")
nextButton.Size = UDim2.new(1, 0, 0, 32)

local row1 = Instance.new("Frame", mainPage)
row1.Size = UDim2.new(1, 0, 0, 32)
row1.BackgroundTransparency = 1
row1.ZIndex = 2
local typeButton = newButton(row1, "Type")
typeButton.Size = UDim2.new(0.48, 0, 1, 0)
local autoTypeButton = newButton(row1, "Auto V1: Off")
autoTypeButton.Position = UDim2.new(0.52, 0, 0, 0)
autoTypeButton.Size = UDim2.new(0.48, 0, 1, 0)

local row2 = Instance.new("Frame", mainPage)
row2.Size = UDim2.new(1, 0, 0, 32)
row2.BackgroundTransparency = 1
row2.ZIndex = 2
local copyButton = newButton(row2, "Copy")
copyButton.Size = UDim2.new(0.48, 0, 1, 0)
local forceFindButton = newButton(row2, "Force Find")
forceFindButton.Position = UDim2.new(0.52, 0, 0, 0)
forceFindButton.Size = UDim2.new(0.48, 0, 1, 0)

local row3 = Instance.new("Frame", mainPage)
row3.Size = UDim2.new(1, 0, 0, 32)
row3.BackgroundTransparency = 1
row3.ZIndex = 2
local longestLabel = newLabel(row3, "Longest First", 13)
longestLabel.Size = UDim2.new(0.5, 0, 1, 0)
longestLabel.TextYAlignment = Enum.TextYAlignment.Center
local longestToggle = newButton(row3, "Off")
longestToggle.Size = UDim2.new(0.48, 0, 1, 0)
longestToggle.Position = UDim2.new(0.52, 0, 0, 0)

local autoTypeV2Row = Instance.new("Frame", mainPage)
autoTypeV2Row.Size = UDim2.new(1, 0, 0, 32)
autoTypeV2Row.BackgroundTransparency = 1
autoTypeV2Row.ZIndex = 2
local autoTypeV2Label = newLabel(autoTypeV2Row, "Auto Type V2", 13)
autoTypeV2Label.Size = UDim2.new(0.5, 0, 1, 0)
autoTypeV2Label.TextYAlignment = Enum.TextYAlignment.Center
local autoTypeV2Toggle = newButton(autoTypeV2Row, "Off")
autoTypeV2Toggle.Size = UDim2.new(0.48, 0, 1, 0)
autoTypeV2Toggle.Position = UDim2.new(0.52, 0, 0, 0)

local v2MinMaxRow = Instance.new("Frame", mainPage)
v2MinMaxRow.Size = UDim2.new(1, 0, 0, 32)
v2MinMaxRow.BackgroundTransparency = 1
v2MinMaxRow.Visible = false
v2MinMaxRow.ZIndex = 2
local v2mml = newLabel(v2MinMaxRow, "V2 Min/Max", 12)
v2mml.Size = UDim2.new(0.38, 0, 1, 0)
v2mml.TextYAlignment = Enum.TextYAlignment.Center
local v2MinInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Min), 32)
v2MinInput.Size = UDim2.new(0.28, 0, 1, 0)
v2MinInput.Position = UDim2.new(0.40, 0, 0, 0)
local v2MaxInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Max), 32)
v2MaxInput.Size = UDim2.new(0.28, 0, 1, 0)
v2MaxInput.Position = UDim2.new(0.70, 0, 0, 0)

local v2MoreRandomRow = Instance.new("Frame", mainPage)
v2MoreRandomRow.Size = UDim2.new(1, 0, 0, 32)
v2MoreRandomRow.BackgroundTransparency = 1
v2MoreRandomRow.Visible = false
v2MoreRandomRow.ZIndex = 2
local v2mrl = newLabel(v2MoreRandomRow, "More Random", 12)
v2mrl.Size = UDim2.new(0.5, 0, 1, 0)
v2mrl.TextYAlignment = Enum.TextYAlignment.Center
local v2MoreRandomToggle = newButton(v2MoreRandomRow, "Off")
v2MoreRandomToggle.Size = UDim2.new(0.48, 0, 1, 0)
v2MoreRandomToggle.Position = UDim2.new(0.52, 0, 0, 0)

local v2MoreHumanRow = Instance.new("Frame", mainPage)
v2MoreHumanRow.Size = UDim2.new(1, 0, 0, 32)
v2MoreHumanRow.BackgroundTransparency = 1
v2MoreHumanRow.Visible = false
v2MoreHumanRow.ZIndex = 2
local v2mhl = newLabel(v2MoreHumanRow, "More Human", 12)
v2mhl.Size = UDim2.new(0.5, 0, 1, 0)
v2mhl.TextYAlignment = Enum.TextYAlignment.Center
local v2MoreHumanToggle = newButton(v2MoreHumanRow, "Off")
v2MoreHumanToggle.Size = UDim2.new(0.48, 0, 1, 0)
v2MoreHumanToggle.Position = UDim2.new(0.52, 0, 0, 0)

-- Enhanced Human Typing Settings Container
local humanSettingsContainer = Instance.new("Frame", mainPage)
humanSettingsContainer.BackgroundTransparency = 1
humanSettingsContainer.Visible = false
humanSettingsContainer.ZIndex = 2
humanSettingsContainer.Size = UDim2.new(1, 0, 0, 0)
humanSettingsContainer.AutomaticSize = Enum.AutomaticSize.Y

local humanLayout = Instance.new("UIListLayout", humanSettingsContainer)
humanLayout.SortOrder = Enum.SortOrder.LayoutOrder
humanLayout.Padding = UDim.new(0, 6)

-- Helper function to create compact setting rows
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
	
	return row, input1, input2
end

-- Section labels
local startSectionLabel = newLabel(humanSettingsContainer, "Start (20%)", 10)
startSectionLabel.Size = UDim2.new(1, 0, 0, 18)
startSectionLabel.TextColor3 = themes[config.theme].accent

local startPauseRow, startPauseChanceInput, startPauseMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Pause %/x", 
	config.humanStartPauseChance * 100, 
	config.humanStartPauseMult
)

local startFlowRow, startFlowChanceInput, startFlowMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Flow %/x", 
	config.humanStartFlowChance * 100, 
	config.humanStartFlowMult
)

addSpacer(humanSettingsContainer, 4)

local midSectionLabel = newLabel(humanSettingsContainer, "Middle (60%)", 10)
midSectionLabel.Size = UDim2.new(1, 0, 0, 18)
midSectionLabel.TextColor3 = themes[config.theme].accent

local midPauseRow, midPauseChanceInput, midPauseMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Pause %/x", 
	config.humanMidPauseChance * 100, 
	config.humanMidPauseMult
)

local midFlowRow, midFlowChanceInput, midFlowMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Flow %/x", 
	config.humanMidFlowChance * 100, 
	config.humanMidFlowMult
)

addSpacer(humanSettingsContainer, 4)

local endSectionLabel = newLabel(humanSettingsContainer, "End (20%)", 10)
endSectionLabel.Size = UDim2.new(1, 0, 0, 18)
endSectionLabel.TextColor3 = themes[config.theme].accent

local endPauseRow, endPauseChanceInput, endPauseMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Pause %/x", 
	config.humanEndPauseChance * 100, 
	config.humanEndPauseMult
)

local endFlowRow, endFlowChanceInput, endFlowMultInput = createCompactSettingRow(
	humanSettingsContainer, 
	"Flow %/x", 
	config.humanEndFlowChance * 100, 
	config.humanEndFlowMult
)

-- ==========================================
-- SETTINGS PAGE UI (REDESIGNED)
-- ==========================================

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

createSettingRow(settingsPage, "Typing Delay", newBox(nil, tostring(config.typingDelay)))
local delayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "Start Delay", newBox(nil, tostring(config.startDelay)))
local startDelayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

local randomRow = Instance.new("Frame", settingsPage)
randomRow.Size = UDim2.new(1, 0, 0, 32)
randomRow.BackgroundTransparency = 1
randomRow.ZIndex = 2
local rl = newLabel(randomRow, "Random Speed", 12)
rl.Size = UDim2.new(0.55, 0, 1, 0)
rl.TextYAlignment = Enum.TextYAlignment.Center
local randomToggleButton = newButton(randomRow, "Off")
randomToggleButton.Size = UDim2.new(0.43, 0, 1, 0)
randomToggleButton.Position = UDim2.new(0.57, 0, 0, 0)

local autoDoneRow = Instance.new("Frame", settingsPage)
autoDoneRow.Size = UDim2.new(1, 0, 0, 32)
autoDoneRow.BackgroundTransparency = 1
autoDoneRow.ZIndex = 2
local adl = newLabel(autoDoneRow, "Auto Done", 12)
adl.Size = UDim2.new(0.55, 0, 1, 0)
adl.TextYAlignment = Enum.TextYAlignment.Center
local autoDoneButton = newButton(autoDoneRow, "On")
autoDoneButton.Size = UDim2.new(0.43, 0, 1, 0)
autoDoneButton.Position = UDim2.new(0.57, 0, 0, 0)

local minMaxRow = Instance.new("Frame", settingsPage)
minMaxRow.Size = UDim2.new(1, 0, 0, 32)
minMaxRow.BackgroundTransparency = 1
minMaxRow.ZIndex = 2
local mml = newLabel(minMaxRow, "Done Min/Max", 12)
mml.Size = UDim2.new(0.38, 0, 1, 0)
mml.TextYAlignment = Enum.TextYAlignment.Center
local minInput = newBox(minMaxRow, tostring(config.autoDoneMin))
minInput.Size = UDim2.new(0.28, 0, 1, 0)
minInput.Position = UDim2.new(0.40, 0, 0, 0)
local maxInput = newBox(minMaxRow, tostring(config.autoDoneMax))
maxInput.Size = UDim2.new(0.28, 0, 1, 0)
maxInput.Position = UDim2.new(0.70, 0, 0, 0)

local antiDupeRow = Instance.new("Frame", settingsPage)
antiDupeRow.Size = UDim2.new(1, 0, 0, 32)
antiDupeRow.BackgroundTransparency = 1
antiDupeRow.ZIndex = 2
local adl2 = newLabel(antiDupeRow, "Anti Dupe", 12)
adl2.Size = UDim2.new(0.55, 0, 1, 0)
adl2.TextYAlignment = Enum.TextYAlignment.Center
local antiDupeToggle = newButton(antiDupeRow, "Off")
antiDupeToggle.Size = UDim2.new(0.43, 0, 1, 0)
antiDupeToggle.Position = UDim2.new(0.57, 0, 0, 0)

createSettingRow(settingsPage, "Min Length", newBox(nil, tostring(config.minWordLength)))
local shortInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

local instantRow = Instance.new("Frame", settingsPage)
instantRow.Size = UDim2.new(1, 0, 0, 32)
instantRow.BackgroundTransparency = 1
instantRow.ZIndex = 2
local il = newLabel(instantRow, "Instant Type", 12)
il.Size = UDim2.new(0.55, 0, 1, 0)
il.TextYAlignment = Enum.TextYAlignment.Center
local instantToggle = newButton(instantRow, "Off")
instantToggle.Size = UDim2.new(0.43, 0, 1, 0)
instantToggle.Position = UDim2.new(0.57, 0, 0, 0)

createSettingRow(settingsPage, "Custom Words", newBox(nil, ""))
local customInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "End In (1-2)", newBox(nil, ""))
local endingInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

addSpacer(settingsPage, 10)

local resetButton = newButton(settingsPage, "Reset Used Words")
resetButton.Size = UDim2.new(1, 0, 0, 32)

-- ==========================================
-- HISTORY PAGE UI (NEW)
-- ==========================================

local historyTitle = newLabel(historyPage, "Word History", 15)
historyTitle.TextXAlignment = Enum.TextXAlignment.Center
historyTitle.TextColor3 = themes[config.theme].highlight

local historyTabBar = Instance.new("Frame", historyPage)
historyTabBar.Size = UDim2.new(1, 0, 0, 35)
historyTabBar.BackgroundTransparency = 1
historyTabBar.ZIndex = 2

local historyTabs = {"Typed", "Skipped", "Failed"}
local historyTabButtons = {}
local currentHistoryTab = "Typed"

for i, tabName in ipairs(historyTabs) do
	local btn = newButton(historyTabBar, tabName)
	btn.Size = UDim2.new(0.32, 0, 1, 0)
	btn.Position = UDim2.new((i-1) * 0.34, 0, 0, 0)
	btn.TextSize = 11
	historyTabButtons[tabName] = btn
end

local historyListContainer = Instance.new("Frame", historyPage)
historyListContainer.Size = UDim2.new(1, 0, 0, 220)
historyListContainer.BackgroundColor3 = themes[config.theme].secondary
historyListContainer.BorderSizePixel = 0
historyListContainer.ZIndex = 2

local historyListCorner = Instance.new("UICorner", historyListContainer)
historyListCorner.CornerRadius = UDim.new(0, 8)

local historyListStroke = Instance.new("UIStroke", historyListContainer)
historyListStroke.Color = themes[config.theme].accent
historyListStroke.Thickness = 1
historyListStroke.Transparency = 0.7

local historyScrollFrame = Instance.new("ScrollingFrame", historyListContainer)
historyScrollFrame.Size = UDim2.new(1, -8, 1, -8)
historyScrollFrame.Position = UDim2.new(0, 4, 0, 4)
historyScrollFrame.BackgroundTransparency = 1
historyScrollFrame.ScrollBarThickness = 4
historyScrollFrame.ScrollBarImageColor3 = themes[config.theme].accent
historyScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
historyScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
historyScrollFrame.BorderSizePixel = 0
historyScrollFrame.ZIndex = 3

local historyLayout = Instance.new("UIListLayout", historyScrollFrame)
historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
historyLayout.Padding = UDim.new(0, 4)

local historyPadding = Instance.new("UIPadding", historyScrollFrame)
historyPadding.PaddingLeft = UDim.new(0, 4)
historyPadding.PaddingRight = UDim.new(0, 4)
historyPadding.PaddingTop = UDim.new(0, 4)
historyPadding.PaddingBottom = UDim.new(0, 4)

local historyPageInfo = newLabel(historyPage, "Page 1", 11)
historyPageInfo.TextXAlignment = Enum.TextXAlignment.Center

local historyPaginationRow = Instance.new("Frame", historyPage)
historyPaginationRow.Size = UDim2.new(1, 0, 0, 28)
historyPaginationRow.BackgroundTransparency = 1
historyPaginationRow.ZIndex = 2

local historyPrevButton = newButton(historyPaginationRow, "<")
historyPrevButton.Size = UDim2.new(0.48, 0, 1, 0)
historyPrevButton.Position = UDim2.new(0, 0, 0, 0)

local historyNextButton = newButton(historyPaginationRow, ">")
historyNextButton.Size = UDim2.new(0.48, 0, 1, 0)
historyNextButton.Position = UDim2.new(0.52, 0, 0, 0)

local currentHistoryPage = 1
local historyItemsPerPage = 10

-- ==========================================
-- CONFIG PAGE UI (NEW)
-- ==========================================

local configTitle = newLabel(configPage, "Configuration", 15)
configTitle.TextXAlignment = Enum.TextXAlignment.Center
configTitle.TextColor3 = themes[config.theme].highlight

addSpacer(configPage, 5)

local saveRow = Instance.new("Frame", configPage)
saveRow.Size = UDim2.new(1, 0, 0, 32)
saveRow.BackgroundTransparency = 1
saveRow.ZIndex = 2
local saveConfigButton = newButton(saveRow, "Save Config")
saveConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
local loadConfigButton = newButton(saveRow, "Load Config")
loadConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
loadConfigButton.Position = UDim2.new(0.52, 0, 0, 0)

addSpacer(configPage, 10)

local themeLabel = newLabel(configPage, "Theme", 13)
themeLabel.Size = UDim2.new(1, 0, 0, 20)

local themeDropdownFrame = Instance.new("Frame", configPage)
themeDropdownFrame.Size = UDim2.new(1, 0, 0, 32)
themeDropdownFrame.BackgroundColor3 = themes[config.theme].secondary
themeDropdownFrame.BorderSizePixel = 0
themeDropdownFrame.ZIndex = 2

local themeDropdownCorner = Instance.new("UICorner", themeDropdownFrame)
themeDropdownCorner.CornerRadius = UDim.new(0, 8)

local themeDropdownStroke = Instance.new("UIStroke", themeDropdownFrame)
themeDropdownStroke.Color = themes[config.theme].accent
themeDropdownStroke.Thickness = 1
themeDropdownStroke.Transparency = 0.7

local themeDropdownButton = Instance.new("TextButton", themeDropdownFrame)
themeDropdownButton.Size = UDim2.new(1, 0, 1, 0)
themeDropdownButton.BackgroundTransparency = 1
themeDropdownButton.Text = config.theme
themeDropdownButton.TextColor3 = themes[config.theme].text
themeDropdownButton.Font = Enum.Font.GothamSemibold
themeDropdownButton.TextSize = 13
themeDropdownButton.ZIndex = 3

local themeDropdownExpanded = false
local themeDropdownList = Instance.new("ScrollingFrame", gui)
themeDropdownList.Size = UDim2.new(0, 268, 0, 0)
themeDropdownList.Position = themeDropdownFrame.Position
themeDropdownList.BackgroundColor3 = themes[config.theme].secondary
themeDropdownList.BorderSizePixel = 0
themeDropdownList.Visible = false
themeDropdownList.ZIndex = 100
themeDropdownList.ScrollBarThickness = 4

local themeDropdownListCorner = Instance.new("UICorner", themeDropdownList)
themeDropdownListCorner.CornerRadius = UDim.new(0, 8)

local themeDropdownListStroke = Instance.new("UIStroke", themeDropdownList)
themeDropdownListStroke.Color = themes[config.theme].accent
themeDropdownListStroke.Thickness = 1
themeDropdownListStroke.Transparency = 0.7

local themeDropdownLayout = Instance.new("UIListLayout", themeDropdownList)
themeDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeDropdownLayout.Padding = UDim.new(0, 2)

addSpacer(configPage, 5)

local transparencyLabel = newLabel(configPage, "Transparency", 13)
transparencyLabel.Size = UDim2.new(1, 0, 0, 20)

local transparencySliderFrame = Instance.new("Frame", configPage)
transparencySliderFrame.Size = UDim2.new(1, 0, 0, 40)
transparencySliderFrame.BackgroundColor3 = themes[config.theme].secondary
transparencySliderFrame.BorderSizePixel = 0
transparencySliderFrame.ZIndex = 2

local transparencySliderCorner = Instance.new("UICorner", transparencySliderFrame)
transparencySliderCorner.CornerRadius = UDim.new(0, 8)

local transparencySliderStroke = Instance.new("UIStroke", transparencySliderFrame)
transparencySliderStroke.Color = themes[config.theme].accent
transparencySliderStroke.Thickness = 1
transparencySliderStroke.Transparency = 0.7

local transparencySliderBar = Instance.new("Frame", transparencySliderFrame)
transparencySliderBar.Size = UDim2.new(0.85, 0, 0, 6)
transparencySliderBar.Position = UDim2.new(0.075, 0, 0.5, -3)
transparencySliderBar.BackgroundColor3 = themes[config.theme].accent
transparencySliderBar.BorderSizePixel = 0
transparencySliderBar.ZIndex = 3

local transparencySliderBarCorner = Instance.new("UICorner", transparencySliderBar)
transparencySliderBarCorner.CornerRadius = UDim.new(1, 0)

local transparencySliderHandle = Instance.new("TextButton", transparencySliderBar)
transparencySliderHandle.Size = UDim2.new(0, 20, 0, 20)
transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -10, 0.5, -10)
transparencySliderHandle.BackgroundColor3 = themes[config.theme].highlight
transparencySliderHandle.BorderSizePixel = 0
transparencySliderHandle.Text = ""
transparencySliderHandle.ZIndex = 4

local transparencySliderHandleCorner = Instance.new("UICorner", transparencySliderHandle)
transparencySliderHandleCorner.CornerRadius = UDim.new(1, 0)

local transparencyValueLabel = newLabel(transparencySliderFrame, string.format("%.2f", config.transparency), 11)
transparencyValueLabel.Size = UDim2.new(1, 0, 1, 0)
transparencyValueLabel.TextXAlignment = Enum.TextXAlignment.Center
transparencyValueLabel.TextYAlignment = Enum.TextYAlignment.Center
transparencyValueLabel.ZIndex = 3

addSpacer(configPage, 5)

local acrylicRow = Instance.new("Frame", configPage)
acrylicRow.Size = UDim2.new(1, 0, 0, 32)
acrylicRow.BackgroundTransparency = 1
acrylicRow.ZIndex = 2
local acrylicLabel = newLabel(acrylicRow, "Acrylic Effect", 12)
acrylicLabel.Size = UDim2.new(0.55, 0, 1, 0)
acrylicLabel.TextYAlignment = Enum.TextYAlignment.Center
local acrylicToggle = newButton(acrylicRow, config.acrylic and "On" or "Off")
acrylicToggle.Size = UDim2.new(0.43, 0, 1, 0)
acrylicToggle.Position = UDim2.new(0.57, 0, 0, 0)

addSpacer(configPage, 10)

local reloadDictButton = newButton(configPage, "Reload Dictionary")
reloadDictButton.Size = UDim2.new(1, 0, 0, 32)

-- ==========================================
-- INFO PAGE 1 (DEFINITION SEARCH)
-- ==========================================

local infoTitle = newLabel(infoPage, "Definition Search", 15)
infoTitle.TextXAlignment = Enum.TextXAlignment.Center
infoTitle.TextColor3 = themes[config.theme].highlight

local meaningInput = newBox(infoPage, "Enter word...")
meaningInput.PlaceholderText = "Enter word..."

local meaningSearchButton = newButton(infoPage, "Search Definition")
meaningSearchButton.Size = UDim2.new(1, 0, 0, 32)

local copyDefButton = newButton(infoPage, "Copy Definition")
copyDefButton.Size = UDim2.new(1, 0, 0, 32)

local meaningOutputFrame = Instance.new("Frame", infoPage)
meaningOutputFrame.Size = UDim2.new(1, 0, 0, 150)
meaningOutputFrame.BackgroundColor3 = themes[config.theme].secondary
meaningOutputFrame.BorderSizePixel = 0
meaningOutputFrame.ZIndex = 2

local meaningOutputCorner = Instance.new("UICorner", meaningOutputFrame)
meaningOutputCorner.CornerRadius = UDim.new(0, 8)

local meaningOutputStroke = Instance.new("UIStroke", meaningOutputFrame)
meaningOutputStroke.Color = themes[config.theme].accent
meaningOutputStroke.Thickness = 1
meaningOutputStroke.Transparency = 0.7

local meaningOutput = newLabel(meaningOutputFrame, "Definition will appear here...", 11)
meaningOutput.Size = UDim2.new(1, -12, 1, -12)
meaningOutput.Position = UDim2.new(0, 6, 0, 6)
meaningOutput.TextWrapped = true
meaningOutput.TextYAlignment = Enum.TextYAlignment.Top
meaningOutput.TextXAlignment = Enum.TextXAlignment.Left
meaningOutput.ZIndex = 3

addSpacer(infoPage, 10)

local infoPaginationRow = Instance.new("Frame", infoPage)
infoPaginationRow.Size = UDim2.new(1, 0, 0, 28)
infoPaginationRow.BackgroundTransparency = 1
infoPaginationRow.ZIndex = 2

local infoPageLabel = newLabel(infoPaginationRow, "Page 1/2", 11)
infoPageLabel.Size = UDim2.new(0.3, 0, 1, 0)
infoPageLabel.TextXAlignment = Enum.TextXAlignment.Center
infoPageLabel.TextYAlignment = Enum.TextYAlignment.Center

local infoPrevButton = newButton(infoPaginationRow, "<")
infoPrevButton.Size = UDim2.new(0.33, 0, 1, 0)
infoPrevButton.Position = UDim2.new(0.34, 0, 0, 0)

local infoNextButton = newButton(infoPaginationRow, ">")
infoNextButton.Size = UDim2.new(0.33, 0, 1, 0)
infoNextButton.Position = UDim2.new(0.67, 0, 0, 0)

-- ==========================================
-- INFO PAGE 2 (USAGE GUIDE)
-- ==========================================

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
guideLabel.TextWrapped = true

addSpacer(infoPage2, 10)

local infoPaginationRow2 = Instance.new("Frame", infoPage2)
infoPaginationRow2.Size = UDim2.new(1, 0, 0, 28)
infoPaginationRow2.BackgroundTransparency = 1
infoPaginationRow2.ZIndex = 2

local infoPageLabel2 = newLabel(infoPaginationRow2, "Page 2/2", 11)
infoPageLabel2.Size = UDim2.new(0.3, 0, 1, 0)
infoPageLabel2.TextXAlignment = Enum.TextXAlignment.Center
infoPageLabel2.TextYAlignment = Enum.TextYAlignment.Center

local infoPrevButton2 = newButton(infoPaginationRow2, "<")
infoPrevButton2.Size = UDim2.new(0.33, 0, 1, 0)
infoPrevButton2.Position = UDim2.new(0.34, 0, 0, 0)

local infoNextButton2 = newButton(infoPaginationRow2, ">")
infoNextButton2.Size = UDim2.new(0.33, 0, 1, 0)
infoNextButton2.Position = UDim2.new(0.67, 0, 0, 0)

-- Info page navigation logic
local currentInfoPage = 1

local function updateInfoPage(pageNum)
	currentInfoPage = pageNum
	infoPage.Visible = (pageNum == 1)
	infoPage2.Visible = (pageNum == 2)
	infoPageLabel.Text = "Page 1/2"
	infoPageLabel2.Text = "Page 2/2"
end

infoPrevButton.MouseButton1Click:Connect(function()
	if currentInfoPage > 1 then
		updateInfoPage(currentInfoPage - 1)
	end
end)

infoNextButton.MouseButton1Click:Connect(function()
	if currentInfoPage < 2 then
		updateInfoPage(currentInfoPage + 1)
	end
end)

infoPrevButton2.MouseButton1Click:Connect(function()
	if currentInfoPage > 1 then
		updateInfoPage(currentInfoPage - 1)
	end
end)

infoNextButton2.MouseButton1Click:Connect(function()
	if currentInfoPage < 2 then
		updateInfoPage(currentInfoPage + 1)
	end
end)

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
			if element.Name:find("Container") or element.Name:find("Output") or element.Name:find("List") or element == historyListContainer or element == meaningOutputFrame then
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
	historyTitle.TextColor3 = theme.highlight
	configTitle.TextColor3 = theme.highlight
	infoTitle.TextColor3 = theme.highlight
	infoTitle2.TextColor3 = theme.highlight
	startSectionLabel.TextColor3 = theme.accent
	midSectionLabel.TextColor3 = theme.accent
	endSectionLabel.TextColor3 = theme.accent
	
	themeDropdownButton.Text = themeName
	themeDropdownButton.TextColor3 = theme.text
	themeDropdownFrame.BackgroundColor3 = theme.secondary
	themeDropdownList.BackgroundColor3 = theme.secondary
	transparencySliderHandle.BackgroundColor3 = theme.highlight
end

-- Dropdown positioning update function
local function updateDropdownPosition()
	local absPos = themeDropdownFrame.AbsolutePosition
	themeDropdownList.Position = UDim2.new(0, absPos.X, 0, absPos.Y + 35)
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
		
		themeDropdownList.Size = UDim2.new(0, 268, 0, themeCount * 32)
		themeDropdownList.CanvasSize = UDim2.new(0, 0, 0, themeCount * 32)
		
		for themeName, _ in pairs(themes) do
			local themeOption = Instance.new("TextButton", themeDropdownList)
			themeOption.Size = UDim2.new(1, -8, 0, 30)
			themeOption.BackgroundColor3 = themes[config.theme].secondary
			themeOption.TextColor3 = themes[config.theme].text
			themeOption.Text = themeName
			themeOption.Font = Enum.Font.GothamSemibold
			themeOption.TextSize = 12
			themeOption.BorderSizePixel = 0
			themeOption.ZIndex = 101
			
			local optCorner = Instance.new("UICorner", themeOption)
			optCorner.CornerRadius = UDim.new(0, 6)
			
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

-- Fixed Transparency Slider Logic
local draggingTransparency = false

transparencySliderHandle.MouseButton1Down:Connect(function()
	draggingTransparency = true
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingTransparency = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingTransparency and input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UserInputService:GetMouseLocation()
		local barPos = transparencySliderBar.AbsolutePosition
		local barSize = transparencySliderBar.AbsoluteSize
		
		local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
		local newTransparency = 1 - relativeX
		
		config.transparency = newTransparency
		frame.BackgroundTransparency = newTransparency
		
		transparencySliderHandle.Position = UDim2.new(relativeX, -10, 0.5, -10)
		transparencyValueLabel.Text = string.format("%.2f", newTransparency)
	end
end)

acrylicToggle.MouseButton1Click:Connect(function()
	config.acrylic = not config.acrylic
	acrylicToggle.Text = config.acrylic and "On" or "Off"
	
	if config.acrylic then
		if not acrylicBlur then
			acrylicBlur = Instance.new("BlurEffect")
			acrylicBlur.Size = 24
			acrylicBlur.Name = "WordHelperAcrylicBlur"
			acrylicBlur.Parent = frame
		end
		acrylicBlur.Enabled = true
	else
		if acrylicBlur then
			acrylicBlur.Enabled = false
		end
	end
end)

-- ==========================================
-- HISTORY SYSTEM
-- ==========================================

local function addToHistory(word, category)
	if category == "Typed" then
		if not table.find(typedWords, word) then
			table.insert(typedWords, 1, word)
		end
	elseif category == "Skipped" then
		if not table.find(skippedWords, word) then
			table.insert(skippedWords, 1, word)
		end
	elseif category == "Failed" then
		if not table.find(failedWords, word) then
			table.insert(failedWords, 1, word)
		end
	end
end

local function getHistoryList(category)
	if category == "Typed" then
		return typedWords
	elseif category == "Skipped" then
		return skippedWords
	elseif category == "Failed" then
		return failedWords
	end
	return {}
end

local function sendToChat(message)
	if setclipboard then
		setclipboard(message)
	end
	
	local chatBar = player.PlayerGui:FindFirstChild("Chat")
	if chatBar then
		local chatFrame = chatBar:FindFirstChild("Frame")
		if chatFrame then
			local chatBarParent = chatFrame:FindFirstChild("ChatBarParentFrame")
			if chatBarParent then
				local frameIn = chatBarParent:FindFirstChild("Frame")
				if frameIn then
					local boxFrame = frameIn:FindFirstChild("BoxFrame")
					if boxFrame then
						local frameDeep = boxFrame:FindFirstChild("Frame")
						if frameDeep then
							local chatInput = frameDeep:FindFirstChild("ChatBar")
							if chatInput and chatInput:IsA("TextBox") then
								chatInput.Text = message
								task.wait(0.05)
								chatInput:CaptureFocus()
							end
						end
					end
				end
			end
		end
	end
end

local function createHistoryItem(word, category)
	local item = Instance.new("Frame", historyScrollFrame)
	item.Size = UDim2.new(1, 0, 0, 60)
	item.BackgroundColor3 = themes[config.theme].secondary
	item.BorderSizePixel = 0
	item.ZIndex = 4
	
	local itemCorner = Instance.new("UICorner", item)
	itemCorner.CornerRadius = UDim.new(0, 6)
	
	local itemStroke = Instance.new("UIStroke", item)
	itemStroke.Color = themes[config.theme].accent
	itemStroke.Thickness = 1
	itemStroke.Transparency = 0.8
	
	local wordLabelItem = Instance.new("TextLabel", item)
	wordLabelItem.Size = UDim2.new(1, -10, 0, 20)
	wordLabelItem.Position = UDim2.new(0, 5, 0, 5)
	wordLabelItem.BackgroundTransparency = 1
	wordLabelItem.Text = word
	wordLabelItem.Font = Enum.Font.GothamBold
	wordLabelItem.TextColor3 = themes[config.theme].highlight
	wordLabelItem.TextSize = 13
	wordLabelItem.TextXAlignment = Enum.TextXAlignment.Left
	wordLabelItem.ZIndex = 5
	
	local btnSize = UDim2.new(0.18, 0, 0, 22)
	local btnY = 30
	
	local blacklistBtn = newButton(item, "BL")
	blacklistBtn.Size = btnSize
	blacklistBtn.Position = UDim2.new(0.02, 0, 0, btnY)
	blacklistBtn.TextSize = 9
	blacklistBtn.ZIndex = 5
	
	local favorBtn = newButton(item, "Fav")
	favorBtn.Size = btnSize
	favorBtn.Position = UDim2.new(0.21, 0, 0, btnY)
	favorBtn.TextSize = 9
	favorBtn.ZIndex = 5
	
	local removeBtn = newButton(item, "Rem")
	removeBtn.Size = btnSize
	removeBtn.Position = UDim2.new(0.40, 0, 0, btnY)
	removeBtn.TextSize = 9
	removeBtn.ZIndex = 5
	
	local unblacklistBtn = newButton(item, "UBL")
	unblacklistBtn.Size = btnSize
	unblacklistBtn.Position = UDim2.new(0.59, 0, 0, btnY)
	unblacklistBtn.TextSize = 9
	unblacklistBtn.ZIndex = 5
	
	local chatBtn = newButton(item, "Chat")
	chatBtn.Size = btnSize
	chatBtn.Position = UDim2.new(0.78, 0, 0, btnY)
	chatBtn.TextSize = 9
	chatBtn.ZIndex = 5
	
	blacklistBtn.MouseButton1Click:Connect(function()
		blacklist[word] = true
		blacklistBtn.Text = "✓"
	end)
	
	favorBtn.MouseButton1Click:Connect(function()
		favoredWords[word] = true
		favorBtn.Text = "★"
	end)
	
	removeBtn.MouseButton1Click:Connect(function()
		usedWords[word] = nil
		removeBtn.Text = "✓"
	end)
	
	unblacklistBtn.MouseButton1Click:Connect(function()
		blacklist[word] = nil
		unblacklistBtn.Text = "✓"
	end)
	
	chatBtn.MouseButton1Click:Connect(function()
		sendToChat(word)
	end)
	
	return item
end

local function refreshHistoryList()
	for _, child in ipairs(historyScrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local list = getHistoryList(currentHistoryTab)
	local startIdx = (currentHistoryPage - 1) * historyItemsPerPage + 1
	local endIdx = math.min(startIdx + historyItemsPerPage - 1, #list)
	
	for i = startIdx, endIdx do
		if list[i] then
			createHistoryItem(list[i], currentHistoryTab)
		end
	end
	
	local totalPages = math.ceil(#list / historyItemsPerPage)
	if totalPages == 0 then totalPages = 1 end
	historyPageInfo.Text = string.format("Page %d / %d", currentHistoryPage, totalPages)
end

for tabName, btn in pairs(historyTabButtons) do
	btn.MouseButton1Click:Connect(function()
		currentHistoryTab = tabName
		currentHistoryPage = 1
		refreshHistoryList()
	end)
end

historyPrevButton.MouseButton1Click:Connect(function()
	if currentHistoryPage > 1 then
		currentHistoryPage = currentHistoryPage - 1
		refreshHistoryList()
	end
end)

historyNextButton.MouseButton1Click:Connect(function()
	local list = getHistoryList(currentHistoryTab)
	local totalPages = math.ceil(#list / historyItemsPerPage)
	if currentHistoryPage < totalPages then
		currentHistoryPage = currentHistoryPage + 1
		refreshHistoryList()
	end
end)

-- ==========================================
-- LOGIC
-- ==========================================

loadDictionaries()

local pages = {
	Main = mainPage,
	Settings = settingsPage,
	History = historyPage,
	Config = configPage,
	Info = infoPage
}

for pageName, btn in pairs(navButtons) do
	btn.MouseButton1Click:Connect(function()
		for name, page in pairs(pages) do
			page.Visible = (name == pageName)
		end
		infoPage2.Visible = false
		
		if pageName == "History" then
			refreshHistoryList()
		elseif pageName == "Info" then
			updateInfoPage(1)
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

local function safeGetKeyboard()
	local ok, overbar = pcall(function() return player.PlayerGui.Overbar end)
	if not ok or not overbar then return nil end
	local fr = overbar:FindFirstChild("Frame")
	if not fr then return nil end
	local kb = fr:FindFirstChild("Keyboard")
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

local function pressLetter(c)
	local kb = safeGetKeyboard()
	if not kb then return end
	c = c:upper()
	for _, rowName in ipairs({"1","2","3"}) do
		local row = kb:FindFirstChild(rowName)
		if row then
			local children = row:GetChildren()
			for i = 1, #children do
				local btn = children[i]
				if btn and btn:IsA("TextButton") then
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

local function getV2TypeDelay(position, totalLength)
	local minv = config.autoTypeV2Min
	local maxv = config.autoTypeV2Max
	
	if maxv <= minv then
		return minv
	end
	
	if config.autoTypeV2MoreHuman then
		local range = maxv - minv
		local baseDelay = minv + math.random() * range
		
		-- Determine which section we're in
		local startThreshold = math.ceil(totalLength * 0.20)
		local endThreshold = math.ceil(totalLength * 0.80)
		
		local pauseChance, pauseMult, flowChance, flowMult
		
		if position <= startThreshold then
			-- Start section (first 20%)
			pauseChance = config.humanStartPauseChance
			pauseMult = config.humanStartPauseMult
			flowChance = config.humanStartFlowChance
			flowMult = config.humanStartFlowMult
		elseif position > endThreshold then
			-- End section (last 20%)
			pauseChance = config.humanEndPauseChance
			pauseMult = config.humanEndPauseMult
			flowChance = config.humanEndFlowChance
			flowMult = config.humanEndFlowMult
		else
			-- Middle section (middle 60%)
			pauseChance = config.humanMidPauseChance
			pauseMult = config.humanMidPauseMult
			flowChance = config.humanMidFlowChance
			flowMult = config.humanMidFlowMult
		end
		
		-- Apply pause
		if math.random() < pauseChance then
			baseDelay = baseDelay * pauseMult
		end
		
		-- Apply flow
		if math.random() < flowChance then
			baseDelay = baseDelay * flowMult
		end
		
		return math.clamp(baseDelay, minv, maxv * 2)
	elseif config.autoTypeV2MoreRandom then
		local range = maxv - minv
		local lastDelay = lastV2TypeTimes[#lastV2TypeTimes]
		
		if lastDelay then
			local attempts = 0
			local newDelay
			repeat
				newDelay = minv + math.random() * range
				attempts = attempts + 1
			until math.abs(newDelay - lastDelay) > range * 0.15 or attempts > 10
			
			table.insert(lastV2TypeTimes, newDelay)
			if #lastV2TypeTimes > 5 then
				table.remove(lastV2TypeTimes, 1)
			end
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
	full = full:lower()
	prefix = prefix:lower()
	local start = #prefix + 1
	if start > #full then
		isTypingInProgress = false
		addToHistory(full, "Failed")
		return
	end

	local cont = full:sub(start)
	local totalLength = #cont

	if config.instantType then
		for i = 1, #cont do
			pressLetter(cont:sub(i,i))
		end
		typedCount = #cont
	else
		for i = 1, #cont do
			pressLetter(cont:sub(i,i))
			typedCount = typedCount + 1
			
			local delay
			if useV2Speed then
				delay = getV2TypeDelay(i, totalLength)
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
	addToHistory(full, "Typed")
end

-- Connect all input handlers for enhanced human typing settings
startPauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(startPauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanStartPauseChance = v / 100
	end
	startPauseChanceInput.Text = tostring(config.humanStartPauseChance * 100)
end)

startPauseMultInput.FocusLost:Connect(function()
	local v = tonumber(startPauseMultInput.Text)
	if v and v >= 1 then
		config.humanStartPauseMult = v
	end
	startPauseMultInput.Text = tostring(config.humanStartPauseMult)
end)

startFlowChanceInput.FocusLost:Connect(function()
	local v = tonumber(startFlowChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanStartFlowChance = v / 100
	end
	startFlowChanceInput.Text = tostring(config.humanStartFlowChance * 100)
end)

startFlowMultInput.FocusLost:Connect(function()
	local v = tonumber(startFlowMultInput.Text)
	if v and v > 0 and v <= 1 then
		config.humanStartFlowMult = v
	end
	startFlowMultInput.Text = tostring(config.humanStartFlowMult)
end)

midPauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(midPauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanMidPauseChance = v / 100
	end
	midPauseChanceInput.Text = tostring(config.humanMidPauseChance * 100)
end)

midPauseMultInput.FocusLost:Connect(function()
	local v = tonumber(midPauseMultInput.Text)
	if v and v >= 1 then
		config.humanMidPauseMult = v
	end
	midPauseMultInput.Text = tostring(config.humanMidPauseMult)
end)

midFlowChanceInput.FocusLost:Connect(function()
	local v = tonumber(midFlowChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanMidFlowChance = v / 100
	end
	midFlowChanceInput.Text = tostring(config.humanMidFlowChance * 100)
end)

midFlowMultInput.FocusLost:Connect(function()
	local v = tonumber(midFlowMultInput.Text)
	if v and v > 0 and v <= 1 then
		config.humanMidFlowMult = v
	end
	midFlowMultInput.Text = tostring(config.humanMidFlowMult)
end)

endPauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(endPauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanEndPauseChance = v / 100
	end
	endPauseChanceInput.Text = tostring(config.humanEndPauseChance * 100)
end)

endPauseMultInput.FocusLost:Connect(function()
	local v = tonumber(endPauseMultInput.Text)
	if v and v >= 1 then
		config.humanEndPauseMult = v
	end
	endPauseMultInput.Text = tostring(config.humanEndPauseMult)
end)

endFlowChanceInput.FocusLost:Connect(function()
	local v = tonumber(endFlowChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanEndFlowChance = v / 100
	end
	endFlowChanceInput.Text = tostring(config.humanEndFlowChance * 100)
end)

endFlowMultInput.FocusLost:Connect(function()
	local v = tonumber(endFlowMultInput.Text)
	if v and v > 0 and v <= 1 then
		config.humanEndFlowMult = v
	end
	endFlowMultInput.Text = tostring(config.humanEndFlowMult)
end)

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
		v2MoreRandomRow.Visible = false
		v2MoreHumanRow.Visible = false
		humanSettingsContainer.Visible = false
	end
	
	if not config.autoType then
		clearTypedContinuation()
	end
end)

autoTypeV2Toggle.MouseButton1Click:Connect(function()
	config.autoTypeV2 = not config.autoTypeV2
	autoTypeV2Toggle.Text = config.autoTypeV2 and "On" or "Off"
	
	v2MinMaxRow.Visible = config.autoTypeV2
	v2MoreRandomRow.Visible = config.autoTypeV2
	v2MoreHumanRow.Visible = config.autoTypeV2
	
	if config.autoTypeV2 and config.autoType then
		config.autoType = false
		autoTypeButton.Text = "Auto V1: Off"
	end
	
	if not config.autoTypeV2 then
		clearTypedContinuation()
		humanSettingsContainer.Visible = false
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

v2MoreRandomToggle.MouseButton1Click:Connect(function()
	config.autoTypeV2MoreRandom = not config.autoTypeV2MoreRandom
	v2MoreRandomToggle.Text = config.autoTypeV2MoreRandom and "On" or "Off"
	lastV2TypeTimes = {}
	
	if config.autoTypeV2MoreRandom and config.autoTypeV2MoreHuman then
		config.autoTypeV2MoreHuman = false
		v2MoreHumanToggle.Text = "Off"
		humanSettingsContainer.Visible = false
	end
end)

v2MoreHumanToggle.MouseButton1Click:Connect(function()
	config.autoTypeV2MoreHuman = not config.autoTypeV2MoreHuman
	v2MoreHumanToggle.Text = config.autoTypeV2MoreHuman and "On" or "Off"
	
	humanSettingsContainer.Visible = config.autoTypeV2MoreHuman
	
	if config.autoTypeV2MoreHuman and config.autoTypeV2MoreRandom then
		config.autoTypeV2MoreRandom = false
		v2MoreRandomToggle.Text = "Off"
	end
end)

nextButton.MouseButton1Click:Connect(function()
	if #currentMatches > 0 then
		if currentMatches[matchIndex] then
			addToHistory(currentMatches[matchIndex], "Skipped")
		end
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
		typeContinuation(word, lastPrefix, false)
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

loadConfigButton.MouseButton1Click:Connect(function()
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
			v2MoreRandomToggle.Text = config.autoTypeV2MoreRandom and "On" or "Off"
			v2MoreHumanToggle.Text = config.autoTypeV2MoreHuman and "On" or "Off"
			longestToggle.Text = longest and "On" or "Off"
			v2MinMaxRow.Visible = config.autoTypeV2
			v2MoreRandomRow.Visible = config.autoTypeV2
			v2MoreHumanRow.Visible = config.autoTypeV2
			humanSettingsContainer.Visible = config.autoTypeV2MoreHuman
			acrylicToggle.Text = config.acrylic and "On" or "Off"
			
			-- Update human typing inputs
			startPauseChanceInput.Text = tostring(config.humanStartPauseChance * 100)
			startPauseMultInput.Text = tostring(config.humanStartPauseMult)
			startFlowChanceInput.Text = tostring(config.humanStartFlowChance * 100)
			startFlowMultInput.Text = tostring(config.humanStartFlowMult)
			midPauseChanceInput.Text = tostring(config.humanMidPauseChance * 100)
			midPauseMultInput.Text = tostring(config.humanMidPauseMult)
			midFlowChanceInput.Text = tostring(config.humanMidFlowChance * 100)
			midFlowMultInput.Text = tostring(config.humanMidFlowMult)
			endPauseChanceInput.Text = tostring(config.humanEndPauseChance * 100)
			endPauseMultInput.Text = tostring(config.humanEndPauseMult)
			endFlowChanceInput.Text = tostring(config.humanEndFlowChance * 100)
			endFlowMultInput.Text = tostring(config.humanEndFlowMult)
			
			applyTheme(config.theme)
			frame.BackgroundTransparency = config.transparency
			transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -10, 0.5, -10)
			transparencyValueLabel.Text = string.format("%.2f", config.transparency)
			
			if config.acrylic then
				if not acrylicBlur then
					acrylicBlur = Instance.new("BlurEffect")
					acrylicBlur.Size = 24
					acrylicBlur.Name = "WordHelperAcrylicBlur"
					acrylicBlur.Parent = frame
				end
				acrylicBlur.Enabled = true
			else
				if acrylicBlur then
					acrylicBlur.Enabled = false
				end
			end
			
			loadConfigButton.Text = "Loaded!"
			task.delay(1, function()
				loadConfigButton.Text = "Load Config"
			end)
		else
			loadConfigButton.Text = "Fail"
			task.delay(1, function() loadConfigButton.Text = "Load Config" end)
		end
	else
		loadConfigButton.Text = "No File"
		task.delay(1, function() loadConfigButton.Text = "Load Config" end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.T then
		if #currentMatches == 0 or lastPrefix == "" or isTypingInProgress then return end
		local word = currentMatches[matchIndex]
		if config.antiDupe and usedWords[word] then return end
		task.spawn(function()
			typeContinuation(word, lastPrefix, false)
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
		
		typeContinuation(word, lastPrefix, config.autoTypeV2)
		
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
