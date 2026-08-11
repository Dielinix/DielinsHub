local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Таблица для очистки всех соединений при завершении
local Connections = {}

-- Функция воспроизведения звука
local function playSound(soundId)
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. tostring(soundId)
        sound.Volume = 0.5
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
        task.delay(3, function()
            if sound and sound.Parent then sound:Destroy() end
        end)
    end)
end

-- ==========================================
-- КОНФИГУРАЦИЯ И СОСТОЯНИЯ
-- ==========================================
local Config = {
    -- Aimbot Settings
    Aimbot_Enabled = false,
    Aimbot_Part = "Head",

    -- Ink Game Features
    RGBHighlight_Enabled = false,
    AutoTiming_Enabled = false,

    -- ESP Settings
    ESP_Enabled = false,
    ESP_Tracers = false,
    ESP_Color = Color3.fromRGB(255, 60, 60),
    ESP_FillTransparency = 0.5,
    Tracer_Origin = "Bottom",
    Tracer_Thickness = 1.5,
    NameTags_Enabled = false,
    NameTags_ShowHealth = true,
    NameTags_ShowDistance = true,
    NameTags_Color = Color3.fromRGB(255, 255, 255),

    -- Movement Settings
    WalkSpeed = 16,
    JumpPower = 50,
    ShiftSprint_Enabled = false,
    SprintSpeed = 35,
    Fly_Enabled = false,
    Fly_Speed = 50,
    Noclip_Enabled = false,
    InfJump_Enabled = false,
    Bhop_Enabled = false,
    Bhop_StartSpeed = 25,
    Bhop_Accel = 1.5,
    Bhop_MaxSpeed = 120,
    Invisible_Enabled = false,
    Spin_Enabled = false,
    Spin_Speed = 20,

    -- Hitbox Settings
    Hitbox_Enabled = false,
    Hitbox_Visible = true,
    Hitbox_Size = 10,
    Hitbox_Color = Color3.fromRGB(255, 0, 0),
    Hitbox_Transparency = 0.6,
    Hitbox_Material = Enum.Material.Neon,

    -- Custom FX (Trails & Particles)
    Trail_Enabled = false,
    Trail_Style = "Neon Solid",
    Trail_Color = Color3.fromRGB(130, 80, 255),
    
    Particle_Enabled = false,
    Particle_Style = "Sparkles",
    Particle_Rate = 20,
    Particle_Speed = 4,

    -- Visuals / Weather / HUD
    Fullbright_Enabled = false,
    ShowStats = true,
    FOV_Value = 70,
    OriginalAmbient = Lighting.Ambient,
    OriginalOutdoorAmbient = Lighting.OutdoorAmbient,

    -- VIP / Premium Status
    VIPUnlocked = false,

    -- Extra & VIP Troll Functions
    ClickTP_Enabled = false,
    AntiAFK_Enabled = true,
    RainbowChar_Enabled = false,
    DrunkCam_Enabled = false,
    BigHead_Enabled = false,
    ScreenShake_Enabled = false,
    AutoClick_Enabled = false,
    SuperJump_Enabled = false,
    FlingAura_Enabled = false,
    Ragdoll_Enabled = false,
    FakeChat_Enabled = false,
    InvisibleArms_Enabled = false,

    -- UI Theme Customization
    Theme_Color1 = Color3.fromRGB(130, 80, 255),
    Theme_Color2 = Color3.fromRGB(255, 80, 180),
    Font_Main = Enum.Font.FredokaOne
}

-- Словари Ресурсов
local FX_Textures = {
    Particles = {
        Sparkles = "rbxassetid://243660364",
        Flames = "rbxassetid://258122325",
        Hearts = "rbxassetid://258122325",
        Snowflakes = "rbxassetid://241685483",
        Electric = "rbxassetid://278709328",
        Cash = "rbxassetid://1084991219"
    },
    Trails = {
        ["Neon Solid"] = "",
        ["Lightning"] = "rbxassetid://1084991219",
        ["Fire"] = "rbxassetid://138879255",
        ["Cosmic"] = "rbxassetid://243660364"
    }
}

local Keybinds = {}
local ListeningFeature = nil

-- Привилегии
local SpecialRoles = {
    ["topil40"] = {Role = "Owner", Text = "Owner Access", Color = Color3.fromRGB(255, 215, 0)},
    ["pol_materiHuyeta"] = {Role = "Beta Tester", Text = "Beta Tester", Color = Color3.fromRGB(0, 255, 150)}
}

local localUserRoleText = "PaidAccess | Member"
local localUserRoleColor = Color3.fromRGB(255, 185, 0)

if SpecialRoles[LocalPlayer.Name] then
    localUserRoleText = SpecialRoles[LocalPlayer.Name].Text
    localUserRoleColor = SpecialRoles[LocalPlayer.Name].Color
end

-- ==========================================
-- ИНИЦИАЛИЗАЦИЯ GUI
-- ==========================================
local guiParent = pcall(function() return CoreGui end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
if guiParent:FindFirstChild("DielinsHubGui") then
    guiParent.DielinsHubGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DielinsHubGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local ThemedGradients = {}

local function addGradient(parent, color1, color2, angle, isThemed)
    local grad = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color1 or Config.Theme_Color1),
        ColorSequenceKeypoint.new(1, color2 or Config.Theme_Color2)
    })
    grad.Rotation = angle or 45
    grad.Parent = parent
    
    if isThemed then
        table.insert(ThemedGradients, grad)
    end
    
    return grad
end

-- Кнопка открытия/закрытия главного меню
local ToggleButton = Instance.new("ImageButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Size = UDim2.new(0, 50, 0, 50)
ToggleButton.Position = UDim2.new(0.015, 0, 0.2, 0)
ToggleButton.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
ToggleButton.Image = "rbxassetid://15966491875"
ToggleButton.ScaleType = Enum.ScaleType.Fit
ToggleButton.Active = true
ToggleButton.Draggable = true
ToggleButton.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 12)
ToggleCorner.Parent = ToggleButton

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(255, 255, 255)
ToggleStroke.Thickness = 2
ToggleStroke.Parent = ToggleButton

ToggleButton.MouseEnter:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 56, 0, 56)}):Play()
end)
ToggleButton.MouseLeave:Connect(function()
    TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 50, 0, 50)}):Play()
end)

local StatsFrame = Instance.new("TextLabel")
StatsFrame.Name = "StatsFrame"
StatsFrame.Size = UDim2.new(0, 160, 0, 26)
StatsFrame.Position = UDim2.new(0.015, 0, 0.02, 0)
StatsFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
StatsFrame.Text = "FPS: 60 | Ping: 0ms"
StatsFrame.TextColor3 = Color3.fromRGB(0, 255, 180)
StatsFrame.Font = Config.Font_Main
StatsFrame.TextSize = 11
StatsFrame.Visible = Config.ShowStats
StatsFrame.Parent = ScreenGui

local StatsCorner = Instance.new("UICorner")
StatsCorner.CornerRadius = UDim.new(0, 8)
StatsCorner.Parent = StatsFrame

local StatsStroke = Instance.new("UIStroke")
StatsStroke.Thickness = 1
StatsStroke.Color = Config.Theme_Color1
StatsStroke.Parent = StatsFrame

local frameCount = 0
local lastFpsUpdate = tick()
local currentFPS = 60

table.insert(Connections, RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    if tick() - lastFpsUpdate >= 1 then
        currentFPS = frameCount
        frameCount = 0
        lastFpsUpdate = tick()
    end

    if Config.ShowStats then
        local pingVal = 0
        pcall(function()
            pingVal = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        StatsFrame.Text = "FPS: " .. currentFPS .. " | Ping: " .. pingVal .. "ms"
    end
    StatsFrame.Visible = Config.ShowStats
end))

-- ТЕМНЫЙ ФОН GUI ДЛЯ УСТРАНЕНИЯ СЛИШКОМ ЯРКОГО СВЕЧЕНИЯ
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 670, 0, 480)
MainFrame.Position = UDim2.new(0.5, -335, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 20, 28) -- Исправлено: темно-серый вместо ярко-белого
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame
local globalMainGrad = addGradient(MainStroke, Config.Theme_Color1, Config.Theme_Color2, 90, true)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 180, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 16)
SidebarCorner.Parent = Sidebar

local Logo = Instance.new("TextLabel")
Logo.Size = UDim2.new(1, 0, 0, 38)
Logo.BackgroundTransparency = 1
Logo.Text = "dielin's Hub"
Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
Logo.Font = Config.Font_Main
Logo.TextSize = 20
Logo.Parent = Sidebar
addGradient(Logo, Config.Theme_Color1, Config.Theme_Color2, 0, true)

local CreditLabel1 = Instance.new("TextLabel")
CreditLabel1.Size = UDim2.new(1, 0, 0, 12)
CreditLabel1.Position = UDim2.new(0, 0, 0, 36)
CreditLabel1.BackgroundTransparency = 1
CreditLabel1.Text = "TGK - Dielinix"
CreditLabel1.TextColor3 = Color3.fromRGB(0, 220, 255)
CreditLabel1.Font = Config.Font_Main
CreditLabel1.TextSize = 10
CreditLabel1.Parent = Sidebar

local CreditLabel2 = Instance.new("TextLabel")
CreditLabel2.Size = UDim2.new(1, 0, 0, 12)
CreditLabel2.Position = UDim2.new(0, 0, 0, 48)
CreditLabel2.BackgroundTransparency = 1
CreditLabel2.Text = "Created By Dielin/disphory"
CreditLabel2.TextColor3 = Color3.fromRGB(160, 165, 185)
CreditLabel2.Font = Config.Font_Main
CreditLabel2.TextSize = 9
CreditLabel2.Parent = Sidebar

