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
MenuButton.Text = "👉 ĐỔI SERVER CŨ NHẤT"
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
UIStroke.Color = Color3.fromRGB(255, 170, 0) -- Màu cam nổi bật cho tính năng Hop
UIStroke.Thickness = 2
UIStroke.Parent = MenuButton

-- [[ DRAGGABLE SYSTEM: Kéo thả mượt mà ]]
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    TweenService:Create(MenuButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
end

MenuButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MenuButton.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

MenuButton.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then update(input) end
end)

-- [[ HÀM TÌM VÀ CHUYỂN ĐẾN SERVER LÂU ĐỜI NHẤT (OLDEST SERVER) ]]
local function TeleportToOldestServer()
    MenuButton.Text = "⏳ Đang quét server..."
    MenuButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    
    local placeId = game.PlaceId
    local currentJobId = game.JobId
    local apiURL = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100" 
    -- Lưu ý: sortOrder=Asc giúp Roblox ưu tiên trả về các server tạo ra đầu tiên (cũ nhất)
    
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(apiURL))
    end)
    
    if success and result and result.data then
        local targetServer = nil
        
        -- Duyệt danh sách tìm server hợp lệ (không đầy, không phải server hiện tại)
        for _, server in ipairs(result.data) do
            if server.id ~= currentJobId and server.playing < server.maxPlayers then
                targetServer = server
                break -- Lấy ngay server cũ nhất thỏa mãn điều kiện
            end
        end
        
        if targetServer then
            MenuButton.Text = "🚀 Đang kết nối..."
            MenuButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
            
            -- Xóa GUI trước khi nhảy để tránh lỗi bộ nhớ
            if getgenv()[SCRIPT_ID] then
                getgenv()[SCRIPT_ID]:Destroy()
                getgenv()[SCRIPT_ID] = nil
            end
            
            -- Thực hiện dịch chuyển
            TeleportService:TeleportToPlaceInstance(placeId, targetServer.id, Players.LocalPlayer)
        else
            MenuButton.Text = "❌ Không tìm thấy server khác"
            MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
            task.wait(2)
            MenuButton.Text = "👉 ĐỔI SERVER CŨ NHẤT"
            MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
        end
    else
        MenuButton.Text = "❌ Lỗi kết nối API"
        MenuButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        task.wait(2)
        MenuButton.Text = "👉 ĐỔI SERVER CŨ NHẤT"
        MenuButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    end
end

-- Kích hoạt khi click vào nút hình chữ nhật
MenuButton.MouseButton1Click:Connect(TeleportToOldestServer)
