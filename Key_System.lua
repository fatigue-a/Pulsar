repeat task.wait() until game and game:IsLoaded()

local CONFIG = {
    Name = "Pulsar Hub",
    Version = "v2.0.0",
    BaseURL = "https://raw.githubusercontent.com/fatigue-a/Pulsar/refs/heads/main",
    KeyCoreFile = "return/k_core.lua",
    LoaderFile = "Pulsar_Loader.lua",
    KeyFileName = "PulsarKey.txt",
    Background = Color3.fromRGB(15, 15, 18),
    Surface = Color3.fromRGB(22, 22, 26),
    Border = Color3.fromRGB(45, 45, 55),
    BorderActive = Color3.fromRGB(75, 130, 195),
    Text = Color3.fromRGB(200, 200, 200),
    TextDim = Color3.fromRGB(100, 100, 110),
    Accent = Color3.fromRGB(95, 165, 230),
    Success = Color3.fromRGB(85, 185, 120),
    Error = Color3.fromRGB(210, 85, 85),
    Warning = Color3.fromRGB(220, 175, 75),
}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function notify(title, msg, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "Pulsar",
            Text = msg or "",
            Duration = duration or 3
        })
    end)
end

local function getSavedKey()
    local ok, data = pcall(function()
        if readfile and isfile and isfile(CONFIG.KeyFileName) then
            return readfile(CONFIG.KeyFileName)
        end
    end)
    return ok and data and data ~= "" and data or nil
end

local function saveKey(key)
    pcall(function()
        if writefile then writefile(CONFIG.KeyFileName, key) end
    end)
end

local function deleteKey()
    pcall(function()
        if delfile and isfile and isfile(CONFIG.KeyFileName) then delfile(CONFIG.KeyFileName) end
    end)
end

notify("Pulsar", "Loading key system...", 2)

local coreOk, coreSrc = pcall(function()
    return game:HttpGet(CONFIG.BaseURL .. "/" .. CONFIG.KeyCoreFile)
end)

if not coreOk or not coreSrc or coreSrc == "" then
    error("[Pulsar] Failed to load key core: " .. tostring(coreSrc))
end

local newKeySystem = assert(loadstring(coreSrc), "[Pulsar] Failed to compile key core")()

local lastApiMessage = nil

local keyApi = newKeySystem({
    useNonce = true,
    onMessage = function(msg)
        lastApiMessage = msg
        notify("Key System", msg, 3)
    end,
})

local function loadHub()
    notify("Pulsar", "Key verified! Loading hub...", 2)
    task.wait(0.5)
    local hubOk, hubSrc = pcall(function()
        return game:HttpGet(CONFIG.BaseURL .. "/" .. CONFIG.LoaderFile)
    end)
    if not hubOk or not hubSrc or hubSrc == "" then
        error("[Pulsar] Failed to load hub: " .. tostring(hubSrc))
    end
    local hubFn, hubErr = loadstring(hubSrc)
    if not hubFn then
        error("[Pulsar] Failed to compile hub: " .. tostring(hubErr))
    end
    getgenv().__PULSAR_KEY_VERIFIED = true
    hubFn()
end

local savedKey = getSavedKey()
if savedKey then
    notify("Pulsar", "Checking saved key...", 2)
    local valid = keyApi.verifyKey(savedKey)
    if valid then
        loadHub()
        return
    else
        notify("Pulsar", "Saved key expired or invalid", 2)
        deleteKey()
    end
end

local UserInputService = game:GetService("UserInputService")
local guiParent = game:GetService("CoreGui")
pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

local isMobile = UserInputService.TouchEnabled
local screenSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
local isSmallScreen = screenSize.X < 1024 or screenSize.Y < 768

local scale = (isMobile or isSmallScreen) and 0.85 or 1
local baseWidth = math.floor(480 * scale)
local baseHeight = math.floor(340 * scale)
local titleBarHeight = math.floor(28 * (isMobile and 1.2 or 1))
local controlSize = isMobile and 16 or 12
local fontSize = math.floor(12 * scale)
local smallFontSize = math.floor(11 * scale)

local screen = Instance.new("ScreenGui")
screen.Name = "PulsarConsole_" .. tostring(math.random(1000, 9999))
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 999

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(screen)
    end