local ProfileFrame = Instance.new("Frame")
ProfileFrame.Size = UDim2.new(1, -16, 0, 64) 
ProfileFrame.Position = UDim2.new(0, 8, 0, 64)
ProfileFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
ProfileFrame.Parent = Sidebar

local ProfileCorner = Instance.new("UICorner")
ProfileCorner.CornerRadius = UDim.new(0, 10)
ProfileCorner.Parent = ProfileFrame

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.Size = UDim2.new(0, 30, 0, 30)
AvatarImage.Position = UDim2.new(0, 6, 0, 6)
AvatarImage.BackgroundTransparency = 1
pcall(function()
    AvatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
AvatarImage.Parent = ProfileFrame

local UsernameLabel = Instance.new("TextLabel")
UsernameLabel.Size = UDim2.new(1, -44, 0, 15)
UsernameLabel.Position = UDim2.new(0, 40, 0, 5)
UsernameLabel.BackgroundTransparency = 1
UsernameLabel.Text = LocalPlayer.DisplayName
UsernameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
UsernameLabel.Font = Config.Font_Main
UsernameLabel.TextSize = 11
UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
UsernameLabel.Parent = ProfileFrame

local BadgeLabel = Instance.new("TextLabel")
BadgeLabel.Size = UDim2.new(1, -44, 0, 14)
BadgeLabel.Position = UDim2.new(0, 40, 0, 20)
BadgeLabel.BackgroundTransparency = 1
BadgeLabel.Text = localUserRoleText
BadgeLabel.TextColor3 = localUserRoleColor
BadgeLabel.Font = Config.Font_Main
BadgeLabel.TextSize = 9
BadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
BadgeLabel.Parent = ProfileFrame

local SubscribeBtn = Instance.new("TextButton")
SubscribeBtn.Size = UDim2.new(1, -44, 0, 16)
SubscribeBtn.Position = UDim2.new(0, 40, 0, 40)
SubscribeBtn.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
SubscribeBtn.Text = "Subscribe"
SubscribeBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
SubscribeBtn.Font = Config.Font_Main
SubscribeBtn.TextSize = 10
SubscribeBtn.Parent = ProfileFrame
local SubBtnCorner = Instance.new("UICorner")
SubBtnCorner.CornerRadius = UDim.new(0, 4)
SubBtnCorner.Parent = SubscribeBtn

-- Кнопка полного закрытия/выключения скрипта
local FullCloseBtn = Instance.new("TextButton")
FullCloseBtn.Size = UDim2.new(1, -16, 0, 24)
FullCloseBtn.Position = UDim2.new(0, 8, 1, -32)
FullCloseBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 30)
FullCloseBtn.Text = "❌ Выключить Скрипт"
FullCloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
FullCloseBtn.Font = Config.Font_Main
FullCloseBtn.TextSize = 10
FullCloseBtn.Parent = Sidebar
local FullCloseCorner = Instance.new("UICorner")
FullCloseCorner.CornerRadius = UDim.new(0, 6)
FullCloseCorner.Parent = FullCloseBtn

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -16, 1, -170)
TabContainer.Position = UDim2.new(0, 8, 0, 134)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = Sidebar

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 4)
TabListLayout.Parent = TabContainer

local PagesContainer = Instance.new("Frame")
PagesContainer.Size = UDim2.new(1, -195, 1, -20)
PagesContainer.Position = UDim2.new(0, 188, 0, 10)
PagesContainer.BackgroundTransparency = 1
PagesContainer.Parent = MainFrame

-- ==========================================
-- СИСТЕМА ВКЛАДОК
-- ==========================================
local tabs = {}
local pages = {}

local function createPage(name)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = name .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.Position = UDim2.new(1, 50, 0, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.ScrollBarImageColor3 = Config.Theme_Color1
    Page.Visible = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Parent = PagesContainer

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 8)
    Layout.Parent = Page

    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
    end)

    pages[name] = Page
    return Page
end

local function createTabButton(name, order)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(1, 0, 0, 28)
    TabBtn.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
    TabBtn.Text = name
    TabBtn.TextColor3 = Color3.fromRGB(150, 155, 175)
    TabBtn.Font = Config.Font_Main
    TabBtn.TextSize = 11
    TabBtn.TextStrokeTransparency = 0.2
    TabBtn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TabBtn.LayoutOrder = order
    TabBtn.BorderSizePixel = 0
    TabBtn.Parent = TabContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = TabBtn

    local Gradient = addGradient(TabBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)
    Gradient.Enabled = false

    tabs[name] = TabBtn

    TabBtn.MouseButton1Click:Connect(function()
        -- Звук переключения вкладки 123796710194563
        playSound(123796710194563)

        for tabName, btn in pairs(tabs) do
            btn.BackgroundColor3 = Color3.fromRGB(26, 28, 38)
            btn.TextColor3 = Color3.fromRGB(150, 155, 175)
            local g = btn:FindFirstChildOfClass("UIGradient")
            if g then g.Enabled = false end
        end
        for _, page in pairs(pages) do 
            page.Visible = false 
        end

        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Gradient.Enabled = true
        
        local activePage = pages[name]
        activePage.Visible = true
        activePage.Position = UDim2.new(0.08, 0, 0, 0)
        activePage.BackgroundTransparency = 0.8
        
        TweenService:Create(activePage, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()

        TweenService:Create(TabBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, -6, 0, 26)}):Play()
        task.delay(0.1, function()
            TweenService:Create(TabBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 28)}):Play()
        end)
    end)
end

local combatPage = createPage("Combat")
local visualPage = createPage("Visuals")
local movePage = createPage("Movement")
local hitboxPage = createPage("Hitbox")
local tpPage = createPage("Teleport")
local vipPage = createPage("VIP & Fun")
local weatherPage = createPage("Weather")
local customPage = createPage("FX Custom")
local uiPage = createPage("UI Theme")

createTabButton("Combat", 1)
createTabButton("Visuals", 2)
createTabButton("Movement", 3)
createTabButton("Hitbox", 4)
createTabButton("Teleport", 5)
createTabButton("VIP & Fun", 6)
createTabButton("Weather", 7)
createTabButton("FX Custom", 8)
createTabButton("UI Theme", 9)

tabs["Combat"].TextColor3 = Color3.fromRGB(255, 255, 255)
tabs["Combat"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tabs["Combat"]:FindFirstChildOfClass("UIGradient").Enabled = true
pages["Combat"].Visible = true
pages["Combat"].Position = UDim2.new(0, 0, 0, 0)

-- ==========================================
-- КОМПОНЕНТЫ ИНТЕРФЕЙСА
-- ==========================================
local function createToggle(parent, text, featureId, initialValue, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.48, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230, 230, 240)
    Label.Font = Config.Font_Main
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ClearBindBtn = Instance.new("TextButton")
    ClearBindBtn.Size = UDim2.new(0, 20, 0, 20)
    ClearBindBtn.Position = UDim2.new(1, -125, 0.5, -10)
    ClearBindBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 30)
    ClearBindBtn.Text = "X"
    ClearBindBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    ClearBindBtn.Font = Config.Font_Main
    ClearBindBtn.TextSize = 10
    ClearBindBtn.Parent = Frame

    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 4)
    ClearCorner.Parent = ClearBindBtn

    local BindBtn = Instance.new("TextButton")
    BindBtn.Size = UDim2.new(0, 50, 0, 20)
    BindBtn.Position = UDim2.new(1, -100, 0.5, -10)
    BindBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
    BindBtn.Text = "[Bind]"
    BindBtn.TextColor3 = Color3.fromRGB(180, 185, 205)
    BindBtn.Font = Config.Font_Main
    BindBtn.TextSize = 9
    BindBtn.Parent = Frame

    local BindCorner = Instance.new("UICorner")
    BindCorner.CornerRadius = UDim.new(0, 4)
    BindCorner.Parent = BindBtn

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 40, 0, 20)
    ToggleBtn.Position = UDim2.new(1, -45, 0.5, -10)
    ToggleBtn.BackgroundColor3 = initialValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(40, 44, 60)
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Frame

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = ToggleBtn

    local ToggleGrad = addGradient(ToggleBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)
    ToggleGrad.Enabled = initialValue

    local Circle = Instance.new("Frame")
    Circle.Size = UDim2.new(0, 14, 0, 14)
    Circle.Position = initialValue and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Circle.Parent = ToggleBtn

    local CircleCorner = Instance.new("UICorner")
    CircleCorner.CornerRadius = UDim.new(1, 0)
    CircleCorner.Parent = Circle

    local state = initialValue

    local function setToggleState(newState)
        state = newState
        -- Звук переключения любой функции 8968249849
        playSound(8968249849)

        local targetPos = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        ToggleGrad.Enabled = state
        if not state then 
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 44, 60)}):Play() 
        else 
            TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play() 
        end
        TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos}):Play()
        callback(state)
    end

    ToggleBtn.MouseButton1Click:Connect(function() setToggleState(not state) end)

    BindBtn.MouseButton1Click:Connect(function()
        BindBtn.Text = "[...]"
        BindBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        ListeningFeature = {
            ID = featureId,
            Button = BindBtn,
            Action = function() setToggleState(not state) end
        }
    end)

    ClearBindBtn.MouseButton1Click:Connect(function()
        Keybinds[featureId] = nil
        BindBtn.Text = "[Bind]"
        BindBtn.TextColor3 = Color3.fromRGB(180, 185, 205)
    end)
end

