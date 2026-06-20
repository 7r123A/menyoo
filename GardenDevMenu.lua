local Players                = game:GetService("Players")
local TweenService           = game:GetService("TweenService")
local UserInputService       = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService             = game:GetService("RunService")

local player    = Players.LocalPlayer
local character = player.Character
local rootPart  = character and character:FindFirstChild("HumanoidRootPart") or nil

local function onCharacter(c)
    character = c
    task.spawn(function()
        rootPart = c:WaitForChild("HumanoidRootPart", 10)
    end)
end

if not character then
    task.spawn(function()
        character = player.CharacterAdded:Wait()
        onCharacter(character)
    end)
end
player.CharacterAdded:Connect(onCharacter)

local T = {
    Green     = Color3.fromRGB(50,  200, 100),
    DarkGreen = Color3.fromRGB(30,  150,  70),
    Blue      = Color3.fromRGB(60,  100, 220),
    Red       = Color3.fromRGB(220,  70,  70),
    RedHover  = Color3.fromRGB(255,  80,  80),
    Bg        = Color3.fromRGB(18,   18,  18),
    Card      = Color3.fromRGB(28,   28,  28),
    CardHover = Color3.fromRGB(42,   42,  42),
    Text      = Color3.fromRGB(240, 240, 240),
    Sub       = Color3.fromRGB(150, 150, 150),
    White     = Color3.fromRGB(255, 255, 255),
}

local function corner(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 10)
end

local function stroke(p, color, thick)
    local s = Instance.new("UIStroke", p)
    s.Color     = color or T.Green
    s.Thickness = thick or 1.5
end

local function tw(obj, props, t, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        t or 0.2,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function getPos(obj)
    if not obj or not obj.Parent then return nil end
    local ok, r = pcall(function()
        if obj:IsA("Model") then
            if obj.PrimaryPart then return obj.PrimaryPart.Position end
            local cf = obj:GetBoundingBox()
            return cf.Position
        end
        if obj:IsA("BasePart") then return obj.Position end
    end)
    return ok and r or nil
end

local function triggerPP(pp)
    if not pp or not pp.Parent then return end
    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(pp)
        else
            ProximityPromptService:TriggerPrompt(pp)
        end
    end)
end

local function findAllCrops()
    local results, seen = {}, {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local at = obj.ActionText:lower()
            if at:find("harvest") or at:find("collect") or at:find("pick") then
                local target = obj.Parent
                if not target then continue end
                if target:IsA("BasePart") and target.Parent
                   and (target.Parent:IsA("Model") or target.Parent:IsA("Folder")) then
                    target = target.Parent
                end
                if not seen[target] then
                    seen[target] = true
                    local dn = (obj.ObjectText ~= "" and obj.ObjectText) or target.Name
                    table.insert(results, {obj=target, name=dn, pp=obj})
                end
            end
        end
    end
    return results
end

local function collectOne(entry)
    if not entry.obj or not entry.obj.Parent then return end
    local p = getPos(entry.obj)
    if not p then return end
    if not rootPart then return end
    rootPart.CFrame = CFrame.new(p + Vector3.new(0, 3.5, 0))
    task.wait(0.3)
    if not entry.obj.Parent then return end
    triggerPP(entry.pp)
    task.wait(0.15)
    if entry.pp and entry.pp.Parent then triggerPP(entry.pp) end
end

local speedOn  = false
local speedVal = 50
local function applySpeed(v)
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end)
end
player.CharacterAdded:Connect(function(c)
    if not speedOn then return end
    task.wait(0.5)
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speedVal end
end)