end)

screen.Parent = guiParent

-- Dim overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Parent = screen

TweenService:Create(overlay, TweenInfo.new(0.3), {BackgroundTransparency = 0.5}):Play()

-- Main console window
local console = Instance.new("Frame")
console.Name = "Console"
console.Size = UDim2.new(0, baseWidth, 0, baseHeight)
console.Position = UDim2.new(0.5, -baseWidth/2, 0.5, -baseHeight/2)
console.BackgroundColor3 = CONFIG.Background
console.BorderSizePixel = 0
console.ClipsDescendants = true
console.Active = true  -- Required for touch dragging
console.Parent = screen

-- Minimized state tracking
local isMinimized = false
local expandedSize = UDim2.new(0, baseWidth, 0, baseHeight)

local consoleCorner = Instance.new("UICorner")
consoleCorner.CornerRadius = UDim.new(0, 4)
consoleCorner.Parent = console

local consoleBorder = Instance.new("UIStroke")
consoleBorder.Color = CONFIG.Border
consoleBorder.Thickness = isMobile and 2 or 1
consoleBorder.Parent = console

-- Intro animation (non-blocking)
console.Size = UDim2.new(0, baseWidth, 0, 0)
console.BackgroundTransparency = 1
TweenService:Create(console, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, baseWidth, 0, baseHeight),
    BackgroundTransparency = 0
}):Play()
-- Don't wait for animation, continue building UI

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, titleBarHeight)
titleBar.BackgroundColor3 = CONFIG.Surface
titleBar.BorderSizePixel = 0
titleBar.Active = true  -- For touch
titleBar.Parent = console

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 4)
titleCorner.Parent = titleBar

-- Fix bottom corners of title bar
local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 8)
titleFix.Position = UDim2.new(0, 0, 1, -8)
titleFix.BackgroundColor3 = CONFIG.Surface
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

-- Title bar bottom border
local titleBorder = Instance.new("Frame")
titleBorder.Size = UDim2.new(1, 0, 0, 1)
titleBorder.Position = UDim2.new(0, 0, 1, 0)
titleBorder.BackgroundColor3 = CONFIG.Border
titleBorder.BorderSizePixel = 0
titleBorder.Parent = titleBar

-- Window controls (functional) - larger for mobile
local controls = Instance.new("Frame")
controls.Size = UDim2.new(0, controlSize * 3 + 16, 0, controlSize)
controls.Position = UDim2.new(0, 10, 0.5, 0)
controls.AnchorPoint = Vector2.new(0, 0.5)
controls.BackgroundTransparency = 1
controls.Parent = titleBar

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.Padding = UDim.new(0, isMobile and 10 or 8)
controlsLayout.Parent = controls

local controlColors = {
    {Color3.fromRGB(255, 95, 85), "close"},
    {Color3.fromRGB(255, 190, 45), "minimize"},
    {Color3.fromRGB(45, 200, 70), "maximize"}
}

local closeBtn, minimizeBtn, maximizeBtn

for i, data in ipairs(controlColors) do
    local color, action = data[1], data[2]
    
    local dot = Instance.new("TextButton")
    dot.Size = UDim2.new(0, controlSize, 0, controlSize)
    dot.BackgroundColor3 = color
    dot.BackgroundTransparency = 0.3
    dot.BorderSizePixel = 0
    dot.Text = ""
    dot.AutoButtonColor = false
    dot.Parent = controls
    
    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = dot
    
    -- Hover/Touch effect
    dot.MouseEnter:Connect(function()
        TweenService:Create(dot, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
    end)
    dot.MouseLeave:Connect(function()
        TweenService:Create(dot, TweenInfo.new(0.15), {BackgroundTransparency = 0.3}):Play()
    end)
    
    -- Touch feedback for mobile
    if isMobile then
        dot.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0, Size = UDim2.new(0, controlSize * 1.2, 0, controlSize * 1.2)}):Play()
            end
        end)
        dot.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                TweenService:Create(dot, TweenInfo.new(0.1), {BackgroundTransparency = 0.3, Size = UDim2.new(0, controlSize, 0, controlSize)}):Play()
            end
        end)
    end
    
    if action == "close" then
        closeBtn = dot
    elseif action == "minimize" then
        minimizeBtn = dot
    else
        maximizeBtn = dot
    end
