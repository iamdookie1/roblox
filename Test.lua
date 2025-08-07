

-- Mobile and PC Draggable Function
local function makeDraggable(frame, handle)
	local dragging = false
	local dragInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

local PromptInterface = loadstring(game:HttpGet("https://raw.githubusercontent.com/trinyxScripts/Prompt-UI/refs/heads/main/load.lua"))()


local function GetMobile()
    if game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").MouseEnabled then
        return "Mobile"
    else
        return "Computer" 
    end
 end

if GetMobile() == "Mobile" then
 	PromptInterface.create(
        "Incompatable", -- Title
        " Mobile is yet not supported by Revin", -- Description
        "Ok", -- Primary Button Text
        "", -- Secondary Button Text
        function(response)
		if responce then
			else
				return
			end
        end
    )
	
end

local tweenService = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local player = players.LocalPlayer
local mouse = player:GetMouse()

local Library = {}

local testmode = false

function Library:tween(object, goal, time, easeStyle,EaseDirection, callback)
	local tweenInfo = nil
	
	if testmode then
		tweenInfo = TweenInfo.new(
			0,
			easeStyle or Enum.EasingStyle.Back,
			EaseDirection or Enum.EasingDirection.Out
		)
	else
		tweenInfo = TweenInfo.new(
			time or 0.15,
			easeStyle or Enum.EasingStyle.Back,
			EaseDirection or Enum.EasingDirection.Out
		)
	end
		
	local tween = tweenService:Create(object, tweenInfo, goal)
	tween.Completed:Connect(callback or function() end)
	tween:Play()
end

function Library:Validate(defaults,options)

	for i, v in pairs(defaults) do
		if options[i] == nil then
			options[i] = v
		end
	end
	return options
end

