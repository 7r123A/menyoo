local Players                = game:GetService("Players")
local TweenService           = game:GetService("TweenService")
local UserInputService       = game:GetService("UserInputService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    character = c
    rootPart  = c:WaitForChild("HumanoidRootPart")
end)

-- ── Theme ─────────────────────────────────────────────────────────────────

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
    Gold      = Color3.fromRGB(255, 200,  50),
    DarkText  = Color3.fromRGB(40,   20,   0),
}

local RARITY_COLOR = {
    Common    = Color3.fromRGB(120, 180, 120),
    Uncommon  = Color3.fromRGB(60,  140, 220),
    Rare      = Color3.fromRGB(140,  80, 220),
    Epic      = Color3.fromRGB(220,  80, 180),
    Legendary = Color3.fromRGB(255, 200,  50),
    Mythic    = Color3.fromRGB(255,  80,  80),
}

-- ── Seeds data ────────────────────────────────────────────────────────────

local SEEDS = {
    {name = "Carrot",          emoji = "🥕", rarity = "Common"},
    {name = "Strawberry",      emoji = "🍓", rarity = "Common"},
    {name = "Tomato",          emoji = "🍅", rarity = "Common"},
    {name = "Corn",            emoji = "🌽", rarity = "Common"},
    {name = "Potato",          emoji = "🥔", rarity = "Common"},
    {name = "Cucumber",        emoji = "🥒", rarity = "Common"},
    {name = "Pear",            emoji = "🍐", rarity = "Common"},
    {name = "Banana",          emoji = "🍌", rarity = "Common"},
    {name = "Lemon",           emoji = "🍋", rarity = "Common"},
    {name = "Apple",           emoji = "🍎", rarity = "Common"},
    {name = "Blueberry",       emoji = "🫐", rarity = "Uncommon"},
    {name = "Watermelon",      emoji = "🍉", rarity = "Uncommon"},
    {name = "Peach",           emoji = "🍑", rarity = "Uncommon"},
    {name = "Orange",          emoji = "🍊", rarity = "Uncommon"},
    {name = "Cherry",          emoji = "🍒", rarity = "Uncommon"},
    {name = "Pumpkin",         emoji = "🎃", rarity = "Uncommon"},
    {name = "Bell Pepper",     emoji = "🫑", rarity = "Uncommon"},
    {name = "Eggplant",        emoji = "🍆", rarity = "Uncommon"},
    {name = "Raspberry",       emoji = "🔴", rarity = "Uncommon"},
    {name = "Pineapple",       emoji = "🍍", rarity = "Rare"},
    {name = "Grape",           emoji = "🍇", rarity = "Rare"},
    {name = "Mango",           emoji = "🥭", rarity = "Rare"},
    {name = "Coconut",         emoji = "🥥", rarity = "Rare"},
    {name = "Kiwi",            emoji = "🥝", rarity = "Rare"},
    {name = "Avocado",         emoji = "🥑", rarity = "Rare"},
    {name = "Papaya",          emoji = "🍈", rarity = "Rare"},
    {name = "Pomegranate",     emoji = "❤️",  rarity = "Rare"},
    {name = "Dragon Fruit",    emoji = "🐉", rarity = "Epic"},
    {name = "Star Fruit",      emoji = "⭐", rarity = "Epic"},
    {name = "Passion Fruit",   emoji = "💜", rarity = "Epic"},
    {name = "Durian",          emoji = "🌵", rarity = "Epic"},
    {name = "Jackfruit",       emoji = "🟡", rarity = "Epic"},
    {name = "Rainbow Fruit",   emoji = "🌈", rarity = "Legendary"},
    {name = "Golden Apple",    emoji = "✨", rarity = "Legendary"},
    {name = "Crystal Melon",   emoji = "💎", rarity = "Legendary"},
    {name = "Golden Carrot",   emoji = "🌟", rarity = "Legendary"},
    {name = "Moon Berry",      emoji = "🌙", rarity = "Mythic"},
    {name = "Void Fruit",      emoji = "🌑", rarity = "Mythic"},
    {name = "Celestial Grape", emoji = "🔮", rarity = "Mythic"},
}

-- ── UI helpers ────────────────────────────────────────────────────────────

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
        t     or 0.2,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

-- ── Game helpers ──────────────────────────────────────────────────────────

local function getPos(obj)
    if not obj or not obj.Parent then return nil end
    local ok, result = pcall(function()
        if obj:IsA("Model")    then return obj:GetModelCFrame().Position end
        if obj:IsA("BasePart") then return obj.Position end
    end)
    return ok and result or nil
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
                    local displayName = (obj.ObjectText ~= "" and obj.ObjectText) or target.Name
                    table.insert(results, {obj = target, name = displayName, pp = obj})
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
    rootPart.CFrame = CFrame.new(p + Vector3.new(0, 3.5, 0))
    task.wait(0.3)
    if not entry.obj.Parent then return end
    triggerPP(entry.pp)
    task.wait(0.15)
    if entry.pp and entry.pp.Parent then triggerPP(entry.pp) end