end

-- Dragging functionality
local dragging = false
local dragStart = nil
local startPos = nil

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = console.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        console.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Close button functionality
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(console, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, baseWidth, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.25)
    screen:Destroy()
end)

-- Title text
local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -(controlSize * 3 + 90), 1, 0)
titleText.Position = UDim2.new(0, controlSize * 3 + 30, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = isMobile and "pulsar://key" or "pulsar://key-system"
titleText.TextColor3 = CONFIG.TextDim
titleText.Font = Enum.Font.Code
titleText.TextSize = math.floor(13 * scale)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.TextScaled = isMobile
titleText.Parent = titleBar

if isMobile then
    local titleConstraint = Instance.new("UITextSizeConstraint")
    titleConstraint.MaxTextSize = math.floor(13 * scale)
    titleConstraint.MinTextSize = 9
    titleConstraint.Parent = titleText
end

-- Version label
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60 * scale, 1, 0)
versionLabel.Position = UDim2.new(1, -65 * scale, 0, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = CONFIG.Version
versionLabel.TextColor3 = CONFIG.Accent
versionLabel.Font = Enum.Font.Code
versionLabel.TextSize = smallFontSize
versionLabel.Parent = titleBar

-- Content area
local contentPadding = math.floor(10 * scale)
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -contentPadding * 2, 1, -(titleBarHeight + 10))
content.Position = UDim2.new(0, contentPadding, 0, titleBarHeight + 5)
content.BackgroundTransparency = 1
content.Parent = console

-- Minimize button functionality (must be after content is created)
minimizeBtn.MouseButton1Click:Connect(function()
    if isMinimized then
        -- Restore
        isMinimized = false
        content.Visible = true
        TweenService:Create(console, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = expandedSize
        }):Play()
        TweenService:Create(titleBorder, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    else
        -- Minimize to title bar only
        isMinimized = true
        TweenService:Create(console, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, baseWidth, 0, titleBarHeight)
        }):Play()
        TweenService:Create(titleBorder, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
        task.delay(0.2, function()
            if isMinimized then
                content.Visible = false
            end
        end)
    end
end)

-- Double-click/tap title bar to minimize/restore
local lastClickTime = 0
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local currentTime = tick()
        if currentTime - lastClickTime < 0.3 then
            minimizeBtn.MouseButton1Click:Fire()
        end
        lastClickTime = currentTime
    end
end)

-- ASCII Header (simplified for mobile)
local asciiHeader = Instance.new("TextLabel")
asciiHeader.Size = UDim2.new(1, 0, 0, isMobile and 35 or 45)
asciiHeader.BackgroundTransparency = 1
if isMobile then
    asciiHeader.Text = "⚡ PULSAR HUB - Key Authentication"
else
    asciiHeader.Text = [[
 ╔═══════════════════════════════════════════════════╗
 ║     ⚡ PULSAR HUB  -  Key Authentication          ║
 ╚═══════════════════════════════════════════════════╝]]
end
asciiHeader.TextColor3 = CONFIG.Accent
asciiHeader.Font = Enum.Font.Code
asciiHeader.TextSize = smallFontSize
asciiHeader.TextYAlignment = Enum.TextYAlignment.Top
asciiHeader.TextScaled = isMobile
asciiHeader.Parent = content

if isMobile then
    local headerConstraint = Instance.new("UITextSizeConstraint")
    headerConstraint.MaxTextSize = 14
    headerConstraint.MinTextSize = 10
    headerConstraint.Parent = asciiHeader
end

-- Console output area
local outputHeight = isMobile and 70 or 90
local outputFrame = Instance.new("Frame")
outputFrame.Name = "OutputFrame"
outputFrame.Size = UDim2.new(1, 0, 0, outputHeight * scale)
outputFrame.Position = UDim2.new(0, 0, 0, isMobile and 38 or 50)
outputFrame.BackgroundColor3 = CONFIG.Surface
outputFrame.BorderSizePixel = 0
outputFrame.Parent = content

