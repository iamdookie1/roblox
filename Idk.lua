Players = game:GetService("Players")
UserInputService = game:GetService("UserInputService")
RunService = game:GetService("RunService")
HttpService = game:GetService("HttpService")
TweenService = game:GetService("TweenService")

player = Players.LocalPlayer

DICT_URL = "https://raw.githubusercontent.com/dwyl/english-words/refs/heads/master/words_alpha.txt"
DICT_URL_BACKUP = "https://raw.githubusercontent.com/raun/Scrabble/master/words.txt"
DICT_URL_YAWL = "https://raw.githubusercontent.com/elasticdog/yawl/refs/heads/master/yawl-0.3.2.03/word.list"
BAD_WORDS_URL_1 = "https://raw.githubusercontent.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/master/en"
BAD_WORDS_URL_2 = "https://raw.githubusercontent.com/RobertJGabriel/Google-profanity-words/master/list.txt"

TRAP_WORDS = [[
ingannation
yangtze
yangs
qaid
qat
qi
za
]]

dictionary = {}
index = {}
blacklist = {}

isDictionaryReady = false
isReloading = false

local updateStatusLabel

WORDS_PER_FRAME = 25000

themes = {
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

local function fetchData(url)
	local maxRetries = 3
	
	for attempt = 1, maxRetries do
		local success, res = pcall(function()
			return game:HttpGet(url, true)
		end)
		if success and res and #res > 100 then
			return res
		end
		if attempt < maxRetries then
			task.wait(1.0)
		end
	end
	warn("Failed to load URL after retries: " .. url)
	return ""
end

local function buildDictionaryStructure(dText1, dText2, dText3, bText1, bText2)
	dictionary = {}
	index = {}
	blacklist = {}

	local maxPerFrame = tonumber(WORDS_PER_FRAME) or 25000
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

	local function processDict(str, label, stripQuotes)
		if not str or #str == 0 then return end

		local words = {}
		for word in str:gmatch("[^\r\n]+") do
			local w = word:lower():gsub("%s+", "")
			
			if stripQuotes then
				w = w:gsub('^"', ''):gsub('"$', '')
				w = w:gsub("^'", ''):gsub("'$", '')
			end
			
			if #w > 0 and not w:find("'") and not blacklist[w] and not seen[w] then
				words[#words + 1] = w
				seen[w] = true
			end
		end
		
		for i = 1, #words do
			local w = words[i]
			processedCount = processedCount + 1
			
			local f = w:sub(1, 1)
			local bucket = index[f]
			if not bucket then
				bucket = {}
				index[f] = bucket
			end
			
			bucket[#bucket + 1] = w
			dictionary[#dictionary + 1] = w
			
			if processedCount % maxPerFrame == 0 then
				if updateStatusLabel then
					updateStatusLabel(label .. " (" .. math.floor(processedCount / 1000) .. "k)")
				end
				RunService.Heartbeat:Wait()
			end
		end
	end

	processDict(dText1, "Processing Main", false)
	processDict(dText2, "Processing Backup", false)
	processDict(dText3, "Processing YAWL", false)
	processDict(TRAP_WORDS, "Finalizing", false)
end

loadConfigFromFile = nil

local function loadDictionaries()
	if isReloading then return end
	isReloading = true
	isDictionaryReady = false

	if updateStatusLabel then updateStatusLabel("Downloading...") end

	task.spawn(function()
		print("=== Loading Dictionary 1 (dwyl) ===")
		local dt1 = fetchData(DICT_URL)
		task.wait(0.5)
		
		print("=== Loading Dictionary 2 (Scrabble) ===")
		local dt2 = fetchData(DICT_URL_BACKUP)
		task.wait(0.5)
		
		print("=== Loading Dictionary 3 (YAWL) ===")
		local dt3 = fetchData(DICT_URL_YAWL)
		task.wait(0.5)
		
		print("=== Loading Blacklists ===")
		local bt1 = fetchData(BAD_WORDS_URL_1)
		task.wait(0.3)
		local bt2 = fetchData(BAD_WORDS_URL_2)
		
		print("=== RESULTS ===")
		if not dt1 or #dt1 < 100 then
			warn("✗ Main Dictionary (dwyl) failed. Size: " .. #(dt1 or ""))
			dt1 = ""
		else
			print("✓ Main Dictionary (dwyl): " .. #dt1 .. " chars")
		end
		
		if not dt2 or #dt2 < 100 then
			warn("✗ Backup Dictionary (Scrabble) failed. Size: " .. #(dt2 or ""))
			dt2 = ""
		else
			print("✓ Backup Dictionary (Scrabble): " .. #dt2 .. " chars")
		end
		
		if not dt3 or #dt3 < 100 then
			warn("✗ YAWL Dictionary failed. Size: " .. #(dt3 or ""))
			dt3 = ""
		else
			print("✓ YAWL Dictionary: " .. #dt3 .. " chars")
		end

		if dt1 == "" and dt2 == "" and dt3 == "" then
			if updateStatusLabel then updateStatusLabel("FAILED TO LOAD") end
			warn("CRITICAL: No dictionary sources loaded.")
			dt1 = "apple\nbanana\ncat\ndog\nelephant\nfish\ngrape\nhat\nice\njump\nkite\nlion\nmoon\nno\norange"
		end
		
		print("=== Building Dictionary Structure ===")
		buildDictionaryStructure(dt1, dt2, dt3, bt1, bt2)
		
		print("✓ Dictionary complete with " .. #dictionary .. " words")
		
		isDictionaryReady = true
		isReloading = false
		if updateStatusLabel then updateStatusLabel("Ready") end
		
		if config and config.autoLoadConfig then
			task.wait(0.1)
			if loadConfigFromFile then
				loadConfigFromFile(true)
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

config = {
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
	
	autoTypeV3 = false,
	v3MinDelay = 0.08,
	v3MaxDelay = 0.18,
	v3HumanLike = false,
	v3PauseChance = 0.10,
	v3PauseMin = 0.2,
	v3PauseMax = 0.6,
	v3ThinkPauseChance = 0.06,
	v3ThinkPauseMin = 0.4,
	v3ThinkPauseMax = 1.2,
	v3BurstChance = 0.12,
	v3BurstMultiplier = 0.7,
	v3RhythmVariation = false,
	v3Acceleration = 0.015,
	v3Fatigue = false,
	v3FatigueRate = 0.015,
	v3WordStartPause = 0.15,
	v3WordEndPause = 0.12,
	v3ErrorSimulation = false,
	v3TypoChance = 0.03,
	v3TypoCorrectDelay = 0.3,
	v3SpeedRandomization = true,
	v3RandomizationAmount = 0.35,
	v3CustomStartDelay = false,
	v3StartDelayMin = 0.5,
	v3StartDelayMax = 1.5,
	v3CustomDoneDelay = false,
	v3DoneDelayMin = 0.1,
	v3DoneDelayMax = 0.3,
	v3SpeedLimit = false,
	v3MaxLPS = 6.0,
	v3MinLPSEnabled = false,
	v3MinLPS = 2.0,
	v3MaxWPM = false,
	v3MaxWPMValue = 70,
	v3MaxCPS = false,
	v3MaxCPSValue = 9.0,
	v3ButtonHold = false,
	v3ButtonHoldMin = 0.05,
	v3ButtonHoldMax = 0.15,
	
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
	humanWordStartPause = 0.2,
	humanWordEndPause = 0.15,
	humanRhythmVariation = true,
	humanAcceleration = 0.02,
	humanThinkingPauseChance = 0.08,
	humanThinkingPauseMin = 0.5,
	humanThinkingPauseMax = 1.5,
	
	speedLimitEnabled = false,
	speedLimitLPS = 5.0,
	speedLimitWPM = false,
	speedLimitWPMValue = 60,
	speedLimitCPS = false,
	speedLimitCPSValue = 8.0,
	
	requireVisibleUI = true,
	requirePlayerNameInPrompt = true,
	safetyDelay = 0.3,
	
	minWordLength = 3,
	endingIn = "",
	theme = "Dark",
	transparency = 0.05,
	acrylic = false,
	autoLoadConfig = false,
	
	uiElementTransparency = 0,
	uiElementAcrylic = false,
	
	debugOverlay = false,
	debugTextSize = 14
}

usedWords = {}
typedCount = 0
isTypingInProgress = false
autoTypePrefixTime = 0

statsTracking = {
	typingStartTime = 0,
	totalCharsTyped = 0,
	wordsTyped = 0,
	lastWpmCalcTime = 0,
	wpmValue = 0,
	etcValue = 0,
	lastEtcUpdate = 0,
	sessionStartTime = tick()
}

humanTypingState = {
	rhythmOffset = 0,
	currentSpeed = 1.0,
	consecutiveChars = 0
}

v3TypingState = {
	rhythmOffset = 0,
	consecutiveChars = 0,
	currentSpeed = 1.0
}

timerState = {
	isActive = false,
	startTime = 0,
	startValue = 15,
	lastTimerValue = 0,
	hasWaited = false,
	canTypeNow = false
}

local function getTimerInfo()
	local success, inGame = pcall(function() 
		return player.PlayerGui:FindFirstChild("InGame") 
	end)
	if not success or not inGame then return nil, nil, false end
	
	local frame = inGame:FindFirstChild("Frame")
	if not frame then return nil, nil, false end
	
	local circle = frame:FindFirstChild("Circle")
	if not circle then return nil, nil, false end
	
	local isVisible = circle.Visible
	
	if not isVisible then
		return nil, nil, false
	end
	
	local timer = circle:FindFirstChild("Timer")
	if not timer then return nil, nil, true end
	
	local seconds = timer:FindFirstChild("Seconds")
	if not seconds then return nil, nil, true end
	
	local timeText = tostring(seconds.Text or "")
	local timeValue = tonumber(timeText)
	
	return timeValue, seconds, true
end

local function updateTimerState()
	local timeValue, secondsLabel, circleVisible = getTimerInfo()
	
	if not circleVisible then
		if timerState.isActive then
			timerState.isActive = false
			timerState.hasWaited = false
			timerState.canTypeNow = false
		end
		return
	end
	
	if not timeValue then return end
	
	if not timerState.isActive or timeValue > timerState.lastTimerValue then
		timerState.isActive = true
		timerState.startTime = tick()
		timerState.startValue = timeValue
		timerState.lastTimerValue = timeValue
		timerState.hasWaited = false
		timerState.canTypeNow = false
		
		print("🕐 Timer detected! Starting value: " .. timeValue .. "s")
		
		task.spawn(function()
			task.wait(1.5)
			timerState.hasWaited = true
			
			local randomDelay = 0.5 + (math.random() * 0.75)
			task.wait(randomDelay)
			
			timerState.canTypeNow = true
			print("✓ Ready to type! (waited " .. string.format("%.2f", 1.5 + randomDelay) .. "s)")
		end)
	else
		timerState.lastTimerValue = timeValue
	end
end

local function isKeyboardVisible()
	local ok, overbar = pcall(function() return player.PlayerGui.Overbar end)
	if not ok or not overbar then return false end
	
	local frame = overbar:FindFirstChild("Frame")
	if not frame then return false end
	
	local keyboard = frame:FindFirstChild("Keyboard")
	if not keyboard then return false end
	
	if not keyboard.Visible then return false end
	if keyboard.Parent and not keyboard.Parent.Visible then return false end
	
	return true
end

local function isPlayerTurn()
	local inGame = player.PlayerGui:FindFirstChild("InGame")
	if not inGame then return false end
	
	local frame = inGame:FindFirstChild("Frame")
	if not frame then return false end
	
	local typeLabel = frame:FindFirstChild("Type")
	if not typeLabel then return false end
	
	local txt = tostring(typeLabel.Text or "")
	if txt == "" then return false end
	
	if config.requirePlayerNameInPrompt then
		local hasPlayerName = string.find(txt, player.Name, 1, true)
		local hasDisplayName = player.DisplayName ~= "" and string.find(txt, player.DisplayName, 1, true)
		
		if not (hasPlayerName or hasDisplayName) then
			return false
		end
	end
	
	return true
end

local function canAutoType()
	if config.requireVisibleUI and not isKeyboardVisible() then
		return false, "UI not visible"
	end
	
	if not isPlayerTurn() then
		return false, "Not player's turn"
	end
	
	if isTypingInProgress then
		return false, "Already typing"
	end
	
	if not isDictionaryReady then
		return false, "Dictionary not ready"
	end
	
	if not timerState.canTypeNow then
		if timerState.isActive and not timerState.hasWaited then
			return false, "Waiting for timer"
		elseif timerState.isActive and timerState.hasWaited then
			return false, "Timer cooldown"
		else
			return false, "No timer detected"
		end
	end
	
	return true, "OK"
end

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
		local lenA = #a
		local lenB = #b
		
		if lenA ~= lenB then
			if longest then
				return lenA > lenB
			else
				return lenA < lenB
			end
		else
			return a < b
		end
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

gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Name = "WordHelperUI"

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 380)
frame.Position = UDim2.new(0.72, 0, 0.12, 0)
frame.BackgroundColor3 = themes[config.theme].primary
frame.BackgroundTransparency = config.transparency
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 14)

frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = themes[config.theme].accent
frameStroke.Thickness = 2
frameStroke.Transparency = 0.3

blur = Instance.new("UIGradient", frame)
blur.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, themes[config.theme].gradient1),
	ColorSequenceKeypoint.new(1, themes[config.theme].gradient2)
}
blur.Rotation = 45

acrylicFrame = nil
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

topBar = Instance.new("Frame", frame)
topBar.Size = UDim2.new(1, 0, 0, 32)
topBar.BackgroundTransparency = 1
topBar.ZIndex = 2

local function applyUIElementEffects(element)
	if element:IsA("TextButton") or element:IsA("TextBox") or (element:IsA("Frame") and element.BackgroundTransparency < 1 and not element:FindFirstChild("UIListLayout")) then
		element.BackgroundTransparency = config.uiElementTransparency
		
		local existingAcrylic = element:FindFirstChild("UIElementAcrylic")
		if config.uiElementAcrylic then
			if not existingAcrylic then
				local acrylicEffect = Instance.new("Frame", element)
				acrylicEffect.Name = "UIElementAcrylic"
				acrylicEffect.Size = UDim2.new(1, 0, 1, 0)
				acrylicEffect.Position = UDim2.new(0, 0, 0, 0)
				acrylicEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				acrylicEffect.BackgroundTransparency = 0.95
				acrylicEffect.BorderSizePixel = 0
				acrylicEffect.ZIndex = element.ZIndex
				
				local existingCorner = element:FindFirstChildOfClass("UICorner")
				if existingCorner then
					local acrylicCorner = Instance.new("UICorner", acrylicEffect)
					acrylicCorner.CornerRadius = existingCorner.CornerRadius
				end
				
				local blur = Instance.new("BlurEffect", acrylicEffect)
				blur.Size = 4
			end
		else
			if existingAcrylic then
				existingAcrylic:Destroy()
			end
		end
	end
end

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
	
	applyUIElementEffects(b)
	
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = themes[config.theme].accent}):Play()
	end)
	
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = themes[config.theme].secondary}):Play()
	end)
	
	return b
end

navButtons = {}
navButtonNames = {"Main", "Settings", "Human", "V3", "Config", "Info"}
buttonWidth = 0.165

for i, name in ipairs(navButtonNames) do
	local btn = newButton(topBar, name)
	btn.Size = UDim2.new(buttonWidth, 0, 1, 0)
	btn.Position = UDim2.new((i-1) * (buttonWidth + 0.003) + 0.003, 0, 0, 0)
	btn.TextSize = 9
	navButtons[name] = btn
end

contentContainer = Instance.new("Frame", frame)
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

mainPage = createPage()
mainPage.Visible = true
settingsPage = createPage()
humanPage = createPage()
v3Page = createPage()
configPage = createPage()
infoPage = createPage()

local function addSpacer(parent, height)
	local f = Instance.new("Frame", parent)
	f.BackgroundTransparency = 1
	f.Size = UDim2.new(1, 0, 0, height or 5)
	return f
end

local function addDivider(parent, text)
	local divider = Instance.new("Frame", parent)
	divider.Size = UDim2.new(1, 0, 0, 20)
	divider.BackgroundTransparency = 1
	divider.ZIndex = 2
	
	local line1 = Instance.new("Frame", divider)
	line1.Size = UDim2.new(0.25, 0, 0, 1)
	line1.Position = UDim2.new(0, 0, 0.5, 0)
	line1.BackgroundColor3 = themes[config.theme].accent
	line1.BorderSizePixel = 0
	line1.ZIndex = 2
	
	local label = Instance.new("TextLabel", divider)
	label.Size = UDim2.new(0.48, 0, 1, 0)
	label.Position = UDim2.new(0.26, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextSize = 11
	label.TextColor3 = themes[config.theme].highlight
	label.ZIndex = 2
	
	local line2 = Instance.new("Frame", divider)
	line2.Size = UDim2.new(0.25, 0, 0, 1)
	line2.Position = UDim2.new(0.75, 0, 0.5, 0)
	line2.BackgroundColor3 = themes[config.theme].accent
	line2.BorderSizePixel = 0
	line2.ZIndex = 2
	
	return divider
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
	
	applyUIElementEffects(b)
	
	return b
end

title = newLabel(mainPage, "Word Helper Pro", 15)
title.TextXAlignment = Enum.TextXAlignment.Center
title.TextColor3 = themes[config.theme].highlight

wordLabel = Instance.new("TextLabel", mainPage)
wordLabel.Size = UDim2.new(1, 0, 0, 42)
wordLabel.BackgroundColor3 = themes[config.theme].secondary
wordLabel.TextColor3 = themes[config.theme].highlight
wordLabel.Font = Enum.Font.GothamBold
wordLabel.TextSize = 17
wordLabel.Text = "Waiting..."
wordLabel.BorderSizePixel = 0
wordLabel.ZIndex = 2

wordCorner = Instance.new("UICorner", wordLabel)
wordCorner.CornerRadius = UDim.new(0, 9)

wordStroke = Instance.new("UIStroke", wordLabel)
wordStroke.Color = themes[config.theme].accent
wordStroke.Thickness = 2
wordStroke.Transparency = 0.4

applyUIElementEffects(wordLabel)

updateStatusLabel = function(txt)
	wordLabel.Text = txt
end

addDivider(mainPage, "Controls")

nextButton = newButton(mainPage, "Next Word")
nextButton.Size = UDim2.new(1, 0, 0, 30)

row1 = Instance.new("Frame", mainPage)
row1.Size = UDim2.new(1, 0, 0, 30)
row1.BackgroundTransparency = 1
row1.ZIndex = 2
typeButton = newButton(row1, "Type")
typeButton.Size = UDim2.new(0.48, 0, 1, 0)
autoTypeButton = newButton(row1, "Auto V1: Off")
autoTypeButton.Position = UDim2.new(0.52, 0, 0, 0)
autoTypeButton.Size = UDim2.new(0.48, 0, 1, 0)

row2 = Instance.new("Frame", mainPage)
row2.Size = UDim2.new(1, 0, 0, 30)
row2.BackgroundTransparency = 1
row2.ZIndex = 2
copyButton = newButton(row2, "Copy")
copyButton.Size = UDim2.new(0.48, 0, 1, 0)
forceFindButton = newButton(row2, "Force Find")
forceFindButton.Position = UDim2.new(0.52, 0, 0, 0)
forceFindButton.Size = UDim2.new(0.48, 0, 1, 0)

addDivider(mainPage, "Options")

row3 = Instance.new("Frame", mainPage)
row3.Size = UDim2.new(1, 0, 0, 30)
row3.BackgroundTransparency = 1
row3.ZIndex = 2
longestLabel = newLabel(row3, "Longest First", 12)
longestLabel.Size = UDim2.new(0.5, 0, 1, 0)
longestLabel.TextYAlignment = Enum.TextYAlignment.Center
longestToggle = newButton(row3, "Off")
longestToggle.Size = UDim2.new(0.48, 0, 1, 0)
longestToggle.Position = UDim2.new(0.52, 0, 0, 0)

autoTypeV2Row = Instance.new("Frame", mainPage)
autoTypeV2Row.Size = UDim2.new(1, 0, 0, 30)
autoTypeV2Row.BackgroundTransparency = 1
autoTypeV2Row.ZIndex = 2
autoTypeV2Label = newLabel(autoTypeV2Row, "Auto Type V2", 12)
autoTypeV2Label.Size = UDim2.new(0.5, 0, 1, 0)
autoTypeV2Label.TextYAlignment = Enum.TextYAlignment.Center
autoTypeV2Toggle = newButton(autoTypeV2Row, "Off")
autoTypeV2Toggle.Size = UDim2.new(0.48, 0, 1, 0)
autoTypeV2Toggle.Position = UDim2.new(0.52, 0, 0, 0)

v2MinMaxRow = Instance.new("Frame", mainPage)
v2MinMaxRow.Size = UDim2.new(1, 0, 0, 30)
v2MinMaxRow.BackgroundTransparency = 1
v2MinMaxRow.Visible = false
v2MinMaxRow.ZIndex = 2
v2mml = newLabel(v2MinMaxRow, "V2 Min/Max", 11)
v2mml.Size = UDim2.new(0.36, 0, 1, 0)
v2mml.TextYAlignment = Enum.TextYAlignment.Center
v2MinInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Min), 30)
v2MinInput.Size = UDim2.new(0.29, 0, 1, 0)
v2MinInput.Position = UDim2.new(0.38, 0, 0, 0)
v2MaxInput = newBox(v2MinMaxRow, tostring(config.autoTypeV2Max), 30)
v2MaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v2MaxInput.Position = UDim2.new(0.69, 0, 0, 0)

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

addDivider(settingsPage, "Basic Settings")

createSettingRow(settingsPage, "Typing Delay", newBox(nil, tostring(config.typingDelay)))
delayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "Start Delay", newBox(nil, tostring(config.startDelay)))
startDelayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