end

-- ── ReplicaService exploit ────────────────────────────────────────────────

local RS = game:GetService("ReplicatedStorage")

-- Search ALL descendants for a remote whose parent is named `parentName`.
-- Fixes the Packet/Charm remotes that aren't direct children of RS.
local function findByParentName(parentName, remoteName)
    for _, d in ipairs(RS:GetDescendants()) do
        if d.Parent and d.Parent.Name == parentName then
            if remoteName == nil or d.Name == remoteName then return d end
        end
    end
    return nil
end

local RemEvts        = RS:FindFirstChild("RemoteEvents")
local ReplicaSet         = RemEvts and RemEvts:FindFirstChild("ReplicaSet")
local ReplicaSetValues   = RemEvts and RemEvts:FindFirstChild("ReplicaSetValues")
local ReplicaWrite       = RemEvts and RemEvts:FindFirstChild("ReplicaWrite")
local ReplicaTableInsert = RemEvts and RemEvts:FindFirstChild("ReplicaTableInsert")
local ReplicaCreate      = RemEvts and RemEvts:FindFirstChild("ReplicaCreate")
local ReplicaReqData     = RemEvts and RemEvts:FindFirstChild("ReplicaRequestData")

-- FIX: Packet/Charm are NOT direct children of RS → search all descendants
local PacketRemote = findByParentName("Packet",  "RemoteEvent")
local SyncState    = findByParentName("Charm",   "SyncState")
local RequestState = findByParentName("Charm",   "RequestState")

local capturedReplicas = {}
local lastCharmState   = {}

-- ── PASSIVE REPLICA ID CAPTURE ──────────────────────────────────────────
-- The server fires ReplicaSet / ReplicaSetValues CONSTANTLY to sync player
-- data (coins, inventory, etc.).  The very first argument is always the
-- numeric replica ID.  By listening here we get IDs for free, without
-- having to re-request anything.
local function passiveCapture(id)
    if type(id) == "number" and not capturedReplicas[id] then
        capturedReplicas[id] = {id}
    end
end
if ReplicaSet       then ReplicaSet.OnClientEvent:Connect(function(id) passiveCapture(id) end)       end
if ReplicaSetValues then ReplicaSetValues.OnClientEvent:Connect(function(id) passiveCapture(id) end) end

-- ── ACTIVE REPLICA CAPTURE ───────────────────────────────────────────────
task.spawn(function()
    -- Wait for RemoteEvents if not ready yet (yielding is safe inside task.spawn)
    if not RemEvts then
        RemEvts = RS:WaitForChild("RemoteEvents", 15)
        if RemEvts then
            ReplicaSet         = RemEvts:FindFirstChild("ReplicaSet")
            ReplicaSetValues   = RemEvts:FindFirstChild("ReplicaSetValues")
            ReplicaWrite       = RemEvts:FindFirstChild("ReplicaWrite")
            ReplicaTableInsert = RemEvts:FindFirstChild("ReplicaTableInsert")
            ReplicaCreate      = RemEvts:FindFirstChild("ReplicaCreate")
            ReplicaReqData     = RemEvts:FindFirstChild("ReplicaRequestData")
            -- Re-attach passive listeners on the newly found remotes
            if ReplicaSet       then ReplicaSet.OnClientEvent:Connect(function(id) passiveCapture(id) end)       end
            if ReplicaSetValues then ReplicaSetValues.OnClientEvent:Connect(function(id) passiveCapture(id) end) end
        end
    end
    if not PacketRemote then PacketRemote = findByParentName("Packet", "RemoteEvent") end
    if not SyncState    then SyncState    = findByParentName("Charm",  "SyncState")   end
    if not RequestState then RequestState = findByParentName("Charm",  "RequestState") end

    -- ReplicaCreate: server sends full replica packet when client requests data.
    -- Handles both table-packed and individual-argument formats.
    if ReplicaCreate then
        ReplicaCreate.OnClientEvent:Connect(function(...)
            local args = {...}
            local function tryStore(v)
                if type(v) ~= "table" then return end
                local id = v[1] or v.id
                if type(id) == "number" then
                    capturedReplicas[id] = v
                else
                    for _, sub in ipairs(v) do
                        if type(sub) == "table" then
                            local sid = sub[1] or sub.id
                            if type(sid) == "number" then capturedReplicas[sid] = sub end
                        end
                    end
                end
            end
            if type(args[1]) == "number" then
                capturedReplicas[args[1]] = args
            else
                for _, a in ipairs(args) do tryStore(a) end
            end
        end)
    end
    if SyncState then
        SyncState.OnClientEvent:Connect(function(data)
            if type(data) == "table" then lastCharmState = data end
        end)
    end

    task.wait(0.2)
    if ReplicaReqData then pcall(function() ReplicaReqData:FireServer() end) end
    if RequestState   then pcall(function() RequestState:FireServer()   end) end

    -- Exploit-function fallback: read existing ReplicaController connections
    task.wait(1.5)
    if next(capturedReplicas) == nil then
        pcall(function()
            if not (getconnections and ReplicaCreate) then return end
            for _, conn in ipairs(getconnections(ReplicaCreate.OnClientEvent)) do
                if conn.Function and getupvalues then
                    for _, up in ipairs(getupvalues(conn.Function)) do
                        if type(up) == "table" then
                            for k, v in pairs(up) do
                                if type(k) == "number" and type(v) == "table" then
                                    capturedReplicas[k] = v
                                end
                            end
                        end
                    end
                end
            end
        end)
        -- gc scan: look for tables with numeric Id field (ReplicaService replica objects)
        pcall(function()
            if not getgc then return end
            for _, v in ipairs(getgc(false)) do
                if type(v) == "table" then
                    local id = rawget(v, "Id") or rawget(v, "id")
                    if type(id) == "number" and rawget(v, "Data") ~= nil then
                        capturedReplicas[id] = v
                    end
                end
            end
        end)
    end
end)