function Library:CreateWindow(options)
	
	local GUI = {
		CurrentTab = nil,
		CurrentNumTab = nil,
		StartWithAnim = true,
		Smallered = false,
		Minimised = false,
		Loaded = false,
		AnimatingHiding = false,
		ToggleKeybind = nil,
	}
	
	options =  Library:Validate({
		AreSettingsEnabled = false,
		ToggleKeybind = Enum.KeyCode.End,
		LoadingAnimation = {
			Title = "Loading",
			Text = "Welcome to my ui library. Hope you enjouy it",
			Duration = 2
		}
	},options or {})
	
	GUI.ToggleKeybind = options.ToggleKeybind
	
	--make ui
	do
		GUI["1"] = Instance.new("ScreenGui", game:GetService("CoreGui"));
		GUI["1"].Name = game:GetService("HttpService"):GenerateGUID()
		GUI["1"].ResetOnSpawn = false
	--dock
	do 
		GUI["2"] = Instance.new("ImageLabel", GUI["1"]);
		GUI["2"]["BorderSizePixel"] = 0;
		GUI["2"]["BackgroundColor3"] = Color3.fromRGB(190, 201, 224);
		GUI["2"]["ScaleType"] = Enum.ScaleType.Crop;
		GUI["2"]["ImageTransparency"] = 1;
		GUI["2"]["AutomaticSize"] = Enum.AutomaticSize.XY;
		GUI["2"]["AnchorPoint"] = Vector2.new(1, 0.5);
		GUI["2"]["Image"] = [[rbxassetid://16255699706]];
		GUI["2"]["Size"] = UDim2.new(0, 60, 0, 180);
		GUI["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["2"]["BackgroundTransparency"] = 0.15;
		GUI["2"]["Name"] = [[Dock]];
		GUI["2"]["Position"] = UDim2.new(0.99, 80, 0.5, 0);
		
		-- StarterGUI.ScreenGUI.Dock.UICorner
		GUI["3"] = Instance.new("UICorner", GUI["2"]);
		GUI["3"]["CornerRadius"] = UDim.new(0, 28);

		-- StarterGUI.ScreenGUI.Dock.Icons
		GUI["5"] = Instance.new("ScrollingFrame", GUI["2"]);
		GUI["5"]["Active"] = true;
		GUI["5"]["ScrollingDirection"] = Enum.ScrollingDirection.Y;
		GUI["5"]["BorderSizePixel"] = 0;
		GUI["5"]["CanvasSize"] = UDim2.new(1, 0, 1, 0);
		GUI["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["5"]["Name"] = [[Icons]];
		GUI["5"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y ;
			GUI["5"]["Size"] = UDim2.new(1, 0, 1,-20);
			GUI["5"].Position = UDim2.new(0,0,0,10)
		GUI["5"]["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["5"]["ScrollBarThickness"] = 0;
		GUI["5"]["BackgroundTransparency"] = 1;


		-- StarterGUI.ScreenGUI.Dock.Icons.UIListLayout
		GUI["6"] = Instance.new("UIListLayout", GUI["5"]);
		GUI["6"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
		GUI["6"]["Padding"] = UDim.new(0, 10);
		GUI["6"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
		GUI["6"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


		-- StarterGUI.ScreenGUI.Dock.Icons.ImageLabel

		-- StarterGUI.ScreenGUI.Dock.UIGradient
		GUI["a"] = Instance.new("UIGradient", GUI["2"]);
			GUI["a"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(70, 70, 70)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(191, 191, 191))};
	end
	--main
	do
		GUI["10"] = Instance.new("Frame", GUI["1"]);
		GUI["10"]["BorderSizePixel"] = 0;
		GUI["10"]["BackgroundColor3"] = Color3.fromRGB(189, 200, 223);
		GUI["10"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
		GUI["10"]["Size"] = UDim2.new(0,500,0,325);
		GUI["10"]["Position"] = UDim2.new(0.5, 0, 0, -375);
		GUI["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["10"]["Name"] = [[Main]];
		GUI["10"]["BackgroundTransparency"] = 0.2;
		GUI["10"].ClipsDescendants = true
		
		-- StarterGUI.ScreenGUI.Main.UICorner
		GUI["11"] = Instance.new("UICorner", GUI["10"]);
		GUI["11"]["CornerRadius"] = UDim.new(0, 20);

		-- StarterGUI.ScreenGUI.Main.topbar
		GUI["12"] = Instance.new("Frame", GUI["10"]);
		GUI["12"]["BorderSizePixel"] = 0;
		GUI["12"]["BackgroundColor3"] = Color3.fromRGB(2, 2, 2);
		GUI["12"]["Size"] = UDim2.new(1, 0, 0, 35);
		GUI["12"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["12"]["Name"] = [[topbar]];
		GUI["12"]["BackgroundTransparency"] = 1;

		-- StarterGUI.ScreenGUI.Main.topbar.TextLabel
		GUI["13"] = Instance.new("TextLabel", GUI["12"]);
		GUI["13"]["TextWrapped"] = true;
		GUI["13"]["BorderSizePixel"] = 0;
		GUI["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["13"]["TextSize"] = 35;
		GUI["13"]["FontFace"] = Font.new([[rbxassetid://11702779517]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
		GUI["13"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["13"]["BackgroundTransparency"] = 1;
		GUI["13"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
		GUI["13"]["Size"] = UDim2.new(0, 122, 1, -5);
		GUI["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["13"]["Text"] = [[Game]];
		GUI["13"]["Position"] = UDim2.new(0.5, 0, 0.55714, 0);


		-- StarterGUI.ScreenGUI.Main.topbar.UICorner
		GUI["14"] = Instance.new("UICorner", GUI["12"]);
		GUI["14"]["CornerRadius"] = UDim.new(0, 16);


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons
		GUI["15"] = Instance.new("Frame", GUI["12"]);
		GUI["15"]["BorderSizePixel"] = 0;
		GUI["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["15"]["Size"] = UDim2.new(0, 150, 1, 0);
		GUI["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["15"]["Name"] = [[NavButtons]];
		GUI["15"]["BackgroundTransparency"] = 1;


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.UIListLayout
		GUI["16"] = Instance.new("UIListLayout", GUI["15"]);
		GUI["16"]["Padding"] = UDim.new(0, 5);
		GUI["16"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
		GUI["16"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
		GUI["16"]["FillDirection"] = Enum.FillDirection.Horizontal;


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.Red
		GUI["17"] = Instance.new("ImageButton", GUI["15"]);
		GUI["17"]["Active"] = false;
		GUI["17"]["BorderSizePixel"] = 0;
		GUI["17"]["ImageTransparency"] = 1;
		GUI["17"]["BackgroundColor3"] = Color3.fromRGB(253, 99, 94);
		GUI["17"]["Selectable"] = false;
		GUI["17"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
		GUI["17"]["Size"] = UDim2.new(0, 16, 0, 16);
			GUI["17"]["Name"] = [[Red]];
			GUI["17"].AutoButtonColor = false
		GUI["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.Exit.UICorner
		GUI["18"] = Instance.new("UICorner", GUI["17"]);
		GUI["18"]["CornerRadius"] = UDim.new(0, 20);


			-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.Yellow
		GUI["19"] = Instance.new("ImageButton", GUI["15"]);
		GUI["19"]["Active"] = false;
		GUI["19"]["BorderSizePixel"] = 0;
		GUI["19"]["ImageTransparency"] = 1;
		GUI["19"]["BackgroundColor3"] = Color3.fromRGB(254, 189, 65);
			GUI["19"]["Selectable"] = false;
			GUI["19"].AutoButtonColor = false
		GUI["19"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
		GUI["19"]["Size"] = UDim2.new(0, 16, 0, 16);
		GUI["19"]["Name"] = [[Yellow]];
		GUI["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.ToggleVis.UICorner
		GUI["1a"] = Instance.new("UICorner", GUI["19"]);
		GUI["1a"]["CornerRadius"] = UDim.new(0, 20);


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.Green
		GUI["1b"] = Instance.new("ImageButton", GUI["15"]);
		GUI["1b"]["Active"] = false;
		GUI["1b"]["BorderSizePixel"] = 0;
		GUI["1b"]["ImageTransparency"] = 1;
		GUI["1b"]["BackgroundColor3"] = Color3.fromRGB(53, 201, 75);
		GUI["1b"]["Selectable"] = false;
		GUI["1b"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
		GUI["1b"]["Size"] = UDim2.new(0, 16, 0, 16);
		GUI["1b"]["Name"] = [[Green]];
		GUI["1b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["1b"].AutoButtonColor = false

		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.Green.UICorner
		GUI["1c"] = Instance.new("UICorner", GUI["1b"]);
		GUI["1c"]["CornerRadius"] = UDim.new(0, 20);


		-- StarterGUI.ScreenGUI.Main.topbar.NavButtons.UIPadding
		GUI["1d"] = Instance.new("UIPadding", GUI["15"]);
		GUI["1d"]["PaddingTop"] = UDim.new(0, 5);
		GUI["1d"]["PaddingLeft"] = UDim.new(0, 16);


		-- StarterGUI.ScreenGUI.Main.Objects
		GUI["1e"] = Instance.new("Frame", GUI["10"]);
		GUI["1e"]["BorderSizePixel"] = 0;
		GUI["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["1e"]["Size"] = UDim2.new(1, 0, 1, -50);
		GUI["1e"]["Position"] = UDim2.new(0, 0, 0, 50);
		GUI["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["1e"]["Name"] = [[Objects]];
		GUI["1e"]["BackgroundTransparency"] = 1;
			
		GUI["ho"] = Instance.new("ScrollingFrame", GUI["1e"]);
		GUI["ho"]["ScrollingDirection"] = Enum.ScrollingDirection.X;
		GUI["ho"]["BorderSizePixel"] = 0;
		GUI["ho"]["CanvasSize"] = UDim2.new(0, 0, 1, 0);
		GUI["ho"]["ScrollingEnabled"] = false;
		GUI["ho"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
		GUI["ho"]["Name"] = [[Frame]];
		GUI["ho"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X;
		GUI["ho"]["ClipsDescendants"] = false;
		GUI["ho"]["Size"] = UDim2.new(1, 0, 1, 0);
		GUI["ho"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
		GUI["ho"]["ScrollBarThickness"] = 0;
		GUI["ho"]["BackgroundTransparency"] = 1;
			
		GUI["ho1"] = Instance.new("UIListLayout",GUI["ho"])
		GUI["ho1"].FillDirection = Enum.FillDirection.Horizontal
			
		GUI["6c"] = Instance.new("UICorner", GUI["6b"]);
		GUI["6c"]["CornerRadius"] = UDim.new(1, 0);


		-- StarterGUI.ScreenGUI.Main.UIStroke
		GUI["6d"] = Instance.new("UIStroke", GUI["10"]);
		GUI["6d"]["Transparency"] = 0.8;
		GUI["6d"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
		GUI["6d"]["Color"] = Color3.fromRGB(201, 201, 201);


		-- StarterGUI.ScreenGUI.Main.UIGradient
		GUI["6e"] = Instance.new("UIGradient", GUI["10"]);
		GUI["6e"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(70, 70, 70)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(191, 191, 191))};
		
	end
	end
	
	--functions
	do
		function GUI:MakeSettings()
			local Settings = {
				isSettingsSelected = false,
				CanAnimate = true,
				isTabSelected = false
			}
			
			do
			Settings["b"] = Instance.new("Frame", GUI["2"]);
			Settings["b"]["BorderSizePixel"] = 0;
			Settings["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["b"]["AnchorPoint"] = Vector2.new(0.5, 1);
			Settings["b"]["Size"] = UDim2.new(0, 60, 0, 60);
			Settings["b"]["Position"] = UDim2.new(0.5, 0, 0, -20);
			Settings["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["b"]["Name"] = [[Settings]];
			Settings["b"]["BackgroundTransparency"] = 0.55;


			-- StarterSettings.ScreenSettings.Dock.Settings.UICorner
			Settings["c"] = Instance.new("UICorner", Settings["b"]);
			Settings["c"]["CornerRadius"] = UDim.new(0, 18);


			-- StarterSettings.ScreenSettings.Dock.Settings.UIGradient
			Settings["d"] = Instance.new("UIGradient", Settings["b"]);
			Settings["d"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(164, 174, 194)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(71, 154, 154))};


			-- StarterSettings.ScreenSettings.Dock.Settings.UIStroke
			Settings["e"] = Instance.new("UIStroke", Settings["b"]);
			Settings["e"]["Transparency"] = 0.8;
			Settings["e"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
			Settings["e"]["Color"] = Color3.fromRGB(201, 201, 201);


			-- StarterSettings.ScreenSettings.Dock.Settings.ImageLabel
			Settings["f"] = Instance.new("ImageButton", Settings["b"]);
			Settings["f"]["BorderSizePixel"] = 0;
			Settings["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["f"]["ImageTransparency"] = 0.2;
			Settings["f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
			Settings["f"]["Image"] = [[rbxassetid://10734950020]];
				Settings["f"]["Size"] = UDim2.new(0, 40, 0, 40);
				Settings["f"].ImageColor3 = Color3.fromRGB(200,200,200)
			Settings["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["f"]["BackgroundTransparency"] = 1;
			Settings["f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

			-- StarterGUI.ScreenGUI.Setings
			Settings["6f"] = Instance.new("Frame", GUI["1"]);
			Settings["6f"]["Visible"] = false;
			Settings["6f"]["BorderSizePixel"] = 0;
			Settings["6f"]["BackgroundColor3"] = Color3.fromRGB(189, 200, 223);
			Settings["6f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
			Settings["6f"]["ClipsDescendants"] = true;
			Settings["6f"]["Size"] = UDim2.new(0, 500, 0, 400);
			Settings["6f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
			Settings["6f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["6f"]["Name"] = [[Setings]];
			Settings["6f"]["BackgroundTransparency"] = 0.2;


			-- StarterGUI.ScreenGUI.Setings.Objects
			Settings["70"] = Instance.new("Frame", Settings["6f"]);
			Settings["70"]["BorderSizePixel"] = 0;
			Settings["70"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["70"]["Size"] = UDim2.new(1, 0, 1, -50);
			Settings["70"]["Position"] = UDim2.new(0, 0, 0, 50);
			Settings["70"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["70"]["Name"] = [[Objects]];
			Settings["70"]["BackgroundTransparency"] = 1;


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame
			Settings["71"] = Instance.new("ScrollingFrame", Settings["70"]);
			Settings["71"]["Visible"] = false;
			Settings["71"]["ScrollingDirection"] = Enum.ScrollingDirection.Y;
			Settings["71"]["BorderSizePixel"] = 0;
			Settings["71"]["CanvasSize"] = UDim2.new(1, 0, 1, 0);
			Settings["71"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["71"]["Selectable"] = false;
			Settings["71"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
			Settings["71"]["Size"] = UDim2.new(1, 0, 1, 0);
			Settings["71"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["71"]["ScrollBarThickness"] = 9;
			Settings["71"]["BackgroundTransparency"] = 1;


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.UIListLayout
			Settings["72"] = Instance.new("UIListLayout", Settings["71"]);
			Settings["72"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
			Settings["72"]["Padding"] = UDim.new(0, 7);
			Settings["72"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.UIPadding
			Settings["73"] = Instance.new("UIPadding", Settings["71"]);
			Settings["73"]["PaddingTop"] = UDim.new(0, 20);
			Settings["73"]["PaddingRight"] = UDim.new(0, 20);
			Settings["73"]["PaddingLeft"] = UDim.new(0, 20);
			Settings["73"]["PaddingBottom"] = UDim.new(0, 20);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label
			Settings["74"] = Instance.new("TextButton", Settings["71"]);
			Settings["74"]["TextWrapped"] = true;
			Settings["74"]["Active"] = false;
			Settings["74"]["BorderSizePixel"] = 0;
			Settings["74"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			Settings["74"]["TextTransparency"] = 0.2;
			Settings["74"]["TextSize"] = 21;
			Settings["74"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["74"]["TextYAlignment"] = Enum.TextYAlignment.Top;
			Settings["74"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
			Settings["74"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["74"]["Selectable"] = false;
			Settings["74"]["Size"] = UDim2.new(1, 0, -0.10171, 100);
			Settings["74"]["BackgroundTransparency"] = 0.6;
			Settings["74"]["Name"] = [[Label]];
			Settings["74"]["ClipsDescendants"] = true;
			Settings["74"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["74"]["Text"] = [[Label]];
			Settings["74"]["Position"] = UDim2.new(0, 0, 0, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label.UICorner
			Settings["75"] = Instance.new("UICorner", Settings["74"]);
			Settings["75"]["CornerRadius"] = UDim.new(0, 15);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label.UIPadding
			Settings["76"] = Instance.new("UIPadding", Settings["74"]);
			Settings["76"]["PaddingTop"] = UDim.new(0, 15);
			Settings["76"]["PaddingRight"] = UDim.new(0, 15);
			Settings["76"]["PaddingLeft"] = UDim.new(0, 15);
			Settings["76"]["PaddingBottom"] = UDim.new(0, 1);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label.Icon
			Settings["77"] = Instance.new("ImageLabel", Settings["74"]);
			Settings["77"]["BorderSizePixel"] = 0;
			Settings["77"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["77"]["AnchorPoint"] = Vector2.new(1, 0.5);
			Settings["77"]["Image"] = [[rbxassetid://10723415903]];
			Settings["77"]["Size"] = UDim2.new(0, 25, 0, 25);
			Settings["77"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["77"]["BackgroundTransparency"] = 1;
			Settings["77"]["Name"] = [[Icon]];
			Settings["77"]["Position"] = UDim2.new(1, 0, 0.1, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label.TextLabel
			Settings["78"] = Instance.new("TextLabel", Settings["74"]);
			Settings["78"]["TextWrapped"] = true;
			Settings["78"]["BorderSizePixel"] = 0;
			Settings["78"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			Settings["78"]["TextTransparency"] = 0.2;
			Settings["78"]["TextYAlignment"] = Enum.TextYAlignment.Top;
			Settings["78"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["78"]["TextSize"] = 21;
			Settings["78"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["78"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["78"]["BackgroundTransparency"] = 1;
			Settings["78"]["AnchorPoint"] = Vector2.new(0, 1);
			Settings["78"]["Size"] = UDim2.new(1, 0, 0.6, 0);
			Settings["78"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["78"]["Text"] = [[Here are all the settings]];
			Settings["78"]["Position"] = UDim2.new(0, 0, 1, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Label.TextLabel.UIPadding
			Settings["79"] = Instance.new("UIPadding", Settings["78"]);



			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle
			Settings["7a"] = Instance.new("TextButton", Settings["71"]);
			Settings["7a"]["TextWrapped"] = true;
			Settings["7a"]["Active"] = false;
			Settings["7a"]["BorderSizePixel"] = 0;
			Settings["7a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
			Settings["7a"]["TextTransparency"] = 0.2;
			Settings["7a"]["TextSize"] = 21;
			Settings["7a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["7a"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
			Settings["7a"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["7a"]["Selectable"] = false;
			Settings["7a"]["Size"] = UDim2.new(1, 0, 0, 55);
			Settings["7a"]["BackgroundTransparency"] = 0.6;
			Settings["7a"]["Name"] = [[Toggle]];
			Settings["7a"]["ClipsDescendants"] = true;
			Settings["7a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["7a"]["Text"] = [[Smth]];
			Settings["7a"]["Position"] = UDim2.new(0.05357, 0, 0.71672, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.UICorner
			Settings["7b"] = Instance.new("UICorner", Settings["7a"]);
			Settings["7b"]["CornerRadius"] = UDim.new(0, 15);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.UIPadding
			Settings["7c"] = Instance.new("UIPadding", Settings["7a"]);
			Settings["7c"]["PaddingTop"] = UDim.new(0, 15);
			Settings["7c"]["PaddingRight"] = UDim.new(0, 15);
			Settings["7c"]["PaddingLeft"] = UDim.new(0, 15);
			Settings["7c"]["PaddingBottom"] = UDim.new(0, 15);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.ToggleBack
			Settings["7d"] = Instance.new("Frame", Settings["7a"]);
			Settings["7d"]["BorderSizePixel"] = 0;
			Settings["7d"]["BackgroundColor3"] = Color3.fromRGB(196, 197, 201);
			Settings["7d"]["AnchorPoint"] = Vector2.new(1, 0.5);
			Settings["7d"]["Size"] = UDim2.new(0, 65, 0, 32);
			Settings["7d"]["Position"] = UDim2.new(1, -5, 0.5, 0);
			Settings["7d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["7d"]["Name"] = [[ToggleBack]];


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.ToggleBack.UICorner
			Settings["7e"] = Instance.new("UICorner", Settings["7d"]);
			Settings["7e"]["CornerRadius"] = UDim.new(0, 30);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.ToggleBack.ToggleCircle
			Settings["7f"] = Instance.new("Frame", Settings["7d"]);
			Settings["7f"]["BorderSizePixel"] = 0;
			Settings["7f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["7f"]["AnchorPoint"] = Vector2.new(0, 0.5);
			Settings["7f"]["Size"] = UDim2.new(0, 20, 0, 20);
			Settings["7f"]["Position"] = UDim2.new(0, 0, 0.5, 0);
			Settings["7f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["7f"]["Name"] = [[ToggleCircle]];


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.ToggleBack.ToggleCircle.UICorner
			Settings["80"] = Instance.new("UICorner", Settings["7f"]);
			Settings["80"]["CornerRadius"] = UDim.new(1, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.ScrollingFrame.Toggle.ToggleBack.UIPadding
			Settings["81"] = Instance.new("UIPadding", Settings["7d"]);
			Settings["81"]["PaddingTop"] = UDim.new(0, 8);
			Settings["81"]["PaddingRight"] = UDim.new(0, 8);
			Settings["81"]["PaddingLeft"] = UDim.new(0, 8);
			Settings["81"]["PaddingBottom"] = UDim.new(0, 8);


			-- StarterGUI.ScreenGUI.Setings.Objects.General
			Settings["82"] = Instance.new("TextButton", Settings["70"]);
			Settings["82"]["BorderSizePixel"] = 0;
			Settings["82"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["82"]["Size"] = UDim2.new(1, 0, 0.4, 0);
			Settings["82"]["Position"] = UDim2.new(0, 0, 0.026, 0);
			Settings["82"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["82"]["Name"] = [[General]];
				Settings["82"].AutoButtonColor = false
				Settings["82"].Text = [[]]

			-- StarterGUI.ScreenGUI.Setings.Objects.General.UIGradient
			Settings["83"] = Instance.new("UIGradient", Settings["82"]);
			Settings["83"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(164, 174, 194)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(146, 187, 133))};

			-- StarterGUI.ScreenGUI.Setings.Objects.General.TextLabel
			Settings["84"] = Instance.new("TextLabel", Settings["82"]);
			Settings["84"]["TextWrapped"] = true;
			Settings["84"]["BorderSizePixel"] = 0;
			Settings["84"]["TextScaled"] = true;
			Settings["84"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["84"]["TextSize"] = 14;
			Settings["84"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["84"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["84"]["BackgroundTransparency"] = 1;
			Settings["84"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
			Settings["84"]["Size"] = UDim2.new(0, 100, 0, 50);
			Settings["84"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["84"]["Text"] = [[General]];
			Settings["84"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.General.UICorner
			Settings["85"] = Instance.new("UICorner", Settings["82"]);
			Settings["85"]["CornerRadius"] = UDim.new(0, 17);


				-- StarterGUI.ScreenGUI.Setings.Objects.Appearance
			Settings["86"] = Instance.new("TextButton", Settings["70"]);
			Settings["86"]["BorderSizePixel"] = 0;
			Settings["86"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["86"]["Size"] = UDim2.new(1, 0, 0.4, 0);
			Settings["86"]["Position"] = UDim2.new(0, 0, 0.45, 0);
			Settings["86"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["86"]["Name"] = [[Appearance]];
				Settings["86"].AutoButtonColor = false
				Settings["86"].Text = [[]]

			-- StarterGUI.ScreenGUI.Setings.Objects.Frame.UIGradient
			Settings["87"] = Instance.new("UIGradient", Settings["86"]);
			Settings["87"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(164, 174, 194)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(136, 187, 183))};


			-- StarterGUI.ScreenGUI.Setings.Objects.Frame.TextLabel
			Settings["88"] = Instance.new("TextLabel", Settings["86"]);
			Settings["88"]["TextWrapped"] = true;
			Settings["88"]["BorderSizePixel"] = 0;
			Settings["88"]["TextScaled"] = true;
			Settings["88"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["88"]["TextSize"] = 14;
			Settings["88"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["88"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["88"]["BackgroundTransparency"] = 1;
			Settings["88"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
			Settings["88"]["Size"] = UDim2.new(0, 150, 0, 100);
			Settings["88"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["88"]["Text"] = [[Appearance]];
			Settings["88"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);


			-- StarterGUI.ScreenGUI.Setings.Objects.Frame.UICorner
			Settings["89"] = Instance.new("UICorner", Settings["86"]);
			Settings["89"]["CornerRadius"] = UDim.new(0, 17);


			-- StarterGUI.ScreenGUI.Setings.Objects.UIPadding
			Settings["8a"] = Instance.new("UIPadding", Settings["70"]);
			Settings["8a"]["PaddingTop"] = UDim.new(0, 1);
			Settings["8a"]["PaddingRight"] = UDim.new(0, 25);
			Settings["8a"]["PaddingLeft"] = UDim.new(0, 25);
			Settings["8a"]["PaddingBottom"] = UDim.new(0, 1);


			-- StarterGUI.ScreenGUI.Setings.topbar
			Settings["8b"] = Instance.new("Frame", Settings["6f"]);
			Settings["8b"]["BorderSizePixel"] = 0;
			Settings["8b"]["BackgroundColor3"] = Color3.fromRGB(2, 2, 2);
			Settings["8b"]["Size"] = UDim2.new(1, 0, 0, 35);
			Settings["8b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["8b"]["Name"] = [[topbar]];
			Settings["8b"]["BackgroundTransparency"] = 1;


			-- StarterGUI.ScreenGUI.Setings.topbar.TextLabel
			Settings["8c"] = Instance.new("TextLabel", Settings["8b"]);
			Settings["8c"]["TextWrapped"] = true;
			Settings["8c"]["BorderSizePixel"] = 0;
			Settings["8c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["8c"]["TextSize"] = 35;
			Settings["8c"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
			Settings["8c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["8c"]["BackgroundTransparency"] = 1;
			Settings["8c"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
			Settings["8c"]["Size"] = UDim2.new(0.065, 122, 1, -5);
			Settings["8c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["8c"]["Text"] = [[Settings]];
			Settings["8c"]["Position"] = UDim2.new(0.5, 0, 0.52857, 0);


			-- StarterGUI.ScreenGUI.Setings.topbar.UICorner
			Settings["8d"] = Instance.new("UICorner", Settings["8b"]);
			Settings["8d"]["CornerRadius"] = UDim.new(0, 16);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons
			Settings["8e"] = Instance.new("Frame", Settings["8b"]);
			Settings["8e"]["Visible"] = false;
			Settings["8e"]["BorderSizePixel"] = 0;
			Settings["8e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
			Settings["8e"]["Size"] = UDim2.new(0, 150, 1, 0);
			Settings["8e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
			Settings["8e"]["Name"] = [[NavButtons]];
			Settings["8e"]["BackgroundTransparency"] = 1;


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.UIListLayout
			Settings["8f"] = Instance.new("UIListLayout", Settings["8e"]);
			Settings["8f"]["Padding"] = UDim.new(0, 5);
			Settings["8f"]["VerticalAlignment"] = Enum.VerticalAlignment.Center;
			Settings["8f"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
			Settings["8f"]["FillDirection"] = Enum.FillDirection.Horizontal;


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.Exit
			Settings["90"] = Instance.new("ImageButton", Settings["8e"]);
			Settings["90"]["Active"] = false;
			Settings["90"]["BorderSizePixel"] = 0;
			Settings["90"]["ImageTransparency"] = 1;
			Settings["90"]["BackgroundColor3"] = Color3.fromRGB(253, 99, 94);
			Settings["90"]["Selectable"] = false;
			Settings["90"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
			Settings["90"]["Size"] = UDim2.new(0, 16, 0, 16);
			Settings["90"]["Name"] = [[Exit]];
			Settings["90"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.Exit.UICorner
			Settings["91"] = Instance.new("UICorner", Settings["90"]);
			Settings["91"]["CornerRadius"] = UDim.new(0, 20);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.ToggleVis
			Settings["92"] = Instance.new("ImageButton", Settings["8e"]);
			Settings["92"]["Active"] = false;
			Settings["92"]["BorderSizePixel"] = 0;
			Settings["92"]["ImageTransparency"] = 1;
			Settings["92"]["BackgroundColor3"] = Color3.fromRGB(254, 189, 65);
			Settings["92"]["Selectable"] = false;
			Settings["92"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
			Settings["92"]["Size"] = UDim2.new(0, 16, 0, 16);
			Settings["92"]["Name"] = [[ToggleVis]];
			Settings["92"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.ToggleVis.UICorner
			Settings["93"] = Instance.new("UICorner", Settings["92"]);
			Settings["93"]["CornerRadius"] = UDim.new(0, 20);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.Green
			Settings["94"] = Instance.new("ImageButton", Settings["8e"]);
			Settings["94"]["Active"] = false;
			Settings["94"]["BorderSizePixel"] = 0;
			Settings["94"]["ImageTransparency"] = 1;
			Settings["94"]["BackgroundColor3"] = Color3.fromRGB(53, 201, 75);
			Settings["94"]["Selectable"] = false;
			Settings["94"]["Image"] = [[rbxasset://textures/ui/GUIImagePlaceholder.png]];
			Settings["94"]["Size"] = UDim2.new(0, 16, 0, 16);
			Settings["94"]["Name"] = [[Green]];
			Settings["94"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.Green.UICorner
			Settings["95"] = Instance.new("UICorner", Settings["94"]);
			Settings["95"]["CornerRadius"] = UDim.new(0, 20);


			-- StarterGUI.ScreenGUI.Setings.topbar.NavButtons.UIPadding
			Settings["96"] = Instance.new("UIPadding", Settings["8e"]);
			Settings["96"]["PaddingTop"] = UDim.new(0, 5);
			Settings["96"]["PaddingLeft"] = UDim.new(0, 16);


			-- StarterGUI.ScreenGUI.Setings.UIStroke
			Settings["97"] = Instance.new("UIStroke", Settings["6f"]);
			Settings["97"]["Transparency"] = 0.8;
			Settings["97"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
			Settings["97"]["Color"] = Color3.fromRGB(201, 201, 201);


			-- StarterGUI.ScreenGUI.Setings.UIGradient
			Settings["98"] = Instance.new("UIGradient", Settings["6f"]);
			Settings["98"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(164, 174, 194)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(71, 154, 154))};


			-- StarterGUI.ScreenGUI.Setings.UICorner
			Settings["99"] = Instance.new("UICorner", Settings["6f"]);
				Settings["99"]["CornerRadius"] = UDim.new(0, 20);
			end
			--logic
			do
				local function toogle()
					Settings["6f"].Position = GUI["10"].Position
					if Settings.isSettingsSelected == false then
						Library:tween(Settings["f"],{ImageColor3 = Color3.fromRGB(255,255,255)},0.5)
						Library:tween(Settings["f"],{Size = UDim2.new(0, 50, 0, 50)},0.5)
						
						GUI["10"].Size = UDim2.new(0,500,0,325)
						Settings["6f"].Size = UDim2.new(0, 500, 0, 0)
						Library:tween(GUI["10"],{Size = UDim2.new(0, 550, 0, 0)},0.6,Enum.EasingStyle.Back,Enum.EasingDirection.In,function() GUI["10"].Visible = false 
							Settings["6f"].Visible = true
						end)		
						task.wait(0.5)
						Library:tween(Settings["6f"],{Size = UDim2.new(0, 500, 0, 400)},0.6)	
					elseif Settings.isSettingsSelected == true then
						Library:tween(Settings["f"],{ImageColor3 = Color3.fromRGB(200,200,200)},0.5)
						Library:tween(Settings["f"],{Size = UDim2.new(0, 40, 0, 40)},0.5)
						GUI["10"].Size =UDim2.new(0, 550, 0, 0)
						Settings["6f"].Size = UDim2.new(0, 500, 0, 400)
						Library:tween(Settings["6f"],{Size = UDim2.new(0, 500, 0, 0)},0.6,Enum.EasingStyle.Back,Enum.EasingDirection.In,function() Settings["6f"].Visible = false end)	
						wait(0.5)
						Library:tween(GUI["10"],{Size = UDim2.new(0,500,0,325)},0.6)
						GUI["10"].Visible = true
					end
					Settings.isSettingsSelected = not Settings.isSettingsSelected
				end
				
				Settings["f"].MouseButton1Down:Connect(function()
					toogle()
				end)
				Settings["f"].MouseEnter:Connect(function()
					if Settings.isSettingsSelected == false then
						Library:tween(Settings["f"],{Size = UDim2.new(0, 50, 0, 50)},0.5)
					end
				end)
				Settings["f"].MouseLeave:Connect(function()
					if Settings.isSettingsSelected == false then
						Library:tween(Settings["f"],{Size = UDim2.new(0, 40, 0, 40)},0.5)
					end
				end)
			end
			--Settings["6f"] buttons
			do
				--General
				Settings["82"].MouseButton1Down:Connect(function()
					if not Settings.isTabSelected then
						Settings.isTabSelected = true
						Library:tween(Settings["82"],{Size = UDim2.new(1,0,1,0)},0.8)
						Library:tween(Settings["82"],{Position = UDim2.new(0,0,0,0)},0.8)
						Library:tween(Settings["70"],{Size = UDim2.new(1,0,1,0)},0.8)
						Library:tween(Settings["70"],{Position = UDim2.new(0,0,0,0)},0.8)
						Settings["8a"]["PaddingTop"] = UDim.new(0, 0);
						Settings["8a"]["PaddingRight"] = UDim.new(0, 0);
						Settings["8a"]["PaddingLeft"] = UDim.new(0, 0);
						Settings["8a"]["PaddingBottom"] = UDim.new(0, 0);
						Library:tween(Settings["84"],{Position = UDim2.new(0.5,0,0,40)},0.8,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						Settings["86"].Visible = false
						Settings["8b"].Visible = false
					end
				end)
			end
			return Settings
		end
		if options.AreSettingsEnabled then
			GUI:MakeSettings()
		end
		
		local tabCounter = 0
		
		function GUI:CreateTab(options)
			options = Library:Validate({
				Icon = "rbxassetid://121088157314410",
				Text = "Tab"
			},options or {})

			local Tab = {
				Hover = false,
				Active = false,
				tabNum = nil
			}
			
			Tab.tabNum = tabCounter
			tabCounter = tabCounter + 1
			
			if tabCounter > 4 then
				GUI["6"]["VerticalAlignment"] = Enum.VerticalAlignment.Top;
			end
			
			do
				Tab["7"] = Instance.new("ImageButton", GUI["5"]);
				Tab["7"]["Active"] = false;
				Tab["7"]["BorderSizePixel"] = 0;
				Tab["7"]["ImageTransparency"] = 0.2;
				Tab["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
				Tab["7"]["ImageColor3"] = Color3.fromRGB(201, 201, 201);
				Tab["7"]["Selectable"] = false;
				Tab["7"]["Image"] = options.Icon;
				Tab["7"]["Size"] = UDim2.new(0, 35, 0, 35);
				Tab["7"]["BackgroundTransparency"] = 1;
				Tab["7"]["Name"] = options.Text;
				Tab["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

				Tab["1f"] = Instance.new("ScrollingFrame", GUI["ho"]);
				Tab["1f"]["ScrollingDirection"] = Enum.ScrollingDirection.Y;
				Tab["1f"]["BorderSizePixel"] = 0;
				Tab["1f"]["CanvasSize"] = UDim2.new(1, 0, 1, 0);
				Tab["1f"]["CanvasPosition"] = Vector2.new(0, 300);
				Tab["1f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
				Tab["1f"]["Selectable"] = false;
				Tab["1f"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
				Tab["1f"]["Size"] = UDim2.new(1, 0, 0.95, 0);
				Tab["1f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
				Tab["1f"]["ScrollBarThickness"] = 0;
				Tab["1f"]["BackgroundTransparency"] = 1;
				Tab["1f"].Position = UDim2.new(1,0,0,0)
				Tab["1f"].Visible = true
				
				Tab["24"] = Instance.new("UIListLayout", Tab["1f"]);
				Tab["24"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
				Tab["24"]["Padding"] = UDim.new(0, 10);
				Tab["24"]["SortOrder"] = Enum.SortOrder.LayoutOrder;


				-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.UIPadding
				Tab["25"] = Instance.new("UIPadding", Tab["1f"]);
				Tab["25"]["PaddingTop"] = UDim.new(0, 20);
				Tab["25"]["PaddingRight"] = UDim.new(0, 20);
				Tab["25"]["PaddingLeft"] = UDim.new(0, 20);
				Tab["25"]["PaddingBottom"] = UDim.new(0, 20);
			end
			
			do
				function Tab:Activate()
					GUI.CurrentNumTab = Tab.tabNum
					if not Tab.Active then
						if GUI.CurrentTab ~= nil then
							GUI.CurrentTab:Deactivate()
						end
						Tab.Active = true
						Tab["1f"].Visible = true
						--Library:tween(Tab["1f"], {Position = UDim2.new(0,0,0,0)},0.9,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						Library:tween(GUI["ho"], {CanvasPosition = Vector2.new(500 * Tab.tabNum)},0.9,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						Library:tween(Tab["7"],{ImageColor3 = Color3.fromRGB(255,255,255)},0.5)
						Library:tween(Tab["7"],{Size = UDim2.new(0, 45, 0, 45)},0.5)
						Tab["7"]["ImageTransparency"] = 0;
						GUI.CurrentTab = Tab
					end
				end
				
				function Tab:Deactivate()
					if Tab.Active then
						Tab.Active = false
						Tab.Hover = false
						--[[if Tab.tabNum >= GUI.CurrentNumTab then
							Library:tween(Tab["1f"], {Position = UDim2.new(1,0,0,0)},0.9,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						elseif Tab.tabNum <= GUI.CurrentNumTab then
							Library:tween(Tab["1f"], {Position = UDim2.new(-1,0,0,0)},0.9,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						end]]
						Library:tween(Tab["7"],{ImageColor3 = Color3.fromRGB(200,200,200)},0.5)
						Library:tween(Tab["7"],{Size = UDim2.new(0, 35, 0, 35)},0.5)
						Tab["7"]["ImageTransparency"] = 0.2;
					end
				end	
				
				if GUI.CurrentTab == nil then
					Tab:Activate()
				end
				
				do
					Tab["7"].MouseButton1Down:Connect(function() 
						Tab:Activate()
					end)
					Tab["7"].MouseEnter:Connect(function()
						if not Tab.Active then
							Library:tween(Tab["7"],{ImageColor3 = Color3.fromRGB(225,225,225)},0.5)
							Library:tween(Tab["7"],{Size = UDim2.new(0, 45, 0, 45)},0.5)
							Tab["7"]["ImageTransparency"] = 0.2;
						end
					end)
					Tab["7"].MouseLeave:Connect(function()
						if not Tab.Active then
							Library:tween(Tab["7"],{ImageColor3 = Color3.fromRGB(200,200,200)},0.5)
							Library:tween(Tab["7"],{Size = UDim2.new(0, 35, 0, 35)},0.5)
							Tab["7"]["ImageTransparency"] = 0.2;
						end
					end)
				end	
				
				--ui
				do
					function Tab:CreateButton(options)
						options = Library:Validate({
							Text = "Button",
							Callback = function() end
						},options or {})
						
						local button = {
							isClicking = false,
							isHovering = false
						}
						do
							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Button
							button["20"] = Instance.new("TextButton", Tab["1f"]);
							button["20"]["TextWrapped"] = true;
							button["20"]["Active"] = false;
							button["20"]["BorderSizePixel"] = 0;
							button["20"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							button["20"]["TextTransparency"] = 0.2;
							button["20"]["TextSize"] = 21;
							button["20"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							button["20"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							button["20"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							button["20"]["Selectable"] = false;
							button["20"]["Size"] = UDim2.new(1, 0, 0, 50);
							button["20"]["BackgroundTransparency"] = 0.6;
							button["20"]["Name"] = [[Button]];
							button["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							button["20"].Text = options.Text
							button["20"].AutoButtonColor = false

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Button.UIPadding
							button["21"] = Instance.new("UIPadding", button["20"]);
							button["21"]["PaddingTop"] = UDim.new(0, 15);
							button["21"]["PaddingRight"] = UDim.new(0, 15);
							button["21"]["PaddingLeft"] = UDim.new(0, 15);
							button["21"]["PaddingBottom"] = UDim.new(0, 15);

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Button.Icon
							button["22"] = Instance.new("ImageLabel", button["20"]);
							button["22"]["BorderSizePixel"] = 0;
							button["22"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							button["22"]["AnchorPoint"] = Vector2.new(1, 0.5);
							button["22"]["Image"] = [[rbxassetid://10734898194]];
							button["22"]["Size"] = UDim2.new(0, 25, 0, 25);
							button["22"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							button["22"]["BackgroundTransparency"] = 1;
							button["22"]["Name"] = [[Icon]];
							button["22"]["Position"] = UDim2.new(1, 0, 0.5, 0);

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Button.UICorner
							button["23"] = Instance.new("UICorner", button["20"]);
							button["23"]["CornerRadius"] = UDim.new(0, 15);
						end
						
						--logic
						do
							button["20"].MouseButton1Down:Connect(function()
								options.Callback()
								Library:tween(button["20"],{Size = UDim2.new(1,10,0,60)},0.8)
								Library:tween(button["20"],{BackgroundColor3 = Color3.fromRGB(132, 132, 132)},0.8)
								Library:tween(button["22"],{Size = UDim2.new(0,30, 0, 30)},0.8)
								Library:tween(button["22"],{Rotation = -10},0.4)
							end)
							button["20"].MouseButton1Up:Connect(function()
								Library:tween(button["20"],{Size = UDim2.new(1,0,0,50)},0.8)
								Library:tween(button["22"],{Size = UDim2.new(0,25, 0, 25)},0.8)
								Library:tween(button["20"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
								Library:tween(button["22"],{Rotation = 0},0.4)
							end)
							button["20"].MouseEnter:Connect(function()
								Library:tween(button["20"],{Size = UDim2.new(1,5,0,55)},0.8)
								Library:tween(button["20"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)
							end)
							button["20"].MouseLeave:Connect(function()
								Library:tween(button["20"],{Size = UDim2.new(1,0,0,50)},0.8)
								Library:tween(button["20"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
							end)
						end
						return button
					end
					function Tab:Seperator()
						local Seperator = {}
						Seperator["6b"] = Instance.new("Frame", Tab["1f"]);
						Seperator["6b"]["BorderSizePixel"] = 0;
						Seperator["6b"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
						Seperator["6b"]["Size"] = UDim2.new(1, 0, 0, 10);
						Seperator["6b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
						Seperator["6b"]["Name"] = [[Seperator]];
						Seperator["6b"]["BackgroundTransparency"] = 0.6;


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Seperator.UICorner
						Seperator["6c"] = Instance.new("UICorner", Seperator["6b"]);
						Seperator["6c"]["CornerRadius"] = UDim.new(1, 0);
						return Seperator
					end
					function Tab:Paragraph(options)
						options = Library:Validate({
							Text = "Button",
						},options or {})
						
						local Paragraph = {}
						
						do
							Paragraph["65"] = Instance.new("TextLabel", Tab["1f"]);
							Paragraph["65"]["TextWrapped"] = true;
							Paragraph["65"]["BorderSizePixel"] = 0;
							Paragraph["65"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							Paragraph["65"]["TextTransparency"] = 0.2;
							Paragraph["65"]["TextYAlignment"] = Enum.TextYAlignment.Top;
							Paragraph["65"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							Paragraph["65"]["TextSize"] = 21;
							Paragraph["65"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Paragraph["65"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Paragraph["65"]["BackgroundTransparency"] = 0.6;
							Paragraph["65"]["Size"] = UDim2.new(1, 0, 0, 100);
							Paragraph["65"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Paragraph["65"]["Text"] = [[]];
							Paragraph["65"]["Name"] = [[Paragraph]];
							Paragraph["65"]["Position"] = UDim2.new(0, 0, 0, 0);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Paragraph.UICorner
							Paragraph["66"] = Instance.new("UICorner", Paragraph["65"]);
							Paragraph["66"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Paragraph.UIPadding
							Paragraph["67"] = Instance.new("UIPadding", Paragraph["65"]);
							Paragraph["67"]["PaddingTop"] = UDim.new(0, 15);
							Paragraph["67"]["PaddingRight"] = UDim.new(0, 15);
							Paragraph["67"]["PaddingLeft"] = UDim.new(0, 15);
							Paragraph["67"]["PaddingBottom"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Paragraph.Icon
							Paragraph["68"] = Instance.new("ImageLabel", Paragraph["65"]);
							Paragraph["68"]["BorderSizePixel"] = 0;
							Paragraph["68"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							Paragraph["68"]["AnchorPoint"] = Vector2.new(1, 0.5);
							Paragraph["68"]["Image"] = [[rbxassetid://10723415903]];
							Paragraph["68"]["Size"] = UDim2.new(0, 25, 0, 25);
							Paragraph["68"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Paragraph["68"]["BackgroundTransparency"] = 1;
							Paragraph["68"]["Name"] = [[Icon]];
							Paragraph["68"]["Position"] = UDim2.new(1, 0, 0.1, 0);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Paragraph.TextLabel
							Paragraph["69"] = Instance.new("TextLabel", Paragraph["65"]);
							Paragraph["69"]["TextWrapped"] = true;
							Paragraph["69"]["BorderSizePixel"] = 0;
							Paragraph["69"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							Paragraph["69"]["TextTransparency"] = 0.2;
							Paragraph["69"]["TextYAlignment"] = Enum.TextYAlignment.Top;
							Paragraph["69"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							Paragraph["69"]["TextSize"] = 21;
							Paragraph["69"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Paragraph["69"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Paragraph["69"]["BackgroundTransparency"] = 1;
							Paragraph["69"]["AnchorPoint"] = Vector2.new(0, .5);
							Paragraph["69"]["Size"] = UDim2.new(0.91, 0, 1, 0);
							Paragraph["69"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Paragraph["69"]["Text"] = options.Text;
							Paragraph["69"]["Position"] = UDim2.new(0, 0, .5, 0);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Paragraph.TextLabel.UIPadding
							Paragraph["6a"] = Instance.new("UIPadding", Paragraph["69"]);
						end
						
						do
							function Paragraph:_update(Text)
								if Text ~= nil then
									Paragraph["69"]["Text"] = Text
								else
									Paragraph["69"]["Text"] = options.Text
								end
								Paragraph["69"].Size = UDim2.new(Paragraph["69"].Size.X.Scale, Paragraph["69"].Size.X.Offset, 0, math.huge)
								Paragraph["69"].Size = UDim2.new(Paragraph["69"].Size.X.Scale, Paragraph["69"].Size.X.Offset, 0, Paragraph["69"].TextBounds.Y)
								Library:tween(Paragraph["65"], {Size = UDim2.new(Paragraph["65"].Size.X.Scale, Paragraph["65"].Size.X.Offset, 0,Paragraph["69"].TextBounds.Y + 14+25)},0.5)
							end
							Paragraph:_update()
						end
						return Paragraph
					end
					function Tab:Label(options)
						options = Library:Validate({
							Title = "KABOOM",
							Text = "Button",
						},options or {})

						local Label = {}

						do
							Label["74"] = Instance.new("TextLabel", Tab["1f"]);
							Label["74"]["TextWrapped"] = true;
							Label["74"]["Active"] = false;
							Label["74"]["BorderSizePixel"] = 0;
							Label["74"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							Label["74"]["TextTransparency"] = 0.2;
							Label["74"]["TextSize"] = 21;
							Label["74"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Label["74"]["TextYAlignment"] = Enum.TextYAlignment.Top;
							Label["74"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							Label["74"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Label["74"]["Size"] = UDim2.new(1, 0, -0.10171, 100);
							Label["74"]["BackgroundTransparency"] = 0.6;
							Label["74"]["Name"] = [[Label]];
							Label["74"]["ClipsDescendants"] = true;
							Label["74"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Label["74"]["Text"] = options.Title;
							Label["74"]["Position"] = UDim2.new(0, 0, 0, 0);


							-- StarterGui.ScreenGui.Setings.Objects.ScrollingFrame.Label.UICorner
							Label["75"] = Instance.new("UICorner", Label["74"]);
							Label["75"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Setings.Objects.ScrollingFrame.Label.UIPadding
							Label["76"] = Instance.new("UIPadding", Label["74"]);
							Label["76"]["PaddingTop"] = UDim.new(0, 10);
							Label["76"]["PaddingRight"] = UDim.new(0, 15);
							Label["76"]["PaddingLeft"] = UDim.new(0, 15);
							Label["76"]["PaddingBottom"] = UDim.new(0, 1);


							-- StarterGui.ScreenGui.Setings.Objects.ScrollingFrame.Label.Icon
							Label["77"] = Instance.new("ImageLabel", Label["74"]);
							Label["77"]["BorderSizePixel"] = 0;
							Label["77"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							Label["77"]["AnchorPoint"] = Vector2.new(1, 0);
							Label["77"]["Image"] = [[rbxassetid://10723415903]];
							Label["77"]["Size"] = UDim2.new(0, 25, 0, 25);
							Label["77"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Label["77"]["BackgroundTransparency"] = 1;
							Label["77"]["Name"] = [[Icon]];
							Label["77"]["Position"] = UDim2.new(1, 0, 0, 0);


							-- StarterGui.ScreenGui.Setings.Objects.ScrollingFrame.Label.TextLabel
							Label["78"] = Instance.new("TextLabel", Label["74"]);
							Label["78"]["TextWrapped"] = true;
							Label["78"]["BorderSizePixel"] = 0;
							Label["78"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							Label["78"]["TextTransparency"] = 0.2;
							Label["78"]["TextYAlignment"] = Enum.TextYAlignment.Top;
							Label["78"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							Label["78"]["TextSize"] = 21;
							Label["78"]["FontFace"] = Font.new([[rbxassetid://16658246179]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Label["78"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Label["78"]["BackgroundTransparency"] = 1;
							Label["78"]["AnchorPoint"] = Vector2.new(0, 1);
							Label["78"]["Size"] = UDim2.new(1, 0, 0.6, 0);
							Label["78"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Label["78"]["Text"] = [[Here are all the settings]];
							Label["78"]["Position"] = UDim2.new(0, 0, 1, -10);


							-- StarterGui.ScreenGui.Setings.Objects.ScrollingFrame.Label.TextLabel.UIPadding
							Label["79"] = Instance.new("UIPadding", Label["78"]);
						end
						
						do
							function Label:_updateText(Text)
								if Text ~= nil then
									Label["78"]["Text"] = Text
								else
									Label["78"]["Text"] = options.Text
								end
								Label["78"].Size = UDim2.new(Label["78"].Size.X.Scale, Label["78"].Size.X.Offset, 0, math.huge)
								Label["78"].Size = UDim2.new(Label["78"].Size.X.Scale, Label["78"].Size.X.Offset, 0, Label["78"].TextBounds.Y)
								Library:tween(Label["74"], {Size = UDim2.new(Label["74"].Size.X.Scale, Label["74"].Size.X.Offset, 0,Label["78"].TextBounds.Y + 14+35)},0.5)
							end
							function Label:_updateLabel(Text)
								Label["74"]["Text"] = Text
							end
							Label:_updateText()
						end
						return Label
					end
					function Tab:Toggle(options)
						options = Library:Validate({
							Text = "Toggle",
							DefaultState = false,
							Callback = function(v)end
						},options or {})
						
						local Toggle = {
							currentstate = false
						}
						--ui
						do
						Toggle["26"] = Instance.new("TextButton", Tab["1f"]);
						Toggle["26"]["TextWrapped"] = true;
						Toggle["26"]["Active"] = false;
						Toggle["26"]["BorderSizePixel"] = 0;
						Toggle["26"]["TextXAlignment"] = Enum.TextXAlignment.Left;
						Toggle["26"]["TextTransparency"] = 0.2;
						Toggle["26"]["TextSize"] = 21;
						Toggle["26"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
						Toggle["26"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
						Toggle["26"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
						Toggle["26"]["Selectable"] = false;
						Toggle["26"]["Size"] = UDim2.new(1, 0, 0, 55);
						Toggle["26"]["BackgroundTransparency"] = 0.6;
						Toggle["26"]["Name"] = [[Toggle]];
						Toggle["26"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
						Toggle["26"]["Text"] = options.Text;
						Toggle["26"]["Position"] = UDim2.new(0.05357, 0, 0.71672, 0);
							Toggle["26"].ClipsDescendants = false
							Toggle["26"].AutoButtonColor = false

						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.UICorner
						Toggle["27"] = Instance.new("UICorner", Toggle["26"]);
						Toggle["27"]["CornerRadius"] = UDim.new(0, 15);


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.UIPadding
						Toggle["28"] = Instance.new("UIPadding", Toggle["26"]);
						Toggle["28"]["PaddingTop"] = UDim.new(0, 15);
						Toggle["28"]["PaddingRight"] = UDim.new(0, 15);
						Toggle["28"]["PaddingLeft"] = UDim.new(0, 15);
						Toggle["28"]["PaddingBottom"] = UDim.new(0, 15);


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.ToggleBack
						Toggle["29"] = Instance.new("Frame", Toggle["26"]);
						Toggle["29"]["BorderSizePixel"] = 0;
						Toggle["29"]["BackgroundColor3"] = Color3.fromRGB(196, 197, 201);
						Toggle["29"]["AnchorPoint"] = Vector2.new(1, 0.5);
						Toggle["29"]["Size"] = UDim2.new(0, 60, 0, 30);
						Toggle["29"]["Position"] = UDim2.new(1, -5, 0.5, 0);
						Toggle["29"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
						Toggle["29"]["Name"] = [[ToggleBack]];


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.ToggleBack.UICorner
						Toggle["2a"] = Instance.new("UICorner", Toggle["29"]);
						Toggle["2a"]["CornerRadius"] = UDim.new(0, 30);


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.ToggleBack.ToggleCircle
						Toggle["2b"] = Instance.new("Frame", Toggle["29"]);
						Toggle["2b"]["BorderSizePixel"] = 0;
						Toggle["2b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
						Toggle["2b"]["AnchorPoint"] = Vector2.new(0, 0.5);
						Toggle["2b"]["Size"] = UDim2.new(0, 20, 0, 20);
						Toggle["2b"]["Position"] = UDim2.new(0, 0, 0.5, 0);
						Toggle["2b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
						Toggle["2b"]["Name"] = [[ToggleCircle]];


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.ToggleBack.ToggleCircle.UICorner
						Toggle["2c"] = Instance.new("UICorner", Toggle["2b"]);
						Toggle["2c"]["CornerRadius"] = UDim.new(1, 0);


						-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Toggle.ToggleBack.UIPadding
						Toggle["2d"] = Instance.new("UIPadding", Toggle["29"]);
						Toggle["2d"]["PaddingTop"] = UDim.new(0, 8);
							Toggle["2d"]["PaddingRight"] = UDim.new(0, 27);
						Toggle["2d"]["PaddingLeft"] = UDim.new(0, 8);
						Toggle["2d"]["PaddingBottom"] = UDim.new(0, 8);
						end	
						
						--logic
						do
							function Toggle:ChangeState(bool)
								if bool == true then
									Library:tween(Toggle["2b"],{Position = UDim2.new(1, 0, 0.5, 0)},0.6)
									Library:tween(Toggle["29"],{BackgroundColor3 = Color3.fromRGB(131, 187, 200)},0.6)
								else
									Library:tween(Toggle["2b"],{Position = UDim2.new(0, 0, 0.5, 0)},0.6)
									Library:tween(Toggle["29"],{BackgroundColor3 = Color3.fromRGB(195, 196, 200)},0.6)
								end
							end
							
							Toggle.currentstate = options.DefaultState
							Toggle:ChangeState(options.DefaultState)
							
							Toggle["26"].MouseButton1Down:Connect(function()
								Toggle.currentstate = not Toggle.currentstate
								Toggle:ChangeState(Toggle.currentstate)
								Library:tween(Toggle["26"],{Size = UDim2.new(1,10,0,65)},0.8)
								Library:tween(Toggle["26"],{BackgroundColor3 = Color3.fromRGB(132, 132, 132)},0.8)
								options.Callback(Toggle.currentstate)	
							end)
							Toggle["26"].MouseButton1Up:Connect(function()
								Library:tween(Toggle["26"],{Size = UDim2.new(1,0,0,55)},0.8)
								Library:tween(Toggle["26"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
							end)
							Toggle["26"].MouseEnter:Connect(function()
								Library:tween(Toggle["26"],{Size = UDim2.new(1,5,0,60)},0.8)
								Library:tween(Toggle["26"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)
							end)
							Toggle["26"].MouseLeave:Connect(function()
								Library:tween(Toggle["26"],{Size = UDim2.new(1,0,0,55)},0.8)
								Library:tween(Toggle["26"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
							end)
						end
						return Toggle
					end
					function Tab:TextInput(options)
						options = Library:Validate({
							Text = "TextInput",
							PlaceHolderText = "Txt",
							Callback = function(v) end
						},options or {})
						
						local TextInput = {}
						
						do
							TextInput["2e"] = Instance.new("TextButton", Tab["1f"]);
							TextInput["2e"]["TextWrapped"] = true;
							TextInput["2e"]["Active"] = false;
							TextInput["2e"]["BorderSizePixel"] = 0;
							TextInput["2e"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							TextInput["2e"]["TextTransparency"] = 0.2;
							TextInput["2e"]["TextSize"] = 21;
							TextInput["2e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							TextInput["2e"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							TextInput["2e"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							TextInput["2e"]["Selectable"] = false;
							TextInput["2e"]["Size"] = UDim2.new(1, 0, 0, 55);
							TextInput["2e"]["BackgroundTransparency"] = 0.6;
							TextInput["2e"]["Name"] = [[TextInput]];
							TextInput["2e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							TextInput["2e"]["Text"] = options.Text;
							TextInput["2e"]["Position"] = UDim2.new(0.05357, 0, 0.71672, 0);
							TextInput["2e"].AutoButtonColor = false

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.UICorner
							TextInput["2f"] = Instance.new("UICorner", TextInput["2e"]);
							TextInput["2f"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.UIPadding
							TextInput["30"] = Instance.new("UIPadding", TextInput["2e"]);
							TextInput["30"]["PaddingTop"] = UDim.new(0, 15);
							TextInput["30"]["PaddingRight"] = UDim.new(0, 15);
							TextInput["30"]["PaddingLeft"] = UDim.new(0, 15);
							TextInput["30"]["PaddingBottom"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox
							TextInput["31"] = Instance.new("TextBox", TextInput["2e"]);
							TextInput["31"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							TextInput["31"]["PlaceholderColor3"] = Color3.fromRGB(186, 186, 186);
							TextInput["31"]["BorderSizePixel"] = 0;
							TextInput["31"]["TextXAlignment"] = Enum.TextXAlignment.Right;
							TextInput["31"]["TextSize"] = 21;
							TextInput["31"]["BackgroundColor3"] = Color3.fromRGB(96, 96, 96);
							TextInput["31"]["FontFace"] = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							TextInput["31"]["AutomaticSize"] = Enum.AutomaticSize.X;
							TextInput["31"]["AnchorPoint"] = Vector2.new(1, 0.5);
							TextInput["31"]["Size"] = UDim2.new(0, 15, 0, 30);
							TextInput["31"]["Position"] = UDim2.new(1, 0, 0.5, 0);
							TextInput["31"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							TextInput["31"]["Text"] = [[ss]];
							TextInput["31"]["BackgroundTransparency"] = 0.7;
							TextInput["31"].PlaceholderText = options.PlaceHolderText
							TextInput["31"].ClearTextOnFocus = false

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox.UICorner
							TextInput["32"] = Instance.new("UICorner", TextInput["31"]);

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox.UIPadding
							TextInput["33"] = Instance.new("UIPadding", TextInput["31"]);
							TextInput["33"]["PaddingTop"] = UDim.new(0, 7);
							TextInput["33"]["PaddingRight"] = UDim.new(0, 7);
							TextInput["33"]["PaddingLeft"] = UDim.new(0, 7);
							TextInput["33"]["PaddingBottom"] = UDim.new(0, 7);
						end
						
						do
							TextInput["2e"].MouseEnter:Connect(function()
								Library:tween(TextInput["2e"],{Size = UDim2.new(1,5,0,55)},0.8)
								Library:tween(TextInput["2e"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)
							end)
							TextInput["2e"].MouseLeave:Connect(function()
								Library:tween(TextInput["2e"],{Size = UDim2.new(1,0,0,50)},0.8)
								Library:tween(TextInput["2e"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
							end)
							
							TextInput["31"].FocusLost:Connect(function(enterPressed)
								if enterPressed then
									if TextInput["31"].Text == nil then
										return
									else
										options.Callback(tostring(TextInput["31"].Text))
									end
								end
							end)
							TextInput["31"].Focused:Connect(function()
								local text = TextInput["31"].Text
								local totalTime = 0.3
								local waitTime = totalTime / (#text + 1)
								
								for i = #text, 0, -1 do
									TextInput["31"].Text = text:sub(1, i)
									task.wait(waitTime)
								end
							end)
						end
						return TextInput
					end
					function Tab:Slider(options)
						options = Library:Validate({
							Text = "Slider",
							StartingValue = 34,
							max = 100,
							min = 0,
							Callback = function(v) end
						},options or {})
						
						local Slider = {}
						
						do
							Slider["3a"] = Instance.new("TextButton", Tab["1f"]);
							Slider["3a"]["TextWrapped"] = true;
							Slider["3a"]["BorderSizePixel"] = 0;
							Slider["3a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							Slider["3a"]["TextTransparency"] = 0.2;
							Slider["3a"]["TextYAlignment"] = Enum.TextYAlignment.Top;
							Slider["3a"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							Slider["3a"]["TextSize"] = 21;
							Slider["3a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Slider["3a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Slider["3a"]["BackgroundTransparency"] = 0.6;
							Slider["3a"]["Size"] = UDim2.new(1, 0, 0, 75);
							Slider["3a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Slider["3a"]["Text"] = options.Text;
							Slider["3a"]["Name"] = [[Slider]];
							Slider["3a"].AutoButtonColor = false

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.UICorner
							Slider["3b"] = Instance.new("UICorner", Slider["3a"]);
							Slider["3b"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.UIPadding
							Slider["3c"] = Instance.new("UIPadding", Slider["3a"]);
							Slider["3c"]["PaddingTop"] = UDim.new(0, 15);
							Slider["3c"]["PaddingRight"] = UDim.new(0, 15);
							Slider["3c"]["PaddingLeft"] = UDim.new(0, 15);
							Slider["3c"]["PaddingBottom"] = UDim.new(0, 12);

							
							Slider["3d"] = Instance.new("TextLabel",Slider["3a"]);
							Slider["3d"]["TextWrapped"] = true;
							Slider["3d"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
							Slider["3d"]["BorderSizePixel"] = 0;
							Slider["3d"]["TextXAlignment"] = Enum.TextXAlignment.Right;
							Slider["3d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							Slider["3d"]["TextSize"] = 20;
							Slider["3d"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							Slider["3d"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							Slider["3d"]["BackgroundTransparency"] = 1;
							Slider["3d"]["AnchorPoint"] = Vector2.new(1, 0);
							Slider["3d"]["Size"] = UDim2.new(0, 150, 0, 30);
							Slider["3d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Slider["3d"]["Text"] = options.StartingValue;
							Slider["3d"]["Position"] = UDim2.new(1, 0, 0, 0);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.Slider
							Slider["3e"] = Instance.new("Frame", Slider["3a"]);
							Slider["3e"]["BorderSizePixel"] = 0;
							Slider["3e"]["BackgroundColor3"] = Color3.fromRGB(201, 201, 201);
							Slider["3e"]["AnchorPoint"] = Vector2.new(0, 1);
							Slider["3e"]["Size"] = UDim2.new(1, 0, 0, 12);
							Slider["3e"]["Position"] = UDim2.new(0, 0, 1, 0);
							Slider["3e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Slider["3e"]["Name"] = [[Slider]];
							Slider["3e"]["BackgroundTransparency"] = 0.3;


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.Slider.UICorner
							Slider["3f"] = Instance.new("UICorner", Slider["3e"]);
							Slider["3f"]["CornerRadius"] = UDim.new(0, 11);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.Slider.Slider
							Slider["40"] = Instance.new("Frame", Slider["3e"]);
							Slider["40"]["BorderSizePixel"] = 0;
							Slider["40"]["BackgroundColor3"] = Color3.fromRGB(231, 231, 231);
							Slider["40"]["AnchorPoint"] = Vector2.new(0, 1);
							Slider["40"]["Size"] = UDim2.new(0.5, 0, 0, 12);
							Slider["40"]["Position"] = UDim2.new(0, 0, 1, 0);
							Slider["40"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							Slider["40"]["Name"] = [[Slider]];
							Slider["40"]["BackgroundTransparency"] = 0.3;


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.Slider.Slider.Slider.UICorner
							Slider["41"] = Instance.new("UICorner", Slider["40"]);
							Slider["41"]["CornerRadius"] = UDim.new(0, 11);
						end
						
						do
							function Slider:GetValue()
								return tonumber(Slider["3d"].Text)
							end
							
							function Slider:SetValue(v)
								if v ==  nil then
									local precentage = math.clamp((mouse.X - Slider["3e"].AbsolutePosition.X) / (Slider["3e"].AbsoluteSize.X), 0, 1)
									local value = math.floor(((options.max - options.min) * precentage) + options.min)

									Slider["3d"].Text = tostring(value)
									Library:tween(Slider["40"], {Size =UDim2.fromScale(precentage,1)},.6, Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
								else
									Slider["3d"].Text = tostring(v)

									Library:tween(Slider["40"], {Size =UDim2.fromScale(((v -options.min) / (options.max - options.min)),1) },1)
								end
								options.Callback(Slider:GetValue())
							end
							
							function Slider:SetValues(v)
								if v ==  nil then
									local precentage = math.clamp((mouse.X - Slider["3e"].AbsolutePosition.X) / (Slider["3e"].AbsoluteSize.X), 0, 1)
									local value = math.floor(((options.max - options.min) * precentage) + options.min)

									Slider["3d"].Text = tostring(value)
									Library:tween(Slider["40"], {Size =UDim2.fromScale(precentage,1)},.6, Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
								else
									Slider["3d"].Text = tostring(v)

									Library:tween(Slider["40"], {Size =UDim2.fromScale(((v -options.min) / (options.max - options.min)),1) },1)
								end
							end

							Slider["3a"].MouseButton1Down:Connect(function()
								if not Slider.Connection then
									Slider.Connection = game:GetService("RunService").RenderStepped:Connect(function()
										Slider:SetValue()
									end)
								end
								Library:tween(Slider["3a"],{Size = UDim2.new(1,10,0,85)},0.8)
								Library:tween(Slider["3a"],{BackgroundColor3 = Color3.fromRGB(132, 132, 132)},0.8)
							end)
							
							Slider["3a"].MouseButton1Up:Connect(function()
								if Slider.Connection then Slider.Connection:Disconnect() end
								Slider.Connection = nil
								Library:tween(Slider["3a"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
								Library:tween(Slider["3a"],{Size = UDim2.new(1,0,0,75)},0.8)
							end)
							
							Slider["3a"].MouseEnter:Connect(function()
								Library:tween(Slider["3a"],{Size = UDim2.new(1,5,0,80)},0.8)
								Library:tween(Slider["3a"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)

							end)
							
							Slider["3a"].MouseLeave:Connect(function()
								if Slider.Connection then Slider.Connection:Disconnect() end
								Slider.Connection = nil
								Library:tween(Slider["3a"],{Size = UDim2.new(1,0,0,75)},0.8)
								Library:tween(Slider["3a"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)

							end)
							
							Slider:SetValues(options.StartingValue)
						end	
						return Slider
					end
					function Tab:KeyBind(options)
						options = Library:Validate({
							Text = "KeyBind",
							Bind = Enum.KeyCode.L,
							Callback = function(v) end
						},options or {})
						
						local KeyBind = {
							CurrentKeyBind = nil
						}
						
						KeyBind.CurrentKeyBind = options.Bind
						--make ui
						do
							KeyBind["5f"] = Instance.new("TextButton", Tab["1f"]);
							KeyBind["5f"]["TextWrapped"] = true;
							KeyBind["5f"]["Active"] = false;
							KeyBind["5f"]["BorderSizePixel"] = 0;
							KeyBind["5f"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							KeyBind["5f"]["TextTransparency"] = 0.2;
							KeyBind["5f"]["TextSize"] = 21;
							KeyBind["5f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							KeyBind["5f"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							KeyBind["5f"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							KeyBind["5f"]["Selectable"] = false;
							KeyBind["5f"]["Size"] = UDim2.new(1, 0, 0, 55);
							KeyBind["5f"]["BackgroundTransparency"] = 0.6;
							KeyBind["5f"]["Name"] = [[KeyBind]];
							KeyBind["5f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							KeyBind["5f"]["Text"] = options.Text;
							KeyBind["5f"]["Position"] = UDim2.new(0.05357, 0, 0.71672, 0);
							KeyBind["5f"].AutoButtonColor = false

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.UICorner
							KeyBind["60"] = Instance.new("UICorner", KeyBind["5f"]);
							KeyBind["60"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.UIPadding
							KeyBind["61"] = Instance.new("UIPadding", KeyBind["5f"]);
							KeyBind["61"]["PaddingTop"] = UDim.new(0, 15);
							KeyBind["61"]["PaddingRight"] = UDim.new(0, 15);
							KeyBind["61"]["PaddingLeft"] = UDim.new(0, 15);
							KeyBind["61"]["PaddingBottom"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox
							KeyBind["62"] = Instance.new("TextBox", KeyBind["5f"]);
							KeyBind["62"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							KeyBind["62"]["PlaceholderColor3"] = Color3.fromRGB(186, 186, 186);
							KeyBind["62"]["BorderSizePixel"] = 0;
							KeyBind["62"]["TextEditable"] = false;
							KeyBind["62"]["TextXAlignment"] = Enum.TextXAlignment.Right;
							KeyBind["62"]["TextSize"] = 21;
							KeyBind["62"]["BackgroundColor3"] = Color3.fromRGB(96, 96, 96);
							KeyBind["62"]["FontFace"] = Font.new([[rbxassetid://12187365364]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							KeyBind["62"]["AutomaticSize"] = Enum.AutomaticSize.X;
							KeyBind["62"]["AnchorPoint"] = Vector2.new(1, 0.5);
							KeyBind["62"]["PlaceholderText"] = [[Key]];
							KeyBind["62"]["Size"] = UDim2.new(0, 15, 0, 30);
							KeyBind["62"]["Position"] = UDim2.new(1, 0, 0.5, 0);
							KeyBind["62"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							KeyBind["62"]["Text"] = "Keybind:" .. tostring(KeyBind.CurrentKeyBind.Name);
							KeyBind["62"]["BackgroundTransparency"] = 0.7;


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox.UICorner
							KeyBind["63"] = Instance.new("UICorner", KeyBind["62"]);



							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.TextInput.TextBox.UIPadding
							KeyBind["64"] = Instance.new("UIPadding", KeyBind["62"]);
							KeyBind["64"]["PaddingTop"] = UDim.new(0, 7);
							KeyBind["64"]["PaddingRight"] = UDim.new(0, 7);
							KeyBind["64"]["PaddingLeft"] = UDim.new(0, 7);
							KeyBind["64"]["PaddingBottom"] = UDim.new(0, 7);
						end
						--logic
						do
							KeyBind["5f"].MouseButton1Down:Connect(function()
								Library:tween(KeyBind["5f"],{Size = UDim2.new(1,10,0,65)},0.8)
								Library:tween(KeyBind["5f"],{BackgroundColor3 = Color3.fromRGB(132, 132, 132)},0.8)
							end)

							KeyBind["5f"].MouseButton1Up:Connect(function()
								Library:tween(KeyBind["5f"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
								Library:tween(KeyBind["5f"],{Size = UDim2.new(1,0,0,55)},0.8)
							end)

							KeyBind["5f"].MouseEnter:Connect(function()
								Library:tween(KeyBind["5f"],{Size = UDim2.new(1,5,0,60)},0.8)
								Library:tween(KeyBind["5f"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)

							end)

							KeyBind["5f"].MouseLeave:Connect(function()
								Library:tween(KeyBind["5f"],{Size = UDim2.new(1,0,0,55)},0.8)
								Library:tween(KeyBind["5f"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)

							end)
							
							KeyBind["62"].Focused:Connect(function()
								--print("ListeningForInput")
								KeyBind["62"].Text = "..."
								local connection
								connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
									if input.KeyCode ~= Enum.KeyCode.Unknown then
										KeyBind["62"].Text = "Keybind:" .. input.KeyCode.Name								
										KeyBind["62"]:ReleaseFocus()
										connection:Disconnect()
										task.wait(0.3)
										KeyBind.CurrentKeyBind = input.KeyCode
									end
								end)
							end)

							uis.InputBegan:Connect(function(input)
								if input.KeyCode == KeyBind.CurrentKeyBind then
									options.Callback(KeyBind.CurrentKeyBind)
								end
							end)
						end
						return KeyBind
						
					end	
					function Tab:DropDown(options)
						options = Library:Validate({
							Text = "KeyBind",
							Options = {"Option 1","Option 2"},
							Callback = function(Options)
							end,
						},options or {})
						
						local DropDown = {
							Items = {
								["id"] = {
									--instance = {},
								},
							},
							isOpened = false,
						}
						
						--logic
						do
							DropDown["42"] = Instance.new("TextButton", Tab["1f"]);
							DropDown["42"]["BorderSizePixel"] = 0;
							DropDown["42"]["AutoButtonColor"] = false;
							DropDown["42"]["TextTransparency"] = 1;
							DropDown["42"]["TextSize"] = 21;
							DropDown["42"]["BackgroundColor3"] = Color3.fromRGB(162, 162, 162);
							DropDown["42"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							DropDown["42"]["AnchorPoint"] = Vector2.new(0.5, 0);
							DropDown["42"]["Size"] = UDim2.new(1, 0, 0, 65);
							DropDown["42"]["BackgroundTransparency"] = 0.6;
							DropDown["42"]["Name"] = [[DropDown]];
							DropDown["42"]["ClipsDescendants"] = true;
							DropDown["42"]["BorderColor3"] = Color3.fromRGB(23, 37, 50);
							DropDown["42"]["Position"] = UDim2.new(0.49259, 0, 0.27239, 0);
							

							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.UICorner
							DropDown["43"] = Instance.new("UICorner", DropDown["42"]);
							DropDown["43"]["CornerRadius"] = UDim.new(0, 15);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.Title
							DropDown["44"] = Instance.new("TextLabel", DropDown["42"]);
							DropDown["44"]["BorderSizePixel"] = 0;
							DropDown["44"]["TextXAlignment"] = Enum.TextXAlignment.Left;
							DropDown["44"]["TextTransparency"] = 0.2;
							DropDown["44"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							DropDown["44"]["TextSize"] = 21;
							DropDown["44"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
							DropDown["44"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
							DropDown["44"]["BackgroundTransparency"] = 1;
							DropDown["44"]["Size"] = UDim2.new(1, -26, 0, 25);
							DropDown["44"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							DropDown["44"]["Text"] = [[Dp]];
							DropDown["44"]["Name"] = [[Title]];


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.Title.UIPadding
							DropDown["45"] = Instance.new("UIPadding", DropDown["44"]);
							DropDown["45"]["PaddingLeft"] = UDim.new(0, 9);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.UIPadding
							DropDown["46"] = Instance.new("UIPadding", DropDown["42"]);
							DropDown["46"]["PaddingTop"] = UDim.new(0, 18);
							DropDown["46"]["PaddingRight"] = UDim.new(0, 8);
							DropDown["46"]["PaddingLeft"] = UDim.new(0, 6);
							DropDown["46"]["PaddingBottom"] = UDim.new(0, 6);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.Icon
							DropDown["47"] = Instance.new("ImageLabel", DropDown["42"]);
							DropDown["47"]["BorderSizePixel"] = 0;
							DropDown["47"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							DropDown["47"]["ScaleType"] = Enum.ScaleType.Fit;
							DropDown["47"]["AnchorPoint"] = Vector2.new(1, 1);
							DropDown["47"]["Image"] = [[rbxassetid://136506872237179]];
							DropDown["47"]["Size"] = UDim2.new(0, 30, 0, 30);
							DropDown["47"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							DropDown["47"]["BackgroundTransparency"] = 1;
							DropDown["47"]["Name"] = [[Icon]];
							DropDown["47"]["Position"] = UDim2.new(1, 0, 0, 30);


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.OptionHolder
							DropDown["48"] = Instance.new("Frame", DropDown["42"]);
							DropDown["48"]["Visible"] = false;
							DropDown["48"]["BorderSizePixel"] = 0;
							DropDown["48"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
							DropDown["48"]["Size"] = UDim2.new(1, 0, 1, -24);
							DropDown["48"]["Position"] = UDim2.new(0, 0, 0, 40);
							DropDown["48"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
							DropDown["48"]["Name"] = [[OptionHolder]];
							DropDown["48"]["BackgroundTransparency"] = 1;


							-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.OptionHolder.UIListLayout
							DropDown["49"] = Instance.new("UIListLayout", DropDown["48"]);
							DropDown["49"]["HorizontalAlignment"] = Enum.HorizontalAlignment.Center;
							DropDown["49"]["Padding"] = UDim.new(0,8);
							DropDown["49"]["SortOrder"] = Enum.SortOrder.LayoutOrder;
						end
						--logic
						do
							function DropDown:Toggle()
								local count = 0
								for i,v in pairs(DropDown["48"]:GetChildren()) do
									if v ~= nil then
										if v:IsA("TextButton") then
											count += 1 
										end	
									end
								end
								
								local size = tonumber((65 + (count * 60) + 10) + 30)
								
								DropDown.isOpened = not DropDown.isOpened
								Library:tween(DropDown["42"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
								
								if DropDown.isOpened == true then
									DropDown["48"]["Visible"] = DropDown.isOpened;
									Library:tween(DropDown["42"],{Size = UDim2.new(DropDown["42"].Size.X.Scale,10,0,size)},1.1,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
									Library:tween(DropDown["47"],{Rotation = 180},0.8)
								elseif DropDown.isOpened == false then
									Library:tween(DropDown["42"],{Size = UDim2.new(DropDown["42"].Size.X.Scale,0,0,65)},0.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out,function()
										DropDown["48"]["Visible"] = DropDown.isOpened;
									end)
									Library:tween(DropDown["47"],{Rotation = 0},0.8)
								end
							end
							
							function DropDown:Add(id)
								DropDown.Items[id] = {
									instance = {},
								}
								DropDown.Items[id].instance["4a"] = Instance.new("TextButton", DropDown["48"]);
								DropDown.Items[id].instance["4a"]["TextWrapped"] = true;
								DropDown.Items[id].instance["4a"]["BorderSizePixel"] = 0;
								DropDown.Items[id].instance["4a"]["AutoButtonColor"] = false;
								DropDown.Items[id].instance["4a"]["TextTransparency"] = 0;
								DropDown.Items[id].instance["4a"]["TextSize"] = 21;
								DropDown.Items[id].instance["4a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
								DropDown.Items[id].instance["4a"]["BackgroundColor3"] = Color3.fromRGB(136, 136, 136);
								DropDown.Items[id].instance["4a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
								DropDown.Items[id].instance["4a"]["Size"] = UDim2.new(0.80, 0, 0, 60);
								DropDown.Items[id].instance["4a"]["Name"] = [[inactiveOption]];
								DropDown.Items[id].instance["4a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
								DropDown.Items[id].instance["4a"]["Text"] = id;
								DropDown.Items[id].instance["4a"].BackgroundTransparency = 0.2

								-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.OptionHolder.inactiveOption.UICorner
								DropDown.Items[id].instance["4b"] = Instance.new("UICorner", DropDown.Items[id].instance["4a"]);
								DropDown.Items[id].instance["4b"].CornerRadius = UDim.new(0,15)

								DropDown.Items[id].instance["4k"] = Instance.new("UIGradient", DropDown.Items[id].instance["4a"])
								DropDown.Items[id].instance["4k"].Color = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(99, 99, 99)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(216, 216, 216))};
								
								-- StarterGui.ScreenGui.Main.Objects.ScrollingFrame.DropDown.OptionHolder.UIPadding
								DropDown.Items[id].instance["4c"] = Instance.new("UIPadding", DropDown.Items[id].instance["4a"]);
								DropDown.Items[id].instance["4c"]["PaddingTop"] = UDim.new(0, 6);
								
								DropDown.Items[id].instance["4a"].MouseButton1Down:Connect(function()
									Library:tween(DropDown.Items[id].instance["4a"],{Size = UDim2.new(0.90, 0, 0, 70)},0.8)
									DropDown:Toggle()	
								end)
								
								DropDown.Items[id].instance["4a"].MouseButton1Up:Connect(function()
									Library:tween(DropDown.Items[id].instance["4a"],{Size = UDim2.new(0.80, 0, 0, 60)},0.8)
									task.wait(0.2)
									options.Callback(id)
									
								end)
								
								DropDown.Items[id].instance["4a"].MouseEnter:Connect(function()
									Library:tween(DropDown.Items[id].instance["4a"],{Size = UDim2.new(0.85, 0, 0, 65)},0.8)
									end)
								DropDown.Items[id].instance["4a"].MouseLeave:Connect(function()
									Library:tween(DropDown.Items[id].instance["4a"],{Size = UDim2.new(0.80, 0, 0, 60)},0.8)
									end)
								
							end
							
							for _, Name in pairs(options.Options) do
								DropDown:Add(Name)
							end
							
							DropDown["42"].MouseButton1Down:Connect(function()
								DropDown:Toggle()
							end)
							
							DropDown["42"].MouseEnter:Connect(function()
								if not DropDown.isOpened then
									Library:tween(DropDown["42"],{Size = UDim2.new(DropDown["42"].Size.X.Scale,5,0,70)},0.8)
									Library:tween(DropDown["42"],{BackgroundColor3 = Color3.fromRGB(150, 150, 150)},0.8)

								end
							end)
							DropDown["42"].MouseLeave:Connect(function()
								if not DropDown.isOpened then
									Library:tween(DropDown["42"],{Size = UDim2.new(1,0,0,65)},0.8)
									Library:tween(DropDown["42"],{BackgroundColor3 = Color3.fromRGB(162, 162, 162)},0.8)
								end
							end)
						end
						return DropDown
					end
				end
			end
			return Tab
		end
		
		function GUI:ToggleVisibility()
			if GUI.Loaded then
				if GUI.Minimised == false and GUI.AnimatingHiding == false then
					GUI.AnimatingHiding = true
					Library:tween(GUI["10"], {Size = UDim2.new(0,0,0,0)},0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
						GUI.AnimatingHiding = false
						GUI.Minimised = true
					end)
					if not GUI.Smallered then
						Library:tween(GUI["2"], {Position = UDim2.new(0.99, 80, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					end
				elseif GUI.Minimised == true and GUI.AnimatingHiding == false then
					GUI.AnimatingHiding = true
					if GUI.Smallered then
						Library:tween(GUI["10"], {Size = UDim2.new(0, 320,0, 45)},0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
							GUI.AnimatingHiding = false
						end)
					else
						Library:tween(GUI["10"], {Size = UDim2.new(0, 500,0, 325)},0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
							GUI.AnimatingHiding = false
						end)
						Library:tween(GUI["2"], {Position = UDim2.new(0.99, 0, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					end
					GUI.Minimised = false
				end
			end
		end
		
		uis.InputBegan:Connect(function(input, gameProcessed)
			if input.KeyCode == GUI.ToggleKeybind and not gameProcessed then
				GUI:ToggleVisibility()
			end
		end)
	end
	
	--logic
	do
		
		function GUI:Loading()
			local loading = {
			}
			do
				loading["2"] = Instance.new("Frame", GUI["1"])
				loading["2"].BorderSizePixel = 0
				loading["2"].BackgroundColor3 = Color3.fromRGB(180, 180, 180)
				loading["2"].AnchorPoint = Vector2.new(0.5, 0.5)
				loading["2"].Size = UDim2.new(0, 0, 0, 200)
				loading["2"].Position = UDim2.new(0.5, 0, 0.5, 0)
				loading["2"].BorderColor3 = Color3.fromRGB(255, 255, 255)
				loading["2"].Name = "Loading"
				loading["2"].BackgroundTransparency = 0.25
				loading["2"].ClipsDescendants = true

				Library:tween(loading["2"], {Size = UDim2.new(0, 400, 0, 200)}, 0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

				loading["3"] = Instance.new("UIGradient", loading["2"])
				loading["3"].Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0.000, Color3.fromRGB(70, 70, 70)),
					ColorSequenceKeypoint.new(1.000, Color3.fromRGB(200, 200, 200))
				}

				loading["5"] = Instance.new("UICorner", loading["2"])
				loading["5"].CornerRadius = UDim.new(0, 25)

				loading["6"] = Instance.new("Frame", loading["2"])
				loading["6"].BorderSizePixel = 0
				loading["6"].BackgroundTransparency = 1
				loading["6"].Size = UDim2.new(1, 0, 0, 50)
				loading["6"].Name = "TopBar"

				loading["7"] = Instance.new("UICorner", loading["6"])
				loading["7"].CornerRadius = UDim.new(0, 25)

				loading["8"] = Instance.new("TextLabel", loading["6"])
				loading["8"].Active = true
				loading["8"].BorderSizePixel = 0
				loading["8"].TextXAlignment = Enum.TextXAlignment.Center
				loading["8"].TextTransparency = 0.1
				loading["8"].BackgroundTransparency = 1
				loading["8"].TextSize = 28
				loading["8"].FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
				loading["8"].TextColor3 = Color3.fromRGB(255, 255, 255)
				loading["8"].Size = UDim2.new(1, 0, 1, 0)
				loading["8"].Text = options.LoadingAnimation.Title
				loading["8"].Position = UDim2.new(0, 0, 0, 0)

				loading["a"] = Instance.new("TextLabel", loading["2"])
				loading["a"].TextWrapped = true
				loading["a"].Active = true
				loading["a"].BorderSizePixel = 0
				loading["a"].TextXAlignment = Enum.TextXAlignment.Center
				loading["a"].TextTransparency = 0.1
				loading["a"].TextYAlignment = Enum.TextYAlignment.Top
				loading["a"].BackgroundTransparency = 1
				loading["a"].TextSize = 22
				loading["a"].FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
				loading["a"].TextColor3 = Color3.fromRGB(255, 255, 255)
				loading["a"].Size = UDim2.new(1, -20, 0, 85)
				loading["a"].Text = options.LoadingAnimation.Text
				loading["a"].AnchorPoint = Vector2.new(0.5,0)
				loading["a"].Position = UDim2.new(0.5,0, 0,50)
				

				loading["c"] = Instance.new("ImageLabel", loading["2"])
				loading["c"].BorderSizePixel = 0
				loading["c"].BackgroundTransparency = 1
				loading["c"].AnchorPoint = Vector2.new(0.5, 0.5)
				loading["c"].Image = "rbxassetid://10723433935"
				loading["c"].Size = UDim2.new(0, 50, 0, 50)
				loading["c"].Position = UDim2.new(0.5, 0, 0.8, 0)
			end
			
			do
				local o = 0
				
				local osThatNeedtoBe = options.LoadingAnimation.Duration / 0.025
				
				while true do
					loading["c"]["Rotation"] += 5
					o += 1
					if o == osThatNeedtoBe then
						break
					end
					task.wait(0.025)
				end
				do
					Library:tween(loading["c"],{ImageTransparency = 1},0.6,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					Library:tween(loading["a"],{TextTransparency = 1},0.6,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					Library:tween(loading["8"],{TextTransparency = 1},0.6,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					
					Library:tween(loading["2"],{Size = UDim2.new(0, 0, 0, 150)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
						loading["2"]:Destroy()
						wait(0.4)
						Library:tween(GUI["10"], {Position = UDim2.new(0.5, 0, 0.5, 0)},0.85,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
						Library:tween(GUI["2"], {Position = UDim2.new(0.99,0, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
							wait(0.2)
							GUI.Loaded = true
						end)
					end)
				end
			end
			return loading
		end
		
		if not GUI.StartWithAnim then
			Library:tween(GUI["10"], {Position = UDim2.new(0.5, 0, 0.5, 0)},0.85,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)
			Library:tween(GUI["2"], {Position = UDim2.new(0.99,0, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
		else
			task.wait(1)
			GUI:Loading()
		end
		--drag
		do
			local topbar = GUI["12"]
			local draggableFrame = GUI["10"]
			local isDragging = false
			local dragStart = nil
			local startPos = nil
			local currentTween = nil
			local inputType = nil -- Track input type (mouse or touch)
			
			local function smoothMove(targetPosition)
				if currentTween then currentTween:Cancel() end
				currentTween = Library:tween(draggableFrame, {Position = targetPosition}, 0.80, Enum.EasingStyle.Exponential)
			end
			
			topbar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					isDragging = true
					dragStart = input.Position
					startPos = draggableFrame.Position
					inputType = input.UserInputType -- Store input type
				end
			end)
			
			uis.InputEnded:Connect(function(input)
				if input.UserInputType == inputType then -- Ensure it matches the started input type
					isDragging = false
				end
			end)
			
			uis.InputChanged:Connect(function(input)
				if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local mouseOffset = input.Position - dragStart
					local targetPosition = UDim2.new(
						startPos.X.Scale, startPos.X.Offset + mouseOffset.X,
						startPos.Y.Scale, startPos.Y.Offset + mouseOffset.Y
					)
					smoothMove(targetPosition)
				end
			end)
			
			
		end
		--topbarButtons
		do
			--Red/close
			GUI["17"].MouseButton1Down:Connect(function()
				local waittime = nil
				if GUI.Smallered then
					waittime = 0.4
				else
					waittime = .7
				end
				
				Library:tween(GUI["10"], {Size = UDim2.new(0, GUI["10"].Size.X.Offset, 0, 10)},waittime,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
					Library:tween(GUI["10"], {Size = UDim2.new(0, 0, 0, 10)},.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out,function()
						GUI["10"].Visible = false
					end)
				end)
				Library:tween(GUI["2"], {Position = UDim2.new(0.99, 80, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
				task.wait(1)
				GUI["1"]:Destroy()
				script:Destroy()
			end)
			--Yellow
			GUI["19"].MouseButton1Down:Connect(function()
				GUI.Smallered = not GUI.Smallered
				if GUI.Smallered then
					Library:tween(GUI["10"], {Size = UDim2.new(0, 320,0, 45)},0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					Library:tween(GUI["2"], {Position = UDim2.new(0.99, 80, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
				else
					Library:tween(GUI["10"], {Size = UDim2.new(0, 500,0, 325)},0.7,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
					Library:tween(GUI["2"], {Position = UDim2.new(0.99, 0, 0.5, 0)},0.8,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
				end
			end)
			--Green
			GUI["1b"].MouseButton1Down:Connect(function()
				GUI:ToggleVisibility()
			end)
		end
		
		function GUI:Notification(options)
			options = Library:Validate({
				Title = "",
				Text = "",
			},options or {})

			local Notification = {}

			do
				Notification["9a"] = Instance.new("Frame", GUI["1"]);
				Notification["9a"]["BorderSizePixel"] = 0;
				Notification["9a"]["BackgroundColor3"] = Color3.fromRGB(189, 200, 223);
				Notification["9a"]["AnchorPoint"] = Vector2.new(0.5, 1);
				Notification["9a"]["Size"] = UDim2.new(0, 291, 0, 83);
				Notification["9a"]["Position"] = UDim2.new(0.5, 0, 1, Notification["9a"]["Size"].Y.Offset + 10);
				Notification["9a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
				Notification["9a"]["Name"] = [[Notification]];
				Notification["9a"]["BackgroundTransparency"] = 0.3;

				-- StarterGui.ScreenGui.Notification.UiAll
				Notification["9b"] = Instance.new("Frame", Notification["9a"]);
				Notification["9b"]["BorderSizePixel"] = 0;
				Notification["9b"]["Size"] = UDim2.new(1, 0, 1, 0);
				Notification["9b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
				Notification["9b"]["Name"] = [[UiAll]];
				Notification["9b"]["BackgroundTransparency"] = 1;

				-- StarterGui.ScreenGui.Notification.UiAll.Main Text
				Notification["9c"] = Instance.new("TextLabel", Notification["9b"]);
				Notification["9c"]["TextWrapped"] = true;
				Notification["9c"]["Active"] = true;
				Notification["9c"]["BorderSizePixel"] = 0;
				Notification["9c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
				Notification["9c"]["TextYAlignment"] = Enum.TextYAlignment.Top;
				Notification["9c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
				Notification["9c"]["TextSize"] = 20;
				Notification["9c"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
				Notification["9c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
				Notification["9c"]["BackgroundTransparency"] = 1;
				Notification["9c"]["AnchorPoint"] = Vector2.new(1, 1);
				Notification["9c"]["Size"] = UDim2.new(1, 0, 0.99, -25);
				Notification["9c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
				Notification["9c"]["Text"] = options.Text;
				Notification["9c"]["Selectable"] = true;
				Notification["9c"]["Name"] = [[Main Text]];
				Notification["9c"]["Position"] = UDim2.new(1, 0, 1.07, 2);

				-- StarterGui.ScreenGui.Notification.UiAll.Main Text.UICorner
				Notification["9d"] = Instance.new("UICorner", Notification["9c"]);
				Notification["9d"]["CornerRadius"] = UDim.new(0.1, 8);

				-- StarterGui.ScreenGui.Notification.UiAll.UIPadding
				Notification["9e"] = Instance.new("UIPadding", Notification["9b"]);
				Notification["9e"]["PaddingTop"] = UDim.new(0, 3);
				Notification["9e"]["PaddingRight"] = UDim.new(0, 1);
				Notification["9e"]["PaddingLeft"] = UDim.new(0, 1);
				Notification["9e"]["PaddingBottom"] = UDim.new(0, 5);

				-- StarterGui.ScreenGui.Notification.UiAll.Title
				Notification["9f"] = Instance.new("TextLabel", Notification["9b"]);
				Notification["9f"]["TextWrapped"] = true;
				Notification["9f"]["Active"] = true;
				Notification["9f"]["BorderSizePixel"] = 0;
				Notification["9f"]["TextYAlignment"] = Enum.TextYAlignment.Bottom;
				Notification["9f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
				Notification["9f"]["TextSize"] = 30;
				Notification["9f"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
				Notification["9f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
				Notification["9f"]["BackgroundTransparency"] = 1;
				Notification["9f"]["AnchorPoint"] = Vector2.new(1, 0);
				Notification["9f"]["Size"] = UDim2.new(1, 0, 0.1, 20);
				Notification["9f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
				Notification["9f"]["Text"] = options.Title;
				Notification["9f"]["Selectable"] = true;
				Notification["9f"]["Name"] = [[Title]];
				Notification["9f"]["Position"] = UDim2.new(1, 0, 0, 0);

				-- StarterGui.ScreenGui.Notification.UiAll.Title.UIPadding
				Notification["a0"] = Instance.new("UIPadding", Notification["9f"]);
				Notification["a0"]["PaddingTop"] = UDim.new(0, 30);
				Notification["a0"]["PaddingRight"] = UDim.new(0, 10);
				Notification["a0"]["PaddingLeft"] = UDim.new(0, 10);
				Notification["a0"]["PaddingBottom"] = UDim.new(0, 10);

				-- StarterGui.ScreenGui.Notification.UiAll.Title.UICorner
				Notification["a1"] = Instance.new("UICorner", Notification["9f"]);
				Notification["a1"]["CornerRadius"] = UDim.new(0.1, 8);

				-- StarterGui.ScreenGui.Notification.UiAll.Icon
				Notification["a2"] = Instance.new("ImageLabel", Notification["9b"]);
				Notification["a2"]["AnchorPoint"] = Vector2.new(1, 0);
				Notification["a2"]["Image"] = [[rbxassetid://137847593094125]];
				Notification["a2"]["Size"] = UDim2.new(0, 25, 0, 25);
				Notification["a2"]["BackgroundTransparency"] = 1;
				Notification["a2"]["Name"] = [[Icon]];
				Notification["a2"]["Position"] = UDim2.new(1, 0, 0, 5);

				-- StarterGui.ScreenGui.Notification.UICorner
				Notification["a3"] = Instance.new("UICorner", Notification["9a"]);
				Notification["a3"]["CornerRadius"] = UDim.new(0.1, 8);

				-- StarterGui.ScreenGui.Notification.UIPadding
				Notification["a4"] = Instance.new("UIPadding", Notification["9a"]);
				Notification["a4"]["PaddingTop"] = UDim.new(0, 4);
				Notification["a4"]["PaddingRight"] = UDim.new(0, 15);
				Notification["a4"]["PaddingLeft"] = UDim.new(0, 15);
				Notification["a4"]["PaddingBottom"] = UDim.new(0, 4);

				-- StarterGui.ScreenGui.Notification.UIStroke
				Notification["a5"] = Instance.new("UIStroke", Notification["9a"]);
				Notification["a5"]["Transparency"] = 0.8;
				Notification["a5"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
				Notification["a5"]["Color"] = Color3.fromRGB(201, 201, 201);

				-- StarterGui.ScreenGui.Notification.UIGradient
				Notification["a6"] = Instance.new("UIGradient", Notification["9a"]);
				Notification["a6"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(70, 70, 70)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(191, 191, 191))};

				Library:tween(Notification["9a"], {Position = UDim2.new(0.5, 0, 1, -10)},0.8)
			end
			local function Bb()
				task.wait(4)
				Library:tween(Notification["9a"], {Position = UDim2.new(0.5, 0, 1, Notification["9a"]["Size"].Y.Offset + 10);},0.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out,function()
					Notification["9a"]:Destroy()
				end)
			end
			Bb()

			return Notification	
		end
	end
	
	return GUI
end


return Library

-- Make draggable UI
makeDraggable(GUI["10"], GUI["12"]) -- Main drag via TopBar
makeDraggable(Settings["6f"], Settings["8b"]) -- Settings drag via TopBar