local function createSlider(parent, text, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 46)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 0, 18)
    Label.Position = UDim2.new(0, 10, 0, 4)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230, 230, 240)
    Label.Font = Config.Font_Main
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 30, 0, 18)
    ValueLabel.Position = UDim2.new(0.7, -10, 0, 4)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Color3.fromRGB(160, 165, 185)
    ValueLabel.Font = Config.Font_Main
    ValueLabel.TextSize = 11
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = Frame

    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, -20, 0, 6)
    SliderBar.Position = UDim2.new(0, 10, 1, -12)
    SliderBar.BackgroundColor3 = Color3.fromRGB(40, 44, 60)
    SliderBar.Parent = Frame

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.Parent = SliderBar
    addGradient(Fill, Config.Theme_Color1, Config.Theme_Color2, 0, true)

    local dragging = false
    local function updateInput(input)
        local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
        local rawValue = min + (max - min) * pos
        local value = (max <= 1) and math.floor(rawValue * 100) / 100 or math.floor(rawValue)
        Fill.Size = UDim2.new(pos, 0, 1, 0)
        ValueLabel.Text = tostring(value)
        callback(value)
    end

    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateInput(input)
        end
    end)

    table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then updateInput(input) end
    end))
end

local function createSelector(parent, text, options, defaultIndex, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.4, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(230, 230, 240)
    Label.Font = Config.Font_Main
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame

    local currentIdx = defaultIndex or 1

    local NextBtn = Instance.new("TextButton")
    NextBtn.Size = UDim2.new(0, 24, 0, 24)
    NextBtn.Position = UDim2.new(1, -30, 0.5, -12)
    NextBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
    NextBtn.Text = ">"
    NextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    NextBtn.Font = Config.Font_Main
    NextBtn.TextSize = 12
    NextBtn.Parent = Frame

    local OptionLabel = Instance.new("TextLabel")
    OptionLabel.Size = UDim2.new(0, 120, 0, 24)
    OptionLabel.Position = UDim2.new(1, -154, 0.5, -12)
    OptionLabel.BackgroundTransparency = 1
    OptionLabel.Text = options[currentIdx]
    OptionLabel.TextColor3 = Color3.fromRGB(0, 220, 255)
    OptionLabel.Font = Config.Font_Main
    OptionLabel.TextSize = 11
    OptionLabel.TextXAlignment = Enum.TextXAlignment.Center
    OptionLabel.Parent = Frame

    local PrevBtn = Instance.new("TextButton")
    PrevBtn.Size = UDim2.new(0, 24, 0, 24)
    PrevBtn.Position = UDim2.new(1, -182, 0.5, -12)
    PrevBtn.BackgroundColor3 = Color3.fromRGB(35, 38, 55)
    PrevBtn.Text = "<"
    PrevBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    PrevBtn.Font = Config.Font_Main
    PrevBtn.TextSize = 12
    PrevBtn.Parent = Frame

    local function updateSelector()
        OptionLabel.Text = options[currentIdx]
        callback(options[currentIdx], currentIdx)
    end

    NextBtn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx % #options + 1
        updateSelector()
    end)

    PrevBtn.MouseButton1Click:Connect(function()
        currentIdx = (currentIdx - 2) % #options + 1
        updateSelector()
    end)
end

local function createButton(parent, text, featureId, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -6, 0, 38)
    Frame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    Frame.Parent = parent

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = Frame

    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Size = UDim2.new(1, -125, 1, -12)
    ActionBtn.Position = UDim2.new(0, 6, 0, 6)
    ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Text = text
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.Font = Config.Font_Main
    ActionBtn.TextSize = 11
    ActionBtn.Parent = Frame

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = ActionBtn
    addGradient(ActionBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)

    ActionBtn.MouseButton1Click:Connect(function()
        TweenService:Create(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, -129, 1, -14)}):Play()
        task.delay(0.1, function()
            TweenService:Create(ActionBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, -125, 1, -12)}):Play()
        end)
        callback()
    end)

    local ClearBindBtn = Instance.new("TextButton")
    ClearBindBtn.Size = UDim2.new(0, 20, 0, 20)
    ClearBindBtn.Position = UDim2.new(1, -110, 0.5, -10)
    ClearBindBtn.BackgroundColor3 = Color3.fromRGB(45, 20, 30)
    ClearBindBtn.Text = "X"
    ClearBindBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
    ClearBindBtn.Font = Config.Font_Main
    ClearBindBtn.TextSize = 10
    ClearBindBtn.Parent = Frame

    local ClearCorner = Instance.new("UICorner")
    ClearCorner.CornerRadius = UDim.new(0, 4)
    ClearCorner.Parent = ClearBindBtn

    local BindBtn = Instance.new("TextButton")
    BindBtn.Size = UDim2.new(0, 80, 0, 20)
    BindBtn.Position = UDim2.new(1, -85, 0.5, -10)
    BindBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 50)
    BindBtn.Text = "[Bind]"
    BindBtn.TextColor3 = Color3.fromRGB(180, 185, 205)
    BindBtn.Font = Config.Font_Main
    BindBtn.TextSize = 9
    BindBtn.Parent = Frame

    local BindCorner = Instance.new("UICorner")
    BindCorner.CornerRadius = UDim.new(0, 4)
    BindCorner.Parent = BindBtn

    BindBtn.MouseButton1Click:Connect(function()
        BindBtn.Text = "[...]"
        BindBtn.TextColor3 = Color3.fromRGB(255, 215, 0)
        ListeningFeature = {
            ID = featureId,
            Button = BindBtn,
            Action = callback
        }
    end)

    ClearBindBtn.MouseButton1Click:Connect(function()
        Keybinds[featureId] = nil
        BindBtn.Text = "[Bind]"
        BindBtn.TextColor3 = Color3.fromRGB(180, 185, 205)
    end)
end

-- Обработчик Нажатий Бинд-Клавиш
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    if ListeningFeature and input.UserInputType == Enum.UserInputType.Keyboard then
        local key = input.KeyCode
        if key ~= Enum.KeyCode.Unknown and key ~= Enum.KeyCode.Escape then
            Keybinds[ListeningFeature.ID] = { Key = key, Action = ListeningFeature.Action }
            ListeningFeature.Button.Text = "[" .. key.Name .. "]"
            ListeningFeature.Button.TextColor3 = Color3.fromRGB(0, 255, 180)
        else
            ListeningFeature.Button.Text = "[Bind]"
            ListeningFeature.Button.TextColor3 = Color3.fromRGB(180, 185, 205)
        end
        ListeningFeature = nil
        return
    end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        for id, bindData in pairs(Keybinds) do
            if bindData.Key == input.KeyCode and bindData.Action then
                bindData.Action()
            end
        end
    end
end))

-- ==========================================
-- AIMBOT ЛОГИКА
-- ==========================================
local function getClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mouse = LocalPlayer:GetMouse()
    local mousePos = Vector2.new(mouse.X, mouse.Y)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local targetPart = player.Character:FindFirstChild(Config.Aimbot_Part) or player.Character:FindFirstChild("HumanoidRootPart")
                if targetPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local screenVector = Vector2.new(screenPos.X, screenPos.Y)
                        local distance = (screenVector - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    if Config.Aimbot_Enabled then
        local target = getClosestPlayerToCursor()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Config.Aimbot_Part) or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            end
        end
    end
end))

-- ==========================================
-- INK GAME: RGB ПОДСВЕТКА КРАСНЫХ ШАРОВ
-- ==========================================
local ActiveHighlights = {}

local function IsRedSphere(obj)
    if not obj:IsA("BasePart") then return false end
    local isSphere = (obj.Shape == Enum.PartType.Ball)
    if not isSphere then
        local mesh = obj:FindFirstChildOfClass("SpecialMesh")
        if mesh and (mesh.MeshType == Enum.MeshType.Sphere or string.find(string.lower(mesh.MeshId), "sphere")) then
            isSphere = true
        end
    end

    if isSphere then
        local c = obj.Color
        if c.R > 0.5 and c.R > (c.G + 0.2) and c.R > (c.B + 0.2) then
            return true
        end
    end
    return false
end

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(0.2)
        if Config.RGBHighlight_Enabled then
            local rgbColor = Color3.fromHSV((tick() * 0.4) % 1, 1, 1)

            for _, obj in pairs(workspace:GetDescendants()) do
                if IsRedSphere(obj) then
                    local highlight = obj:FindFirstChildOfClass("Highlight")
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Adornee = obj
                        highlight.FillTransparency = 0.4
                        highlight.OutlineTransparency = 0
                        highlight.Parent = obj
                        table.insert(ActiveHighlights, highlight)
                    end
                    highlight.FillColor = rgbColor
                    highlight.OutlineColor = rgbColor
                end
            end
        else
            for _, highlight in pairs(ActiveHighlights) do
                if highlight then highlight:Destroy() end
            end
            ActiveHighlights = {}
        end
    end
end)