randomRow = Instance.new("Frame", settingsPage)
randomRow.Size = UDim2.new(1, 0, 0, 30)
randomRow.BackgroundTransparency = 1
randomRow.ZIndex = 2
rl = newLabel(randomRow, "Random Speed", 11)
rl.Size = UDim2.new(0.52, 0, 1, 0)
rl.TextYAlignment = Enum.TextYAlignment.Center
randomToggleButton = newButton(randomRow, "Off")
randomToggleButton.Size = UDim2.new(0.46, 0, 1, 0)
randomToggleButton.Position = UDim2.new(0.54, 0, 0, 0)

instantRow = Instance.new("Frame", settingsPage)
instantRow.Size = UDim2.new(1, 0, 0, 30)
instantRow.BackgroundTransparency = 1
instantRow.ZIndex = 2
il = newLabel(instantRow, "Instant Type", 11)
il.Size = UDim2.new(0.52, 0, 1, 0)
il.TextYAlignment = Enum.TextYAlignment.Center
instantToggle = newButton(instantRow, "Off")
instantToggle.Size = UDim2.new(0.46, 0, 1, 0)
instantToggle.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(settingsPage, "Auto Done")

autoDoneRow = Instance.new("Frame", settingsPage)
autoDoneRow.Size = UDim2.new(1, 0, 0, 30)
autoDoneRow.BackgroundTransparency = 1
autoDoneRow.ZIndex = 2
adl = newLabel(autoDoneRow, "Auto Done", 11)
adl.Size = UDim2.new(0.52, 0, 1, 0)
adl.TextYAlignment = Enum.TextYAlignment.Center
autoDoneButton = newButton(autoDoneRow, "On")
autoDoneButton.Size = UDim2.new(0.46, 0, 1, 0)
autoDoneButton.Position = UDim2.new(0.54, 0, 0, 0)

minMaxRow = Instance.new("Frame", settingsPage)
minMaxRow.Size = UDim2.new(1, 0, 0, 30)
minMaxRow.BackgroundTransparency = 1
minMaxRow.ZIndex = 2
mml = newLabel(minMaxRow, "Done Min/Max", 11)
mml.Size = UDim2.new(0.36, 0, 1, 0)
mml.TextYAlignment = Enum.TextYAlignment.Center
minInput = newBox(minMaxRow, tostring(config.autoDoneMin))
minInput.Size = UDim2.new(0.29, 0, 1, 0)
minInput.Position = UDim2.new(0.38, 0, 0, 0)
maxInput = newBox(minMaxRow, tostring(config.autoDoneMax))
maxInput.Size = UDim2.new(0.29, 0, 1, 0)
maxInput.Position = UDim2.new(0.69, 0, 0, 0)

addDivider(settingsPage, "Safety & Detection")

requireUIRow = Instance.new("Frame", settingsPage)
requireUIRow.Size = UDim2.new(1, 0, 0, 30)
requireUIRow.BackgroundTransparency = 1
requireUIRow.ZIndex = 2
requireUILabel = newLabel(requireUIRow, "Require Visible UI", 11)
requireUILabel.Size = UDim2.new(0.52, 0, 1, 0)
requireUILabel.TextYAlignment = Enum.TextYAlignment.Center
requireUIToggle = newButton(requireUIRow, config.requireVisibleUI and "On" or "Off")
requireUIToggle.Size = UDim2.new(0.46, 0, 1, 0)
requireUIToggle.Position = UDim2.new(0.54, 0, 0, 0)

requireNameRow = Instance.new("Frame", settingsPage)
requireNameRow.Size = UDim2.new(1, 0, 0, 30)
requireNameRow.BackgroundTransparency = 1
requireNameRow.ZIndex = 2
requireNameLabel = newLabel(requireNameRow, "Require Your Name", 11)
requireNameLabel.Size = UDim2.new(0.52, 0, 1, 0)
requireNameLabel.TextYAlignment = Enum.TextYAlignment.Center
requireNameToggle = newButton(requireNameRow, config.requirePlayerNameInPrompt and "On" or "Off")
requireNameToggle.Size = UDim2.new(0.46, 0, 1, 0)
requireNameToggle.Position = UDim2.new(0.54, 0, 0, 0)

createSettingRow(settingsPage, "Safety Delay (s)", newBox(nil, tostring(config.safetyDelay)))
safetyDelayInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

addDivider(settingsPage, "Word Filters")

antiDupeRow = Instance.new("Frame", settingsPage)
antiDupeRow.Size = UDim2.new(1, 0, 0, 30)
antiDupeRow.BackgroundTransparency = 1
antiDupeRow.ZIndex = 2
adl2 = newLabel(antiDupeRow, "Anti Dupe", 11)
adl2.Size = UDim2.new(0.52, 0, 1, 0)
adl2.TextYAlignment = Enum.TextYAlignment.Center
antiDupeToggle = newButton(antiDupeRow, "Off")
antiDupeToggle.Size = UDim2.new(0.46, 0, 1, 0)
antiDupeToggle.Position = UDim2.new(0.54, 0, 0, 0)

createSettingRow(settingsPage, "Min Length", newBox(nil, tostring(config.minWordLength)))
shortInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

createSettingRow(settingsPage, "End In (1-2)", newBox(nil, ""))
endingInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

addDivider(settingsPage, "Custom Words")

