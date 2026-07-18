-- [[ CONFIGURATION & ANTI-DUP: Tự động tìm và xóa phiên bản script cũ ]]
local SCRIPT_ID = "Delta_ServerHop_Oldest_V1"

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
local RunService = game:GetService("RunService")

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
MenuButton.Text = "👉 TÌM SERVER LÂU NHẤT"
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
local isProcessing = false

local function update(input)
    if isProcessing then return end
    local delta = input.Position - dragStart
    local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(MenuButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

MenuButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if not isProcessing then
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

-- [[ HÀM TÌM SERVER LÂU NHẤT CÓ CHỖ TRỐNG ]]
local function TeleportToOldestServer()
    if isProcessing then
        warn("[System] Đang xử lý, vui lòng chờ!")
        return
    end
    
    isProcessing = true
    MenuButton.Text = "⏳ Đang quét server..."
    MenuButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    -- Lấy 100 server đầu tiên (sắp xếp từ cũ đến mới)
    local apiURL = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100" 
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(apiURL))
    end)
    
    if success and result and result.data then
        local oldestServer = nil
        
        -- Tìm server cũ nhất (lâu nhất) có chỗ trống
        for _, server in ipairs(result.data) do
            -- Điều kiện: không phải server hiện tại + có chỗ trống
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                oldestServer = server
                break -- Server đầu tiên trong danh sách sắp xếp Asc là cũ nhất
            end
        end
        
        if oldestServer then
            MenuButton.Text = "🚀 Đang kết nối..."
            MenuButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            
            -- Delay trước teleport để tránh lỗi hạn chế
            task.wait(1)
            
            -- Xử lý teleport an toàn
            local teleportSuccess = pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, oldestServer.id, Players.LocalPlayer)
            end)
            
            if not teleportSuccess then
                MenuButton.Text = "❌ Teleport bị từ chối"
                MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
                task.wait(3)
                MenuButton.Text = "👉 TÌM SERVER LÂU NHẤT"
                MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                isProcessing = false
            end
        else
            MenuButton.Text = "❌ Không tìm thấy server"
            MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.wait(3)
            MenuButton.Text = "👉 TÌM SERVER LÂU NHẤT"
            MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            isProcessing = false
        end
    else
        MenuButton.Text = "❌ Lỗi kết nối API"
        MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(3)
        MenuButton.Text = "👉 TÌM SERVER LÂU NHẤT"
        MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        isProcessing = false
    end
end

-- Kích hoạt khi click vào nút
MenuButton.MouseButton1Click:Connect(TeleportToOldestServer)

-- Reset nút nếu bị lỗi sau thời gian dài
task.spawn(function()
    while true do
        task.wait(30)
        if isProcessing and MenuButton.Text ~= "👉 TÌM SERVER LÂU NHẤT" then
            MenuButton.Text = "👉 TÌM SERVER LÂU NHẤT"
            MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            isProcessing = false
            warn("[System] Reset nút do timeout!")
        end
    end
end)