local outputCorner = Instance.new("UICorner")
outputCorner.CornerRadius = UDim.new(0, 3)
outputCorner.Parent = outputFrame

local outputBorder = Instance.new("UIStroke")
outputBorder.Color = CONFIG.Border
outputBorder.Thickness = isMobile and 2 or 1
outputBorder.Parent = outputFrame

local outputScroll = Instance.new("ScrollingFrame")
outputScroll.Size = UDim2.new(1, -8, 1, -8)
outputScroll.Position = UDim2.new(0, 4, 0, 4)
outputScroll.BackgroundTransparency = 1
outputScroll.ScrollBarThickness = isMobile and 6 or 3  -- Thicker for touch
outputScroll.ScrollBarImageColor3 = CONFIG.Border
outputScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
outputScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
outputScroll.ScrollingEnabled = true
outputScroll.Parent = outputFrame

local outputLayout = Instance.new("UIListLayout")
outputLayout.Padding = UDim.new(0, 2)
outputLayout.Parent = outputScroll

-- Console log entries storage
local logEntries = {}
local logFontSize = math.floor(11 * scale)

local function addLog(text, color)
    local entry = Instance.new("TextLabel")
    entry.Size = UDim2.new(1, 0, 0, math.floor(14 * scale))
    entry.BackgroundTransparency = 1
    entry.Text = (isMobile and "" or getTimestamp() .. " ") .. text
    entry.TextColor3 = color or CONFIG.Text
    entry.Font = Enum.Font.Code
    entry.TextSize = logFontSize
    entry.TextXAlignment = Enum.TextXAlignment.Left
    entry.TextWrapped = true
    entry.AutomaticSize = Enum.AutomaticSize.Y
    entry.Parent = outputScroll
    
    table.insert(logEntries, entry)
    
    -- Auto scroll to bottom
    task.defer(function()
        outputScroll.CanvasPosition = Vector2.new(0, outputScroll.AbsoluteCanvasSize.Y)
    end)
    
    -- Limit log entries
    if #logEntries > 50 then
        logEntries[1]:Destroy()
        table.remove(logEntries, 1)
    end
end

-- Initial logs
addLog("Pulsar Key System initialized", CONFIG.Accent)
addLog("Service connected: platoboost.com", CONFIG.TextDim)
addLog("Awaiting key input...", CONFIG.TextDim)

-- Calculate positions based on output height
local inputLabelY = (isMobile and 38 or 50) + outputHeight * scale + 8
local inputBoxY = inputLabelY + (isMobile and 16 or 20)
local inputBoxHeight = isMobile and 38 or 32  -- Taller for touch

-- Input section label
local inputLabel = Instance.new("TextLabel")
inputLabel.Size = UDim2.new(1, 0, 0, isMobile and 16 or 18)
inputLabel.Position = UDim2.new(0, 0, 0, inputLabelY)
inputLabel.BackgroundTransparency = 1
inputLabel.Text = "> Enter Key:"
inputLabel.TextColor3 = CONFIG.Text
inputLabel.Font = Enum.Font.Code
inputLabel.TextSize = fontSize
inputLabel.TextXAlignment = Enum.TextXAlignment.Left
inputLabel.Parent = content

-- Key input box
local inputFrame = Instance.new("Frame")
inputFrame.Size = UDim2.new(1, 0, 0, inputBoxHeight)
inputFrame.Position = UDim2.new(0, 0, 0, inputBoxY)
inputFrame.BackgroundColor3 = CONFIG.Surface
inputFrame.BorderSizePixel = 0
inputFrame.Parent = content

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 3)
inputCorner.Parent = inputFrame

local inputBorder = Instance.new("UIStroke")
inputBorder.Color = CONFIG.Border
inputBorder.Thickness = isMobile and 2 or 1
inputBorder.Parent = inputFrame

local keyInput = Instance.new("TextBox")
keyInput.Name = "KeyInput"
keyInput.Size = UDim2.new(1, -16, 1, 0)
keyInput.Position = UDim2.new(0, 8, 0, 0)
keyInput.BackgroundTransparency = 1
keyInput.PlaceholderText = isMobile and "tap to paste key..." or "paste your key here..."
keyInput.Text = ""
keyInput.TextColor3 = CONFIG.Text
keyInput.PlaceholderColor3 = CONFIG.TextDim
keyInput.Font = Enum.Font.Code
keyInput.TextSize = fontSize
keyInput.TextXAlignment = Enum.TextXAlignment.Left
keyInput.ClearTextOnFocus = false
keyInput.Parent = inputFrame

