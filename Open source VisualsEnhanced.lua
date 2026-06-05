--!! CHUNK 1: Core Initialization, State Management & Engine Configurations !--
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Safely acquire or append standard engine post-processing instances
local function getOrCreate(className, name)
	local obj = Lighting:FindFirstChild(name)
	if not obj then
		obj = Instance.new(className)
		obj.Name = name
		obj.Parent = Lighting
	end
	return obj
end

local sunRays = getOrCreate("SunRaysEffect", "ShaderSunRays")
local bloom = getOrCreate("BloomEffect", "ShaderBloom")
local colorCorrection = getOrCreate("ColorCorrectionEffect", "ShaderColor")

-- Force graphics rendering engine properties
Lighting.ShadowMapEnabled = true
Lighting.EnvironmentDiffuseScale = 1
Lighting.EnvironmentSpecularScale = 1

-- Master Theme Configuration Table (Hex Defaults mapped into active Color3 values)
local Theme = {
	Background = Color3.fromRGB(24, 24, 28),
	Sidebar = Color3.fromRGB(18, 18, 22),
	ToggleOn = Color3.fromRGB(39, 174, 96),
	ToggleOff = Color3.fromRGB(192, 57, 43),
	SliderFill = Color3.fromRGB(0, 210, 255),
	Border = Color3.fromRGB(60, 60, 70)
}

-- Current active shader adjustments data tracking state
local settingsState = {
	Rain = {Enabled = false, Intensity = 0.5},
	SunRays = {Enabled = true, Intensity = 0.35},
	Shadows = {Enabled = true, Quality = 1.0}
}

-- UI Object Arrays for real-time appearance syncing
local trackedToggles = {}
local trackedSliders = {}
local uiVisible = true

--!! CHUNK 2: Window Assembly, Styled Header & Sidebar Layout !--
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "VisualsEnhancedPanel"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0.2, 0, 0.48, 0)
mainFrame.Position = UDim2.new(0.4, 0, 0.26, 0)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = URadius.new(0, 8)
uiCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Theme.Border
uiStroke.Thickness = 1
uiStroke.Parent = mainFrame

-- Top header brand bar layout mapping
local headerBar = Instance.new("Frame")
headerBar.Size = UDim2.new(1, 0, 0.15, 0)
headerBar.BackgroundTransparency = 1
headerBar.Parent = mainFrame