-- ==========================================
-- INK GAME: AUTO QTE PERFECT
-- ==========================================
local DELAY_OFFSET = 0.035 
local QTEKeyMap = {
    Q = Enum.KeyCode.Q,
    E = Enum.KeyCode.E,
    R = Enum.KeyCode.R,
    F = Enum.KeyCode.F
}
local ClickCooldown = false
local TrackedSizes = {}

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(0.01)

        if Config.AutoTiming_Enabled and not ClickCooldown then
            local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                for _, descendant in pairs(playerGui:GetDescendants()) do
                    if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
                        local text = string.upper(descendant.Text)

                        if QTEKeyMap[text] and descendant.Visible then
                            local parent = descendant.Parent
                            if not parent then continue end

                            local circles = {}
                            for _, child in pairs(parent:GetChildren()) do
                                if child:IsA("GuiObject") and child.Visible and child ~= descendant then
                                    table.insert(circles, child)
                                end
                            end

                            if #circles >= 2 then
                                table.sort(circles, function(a, b)
                                    return a.AbsoluteSize.X > b.AbsoluteSize.X
                                end)

                                local outerCircle = circles[1]
                                local targetCircle = circles[2]

                                local outerSize = outerCircle.AbsoluteSize.X
                                local targetSize = targetCircle.AbsoluteSize.X

                                local id = descendant:GetDebugId()

                                local lastSize = TrackedSizes[id] or outerSize
                                TrackedSizes[id] = outerSize

                                if lastSize > outerSize and outerSize <= (targetSize + 1) and outerSize >= (targetSize - 12) then
                                    ClickCooldown = true
                                    TrackedSizes[id] = nil

                                    if DELAY_OFFSET > 0 then
                                        task.wait(DELAY_OFFSET)
                                    end

                                    local keyToPress = QTEKeyMap[text]

                                    VirtualInputManager:SendKeyEvent(true, keyToPress, false, game)
                                    task.wait(0.02)
                                    VirtualInputManager:SendKeyEvent(false, keyToPress, false, game)

                                    task.delay(0.3, function()
                                        ClickCooldown = false
                                    end)

                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- TRAIL & PARTICLES
-- ==========================================
local currentTrail = nil
local currentAtt0, currentAtt1 = nil, nil
local currentParticle = nil

local function updateCustomFX()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not hrp then return end

    if currentTrail then currentTrail:Destroy() currentTrail = nil end
    if currentAtt0 then currentAtt0:Destroy() currentAtt0 = nil end
    if currentAtt1 then currentAtt1:Destroy() currentAtt1 = nil end
    if currentParticle then currentParticle:Destroy() currentParticle = nil end

    if Config.Trail_Enabled then
        currentAtt0 = Instance.new("Attachment", hrp)
        currentAtt0.Position = Vector3.new(0, 1, 0)
        currentAtt1 = Instance.new("Attachment", hrp)
        currentAtt1.Position = Vector3.new(0, -1, 0)

        currentTrail = Instance.new("Trail")
        currentTrail.Attachment0 = currentAtt0
        currentTrail.Attachment1 = currentAtt1
        currentTrail.Lifetime = 0.4
        
        if Config.Trail_Style == "Rainbow" then
            currentTrail.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
                ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255,255,0)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0,255,0)),
                ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0,255,255)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(0,0,255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,255))
            })
        else
            currentTrail.Color = ColorSequence.new(Config.Trail_Color, Config.Theme_Color2)
        end

        local tex = FX_Textures.Trails[Config.Trail_Style]
        if tex and tex ~= "" then currentTrail.Texture = tex end

        currentTrail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        })
        currentTrail.Parent = hrp
    end

    if Config.Particle_Enabled then
        currentParticle = Instance.new("ParticleEmitter")
        local pTexture = FX_Textures.Particles[Config.Particle_Style] or FX_Textures.Particles.Sparkles
        currentParticle.Texture = pTexture
        currentParticle.Rate = Config.Particle_Rate
        currentParticle.Speed = NumberRange.new(Config.Particle_Speed * 0.5, Config.Particle_Speed)
        currentParticle.Lifetime = NumberRange.new(0.5, 1.2)
        currentParticle.Color = ColorSequence.new(Config.Trail_Color, Config.Theme_Color1)
        currentParticle.Parent = hrp
    end
end

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.5)
    updateCustomFX()
end))

-- ==========================================
-- BUNNYHOP
-- ==========================================
local currentBhopSpeed = Config.Bhop_StartSpeed

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Config.Bhop_Enabled and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if hum and hrp then
            if hum.MoveDirection.Magnitude > 0 then
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    currentBhopSpeed = math.min(currentBhopSpeed + Config.Bhop_Accel, Config.Bhop_MaxSpeed)
                end
                
                local moveDirection = hum.MoveDirection.Unit
                hrp.AssemblyLinearVelocity = Vector3.new(
                    moveDirection.X * currentBhopSpeed,
                    hrp.AssemblyLinearVelocity.Y,
                    moveDirection.Z * currentBhopSpeed
                )
            else
                currentBhopSpeed = Config.Bhop_StartSpeed
            end
        end
    end
end))

-- ==========================================
-- ESP & TRACERS (ОПТИМИЗИРОВАНО ДЛЯ SOLARA)
-- ==========================================
local DrawingCache = {}
local DrawingAvailable = pcall(function() return Drawing and Drawing.new end) and Drawing ~= nil

local function removeTracer(userId)
    if DrawingCache[userId] then
        pcall(function() DrawingCache[userId]:Remove() end)
        DrawingCache[userId] = nil
    end
end

table.insert(Connections, Players.PlayerRemoving:Connect(function(player)
    removeTracer(player.UserId)
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                local hrp = char.HumanoidRootPart
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")

                -- Chams Highlight ESP
                if Config.ESP_Enabled then
                    local hl = char:FindFirstChild("DielinHL")
                    if not hl then
                        pcall(function()
                            hl = Instance.new("Highlight")
                            hl.Name = "DielinHL"
                            hl.Parent = char
                        end)
                    end
                    if hl then
                        hl.FillColor = Config.ESP_Color
                        hl.FillTransparency = Config.ESP_FillTransparency
                        hl.OutlineColor = Config.ESP_Color
                        hl.Enabled = true
                    end
                else
                    local hl = char:FindFirstChild("DielinHL")
                    if hl then hl:Destroy() end
                end

                -- NameTags
                if head and Config.NameTags_Enabled then
                    local tag = head:FindFirstChild("DielinTag")
                    if not tag then
                        tag = Instance.new("BillboardGui")
                        tag.Name = "DielinTag"
                        tag.Adornee = head
                        tag.Size = UDim2.new(0, 140, 0, 30)
                        tag.StudsOffset = Vector3.new(0, 2.5, 0)
                        tag.AlwaysOnTop = true
                        tag.Parent = head

                        local lbl = Instance.new("TextLabel")
                        lbl.Name = "Label"
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.TextColor3 = Config.NameTags_Color
                        lbl.TextStrokeTransparency = 0
                        lbl.Font = Config.Font_Main
                        lbl.TextSize = 11
                        lbl.Parent = tag
                    end
                    tag.Enabled = true

                    local lbl = tag:FindFirstChild("Label")
                    if lbl then
                        lbl.TextColor3 = Config.NameTags_Color
                        if hum and hrp and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude)
                            local textStr = player.DisplayName
                            if Config.NameTags_ShowHealth then textStr = textStr .. " [" .. math.floor(hum.Health) .. "HP]" end
                            if Config.NameTags_ShowDistance then textStr = textStr .. " (" .. dist .. "m)" end
                            lbl.Text = textStr
                        end
                    end
                else
                    if head then
                        local tag = head:FindFirstChild("DielinTag")
                        if tag then tag:Destroy() end
                    end
                end

                -- Tracers
                if Config.ESP_Tracers and DrawingAvailable then
                    if not DrawingCache[player.UserId] then
                        pcall(function()
                            local line = Drawing.new("Line")
                            line.Thickness = Config.Tracer_Thickness
                            line.Color = Config.ESP_Color
                            line.Transparency = 1
                            line.Visible = false
                            DrawingCache[player.UserId] = line
                        end)
                    end

                    local tracer = DrawingCache[player.UserId]
                    if tracer then
                        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            local startY = Camera.ViewportSize.Y
                            if Config.Tracer_Origin == "Center" then startY = Camera.ViewportSize.Y / 2
                            elseif Config.Tracer_Origin == "Top" then startY = 0 end

                            tracer.From = Vector2.new(Camera.ViewportSize.X / 2, startY)
                            tracer.To = Vector2.new(pos.X, pos.Y)
                            tracer.Color = Config.ESP_Color
                            tracer.Thickness = Config.Tracer_Thickness
                            tracer.Visible = true
                        else
                            tracer.Visible = false
                        end
                    end
                else
                    removeTracer(player.UserId)
                end
            else
                removeTracer(player.UserId)
            end
        end
    end
end))

-- ==========================================
-- FLY
-- ==========================================
local flyBodyVel, flyBodyGyro

table.insert(Connections, RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if Config.Fly_Enabled and char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        
        if not flyBodyVel or flyBodyVel.Parent ~= hrp then
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyBodyVel.Parent = hrp
        end

        if not flyBodyGyro or flyBodyGyro.Parent ~= hrp then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyBodyGyro.P = 9e4
            flyBodyGyro.Parent = hrp
        end

        flyBodyGyro.CFrame = Camera.CFrame
        local moveVector = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end

        flyBodyVel.Velocity = moveVector * Config.Fly_Speed
    else
        if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
        if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    end
end))

-- ==========================================
-- SHIFT SPRINT
-- ==========================================
local isShiftPressed = false

table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftPressed = true
    end
end))

table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        isShiftPressed = false
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChildOfClass("Humanoid") then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if Config.ShiftSprint_Enabled and isShiftPressed then
            hum.WalkSpeed = Config.SprintSpeed
        else
            hum.WalkSpeed = Config.WalkSpeed
        end
        hum.JumpPower = Config.JumpPower
    end
end))

-- ==========================================
-- ХИТБОКСЫ
-- ==========================================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = p.Character.HumanoidRootPart
            if Config.Hitbox_Enabled then
                hrp.Size = Vector3.new(Config.Hitbox_Size, Config.Hitbox_Size, Config.Hitbox_Size)
                hrp.Color = Config.Hitbox_Color
                hrp.Transparency = Config.Hitbox_Visible and Config.Hitbox_Transparency or 1
                hrp.Material = Config.Hitbox_Material
                hrp.CanCollide = false
            else
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end))