-- Blinking cursor effect
local cursor = Instance.new("TextLabel")
cursor.Size = UDim2.new(0, 8, 0, 14)
cursor.Position = UDim2.new(0, 8, 0.5, 0)
cursor.AnchorPoint = Vector2.new(0, 0.5)
cursor.BackgroundTransparency = 1
cursor.Text = "_"
cursor.TextColor3 = CONFIG.Accent
cursor.Font = Enum.Font.Code
cursor.TextSize = 14
cursor.Visible = true
cursor.Parent = inputFrame

task.spawn(function()
    while cursor and cursor.Parent do
        cursor.Visible = not cursor.Visible
        task.wait(0.5)
    end
end)

keyInput:GetPropertyChangedSignal("Text"):Connect(function()
    cursor.Visible = keyInput.Text == ""
end)

-- Buttons section
local buttonsY = inputBoxY + inputBoxHeight + (isMobile and 10 or 8)
local buttonHeight = isMobile and 36 or 28  -- Taller for touch
local buttonWidth = isMobile and 100 or 140

local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(1, 0, 0, buttonHeight)
buttonsFrame.Position = UDim2.new(0, 0, 0, buttonsY)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = content

local buttonsLayout = Instance.new("UIListLayout")
buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
buttonsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
buttonsLayout.Padding = UDim.new(0, isMobile and 8 or 12)
buttonsLayout.Parent = buttonsFrame

local function createConsoleButton(text)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, buttonWidth, 0, buttonHeight)
    btn.BackgroundColor3 = CONFIG.Surface
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = buttonsFrame
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 3)
    btnCorner.Parent = btn
    
    local btnBorder = Instance.new("UIStroke")
    btnBorder.Color = CONFIG.Border
    btnBorder.Thickness = isMobile and 2 or 1
    btnBorder.Parent = btn
    
    local btnText = Instance.new("TextLabel")
    btnText.Size = UDim2.new(1, 0, 1, 0)
    btnText.BackgroundTransparency = 1
    btnText.Text = isMobile and text or ("[ " .. text .. " ]")
    btnText.TextColor3 = CONFIG.Text
    btnText.Font = Enum.Font.Code
    btnText.TextSize = fontSize
    btnText.TextScaled = isMobile
    btnText.Parent = btn
    
    if isMobile then
        local textConstraint = Instance.new("UITextSizeConstraint")
        textConstraint.MaxTextSize = fontSize
        textConstraint.MinTextSize = 8
        textConstraint.Parent = btnText
    end
    
    -- Hover effects (desktop)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btnBorder, TweenInfo.new(0.15), {Color = CONFIG.BorderActive}):Play()
        TweenService:Create(btnText, TweenInfo.new(0.15), {TextColor3 = CONFIG.Accent}):Play()
    end)
    
    btn.MouseLeave:Connect(function()
        TweenService:Create(btnBorder, TweenInfo.new(0.15), {Color = CONFIG.Border}):Play()
        TweenService:Create(btnText, TweenInfo.new(0.15), {TextColor3 = CONFIG.Text}):Play()
    end)
    
    btn.MouseButton1Down:Connect(function()
        btn.BackgroundColor3 = CONFIG.Border
    end)
    
    btn.MouseButton1Up:Connect(function()
        btn.BackgroundColor3 = CONFIG.Surface
    end)
    
    -- Touch feedback for mobile
    if isMobile then
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.Border}):Play()
                TweenService:Create(btnBorder, TweenInfo.new(0.1), {Color = CONFIG.BorderActive}):Play()
                TweenService:Create(btnText, TweenInfo.new(0.1), {TextColor3 = CONFIG.Accent}):Play()
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.Surface}):Play()
                TweenService:Create(btnBorder, TweenInfo.new(0.15), {Color = CONFIG.Border}):Play()
                TweenService:Create(btnText, TweenInfo.new(0.15), {TextColor3 = CONFIG.Text}):Play()
            end
        end)
    end
    
    return btn, btnText, btnBorder