local MONEY_PATHS = {"Money","Coins","Cash","Currency","Gold","Gems","Bucks",
                     "Sheckles","Credits","Points","Balance","Wallet"}

local function ensureReplicas()
    if next(capturedReplicas) ~= nil then return end
    if ReplicaReqData then pcall(function() ReplicaReqData:FireServer() end) end
    task.wait(0.8)
end

local function replicaWriteMoney(amount)
    if not ReplicaWrite then return end
    local fns = {"AddMoney","GiveMoney","SetMoney","IncrMoney",
                 "AddCoins","GiveCoins","SetCoins","AddCash","GiveCash","AddCurrency"}
    for id in pairs(capturedReplicas) do
        for _, fn in ipairs(fns) do
            pcall(function() ReplicaWrite:FireServer(id, fn, amount) end)
            pcall(function() ReplicaWrite:FireServer(id, fn, {amount = amount}) end)
        end
    end
end

local function replicaSetMoneyDirect(amount)
    if not ReplicaSet then return end
    for id in pairs(capturedReplicas) do
        for _, key in ipairs(MONEY_PATHS) do
            pcall(function() ReplicaSet:FireServer(id, {key}, amount) end)
            pcall(function() ReplicaSet:FireServer(id, key,  amount) end)
        end
    end
    if ReplicaSetValues then
        for id in pairs(capturedReplicas) do
            pcall(function()
                ReplicaSetValues:FireServer(id, {Money=amount,Coins=amount,Cash=amount})
            end)
        end
    end
end

local function replicaWriteSeed(seedName)
    if not ReplicaWrite then return end
    local fns = {"BuySeed","AddSeed","GiveSeed","ClaimSeed","UnlockSeed",
                 "BuyItem","AddItem","GiveItem","UnlockItem","Buy","AddToInventory"}
    for id in pairs(capturedReplicas) do
        for _, fn in ipairs(fns) do
            pcall(function() ReplicaWrite:FireServer(id, fn, seedName) end)
            pcall(function() ReplicaWrite:FireServer(id, fn, seedName, 1) end)
            pcall(function() ReplicaWrite:FireServer(id, fn, {name=seedName, amount=1}) end)
        end
    end
end

local function replicaInsertSeed(seedName)
    if not ReplicaTableInsert then return end
    for id in pairs(capturedReplicas) do
        for _, path in ipairs({{"Inventory"},{"Seeds"},{"Items"},{"Backpack"}}) do
            pcall(function() ReplicaTableInsert:FireServer(id, path, seedName) end)
            pcall(function() ReplicaTableInsert:FireServer(id, path, {name=seedName,amount=1}) end)
        end
    end
end

local function giveMoney(amount)
    ensureReplicas()
    replicaWriteMoney(amount)
    replicaSetMoneyDirect(amount)
    -- Packet remote (Red / custom networking)
    if PacketRemote then
        local acts = {"AddMoney","GiveMoney","SetMoney","AddCoins","GiveCoins","SetCoins","AddCash","GiveCash"}
        for _, act in ipairs(acts) do
            pcall(function() PacketRemote:FireServer(act, amount) end)
            pcall(function() PacketRemote:FireServer({[act]={amount}}) end)
        end
    end