-- Glowing branding text style matching LightLUA
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.new(0.04, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "VisualsEnhanced"
titleLabel.TextColor3 = Theme.SliderFill
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerBar

local titleGlow = Instance.new("TextLabel")
titleGlow.Size = UDim2.new(1, 0, 1, 0)
titleGlow.BackgroundTransparency = 1
titleGlow.Text = titleLabel.Text
titleGlow.TextColor3 = Color3.fromRGB(0, 150, 255)
titleGlow.Font = titleLabel.Font
titleGlow.TextSize = titleLabel.TextSize
titleGlow.TextXAlignment = titleLabel.TextXAlignment
titleGlow.TextTransparency = 0.5
titleGlow.Position = UDim2.new(0, 1, 0, 1)
titleGlow.ZIndex = titleLabel.ZIndex - 1
titleGlow.Parent = titleLabel

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.12, 0, 0.8, 0)
closeBtn.Position = UDim2.new(0.85, 0, 0.1, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = headerBar

closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Sidebar Construction
local sideBar = Instance.new("Frame")
sideBar.Size = UDim2.new(0.25, 0, 0.85, 0)
sideBar.Position = UDim2.new(0, 0, 0.15, 0)
sideBar.BackgroundColor3 = Theme.Sidebar
sideBar.BorderSizePixel = 0
sideBar.Parent = mainFrame

local sideCorner = Instance.new("UICorner")
sideCorner.CornerRadius = URadius.new(0, 8)
sideCorner.Parent = sideBar

local coverBox = Instance.new("Frame")
coverBox.Size = UDim2.new(0.2, 0, 0.2, 0)
coverBox.Position = UDim2.new(0.8, 0, 0, 0)
coverBox.BackgroundColor3 = Theme.Sidebar
coverBox.BorderSizePixel = 0
coverBox.Parent = sideBar

local sideLayout = Instance.new("UIListLayout")
sideLayout.Padding = UDim.new(0, 4)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sideBar

--!! CHUNK 3: Multi-Page View Container, Switcher Transitions & Credits Text !--
local contentContainer = Instance.new("Frame")
contentContainer.Size = UDim2.new(0.75, 0, 0.85, 0)
contentContainer.Position = UDim2.new(0.25, 0, 0.15, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Parent = mainFrame

local shadersPage = Instance.new("Frame")
shadersPage.Size = UDim2.new(1, 0, 1, 0)
shadersPage.BackgroundTransparency = 1
shadersPage.Parent = contentContainer

local settingsPage = Instance.new("Frame")
settingsPage.Size = UDim2.new(1, 0, 1, 0)
settingsPage.BackgroundTransparency = 1
settingsPage.Visible = false
settingsPage.Parent = contentContainer

local creditsPage = Instance.new("Frame")
creditsPage.Size = UDim2.new(1, 0, 1, 0)
creditsPage.BackgroundTransparency = 1
creditsPage.Visible = false
creditsPage.Parent = contentContainer

local shadersLayout = Instance.new("UIListLayout")
shadersLayout.Padding = UDim.new(0, 6)
shadersLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
shadersLayout.Parent = shadersPage

local settingsLayout = Instance.new("UIListLayout")
settingsLayout.Padding = UDim.new(0, 6)
settingsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
settingsLayout.Parent = settingsPage

local currentActivePage = shadersPage

local function switchPageWithTransition(targetPage)
	if currentActivePage == targetPage then return end
	local fadeOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeInInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	
	local hideTween = TweenService:Create(contentContainer, fadeOutInfo, {Size = UDim2.new(0.75, 0, 0.8, 0)})
	hideTween:Play()
	
	task.delay(0.15, function()
		currentActivePage.Visible = false
		targetPage.Visible = true
		currentActivePage = targetPage
		local showTween = TweenService:Create(contentContainer, fadeInInfo, {Size = UDim2.new(0.75, 0, 0.85, 0)})
		showTween:Play()
	end)
end

local function createSideButton(text, order, targetPage)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.9, 0, 0.2, 0)
	btn.BackgroundTransparency = 1
	btn.Text = text
	btn.TextColor3 = (order == 1) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(130, 130, 140)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 10
	btn.LayoutOrder = order
	btn.Parent = sideBar

	btn.MouseButton1Click:Connect(function()
		for _, sideChild in ipairs(sideBar:GetChildren()) do
			if sideChild:IsA("TextButton") then 
				TweenService:Create(sideChild, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(130, 130, 140)}):Play() 
			end
		end
		TweenService:Create(btn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
		switchPageWithTransition(targetPage)
	end)
end

createSideButton("SHADERS", 1, shadersPage)
createSideButton("SETTINGS", 2, settingsPage)
createSideButton("CREDITS", 3, creditsPage)

-- Credits Content text block matching precise trust policies
local creditsText = Instance.new("TextLabel")
creditsText.Size = UDim2.new(0.9, 0, 0.9, 0)
creditsText.Position = UDim2.new(0.05, 0, 0.05, 0)
creditsText.BackgroundTransparency = 1
creditsText.Text = "Developed by the team at PhoenixCode, dedicated to bringing you safe, reliable and free scripts to enhance your gameplay experience. Go to https://phoenixcode.com for all of our scripts and products!\n\nWe will never ask for credit card/bank details or use deceptive methods. We will never scam you and are 100% safe, as it says on Totalvirus."
creditsText.TextColor3 = Color3.fromRGB(200, 200, 215)
creditsText.Font = Enum.Font.Gotham
creditsText.TextSize = 10
creditsText.TextWrapped = true
creditsText.TextYAlignment = Enum.TextYAlignment.Top
creditsText.Parent = creditsPage

local dropletContainer = Instance.new("Frame")
dropletContainer.Size = UDim2.new(1, 0, 1, 0)
dropletContainer.BackgroundTransparency = 1
dropletContainer.Parent = screenGui

--!! CHUNK 4: Toggles, Sliders, Hex Parsing, Keybind Minimize & Rain Loops !--
local function updateInterfaceColors()
	mainFrame.BackgroundColor3 = Theme.Background
	sideBar.BackgroundColor3 = Theme.Sidebar
	coverBox.BackgroundColor3 = Theme.Sidebar
	uiStroke.Color = Theme.Border
	titleLabel.TextColor3 = Theme.SliderFill
	for _, item in ipairs(trackedToggles) do
		item.Button.BackgroundColor3 = item.Target.Enabled and Theme.ToggleOn or Theme.ToggleOff
	end
	for _, fill in ipairs(trackedSliders) do fill.BackgroundColor3 = Theme.SliderFill end
end

local function createControlRow(name, layoutOrder, defaultValue, onToggle, onSliderChange)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.9, 0, 0.26, 0)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = shadersPage

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0.5, 0, 0.45, 0)
	toggle.BackgroundColor3 = defaultValue.Enabled and Theme.ToggleOn or Theme.ToggleOff
	toggle.Text = name .. ": " .. (defaultValue.Enabled and "ON" or "OFF")
	toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 10
	toggle.Parent = row
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = URadius.new(0, 4)
	btnCorner.Parent = toggle
	table.insert(trackedToggles, {Button = toggle, Target = defaultValue})

	local sliderTrack = Instance.new("Frame")
	sliderTrack.Size = UDim2.new(1, 0, 0.15, 0)
	sliderTrack.Position = UDim2.new(0, 0, 0.65, 0)
	sliderTrack.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
	sliderTrack.BorderSizePixel = 0
	sliderTrack.Parent = row

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(defaultValue.Intensity or defaultValue.Quality, 0, 1, 0)
	sliderFill.BackgroundColor3 = Theme.SliderFill
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderTrack
	table.insert(trackedSliders, sliderFill)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0.08, 0, 2.5, 0)
	knob.Position = UDim2.new((defaultValue.Intensity or defaultValue.Quality) - 0.04, 0, -0.75, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.Text = ""
	knob.Parent = sliderTrack
	
	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = URadius.new(0, 4)
	knobCorner.Parent = knob

	toggle.MouseButton1Click:Connect(function()
		defaultValue.Enabled = not defaultValue.Enabled
		local targetColor = defaultValue.Enabled and Theme.ToggleOn or Theme.ToggleOff
		TweenService:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
		toggle.Text = name .. ": " .. (defaultValue.Enabled and "ON" or "OFF")
		onToggle(defaultValue.Enabled)
	end)

	local dragging = false
	knob.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

	RunService.Heartbeat:Connect(function()
		if dragging then
			local mousePos = UserInputService:GetMouseLocation()
			local relativeX = mousePos.X - sliderTrack.AbsolutePosition.X
			local percentage = math.clamp(relativeX / sliderTrack.AbsoluteSize.X, 0, 1)
			knob.Position = UDim2.new(percentage - 0.04, 0, -0.75, 0)
			sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
			if defaultValue.Intensity ~= nil then defaultValue.Intensity = percentage end
			if defaultValue.Quality ~= nil then defaultValue.Quality = percentage end
			onSliderChange(percentage)
		end
	end)
end

createControlRow("Rain Effects", 1, settingsState.Rain, function(e) if not e then dropletContainer:ClearAllChildren() end end, function(v) if settingsState.Rain.Enabled then colorCorrection.Saturation = -v colorCorrection.Contrast = 0.15 + (v * 0.1) end end)
createControlRow("Sun Rays", 2, settingsState.SunRays, function(e) sunRays.Intensity = e and settingsState.SunRays.Intensity or 0 end, function(v) if settingsState.SunRays.Enabled then sunRays.Intensity = v end end)
createControlRow("Shadow Eng", 3, settingsState.Shadows, function(e) Lighting.ShadowMapEnabled = e end, function(v) Lighting.EnvironmentDiffuseScale = v Lighting.EnvironmentSpecularScale = v end)

local function createColorInput(labelText, layoutOrder, defaultHex, onUpdate)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(0.95, 0, 0.18, 0)
	row.BackgroundTransparency = 1
	row.LayoutOrder = layoutOrder
	row.Parent = settingsPage

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 9
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local textBox = Instance.new("TextBox")
	textBox.Size = UDim2.new(0.45, 0, 0.7, 0)
	textBox.Position = UDim2.new(0.5, 0, 0.15, 0)
	textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	textBox.Text = defaultHex
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.Font = Enum.Font.Code
	textBox.TextSize = 9
	textBox.Parent = row
	
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = URadius.new(0, 4)
	boxCorner.Parent = textBox

	textBox.FocusLost:Connect(function()
		local success, result = pcall(function() return Color3.fromHex(textBox.Text) end)
		if success and result then onUpdate(result) updateInterfaceColors() else textBox.Text = "ERR" end
	end)
end

createColorInput("UI BG Hex:", 1, "#18181C", function(c) Theme.Background = c end)
createColorInput("Sidebar Hex:", 2, "#121216", function(c) Theme.Sidebar = c end)
createColorInput("Toggle ON Hex:", 3, "#27AE60", function(c) Theme.ToggleOn = c end)
createColorInput("Toggle OFF Hex:", 4, "#C0392B", function(c) Theme.ToggleOff = c end)
createColorInput("Slider Hex:", 5, "#00D2FF", function(c) Theme.SliderFill = c end)

-- Keybind hide listener thread with smooth slide minimization transition
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Y then 
		uiVisible = not uiVisible 
		local targetSize = uiVisible and UDim2.new(0.2, 0, 0.48, 0) or UDim2.new(0.2, 0, 0, 0)
		local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, uiVisible and Enum.EasingDirection.Out or Enum.EasingDirection.In)
		if uiVisible then mainFrame.Visible = true end
		local minimizeTween = TweenService:Create(mainFrame, tweenInfo, {Size = targetSize})
		minimizeTween:Play()
		minimizeTween.Completed:Connect(function() if not uiVisible then mainFrame.Visible = false end end)
	end