createSettingRow(settingsPage, "Custom Words", newBox(nil, ""))
customInput = settingsPage:GetChildren()[#settingsPage:GetChildren()]:FindFirstChildOfClass("TextBox")

addSpacer(settingsPage, 5)

resetButton = newButton(settingsPage, "Reset Used Words")
resetButton.Size = UDim2.new(1, 0, 0, 30)

humanTitle = newLabel(humanPage, "Human Typing Settings", 14)
humanTitle.TextXAlignment = Enum.TextXAlignment.Center
humanTitle.TextColor3 = themes[config.theme].highlight

addSpacer(humanPage, 3)

humanToggleRow = Instance.new("Frame", humanPage)
humanToggleRow.Size = UDim2.new(1, 0, 0, 30)
humanToggleRow.BackgroundTransparency = 1
humanToggleRow.ZIndex = 2
humanToggleLabel = newLabel(humanToggleRow, "Enable Human Typing", 12)
humanToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
humanToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
humanToggle = newButton(humanToggleRow, "Off")
humanToggle.Size = UDim2.new(0.38, 0, 1, 0)
humanToggle.Position = UDim2.new(0.62, 0, 0, 0)

humanSettingsContainer = Instance.new("Frame", humanPage)
humanSettingsContainer.Size = UDim2.new(1, 0, 0, 10)
humanSettingsContainer.BackgroundTransparency = 1
humanSettingsContainer.Visible = false
humanSettingsContainer.ZIndex = 2
humanSettingsContainer.AutomaticSize = Enum.AutomaticSize.Y

humanSettingsLayout = Instance.new("UIListLayout", humanSettingsContainer)
humanSettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
humanSettingsLayout.Padding = UDim.new(0, 5)

addDivider(humanSettingsContainer, "Basic Speed")

baseSpeedRow = Instance.new("Frame", humanSettingsContainer)
baseSpeedRow.Size = UDim2.new(1, 0, 0, 30)
baseSpeedRow.BackgroundTransparency = 1
baseSpeedRow.ZIndex = 2
baseSpeedLabel = newLabel(baseSpeedRow, "Base Speed (s)", 11)
baseSpeedLabel.Size = UDim2.new(0.52, 0, 1, 0)
baseSpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
baseSpeedInput = newBox(baseSpeedRow, tostring(config.humanBaseSpeed), 30)
baseSpeedInput.Size = UDim2.new(0.46, 0, 1, 0)
baseSpeedInput.Position = UDim2.new(0.54, 0, 0, 0)

variationRow = Instance.new("Frame", humanSettingsContainer)
variationRow.Size = UDim2.new(1, 0, 0, 30)
variationRow.BackgroundTransparency = 1
variationRow.ZIndex = 2
variationLabel = newLabel(variationRow, "Speed Variation", 11)
variationLabel.Size = UDim2.new(0.52, 0, 1, 0)
variationLabel.TextYAlignment = Enum.TextYAlignment.Center
variationInput = newBox(variationRow, tostring(config.humanVariation), 30)
variationInput.Size = UDim2.new(0.46, 0, 1, 0)
variationInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(humanSettingsContainer, "Natural Pauses")

pauseChanceRow = Instance.new("Frame", humanSettingsContainer)
pauseChanceRow.Size = UDim2.new(1, 0, 0, 30)
pauseChanceRow.BackgroundTransparency = 1
pauseChanceRow.ZIndex = 2
pauseChanceLabel = newLabel(pauseChanceRow, "Pause Chance (%)", 11)
pauseChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
pauseChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
pauseChanceInput = newBox(pauseChanceRow, tostring(config.humanPauseChance * 100), 30)
pauseChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
pauseChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

pauseDurationRow = Instance.new("Frame", humanSettingsContainer)
pauseDurationRow.Size = UDim2.new(1, 0, 0, 30)
pauseDurationRow.BackgroundTransparency = 1
pauseDurationRow.ZIndex = 2
pauseDurationLabel = newLabel(pauseDurationRow, "Pause Min/Max", 11)
pauseDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
pauseDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
pauseMinInput = newBox(pauseDurationRow, tostring(config.humanPauseMin), 30)
pauseMinInput.Size = UDim2.new(0.29, 0, 1, 0)
pauseMinInput.Position = UDim2.new(0.38, 0, 0, 0)
pauseMaxInput = newBox(pauseDurationRow, tostring(config.humanPauseMax), 30)
pauseMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
pauseMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

thinkingPauseChanceRow = Instance.new("Frame", humanSettingsContainer)
thinkingPauseChanceRow.Size = UDim2.new(1, 0, 0, 30)
thinkingPauseChanceRow.BackgroundTransparency = 1
thinkingPauseChanceRow.ZIndex = 2
thinkingPauseChanceLabel = newLabel(thinkingPauseChanceRow, "Think Pause (%)", 11)
thinkingPauseChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
thinkingPauseChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
thinkingPauseChanceInput = newBox(thinkingPauseChanceRow, tostring(config.humanThinkingPauseChance * 100), 30)
thinkingPauseChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
thinkingPauseChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

thinkingPauseDurationRow = Instance.new("Frame", humanSettingsContainer)
thinkingPauseDurationRow.Size = UDim2.new(1, 0, 0, 30)
thinkingPauseDurationRow.BackgroundTransparency = 1
thinkingPauseDurationRow.ZIndex = 2
thinkingPauseDurationLabel = newLabel(thinkingPauseDurationRow, "Think Min/Max", 11)
thinkingPauseDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
thinkingPauseDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
thinkingPauseMinInput = newBox(thinkingPauseDurationRow, tostring(config.humanThinkingPauseMin), 30)
thinkingPauseMinInput.Size = UDim2.new(0.29, 0, 1, 0)
thinkingPauseMinInput.Position = UDim2.new(0.38, 0, 0, 0)
thinkingPauseMaxInput = newBox(thinkingPauseDurationRow, tostring(config.humanThinkingPauseMax), 30)
thinkingPauseMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
thinkingPauseMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

wordStartPauseRow = Instance.new("Frame", humanSettingsContainer)
wordStartPauseRow.Size = UDim2.new(1, 0, 0, 30)
wordStartPauseRow.BackgroundTransparency = 1
wordStartPauseRow.ZIndex = 2
wordStartPauseLabel = newLabel(wordStartPauseRow, "Word Start Pause", 11)
wordStartPauseLabel.Size = UDim2.new(0.52, 0, 1, 0)
wordStartPauseLabel.TextYAlignment = Enum.TextYAlignment.Center
wordStartPauseInput = newBox(wordStartPauseRow, tostring(config.humanWordStartPause), 30)
wordStartPauseInput.Size = UDim2.new(0.46, 0, 1, 0)
wordStartPauseInput.Position = UDim2.new(0.54, 0, 0, 0)

wordEndPauseRow = Instance.new("Frame", humanSettingsContainer)
wordEndPauseRow.Size = UDim2.new(1, 0, 0, 30)
wordEndPauseRow.BackgroundTransparency = 1
wordEndPauseRow.ZIndex = 2
wordEndPauseLabel = newLabel(wordEndPauseRow, "Word End Pause", 11)
wordEndPauseLabel.Size = UDim2.new(0.52, 0, 1, 0)
wordEndPauseLabel.TextYAlignment = Enum.TextYAlignment.Center
wordEndPauseInput = newBox(wordEndPauseRow, tostring(config.humanWordEndPause), 30)
wordEndPauseInput.Size = UDim2.new(0.46, 0, 1, 0)
wordEndPauseInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(humanSettingsContainer, "Burst & Rhythm")

burstChanceRow = Instance.new("Frame", humanSettingsContainer)
burstChanceRow.Size = UDim2.new(1, 0, 0, 30)
burstChanceRow.BackgroundTransparency = 1
burstChanceRow.ZIndex = 2
burstChanceLabel = newLabel(burstChanceRow, "Burst Chance (%)", 11)
burstChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
burstChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
burstChanceInput = newBox(burstChanceRow, tostring(config.humanBurstChance * 100), 30)
burstChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
burstChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

burstSpeedRow = Instance.new("Frame", humanSettingsContainer)
burstSpeedRow.Size = UDim2.new(1, 0, 0, 30)
burstSpeedRow.BackgroundTransparency = 1
burstSpeedRow.ZIndex = 2
burstSpeedLabel = newLabel(burstSpeedRow, "Burst Multiplier", 11)
burstSpeedLabel.Size = UDim2.new(0.52, 0, 1, 0)
burstSpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
burstSpeedInput = newBox(burstSpeedRow, tostring(config.humanBurstSpeed), 30)
burstSpeedInput.Size = UDim2.new(0.46, 0, 1, 0)
burstSpeedInput.Position = UDim2.new(0.54, 0, 0, 0)

rhythmVariationRow = Instance.new("Frame", humanSettingsContainer)
rhythmVariationRow.Size = UDim2.new(1, 0, 0, 30)
rhythmVariationRow.BackgroundTransparency = 1
rhythmVariationRow.ZIndex = 2
rhythmVariationLabel = newLabel(rhythmVariationRow, "Rhythm Variation", 11)
rhythmVariationLabel.Size = UDim2.new(0.52, 0, 1, 0)
rhythmVariationLabel.TextYAlignment = Enum.TextYAlignment.Center
rhythmVariationToggle = newButton(rhythmVariationRow, config.humanRhythmVariation and "On" or "Off")
rhythmVariationToggle.Size = UDim2.new(0.46, 0, 1, 0)
rhythmVariationToggle.Position = UDim2.new(0.54, 0, 0, 0)

accelerationRow = Instance.new("Frame", humanSettingsContainer)
accelerationRow.Size = UDim2.new(1, 0, 0, 30)
accelerationRow.BackgroundTransparency = 1
accelerationRow.ZIndex = 2
accelerationLabel = newLabel(accelerationRow, "Acceleration", 11)
accelerationLabel.Size = UDim2.new(0.52, 0, 1, 0)
accelerationLabel.TextYAlignment = Enum.TextYAlignment.Center
accelerationInput = newBox(accelerationRow, tostring(config.humanAcceleration), 30)
accelerationInput.Size = UDim2.new(0.46, 0, 1, 0)
accelerationInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(humanSettingsContainer, "Fatigue")

fatigueRow = Instance.new("Frame", humanSettingsContainer)
fatigueRow.Size = UDim2.new(1, 0, 0, 30)
fatigueRow.BackgroundTransparency = 1
fatigueRow.ZIndex = 2
fatigueRowLabel = newLabel(fatigueRow, "Fatigue Effect", 11)
fatigueRowLabel.Size = UDim2.new(0.52, 0, 1, 0)
fatigueRowLabel.TextYAlignment = Enum.TextYAlignment.Center
fatigueToggle = newButton(fatigueRow, config.humanFatigue and "On" or "Off")
fatigueToggle.Size = UDim2.new(0.46, 0, 1, 0)
fatigueToggle.Position = UDim2.new(0.54, 0, 0, 0)

fatigueRateRow = Instance.new("Frame", humanSettingsContainer)
fatigueRateRow.Size = UDim2.new(1, 0, 0, 30)
fatigueRateRow.BackgroundTransparency = 1
fatigueRateRow.Visible = config.humanFatigue
fatigueRateRow.ZIndex = 2
fatigueRateLabel = newLabel(fatigueRateRow, "Fatigue Rate", 11)
fatigueRateLabel.Size = UDim2.new(0.52, 0, 1, 0)
fatigueRateLabel.TextYAlignment = Enum.TextYAlignment.Center
fatigueRateInput = newBox(fatigueRateRow, tostring(config.humanFatigueRate), 30)
fatigueRateInput.Size = UDim2.new(0.46, 0, 1, 0)
fatigueRateInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(humanSettingsContainer, "Speed Limits (Anti-Detection)")

speedLimitToggleRow = Instance.new("Frame", humanSettingsContainer)
speedLimitToggleRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitToggleRow.BackgroundTransparency = 1
speedLimitToggleRow.ZIndex = 2
speedLimitToggleLabel = newLabel(speedLimitToggleRow, "Enable L/S Limit", 11)
speedLimitToggleLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitToggle = newButton(speedLimitToggleRow, config.speedLimitEnabled and "On" or "Off")
speedLimitToggle.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitToggle.Position = UDim2.new(0.54, 0, 0, 0)

speedLimitLPSRow = Instance.new("Frame", humanSettingsContainer)
speedLimitLPSRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitLPSRow.BackgroundTransparency = 1
speedLimitLPSRow.Visible = config.speedLimitEnabled
speedLimitLPSRow.ZIndex = 2
speedLimitLPSLabel = newLabel(speedLimitLPSRow, "Letters/Second", 11)
speedLimitLPSLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitLPSLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitLPSInput = newBox(speedLimitLPSRow, tostring(config.speedLimitLPS), 30)
speedLimitLPSInput.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitLPSInput.Position = UDim2.new(0.54, 0, 0, 0)

speedLimitWPMToggleRow = Instance.new("Frame", humanSettingsContainer)
speedLimitWPMToggleRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitWPMToggleRow.BackgroundTransparency = 1
speedLimitWPMToggleRow.ZIndex = 2
speedLimitWPMToggleLabel = newLabel(speedLimitWPMToggleRow, "Enable WPM Limit", 11)
speedLimitWPMToggleLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitWPMToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitWPMToggle = newButton(speedLimitWPMToggleRow, config.speedLimitWPM and "On" or "Off")
speedLimitWPMToggle.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitWPMToggle.Position = UDim2.new(0.54, 0, 0, 0)

speedLimitWPMValueRow = Instance.new("Frame", humanSettingsContainer)
speedLimitWPMValueRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitWPMValueRow.BackgroundTransparency = 1
speedLimitWPMValueRow.Visible = config.speedLimitWPM
speedLimitWPMValueRow.ZIndex = 2
speedLimitWPMValueLabel = newLabel(speedLimitWPMValueRow, "Max WPM", 11)
speedLimitWPMValueLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitWPMValueLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitWPMValueInput = newBox(speedLimitWPMValueRow, tostring(config.speedLimitWPMValue), 30)
speedLimitWPMValueInput.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitWPMValueInput.Position = UDim2.new(0.54, 0, 0, 0)

speedLimitCPSToggleRow = Instance.new("Frame", humanSettingsContainer)
speedLimitCPSToggleRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitCPSToggleRow.BackgroundTransparency = 1
speedLimitCPSToggleRow.ZIndex = 2
speedLimitCPSToggleLabel = newLabel(speedLimitCPSToggleRow, "Enable CPS Limit", 11)
speedLimitCPSToggleLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitCPSToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitCPSToggle = newButton(speedLimitCPSToggleRow, config.speedLimitCPS and "On" or "Off")
speedLimitCPSToggle.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitCPSToggle.Position = UDim2.new(0.54, 0, 0, 0)

speedLimitCPSValueRow = Instance.new("Frame", humanSettingsContainer)
speedLimitCPSValueRow.Size = UDim2.new(1, 0, 0, 30)
speedLimitCPSValueRow.BackgroundTransparency = 1
speedLimitCPSValueRow.Visible = config.speedLimitCPS
speedLimitCPSValueRow.ZIndex = 2
speedLimitCPSValueLabel = newLabel(speedLimitCPSValueRow, "Chars/Second", 11)
speedLimitCPSValueLabel.Size = UDim2.new(0.52, 0, 1, 0)
speedLimitCPSValueLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLimitCPSValueInput = newBox(speedLimitCPSValueRow, tostring(config.speedLimitCPSValue), 30)
speedLimitCPSValueInput.Size = UDim2.new(0.46, 0, 1, 0)
speedLimitCPSValueInput.Position = UDim2.new(0.54, 0, 0, 0)

v3Title = newLabel(v3Page, "Auto Type V3 - Advanced", 14)
v3Title.TextXAlignment = Enum.TextXAlignment.Center
v3Title.TextColor3 = themes[config.theme].highlight

addSpacer(v3Page, 3)

v3ToggleRow = Instance.new("Frame", v3Page)
v3ToggleRow.Size = UDim2.new(1, 0, 0, 30)
v3ToggleRow.BackgroundTransparency = 1
v3ToggleRow.ZIndex = 2
v3ToggleLabel = newLabel(v3ToggleRow, "Enable Auto Type V3", 12)
v3ToggleLabel.Size = UDim2.new(0.6, 0, 1, 0)
v3ToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
v3Toggle = newButton(v3ToggleRow, "Off")
v3Toggle.Size = UDim2.new(0.38, 0, 1, 0)
v3Toggle.Position = UDim2.new(0.62, 0, 0, 0)

v3SettingsContainer = Instance.new("Frame", v3Page)
v3SettingsContainer.Size = UDim2.new(1, 0, 0, 10)
v3SettingsContainer.BackgroundTransparency = 1
v3SettingsContainer.Visible = false
v3SettingsContainer.ZIndex = 2
v3SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y

v3SettingsLayout = Instance.new("UIListLayout", v3SettingsContainer)
v3SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder
v3SettingsLayout.Padding = UDim.new(0, 5)

addDivider(v3SettingsContainer, "Base Speed")

v3SpeedRow = Instance.new("Frame", v3SettingsContainer)
v3SpeedRow.Size = UDim2.new(1, 0, 0, 30)
v3SpeedRow.BackgroundTransparency = 1
v3SpeedRow.ZIndex = 2
v3SpeedLabel = newLabel(v3SpeedRow, "Speed Min/Max", 11)
v3SpeedLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3SpeedLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MinDelayInput = newBox(v3SpeedRow, tostring(config.v3MinDelay), 30)
v3MinDelayInput.Size = UDim2.new(0.29, 0, 1, 0)
v3MinDelayInput.Position = UDim2.new(0.38, 0, 0, 0)
v3MaxDelayInput = newBox(v3SpeedRow, tostring(config.v3MaxDelay), 30)
v3MaxDelayInput.Size = UDim2.new(0.29, 0, 1, 0)
v3MaxDelayInput.Position = UDim2.new(0.69, 0, 0, 0)

v3RandomizationRow = Instance.new("Frame", v3SettingsContainer)
v3RandomizationRow.Size = UDim2.new(1, 0, 0, 30)
v3RandomizationRow.BackgroundTransparency = 1
v3RandomizationRow.ZIndex = 2
v3RandomizationLabel = newLabel(v3RandomizationRow, "Speed Randomization", 11)
v3RandomizationLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3RandomizationLabel.TextYAlignment = Enum.TextYAlignment.Center
v3RandomizationToggle = newButton(v3RandomizationRow, config.v3SpeedRandomization and "On" or "Off")
v3RandomizationToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3RandomizationToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3RandomAmountRow = Instance.new("Frame", v3SettingsContainer)
v3RandomAmountRow.Size = UDim2.new(1, 0, 0, 30)
v3RandomAmountRow.BackgroundTransparency = 1
v3RandomAmountRow.Visible = config.v3SpeedRandomization
v3RandomAmountRow.ZIndex = 2
v3RandomAmountLabel = newLabel(v3RandomAmountRow, "Random Amount", 11)
v3RandomAmountLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3RandomAmountLabel.TextYAlignment = Enum.TextYAlignment.Center
v3RandomAmountInput = newBox(v3RandomAmountRow, tostring(config.v3RandomizationAmount), 30)
v3RandomAmountInput.Size = UDim2.new(0.46, 0, 1, 0)
v3RandomAmountInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(v3SettingsContainer, "Human-Like Features")

v3HumanLikeRow = Instance.new("Frame", v3SettingsContainer)
v3HumanLikeRow.Size = UDim2.new(1, 0, 0, 30)
v3HumanLikeRow.BackgroundTransparency = 1
v3HumanLikeRow.ZIndex = 2
v3HumanLikeLabel = newLabel(v3HumanLikeRow, "Enable Human-Like", 11)
v3HumanLikeLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3HumanLikeLabel.TextYAlignment = Enum.TextYAlignment.Center
v3HumanLikeToggle = newButton(v3HumanLikeRow, config.v3HumanLike and "On" or "Off")
v3HumanLikeToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3HumanLikeToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3HumanContainer = Instance.new("Frame", v3SettingsContainer)
v3HumanContainer.Size = UDim2.new(1, 0, 0, 10)
v3HumanContainer.BackgroundTransparency = 1
v3HumanContainer.Visible = config.v3HumanLike
v3HumanContainer.ZIndex = 2
v3HumanContainer.AutomaticSize = Enum.AutomaticSize.Y

v3HumanLayout = Instance.new("UIListLayout", v3HumanContainer)
v3HumanLayout.SortOrder = Enum.SortOrder.LayoutOrder
v3HumanLayout.Padding = UDim.new(0, 5)

v3PauseChanceRow = Instance.new("Frame", v3HumanContainer)
v3PauseChanceRow.Size = UDim2.new(1, 0, 0, 30)
v3PauseChanceRow.BackgroundTransparency = 1
v3PauseChanceRow.ZIndex = 2
v3PauseChanceLabel = newLabel(v3PauseChanceRow, "Pause Chance (%)", 11)
v3PauseChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3PauseChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
v3PauseChanceInput = newBox(v3PauseChanceRow, tostring(config.v3PauseChance * 100), 30)
v3PauseChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
v3PauseChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

v3PauseDurationRow = Instance.new("Frame", v3HumanContainer)
v3PauseDurationRow.Size = UDim2.new(1, 0, 0, 30)
v3PauseDurationRow.BackgroundTransparency = 1
v3PauseDurationRow.ZIndex = 2
v3PauseDurationLabel = newLabel(v3PauseDurationRow, "Pause Min/Max", 11)
v3PauseDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3PauseDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
v3PauseMinInput = newBox(v3PauseDurationRow, tostring(config.v3PauseMin), 30)
v3PauseMinInput.Size = UDim2.new(0.29, 0, 1, 0)
v3PauseMinInput.Position = UDim2.new(0.38, 0, 0, 0)
v3PauseMaxInput = newBox(v3PauseDurationRow, tostring(config.v3PauseMax), 30)
v3PauseMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v3PauseMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

v3ThinkPauseChanceRow = Instance.new("Frame", v3HumanContainer)
v3ThinkPauseChanceRow.Size = UDim2.new(1, 0, 0, 30)
v3ThinkPauseChanceRow.BackgroundTransparency = 1
v3ThinkPauseChanceRow.ZIndex = 2
v3ThinkPauseChanceLabel = newLabel(v3ThinkPauseChanceRow, "Think Pause (%)", 11)
v3ThinkPauseChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3ThinkPauseChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
v3ThinkPauseChanceInput = newBox(v3ThinkPauseChanceRow, tostring(config.v3ThinkPauseChance * 100), 30)
v3ThinkPauseChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
v3ThinkPauseChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

v3ThinkPauseDurationRow = Instance.new("Frame", v3HumanContainer)
v3ThinkPauseDurationRow.Size = UDim2.new(1, 0, 0, 30)
v3ThinkPauseDurationRow.BackgroundTransparency = 1
v3ThinkPauseDurationRow.ZIndex = 2
v3ThinkPauseDurationLabel = newLabel(v3ThinkPauseDurationRow, "Think Min/Max", 11)
v3ThinkPauseDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3ThinkPauseDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
v3ThinkPauseMinInput = newBox(v3ThinkPauseDurationRow, tostring(config.v3ThinkPauseMin), 30)
v3ThinkPauseMinInput.Size = UDim2.new(0.29, 0, 1, 0)
v3ThinkPauseMinInput.Position = UDim2.new(0.38, 0, 0, 0)
v3ThinkPauseMaxInput = newBox(v3ThinkPauseDurationRow, tostring(config.v3ThinkPauseMax), 30)
v3ThinkPauseMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v3ThinkPauseMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

v3WordStartPauseRow = Instance.new("Frame", v3HumanContainer)
v3WordStartPauseRow.Size = UDim2.new(1, 0, 0, 30)
v3WordStartPauseRow.BackgroundTransparency = 1
v3WordStartPauseRow.ZIndex = 2
v3WordStartPauseLabel = newLabel(v3WordStartPauseRow, "Word Start Pause", 11)
v3WordStartPauseLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3WordStartPauseLabel.TextYAlignment = Enum.TextYAlignment.Center
v3WordStartPauseInput = newBox(v3WordStartPauseRow, tostring(config.v3WordStartPause), 30)
v3WordStartPauseInput.Size = UDim2.new(0.46, 0, 1, 0)
v3WordStartPauseInput.Position = UDim2.new(0.54, 0, 0, 0)

v3WordEndPauseRow = Instance.new("Frame", v3HumanContainer)
v3WordEndPauseRow.Size = UDim2.new(1, 0, 0, 30)
v3WordEndPauseRow.BackgroundTransparency = 1
v3WordEndPauseRow.ZIndex = 2
v3WordEndPauseLabel = newLabel(v3WordEndPauseRow, "Word End Pause", 11)
v3WordEndPauseLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3WordEndPauseLabel.TextYAlignment = Enum.TextYAlignment.Center
v3WordEndPauseInput = newBox(v3WordEndPauseRow, tostring(config.v3WordEndPause), 30)
v3WordEndPauseInput.Size = UDim2.new(0.46, 0, 1, 0)
v3WordEndPauseInput.Position = UDim2.new(0.54, 0, 0, 0)

v3BurstChanceRow = Instance.new("Frame", v3HumanContainer)
v3BurstChanceRow.Size = UDim2.new(1, 0, 0, 30)
v3BurstChanceRow.BackgroundTransparency = 1
v3BurstChanceRow.ZIndex = 2
v3BurstChanceLabel = newLabel(v3BurstChanceRow, "Burst Chance (%)", 11)
v3BurstChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3BurstChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
v3BurstChanceInput = newBox(v3BurstChanceRow, tostring(config.v3BurstChance * 100), 30)
v3BurstChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
v3BurstChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

v3BurstMultiplierRow = Instance.new("Frame", v3HumanContainer)
v3BurstMultiplierRow.Size = UDim2.new(1, 0, 0, 30)
v3BurstMultiplierRow.BackgroundTransparency = 1
v3BurstMultiplierRow.ZIndex = 2
v3BurstMultiplierLabel = newLabel(v3BurstMultiplierRow, "Burst Multiplier", 11)
v3BurstMultiplierLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3BurstMultiplierLabel.TextYAlignment = Enum.TextYAlignment.Center
v3BurstMultiplierInput = newBox(v3BurstMultiplierRow, tostring(config.v3BurstMultiplier), 30)
v3BurstMultiplierInput.Size = UDim2.new(0.46, 0, 1, 0)
v3BurstMultiplierInput.Position = UDim2.new(0.54, 0, 0, 0)

v3RhythmRow = Instance.new("Frame", v3HumanContainer)
v3RhythmRow.Size = UDim2.new(1, 0, 0, 30)
v3RhythmRow.BackgroundTransparency = 1
v3RhythmRow.ZIndex = 2
v3RhythmLabel = newLabel(v3RhythmRow, "Rhythm Variation", 11)
v3RhythmLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3RhythmLabel.TextYAlignment = Enum.TextYAlignment.Center
v3RhythmToggle = newButton(v3RhythmRow, config.v3RhythmVariation and "On" or "Off")
v3RhythmToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3RhythmToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3AccelerationRow = Instance.new("Frame", v3HumanContainer)
v3AccelerationRow.Size = UDim2.new(1, 0, 0, 30)
v3AccelerationRow.BackgroundTransparency = 1
v3AccelerationRow.ZIndex = 2
v3AccelerationLabel = newLabel(v3AccelerationRow, "Acceleration", 11)
v3AccelerationLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3AccelerationLabel.TextYAlignment = Enum.TextYAlignment.Center
v3AccelerationInput = newBox(v3AccelerationRow, tostring(config.v3Acceleration), 30)
v3AccelerationInput.Size = UDim2.new(0.46, 0, 1, 0)
v3AccelerationInput.Position = UDim2.new(0.54, 0, 0, 0)

v3FatigueRow = Instance.new("Frame", v3HumanContainer)
v3FatigueRow.Size = UDim2.new(1, 0, 0, 30)
v3FatigueRow.BackgroundTransparency = 1
v3FatigueRow.ZIndex = 2
v3FatigueLabel = newLabel(v3FatigueRow, "Fatigue Effect", 11)
v3FatigueLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3FatigueLabel.TextYAlignment = Enum.TextYAlignment.Center
v3FatigueToggle = newButton(v3FatigueRow, config.v3Fatigue and "On" or "Off")
v3FatigueToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3FatigueToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3FatigueRateRow = Instance.new("Frame", v3HumanContainer)
v3FatigueRateRow.Size = UDim2.new(1, 0, 0, 30)
v3FatigueRateRow.BackgroundTransparency = 1
v3FatigueRateRow.Visible = config.v3Fatigue
v3FatigueRateRow.ZIndex = 2
v3FatigueRateLabel = newLabel(v3FatigueRateRow, "Fatigue Rate", 11)
v3FatigueRateLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3FatigueRateLabel.TextYAlignment = Enum.TextYAlignment.Center
v3FatigueRateInput = newBox(v3FatigueRateRow, tostring(config.v3FatigueRate), 30)
v3FatigueRateInput.Size = UDim2.new(0.46, 0, 1, 0)
v3FatigueRateInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(v3SettingsContainer, "Error Simulation")

v3ErrorRow = Instance.new("Frame", v3SettingsContainer)
v3ErrorRow.Size = UDim2.new(1, 0, 0, 30)
v3ErrorRow.BackgroundTransparency = 1
v3ErrorRow.ZIndex = 2
v3ErrorLabel = newLabel(v3ErrorRow, "Enable Typo Errors", 11)
v3ErrorLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3ErrorLabel.TextYAlignment = Enum.TextYAlignment.Center
v3ErrorToggle = newButton(v3ErrorRow, config.v3ErrorSimulation and "On" or "Off")
v3ErrorToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3ErrorToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3ErrorContainer = Instance.new("Frame", v3SettingsContainer)
v3ErrorContainer.Size = UDim2.new(1, 0, 0, 10)
v3ErrorContainer.BackgroundTransparency = 1
v3ErrorContainer.Visible = config.v3ErrorSimulation
v3ErrorContainer.ZIndex = 2
v3ErrorContainer.AutomaticSize = Enum.AutomaticSize.Y

v3ErrorLayout = Instance.new("UIListLayout", v3ErrorContainer)
v3ErrorLayout.SortOrder = Enum.SortOrder.LayoutOrder
v3ErrorLayout.Padding = UDim.new(0, 5)

v3TypoChanceRow = Instance.new("Frame", v3ErrorContainer)
v3TypoChanceRow.Size = UDim2.new(1, 0, 0, 30)
v3TypoChanceRow.BackgroundTransparency = 1
v3TypoChanceRow.ZIndex = 2
v3TypoChanceLabel = newLabel(v3TypoChanceRow, "Typo Chance (%)", 11)
v3TypoChanceLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3TypoChanceLabel.TextYAlignment = Enum.TextYAlignment.Center
v3TypoChanceInput = newBox(v3TypoChanceRow, tostring(config.v3TypoChance * 100), 30)
v3TypoChanceInput.Size = UDim2.new(0.46, 0, 1, 0)
v3TypoChanceInput.Position = UDim2.new(0.54, 0, 0, 0)

v3TypoCorrectRow = Instance.new("Frame", v3ErrorContainer)
v3TypoCorrectRow.Size = UDim2.new(1, 0, 0, 30)
v3TypoCorrectRow.BackgroundTransparency = 1
v3TypoCorrectRow.ZIndex = 2
v3TypoCorrectLabel = newLabel(v3TypoCorrectRow, "Correction Delay", 11)
v3TypoCorrectLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3TypoCorrectLabel.TextYAlignment = Enum.TextYAlignment.Center
v3TypoCorrectInput = newBox(v3TypoCorrectRow, tostring(config.v3TypoCorrectDelay), 30)
v3TypoCorrectInput.Size = UDim2.new(0.46, 0, 1, 0)
v3TypoCorrectInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(v3SettingsContainer, "Timing Controls")

v3StartDelayRow = Instance.new("Frame", v3SettingsContainer)
v3StartDelayRow.Size = UDim2.new(1, 0, 0, 30)
v3StartDelayRow.BackgroundTransparency = 1
v3StartDelayRow.ZIndex = 2
v3StartDelayLabel = newLabel(v3StartDelayRow, "Custom Start Delay", 11)
v3StartDelayLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3StartDelayLabel.TextYAlignment = Enum.TextYAlignment.Center
v3StartDelayToggle = newButton(v3StartDelayRow, config.v3CustomStartDelay and "On" or "Off")
v3StartDelayToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3StartDelayToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3StartDelayValuesRow = Instance.new("Frame", v3SettingsContainer)
v3StartDelayValuesRow.Size = UDim2.new(1, 0, 0, 30)
v3StartDelayValuesRow.BackgroundTransparency = 1
v3StartDelayValuesRow.Visible = config.v3CustomStartDelay
v3StartDelayValuesRow.ZIndex = 2
v3StartDelayValuesLabel = newLabel(v3StartDelayValuesRow, "Start Min/Max", 11)
v3StartDelayValuesLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3StartDelayValuesLabel.TextYAlignment = Enum.TextYAlignment.Center
v3StartDelayMinInput = newBox(v3StartDelayValuesRow, tostring(config.v3StartDelayMin), 30)
v3StartDelayMinInput.Size = UDim2.new(0.29, 0, 1, 0)
v3StartDelayMinInput.Position = UDim2.new(0.38, 0, 0, 0)
v3StartDelayMaxInput = newBox(v3StartDelayValuesRow, tostring(config.v3StartDelayMax), 30)
v3StartDelayMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v3StartDelayMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

v3DoneDelayRow = Instance.new("Frame", v3SettingsContainer)
v3DoneDelayRow.Size = UDim2.new(1, 0, 0, 30)
v3DoneDelayRow.BackgroundTransparency = 1
v3DoneDelayRow.ZIndex = 2
v3DoneDelayLabel = newLabel(v3DoneDelayRow, "Custom Done Delay", 11)
v3DoneDelayLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3DoneDelayLabel.TextYAlignment = Enum.TextYAlignment.Center
v3DoneDelayToggle = newButton(v3DoneDelayRow, config.v3CustomDoneDelay and "On" or "Off")
v3DoneDelayToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3DoneDelayToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3DoneDelayValuesRow = Instance.new("Frame", v3SettingsContainer)
v3DoneDelayValuesRow.Size = UDim2.new(1, 0, 0, 30)
v3DoneDelayValuesRow.BackgroundTransparency = 1
v3DoneDelayValuesRow.Visible = config.v3CustomDoneDelay
v3DoneDelayValuesRow.ZIndex = 2
v3DoneDelayValuesLabel = newLabel(v3DoneDelayValuesRow, "Done Min/Max", 11)
v3DoneDelayValuesLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3DoneDelayValuesLabel.TextYAlignment = Enum.TextYAlignment.Center
v3DoneDelayMinInput = newBox(v3DoneDelayValuesRow, tostring(config.v3DoneDelayMin), 30)
v3DoneDelayMinInput.Size = UDim2.new(0.29, 0, 1, 0)
v3DoneDelayMinInput.Position = UDim2.new(0.38, 0, 0, 0)
v3DoneDelayMaxInput = newBox(v3DoneDelayValuesRow, tostring(config.v3DoneDelayMax), 30)
v3DoneDelayMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v3DoneDelayMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

addDivider(v3SettingsContainer, "Speed Limits")

v3SpeedLimitRow = Instance.new("Frame", v3SettingsContainer)
v3SpeedLimitRow.Size = UDim2.new(1, 0, 0, 30)
v3SpeedLimitRow.BackgroundTransparency = 1
v3SpeedLimitRow.ZIndex = 2
v3SpeedLimitLabel = newLabel(v3SpeedLimitRow, "Enable Speed Limit", 11)
v3SpeedLimitLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3SpeedLimitLabel.TextYAlignment = Enum.TextYAlignment.Center
v3SpeedLimitToggle = newButton(v3SpeedLimitRow, config.v3SpeedLimit and "On" or "Off")
v3SpeedLimitToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3SpeedLimitToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3MaxLPSRow = Instance.new("Frame", v3SettingsContainer)
v3MaxLPSRow.Size = UDim2.new(1, 0, 0, 30)
v3MaxLPSRow.BackgroundTransparency = 1
v3MaxLPSRow.Visible = config.v3SpeedLimit
v3MaxLPSRow.ZIndex = 2
v3MaxLPSLabel = newLabel(v3MaxLPSRow, "Max Letters/Sec", 11)
v3MaxLPSLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MaxLPSLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MaxLPSInput = newBox(v3MaxLPSRow, tostring(config.v3MaxLPS), 30)
v3MaxLPSInput.Size = UDim2.new(0.46, 0, 1, 0)
v3MaxLPSInput.Position = UDim2.new(0.54, 0, 0, 0)

v3MinLPSToggleRow = Instance.new("Frame", v3SettingsContainer)
v3MinLPSToggleRow.Size = UDim2.new(1, 0, 0, 30)
v3MinLPSToggleRow.BackgroundTransparency = 1
v3MinLPSToggleRow.ZIndex = 2
v3MinLPSToggleLabel = newLabel(v3MinLPSToggleRow, "Enable Min L/S", 11)
v3MinLPSToggleLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MinLPSToggleLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MinLPSToggle = newButton(v3MinLPSToggleRow, config.v3MinLPSEnabled and "On" or "Off")
v3MinLPSToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3MinLPSToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3MinLPSRow = Instance.new("Frame", v3SettingsContainer)
v3MinLPSRow.Size = UDim2.new(1, 0, 0, 30)
v3MinLPSRow.BackgroundTransparency = 1
v3MinLPSRow.Visible = config.v3MinLPSEnabled
v3MinLPSRow.ZIndex = 2
v3MinLPSLabel = newLabel(v3MinLPSRow, "Min Letters/Sec", 11)
v3MinLPSLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MinLPSLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MinLPSInput = newBox(v3MinLPSRow, tostring(config.v3MinLPS), 30)
v3MinLPSInput.Size = UDim2.new(0.46, 0, 1, 0)
v3MinLPSInput.Position = UDim2.new(0.54, 0, 0, 0)

v3MaxWPMRow = Instance.new("Frame", v3SettingsContainer)
v3MaxWPMRow.Size = UDim2.new(1, 0, 0, 30)
v3MaxWPMRow.BackgroundTransparency = 1
v3MaxWPMRow.ZIndex = 2
v3MaxWPMLabel = newLabel(v3MaxWPMRow, "Enable WPM Limit", 11)
v3MaxWPMLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MaxWPMLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MaxWPMToggle = newButton(v3MaxWPMRow, config.v3MaxWPM and "On" or "Off")
v3MaxWPMToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3MaxWPMToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3MaxWPMValueRow = Instance.new("Frame", v3SettingsContainer)
v3MaxWPMValueRow.Size = UDim2.new(1, 0, 0, 30)
v3MaxWPMValueRow.BackgroundTransparency = 1
v3MaxWPMValueRow.Visible = config.v3MaxWPM
v3MaxWPMValueRow.ZIndex = 2
v3MaxWPMValueLabel = newLabel(v3MaxWPMValueRow, "Max WPM", 11)
v3MaxWPMValueLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MaxWPMValueLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MaxWPMValueInput = newBox(v3MaxWPMValueRow, tostring(config.v3MaxWPMValue), 30)
v3MaxWPMValueInput.Size = UDim2.new(0.46, 0, 1, 0)
v3MaxWPMValueInput.Position = UDim2.new(0.54, 0, 0, 0)

v3MaxCPSRow = Instance.new("Frame", v3SettingsContainer)
v3MaxCPSRow.Size = UDim2.new(1, 0, 0, 30)
v3MaxCPSRow.BackgroundTransparency = 1
v3MaxCPSRow.ZIndex = 2
v3MaxCPSLabel = newLabel(v3MaxCPSRow, "Enable CPS Limit", 11)
v3MaxCPSLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MaxCPSLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MaxCPSToggle = newButton(v3MaxCPSRow, config.v3MaxCPS and "On" or "Off")
v3MaxCPSToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3MaxCPSToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3MaxCPSValueRow = Instance.new("Frame", v3SettingsContainer)
v3MaxCPSValueRow.Size = UDim2.new(1, 0, 0, 30)
v3MaxCPSValueRow.BackgroundTransparency = 1
v3MaxCPSValueRow.Visible = config.v3MaxCPS
v3MaxCPSValueRow.ZIndex = 2
v3MaxCPSValueLabel = newLabel(v3MaxCPSValueRow, "Chars/Second", 11)
v3MaxCPSValueLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3MaxCPSValueLabel.TextYAlignment = Enum.TextYAlignment.Center
v3MaxCPSValueInput = newBox(v3MaxCPSValueRow, tostring(config.v3MaxCPSValue), 30)
v3MaxCPSValueInput.Size = UDim2.new(0.46, 0, 1, 0)
v3MaxCPSValueInput.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(v3SettingsContainer, "Button Hold")

v3ButtonHoldRow = Instance.new("Frame", v3SettingsContainer)
v3ButtonHoldRow.Size = UDim2.new(1, 0, 0, 30)
v3ButtonHoldRow.BackgroundTransparency = 1
v3ButtonHoldRow.ZIndex = 2
v3ButtonHoldLabel = newLabel(v3ButtonHoldRow, "Enable Button Hold", 11)
v3ButtonHoldLabel.Size = UDim2.new(0.52, 0, 1, 0)
v3ButtonHoldLabel.TextYAlignment = Enum.TextYAlignment.Center
v3ButtonHoldToggle = newButton(v3ButtonHoldRow, config.v3ButtonHold and "On" or "Off")
v3ButtonHoldToggle.Size = UDim2.new(0.46, 0, 1, 0)
v3ButtonHoldToggle.Position = UDim2.new(0.54, 0, 0, 0)

v3ButtonHoldDurationRow = Instance.new("Frame", v3SettingsContainer)
v3ButtonHoldDurationRow.Size = UDim2.new(1, 0, 0, 30)
v3ButtonHoldDurationRow.BackgroundTransparency = 1
v3ButtonHoldDurationRow.Visible = config.v3ButtonHold
v3ButtonHoldDurationRow.ZIndex = 2
v3ButtonHoldDurationLabel = newLabel(v3ButtonHoldDurationRow, "Hold Min/Max (s)", 11)
v3ButtonHoldDurationLabel.Size = UDim2.new(0.36, 0, 1, 0)
v3ButtonHoldDurationLabel.TextYAlignment = Enum.TextYAlignment.Center
v3ButtonHoldMinInput = newBox(v3ButtonHoldDurationRow, tostring(config.v3ButtonHoldMin), 30)
v3ButtonHoldMinInput.Size = UDim2.new(0.29, 0, 1, 0)
v3ButtonHoldMinInput.Position = UDim2.new(0.38, 0, 0, 0)
v3ButtonHoldMaxInput = newBox(v3ButtonHoldDurationRow, tostring(config.v3ButtonHoldMax), 30)
v3ButtonHoldMaxInput.Size = UDim2.new(0.29, 0, 1, 0)
v3ButtonHoldMaxInput.Position = UDim2.new(0.69, 0, 0, 0)

configTitle = newLabel(configPage, "Configuration", 14)
configTitle.TextXAlignment = Enum.TextXAlignment.Center
configTitle.TextColor3 = themes[config.theme].highlight

addSpacer(configPage, 4)

saveRow = Instance.new("Frame", configPage)
saveRow.Size = UDim2.new(1, 0, 0, 30)
saveRow.BackgroundTransparency = 1
saveRow.ZIndex = 2
saveConfigButton = newButton(saveRow, "Save Config")
saveConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
loadConfigButton = newButton(saveRow, "Load Config")
loadConfigButton.Size = UDim2.new(0.48, 0, 1, 0)
loadConfigButton.Position = UDim2.new(0.52, 0, 0, 0)

addSpacer(configPage, 4)

autoLoadRow = Instance.new("Frame", configPage)
autoLoadRow.Size = UDim2.new(1, 0, 0, 30)
autoLoadRow.BackgroundTransparency = 1
autoLoadRow.ZIndex = 2
autoLoadLabel = newLabel(autoLoadRow, "Auto Load Config", 11)
autoLoadLabel.Size = UDim2.new(0.52, 0, 1, 0)
autoLoadLabel.TextYAlignment = Enum.TextYAlignment.Center
autoLoadToggle = newButton(autoLoadRow, config.autoLoadConfig and "On" or "Off")
autoLoadToggle.Size = UDim2.new(0.46, 0, 1, 0)
autoLoadToggle.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(configPage, "Appearance")

themeLabel = newLabel(configPage, "Theme", 12)
themeLabel.Size = UDim2.new(1, 0, 0, 18)

themeDropdownFrame = Instance.new("Frame", configPage)
themeDropdownFrame.Size = UDim2.new(1, 0, 0, 30)
themeDropdownFrame.BackgroundColor3 = themes[config.theme].secondary
themeDropdownFrame.BorderSizePixel = 0
themeDropdownFrame.ZIndex = 2

themeDropdownCorner = Instance.new("UICorner", themeDropdownFrame)
themeDropdownCorner.CornerRadius = UDim.new(0, 7)

themeDropdownStroke = Instance.new("UIStroke", themeDropdownFrame)
themeDropdownStroke.Color = themes[config.theme].accent
themeDropdownStroke.Thickness = 1
themeDropdownStroke.Transparency = 0.6

applyUIElementEffects(themeDropdownFrame)

themeDropdownButton = Instance.new("TextButton", themeDropdownFrame)
themeDropdownButton.Size = UDim2.new(1, 0, 1, 0)
themeDropdownButton.BackgroundTransparency = 1
themeDropdownButton.Text = config.theme
themeDropdownButton.TextColor3 = themes[config.theme].text
themeDropdownButton.Font = Enum.Font.GothamSemibold
themeDropdownButton.TextSize = 12
themeDropdownButton.ZIndex = 3

themeDropdownExpanded = false
themeDropdownList = Instance.new("ScrollingFrame", gui)
themeDropdownList.Size = UDim2.new(0, 248, 0, 0)
themeDropdownList.Position = themeDropdownFrame.Position
themeDropdownList.BackgroundColor3 = themes[config.theme].secondary
themeDropdownList.BorderSizePixel = 0
themeDropdownList.Visible = false
themeDropdownList.ZIndex = 100
themeDropdownList.ScrollBarThickness = 3

themeDropdownListCorner = Instance.new("UICorner", themeDropdownList)
themeDropdownListCorner.CornerRadius = UDim.new(0, 7)

themeDropdownListStroke = Instance.new("UIStroke", themeDropdownList)
themeDropdownListStroke.Color = themes[config.theme].accent
themeDropdownListStroke.Thickness = 1
themeDropdownListStroke.Transparency = 0.6

themeDropdownLayout = Instance.new("UIListLayout", themeDropdownList)
themeDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
themeDropdownLayout.Padding = UDim.new(0, 2)

addSpacer(configPage, 4)

transparencyLabel = newLabel(configPage, "Frame Transparency", 12)
transparencyLabel.Size = UDim2.new(1, 0, 0, 18)

transparencySliderFrame = Instance.new("Frame", configPage)
transparencySliderFrame.Size = UDim2.new(1, 0, 0, 36)
transparencySliderFrame.BackgroundColor3 = themes[config.theme].secondary
transparencySliderFrame.BorderSizePixel = 0
transparencySliderFrame.ZIndex = 2

transparencySliderCorner = Instance.new("UICorner", transparencySliderFrame)
transparencySliderCorner.CornerRadius = UDim.new(0, 7)

transparencySliderStroke = Instance.new("UIStroke", transparencySliderFrame)
transparencySliderStroke.Color = themes[config.theme].accent
transparencySliderStroke.Thickness = 1
transparencySliderStroke.Transparency = 0.6

applyUIElementEffects(transparencySliderFrame)

transparencySliderBar = Instance.new("Frame", transparencySliderFrame)
transparencySliderBar.Size = UDim2.new(0.85, 0, 0, 5)
transparencySliderBar.Position = UDim2.new(0.075, 0, 0.5, -2.5)
transparencySliderBar.BackgroundColor3 = themes[config.theme].accent
transparencySliderBar.BorderSizePixel = 0
transparencySliderBar.ZIndex = 3

transparencySliderBarCorner = Instance.new("UICorner", transparencySliderBar)
transparencySliderBarCorner.CornerRadius = UDim.new(1, 0)

transparencySliderHandle = Instance.new("TextButton", transparencySliderBar)
transparencySliderHandle.Size = UDim2.new(0, 18, 0, 18)
transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -9, 0.5, -9)
transparencySliderHandle.BackgroundColor3 = themes[config.theme].highlight
transparencySliderHandle.BorderSizePixel = 0
transparencySliderHandle.Text = ""
transparencySliderHandle.ZIndex = 4