end

local function claimSeed(seedName)
    ensureReplicas()
    replicaWriteSeed(seedName)
    replicaInsertSeed(seedName)
    if PacketRemote then
        local acts = {"BuySeed","AddSeed","GiveSeed","ClaimSeed","BuyItem","AddItem","GiveItem","Buy","Purchase"}
        for _, act in ipairs(acts) do
            pcall(function() PacketRemote:FireServer(act, seedName)          end)
            pcall(function() PacketRemote:FireServer(act, seedName, 1)       end)
            pcall(function() PacketRemote:FireServer({[act]={seedName}})     end)
            pcall(function() PacketRemote:FireServer({[act]={seedName,1}})   end)
        end
    end
    -- ProximityPrompt fallback
    local snLower = seedName:lower()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local ot = obj.ObjectText:lower()
            if ot:find(snLower, 1, true) then
                local p = getPos(obj.Parent)
                if p then rootPart.CFrame = CFrame.new(p + Vector3.new(0,3.5,0)); task.wait(0.2) end
                triggerPP(obj); task.wait(0.1); triggerPP(obj)
            end
        end
    end
end

local function scanRemoteNames()
    local names = {}
    for _, obj in ipairs(RS:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            table.insert(names, obj.Name .. " [" .. obj.Parent.Name .. "]")
        end
    end
    table.sort(names)
    local replicaCount = 0
    for _ in pairs(capturedReplicas) do replicaCount = replicaCount + 1 end
    local charmKeys = 0
    for _ in pairs(lastCharmState) do charmKeys = charmKeys + 1 end
    table.insert(names, "")
    table.insert(names, "--- Status ---")
    table.insert(names, "Replicas captured: " .. replicaCount)
    table.insert(names, "Packet remote: " .. (PacketRemote and "found" or "NOT FOUND"))
    table.insert(names, "SyncState: " .. (SyncState and "found" or "NOT FOUND"))
    table.insert(names, "Charm keys: " .. charmKeys)
    return names
end

-- ── GUI ───────────────────────────────────────────────────────────────────

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

local PH, PW = 560, 320

local Panel = Instance.new("Frame", Gui)
Panel.Name              = "Panel"
Panel.Size              = UDim2.new(0, 0, 0, PH)
Panel.Position          = UDim2.new(0, 138, 0.5, -PH / 2)
Panel.BackgroundColor3  = T.Bg
Panel.BorderSizePixel   = 0
Panel.ClipsDescendants  = true
Panel.Visible           = false
Panel.ZIndex            = 5
corner(Panel, 14)
stroke(Panel, T.Green, 1.5)

-- Header
local Header = Instance.new("Frame", Panel)
Header.Size             = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = T.Green
Header.BorderSizePixel  = 0
Header.ZIndex           = 6
corner(Header, 14)

-- fix round corners only on top
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
TitleLbl.Text                   = "🌱  Grow a Garden — Dev Tools"
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
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = T.White
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.TextSize         = 13
CloseBtn.AutoButtonColor  = false
CloseBtn.ZIndex           = 8
corner(CloseBtn, 6)
CloseBtn.MouseEnter:Connect(function() tw(CloseBtn, {BackgroundColor3 = T.RedHover}, 0.1) end)
CloseBtn.MouseLeave:Connect(function() tw(CloseBtn, {BackgroundColor3 = T.Red},      0.1) end)

-- Tab bar (y=56, h=34)
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
local SeedsTab = makeTab("🌱  Seeds", 0.5)

-- ── Crops content (y=98, h=462) ───────────────────────────────────────────

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
StatsLbl.Text                   = "🔍 Press Refresh to search..."
StatsLbl.TextColor3             = T.Sub
StatsLbl.Font                   = Enum.Font.Gotham
StatsLbl.TextSize               = 12
StatsLbl.TextXAlignment         = Enum.TextXAlignment.Left
StatsLbl.ZIndex                 = 7

-- CropScroll y=38..328, buttons at 338/380/422
local CropScroll = Instance.new("ScrollingFrame", CropsContent)
CropScroll.Size                   = UDim2.new(1, -16, 0, 290)
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
cropPad.PaddingTop = UDim.new(0, 4); cropPad.PaddingBottom = UDim.new(0, 4)

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

local CollectAllBtn = makeCropBtn("🍎  Collect All",  T.Green, 338)
local AutoBtn       = makeCropBtn("⚡  Auto: OFF",     T.Card,  380)
local RefreshBtn    = makeCropBtn("🔄  Refresh List",  T.Blue,  422)

for _, info in ipairs({{CollectAllBtn, T.Green}, {RefreshBtn, T.Blue}}) do
    local btn, clr = info[1], info[2]
    btn.MouseEnter:Connect(function() tw(btn, {BackgroundColor3 = clr:Lerp(T.White, 0.13)}, 0.12) end)
    btn.MouseLeave:Connect(function() tw(btn, {BackgroundColor3 = clr}, 0.12) end)
end

local autoBaseColor = T.Card
AutoBtn.MouseEnter:Connect(function() tw(AutoBtn, {BackgroundColor3 = autoBaseColor:Lerp(T.White, 0.13)}, 0.12) end)
AutoBtn.MouseLeave:Connect(function() tw(AutoBtn, {BackgroundColor3 = autoBaseColor}, 0.12) end)

-- ── Seeds content (y=98, h=462) ───────────────────────────────────────────

local SeedsContent = Instance.new("Frame", Panel)
SeedsContent.Size                   = UDim2.new(1, 0, 0, PH - 98)
SeedsContent.Position               = UDim2.new(0, 0, 0, 98)
SeedsContent.BackgroundTransparency = 1
SeedsContent.BorderSizePixel        = 0
SeedsContent.ZIndex                 = 5
SeedsContent.Visible                = false

-- SeedScroll y=0..254, buttons at 262/304/346/388
local SeedScroll = Instance.new("ScrollingFrame", SeedsContent)
SeedScroll.Size                   = UDim2.new(1, -16, 0, 254)
SeedScroll.Position               = UDim2.new(0, 8, 0, 0)
SeedScroll.BackgroundTransparency = 1
SeedScroll.BorderSizePixel        = 0
SeedScroll.ScrollBarThickness     = 4
SeedScroll.ScrollBarImageColor3   = T.Green
SeedScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
SeedScroll.ZIndex                 = 6

local SeedListLayout = Instance.new("UIListLayout", SeedScroll)
SeedListLayout.Padding   = UDim.new(0, 4)
SeedListLayout.SortOrder = Enum.SortOrder.LayoutOrder
SeedListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    SeedScroll.CanvasSize = UDim2.new(0, 0, 0, SeedListLayout.AbsoluteContentSize.Y + 8)
end)