end)

-- Screen rain droplet loop
local camera = workspace.CurrentCamera
RunService.RenderStepped:Connect(function()
	if settingsState.Rain.Enabled and uiVisible then
		if camera.CFrame.LookVector.Y > 0.1 and math.random() < (0.03 * (settingsState.Rain.Intensity * 3)) then
			local droplet = Instance.new("ImageLabel")
			droplet.Image = "rbxassetid://10849912111" 
			droplet.BackgroundTransparency = 1
			droplet.ImageTransparency = 0.4
			droplet.Size = UDim2.new(0, math.random(15, 35), 0, math.random(15, 35))
			droplet.Position = UDim2.new(math.random(), 0, math.random() * 0.5, 0)
			droplet.Parent = dropletContainer
			local slideTime = math.random(15, 30) / 10
			droplet:TweenPosition(UDim2.new(droplet.Position.X.Scale, 0, droplet.Position.Y.Scale + 0.3, 0), "Out", "Quad", slideTime, true)
			task.delay(slideTime * 0.7, function()
				local fade = TweenService:Create(droplet, TweenInfo.new(slideTime * 0.3), {ImageTransparency = 1})
				fade:Play()
				fade.Completed:Connect(function() droplet:Destroy() end)
			end)
		end
	end
end)

print("[PhoenixCode]: VisualsEnhanced environment core successfully generated.")