transparencySliderHandleCorner = Instance.new("UICorner", transparencySliderHandle)
transparencySliderHandleCorner.CornerRadius = UDim.new(1, 0)

transparencyValueLabel = newLabel(transparencySliderFrame, string.format("%.2f", config.transparency), 10)
transparencyValueLabel.Size = UDim2.new(1, 0, 1, 0)
transparencyValueLabel.TextXAlignment = Enum.TextXAlignment.Center
transparencyValueLabel.TextYAlignment = Enum.TextYAlignment.Center
transparencyValueLabel.ZIndex = 3

addSpacer(configPage, 4)

acrylicRow = Instance.new("Frame", configPage)
acrylicRow.Size = UDim2.new(1, 0, 0, 30)
acrylicRow.BackgroundTransparency = 1
acrylicRow.ZIndex = 2
acrylicLabel = newLabel(acrylicRow, "Frame Acrylic Effect", 11)
acrylicLabel.Size = UDim2.new(0.52, 0, 1, 0)
acrylicLabel.TextYAlignment = Enum.TextYAlignment.Center
acrylicToggle = newButton(acrylicRow, config.acrylic and "On" or "Off")
acrylicToggle.Size = UDim2.new(0.46, 0, 1, 0)
acrylicToggle.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(configPage, "UI Elements")