local afkOn     = false
local afkThread = nil
local function startAntiAfk()
    afkThread = task.spawn(function()
        while afkOn do
            task.wait(55)
            if not afkOn then break end
            pcall(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
    end)
end

local noclipOn = false
RunService.Stepped:Connect(function()
    if not noclipOn or not player.Character then return end
    for _, p in ipairs(player.Character:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local flyOn   = false
local flyBV, flyBG, flyConn
local function stopFly()
    flyOn = false
    if flyBV   then flyBV:Destroy();       flyBV   = nil end
    if flyBG   then flyBG:Destroy();       flyBG   = nil end
    if flyConn then flyConn:Disconnect();  flyConn = nil end
    pcall(function()
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
    end)
end
local function startFly()
    local hrp = rootPart or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Parent   = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P         = 1e9
    flyBG.Parent    = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyOn then stopFly(); return end
        local cam = workspace.CurrentCamera
        local spd = 55
        local vx, vy, vz = 0, 0, 0
        local lv = cam.CFrame.LookVector
        local rv = cam.CFrame.RightVector
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then vx = vx + lv.X*spd; vy = vy + lv.Y*spd; vz = vz + lv.Z*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then vx = vx - lv.X*spd; vy = vy - lv.Y*spd; vz = vz - lv.Z*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then vx = vx - rv.X*spd; vy = vy - rv.Y*spd; vz = vz - rv.Z*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then vx = vx + rv.X*spd; vy = vy + rv.Y*spd; vz = vz + rv.Z*spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then vy = vy + spd end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vy = vy - spd end
        if flyBV then flyBV.Velocity = Vector3.new(vx, vy, vz) end
        if flyBG then flyBG.CFrame   = cam.CFrame end
    end)
end

local function teleportToShop()
    local kw = {"shop","store","merchant","vendor","market","seed"}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local at = obj.ActionText:lower()
            for _, k in ipairs(kw) do
                if at:find(k, 1, true) then
                    local p = getPos(obj.Parent)
                    if p and rootPart then
                        rootPart.CFrame = CFrame.new(p + Vector3.new(0, 6, 0))
                        return true
                    end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            for _, k in ipairs(kw) do
                if obj.Name:lower():find(k, 1, true) then
                    local p = getPos(obj)
                    if p and rootPart then
                        rootPart.CFrame = CFrame.new(p + Vector3.new(0, 6, 0))
                        return true
                    end
                end
            end
        end
    end
    return false
end

local old = player.PlayerGui:FindFirstChild("GardenDevMenu")
if old then old:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name           = "GardenDevMenu"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.IgnoreGuiInset = true
Gui.Parent         = player.PlayerGui

local ToggleBtn = Instance.new("TextButton", Gui)
ToggleBtn.Size             = UDim2.new(0, 118, 0, 38)
ToggleBtn.Position         = UDim2.new(0, 12, 0.5, -19)
ToggleBtn.BackgroundColor3 = T.Bg
ToggleBtn.BorderSizePixel  = 0
ToggleBtn.Text             = "🌿  Dev Menu"
ToggleBtn.TextColor3       = T.Green
ToggleBtn.Font             = Enum.Font.GothamBold
ToggleBtn.TextSize         = 14
ToggleBtn.AutoButtonColor  = false
ToggleBtn.ZIndex           = 10
corner(ToggleBtn, 10)
stroke(ToggleBtn, T.Green, 1.5)
ToggleBtn.MouseEnter:Connect(function() tw(ToggleBtn, {BackgroundColor3 = T.Card}, 0.1) end)
ToggleBtn.MouseLeave:Connect(function() tw(ToggleBtn, {BackgroundColor3 = T.Bg},   0.1) end)

local PH, PW = 530, 300

local Panel = Instance.new("Frame", Gui)
Panel.Name              = "Panel"
Panel.Size              = UDim2.new(0, 0, 0, PH)
Panel.Position          = UDim2.new(0.5, -PW/2, 0.5, -PH/2)
Panel.BackgroundColor3  = T.Bg
Panel.BorderSizePixel   = 0
Panel.ClipsDescendants  = true
Panel.Visible           = false
Panel.ZIndex            = 5
corner(Panel, 14)
stroke(Panel, T.Green, 1.5)

local Header = Instance.new("Frame", Panel)
Header.Size             = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = T.Green
Header.BorderSizePixel  = 0
Header.ZIndex           = 6
corner(Header, 14)

local HFix = Instance.new("Frame", Header)
HFix.Size             = UDim2.new(1, 0, 0.5, 0)
HFix.Position         = UDim2.new(0, 0, 0.5, 0)
HFix.BackgroundColor3 = T.Green
HFix.BorderSizePixel  = 0
HFix.ZIndex           = 6

local TitleLbl = Instance.new("TextLabel", Header)
TitleLbl.Size                   = UDim2.new(1, -50, 1, 0)
TitleLbl.Position               = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                   = "🌱  Garden Dev Menu"
TitleLbl.TextColor3             = T.White
TitleLbl.Font                   = Enum.Font.GothamBold
TitleLbl.TextSize               = 15
TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
TitleLbl.ZIndex                 = 7

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size             = UDim2.new(0, 26, 0, 26)
CloseBtn.Position         = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundColor3 = T.Red
CloseBtn.BorderSizePixel  = 0
CloseBtn.Text             = "X"
CloseBtn.TextColor3       = T.White
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.AutoButtonColor  = false
CloseBtn.ZIndex           = 8
corner(CloseBtn, 6)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {BackgroundColor3 = T.RedHover}, 0.1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {BackgroundColor3 = T.Red},      0.1) end)