-- ==========================================
-- ПОГОДА
-- ==========================================
local function resetSky()
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Sky") or v:IsA("Atmosphere") or v.Name:find("Dielin") then v:Destroy() end
    end
end

local function applyWeatherTheme(type)
    resetSky()
    if type == "Sunset" then
        Lighting.ClockTime = 17.5
        local blur = Instance.new("BlurEffect", Lighting)
        blur.Name = "DielinBlur"
        blur.Size = 8
    elseif type == "Night" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.5
    elseif type == "Cyberpunk" then
        Lighting.ClockTime = 20
        Lighting.OutdoorAmbient = Color3.fromRGB(150, 0, 200)
    elseif type == "Matrix" then
        Lighting.ClockTime = 12
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 255, 100)
        Lighting.FogColor = Color3.fromRGB(0, 50, 20)
        Lighting.FogEnd = 200
    elseif type == "Foggy" then
        Lighting.FogColor = Color3.fromRGB(150, 150, 150)
        Lighting.FogEnd = 100
    elseif type == "Clear" then
        Lighting.ClockTime = 14
        Lighting.Ambient = Config.OriginalAmbient
        Lighting.OutdoorAmbient = Config.OriginalOutdoorAmbient
        Lighting.FogEnd = 100000
    end
end

-- ==========================================
-- НАПОЛНЕНИЕ ВКЛАДОК
-- ==========================================

-- COMBAT (AIMBOT + AUTO QTE)
createToggle(combatPage, "Enable Aimbot (Курсор)", "AimbotToggle", Config.Aimbot_Enabled, function(v) Config.Aimbot_Enabled = v end)
createSelector(combatPage, "Aimbot Target Part", {"Head", "HumanoidRootPart", "UpperTorso"}, 1, function(v) Config.Aimbot_Part = v end)
createToggle(combatPage, "Auto QTE Perfect (Anti-Early)", "AutoQTE", Config.AutoTiming_Enabled, function(v) Config.AutoTiming_Enabled = v end)

-- VISUALS (ESP + RGB RED SPHERES)
createToggle(visualPage, "Chams ESP", "ChamsESP", Config.ESP_Enabled, function(v) Config.ESP_Enabled = v end)
createToggle(visualPage, "RGB Red Spheres Highlight", "RGBHighlight", Config.RGBHighlight_Enabled, function(v) Config.RGBHighlight_Enabled = v end)
createToggle(visualPage, "Tracers (Линии)", "TracersESP", Config.ESP_Tracers, function(v) Config.ESP_Tracers = v end)
createSelector(visualPage, "Tracer Origin", {"Bottom", "Center", "Top"}, 1, function(v) Config.Tracer_Origin = v end)
createSlider(visualPage, "Tracer Thickness", 1, 5, Config.Tracer_Thickness, function(v) Config.Tracer_Thickness = v end)
createToggle(visualPage, "Enable NameTags", "NameTags", Config.NameTags_Enabled, function(v) Config.NameTags_Enabled = v end)
createToggle(visualPage, "Show Health in Tags", "ShowHP", Config.NameTags_ShowHealth, function(v) Config.NameTags_ShowHealth = v end)
createToggle(visualPage, "Show Distance in Tags", "ShowDist", Config.NameTags_ShowDistance, function(v) Config.NameTags_ShowDistance = v end)
createToggle(visualPage, "Fullbright (Без теней)", "Fullbright", Config.Fullbright_Enabled, function(v) 
    Config.Fullbright_Enabled = v 
    Lighting.Ambient = v and Color3.fromRGB(255,255,255) or Config.OriginalAmbient
end)
createToggle(visualPage, "Show FPS & Ping HUD", "ShowStatsHUD", Config.ShowStats, function(v) Config.ShowStats = v end)
createSlider(visualPage, "Field of View (FOV)", 70, 120, Config.FOV_Value, function(v) Camera.FieldOfView = v end)

-- MOVEMENT
createToggle(movePage, "Fly Mode (Полет)", "FlyToggle", Config.Fly_Enabled, function(v) Config.Fly_Enabled = v end)
createSlider(movePage, "Fly Speed (Скорость Полета)", 10, 200, Config.Fly_Speed, function(v) Config.Fly_Speed = v end)
createToggle(movePage, "Shift Sprint (Бег на Shift)", "ShiftSprintToggle", Config.ShiftSprint_Enabled, function(v) Config.ShiftSprint_Enabled = v end)
createSlider(movePage, "Sprint Speed (Скорость Shift)", 20, 150, Config.SprintSpeed, function(v) Config.SprintSpeed = v end)
createToggle(movePage, "Ghost / Invisible", "Invis", Config.Invisible_Enabled, function(v)
    Config.Invisible_Enabled = v
    if LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then p.Transparency = v and 1 or 0 end
        end
    end
end)
createToggle(movePage, "Noclip (Сквозь стены)", "Noclip", Config.Noclip_Enabled, function(v) Config.Noclip_Enabled = v end)
createToggle(movePage, "Infinite Jump", "InfJump", Config.InfJump_Enabled, function(v) Config.InfJump_Enabled = v end)
createToggle(movePage, "Auto BunnyHop (Без заносов)", "Bhop", Config.Bhop_Enabled, function(v) Config.Bhop_Enabled = v end)
createSlider(movePage, "Bhop Max Speed", 30, 250, Config.Bhop_MaxSpeed, function(v) Config.Bhop_MaxSpeed = v end)
createSlider(movePage, "Base WalkSpeed", 16, 250, Config.WalkSpeed, function(v) Config.WalkSpeed = v end)
createSlider(movePage, "Base JumpPower", 50, 300, Config.JumpPower, function(v) Config.JumpPower = v end)

-- HITBOX
createToggle(hitboxPage, "Enable Hitbox Expander", "HitboxExp", Config.Hitbox_Enabled, function(v) Config.Hitbox_Enabled = v end)
createToggle(hitboxPage, "Hitbox Visible (Видимость)", "HitboxVis", Config.Hitbox_Visible, function(v) Config.Hitbox_Visible = v end)
createSelector(hitboxPage, "Hitbox Material", {"Neon", "SmoothPlastic", "ForceField", "Glass"}, 1, function(v)
    if v == "Neon" then Config.Hitbox_Material = Enum.Material.Neon
    elseif v == "SmoothPlastic" then Config.Hitbox_Material = Enum.Material.SmoothPlastic
    elseif v == "ForceField" then Config.Hitbox_Material = Enum.Material.ForceField
    elseif v == "Glass" then Config.Hitbox_Material = Enum.Material.Glass end
end)
createSelector(hitboxPage, "Hitbox Color Preset", {"Red", "Green", "Blue", "Purple", "Cyan", "White"}, 1, function(v)
    if v == "Red" then Config.Hitbox_Color = Color3.fromRGB(255,0,0)
    elseif v == "Green" then Config.Hitbox_Color = Color3.fromRGB(0,255,100)
    elseif v == "Blue" then Config.Hitbox_Color = Color3.fromRGB(0,120,255)
    elseif v == "Purple" then Config.Hitbox_Color = Color3.fromRGB(170,0,255)
    elseif v == "Cyan" then Config.Hitbox_Color = Color3.fromRGB(0,255,255)
    elseif v == "White" then Config.Hitbox_Color = Color3.fromRGB(255,255,255) end
end)
createSlider(hitboxPage, "Hitbox Size", 2, 40, Config.Hitbox_Size, function(v) Config.Hitbox_Size = v end)
createSlider(hitboxPage, "Hitbox Transparency", 0, 1, Config.Hitbox_Transparency, function(v) Config.Hitbox_Transparency = v end)

-- FX CUSTOM
createToggle(customPage, "Enable Neon Trail", "TrailToggle", Config.Trail_Enabled, function(v) Config.Trail_Enabled = v updateCustomFX() end)
createSelector(customPage, "Trail Style", {"Neon Solid", "Rainbow", "Fire", "Lightning", "Cosmic"}, 1, function(v) Config.Trail_Style = v updateCustomFX() end)
createSelector(customPage, "Trail Color Preset", {"Purple", "Cyan", "Red", "Lime", "Gold"}, 1, function(v)
    if v == "Purple" then Config.Trail_Color = Color3.fromRGB(150, 0, 255)
    elseif v == "Cyan" then Config.Trail_Color = Color3.fromRGB(0, 230, 255)
    elseif v == "Red" then Config.Trail_Color = Color3.fromRGB(255, 30, 30)
    elseif v == "Lime" then Config.Trail_Color = Color3.fromRGB(50, 255, 50)
    elseif v == "Gold" then Config.Trail_Color = Color3.fromRGB(255, 215, 0) end
    updateCustomFX()
end)

createToggle(customPage, "Enable Particle Aura", "ParticleToggle", Config.Particle_Enabled, function(v) Config.Particle_Enabled = v updateCustomFX() end)
createSelector(customPage, "Particle Style", {"Sparkles", "Flames", "Hearts", "Snowflakes", "Electric", "Cash"}, 1, function(v) Config.Particle_Style = v updateCustomFX() end)
createSlider(customPage, "Particle Rate (Кол-во)", 5, 80, Config.Particle_Rate, function(v) Config.Particle_Rate = v updateCustomFX() end)
createSlider(customPage, "Particle Speed (Скорость)", 1, 15, Config.Particle_Speed, function(v) Config.Particle_Speed = v updateCustomFX() end)

