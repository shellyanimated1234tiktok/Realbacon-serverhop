-- [[ CONFIGURATION & ANTI-DUP: Tự động tìm và xóa phiên bản script cũ ]]
local SCRIPT_ID = "Delta_ServerHop_HiddenCounter_V2"

if getgenv()[SCRIPT_ID] then
    pcall(function()
        getgenv()[SCRIPT_ID]:Destroy()
    end)
    getgenv()[SCRIPT_ID] = nil
    warn("[System] Đã dọn dẹp menu cũ để nạp menu mới!")
end

-- [[ MAIN GUI CREATION ]]
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = SCRIPT_ID
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

getgenv()[SCRIPT_ID] = ScreenGui

-- Tạo Nút Chữ Nhật Kéo Thả
local MenuButton = Instance.new("TextButton")
MenuButton.Name = "ServerHopButton"
MenuButton.Size = UDim2.new(0, 180, 0, 50)
MenuButton.Position = UDim2.new(0.1, 0, 0.2, 0)
MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
MenuButton.Text = "👉 AUTO SPAM SERVER"
MenuButton.TextColor3 = Color3.fromRGB(255, 255, 255)
MenuButton.Font = Enum.Font.SourceSansBold
MenuButton.TextSize = 14
MenuButton.BorderSizePixel = 0
MenuButton.AutoButtonColor = true
MenuButton.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MenuButton

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 170, 0)
UIStroke.Thickness = 2
UIStroke.Parent = MenuButton

-- [[ DRAGGABLE SYSTEM: Kéo thả mượt mà ]]
local dragging, dragInput, dragStart, startPos
local isSpamming = false
local lastClickTime = 0
local CLICK_COOLDOWN = 5 -- 5 giây cooldown giữa các lần ấn

local function update(input)
    if isSpamming then return end
    local delta = input.Position - dragStart
    local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(MenuButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

MenuButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not isSpamming then
            dragging = true
            dragStart = input.Position
            startPos = MenuButton.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end
end)

MenuButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- [[ HÀM SPAM TELEPORT CHO ĐẾN KHI VÀO ĐƯỢC - KHÔNG HIỂN THỊ SỐ LẦN ]]
local function SpamTeleportServers()
    local currentTime = tick()
    
    if isSpamming then
        warn("[System] Đang spam, vui lòng chờ!")
        return
    end
    
    if currentTime - lastClickTime < CLICK_COOLDOWN then
        local waitTime = math.ceil(CLICK_COOLDOWN - (currentTime - lastClickTime))
        MenuButton.Text = "⏳ Chờ " .. waitTime .. "s"
        MenuButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        return
    end
    
    isSpamming = true
    lastClickTime = tick()
    MenuButton.Text = "🔴 SPAM ĐANG CHẠY"
    MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local attemptCount = 0
    local maxAttempts = 50
    local teleportSuccess = false
    
    while attemptCount < maxAttempts and not teleportSuccess do
        attemptCount = attemptCount + 1
        
        local apiURL = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
        
        local success, result = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(apiURL))
        end)
        
        if success and result and result.data then
            local oldestServer = nil
            
            -- Tìm server cũ nhất có chỗ trống
            for _, server in ipairs(result.data) do
                if server.id ~= currentJobId and server.playing < server.maxPlayers then
                    oldestServer = server
                    break
                end
            end
            
            if oldestServer then
                local teleportAttempt = pcall(function()
                    TeleportService:TeleportToPlaceInstance(placeId, oldestServer.id, Players.LocalPlayer)
                end)
                
                if teleportAttempt then
                    teleportSuccess = true
                    warn("[System] Teleport thành công ở lần #" .. attemptCount)
                end
            end
        end
        
        -- Delay 0.2 giây trước khi spam lần tiếp theo
        task.wait(0.2)
    end
    
    if teleportSuccess then
        MenuButton.Text = "✅ THÀNH CÔNG!"
        MenuButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
    else
        MenuButton.Text = "❌ SPAM THẤT BẠI"
        MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(3)
    end
    
    MenuButton.Text = "👉 AUTO SPAM SERVER"
    MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    isSpamming = false
end

-- Kích hoạt khi click vào nút
MenuButton.MouseButton1Click:Connect(SpamTeleportServers)

-- Reset nút nếu bị lỗi sau thời gian dài
task.spawn(function()
    while true do
        task.wait(60)
        if isSpamming and MenuButton.Text ~= "👉 AUTO SPAM SERVER" then
            MenuButton.Text = "👉 AUTO SPAM SERVER"
            MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            isSpamming = false
            warn("[System] Reset nút do timeout!")
        end
    end
end)