do
    local dragging  = false
    local dragStart = Vector3.new(0, 0, 0)
    local startPos  = UDim2.new(0, 0, 0, 0)
    Header.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = Panel.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
           inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = inp.Position - dragStart
        Panel.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
           inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local TabBar = Instance.new("Frame", Panel)
TabBar.Size             = UDim2.new(1, -16, 0, 34)
TabBar.Position         = UDim2.new(0, 8, 0, 56)
TabBar.BackgroundColor3 = T.Card
TabBar.BorderSizePixel  = 0
TabBar.ZIndex           = 6
corner(TabBar, 8)

local function makeTab(text, xScale)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size             = UDim2.new(0.5, -6, 1, -8)
    btn.Position         = UDim2.new(xScale, 4, 0, 4)
    btn.BackgroundColor3 = T.Bg
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = T.Sub
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    btn.ZIndex           = 7
    corner(btn, 6)
    return btn
end

local CropsTab = makeTab("🌾  Crops", 0)
local ToolsTab = makeTab("⚡  Tools", 0.5)

local CropsContent = Instance.new("Frame", Panel)
CropsContent.Size                   = UDim2.new(1, 0, 0, PH - 98)
CropsContent.Position               = UDim2.new(0, 0, 0, 98)
CropsContent.BackgroundTransparency = 1
CropsContent.BorderSizePixel        = 0
CropsContent.ZIndex                 = 5

local StatsBar = Instance.new("Frame", CropsContent)
StatsBar.Size             = UDim2.new(1, -16, 0, 30)
StatsBar.Position         = UDim2.new(0, 8, 0, 0)
StatsBar.BackgroundColor3 = T.Card
StatsBar.BorderSizePixel  = 0
StatsBar.ZIndex           = 6
corner(StatsBar, 8)

local StatsLbl = Instance.new("TextLabel", StatsBar)
StatsLbl.Size                   = UDim2.new(1, -10, 1, 0)
StatsLbl.Position               = UDim2.new(0, 8, 0, 0)
StatsLbl.BackgroundTransparency = 1
StatsLbl.Text                   = "Press Refresh to search..."
StatsLbl.TextColor3             = T.Sub
StatsLbl.Font                   = Enum.Font.Gotham
StatsLbl.TextSize               = 12
StatsLbl.TextXAlignment         = Enum.TextXAlignment.Left
StatsLbl.ZIndex                 = 7

local CropScroll = Instance.new("ScrollingFrame", CropsContent)
CropScroll.Size                   = UDim2.new(1, -16, 0, 282)
CropScroll.Position               = UDim2.new(0, 8, 0, 38)
CropScroll.BackgroundTransparency = 1
CropScroll.BorderSizePixel        = 0
CropScroll.ScrollBarThickness     = 4
CropScroll.ScrollBarImageColor3   = T.Green
CropScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
CropScroll.ZIndex                 = 6