-- UI THEME CUSTOMIZATION
createSelector(uiPage, "UI Color Theme", {"Purple Pink", "Cyber Neon", "Crimson Red", "Emerald Green", "Ice Blue", "Golden VIP"}, 1, function(v)
    if v == "Purple Pink" then
        Config.Theme_Color1 = Color3.fromRGB(130, 80, 255)
        Config.Theme_Color2 = Color3.fromRGB(255, 80, 180)
    elseif v == "Cyber Neon" then
        Config.Theme_Color1 = Color3.fromRGB(0, 230, 255)
        Config.Theme_Color2 = Color3.fromRGB(0, 255, 120)
    elseif v == "Crimson Red" then
        Config.Theme_Color1 = Color3.fromRGB(255, 30, 60)
        Config.Theme_Color2 = Color3.fromRGB(255, 120, 0)
    elseif v == "Emerald Green" then
        Config.Theme_Color1 = Color3.fromRGB(0, 220, 100)
        Config.Theme_Color2 = Color3.fromRGB(180, 255, 0)
    elseif v == "Ice Blue" then
        Config.Theme_Color1 = Color3.fromRGB(0, 150, 255)
        Config.Theme_Color2 = Color3.fromRGB(180, 230, 255)
    elseif v == "Golden VIP" then
        Config.Theme_Color1 = Color3.fromRGB(255, 215, 0)
        Config.Theme_Color2 = Color3.fromRGB(255, 120, 0)
    end
    
    local aliveGradients = {}
    for _, grad in ipairs(ThemedGradients) do
        if grad and grad.Parent then
            grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.Theme_Color1),
                ColorSequenceKeypoint.new(1, Config.Theme_Color2)
            })
            table.insert(aliveGradients, grad)
        end
    end
    ThemedGradients = aliveGradients
    StatsStroke.Color = Config.Theme_Color1
end)

-- WEATHER
createButton(weatherPage, "Clear Day (Ясный День)", "WeatherClear", function() applyWeatherTheme("Clear") end)
createButton(weatherPage, "Sunset + Blur (Закат)", "WeatherSunset", function() applyWeatherTheme("Sunset") end)
createButton(weatherPage, "Night Neon (Ночной Неон)", "WeatherNight", function() applyWeatherTheme("Night") end)
createButton(weatherPage, "Cyberpunk World (Фиолетовый)", "WeatherCyber", function() applyWeatherTheme("Cyberpunk") end)
createButton(weatherPage, "Matrix World (Зеленая Матрица)", "WeatherMatrix", function() applyWeatherTheme("Matrix") end)
createButton(weatherPage, "Silent Hill Fog (Туман)", "WeatherFog", function() applyWeatherTheme("Foggy") end)

-- ==========================================
-- VIP & TROLL FUNCTIONS (С ПОЛУПРОЗРАЧНЫМ ОВЕРЛЕЕМ)
-- ==========================================

local VipControlsFrame = Instance.new("Frame")
VipControlsFrame.Size = UDim2.new(1, 0, 0, 0)
VipControlsFrame.BackgroundTransparency = 1
VipControlsFrame.Parent = vipPage

local VipLayout = Instance.new("UIListLayout")
VipLayout.SortOrder = Enum.SortOrder.LayoutOrder
VipLayout.Padding = UDim.new(0, 8)
VipLayout.Parent = VipControlsFrame

VipLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    VipControlsFrame.Size = UDim2.new(1, 0, 0, VipLayout.AbsoluteContentSize.Y)
end)

createToggle(VipControlsFrame, "Click Teleport (Ctrl + Click)", "ClickTP", Config.ClickTP_Enabled, function(v) if Config.VIPUnlocked then Config.ClickTP_Enabled = v end end)
createToggle(VipControlsFrame, "Spinbot (Вращение)", "Spinbot", Config.Spin_Enabled, function(v) if Config.VIPUnlocked then Config.Spin_Enabled = v end end)
createSlider(VipControlsFrame, "Spin Speed", 5, 100, Config.Spin_Speed, function(v) if Config.VIPUnlocked then Config.Spin_Speed = v end end)
createToggle(VipControlsFrame, "Anti-AFK Protection", "AntiAFK", Config.AntiAFK_Enabled, function(v) if Config.VIPUnlocked then Config.AntiAFK_Enabled = v end end)

createToggle(VipControlsFrame, "1. Rainbow Character (Радужный)", "RainbowChar", Config.RainbowChar_Enabled, function(v) if Config.VIPUnlocked then Config.RainbowChar_Enabled = v end end)
createToggle(VipControlsFrame, "2. Drunk Camera (Пьяная Камера)", "DrunkCam", Config.DrunkCam_Enabled, function(v) if Config.VIPUnlocked then Config.DrunkCam_Enabled = v end end)
createToggle(VipControlsFrame, "3. Big Head (Огромные головы игроков)", "BigHead", Config.BigHead_Enabled, function(v) if Config.VIPUnlocked then Config.BigHead_Enabled = v end end)
createToggle(VipControlsFrame, "4. Screen Shake (Тряска экрана)", "ScreenShake", Config.ScreenShake_Enabled, function(v) if Config.VIPUnlocked then Config.ScreenShake_Enabled = v end end)
createToggle(VipControlsFrame, "5. Auto Clicker (Автокликер мыши)", "AutoClick", Config.AutoClick_Enabled, function(v) if Config.VIPUnlocked then Config.AutoClick_Enabled = v end end)
createToggle(VipControlsFrame, "6. Super Jump VIP (Супер-прыжок)", "SuperJump", Config.SuperJump_Enabled, function(v) if Config.VIPUnlocked then Config.SuperJump_Enabled = v end end)
createToggle(VipControlsFrame, "7. Fling Aura (Троллинг раскидыванием)", "FlingAura", Config.FlingAura_Enabled, function(v) if Config.VIPUnlocked then Config.FlingAura_Enabled = v end end)
createToggle(VipControlsFrame, "8. Ragdoll Mode (Падение в рэгдолл)", "Ragdoll", Config.Ragdoll_Enabled, function(v) if Config.VIPUnlocked then Config.Ragdoll_Enabled = v end end)
createToggle(VipControlsFrame, "9. Fake Chat Spam (Спам в чат)", "FakeChat", Config.FakeChat_Enabled, function(v) if Config.VIPUnlocked then Config.FakeChat_Enabled = v end end)
createToggle(VipControlsFrame, "10. Invisible Arms (Невидимые руки)", "InvisArms", Config.InvisibleArms_Enabled, function(v) if Config.VIPUnlocked then Config.InvisibleArms_Enabled = v end end)

-- ЧЕРНО-ПОЛУПРОЗРАЧНЫЙ ОВЕРЛЕЙ БЛОКИРОВКИ ВКЛАДКИ VIP
local PremiumLockOverlay = Instance.new("Frame")
PremiumLockOverlay.Size = UDim2.new(1, 0, 1, 0)
PremiumLockOverlay.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
PremiumLockOverlay.BackgroundTransparency = 0.35 -- Черно-прозрачный оверлей
PremiumLockOverlay.ZIndex = 5
PremiumLockOverlay.Parent = vipPage

local LockCenterCard = Instance.new("Frame")
LockCenterCard.Size = UDim2.new(0, 340, 0, 160)
LockCenterCard.Position = UDim2.new(0.5, -170, 0.5, -80)
LockCenterCard.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
LockCenterCard.ZIndex = 6
LockCenterCard.Parent = PremiumLockOverlay

local LockCardCorner = Instance.new("UICorner")
LockCardCorner.CornerRadius = UDim.new(0, 12)
LockCardCorner.Parent = LockCenterCard

local LockCardStroke = Instance.new("UIStroke")
LockCardStroke.Thickness = 2
LockCardStroke.Color = Color3.fromRGB(255, 215, 0)
LockCardStroke.Parent = LockCenterCard
addGradient(LockCardStroke, Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 230, 255), 45, false)

local LockIcon = Instance.new("TextLabel")
LockIcon.Size = UDim2.new(1, 0, 0, 35)
LockIcon.Position = UDim2.new(0, 0, 0, 12)
LockIcon.BackgroundTransparency = 1
LockIcon.Text = "🔒"
LockIcon.TextSize = 26
LockIcon.ZIndex = 7
LockIcon.Parent = LockCenterCard

local LockMsgTitle = Instance.new("TextLabel")
LockMsgTitle.Size = UDim2.new(1, 0, 0, 25)
LockMsgTitle.Position = UDim2.new(0, 0, 0, 48)
LockMsgTitle.BackgroundTransparency = 1
LockMsgTitle.Text = "Требуется Premium или Platinum!"
LockMsgTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
LockMsgTitle.Font = Config.Font_Main
LockMsgTitle.TextSize = 13
LockMsgTitle.ZIndex = 7
LockMsgTitle.Parent = LockCenterCard

local LockMsgSub = Instance.new("TextLabel")
LockMsgSub.Size = UDim2.new(1, -20, 0, 35)
LockMsgSub.Position = UDim2.new(0, 10, 0, 75)
LockMsgSub.BackgroundTransparency = 1
LockMsgSub.Text = "Функции видны для ознакомления. Для разблокировки необходима активная подписка Premium или Platinum."
LockMsgSub.TextColor3 = Color3.fromRGB(180, 185, 205)
LockMsgSub.Font = Config.Font_Main
LockMsgSub.TextSize = 10
LockMsgSub.TextWrapped = true
LockMsgSub.ZIndex = 7
LockMsgSub.Parent = LockCenterCard