local seedPad = Instance.new("UIPadding", SeedScroll)
seedPad.PaddingTop = UDim.new(0, 4); seedPad.PaddingBottom = UDim.new(0, 4)

local function makeSeedBtn(text, color, yAbs, textColor)
    local btn = Instance.new("TextButton", SeedsContent)
    btn.Size             = UDim2.new(1, -16, 0, 34)
    btn.Position         = UDim2.new(0, 8, 0, yAbs)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel  = 0
    btn.Text             = text
    btn.TextColor3       = textColor or T.White
    btn.Font             = Enum.Font.GothamBold
    btn.TextSize         = 13
    btn.AutoButtonColor  = false
    btn.ZIndex           = 7
    corner(btn, 8)
    return btn
end

local ScanRemotesBtn   = makeSeedBtn("🔎  Scan Remotes",      T.Blue,  262)
local GiveMoneyBtn     = makeSeedBtn("💰  Give $100,000",     T.Gold,  304, T.DarkText)
local Give10MBtn       = makeSeedBtn("💎  Give $10,000,000",  T.Gold,  346, T.DarkText)
local ClaimAllSeedsBtn = makeSeedBtn("🌱  Claim All Seeds",   T.Green, 388)

ScanRemotesBtn.MouseEnter:Connect(function()   tw(ScanRemotesBtn,   {BackgroundColor3 = T.Blue:Lerp(T.White, 0.2)}, 0.12) end)
ScanRemotesBtn.MouseLeave:Connect(function()   tw(ScanRemotesBtn,   {BackgroundColor3 = T.Blue},  0.12) end)
GiveMoneyBtn.MouseEnter:Connect(function()     tw(GiveMoneyBtn,     {BackgroundColor3 = T.Gold:Lerp(T.White, 0.2)}, 0.12) end)
GiveMoneyBtn.MouseLeave:Connect(function()     tw(GiveMoneyBtn,     {BackgroundColor3 = T.Gold},  0.12) end)
Give10MBtn.MouseEnter:Connect(function()       tw(Give10MBtn,       {BackgroundColor3 = T.Gold:Lerp(T.White, 0.2)}, 0.12) end)
Give10MBtn.MouseLeave:Connect(function()       tw(Give10MBtn,       {BackgroundColor3 = T.Gold},  0.12) end)
ClaimAllSeedsBtn.MouseEnter:Connect(function() tw(ClaimAllSeedsBtn, {BackgroundColor3 = T.DarkGreen}, 0.12) end)
ClaimAllSeedsBtn.MouseLeave:Connect(function() tw(ClaimAllSeedsBtn, {BackgroundColor3 = T.Green}, 0.12) end)