local CropListLayout = Instance.new("UIListLayout", CropScroll)
CropListLayout.Padding   = UDim.new(0, 4)
CropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
CropListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CropScroll.CanvasSize = UDim2.new(0, 0, 0, CropListLayout.AbsoluteContentSize.Y + 8)
end)

local cropPad = Instance.new("UIPadding", CropScroll)
cropPad.PaddingTop    = UDim.new(0, 4)
cropPad.PaddingBottom = UDim.new(0, 4)

local function makeCropBtn(text, color, yAbs)
    local btn = Instance.new("TextButton", CropsContent)
    btn.Size             = UDim2.new(1, -16, 0, 34)
    btn.Position         = UDim2.new(0, 8, 0, yAbs)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = T.White
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    btn.ZIndex           = 7
    corner(btn, 8)
    return btn
end

local CollectAllBtn = makeCropBtn("🍎  Collect All",   T.Green, 328)
local AutoBtn       = makeCropBtn("⚡  Auto: OFF",      T.Card,  370)
local RefreshBtn    = makeCropBtn("🔄  Refresh List",   T.Blue,  412)

for _, info in ipairs({{CollectAllBtn, T.Green}, {RefreshBtn, T.Blue}}) do
    local btn, clr = info[1], info[2]
    btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = clr:Lerp(T.White, 0.13)}, 0.12) end)
    btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = clr}, 0.12) end)
end

local autoBaseColor = T.Card
AutoBtn.MouseEnter:Connect(function() tw(AutoBtn, {BackgroundColor3 = autoBaseColor:Lerp(T.White, 0.13)}, 0.12) end)
AutoBtn.MouseLeave:Connect(function() tw(AutoBtn, {BackgroundColor3 = autoBaseColor}, 0.12) end)

local ToolsContent = Instance.new("Frame", Panel)
ToolsContent.Size                   = UDim2.new(1, 0, 0, PH - 98)
ToolsContent.Position               = UDim2.new(0, 0, 0, 98)
ToolsContent.BackgroundTransparency = 1
ToolsContent.BorderSizePixel        = 0
ToolsContent.ZIndex                 = 5
ToolsContent.Visible                = false

local function makeToolBtn(text, color, yAbs)
    local btn = Instance.new("TextButton", ToolsContent)
    btn.Size             = UDim2.new(1, -16, 0, 52)
    btn.Position         = UDim2.new(0, 8, 0, yAbs)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = T.White
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 14
    btn.AutoButtonColor  = false
    btn.ZIndex           = 7
    corner(btn, 10)
    return btn
end

local SpeedBtn  = makeToolBtn("🏃  Speed: OFF",       Color3.fromRGB(100, 60, 180),  10)
local AfkBtn    = makeToolBtn("💤  Anti-AFK: OFF",    Color3.fromRGB(60, 130, 180),  72)
local NoclipBtn = makeToolBtn("👻  NoClip: OFF",      Color3.fromRGB(120, 90, 30),   134)
local FlyBtn    = makeToolBtn("🦋  Fly: OFF",         Color3.fromRGB(60, 90, 180),   196)
local TpShopBtn = makeToolBtn("🏪  Teleport to Shop", T.Blue,                        258)

local function setTab(tab)
    if tab == "crops" then
        CropsContent.Visible = true
        ToolsContent.Visible = false
        tw(CropsTab, {BackgroundColor3 = T.Green}, 0.15); CropsTab.TextColor3 = T.White
        tw(ToolsTab,  {BackgroundColor3 = T.Bg},   0.15); ToolsTab.TextColor3  = T.Sub
    else
        CropsContent.Visible = false
        ToolsContent.Visible = true
        tw(ToolsTab,  {BackgroundColor3 = T.Green}, 0.15); ToolsTab.TextColor3  = T.White
        tw(CropsTab,  {BackgroundColor3 = T.Bg},   0.15); CropsTab.TextColor3  = T.Sub
    end
end