local GoToSubBtn = Instance.new("TextButton")
GoToSubBtn.Size = UDim2.new(0, 180, 0, 30)
GoToSubBtn.Position = UDim2.new(0.5, -90, 0, 118)
GoToSubBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
GoToSubBtn.Text = "Получить подписку"
GoToSubBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
GoToSubBtn.Font = Config.Font_Main
GoToSubBtn.TextSize = 11
GoToSubBtn.ZIndex = 7
GoToSubBtn.Parent = LockCenterCard
local GoSubCorner = Instance.new("UICorner")
GoSubCorner.CornerRadius = UDim.new(0, 6)
GoSubCorner.Parent = GoToSubBtn
addGradient(GoToSubBtn, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 120, 0), 0, false)

-- ==========================================
-- СИСТЕМА ПОДПИСОК (UI И ЛОГИКА АКТИВАЦИИ)
-- ==========================================
local SubOverlay = Instance.new("Frame")
SubOverlay.Size = UDim2.new(1, -180, 1, 0)
SubOverlay.Position = UDim2.new(1, 0, 0, 0)
SubOverlay.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
SubOverlay.ZIndex = 10
SubOverlay.Visible = false
SubOverlay.Parent = MainFrame

local CloseSubBtn = Instance.new("TextButton")
CloseSubBtn.Size = UDim2.new(0, 30, 0, 30)
CloseSubBtn.Position = UDim2.new(1, -35, 0, 5)
CloseSubBtn.BackgroundTransparency = 1
CloseSubBtn.Text = "X"
CloseSubBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseSubBtn.Font = Enum.Font.GothamBold
CloseSubBtn.TextSize = 18
CloseSubBtn.ZIndex = 11
CloseSubBtn.Parent = SubOverlay

SubscribeBtn.MouseButton1Click:Connect(function()
    SubOverlay.Visible = true
    SubOverlay.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(SubOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 180, 0, 0)}):Play()
end)

GoToSubBtn.MouseButton1Click:Connect(function()
    SubOverlay.Visible = true
    SubOverlay.Position = UDim2.new(1, 0, 0, 0)
    TweenService:Create(SubOverlay, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 180, 0, 0)}):Play()
end)

CloseSubBtn.MouseButton1Click:Connect(function()
    local tw = TweenService:Create(SubOverlay, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Position = UDim2.new(1, 0, 0, 0)})
    tw:Play()
    tw.Completed:Connect(function()
        SubOverlay.Visible = false
    end)
end)

-- Карточка Premium
local PremCard = Instance.new("Frame")
PremCard.Size = UDim2.new(0, 220, 0, 80)
PremCard.Position = UDim2.new(0, 15, 0, 15)
PremCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PremCard.ZIndex = 10
PremCard.Parent = SubOverlay
local PremCorner = Instance.new("UICorner")
PremCorner.CornerRadius = UDim.new(0, 8)
PremCorner.Parent = PremCard
addGradient(PremCard, Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 140, 0), 45, false)

local PremTitle = Instance.new("TextLabel")
PremTitle.Size = UDim2.new(1, 0, 0, 20)
PremTitle.Position = UDim2.new(0, 0, 0, 10)
PremTitle.BackgroundTransparency = 1
PremTitle.Text = "Premium Status"
PremTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PremTitle.Font = Config.Font_Main
PremTitle.TextSize = 16
PremTitle.ZIndex = 11
PremTitle.Parent = PremCard

local PremPriceRUB = Instance.new("TextLabel")
PremPriceRUB.Size = UDim2.new(1, 0, 0, 15)
PremPriceRUB.Position = UDim2.new(0, 0, 0, 35)
PremPriceRUB.BackgroundTransparency = 1
PremPriceRUB.Text = "30 Рублей"
PremPriceRUB.TextColor3 = Color3.fromRGB(255, 255, 255)
PremPriceRUB.Font = Config.Font_Main
PremPriceRUB.TextSize = 14
PremPriceRUB.ZIndex = 11
PremPriceRUB.Parent = PremCard

local PremPriceUSD = Instance.new("TextLabel")
PremPriceUSD.Size = UDim2.new(1, 0, 0, 15)
PremPriceUSD.Position = UDim2.new(0, 0, 0, 55)
PremPriceUSD.BackgroundTransparency = 1
PremPriceUSD.Text = "~ 0.33 USD"
PremPriceUSD.TextColor3 = Color3.fromRGB(240, 240, 240)
PremPriceUSD.Font = Config.Font_Main
PremPriceUSD.TextSize = 12
PremPriceUSD.ZIndex = 11
PremPriceUSD.Parent = PremCard

-- Карточка Platinum
local PlatCard = Instance.new("Frame")
PlatCard.Size = UDim2.new(0, 220, 0, 80)
PlatCard.Position = UDim2.new(0, 245, 0, 15)
PlatCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PlatCard.ZIndex = 10
PlatCard.Parent = SubOverlay
local PlatCorner = Instance.new("UICorner")
PlatCorner.CornerRadius = UDim.new(0, 8)
PlatCorner.Parent = PlatCard
addGradient(PlatCard, Color3.fromRGB(200, 230, 255), Color3.fromRGB(255, 180, 255), 45, false)

local PlatTitle = Instance.new("TextLabel")
PlatTitle.Size = UDim2.new(1, 0, 0, 20)
PlatTitle.Position = UDim2.new(0, 0, 0, 10)
PlatTitle.BackgroundTransparency = 1
PlatTitle.Text = "Platinum Status"
PlatTitle.TextColor3 = Color3.fromRGB(50, 50, 100)
PlatTitle.Font = Config.Font_Main
PlatTitle.TextSize = 16
PlatTitle.ZIndex = 11
PlatTitle.Parent = PlatCard

local PlatPriceRUB = Instance.new("TextLabel")
PlatPriceRUB.Size = UDim2.new(1, 0, 0, 15)
PlatPriceRUB.Position = UDim2.new(0, 0, 0, 35)
PlatPriceRUB.BackgroundTransparency = 1
PlatPriceRUB.Text = "69 Руб. (Скидка! Без: 119 Руб.)"
PlatPriceRUB.TextColor3 = Color3.fromRGB(50, 50, 100)
PlatPriceRUB.Font = Config.Font_Main
PlatPriceRUB.TextSize = 12
PlatPriceRUB.ZIndex = 11
PlatPriceRUB.Parent = PlatCard

local PlatPriceUSD = Instance.new("TextLabel")
PlatPriceUSD.Size = UDim2.new(1, 0, 0, 15)
PlatPriceUSD.Position = UDim2.new(0, 0, 0, 55)
PlatPriceUSD.BackgroundTransparency = 1
PlatPriceUSD.Text = "~ 0.76 USD (Без: 1.32 USD)"
PlatPriceUSD.TextColor3 = Color3.fromRGB(80, 80, 130)
PlatPriceUSD.Font = Config.Font_Main
PlatPriceUSD.TextSize = 11
PlatPriceUSD.ZIndex = 11
PlatPriceUSD.Parent = PlatCard

-- Поле и кнопка активации
local ActTitle = Instance.new("TextLabel")
ActTitle.Size = UDim2.new(1, 0, 0, 20)
ActTitle.Position = UDim2.new(0, 0, 0, 130)
ActTitle.BackgroundTransparency = 1
ActTitle.Text = "Активировать подписку"
ActTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ActTitle.Font = Config.Font_Main
ActTitle.TextSize = 16
ActTitle.ZIndex = 11
ActTitle.Parent = SubOverlay

local SubPromoBox = Instance.new("TextBox")
SubPromoBox.Size = UDim2.new(0, 250, 0, 35)
SubPromoBox.Position = UDim2.new(0.5, -125, 0, 160)
SubPromoBox.BackgroundColor3 = Color3.fromRGB(30, 33, 48)
SubPromoBox.PlaceholderText = "Введите промокод..."
SubPromoBox.Text = ""
SubPromoBox.TextColor3 = Color3.fromRGB(255, 255, 255)
SubPromoBox.Font = Config.Font_Main
SubPromoBox.TextSize = 14
SubPromoBox.ZIndex = 11
SubPromoBox.Parent = SubOverlay
local SubBoxCorner = Instance.new("UICorner")
SubBoxCorner.CornerRadius = UDim.new(0, 6)
SubBoxCorner.Parent = SubPromoBox

local SubApplyBtn = Instance.new("TextButton")
SubApplyBtn.Size = UDim2.new(0, 150, 0, 35)
SubApplyBtn.Position = UDim2.new(0.5, -75, 0, 205)
SubApplyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SubApplyBtn.Text = "Активировать"
SubApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SubApplyBtn.Font = Config.Font_Main
SubApplyBtn.TextSize = 14
SubApplyBtn.ZIndex = 11
SubApplyBtn.Parent = SubOverlay
local SubApplyCorner = Instance.new("UICorner")
SubApplyCorner.CornerRadius = UDim.new(0, 6)
SubApplyCorner.Parent = SubApplyBtn
addGradient(SubApplyBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)

local SubStatusMsg = Instance.new("TextLabel")
SubStatusMsg.Size = UDim2.new(1, -40, 0, 40)
SubStatusMsg.Position = UDim2.new(0, 20, 0, 250)
SubStatusMsg.BackgroundTransparency = 1
SubStatusMsg.Text = ""
SubStatusMsg.TextColor3 = Color3.fromRGB(0, 255, 100)
SubStatusMsg.Font = Config.Font_Main
SubStatusMsg.TextSize = 12
SubStatusMsg.TextWrapped = true
SubStatusMsg.Visible = false
SubStatusMsg.ZIndex = 11
SubStatusMsg.Parent = SubOverlay