end

local getKeyBtn, getKeyText, getKeyBorder = createConsoleButton("GET_KEY")
local redeemBtn, redeemText, redeemBorder = createConsoleButton("REDEEM")
local verifyBtn, verifyText, verifyBorder = createConsoleButton("VERIFY")

-- Status bar at bottom
local statusBarY = buttonsY + buttonHeight + (isMobile and 8 or 10)
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, 0, 0, isMobile and 20 or 24)
statusBar.Position = UDim2.new(0, 0, 0, statusBarY)
statusBar.BackgroundColor3 = CONFIG.Surface
statusBar.BorderSizePixel = 0
statusBar.Parent = content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 3)
statusCorner.Parent = statusBar

local statusBorder = Instance.new("UIStroke")
statusBorder.Color = CONFIG.Border
statusBorder.Thickness = isMobile and 2 or 1
statusBorder.Parent = statusBar

local indicatorSize = isMobile and 6 or 8
local statusIndicator = Instance.new("Frame")
statusIndicator.Size = UDim2.new(0, indicatorSize, 0, indicatorSize)
statusIndicator.Position = UDim2.new(0, 8, 0.5, 0)
statusIndicator.AnchorPoint = Vector2.new(0, 0.5)
statusIndicator.BackgroundColor3 = CONFIG.Accent
statusIndicator.BorderSizePixel = 0
statusIndicator.Parent = statusBar

local indicatorCorner = Instance.new("UICorner")
indicatorCorner.CornerRadius = UDim.new(1, 0)
indicatorCorner.Parent = statusIndicator

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -24, 1, 0)
statusText.Position = UDim2.new(0, 18 + indicatorSize, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = isMobile and "READY" or "READY - waiting for input"
statusText.TextColor3 = CONFIG.TextDim
statusText.Font = Enum.Font.Code
statusText.TextSize = smallFontSize
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.TextScaled = isMobile
statusText.Parent = statusBar

if isMobile then
    local statusConstraint = Instance.new("UITextSizeConstraint")
    statusConstraint.MaxTextSize = smallFontSize
    statusConstraint.MinTextSize = 8
    statusConstraint.Parent = statusText
end

-- Blinking status indicator
task.spawn(function()
    while statusIndicator and statusIndicator.Parent do
        TweenService:Create(statusIndicator, TweenInfo.new(0.8), {BackgroundTransparency = 0.6}):Play()
        task.wait(0.8)
        TweenService:Create(statusIndicator, TweenInfo.new(0.8), {BackgroundTransparency = 0}):Play()
        task.wait(0.8)
    end
end)

--// =========================================================
--// BUTTON LOGIC
--// =========================================================
local function setStatus(text, color)
    -- Shorten text for mobile
    if isMobile and #text > 25 then
        text = text:sub(1, 22) .. "..."
    end
    statusText.Text = text
    statusText.TextColor3 = color or CONFIG.TextDim
    statusIndicator.BackgroundColor3 = color or CONFIG.Accent
end

local function setButtonsEnabled(enabled)
    getKeyBtn.Active = enabled
    redeemBtn.Active = enabled
    verifyBtn.Active = enabled
    
    local alpha = enabled and 1 or 0.5
    getKeyText.TextTransparency = enabled and 0 or 0.5
    redeemText.TextTransparency = enabled and 0 or 0.5
    verifyText.TextTransparency = enabled and 0 or 0.5
end

local function destroyUI()
    TweenService:Create(console, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 480, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.25)
    screen:Destroy()
end

-- Get Key button
getKeyBtn.MouseButton1Click:Connect(function()
    addLog("Requesting key link from server...", CONFIG.Warning)
    setStatus("PROCESSING - fetching link", CONFIG.Warning)
    setButtonsEnabled(false)
    lastApiMessage = nil  -- Clear previous message
    
    task.spawn(function()
        local okCopy, link = keyApi.copyLink()
        if okCopy then
            addLog("Link copied to clipboard!", CONFIG.Success)
            addLog("Open link in browser to get key", CONFIG.TextDim)
            setStatus("SUCCESS - link copied", CONFIG.Success)
        else
            local errorMsg = lastApiMessage or "unknown error"
            addLog("ERROR: " .. errorMsg, CONFIG.Error)
            setStatus("ERROR - " .. errorMsg, CONFIG.Error)
        end
        setButtonsEnabled(true)
    end)
end)

-- Redeem button
redeemBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text:gsub("%s+", "")
    if key == "" then
        addLog("ERROR: No key provided", CONFIG.Error)
        setStatus("ERROR - empty input", CONFIG.Error)
        TweenService:Create(inputBorder, TweenInfo.new(0.1), {Color = CONFIG.Error}):Play()
        task.wait(0.3)
        TweenService:Create(inputBorder, TweenInfo.new(0.2), {Color = CONFIG.Border}):Play()
        return
    end
    
    addLog("Attempting to redeem key...", CONFIG.Warning)
    setStatus("PROCESSING - redeeming", CONFIG.Warning)
    setButtonsEnabled(false)
    lastApiMessage = nil  -- Clear previous message
    
    task.spawn(function()
        local okRedeem = keyApi.redeemKey(key)
        if okRedeem then
            addLog("Key redeemed successfully!", CONFIG.Success)
            addLog("Run VERIFY to authenticate", CONFIG.Accent)
            setStatus("SUCCESS - now verify", CONFIG.Success)
        else
            local errorMsg = lastApiMessage or "invalid key"
            addLog("ERROR: " .. errorMsg, CONFIG.Error)
            setStatus("ERROR - " .. errorMsg, CONFIG.Error)
        end
        setButtonsEnabled(true)
    end)
end)