CropsTab.MouseButton1Click:Connect(function() setTab("crops") end)
ToolsTab.MouseButton1Click:Connect(function()  setTab("tools") end)

local function makeCropCard(entry, idx)
    local obj  = entry.obj
    local pos  = getPos(obj)
    local dist = (pos and rootPart) and math.floor((rootPart.Position - pos).Magnitude) or 0

    local card = Instance.new("Frame", CropScroll)
    card.Size             = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel  = 0
    card.LayoutOrder      = idx
    card.ZIndex           = 7
    corner(card, 8)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size                   = UDim2.new(1, -84, 0, 22)
    nameLbl.Position               = UDim2.new(0, 10, 0, 5)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = "🌿 " .. entry.name
    nameLbl.TextColor3             = T.Text
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextSize               = 13
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
    nameLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex                 = 8

    local distLbl = Instance.new("TextLabel", card)
    distLbl.Size                   = UDim2.new(1, -84, 0, 14)
    distLbl.Position               = UDim2.new(0, 10, 0, 26)
    distLbl.BackgroundTransparency = 1
    distLbl.Text                   = pos and ("📍 " .. dist .. " studs") or "📍 Unknown"
    distLbl.TextColor3             = T.Sub
    distLbl.Font                   = Enum.Font.Gotham
    distLbl.TextSize               = 11
    distLbl.TextXAlignment         = Enum.TextXAlignment.Left
    distLbl.ZIndex                 = 8

    local collectBtn = Instance.new("TextButton", card)
    collectBtn.Size             = UDim2.new(0, 68, 0, 26)
    collectBtn.Position         = UDim2.new(1, -76, 0.5, -13)
    collectBtn.BackgroundColor3 = T.Green
    collectBtn.BorderSizePixel  = 0
    collectBtn.Text             = "Collect"
    collectBtn.TextColor3       = T.White
    collectBtn.Font             = Enum.Font.GothamBold
    collectBtn.TextSize         = 12
    collectBtn.AutoButtonColor  = false
    collectBtn.ZIndex           = 9
    corner(collectBtn, 6)

    card.MouseEnter:Connect(function()       tw(card,       {BackgroundColor3 = T.CardHover}, 0.12) end)
    card.MouseLeave:Connect(function()       tw(card,       {BackgroundColor3 = T.Card},      0.12) end)
    collectBtn.MouseEnter:Connect(function() tw(collectBtn, {BackgroundColor3 = T.DarkGreen}, 0.1)  end)
    collectBtn.MouseLeave:Connect(function() tw(collectBtn, {BackgroundColor3 = T.Green},     0.1)  end)

    local busy = false
    collectBtn.MouseButton1Click:Connect(function()
        if busy then return end
        if not obj or not obj.Parent then
            collectBtn.Text             = "Gone"
            collectBtn.BackgroundColor3 = T.Red
            return
        end
        busy = true
        task.spawn(function()
            collectOne(entry)
            if collectBtn and collectBtn.Parent then
                collectBtn.Text             = "OK"
                collectBtn.BackgroundColor3 = T.DarkGreen
                task.wait(1.5)
                if collectBtn and collectBtn.Parent then
                    collectBtn.Text             = "Collect"
                    collectBtn.BackgroundColor3 = T.Green
                end
            end
            busy = false
        end)
    end)
end

local foundCrops = {}
local autoOn     = false
local autoThread = nil