-- Ссылка для покупки
local LinkBox = Instance.new("TextBox")
LinkBox.Size = UDim2.new(1, -40, 0, 30)
LinkBox.Position = UDim2.new(0, 20, 1, -50)
LinkBox.BackgroundTransparency = 1
LinkBox.Text = "Купить подписку - https://funpay.com/users/8853022/"
LinkBox.TextColor3 = Color3.fromRGB(150, 155, 175)
LinkBox.Font = Config.Font_Main
LinkBox.TextSize = 12
LinkBox.ClearTextOnFocus = false
LinkBox.TextEditable = false
LinkBox.ZIndex = 11
LinkBox.Parent = SubOverlay

-- Логика проверки подписки
SubApplyBtn.MouseButton1Click:Connect(function()
    local code = SubPromoBox.Text
    if code == "Dielin123" then
        -- Звук активации Premium 17161225362
        playSound(17161225362)

        SubStatusMsg.Text = 'Поздравляем с покупкой "Premium Status" вам теперь доступны новые функции.'
        SubStatusMsg.TextColor3 = Color3.fromRGB(255, 215, 0)
        SubStatusMsg.Visible = true
        Config.VIPUnlocked = true
        BadgeLabel.Text = "Premium Status"
        BadgeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        
        TweenService:Create(PremiumLockOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(LockCenterCard, TweenInfo.new(0.4), {Size = UDim2.new(0, 0, 0, 0), Position = LockCenterCard.Position + UDim2.new(0, 170, 0, 80)}):Play()
        task.wait(0.4)
        PremiumLockOverlay.Visible = false

    elseif code == "Dielin12345" then
        -- Звук активации Platinum 127675253015979
        playSound(127675253015979)

        SubStatusMsg.Text = 'Поздравляем с покупкой "Platinum Status" вам теперь доступны новые функции.'
        SubStatusMsg.TextColor3 = Color3.fromRGB(200, 230, 255)
        SubStatusMsg.Visible = true
        Config.VIPUnlocked = true
        BadgeLabel.Text = "Platinum Status"
        BadgeLabel.TextColor3 = Color3.fromRGB(200, 230, 255)
        
        TweenService:Create(PremiumLockOverlay, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
        TweenService:Create(LockCenterCard, TweenInfo.new(0.4), {Size = UDim2.new(0, 0, 0, 0), Position = LockCenterCard.Position + UDim2.new(0, 170, 0, 80)}):Play()
        task.wait(0.4)
        PremiumLockOverlay.Visible = false

    else
        -- Звук неверного промокода 106796270505945
        playSound(106796270505945)

        SubStatusMsg.Text = "Неверный промокод!"
        SubStatusMsg.TextColor3 = Color3.fromRGB(255, 80, 80)
        SubStatusMsg.Visible = true
    end
end)

-- ==========================================
-- ИГРОВЫЕ ЦИКЛЫ ДЛЯ ТРОЛЛИНГА
-- ==========================================
table.insert(Connections, RunService.RenderStepped:Connect(function()
    if Config.VIPUnlocked then
        if Config.RainbowChar_Enabled and LocalPlayer.Character then
            local hue = tick() % 5 / 5
            local col = Color3.fromHSV(hue, 1, 1)
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p:IsA("BasePart") then p.Color = col end
            end
        end

        if Config.DrunkCam_Enabled then
            Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.sin(tick() * 4) * 0.015)
        end

        if Config.BigHead_Enabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                    p.Character.Head.Size = Vector3.new(4, 4, 4)
                end
            end
        end

        if Config.ScreenShake_Enabled then
            Camera.CFrame = Camera.CFrame * CFrame.new(math.random(-8, 8)/400, math.random(-8, 8)/400, 0)
        end

        if Config.SuperJump_Enabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = 150 end
        end

        if Config.Ragdoll_Enabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand = true end
        end

        if Config.InvisibleArms_Enabled and LocalPlayer.Character then
            for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
                if p.Name == "Left Arm" or p.Name == "Right Arm" or p.Name == "LeftHand" or p.Name == "RightHand" then
                    p.Transparency = 1
                end
            end
        end
    end
end))

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(0.08)
        if Config.VIPUnlocked and Config.AutoClick_Enabled then
            pcall(function()
                if mouse1click then
                    mouse1click()
                else
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                end
            end)
        end
    end
end)

table.insert(Connections, RunService.Heartbeat:Connect(function()
    if Config.VIPUnlocked and Config.FlingAura_Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.new(math.random(-300, 300), 4000, math.random(-300, 300))
    end
end))

task.spawn(function()
    while ScreenGui and ScreenGui.Parent do
        task.wait(6)
        if Config.VIPUnlocked and Config.FakeChat_Enabled then
            pcall(function()
                local args = { [1] = "dielin's Hub VIP Troll Activated! 😎", [2] = "All" }
                game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents"):FindFirstChild("SayMessageRequest"):FireServer(unpack(args))
            end)
        end
    end
end)

-- ==========================================
-- TELEPORT TAB
-- ==========================================
local function populateTeleportTab()
    for _, child in ipairs(tpPage:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end

    local RefBtn = Instance.new("TextButton")
    RefBtn.Size = UDim2.new(1, -6, 0, 32)
    RefBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    RefBtn.Text = "Refresh Player List"
    RefBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    RefBtn.Font = Config.Font_Main
    RefBtn.TextSize = 12
    RefBtn.Parent = tpPage

    local RefCorner = Instance.new("UICorner")
    RefCorner.CornerRadius = UDim.new(0, 8)
    RefCorner.Parent = RefBtn
    addGradient(RefBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)

    RefBtn.MouseButton1Click:Connect(populateTeleportTab)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local PFrame = Instance.new("Frame")
            PFrame.Size = UDim2.new(1, -6, 0, 42)
            PFrame.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
            PFrame.Parent = tpPage

            local PCorner = Instance.new("UICorner")
            PCorner.CornerRadius = UDim.new(0, 8)
            PCorner.Parent = PFrame

            local PName = Instance.new("TextLabel")
            PName.Size = UDim2.new(0.6, 0, 1, 0)
            PName.Position = UDim2.new(0, 10, 0, 0)
            PName.BackgroundTransparency = 1
            PName.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            PName.TextColor3 = Color3.fromRGB(230, 230, 240)
            PName.Font = Config.Font_Main
            PName.TextSize = 11
            PName.TextXAlignment = Enum.TextXAlignment.Left
            PName.Parent = PFrame

            local TPBtn = Instance.new("TextButton")
            TPBtn.Size = UDim2.new(0, 80, 0, 24)
            TPBtn.Position = UDim2.new(1, -88, 0.5, -12)
            TPBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TPBtn.Text = "Teleport"
            TPBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            TPBtn.Font = Config.Font_Main
            TPBtn.TextSize = 10
            TPBtn.Parent = PFrame

            local TPCorner = Instance.new("UICorner")
            TPCorner.CornerRadius = UDim.new(0, 6)
            TPCorner.Parent = TPBtn
            addGradient(TPBtn, Config.Theme_Color1, Config.Theme_Color2, 0, true)

            TPBtn.MouseButton1Click:Connect(function()
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                end
            end)
        end
    end
end

populateTeleportTab()

-- ==========================================
-- ВСПОМОГАТЕЛЬНЫЕ ЦИКЛЫ И МЕХАНИКИ
-- ==========================================
table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if Config.VIPUnlocked and Config.ClickTP_Enabled and input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local mouse = LocalPlayer:GetMouse()
        if mouse and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end))

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if Config.InfJump_Enabled and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and Config.Spin_Enabled then
        char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Config.Spin_Speed), 0)
    end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    if Config.Noclip_Enabled and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end))

local menuOpen = true
ToggleButton.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    if menuOpen then
        MainFrame.Visible = true
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 670, 0, 480)}):Play()
    else
        local tw = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
        tw:Play()
        tw.Completed:Connect(function()
            if not menuOpen then MainFrame.Visible = false end
        end)
    end
end)

-- ==========================================
-- ПОЛНОЕ ОТКЛЮЧЕНИЕ / ОЧИСТКА СКРИПТА
-- ==========================================
local function UnloadScript()
    -- 1. Отключение всех Listeners & RenderStepped циклов
    for _, conn in ipairs(Connections) do
        if conn and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    Connections = {}

    -- 2. Очистка ESP, Drawings и Highlight
    for uId, tracer in pairs(DrawingCache) do
        pcall(function() tracer:Remove() end)
    end
    DrawingCache = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then
            local hl = player.Character:FindFirstChild("DielinHL")
            if hl then hl:Destroy() end
            
            if player.Character:FindFirstChild("Head") then
                local tag = player.Character.Head:FindFirstChild("DielinTag")
                if tag then tag:Destroy() end
            end

            if player ~= LocalPlayer and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end

    -- 3. Очистка кастомных эффектов FX
    if currentTrail then currentTrail:Destroy() end
    if currentAtt0 then currentAtt0:Destroy() end
    if currentAtt1 then currentAtt1:Destroy() end
    if currentParticle then currentParticle:Destroy() end

    -- 4. Сброс настроек освещения
    pcall(function()
        Lighting.Ambient = Config.OriginalAmbient
        Lighting.OutdoorAmbient = Config.OriginalOutdoorAmbient
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        resetSky()
    end)

    -- 5. Восстановление свойств локального игрока
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
            hum.PlatformStand = false
        end

        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.Transparency = 0
            end
        end
    end

    -- 6. Удаление всех интерфейсов
    pcall(function() ScreenGui:Destroy() end)
end

FullCloseBtn.MouseButton1Click:Connect(function()
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    TweenService:Create(MainFrame, tweenInfo, {Size = UDim2.new(0, 0, 0, 0), Position = MainFrame.Position + UDim2.new(0, 335, 0, 240)}):Play()
    task.wait(0.3)
    UnloadScript()
end)