-- ── Scan overlay ──────────────────────────────────────────────────────────
-- FIX: height covers visible area properly; ZIndex above all panel children

local ScanOverlay = Instance.new("Frame", Panel)
ScanOverlay.Size             = UDim2.new(1, -16, 0, PH - 106)
ScanOverlay.Position         = UDim2.new(0, 8, 0, 98)
ScanOverlay.BackgroundColor3 = T.Bg
ScanOverlay.BorderSizePixel  = 0
ScanOverlay.ZIndex           = 20
ScanOverlay.Visible          = false
corner(ScanOverlay, 10)
stroke(ScanOverlay, T.Blue, 1.5)

local ScanTitle = Instance.new("TextLabel", ScanOverlay)
ScanTitle.Size                   = UDim2.new(1, -50, 0, 28)
ScanTitle.Position               = UDim2.new(0, 10, 0, 6)
ScanTitle.BackgroundTransparency = 1
ScanTitle.Text                   = "🔎 RemoteEvents"
ScanTitle.TextColor3             = T.Blue
ScanTitle.Font                   = Enum.Font.GothamBold
ScanTitle.TextSize               = 13
ScanTitle.TextXAlignment         = Enum.TextXAlignment.Left
ScanTitle.ZIndex                 = 21

local ScanClose = Instance.new("TextButton", ScanOverlay)
ScanClose.Size             = UDim2.new(0, 24, 0, 24)
ScanClose.Position         = UDim2.new(1, -30, 0, 8)
ScanClose.BackgroundColor3 = T.Red
ScanClose.BorderSizePixel  = 0
ScanClose.Text             = "✕"
ScanClose.TextColor3       = T.White
ScanClose.Font             = Enum.Font.GothamBold
ScanClose.TextSize         = 12
ScanClose.AutoButtonColor  = false
ScanClose.ZIndex           = 22
corner(ScanClose, 5)
ScanClose.MouseButton1Click:Connect(function() ScanOverlay.Visible = false end)

local ScanScroll = Instance.new("ScrollingFrame", ScanOverlay)
ScanScroll.Size                   = UDim2.new(1, -10, 1, -44)
ScanScroll.Position               = UDim2.new(0, 5, 0, 38)
ScanScroll.BackgroundTransparency = 1
ScanScroll.BorderSizePixel        = 0
ScanScroll.ScrollBarThickness     = 4
ScanScroll.ScrollBarImageColor3   = T.Blue
ScanScroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
ScanScroll.ZIndex                 = 21

local ScanLayout = Instance.new("UIListLayout", ScanScroll)
ScanLayout.Padding   = UDim.new(0, 3)
ScanLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScanLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScanScroll.CanvasSize = UDim2.new(0, 0, 0, ScanLayout.AbsoluteContentSize.Y + 6)
end)

-- FIX: added missing UIPadding for scan scroll
local scanPad = Instance.new("UIPadding", ScanScroll)
scanPad.PaddingTop = UDim.new(0, 4); scanPad.PaddingBottom = UDim.new(0, 4)
scanPad.PaddingLeft = UDim.new(0, 4)

ScanRemotesBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(ScanScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local names = scanRemoteNames()
    local replicaCount = 0
    for _ in pairs(capturedReplicas) do replicaCount += 1 end
    ScanTitle.Text = string.format("🔎 %d Remotes  |  %d Replicas", #names, replicaCount)
    if #names == 0 then
        local lbl = Instance.new("TextLabel", ScanScroll)
        lbl.Size                   = UDim2.new(1, 0, 0, 30)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = "⚠️ None found — enter a game first"
        lbl.TextColor3             = T.Sub
        lbl.Font                   = Enum.Font.Gotham
        lbl.TextSize               = 12
        lbl.ZIndex                 = 22
    else
        for i, name in ipairs(names) do
            local lbl = Instance.new("TextLabel", ScanScroll)
            lbl.Size                   = UDim2.new(1, -4, 0, 22)
            lbl.BackgroundTransparency = 1
            lbl.Text                   = "• " .. name
            lbl.TextColor3             = T.Text
            lbl.Font                   = Enum.Font.Gotham
            lbl.TextSize               = 11
            lbl.TextXAlignment         = Enum.TextXAlignment.Left
            lbl.TextTruncate           = Enum.TextTruncate.AtEnd
            lbl.LayoutOrder            = i
            lbl.ZIndex                 = 22
        end
    end
    ScanOverlay.Visible = true
end)

-- ── Seed cards ────────────────────────────────────────────────────────────

for i, seed in ipairs(SEEDS) do
    local rc = RARITY_COLOR[seed.rarity] or T.Green

    local card = Instance.new("Frame", SeedScroll)
    card.Size             = UDim2.new(1, 0, 0, 42)
    card.BackgroundColor3 = T.Card
    card.BorderSizePixel  = 0
    card.LayoutOrder      = i
    card.ZIndex           = 7
    corner(card, 8)

    local bar = Instance.new("Frame", card)
    bar.Size             = UDim2.new(0, 3, 1, -8)
    bar.Position         = UDim2.new(0, 4, 0, 4)
    bar.BackgroundColor3 = rc
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 8
    corner(bar, 2)

    local nameLbl = Instance.new("TextLabel", card)
    nameLbl.Size                   = UDim2.new(1, -90, 0, 22)
    nameLbl.Position               = UDim2.new(0, 16, 0, 4)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text                   = seed.emoji .. " " .. seed.name
    nameLbl.TextColor3             = T.Text
    nameLbl.Font                   = Enum.Font.GothamBold
    nameLbl.TextSize               = 13
    nameLbl.TextXAlignment         = Enum.TextXAlignment.Left
    nameLbl.TextTruncate           = Enum.TextTruncate.AtEnd
    nameLbl.ZIndex                 = 8

    local rarLbl = Instance.new("TextLabel", card)
    rarLbl.Size                   = UDim2.new(1, -90, 0, 14)
    rarLbl.Position               = UDim2.new(0, 16, 0, 25)
    rarLbl.BackgroundTransparency = 1
    rarLbl.Text                   = seed.rarity
    rarLbl.TextColor3             = rc
    rarLbl.Font                   = Enum.Font.Gotham
    rarLbl.TextSize               = 11
    rarLbl.TextXAlignment         = Enum.TextXAlignment.Left
    rarLbl.ZIndex                 = 8

    local claimBtn = Instance.new("TextButton", card)
    claimBtn.Size             = UDim2.new(0, 68, 0, 26)
    claimBtn.Position         = UDim2.new(1, -76, 0.5, -13)
    claimBtn.BackgroundColor3 = rc
    claimBtn.BorderSizePixel  = 0
    claimBtn.Text             = "Claim"
    claimBtn.TextColor3       = T.White
    claimBtn.Font             = Enum.Font.GothamBold
    claimBtn.TextSize         = 12
    claimBtn.AutoButtonColor  = false
    claimBtn.ZIndex           = 9
    corner(claimBtn, 6)

    card.MouseEnter:Connect(function()     tw(card,     {BackgroundColor3 = T.CardHover},             0.12) end)
    card.MouseLeave:Connect(function()     tw(card,     {BackgroundColor3 = T.Card},                  0.12) end)
    claimBtn.MouseEnter:Connect(function() tw(claimBtn, {BackgroundColor3 = rc:Lerp(T.White, 0.2)},  0.1)  end)
    claimBtn.MouseLeave:Connect(function() tw(claimBtn, {BackgroundColor3 = rc},                      0.1)  end)

    local busy = false
    claimBtn.MouseButton1Click:Connect(function()
        if busy then return end
        busy = true
        claimBtn.Text = "⏳"
        task.spawn(function()
            claimSeed(seed.name)
            task.wait(0.3)
            if claimBtn and claimBtn.Parent then
                claimBtn.Text             = "✅"
                claimBtn.BackgroundColor3 = T.DarkGreen
                task.wait(1.5)
                if claimBtn and claimBtn.Parent then
                    claimBtn.Text             = "Claim"
                    claimBtn.BackgroundColor3 = rc
                end
            end
            busy = false
        end)
    end)
end

-- ── Seed bottom buttons ───────────────────────────────────────────────────

local isClaimingAll = false
ClaimAllSeedsBtn.MouseButton1Click:Connect(function()
    if isClaimingAll then return end
    isClaimingAll = true
    ClaimAllSeedsBtn.Text = "⏳  Claiming..."
    tw(ClaimAllSeedsBtn, {BackgroundColor3 = T.DarkGreen}, 0.15)
    task.spawn(function()
        for _, seed in ipairs(SEEDS) do
            claimSeed(seed.name)
            task.wait(0.15)
        end
        ClaimAllSeedsBtn.Text = "✅  Done!"
        task.wait(2)
        ClaimAllSeedsBtn.Text = "🌱  Claim All Seeds"
        tw(ClaimAllSeedsBtn, {BackgroundColor3 = T.Green}, 0.15)
        isClaimingAll = false
    end)
end)

local moneyBusy = false

local function doGiveMoney(btn, amount, label)
    if moneyBusy then return end
    moneyBusy = true
    btn.Text = "⏳  Giving..."
    task.spawn(function()
        giveMoney(amount)
        if btn and btn.Parent then
            btn.Text = "✅  Done!"
            task.wait(1.5)
            if btn and btn.Parent then
                btn.Text = label
            end
        end
        moneyBusy = false
    end)
end

GiveMoneyBtn.MouseButton1Click:Connect(function()
    doGiveMoney(GiveMoneyBtn, 100000, "💰  Give $100,000")
end)

Give10MBtn.MouseButton1Click:Connect(function()
    doGiveMoney(Give10MBtn, 10000000, "💎  Give $10,000,000")
end)

-- ── Tab switching ─────────────────────────────────────────────────────────

local function setTab(tab)
    if tab == "crops" then
        CropsContent.Visible = true
        SeedsContent.Visible = false
        tw(CropsTab, {BackgroundColor3 = T.Green}, 0.15); CropsTab.TextColor3 = T.White
        tw(SeedsTab, {BackgroundColor3 = T.Bg},    0.15); SeedsTab.TextColor3 = T.Sub
    else
        CropsContent.Visible = false
        SeedsContent.Visible = true
        tw(SeedsTab, {BackgroundColor3 = T.Green}, 0.15); SeedsTab.TextColor3 = T.White
        tw(CropsTab, {BackgroundColor3 = T.Bg},    0.15); CropsTab.TextColor3 = T.Sub
    end
end

CropsTab.MouseButton1Click:Connect(function() setTab("crops") end)
SeedsTab.MouseButton1Click:Connect(function() setTab("seeds") end)

-- ── Crop cards ────────────────────────────────────────────────────────────

local function makeCropCard(entry, idx)
    local obj  = entry.obj
    local pos  = getPos(obj)
    local dist = pos and math.floor((rootPart.Position - pos).Magnitude) or 0

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
            collectBtn.Text             = "✕ Gone"
            collectBtn.BackgroundColor3 = T.Red
            return
        end
        busy = true
        task.spawn(function()
            collectOne(entry)
            if collectBtn and collectBtn.Parent then
                collectBtn.Text             = "✅"
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

-- ── Crop functionality ────────────────────────────────────────────────────

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
    StatsLbl.Text = "🔍 Searching..."
    task.wait(0.05)
    foundCrops = findAllCrops()
    StatsLbl.Text = string.format("✅ %d crops found", #foundCrops)
    if #foundCrops == 0 then
        local lbl = Instance.new("TextLabel", CropScroll)
        lbl.Size                   = UDim2.new(1, 0, 0, 60)
        lbl.BackgroundTransparency = 1
        lbl.Text                   = "⚠️ No crops found\nWalk near your garden then press Refresh"
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
    CollectAllBtn.Text = "⏳  Collecting..."
    tw(CollectAllBtn, {BackgroundColor3 = T.DarkGreen}, 0.15)
    local snapshot = {}
    for i = 1, #foundCrops do snapshot[i] = foundCrops[i] end
    for _, entry in ipairs(snapshot) do
        if entry.obj and entry.obj.Parent then
            collectOne(entry)
            task.wait(0.35)
        end
    end
    CollectAllBtn.Text = "✅  Done!"
    task.wait(1.5)
    CollectAllBtn.Text = "🍎  Collect All"
    tw(CollectAllBtn, {BackgroundColor3 = T.Green}, 0.15)
    isCollecting = false
    task.spawn(refreshList)
end)

local refreshBtnBusy = false
RefreshBtn.MouseButton1Click:Connect(function()
    if refreshBtnBusy then return end
    refreshBtnBusy  = true
    RefreshBtn.Text = "⏳  Loading..."
    task.spawn(function()
        refreshList()
        task.wait()
        RefreshBtn.Text = "🔄  Refresh List"
        refreshBtnBusy  = false
    end)
end)

local function startAutoLoop()
    autoThread = task.spawn(function()
        while autoOn do
            if #foundCrops == 0 then
                foundCrops = findAllCrops()
                StatsLbl.Text = string.format("✅ %d crops found", #foundCrops)
                if #foundCrops == 0 then task.wait(3) continue end
            end
            local snapshot = {}
            for i = 1, #foundCrops do snapshot[i] = foundCrops[i] end
            for _, entry in ipairs(snapshot) do
                if not autoOn then break end
                if entry.obj and entry.obj.Parent then
                    collectOne(entry)
                    task.wait(0.4)
                end
            end
            if autoOn then
                task.wait(1)
                foundCrops = findAllCrops()
                StatsLbl.Text = string.format("✅ %d crops found", #foundCrops)
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

-- ── Panel toggle ──────────────────────────────────────────────────────────

local isOpen = false

local function openPanel()
    isOpen            = true
    ScanOverlay.Visible = false  -- FIX: reset scan overlay on every open
    Panel.Size        = UDim2.new(0, 0, 0, PH)
    Panel.Visible     = true
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
            StatsLbl.Text = string.format("✅ %d crops found", #foundCrops)
            break
        end
    end
end)

setTab("crops")