-- Verify button
verifyBtn.MouseButton1Click:Connect(function()
    local key = keyInput.Text:gsub("%s+", "")
    if key == "" then
        addLog("ERROR: No key to verify", CONFIG.Error)
        setStatus("ERROR - empty input", CONFIG.Error)
        TweenService:Create(inputBorder, TweenInfo.new(0.1), {Color = CONFIG.Error}):Play()
        task.wait(0.3)
        TweenService:Create(inputBorder, TweenInfo.new(0.2), {Color = CONFIG.Border}):Play()
        return
    end
    
    addLog("Verifying key with server...", CONFIG.Warning)
    setStatus("PROCESSING - verifying", CONFIG.Warning)
    setButtonsEnabled(false)
    lastApiMessage = nil  -- Clear previous message
    
    task.spawn(function()
        local okVerify = keyApi.verifyKey(key)
        if okVerify then
            addLog("========================================", CONFIG.Success)
            addLog("ACCESS GRANTED", CONFIG.Success)
            addLog("========================================", CONFIG.Success)
            addLog("Loading Pulsar Hub...", CONFIG.Accent)
            setStatus("AUTHENTICATED - loading hub", CONFIG.Success)
            
            saveKey(key)
            
            TweenService:Create(consoleBorder, TweenInfo.new(0.3), {Color = CONFIG.Success}):Play()
            
            task.wait(1.5)
            destroyUI()
            loadHub()
        else
            local errorMsg = lastApiMessage or "invalid or expired key"
            addLog("ERROR: " .. errorMsg, CONFIG.Error)
            setStatus("DENIED - " .. errorMsg, CONFIG.Error)
            
            TweenService:Create(inputBorder, TweenInfo.new(0.2), {Color = CONFIG.Error}):Play()
            task.wait(0.5)
            TweenService:Create(inputBorder, TweenInfo.new(0.2), {Color = CONFIG.Border}):Play()
            
            setButtonsEnabled(true)
        end
    end)
end)

-- Input focus effects
keyInput.Focused:Connect(function()
    TweenService:Create(inputBorder, TweenInfo.new(0.15), {Color = CONFIG.BorderActive}):Play()
    cursor.Visible = false
end)

keyInput.FocusLost:Connect(function(enterPressed)
    TweenService:Create(inputBorder, TweenInfo.new(0.15), {Color = CONFIG.Border}):Play()
    cursor.Visible = keyInput.Text == ""
    
    if enterPressed and keyInput.Text ~= "" then
        verifyBtn.MouseButton1Click:Fire()
    end
end)