local isRefreshing = false
local function refreshList()
    if isRefreshing then return end
    isRefreshing = true
    for _, c in ipairs(CropScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    StatsLbl.Text = "Searching..."
    task.wait(0.05)
    foundCrops    = findAllCrops()
    StatsLbl.Text = string.format("%d crops found", #foundCrops)
    if #foundCrops == 0 then
        local lbl = Instance.new("TextLabel", CropScroll)
        lbl.Size                   = UDim2.new(1, 0, 0, 60)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = "No crops found — walk near your garden then press Refresh"
        lbl.TextColor3             = T.Sub
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextSize               = 12
        lbl.TextWrapped            = true
        lbl.ZIndex                 = 7
    else
        for i, entry in ipairs(foundCrops) do
            makeCropCard(entry, i)
            if i % 15 == 0 then task.wait() end
        end
    end
    isRefreshing = false
end

local isCollecting = false
CollectAllBtn.MouseButton1Click:Connect(function()
    if isCollecting then return end
    isCollecting = true
    CollectAllBtn.Text = "Collecting..."
    tw(CollectAllBtn, {BackgroundColor3 = T.DarkGreen}, 0.15)
    local snapshot = {}
    for i = 1, #foundCrops do snapshot[i] = foundCrops[i] end
    for _, entry in ipairs(snapshot) do
        if entry.obj and entry.obj.Parent then
            collectOne(entry)
            task.wait(0.35)
        end
    end
    CollectAllBtn.Text = "Done!"
    task.wait(1.5)
    CollectAllBtn.Text = "🍎  Collect All"
    tw(CollectAllBtn, {BackgroundColor3 = T.Green}, 0.15)
    isCollecting = false
    task.spawn(refreshList)
end)

local refreshBusy = false
RefreshBtn.MouseButton1Click:Connect(function()
    if refreshBusy then return end
    refreshBusy     = true
    RefreshBtn.Text = "Loading..."
    task.spawn(function()
        refreshList()
        task.wait()
        RefreshBtn.Text = "🔄  Refresh List"
        refreshBusy     = false
    end)
end)

local function startAutoLoop()
    autoThread = task.spawn(function()
        while autoOn do
            task.wait(0.5)
            if #foundCrops == 0 then
                foundCrops    = findAllCrops()
                StatsLbl.Text = string.format("%d crops found", #foundCrops)
                if #foundCrops == 0 then task.wait(3) end
            else
                local snapshot = {}
                for i = 1, #foundCrops do snapshot[i] = foundCrops[i] end
                for _, entry in ipairs(snapshot) do
                    if not autoOn then break end
                    if entry.obj and entry.obj.Parent then collectOne(entry) end
                    task.wait(0.4)
                end
                if autoOn then
                    task.wait(1)
                    foundCrops    = findAllCrops()
                    StatsLbl.Text = string.format("%d crops found", #foundCrops)
                end
            end
        end
    end)
end

AutoBtn.MouseButton1Click:Connect(function()
    autoOn        = not autoOn
    autoBaseColor = autoOn and T.Green or T.Card
    AutoBtn.Text  = autoOn and "⚡  Auto: ON" or "⚡  Auto: OFF"
    tw(AutoBtn, {BackgroundColor3 = autoBaseColor}, 0.15)
    if autoOn then
        startAutoLoop()
    elseif autoThread then
        task.cancel(autoThread)
        autoThread = nil
    end
end)

SpeedBtn.MouseButton1Click:Connect(function()
    speedOn = not speedOn
    if speedOn then
        SpeedBtn.Text = "🏃  Speed: ON  (x3)"
        tw(SpeedBtn, {BackgroundColor3 = Color3.fromRGB(140, 80, 220)}, 0.15)
        applySpeed(50)
    else
        SpeedBtn.Text = "🏃  Speed: OFF"
        tw(SpeedBtn, {BackgroundColor3 = Color3.fromRGB(100, 60, 180)}, 0.15)
        applySpeed(16)
    end
end)

AfkBtn.MouseButton1Click:Connect(function()
    afkOn = not afkOn
    if afkOn then
        AfkBtn.Text = "💤  Anti-AFK: ON"
        tw(AfkBtn, {BackgroundColor3 = Color3.fromRGB(40, 160, 220)}, 0.15)
        startAntiAfk()
    else
        AfkBtn.Text = "💤  Anti-AFK: OFF"
        tw(AfkBtn, {BackgroundColor3 = Color3.fromRGB(60, 130, 180)}, 0.15)
        if afkThread then task.cancel(afkThread); afkThread = nil end
    end
end)

NoclipBtn.MouseButton1Click:Connect(function()
    noclipOn = not noclipOn
    if noclipOn then
        NoclipBtn.Text = "👻  NoClip: ON"
        tw(NoclipBtn, {BackgroundColor3 = Color3.fromRGB(180, 140, 40)}, 0.15)
    else
        NoclipBtn.Text = "👻  NoClip: OFF"
        tw(NoclipBtn, {BackgroundColor3 = Color3.fromRGB(120, 90, 30)}, 0.15)
    end
end)

FlyBtn.MouseButton1Click:Connect(function()
    flyOn = not flyOn
    if flyOn then
        FlyBtn.Text = "🦋  Fly: ON   (WASD + Space / Ctrl)"
        tw(FlyBtn, {BackgroundColor3 = Color3.fromRGB(80, 120, 230)}, 0.15)
        startFly()
    else
        FlyBtn.Text = "🦋  Fly: OFF"
        tw(FlyBtn, {BackgroundColor3 = Color3.fromRGB(60, 90, 180)}, 0.15)
        stopFly()
    end
end)

TpShopBtn.MouseButton1Click:Connect(function()
    TpShopBtn.Text = "Searching..."
    task.spawn(function()
        local ok = teleportToShop()
        task.wait(0.5)
        TpShopBtn.Text = ok and "Teleported!" or "Shop not found"
        task.wait(2)
        TpShopBtn.Text = "🏪  Teleport to Shop"
    end)
end)

local isOpen = false

local function openPanel()
    isOpen        = true
    Panel.Size    = UDim2.new(0, 0, 0, PH)
    Panel.Visible = true
    tw(Panel, {Size = UDim2.new(0, PW, 0, PH)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    setTab("crops")
    task.spawn(refreshList)
end

local function closePanel()
    isOpen = false
    tw(Panel, {Size = UDim2.new(0, 0, 0, PH)}, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    task.delay(0.23, function()
        if not isOpen then Panel.Visible = false end
    end)
end

ToggleBtn.MouseButton1Click:Connect(function()
    if isOpen then closePanel() else openPanel() end
end)
CloseBtn.MouseButton1Click:Connect(closePanel)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        if isOpen then closePanel() else openPanel() end
    end
end)

workspace.DescendantRemoving:Connect(function(obj)
    for i = #foundCrops, 1, -1 do
        if foundCrops[i] and foundCrops[i].obj == obj then
            table.remove(foundCrops, i)
            StatsLbl.Text = string.format("%d crops found", #foundCrops)
            break
        end
    end
end)

setTab("crops")

task.spawn(function()
    local notif = Instance.new("ScreenGui")
    notif.Name           = "GardenNotif"
    notif.ResetOnSpawn   = false
    notif.IgnoreGuiInset = true
    notif.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notif.Parent         = player.PlayerGui

    local box = Instance.new("Frame", notif)
    box.Size             = UDim2.new(0, 280, 0, 60)
    box.Position         = UDim2.new(0.5, -140, 0, 20)
    box.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
    box.BorderSizePixel  = 0
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 10)
    local st = Instance.new("UIStroke", box)
    st.Color = Color3.fromRGB(50, 200, 100); st.Thickness = 1.5

    local lbl = Instance.new("TextLabel", box)
    lbl.Size                   = UDim2.new(1, -10, 0, 30)
    lbl.Position               = UDim2.new(0, 5, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = "Garden Dev Menu — Loaded!"
    lbl.TextColor3             = Color3.fromRGB(50, 200, 100)
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextSize               = 15

    local sub = Instance.new("TextLabel", box)
    sub.Size                   = UDim2.new(1, -10, 0, 20)
    sub.Position               = UDim2.new(0, 5, 0, 34)
    sub.BackgroundTransparency = 1
    sub.Text                   = "Press RightShift or click Dev Menu (left side)"
    sub.TextColor3             = Color3.fromRGB(150, 150, 150)
    sub.Font                   = Enum.Font.Gotham
    sub.TextSize               = 12

    task.wait(5)
    TweenService:Create(box, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(lbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    TweenService:Create(sub, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
    task.wait(0.6)
    notif:Destroy()
end)