uiElementTransparencyLabel = newLabel(configPage, "UI Element Transparency", 12)
uiElementTransparencyLabel.Size = UDim2.new(1, 0, 0, 18)

uiElementTransparencySliderFrame = Instance.new("Frame", configPage)
uiElementTransparencySliderFrame.Size = UDim2.new(1, 0, 0, 36)
uiElementTransparencySliderFrame.BackgroundColor3 = themes[config.theme].secondary
uiElementTransparencySliderFrame.BorderSizePixel = 0
uiElementTransparencySliderFrame.ZIndex = 2

uiElementTransparencySliderCorner = Instance.new("UICorner", uiElementTransparencySliderFrame)
uiElementTransparencySliderCorner.CornerRadius = UDim.new(0, 7)

uiElementTransparencySliderStroke = Instance.new("UIStroke", uiElementTransparencySliderFrame)
uiElementTransparencySliderStroke.Color = themes[config.theme].accent
uiElementTransparencySliderStroke.Thickness = 1
uiElementTransparencySliderStroke.Transparency = 0.6

applyUIElementEffects(uiElementTransparencySliderFrame)

uiElementTransparencySliderBar = Instance.new("Frame", uiElementTransparencySliderFrame)
uiElementTransparencySliderBar.Size = UDim2.new(0.85, 0, 0, 5)
uiElementTransparencySliderBar.Position = UDim2.new(0.075, 0, 0.5, -2.5)
uiElementTransparencySliderBar.BackgroundColor3 = themes[config.theme].accent
uiElementTransparencySliderBar.BorderSizePixel = 0
uiElementTransparencySliderBar.ZIndex = 3

uiElementTransparencySliderBarCorner = Instance.new("UICorner", uiElementTransparencySliderBar)
uiElementTransparencySliderBarCorner.CornerRadius = UDim.new(1, 0)

uiElementTransparencySliderHandle = Instance.new("TextButton", uiElementTransparencySliderBar)
uiElementTransparencySliderHandle.Size = UDim2.new(0, 18, 0, 18)
uiElementTransparencySliderHandle.Position = UDim2.new(config.uiElementTransparency, -9, 0.5, -9)
uiElementTransparencySliderHandle.BackgroundColor3 = themes[config.theme].highlight
uiElementTransparencySliderHandle.BorderSizePixel = 0
uiElementTransparencySliderHandle.Text = ""
uiElementTransparencySliderHandle.ZIndex = 4

uiElementTransparencySliderHandleCorner = Instance.new("UICorner", uiElementTransparencySliderHandle)
uiElementTransparencySliderHandleCorner.CornerRadius = UDim.new(1, 0)

uiElementTransparencyValueLabel = newLabel(uiElementTransparencySliderFrame, string.format("%.2f", config.uiElementTransparency), 10)
uiElementTransparencyValueLabel.Size = UDim2.new(1, 0, 1, 0)
uiElementTransparencyValueLabel.TextXAlignment = Enum.TextXAlignment.Center
uiElementTransparencyValueLabel.TextYAlignment = Enum.TextYAlignment.Center
uiElementTransparencyValueLabel.ZIndex = 3

addSpacer(configPage, 4)

uiElementAcrylicRow = Instance.new("Frame", configPage)
uiElementAcrylicRow.Size = UDim2.new(1, 0, 0, 30)
uiElementAcrylicRow.BackgroundTransparency = 1
uiElementAcrylicRow.ZIndex = 2
uiElementAcrylicLabel = newLabel(uiElementAcrylicRow, "UI Element Acrylic", 11)
uiElementAcrylicLabel.Size = UDim2.new(0.52, 0, 1, 0)
uiElementAcrylicLabel.TextYAlignment = Enum.TextYAlignment.Center
uiElementAcrylicToggle = newButton(uiElementAcrylicRow, config.uiElementAcrylic and "On" or "Off")
uiElementAcrylicToggle.Size = UDim2.new(0.46, 0, 1, 0)
uiElementAcrylicToggle.Position = UDim2.new(0.54, 0, 0, 0)

addDivider(configPage, "Debug")

debugOverlayRow = Instance.new("Frame", configPage)
debugOverlayRow.Size = UDim2.new(1, 0, 0, 30)
debugOverlayRow.BackgroundTransparency = 1
debugOverlayRow.ZIndex = 2
debugOverlayLabel = newLabel(debugOverlayRow, "Debug Overlay", 11)
debugOverlayLabel.Size = UDim2.new(0.52, 0, 1, 0)
debugOverlayLabel.TextYAlignment = Enum.TextYAlignment.Center
debugOverlayToggle = newButton(debugOverlayRow, config.debugOverlay and "On" or "Off")
debugOverlayToggle.Size = UDim2.new(0.46, 0, 1, 0)
debugOverlayToggle.Position = UDim2.new(0.54, 0, 0, 0)

addSpacer(configPage, 4)

debugTextSizeLabel = newLabel(configPage, "Debug Text Size", 12)
debugTextSizeLabel.Size = UDim2.new(1, 0, 0, 18)

debugTextSizeSliderFrame = Instance.new("Frame", configPage)
debugTextSizeSliderFrame.Size = UDim2.new(1, 0, 0, 36)
debugTextSizeSliderFrame.BackgroundColor3 = themes[config.theme].secondary
debugTextSizeSliderFrame.BorderSizePixel = 0
debugTextSizeSliderFrame.ZIndex = 2

debugTextSizeSliderCorner = Instance.new("UICorner", debugTextSizeSliderFrame)
debugTextSizeSliderCorner.CornerRadius = UDim.new(0, 7)

debugTextSizeSliderStroke = Instance.new("UIStroke", debugTextSizeSliderFrame)
debugTextSizeSliderStroke.Color = themes[config.theme].accent
debugTextSizeSliderStroke.Thickness = 1
debugTextSizeSliderStroke.Transparency = 0.6

applyUIElementEffects(debugTextSizeSliderFrame)

debugTextSizeSliderBar = Instance.new("Frame", debugTextSizeSliderFrame)
debugTextSizeSliderBar.Size = UDim2.new(0.85, 0, 0, 5)
debugTextSizeSliderBar.Position = UDim2.new(0.075, 0, 0.5, -2.5)
debugTextSizeSliderBar.BackgroundColor3 = themes[config.theme].accent
debugTextSizeSliderBar.BorderSizePixel = 0
debugTextSizeSliderBar.ZIndex = 3

debugTextSizeSliderBarCorner = Instance.new("UICorner", debugTextSizeSliderBar)
debugTextSizeSliderBarCorner.CornerRadius = UDim.new(1, 0)

local sizeRange = 20
local normalizedSize = (config.debugTextSize - 10) / sizeRange

debugTextSizeSliderHandle = Instance.new("TextButton", debugTextSizeSliderBar)
debugTextSizeSliderHandle.Size = UDim2.new(0, 18, 0, 18)
debugTextSizeSliderHandle.Position = UDim2.new(normalizedSize, -9, 0.5, -9)
debugTextSizeSliderHandle.BackgroundColor3 = themes[config.theme].highlight
debugTextSizeSliderHandle.BorderSizePixel = 0
debugTextSizeSliderHandle.Text = ""
debugTextSizeSliderHandle.ZIndex = 4

debugTextSizeSliderHandleCorner = Instance.new("UICorner", debugTextSizeSliderHandle)
debugTextSizeSliderHandleCorner.CornerRadius = UDim.new(1, 0)

debugTextSizeValueLabel = newLabel(debugTextSizeSliderFrame, tostring(config.debugTextSize), 10)
debugTextSizeValueLabel.Size = UDim2.new(1, 0, 1, 0)
debugTextSizeValueLabel.TextXAlignment = Enum.TextXAlignment.Center
debugTextSizeValueLabel.TextYAlignment = Enum.TextYAlignment.Center
debugTextSizeValueLabel.ZIndex = 3

addDivider(configPage, "Dictionary")

reloadDictButton = newButton(configPage, "Reload Dictionary")
reloadDictButton.Size = UDim2.new(1, 0, 0, 30)

infoTitle = newLabel(infoPage, "Information", 14)
infoTitle.TextXAlignment = Enum.TextXAlignment.Center
infoTitle.TextColor3 = themes[config.theme].highlight

addSpacer(infoPage, 3)

infoNavRow = Instance.new("Frame", infoPage)
infoNavRow.Size = UDim2.new(1, 0, 0, 30)
infoNavRow.BackgroundTransparency = 1
infoNavRow.ZIndex = 2

infoPageDictionaryBtn = newButton(infoNavRow, "Dictionary")
infoPageDictionaryBtn.Size = UDim2.new(0.48, 0, 1, 0)
infoPageV3GuideBtn = newButton(infoNavRow, "V3 Guide")
infoPageV3GuideBtn.Size = UDim2.new(0.48, 0, 1, 0)
infoPageV3GuideBtn.Position = UDim2.new(0.52, 0, 0, 0)

dictionaryInfoContainer = Instance.new("Frame", infoPage)
dictionaryInfoContainer.Size = UDim2.new(1, 0, 0, 10)
dictionaryInfoContainer.BackgroundTransparency = 1
dictionaryInfoContainer.Visible = true
dictionaryInfoContainer.ZIndex = 2
dictionaryInfoContainer.AutomaticSize = Enum.AutomaticSize.Y

dictionaryInfoLayout = Instance.new("UIListLayout", dictionaryInfoContainer)
dictionaryInfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
dictionaryInfoLayout.Padding = UDim.new(0, 5)

addDivider(dictionaryInfoContainer, "Definition Search")

meaningInput = newBox(dictionaryInfoContainer, "Enter word...")
meaningInput.PlaceholderText = "Enter word..."

meaningSearchButton = newButton(dictionaryInfoContainer, "Search Definition")
meaningSearchButton.Size = UDim2.new(1, 0, 0, 30)

copyDefButton = newButton(dictionaryInfoContainer, "Copy Definition")
copyDefButton.Size = UDim2.new(1, 0, 0, 30)

meaningOutputFrame = Instance.new("Frame", dictionaryInfoContainer)
meaningOutputFrame.Size = UDim2.new(1, 0, 0, 140)
meaningOutputFrame.BackgroundColor3 = themes[config.theme].secondary
meaningOutputFrame.BorderSizePixel = 0
meaningOutputFrame.ZIndex = 2

meaningOutputCorner = Instance.new("UICorner", meaningOutputFrame)
meaningOutputCorner.CornerRadius = UDim.new(0, 7)

meaningOutputStroke = Instance.new("UIStroke", meaningOutputFrame)
meaningOutputStroke.Color = themes[config.theme].accent
meaningOutputStroke.Thickness = 1
meaningOutputStroke.Transparency = 0.6

applyUIElementEffects(meaningOutputFrame)

meaningOutput = newLabel(meaningOutputFrame, "Definition will appear here...", 10)
meaningOutput.Size = UDim2.new(1, -10, 1, -10)
meaningOutput.Position = UDim2.new(0, 5, 0, 5)
meaningOutput.TextWrapped = true
meaningOutput.TextYAlignment = Enum.TextYAlignment.Top
meaningOutput.TextXAlignment = Enum.TextXAlignment.Left
meaningOutput.ZIndex = 3

v3GuideContainer = Instance.new("ScrollingFrame", infoPage)
v3GuideContainer.Size = UDim2.new(1, 0, 1, -48)
v3GuideContainer.BackgroundColor3 = themes[config.theme].secondary
v3GuideContainer.BorderSizePixel = 0
v3GuideContainer.Visible = false
v3GuideContainer.ScrollBarThickness = 3
v3GuideContainer.ScrollBarImageColor3 = themes[config.theme].accent
v3GuideContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
v3GuideContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
v3GuideContainer.ZIndex = 2

v3GuideCorner = Instance.new("UICorner", v3GuideContainer)
v3GuideCorner.CornerRadius = UDim.new(0, 7)

v3GuideStroke = Instance.new("UIStroke", v3GuideContainer)
v3GuideStroke.Color = themes[config.theme].accent
v3GuideStroke.Thickness = 1
v3GuideStroke.Transparency = 0.6

applyUIElementEffects(v3GuideContainer)

v3GuideLayout = Instance.new("UIListLayout", v3GuideContainer)
v3GuideLayout.SortOrder = Enum.SortOrder.LayoutOrder
v3GuideLayout.Padding = UDim.new(0, 8)

v3GuidePadding = Instance.new("UIPadding", v3GuideContainer)
v3GuidePadding.PaddingLeft = UDim.new(0, 10)
v3GuidePadding.PaddingRight = UDim.new(0, 10)
v3GuidePadding.PaddingTop = UDim.new(0, 10)
v3GuidePadding.PaddingBottom = UDim2.new(0, 10)

local function addGuideSection(title, content)
	local section = Instance.new("Frame", v3GuideContainer)
	section.Size = UDim2.new(1, -20, 0, 10)
	section.BackgroundTransparency = 1
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.ZIndex = 3
	
	local sectionLayout = Instance.new("UIListLayout", section)
	sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sectionLayout.Padding = UDim.new(0, 4)
	
	local titleLabel = newLabel(section, title, 12)
	titleLabel.Size = UDim2.new(1, 0, 0, 18)
	titleLabel.TextColor3 = themes[config.theme].highlight
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.ZIndex = 3
	
	local contentLabel = newLabel(section, content, 10)
	contentLabel.Size = UDim2.new(1, 0, 0, 10)
	contentLabel.TextWrapped = true
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.AutomaticSize = Enum.AutomaticSize.Y
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.ZIndex = 3
	
	return section
end

addGuideSection("📘 What is Auto Type V3?", 
"Auto Type V3 is the most advanced and customizable auto-typing system. It's designed to be semi-legit with extensive options to simulate natural human typing patterns while giving you full control over every aspect of the typing behavior.")

addGuideSection("⚡ Base Speed (Min/Max)", 
"Controls how fast each letter is typed.\n• LOWER values (0.05-0.10s) = Very fast typing\n• HIGHER values (0.15-0.25s) = Slower, more human-like\n• Recommended: 0.08-0.18 for semi-legit play")

addGuideSection("🎲 Speed Randomization", 
"Adds variation to typing speed to avoid robotic patterns.\n• Random Amount: How much variation is applied\n• LOWER (0.05-0.10) = Slight variation\n• HIGHER (0.15-0.30) = More unpredictable\n• Recommended: 0.35 for natural feel")

addGuideSection("🧠 Human-Like Features", 
"Enable this to activate all natural typing behaviors.\n\n⏸️ Pause Chance: Probability of brief hesitations\n• LOWER (5-10%) = Confident typing\n• HIGHER (15-25%) = More thoughtful\n\n💭 Think Pause: Longer pauses as if thinking\n• Use sparingly (5-10%) for realism\n• Duration: 0.4-1.2s simulates reading/thinking")

addGuideSection("🎯 Word Start/End Pauses", 
"Delays at the beginning and end of words.\n• Word Start: Brief pause before typing (0.10-0.20s)\n• Word End: Pause after completing (0.10-0.15s)\n• Simulates natural word boundaries")

addGuideSection("⚡ Burst Typing", 
"Occasionally type faster (like when you know what to type).\n• Burst Chance: How often bursts occur (10-15%)\n• Burst Multiplier: Speed during burst (0.6-0.8)\n• LOWER multiplier = FASTER during burst")

addGuideSection("🌊 Rhythm Variation", 
"Creates a flowing, wave-like typing rhythm.\n• Mimics natural speed fluctuations\n• Recommended: ON for human-like typing")

addGuideSection("🚀 Acceleration", 
"Gradually type faster as you continue the word.\n• LOWER (0.01-0.02) = Slight speedup\n• HIGHER (0.03-0.05) = Noticeable acceleration\n• Simulates gaining confidence mid-word")

addGuideSection("😴 Fatigue Effect", 
"Gradually slow down after typing many characters.\n• Simulates getting tired\n• Fatigue Rate: How quickly you 'tire'\n• LOWER (0.01-0.015) = Subtle effect\n• HIGHER (0.02-0.03) = More noticeable slowdown")

addGuideSection("❌ Error Simulation", 
"Randomly makes typos and corrects them.\n• Typo Chance: How often mistakes occur (2-5%)\n• Correction Delay: Pause before fixing (0.2-0.4s)\n• Adds realism but may be risky in competitive play")

addGuideSection("⏱️ Custom Start Delay", 
"How long to wait before starting to type.\n• LOWER (0.3-0.8s) = Quick reaction\n• HIGHER (0.8-2.0s) = Slower, more human\n• Randomized between min/max")

