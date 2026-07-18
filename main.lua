-- [[ SINGLE BUTTON - AUTO SPAM TELEPORT ]]
local SCRIPT_ID = "Delta_ServerHop_SingleBtn_V3"

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
Button.Text = "AUTO SPAM"
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

-- Spam function
local isSpamming = false

local function Spam()
    if isSpamming then return end
    isSpamming = true
    Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local attemptCount = 0
    local maxAttempts = 50
    local success = false
    
    while attemptCount < maxAttempts and not success do
        attemptCount = attemptCount + 1
        
        local apiURL = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        
        local ok, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(apiURL))
        end)
        
        if ok and result and result.data then
            for _, server in ipairs(result.data) do
                if server.id ~= currentJobId and server.playing < server.maxPlayers then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(placeId, server.id, Players.LocalPlayer)
                    end)
                    success = true
                    break
                end
            end
        end
        
        task.wait(0.2)
    end
    
    if success then
        Button.Text = "✅ OK"
        Button.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    else
        Button.Text = "❌ FAIL"
        Button.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(2)
    end
    
    Button.Text = "AUTO SPAM"
    Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    isSpamming = false
end

Button.MouseButton1Click:Connect(Spam)
