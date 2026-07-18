-- [[ SINGLE BUTTON - AUTO SPAM TO OLDEST SERVER WITH RAINBOW BORDER + DRAGGABLE ]]
local SCRIPT_ID = "Delta_ServerHop_Fixed_V7"

if getgenv()[SCRIPT_ID] then
    pcall(function()
        getgenv()[SCRIPT_ID]:Destroy()
    end)
    getgenv()[SCRIPT_ID] = nil
end

local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCRIPT_ID
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

getgenv()[SCRIPT_ID] = ScreenGui

-- Tạo 1 nút duy nhất
local Button = Instance.new("TextButton")
Button.Name = "ServerHopBtn"
Button.Size = UDim2.new(0, 150, 0, 45)
Button.Position = UDim2.new(0.05, 0, 0.15, 0)
Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Button.Text = "SERVER HOP"
Button.TextColor3 = Color3.fromRGB(255, 255, 255)
Button.Font = Enum.Font.SourceSansBold
Button.TextSize = 13
Button.BorderSizePixel = 0
Button.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Button

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(255, 170, 0)
Stroke.Thickness = 2
Stroke.Parent = Button

-- [[ DRAGGABLE SYSTEM - FIX VERSION ]]
local dragging = false
local dragStart = nil
local startPos = nil
local lastClickTime = 0
local clickThreshold = 0.2

Button.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Button.Position
        lastClickTime = tick()
    end
end)

Button.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging and dragStart then
        local delta = input.Position - dragStart
        local distance = math.sqrt(delta.X^2 + delta.Y^2)
        
        if distance > 5 then -- Threshold để detect drag
            Button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            dragging = true -- Lock drag state
        end
    end
end)

-- Rainbow colors array
local rainbowColors = {
    Color3.fromRGB(255, 0, 0),      -- Red
    Color3.fromRGB(255, 127, 0),    -- Orange
    Color3.fromRGB(255, 255, 0),    -- Yellow
    Color3.fromRGB(0, 255, 0),      -- Green
    Color3.fromRGB(0, 0, 255),      -- Blue
    Color3.fromRGB(75, 0, 130),     -- Indigo
    Color3.fromRGB(148, 0, 211),    -- Violet
}

-- Rainbow animation loop
task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        for _, color in ipairs(rainbowColors) do
            if not ScreenGui or not ScreenGui.Parent then break end
            local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
            local tween = TweenService:Create(Stroke, tweenInfo, {Color = color})
            tween:Play()
            tween.Completed:Wait()
        end
    end
end)

-- Spam function - Tìm server lâu nhất CHẮC CHẮN
local isSpamming = false

local function GetOldestServer()
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    
    local apiURL = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local ok, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(apiURL))
    end)
    
    if ok and result and result.data and #result.data > 0 then
        for _, server in ipairs(result.data) do
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                return server
            end
        end
    end
    
    return nil
end

local function Spam()
    if isSpamming then return end
    isSpamming = true
    dragging = false
    Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    Button.Text = "🔴 SPAM CHẠY"
    
    local placeId = game.PlaceId
    local attemptCount = 0
    local maxAttempts = 50
    local success = false
    
    while attemptCount < maxAttempts and not success do
        attemptCount = attemptCount + 1
        
        local oldestServer = GetOldestServer()
        
        if oldestServer then
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, oldestServer.id, Players.LocalPlayer)
            end)
            success = true
        end
        
        task.wait(0.3)
    end
    
    if success then
        Button.Text = "✅ OK"
        Button.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
        task.wait(1)
    else
        Button.Text = "❌ FAIL"
        Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(2)
    end
    
    Button.Text = "SERVER HOP"
    Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    isSpamming = false
end

Button.MouseButton1Click:Connect(function()
    if not dragging and (tick() - lastClickTime) > clickThreshold then
        Spam()
    end
end)