addGuideSection("✅ Custom Done Delay", 
"Delay before pressing 'Done' after typing.\n• LOWER (0.05-0.15s) = Fast submission\n• HIGHER (0.15-0.30s) = More natural\n• Simulates double-checking your word")

addGuideSection("🎮 Button Hold", 
"Simulates holding the mouse button down briefly.\n• Hold Duration: 0.05-0.15s typical\n• Adds realism to key presses\n• May feel more like physical typing")

addGuideSection("🚦 Speed Limits (Anti-Detection)", 
"Hard caps on typing speed for safety.\n\n📊 Max Letters/Second (LPS):\n• Ceiling: 5-7 for very safe play\n• Prevents typing FASTER than this\n\n📊 Min Letters/Second (LPS):\n• Floor: 2-3 prevents being too slow\n• Prevents typing SLOWER than this\n\n📝 Words Per Minute (WPM):\n• Average human: 40-60 WPM\n• Fast typist: 70-90 WPM\n• Expert: 90-120 WPM\n\n⌨️ Characters/Second (CPS):\n• Similar to LPS but counts all chars\n• Recommended: 6-10 for safety")

addGuideSection("🎓 Recommended Presets", 
"ULTRA SAFE (Very Human-Like):\n• Speed: 0.12-0.20s\n• All human features: ON\n• Max LPS: 5, Min LPS: 2\n\nBALANCED (Semi-Legit):\n• Speed: 0.08-0.18s\n• Human features: ON\n• Max LPS: 6, Min LPS: 2\n\nFAST (Risky):\n• Speed: 0.05-0.12s\n• Minimal pauses\n• Max LPS: 8, Min LPS: 3")

addGuideSection("⚠️ Important Tips", 
"• Start with HIGHER values and tune down\n• Enable speed limits for safety\n• Use error simulation sparingly\n• Monitor your stats in debug overlay\n• Adjust based on how you type naturally\n• V3 disables V1, V2, and standalone Human mode\n• Min L/S prevents TOO SLOW typing\n• Max L/S prevents TOO FAST typing")

infoPageDictionaryBtn.MouseButton1Click:Connect(function()
	dictionaryInfoContainer.Visible = true
	v3GuideContainer.Visible = false
end)

infoPageV3GuideBtn.MouseButton1Click:Connect(function()
	dictionaryInfoContainer.Visible = false
	v3GuideContainer.Visible = true
end)

debugOverlayFrame = Instance.new("Frame", gui)
debugOverlayFrame.Size = UDim2.new(0, 200, 0, 200)
debugOverlayFrame.Position = UDim2.new(0, 10, 0, 10)
debugOverlayFrame.BackgroundTransparency = 1
debugOverlayFrame.BorderSizePixel = 0
debugOverlayFrame.Visible = config.debugOverlay
debugOverlayFrame.ZIndex = 1000

debugOverlayLayout = Instance.new("UIListLayout", debugOverlayFrame)
debugOverlayLayout.SortOrder = Enum.SortOrder.LayoutOrder
debugOverlayLayout.Padding = UDim.new(0, 2)

local function createDebugLabel(text, order)
	local lbl = Instance.new("TextLabel", debugOverlayFrame)
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.Font = Enum.Font.Code
	lbl.TextSize = config.debugTextSize
	lbl.TextColor3 = Color3.fromRGB(50, 255, 100)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextStrokeTransparency = 0.5
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.ZIndex = 1001
	lbl.LayoutOrder = order
	lbl.RichText = true
	return lbl
end

debugFpsLabel = createDebugLabel("FPS: 0", 1)
debugPingLabel = createDebugLabel("Ping: 0ms", 2)
debugWpmLabel = createDebugLabel("WPM: 0", 3)
debugEtcLabel = createDebugLabel("ETC: 0.0s", 4)
debugDictLabel = createDebugLabel("Dict: 0", 5)
debugMatchLabel = createDebugLabel("Matches: 0", 6)
debugSafetyLabel = createDebugLabel("Safety: OK", 7)
debugTimerLabel = createDebugLabel("Timer: --", 8)

local lastFpsUpdate = 0
local fpsCounter = 0
local fpsValue = 0
local lastPingCheck = 0
local pingValue = 0

local rainbowCache = {}
local function getRainbowColor(position, total)
	local key = string.format("%d_%d", position, total)
	if rainbowCache[key] then
		return rainbowCache[key]
	end
	
	local hue = (position / math.max(total, 1)) % 1
	local saturation = 0.8
	local value = 1.0
	
	local c = value * saturation
	local x = c * (1 - math.abs((hue * 6) % 2 - 1))
	local m = value - c
	
	local r, g, b
	if hue < 1/6 then
		r, g, b = c, x, 0
	elseif hue < 2/6 then
		r, g, b = x, c, 0
	elseif hue < 3/6 then
		r, g, b = 0, c, x
	elseif hue < 4/6 then
		r, g, b = 0, x, c
	elseif hue < 5/6 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end
	
	r, g, b = (r + m) * 255, (g + m) * 255, (b + m) * 255
	local hexColor = string.format("%02X%02X%02X", math.floor(r), math.floor(g), math.floor(b))
	
	rainbowCache[key] = hexColor
	return hexColor
end

local function colorizeText(text, startIndex, totalChars)
	local richText = ""
	
	for i = 1, #text do
		local char = text:sub(i, i)
		local hexColor = getRainbowColor(startIndex + i - 1, totalChars)
		richText = richText .. string.format('<font color="#%s">%s</font>', hexColor, char)
	end
	
	return richText
end

local lastDebugUpdate = 0
local debugUpdateInterval = 0.1

local function updateDebugOverlay()
	if not config.debugOverlay or not debugOverlayFrame.Visible then return end
	
	local now = tick()
	
	if now - lastDebugUpdate < debugUpdateInterval then return end
	lastDebugUpdate = now
	
	fpsCounter = fpsCounter + 1
	if now - lastFpsUpdate >= 1 then
		fpsValue = fpsCounter
		fpsCounter = 0
		lastFpsUpdate = now
	end
	
	if now - lastPingCheck >= 2 then
		local success, stats = pcall(function()
			return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]
		end)
		if success and stats then
			pingValue = math.floor(stats:GetValue())
		end
		lastPingCheck = now
	end
	
	if isTypingInProgress or statsTracking.wordsTyped > 0 then
		local sessionTime = now - statsTracking.sessionStartTime
		local minutes = sessionTime / 60
		if minutes > 0 and statsTracking.wordsTyped > 0 then
			statsTracking.wpmValue = math.floor(statsTracking.wordsTyped / minutes)
		end
	end
	
	if isTypingInProgress then
		local remainingChars = 0
		if #currentMatches > 0 and lastPrefix ~= "" then
			local currentWord = currentMatches[matchIndex]
			remainingChars = #currentWord - #lastPrefix - typedCount
		end
		
		local avgDelay = 0
		
		if config.instantType then
			avgDelay = 0.01
		elseif config.autoTypeV3 and config.v3HumanLike then
			avgDelay = (config.v3MinDelay + config.v3MaxDelay) / 2
			
			if config.v3PauseChance > 0 then
				local avgPauseDuration = (config.v3PauseMin + config.v3PauseMax) / 2
				avgDelay = avgDelay + (config.v3PauseChance * avgPauseDuration)
			end
			
			if config.v3ThinkPauseChance > 0 then
				local avgThinkingPause = (config.v3ThinkPauseMin + config.v3ThinkPauseMax) / 2
				avgDelay = avgDelay + (config.v3ThinkPauseChance * avgThinkingPause)
			end
			
			if config.v3Fatigue then
				local fatigueMultiplier = 1 + (v3TypingState.consecutiveChars * config.v3FatigueRate)
				avgDelay = avgDelay * fatigueMultiplier
			end
			
			if config.v3SpeedLimit and config.v3MaxLPS > 0 then
				local minDelay = 1 / config.v3MaxLPS
				avgDelay = math.max(avgDelay, minDelay)
			end
			
			avgDelay = avgDelay + config.v3WordStartPause
		elseif config.humanTyping then
			avgDelay = config.humanBaseSpeed
			
			if config.humanPauseChance > 0 then
				local avgPauseDuration = (config.humanPauseMin + config.humanPauseMax) / 2
				avgDelay = avgDelay + (config.humanPauseChance * avgPauseDuration)
			end
			
			if config.humanThinkingPauseChance > 0 then
				local avgThinkingPause = (config.humanThinkingPauseMin + config.humanThinkingPauseMax) / 2
				avgDelay = avgDelay + (config.humanThinkingPauseChance * avgThinkingPause)
			end
			
			if config.humanFatigue then
				local fatigueMultiplier = 1 + (humanTypingState.consecutiveChars * config.humanFatigueRate)
				avgDelay = avgDelay * fatigueMultiplier
			end
			
			if config.speedLimitEnabled and config.speedLimitLPS > 0 then
				local minDelay = 1 / config.speedLimitLPS
				avgDelay = math.max(avgDelay, minDelay)
			end
			
			if config.speedLimitCPS and config.speedLimitCPSValue > 0 then
				local minDelay = 1 / config.speedLimitCPSValue
				avgDelay = math.max(avgDelay, minDelay)
			end
			
			avgDelay = avgDelay + config.humanWordStartPause
		elseif config.autoTypeV2 or config.autoTypeV3 then
			local minDelay = config.autoTypeV3 and config.v3MinDelay or config.autoTypeV2Min
			local maxDelay = config.autoTypeV3 and config.v3MaxDelay or config.autoTypeV2Max
			avgDelay = (minDelay + maxDelay) / 2
			
			if config.autoTypeV3 and config.v3SpeedLimit and config.v3MaxLPS > 0 then
				local minDelayLimit = 1 / config.v3MaxLPS
				avgDelay = math.max(avgDelay, minDelayLimit)
			elseif config.speedLimitEnabled and config.speedLimitLPS > 0 then
				local minDelayLimit = 1 / config.speedLimitLPS
				avgDelay = math.max(avgDelay, minDelayLimit)
			end
		else
			avgDelay = config.typingDelay
			if config.randomizeTyping then
				avgDelay = avgDelay * 1.0
			end
		end
		
		statsTracking.etcValue = remainingChars * avgDelay
		
		if config.autoDone then
			if config.autoTypeV3 and config.v3CustomDoneDelay then
				statsTracking.etcValue = statsTracking.etcValue + ((config.v3DoneDelayMin + config.v3DoneDelayMax) / 2)
			else
				statsTracking.etcValue = statsTracking.etcValue + ((config.autoDoneMin + config.autoDoneMax) / 2)
			end
		end
	else
		if statsTracking.etcValue > 0 then
			statsTracking.etcValue = math.max(0, statsTracking.etcValue - (now - (statsTracking.lastEtcUpdate or now)))
		end
	end
	statsTracking.lastEtcUpdate = now
	
	local canType, reason = canAutoType()
	local safetyStatus = canType and "OK" or reason
	
	local timerStatus = "N/A"
	if timerState.isActive then
		local elapsed = tick() - timerState.startTime
		if timerState.canTypeNow then
			timerStatus = "READY"
		elseif timerState.hasWaited then
			timerStatus = "COOLDOWN"
		else
			timerStatus = string.format("WAIT %.1fs", math.max(0, 1.5 - elapsed))
		end
	else
		timerStatus = "INACTIVE"
	end
	
	local labelData = {
		{debugFpsLabel, "FPS: " .. tostring(fpsValue)},
		{debugPingLabel, "Ping: " .. tostring(pingValue) .. "ms"},
		{debugWpmLabel, "WPM: " .. tostring(statsTracking.wpmValue)},
		{debugEtcLabel, string.format("ETC: %.1fs", statsTracking.etcValue)},
		{debugDictLabel, "Dict: " .. tostring(#dictionary)},
		{debugMatchLabel, "Matches: " .. tostring(#currentMatches)},
		{debugSafetyLabel, "Safety: " .. safetyStatus},
		{debugTimerLabel, "Timer: " .. timerStatus}
	}
	
	local totalChars = 0
	for _, data in ipairs(labelData) do
		totalChars = totalChars + #data[2]
	end
	
	local charIndex = 0
	for _, data in ipairs(labelData) do
		local label = data[1]
		local text = data[2]
		label.Text = colorizeText(text, charIndex, totalChars)
		charIndex = charIndex + #text
	end
end

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
	v3Title.TextColor3 = theme.highlight
	configTitle.TextColor3 = theme.highlight
	infoTitle.TextColor3 = theme.highlight
	
	themeDropdownButton.Text = themeName
	themeDropdownButton.TextColor3 = theme.text
	themeDropdownFrame.BackgroundColor3 = theme.secondary
	themeDropdownList.BackgroundColor3 = theme.secondary
	transparencySliderHandle.BackgroundColor3 = theme.highlight
	uiElementTransparencySliderHandle.BackgroundColor3 = theme.highlight
	debugTextSizeSliderHandle.BackgroundColor3 = theme.highlight
end

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

draggingTransparency = false
draggingUIElementTransparency = false
draggingDebugTextSize = false

transparencySliderHandle.MouseButton1Down:Connect(function()
	if configPage.Visible then
		draggingTransparency = true
	end
end)

uiElementTransparencySliderHandle.MouseButton1Down:Connect(function()
	if configPage.Visible then
		draggingUIElementTransparency = true
	end
end)

debugTextSizeSliderHandle.MouseButton1Down:Connect(function()
	if configPage.Visible then
		draggingDebugTextSize = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingTransparency = false
		draggingUIElementTransparency = false
		draggingDebugTextSize = false
	end
end)

for pageName, btn in pairs(navButtons) do
	btn.MouseButton1Click:Connect(function()
		draggingTransparency = false
		draggingUIElementTransparency = false
		draggingDebugTextSize = false
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
	
	if draggingUIElementTransparency and configPage.Visible then
		local mousePos = UserInputService:GetMouseLocation()
		local barPos = uiElementTransparencySliderBar.AbsolutePosition
		local barSize = uiElementTransparencySliderBar.AbsoluteSize
		
		local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
		
		config.uiElementTransparency = relativeX
		
		for _, desc in ipairs(gui:GetDescendants()) do
			applyUIElementEffects(desc)
		end
		
		uiElementTransparencySliderHandle.Position = UDim2.new(relativeX, -9, 0.5, -9)
		uiElementTransparencyValueLabel.Text = string.format("%.2f", relativeX)
	end
	
	if draggingDebugTextSize and configPage.Visible then
		local mousePos = UserInputService:GetMouseLocation()
		local barPos = debugTextSizeSliderBar.AbsolutePosition
		local barSize = debugTextSizeSliderBar.AbsoluteSize
		
		local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
		
		local newSize = 10 + (relativeX * 20)
		newSize = math.floor(newSize)
		
		config.debugTextSize = newSize
		
		for _, child in ipairs(debugOverlayFrame:GetChildren()) do
			if child:IsA("TextLabel") then
				child.TextSize = newSize
			end
		end
		
		debugTextSizeSliderHandle.Position = UDim2.new(relativeX, -9, 0.5, -9)
		debugTextSizeValueLabel.Text = tostring(newSize)
	end
end)

uiElementAcrylicToggle.MouseButton1Click:Connect(function()
	config.uiElementAcrylic = not config.uiElementAcrylic
	uiElementAcrylicToggle.Text = config.uiElementAcrylic and "On" or "Off"
	
	for _, desc in ipairs(gui:GetDescendants()) do
		applyUIElementEffects(desc)
	end
end)

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

autoLoadToggle.MouseButton1Click:Connect(function()
	config.autoLoadConfig = not config.autoLoadConfig
	autoLoadToggle.Text = config.autoLoadConfig and "On" or "Off"
end)

debugOverlayToggle.MouseButton1Click:Connect(function()
	config.debugOverlay = not config.debugOverlay
	debugOverlayToggle.Text = config.debugOverlay and "On" or "Off"
	debugOverlayFrame.Visible = config.debugOverlay
end)

requireUIToggle.MouseButton1Click:Connect(function()
	config.requireVisibleUI = not config.requireVisibleUI
	requireUIToggle.Text = config.requireVisibleUI and "On" or "Off"
end)

requireNameToggle.MouseButton1Click:Connect(function()
	config.requirePlayerNameInPrompt = not config.requirePlayerNameInPrompt
	requireNameToggle.Text = config.requirePlayerNameInPrompt and "On" or "Off"
end)

safetyDelayInput.FocusLost:Connect(function()
	local v = tonumber(safetyDelayInput.Text)
	if v and v >= 0 then config.safetyDelay = v end
	safetyDelayInput.Text = tostring(config.safetyDelay)
end)

humanToggle.MouseButton1Click:Connect(function()
	config.humanTyping = not config.humanTyping
	humanToggle.Text = config.humanTyping and "On" or "Off"
	humanSettingsContainer.Visible = config.humanTyping
	
	if config.humanTyping and config.autoTypeV2 then
		warn("Human Typing requires Auto V2 to be enabled")
	end
end)

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

thinkingPauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(thinkingPauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.humanThinkingPauseChance = v / 100
	end
	thinkingPauseChanceInput.Text = tostring(config.humanThinkingPauseChance * 100)
end)

thinkingPauseMinInput.FocusLost:Connect(function()
	local v = tonumber(thinkingPauseMinInput.Text)
	if v and v >= 0 then config.humanThinkingPauseMin = v end
	thinkingPauseMinInput.Text = tostring(config.humanThinkingPauseMin)
end)

thinkingPauseMaxInput.FocusLost:Connect(function()
	local v = tonumber(thinkingPauseMaxInput.Text)
	if v and v >= 0 then config.humanThinkingPauseMax = v end
	thinkingPauseMaxInput.Text = tostring(config.humanThinkingPauseMax)
end)

wordStartPauseInput.FocusLost:Connect(function()
	local v = tonumber(wordStartPauseInput.Text)
	if v and v >= 0 then config.humanWordStartPause = v end
	wordStartPauseInput.Text = tostring(config.humanWordStartPause)
end)

wordEndPauseInput.FocusLost:Connect(function()
	local v = tonumber(wordEndPauseInput.Text)
	if v and v >= 0 then config.humanWordEndPause = v end
	wordEndPauseInput.Text = tostring(config.humanWordEndPause)
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

rhythmVariationToggle.MouseButton1Click:Connect(function()
	config.humanRhythmVariation = not config.humanRhythmVariation
	rhythmVariationToggle.Text = config.humanRhythmVariation and "On" or "Off"
end)

accelerationInput.FocusLost:Connect(function()
	local v = tonumber(accelerationInput.Text)
	if v and v >= 0 and v <= 1 then config.humanAcceleration = v end
	accelerationInput.Text = tostring(config.humanAcceleration)
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

speedLimitToggle.MouseButton1Click:Connect(function()
	config.speedLimitEnabled = not config.speedLimitEnabled
	speedLimitToggle.Text = config.speedLimitEnabled and "On" or "Off"
	speedLimitLPSRow.Visible = config.speedLimitEnabled
end)

speedLimitLPSInput.FocusLost:Connect(function()
	local v = tonumber(speedLimitLPSInput.Text)
	if v and v > 0 then config.speedLimitLPS = v end
	speedLimitLPSInput.Text = tostring(config.speedLimitLPS)
end)

speedLimitWPMToggle.MouseButton1Click:Connect(function()
	config.speedLimitWPM = not config.speedLimitWPM
	speedLimitWPMToggle.Text = config.speedLimitWPM and "On" or "Off"
	speedLimitWPMValueRow.Visible = config.speedLimitWPM
end)

speedLimitWPMValueInput.FocusLost:Connect(function()
	local v = tonumber(speedLimitWPMValueInput.Text)
	if v and v > 0 then config.speedLimitWPMValue = v end
	speedLimitWPMValueInput.Text = tostring(config.speedLimitWPMValue)
end)

speedLimitCPSToggle.MouseButton1Click:Connect(function()
	config.speedLimitCPS = not config.speedLimitCPS
	speedLimitCPSToggle.Text = config.speedLimitCPS and "On" or "Off"
	speedLimitCPSValueRow.Visible = config.speedLimitCPS
end)

speedLimitCPSValueInput.FocusLost:Connect(function()
	local v = tonumber(speedLimitCPSValueInput.Text)
	if v and v > 0 then config.speedLimitCPSValue = v end
	speedLimitCPSValueInput.Text = tostring(config.speedLimitCPSValue)
end)

v3Toggle.MouseButton1Click:Connect(function()
	config.autoTypeV3 = not config.autoTypeV3
	v3Toggle.Text = config.autoTypeV3 and "On" or "Off"
	v3SettingsContainer.Visible = config.autoTypeV3
	
	if config.autoTypeV3 then
		config.humanTyping = false
		config.autoType = false
		config.autoTypeV2 = false
		humanToggle.Text = "Off"
		autoTypeButton.Text = "Auto V1: Off"
		autoTypeV2Toggle.Text = "Off"
		humanSettingsContainer.Visible = false
		v2MinMaxRow.Visible = false
	end
	
	if not config.autoTypeV3 then
		clearTypedContinuation()
	end
end)

v3MinDelayInput.FocusLost:Connect(function()
	local v = tonumber(v3MinDelayInput.Text)
	if v and v >= 0 then config.v3MinDelay = v end
	v3MinDelayInput.Text = tostring(config.v3MinDelay)
end)

v3MaxDelayInput.FocusLost:Connect(function()
	local v = tonumber(v3MaxDelayInput.Text)
	if v and v >= 0 then config.v3MaxDelay = v end
	v3MaxDelayInput.Text = tostring(config.v3MaxDelay)
end)

v3RandomizationToggle.MouseButton1Click:Connect(function()
	config.v3SpeedRandomization = not config.v3SpeedRandomization
	v3RandomizationToggle.Text = config.v3SpeedRandomization and "On" or "Off"
	v3RandomAmountRow.Visible = config.v3SpeedRandomization
end)

v3RandomAmountInput.FocusLost:Connect(function()
	local v = tonumber(v3RandomAmountInput.Text)
	if v and v >= 0 and v <= 1 then config.v3RandomizationAmount = v end
	v3RandomAmountInput.Text = tostring(config.v3RandomizationAmount)
end)

v3HumanLikeToggle.MouseButton1Click:Connect(function()
	config.v3HumanLike = not config.v3HumanLike
	v3HumanLikeToggle.Text = config.v3HumanLike and "On" or "Off"
	v3HumanContainer.Visible = config.v3HumanLike
end)

v3PauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(v3PauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.v3PauseChance = v / 100
	end
	v3PauseChanceInput.Text = tostring(config.v3PauseChance * 100)
end)

v3PauseMinInput.FocusLost:Connect(function()
	local v = tonumber(v3PauseMinInput.Text)
	if v and v >= 0 then config.v3PauseMin = v end
	v3PauseMinInput.Text = tostring(config.v3PauseMin)
end)

v3PauseMaxInput.FocusLost:Connect(function()
	local v = tonumber(v3PauseMaxInput.Text)
	if v and v >= 0 then config.v3PauseMax = v end
	v3PauseMaxInput.Text = tostring(config.v3PauseMax)
end)

v3ThinkPauseChanceInput.FocusLost:Connect(function()
	local v = tonumber(v3ThinkPauseChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.v3ThinkPauseChance = v / 100
	end
	v3ThinkPauseChanceInput.Text = tostring(config.v3ThinkPauseChance * 100)
end)

v3ThinkPauseMinInput.FocusLost:Connect(function()
	local v = tonumber(v3ThinkPauseMinInput.Text)
	if v and v >= 0 then config.v3ThinkPauseMin = v end
	v3ThinkPauseMinInput.Text = tostring(config.v3ThinkPauseMin)
end)

v3ThinkPauseMaxInput.FocusLost:Connect(function()
	local v = tonumber(v3ThinkPauseMaxInput.Text)
	if v and v >= 0 then config.v3ThinkPauseMax = v end
	v3ThinkPauseMaxInput.Text = tostring(config.v3ThinkPauseMax)
end)

v3WordStartPauseInput.FocusLost:Connect(function()
	local v = tonumber(v3WordStartPauseInput.Text)
	if v and v >= 0 then config.v3WordStartPause = v end
	v3WordStartPauseInput.Text = tostring(config.v3WordStartPause)
end)

v3WordEndPauseInput.FocusLost:Connect(function()
	local v = tonumber(v3WordEndPauseInput.Text)
	if v and v >= 0 then config.v3WordEndPause = v end
	v3WordEndPauseInput.Text = tostring(config.v3WordEndPause)
end)

v3BurstChanceInput.FocusLost:Connect(function()
	local v = tonumber(v3BurstChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.v3BurstChance = v / 100
	end
	v3BurstChanceInput.Text = tostring(config.v3BurstChance * 100)
end)

v3BurstMultiplierInput.FocusLost:Connect(function()
	local v = tonumber(v3BurstMultiplierInput.Text)
	if v and v > 0 and v <= 1 then config.v3BurstMultiplier = v end
	v3BurstMultiplierInput.Text = tostring(config.v3BurstMultiplier)
end)

v3RhythmToggle.MouseButton1Click:Connect(function()
	config.v3RhythmVariation = not config.v3RhythmVariation
	v3RhythmToggle.Text = config.v3RhythmVariation and "On" or "Off"
end)

v3AccelerationInput.FocusLost:Connect(function()
	local v = tonumber(v3AccelerationInput.Text)
	if v and v >= 0 and v <= 1 then config.v3Acceleration = v end
	v3AccelerationInput.Text = tostring(config.v3Acceleration)
end)

v3FatigueToggle.MouseButton1Click:Connect(function()
	config.v3Fatigue = not config.v3Fatigue
	v3FatigueToggle.Text = config.v3Fatigue and "On" or "Off"
	v3FatigueRateRow.Visible = config.v3Fatigue
end)

v3FatigueRateInput.FocusLost:Connect(function()
	local v = tonumber(v3FatigueRateInput.Text)
	if v and v >= 0 and v <= 1 then config.v3FatigueRate = v end
	v3FatigueRateInput.Text = tostring(config.v3FatigueRate)
end)

v3ErrorToggle.MouseButton1Click:Connect(function()
	config.v3ErrorSimulation = not config.v3ErrorSimulation
	v3ErrorToggle.Text = config.v3ErrorSimulation and "On" or "Off"
	v3ErrorContainer.Visible = config.v3ErrorSimulation
end)

v3TypoChanceInput.FocusLost:Connect(function()
	local v = tonumber(v3TypoChanceInput.Text)
	if v and v >= 0 and v <= 100 then
		config.v3TypoChance = v / 100
	end
	v3TypoChanceInput.Text = tostring(config.v3TypoChance * 100)
end)

v3TypoCorrectInput.FocusLost:Connect(function()
	local v = tonumber(v3TypoCorrectInput.Text)
	if v and v >= 0 then config.v3TypoCorrectDelay = v end
	v3TypoCorrectInput.Text = tostring(config.v3TypoCorrectDelay)
end)

v3StartDelayToggle.MouseButton1Click:Connect(function()
	config.v3CustomStartDelay = not config.v3CustomStartDelay
	v3StartDelayToggle.Text = config.v3CustomStartDelay and "On" or "Off"
	v3StartDelayValuesRow.Visible = config.v3CustomStartDelay
end)

v3StartDelayMinInput.FocusLost:Connect(function()
	local v = tonumber(v3StartDelayMinInput.Text)
	if v and v >= 0 then config.v3StartDelayMin = v end
	v3StartDelayMinInput.Text = tostring(config.v3StartDelayMin)
end)

v3StartDelayMaxInput.FocusLost:Connect(function()
	local v = tonumber(v3StartDelayMaxInput.Text)
	if v and v >= 0 then config.v3StartDelayMax = v end
	v3StartDelayMaxInput.Text = tostring(config.v3StartDelayMax)
end)

v3DoneDelayToggle.MouseButton1Click:Connect(function()
	config.v3CustomDoneDelay = not config.v3CustomDoneDelay
	v3DoneDelayToggle.Text = config.v3CustomDoneDelay and "On" or "Off"
	v3DoneDelayValuesRow.Visible = config.v3CustomDoneDelay
end)

v3DoneDelayMinInput.FocusLost:Connect(function()
	local v = tonumber(v3DoneDelayMinInput.Text)
	if v and v >= 0 then config.v3DoneDelayMin = v end
	v3DoneDelayMinInput.Text = tostring(config.v3DoneDelayMin)
end)

v3DoneDelayMaxInput.FocusLost:Connect(function()
	local v = tonumber(v3DoneDelayMaxInput.Text)
	if v and v >= 0 then config.v3DoneDelayMax = v end
	v3DoneDelayMaxInput.Text = tostring(config.v3DoneDelayMax)
end)

v3SpeedLimitToggle.MouseButton1Click:Connect(function()
	config.v3SpeedLimit = not config.v3SpeedLimit
	v3SpeedLimitToggle.Text = config.v3SpeedLimit and "On" or "Off"
	v3MaxLPSRow.Visible = config.v3SpeedLimit
end)

v3MaxLPSInput.FocusLost:Connect(function()
	local v = tonumber(v3MaxLPSInput.Text)
	if v and v > 0 then config.v3MaxLPS = v end
	v3MaxLPSInput.Text = tostring(config.v3MaxLPS)
end)

v3MinLPSToggle.MouseButton1Click:Connect(function()
	config.v3MinLPSEnabled = not config.v3MinLPSEnabled
	v3MinLPSToggle.Text = config.v3MinLPSEnabled and "On" or "Off"
	v3MinLPSRow.Visible = config.v3MinLPSEnabled
end)

v3MinLPSInput.FocusLost:Connect(function()
	local v = tonumber(v3MinLPSInput.Text)
	if v and v > 0 then config.v3MinLPS = v end
	v3MinLPSInput.Text = tostring(config.v3MinLPS)
end)

v3MaxWPMToggle.MouseButton1Click:Connect(function()
	config.v3MaxWPM = not config.v3MaxWPM
	v3MaxWPMToggle.Text = config.v3MaxWPM and "On" or "Off"
	v3MaxWPMValueRow.Visible = config.v3MaxWPM
end)

v3MaxWPMValueInput.FocusLost:Connect(function()
	local v = tonumber(v3MaxWPMValueInput.Text)
	if v and v > 0 then config.v3MaxWPMValue = v end
	v3MaxWPMValueInput.Text = tostring(config.v3MaxWPMValue)
end)

v3MaxCPSToggle.MouseButton1Click:Connect(function()
	config.v3MaxCPS = not config.v3MaxCPS
	v3MaxCPSToggle.Text = config.v3MaxCPS and "On" or "Off"
	v3MaxCPSValueRow.Visible = config.v3MaxCPS
end)

v3MaxCPSValueInput.FocusLost:Connect(function()
	local v = tonumber(v3MaxCPSValueInput.Text)
	if v and v > 0 then config.v3MaxCPSValue = v end
	v3MaxCPSValueInput.Text = tostring(config.v3MaxCPSValue)
end)

v3ButtonHoldToggle.MouseButton1Click:Connect(function()
	config.v3ButtonHold = not config.v3ButtonHold
	v3ButtonHoldToggle.Text = config.v3ButtonHold and "On" or "Off"
	v3ButtonHoldDurationRow.Visible = config.v3ButtonHold
end)

v3ButtonHoldMinInput.FocusLost:Connect(function()
	local v = tonumber(v3ButtonHoldMinInput.Text)
	if v and v >= 0 then config.v3ButtonHoldMin = v end
	v3ButtonHoldMinInput.Text = tostring(config.v3ButtonHoldMin)
end)

v3ButtonHoldMaxInput.FocusLost:Connect(function()
	local v = tonumber(v3ButtonHoldMaxInput.Text)
	if v and v >= 0 then config.v3ButtonHoldMax = v end
	v3ButtonHoldMaxInput.Text = tostring(config.v3ButtonHoldMax)
end)

loadDictionaries()

pages = {
	Main = mainPage,
	Settings = settingsPage,
	Human = humanPage,
	V3 = v3Page,
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

currentMatches = {}
matchIndex = 1
longest = false
lastPrefix = ""
autoTypePending = false
charTypedCount = 0
keyboardCache = nil
lastKeyboardCheck = 0

local function safeGetKeyboard()
	local now = tick()
	if keyboardCache and (now - lastKeyboardCheck) < 0.3 then
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

letterButtonCache = {}
lastCacheUpdate = 0

local function pressLetter(c, useButtonHold)
	if not c or type(c) ~= "string" or #c == 0 then return end
	
	local kb = safeGetKeyboard()
	if not kb then return end
	
	c = c:upper()
	
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
		if useButtonHold and config.autoTypeV3 and config.v3ButtonHold then
			pcall(function() firesignal(btn.MouseButton1Down) end)
			
			local holdMin = config.v3ButtonHoldMin
			local holdMax = config.v3ButtonHoldMax
			local holdDuration
			
			if holdMax <= holdMin then
				holdDuration = holdMin
			else
				holdDuration = holdMin + math.random() * (holdMax - holdMin)
			end
			
			if holdDuration > 0 then
				task.wait(holdDuration)
			end
			
			pcall(function() firesignal(btn.MouseButton1Up) end)
			pcall(function() firesignal(btn.MouseButton1Click) end)
		else
			pcall(function() firesignal(btn.MouseButton1Click) end)
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
		local maxWait = 10
		local waited = 0
		while isTypingInProgress and waited < maxWait do
			task.wait(0.05)
			waited = waited + 0.05
		end
		
		task.wait(0.1)
		
		local minv, maxv
		if config.autoTypeV3 and config.v3CustomDoneDelay then
			minv = config.v3DoneDelayMin
			maxv = config.v3DoneDelayMax
		else
			minv = config.autoDoneMin
			maxv = config.autoDoneMax
		end
		
		local doneDelay
		if maxv <= minv then
			doneDelay = minv
		else
			doneDelay = minv + math.random() * (maxv - minv)
		end
		
		if doneDelay > 0 then
			task.wait(doneDelay)
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
	
	local delay = minv + math.random() * (maxv - minv)
	
	if config.speedLimitEnabled and config.speedLimitLPS > 0 then
		local minDelay = 1 / config.speedLimitLPS
		delay = math.max(delay, minDelay)
	end
	
	if config.speedLimitCPS and config.speedLimitCPSValue > 0 then
		local minDelay = 1 / config.speedLimitCPSValue
		delay = math.max(delay, minDelay)
	end
	
	return delay
end

local function getV3TypeDelay(char, position, wordLength)
	local baseSpeed = (config.v3MinDelay + config.v3MaxDelay) / 2
	local delay = baseSpeed
	
	if config.v3SpeedRandomization then
		local randomFactor = 1 + (math.random() * 2 - 1) * config.v3RandomizationAmount
		delay = delay * randomFactor
	end
	
	if config.v3HumanLike then
		if config.v3RhythmVariation then
			v3TypingState.rhythmOffset = v3TypingState.rhythmOffset + 0.3
			local rhythmFactor = 1 + (math.sin(v3TypingState.rhythmOffset) * 0.15)
			delay = delay * rhythmFactor
		end
		
		if config.v3Acceleration > 0 then
			local accelerationFactor = math.max(0.7, 1 - (position / wordLength) * config.v3Acceleration)
			delay = delay * accelerationFactor
		end
		
		if math.random() < config.v3PauseChance then
			local pauseDuration = config.v3PauseMin + 
				math.random() * (config.v3PauseMax - config.v3PauseMin)
			delay = delay + pauseDuration
		end
		
		if math.random() < config.v3ThinkPauseChance then
			local thinkingPause = config.v3ThinkPauseMin + 
				math.random() * (config.v3ThinkPauseMax - config.v3ThinkPauseMin)
			delay = delay + thinkingPause
		end
		
		if math.random() < config.v3BurstChance then
			delay = delay * config.v3BurstMultiplier
			v3TypingState.currentSpeed = config.v3BurstMultiplier
		else
			v3TypingState.currentSpeed = 1.0
		end
		
		if config.v3Fatigue then
			local fatigueMultiplier = 1 + (v3TypingState.consecutiveChars * config.v3FatigueRate)
			delay = delay * fatigueMultiplier
		end
		
		if position == 1 then
			delay = delay + config.v3WordStartPause
		elseif position == wordLength then
			delay = delay + config.v3WordEndPause
		end
	end
	
	if config.v3MinLPSEnabled and config.v3MinLPS > 0 then
		local maxDelay = 1 / config.v3MinLPS
		delay = math.min(delay, maxDelay)
	end
	
	if config.v3SpeedLimit and config.v3MaxLPS > 0 then
		local minDelay = 1 / config.v3MaxLPS
		delay = math.max(delay, minDelay)
	end
	
	if config.v3MaxCPS and config.v3MaxCPSValue > 0 then
		local minDelay = 1 / config.v3MaxCPSValue
		delay = math.max(delay, minDelay)
	end
	
	if config.v3MaxWPM and config.v3MaxWPMValue > 0 then
		local avgWordLength = 5
		local maxCharsPerMinute = config.v3MaxWPMValue * avgWordLength
		local maxCharsPerSecond = maxCharsPerMinute / 60
		local minDelay = 1 / maxCharsPerSecond
		delay = math.max(delay, minDelay)
	end
	
	return math.max(delay, 0.01)
end

local function getHumanTypeDelay(char, position, wordLength)
	local baseSpeed = config.humanBaseSpeed
	local variation = config.humanVariation
	
	local delay = baseSpeed + (math.random() * 2 - 1) * variation
	
	if config.humanRhythmVariation then
		humanTypingState.rhythmOffset = humanTypingState.rhythmOffset + 0.3
		local rhythmFactor = 1 + (math.sin(humanTypingState.rhythmOffset) * 0.15)
		delay = delay * rhythmFactor
	end
	
	if config.humanAcceleration > 0 then
		local accelerationFactor = math.max(0.7, 1 - (position / wordLength) * config.humanAcceleration)
		delay = delay * accelerationFactor
	end
	
	if math.random() < config.humanPauseChance then
		local pauseDuration = config.humanPauseMin + 
			math.random() * (config.humanPauseMax - config.humanPauseMin)
		delay = delay + pauseDuration
	end
	
	if math.random() < config.humanThinkingPauseChance then
		local thinkingPause = config.humanThinkingPauseMin + 
			math.random() * (config.humanThinkingPauseMax - config.humanThinkingPauseMin)
		delay = delay + thinkingPause
	end
	
	if math.random() < config.humanBurstChance then
		delay = delay * config.humanBurstSpeed
		humanTypingState.currentSpeed = config.humanBurstSpeed
	else
		humanTypingState.currentSpeed = 1.0
	end
	
	if config.humanFatigue then
		local fatigueMultiplier = 1 + (humanTypingState.consecutiveChars * config.humanFatigueRate)
		delay = delay * fatigueMultiplier
	end
	
	if position == 1 then
		delay = delay + config.humanWordStartPause
	elseif position == wordLength then
		delay = delay + config.humanWordEndPause
	end
	
	if config.speedLimitEnabled and config.speedLimitLPS > 0 then
		local minDelay = 1 / config.speedLimitLPS
		delay = math.max(delay, minDelay)
	end
	
	if config.speedLimitCPS and config.speedLimitCPSValue > 0 then
		local minDelay = 1 / config.speedLimitCPSValue
		delay = math.max(delay, minDelay)
	end
	
	if config.speedLimitWPM and config.speedLimitWPMValue > 0 then
		local avgWordLength = 5
		local maxCharsPerMinute = config.speedLimitWPMValue * avgWordLength
		local maxCharsPerSecond = maxCharsPerMinute / 60
		local minDelay = 1 / maxCharsPerSecond
		delay = math.max(delay, minDelay)
	end
	
	return math.max(delay, 0.01)
end

local function typeContinuation(full, prefix, useV3Speed)
	if isTypingInProgress then return end
	
	if config.safetyDelay > 0 then
		task.wait(config.safetyDelay)
	end
	
	local canType, reason = canAutoType()
	if not canType then
		warn("Typing blocked: " .. reason)
		return
	end
	
	isTypingInProgress = true
	
	statsTracking.typingStartTime = tick()
	statsTracking.totalCharsTyped = 0
	humanTypingState.consecutiveChars = 0
	humanTypingState.rhythmOffset = 0
	v3TypingState.consecutiveChars = 0
	v3TypingState.rhythmOffset = 0

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
			pressLetter(cont:sub(i,i), config.autoTypeV3)
			statsTracking.totalCharsTyped = statsTracking.totalCharsTyped + 1
		end
		typedCount = #cont
		statsTracking.wordsTyped = statsTracking.wordsTyped + 1
	else
		for i = 1, #cont do
			local currentChar = cont:sub(i,i)
			
			if config.autoTypeV3 and config.v3ErrorSimulation and math.random() < config.v3TypoChance then
				local wrongChars = {"a","s","d","f","g","h","j","k","l"}
				local wrongChar = wrongChars[math.random(1, #wrongChars)]
				pressLetter(wrongChar, config.autoTypeV3)
				task.wait(config.v3TypoCorrectDelay)
				pressDelete()
			end
			
			pressLetter(currentChar, config.autoTypeV3)
			typedCount = typedCount + 1
			charTypedCount = charTypedCount + 1
			
			if config.autoTypeV3 then
				v3TypingState.consecutiveChars = v3TypingState.consecutiveChars + 1
			else
				humanTypingState.consecutiveChars = humanTypingState.consecutiveChars + 1
			end
			
			statsTracking.totalCharsTyped = statsTracking.totalCharsTyped + 1
			
			local delay
			if config.autoTypeV3 then
				delay = getV3TypeDelay(currentChar, i, #cont)
			elseif config.humanTyping then
				delay = getHumanTypeDelay(currentChar, i, #cont)
			elseif useV3Speed then
				delay = getV2TypeDelay()
			else
				delay = config.typingDelay
				if config.randomizeTyping then
					delay = math.random() * delay * 2
				end
			end
			
			if delay > 0 and i < #cont then
				task.wait(delay)
			end
		end
		statsTracking.wordsTyped = statsTracking.wordsTyped + 1
	end

	if config.autoTypeV3 and config.v3HumanLike and config.v3WordEndPause > 0 then
		task.wait(config.v3WordEndPause)
	elseif config.humanTyping and config.humanWordEndPause > 0 then
		task.wait(config.humanWordEndPause)
	end

	isTypingInProgress = false
	
	task.wait(0.05)
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
	humanTypingState.consecutiveChars = 0
	v3TypingState.consecutiveChars = 0
	statsTracking.wordsTyped = 0
	statsTracking.sessionStartTime = tick()
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
	
	if config.autoType then
		config.autoTypeV2 = false
		config.autoTypeV3 = false
		autoTypeV2Toggle.Text = "Off"
		v3Toggle.Text = "Off"
		v2MinMaxRow.Visible = false
		v3SettingsContainer.Visible = false
	end
	
	if not config.autoType then
		clearTypedContinuation()
	end
end)

autoTypeV2Toggle.MouseButton1Click:Connect(function()
	config.autoTypeV2 = not config.autoTypeV2
	autoTypeV2Toggle.Text = config.autoTypeV2 and "On" or "Off"
	
	v2MinMaxRow.Visible = config.autoTypeV2
	
	if config.autoTypeV2 then
		config.autoType = false
		config.autoTypeV3 = false
		autoTypeButton.Text = "Auto V1: Off"
		v3Toggle.Text = "Off"
		v3SettingsContainer.Visible = false
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
		typeContinuation(word, lastPrefix, config.autoTypeV2 or config.autoTypeV3 or config.humanTyping)
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
			debugOverlayToggle.Text = config.debugOverlay and "On" or "Off"
			debugOverlayFrame.Visible = config.debugOverlay
			
			requireUIToggle.Text = config.requireVisibleUI and "On" or "Off"
			requireNameToggle.Text = config.requirePlayerNameInPrompt and "On" or "Off"
			safetyDelayInput.Text = tostring(config.safetyDelay)
			
			humanToggle.Text = config.humanTyping and "On" or "Off"
			humanSettingsContainer.Visible = config.humanTyping
			baseSpeedInput.Text = tostring(config.humanBaseSpeed)
			variationInput.Text = tostring(config.humanVariation)
			pauseChanceInput.Text = tostring(config.humanPauseChance * 100)
			pauseMinInput.Text = tostring(config.humanPauseMin)
			pauseMaxInput.Text = tostring(config.humanPauseMax)
			thinkingPauseChanceInput.Text = tostring(config.humanThinkingPauseChance * 100)
			thinkingPauseMinInput.Text = tostring(config.humanThinkingPauseMin)
			thinkingPauseMaxInput.Text = tostring(config.humanThinkingPauseMax)
			wordStartPauseInput.Text = tostring(config.humanWordStartPause)
			wordEndPauseInput.Text = tostring(config.humanWordEndPause)
			burstChanceInput.Text = tostring(config.humanBurstChance * 100)
			burstSpeedInput.Text = tostring(config.humanBurstSpeed)
			rhythmVariationToggle.Text = config.humanRhythmVariation and "On" or "Off"
			accelerationInput.Text = tostring(config.humanAcceleration)
			fatigueToggle.Text = config.humanFatigue and "On" or "Off"
			fatigueRateInput.Text = tostring(config.humanFatigueRate)
			fatigueRateRow.Visible = config.humanFatigue
			
			speedLimitToggle.Text = config.speedLimitEnabled and "On" or "Off"
			speedLimitLPSInput.Text = tostring(config.speedLimitLPS)
			speedLimitLPSRow.Visible = config.speedLimitEnabled
			speedLimitWPMToggle.Text = config.speedLimitWPM and "On" or "Off"
			speedLimitWPMValueInput.Text = tostring(config.speedLimitWPMValue)
			speedLimitWPMValueRow.Visible = config.speedLimitWPM
			speedLimitCPSToggle.Text = config.speedLimitCPS and "On" or "Off"
			speedLimitCPSValueInput.Text = tostring(config.speedLimitCPSValue)
			speedLimitCPSValueRow.Visible = config.speedLimitCPS
			
			v3Toggle.Text = config.autoTypeV3 and "On" or "Off"
			v3SettingsContainer.Visible = config.autoTypeV3
			v3MinDelayInput.Text = tostring(config.v3MinDelay)
			v3MaxDelayInput.Text = tostring(config.v3MaxDelay)
			v3RandomizationToggle.Text = config.v3SpeedRandomization and "On" or "Off"
			v3RandomAmountInput.Text = tostring(config.v3RandomizationAmount)
			v3RandomAmountRow.Visible = config.v3SpeedRandomization
			v3HumanLikeToggle.Text = config.v3HumanLike and "On" or "Off"
			v3HumanContainer.Visible = config.v3HumanLike
			v3PauseChanceInput.Text = tostring(config.v3PauseChance * 100)
			v3PauseMinInput.Text = tostring(config.v3PauseMin)
			v3PauseMaxInput.Text = tostring(config.v3PauseMax)
			v3ThinkPauseChanceInput.Text = tostring(config.v3ThinkPauseChance * 100)
			v3ThinkPauseMinInput.Text = tostring(config.v3ThinkPauseMin)
			v3ThinkPauseMaxInput.Text = tostring(config.v3ThinkPauseMax)
			v3WordStartPauseInput.Text = tostring(config.v3WordStartPause)
			v3WordEndPauseInput.Text = tostring(config.v3WordEndPause)
			v3BurstChanceInput.Text = tostring(config.v3BurstChance * 100)
			v3BurstMultiplierInput.Text = tostring(config.v3BurstMultiplier)
			v3RhythmToggle.Text = config.v3RhythmVariation and "On" or "Off"
			v3AccelerationInput.Text = tostring(config.v3Acceleration)
			v3FatigueToggle.Text = config.v3Fatigue and "On" or "Off"
			v3FatigueRateInput.Text = tostring(config.v3FatigueRate)
			v3FatigueRateRow.Visible = config.v3Fatigue
			v3ErrorToggle.Text = config.v3ErrorSimulation and "On" or "Off"
			v3ErrorContainer.Visible = config.v3ErrorSimulation
			v3TypoChanceInput.Text = tostring(config.v3TypoChance * 100)
			v3TypoCorrectInput.Text = tostring(config.v3TypoCorrectDelay)
			v3StartDelayToggle.Text = config.v3CustomStartDelay and "On" or "Off"
			v3StartDelayValuesRow.Visible = config.v3CustomStartDelay
			v3StartDelayMinInput.Text = tostring(config.v3StartDelayMin)
			v3StartDelayMaxInput.Text = tostring(config.v3StartDelayMax)
			v3DoneDelayToggle.Text = config.v3CustomDoneDelay and "On" or "Off"
			v3DoneDelayValuesRow.Visible = config.v3CustomDoneDelay
			v3DoneDelayMinInput.Text = tostring(config.v3DoneDelayMin)
			v3DoneDelayMaxInput.Text = tostring(config.v3DoneDelayMax)
			v3SpeedLimitToggle.Text = config.v3SpeedLimit and "On" or "Off"
			v3MaxLPSRow.Visible = config.v3SpeedLimit
			v3MaxLPSInput.Text = tostring(config.v3MaxLPS)
			v3MinLPSToggle.Text = config.v3MinLPSEnabled and "On" or "Off"
			v3MinLPSRow.Visible = config.v3MinLPSEnabled
			v3MinLPSInput.Text = tostring(config.v3MinLPS)
			v3MaxWPMToggle.Text = config.v3MaxWPM and "On" or "Off"
			v3MaxWPMValueRow.Visible = config.v3MaxWPM
			v3MaxWPMValueInput.Text = tostring(config.v3MaxWPMValue)
			v3MaxCPSToggle.Text = config.v3MaxCPS and "On" or "Off"
			v3MaxCPSValueRow.Visible = config.v3MaxCPS
			v3MaxCPSValueInput.Text = tostring(config.v3MaxCPSValue)
			v3ButtonHoldToggle.Text = config.v3ButtonHold and "On" or "Off"
			v3ButtonHoldDurationRow.Visible = config.v3ButtonHold
			v3ButtonHoldMinInput.Text = tostring(config.v3ButtonHoldMin)
			v3ButtonHoldMaxInput.Text = tostring(config.v3ButtonHoldMax)
			
			uiElementAcrylicToggle.Text = config.uiElementAcrylic and "On" or "Off"
			
			applyTheme(config.theme)
			frame.BackgroundTransparency = config.transparency
			transparencySliderHandle.Position = UDim2.new(1 - config.transparency, -9, 0.5, -9)
			transparencyValueLabel.Text = string.format("%.2f", config.transparency)
			
			uiElementTransparencySliderHandle.Position = UDim2.new(config.uiElementTransparency, -9, 0.5, -9)
			uiElementTransparencyValueLabel.Text = string.format("%.2f", config.uiElementTransparency)
			
			local normalizedSize = (config.debugTextSize - 10) / 20
			debugTextSizeSliderHandle.Position = UDim2.new(normalizedSize, -9, 0.5, -9)
			debugTextSizeValueLabel.Text = tostring(config.debugTextSize)
			
			for _, child in ipairs(debugOverlayFrame:GetChildren()) do
				if child:IsA("TextLabel") then
					child.TextSize = config.debugTextSize
				end
			end
			
			for _, desc in ipairs(gui:GetDescendants()) do
				applyUIElementEffects(desc)
			end
			
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
		
		local canType, reason = canAutoType()
		if not canType then
			warn("Manual typing blocked: " .. reason)
			return
		end
		
		local word = currentMatches[matchIndex]
		if config.antiDupe and usedWords[word] then return end
		task.spawn(function()
			typeContinuation(word, lastPrefix, config.autoTypeV2 or config.autoTypeV3 or config.humanTyping)
			if config.antiDupe then usedWords[word] = true end
			if config.autoDone then schedulePressDone() end
		end)
	end
end)

local function startAutoTypeIfNeeded()
	if not (config.autoType or config.autoTypeV2 or config.autoTypeV3) or autoTypePending or isTypingInProgress then return end
	
	local canType, reason = canAutoType()
	if not canType then
		return
	end

	autoTypePending = true
	task.spawn(function()
		local startDelayValue
		if config.autoTypeV3 and config.v3CustomStartDelay then
			local minDelay = config.v3StartDelayMin
			local maxDelay = config.v3StartDelayMax
			if maxDelay <= minDelay then
				startDelayValue = minDelay
			else
				startDelayValue = minDelay + math.random() * (maxDelay - minDelay)
			end
		else
			startDelayValue = config.startDelay
		end
		
		if startDelayValue > 0 then
			task.wait(startDelayValue)
		end
		
		if not (config.autoType or config.autoTypeV2 or config.autoTypeV3) then 
			autoTypePending = false 
			return 
		end
		
		if isTypingInProgress then
			autoTypePending = false
			return
		end
		
		updateSuggestionFromClosestTable(true)
		
		local word = currentMatches[matchIndex]
		if not word or lastPrefix == "" then 
			autoTypePending = false 
			return 
		end
		
		local remaining = #word - #lastPrefix
		local waitTime = (remaining <= 3) and (0.5 + math.random()) or (1 + math.random()*0.9)
		
		task.wait(waitTime)
		
		if not (config.autoType or config.autoTypeV2 or config.autoTypeV3) then 
			autoTypePending = false 
			return 
		end
		
		local canTypeNow, reasonNow = canAutoType()
		if not canTypeNow then
			autoTypePending = false
			return
		end
		
		if config.antiDupe and usedWords[word] then 
			autoTypePending = false 
			return 
		end
		
		typeContinuation(word, lastPrefix, config.autoTypeV2 or config.autoTypeV3 or config.humanTyping)
		
		local maxWait = 10
		local waited = 0
		while isTypingInProgress and waited < maxWait do
			task.wait(0.05)
			waited = waited + 0.05
		end
		
		if config.antiDupe then usedWords[word] = true end
		
		if config.autoDone then 
			schedulePressDone() 
		end
		
		autoTypePending = false
	end)
end

lastUpdate = 0
updateInterval = 0.08

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
		typedCount = 0
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local bb = tbl:FindFirstChild("Billboard") or tbl:FindFirstChildWhichIsA("Model") or tbl:FindFirstChildWhichIsA("Folder")
	if not bb then
		wordLabel.Text = "Waiting..."
		currentMatches = {}
		matchIndex = 1
		lastPrefix = ""
		typedCount = 0
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
		typedCount = 0
		if not isTypingInProgress then clearTypedContinuation() end
		return
	end

	local isNewWord = (prefix ~= lastPrefix)
	
	if not forced and prefix == lastPrefix and #currentMatches > 0 then return end
	
	if isNewWord and not isTypingInProgress then
		clearTypedContinuation()
		typedCount = 0
		autoTypePending = false
	end
	
	autoTypePrefixTime = tick()
	lastPrefix = prefix

	local sug, m = getSuggestion(prefix, longest, config.antiDupe and true or false, usedWords, config.minWordLength, config.endingIn)
	
	if #m == 0 then
		keyboardCache = nil
		lastKeyboardCheck = 0
		
		task.wait(0.05)
		prefix = extractPrefixFromGui(guiObj)
		if prefix ~= "" then
			lastPrefix = prefix
			sug, m = getSuggestion(prefix, longest, config.antiDupe and true or false, usedWords, config.minWordLength, config.endingIn)
		end
	end
	
	currentMatches = m
	matchIndex = 1
	wordLabel.Text = sug
	
	if not isTypingInProgress then 
		clearTypedContinuation()
		typedCount = 0
	end

	if (config.autoType or config.autoTypeV2 or config.autoTypeV3) and not forced and isNewWord then
		startAutoTypeIfNeeded()
	end
end

forceFindButton.MouseButton1Click:Connect(function()
	updateSuggestionFromClosestTable(true)
end)

RunService.RenderStepped:Connect(function()
	local now = tick()
	
	updateTimerState()
	
	if now - lastUpdate >= updateInterval then
		lastUpdate = now
		updateSuggestionFromClosestTable()
	end
	if (config.autoType or config.autoTypeV2 or config.autoTypeV3) and not autoTypePending then
		startAutoTypeIfNeeded()
	end
	
	updateDebugOverlay()
end)
