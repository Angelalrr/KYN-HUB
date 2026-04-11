-- =====================================================================
-- ⚡ KYN HUB - ELECTRIC BLUE EDITION (PC & MOBILE OPTIMIZED) ⚡
-- =====================================================================

local CoreGui           = game:GetService("CoreGui")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local UIS               = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local Lighting          = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local HttpService       = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local isForcingReset = false -- Variable para evitar conflictos entre Desync y Anti Ragdoll

local guiName = "KYNHubGUI_Electric"
local OLD = CoreGui:FindFirstChild(guiName)
if OLD then OLD:Destroy() end

-- ============================================================
-- // SISTEMA DE CONFIGURACIÓN (GUARDADO DE TOGGLES)
-- ============================================================
local CONFIG_FILE     = "KYN_Hub_Config.json"
local kynConfig       = {}
local kynRestoring    = false  
local pendingRestores = {}     

local function loadKYNConfig()
    if isfile and isfile(CONFIG_FILE) then
        pcall(function()
            local raw     = readfile(CONFIG_FILE)
            local decoded = HttpService:JSONDecode(raw)
            if type(decoded) == "table" then
                kynConfig = decoded
            end
        end)
    end
end

local function saveKYNConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(kynConfig))
        end)
    end
end

loadKYNConfig()

-- ===========================
-- PALETA DE COLORES
-- ===========================
local THEME = {
    BG        = Color3.fromRGB(8, 12, 20),
    Frame     = Color3.fromRGB(15, 20, 35),
    Primary   = Color3.fromRGB(0, 255, 255),
    Secondary = Color3.fromRGB(0, 80, 255),
    DarkBlue  = Color3.fromRGB(0, 20, 50),
    Neon1     = Color3.fromRGB(180, 230, 255),
    Dim       = Color3.fromRGB(100, 130, 170),
    BorderOff = Color3.fromRGB(40, 50, 70),
    Green     = Color3.fromRGB(0, 255, 150),
    Red       = Color3.fromRGB(255, 50, 80),
    Purple    = Color3.fromRGB(180, 50, 255),
}

-- ===========================
-- FUNCIONES ÚTILES
-- ===========================
local function tween(obj, props, time, style)
    TweenService:Create(obj, TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quint), props):Play()
end

local function corner(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius or 8)
    return c
end

local function stroke(parent, color, thick)
    local s = Instance.new("UIStroke", parent)
    s.Color = color or THEME.BorderOff
    s.Thickness = thick or 1.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return s
end

-- ===========================
-- SISTEMA DE NOTIFICACIONES
-- ===========================
local notifQueue      = {}
local notifRunning    = false
local notifContainer  = nil  

local function ensureNotifContainer()
    if notifContainer and notifContainer.Parent then return end
    local root = CoreGui:FindFirstChild(guiName)
    if not root then return end
    notifContainer = Instance.new("Frame", root)
    notifContainer.Name       = "KYN_NotifContainer"
    notifContainer.Size       = UDim2.new(0, 280, 1, 0)
    notifContainer.Position   = UDim2.new(0.5, -140, 0, 0)
    notifContainer.BackgroundTransparency = 1
    notifContainer.ZIndex     = 200
end

local function processNotifQueue()
    if notifRunning then return end
    notifRunning = true
    task.spawn(function()
        while #notifQueue > 0 do
            local data = table.remove(notifQueue, 1)
            ensureNotifContainer()
            if not notifContainer then task.wait(0.5) continue end

            local card = Instance.new("Frame", notifContainer)
            card.Size             = UDim2.new(1, 0, 0, 54)
            card.Position         = UDim2.new(0, 0, 0, -60)  
            card.BackgroundColor3 = THEME.BG
            card.ZIndex           = 201
            card.ClipsDescendants = false

            local cr = Instance.new("UICorner", card)
            cr.CornerRadius = UDim.new(0, 10)

            local cStroke = Instance.new("UIStroke", card)
            cStroke.Thickness = 3
            cStroke.Color     = Color3.new(1, 1, 1)
            cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local cGrad = Instance.new("UIGradient", cStroke)
            cGrad.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0,    THEME.Secondary),
                ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
                ColorSequenceKeypoint.new(0.5,  THEME.Primary),
                ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
                ColorSequenceKeypoint.new(1,    THEME.Secondary),
            }
            cGrad.Rotation = 0

            local rotConn
            rotConn = RunService.RenderStepped:Connect(function()
                if card and card.Parent then
                    cGrad.Rotation = (cGrad.Rotation + 3) % 360
                else
                    rotConn:Disconnect()
                end
            end)

            local icon = Instance.new("TextLabel", card)
            icon.Size               = UDim2.new(0, 36, 1, 0)
            icon.Position           = UDim2.new(0, 8, 0, 0)
            icon.BackgroundTransparency = 1
            icon.Text               = data.icon or "⚡"
            icon.Font               = Enum.Font.GothamBold
            icon.TextSize           = 22
            icon.TextColor3         = data.color or THEME.Primary
            icon.ZIndex             = 202

            local titleLbl = Instance.new("TextLabel", card)
            titleLbl.Size           = UDim2.new(1, -52, 0, 20)
            titleLbl.Position       = UDim2.new(0, 48, 0, 7)
            titleLbl.BackgroundTransparency = 1
            titleLbl.Text           = data.title or "KYN HUB"
            titleLbl.Font           = Enum.Font.GothamBlack
            titleLbl.TextSize       = 13
            titleLbl.TextColor3     = data.color or THEME.Primary
            titleLbl.TextXAlignment = Enum.TextXAlignment.Left
            titleLbl.ZIndex         = 202

            local bodyLbl = Instance.new("TextLabel", card)
            bodyLbl.Size            = UDim2.new(1, -52, 0, 18)
            bodyLbl.Position        = UDim2.new(0, 48, 0, 28)
            bodyLbl.BackgroundTransparency = 1
            bodyLbl.Text            = data.msg or ""
            bodyLbl.Font            = Enum.Font.Gotham
            bodyLbl.TextSize        = 11
            bodyLbl.TextColor3      = THEME.Neon1
            bodyLbl.TextXAlignment  = Enum.TextXAlignment.Left
            bodyLbl.ZIndex          = 202

            TweenService:Create(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, 0, 0, 14)}):Play()

            task.wait(data.duration or 2.8)

            local t = TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
                {Position = UDim2.new(0, 0, 0, -65)})
            t:Play()
            t.Completed:Wait()
            rotConn:Disconnect()
            card:Destroy()

            task.wait(0.15) 
        end
        notifRunning = false
    end)
end

local function KYNNotify(title, msg, icon, color, duration)
    if kynRestoring then return end  
    table.insert(notifQueue, {
        title    = title,
        msg      = msg,
        icon     = icon or "⚡",
        color    = color or THEME.Primary,
        duration = duration or 2.8,
    })
    processNotifQueue()
end

local espGradientColor = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(0, 80, 255)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0, 20, 50)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0, 255, 255)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 20, 50)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(0, 80, 255)),
}
local espStealerGradientColor = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(200, 80,  0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(255, 220, 0)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(200, 80,  0)),
}
local espMineGradientColor = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(100, 0, 255)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(200, 50, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(100, 0, 255)),
}

local espGradients = {}

local function makeStyledBillboard(adornee, size, offset, textColor, text, gradColor)
    local bb = Instance.new("BillboardGui")
    bb.Size = size or UDim2.new(0, 160, 0, 36)
    bb.StudsOffset = offset or Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = adornee
    bb.Parent = adornee

    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.45
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

    local uiStroke = Instance.new("UIStroke", bg)
    uiStroke.Thickness = 2
    uiStroke.Color = Color3.new(1, 1, 1)
    uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local grad = Instance.new("UIGradient", uiStroke)
    grad.Color = gradColor or espGradientColor
    grad.Rotation = 0
    table.insert(espGradients, grad)

    local lbl = Instance.new("TextLabel", bg)
    lbl.Name = "Label"
    lbl.Size = UDim2.new(1, -8, 1, 0)
    lbl.Position = UDim2.new(0, 4, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = textColor or THEME.Primary
    lbl.TextStrokeTransparency = 0.5
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.Text = text or ""
    lbl.ZIndex = 2
    return bb, lbl
end

local function MakeDraggable(dragFrame, handle)
    handle = handle or dragFrame
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            dragFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ===========================
-- SETUP PRINCIPAL
-- ===========================
local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local btnDragFrame = Instance.new("Frame", gui)
btnDragFrame.Size = UDim2.new(0, 55, 0, 55)
btnDragFrame.Position = UDim2.new(0, 20, 0.2, 0)
btnDragFrame.BackgroundTransparency = 1
btnDragFrame.Active = true

local toggleBtn = Instance.new("ImageButton", btnDragFrame)
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.Image = "rbxassetid://82945336379835"
toggleBtn.BackgroundColor3 = THEME.Frame
toggleBtn.Active = true
corner(toggleBtn, 50)

local btnStroke = stroke(toggleBtn, Color3.new(1, 1, 1), 3)
local btnGradient = Instance.new("UIGradient", btnStroke)
btnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    THEME.Secondary),
    ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
    ColorSequenceKeypoint.new(0.5,  THEME.Primary),
    ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
    ColorSequenceKeypoint.new(1,    THEME.Secondary),
}

MakeDraggable(btnDragFrame, toggleBtn)

toggleBtn.MouseEnter:Connect(function()
    tween(toggleBtn, {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}, 0.2, Enum.EasingStyle.Back)
end)
toggleBtn.MouseLeave:Connect(function()
    tween(toggleBtn, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Back)
end)

local mainDragFrame = Instance.new("Frame", gui)
mainDragFrame.Size = UDim2.new(0, 300, 0, 370)
mainDragFrame.Position = UDim2.new(0.5, -150, 0.5, -185)
mainDragFrame.BackgroundTransparency = 1
mainDragFrame.Active = true
mainDragFrame.Visible = false

local mainFrame = Instance.new("Frame", mainDragFrame)
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = THEME.BG
mainFrame.ClipsDescendants = false
corner(mainFrame, 12)

local uiScale = Instance.new("UIScale", mainDragFrame)
uiScale.Scale = 0

local mainStroke = stroke(mainFrame, Color3.new(1, 1, 1), 4)
local mainGradient = Instance.new("UIGradient", mainStroke)
mainGradient.Color = btnGradient.Color

local glass = Instance.new("Frame", mainFrame)
glass.Size = UDim2.new(1, 0, 1, 0)
glass.BackgroundTransparency = 1
glass.ClipsDescendants = true
glass.ZIndex = 0
corner(glass, 12)

for i = 1, 15 do
    local dot = Instance.new("Frame", glass)
    dot.Size = UDim2.new(0, 3, 0, 3)
    dot.Position = UDim2.new(math.random(), 0, math.random(), 0)
    dot.BackgroundColor3 = THEME.Primary
    dot.BackgroundTransparency = math.random(40, 80) / 100
    corner(dot, 50)
    task.spawn(function()
        while dot and dot.Parent do
            local t = math.random(5, 12)
            tween(dot, {Position = UDim2.new(math.random(), 0, math.random(), 0)}, t, Enum.EasingStyle.Sine)
            task.wait(t)
        end
    end)
end

local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = THEME.Frame
header.BorderSizePixel = 0
header.Active = true
header.ZIndex = 5
corner(header, 12)

local headerPatch = Instance.new("Frame", header)
headerPatch.Size = UDim2.new(1, 0, 0, 10)
headerPatch.Position = UDim2.new(0, 0, 1, -10)
headerPatch.BackgroundColor3 = THEME.Frame
headerPatch.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ KYN HUB"
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextColor3 = THEME.Primary

MakeDraggable(mainDragFrame, header)

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -35, 0.5, -13)
closeBtn.Text = "X"
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
closeBtn.TextColor3 = THEME.Dim
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 13
closeBtn.ZIndex = 10
corner(closeBtn, 6)
local closeStroke = stroke(closeBtn, THEME.BorderOff, 1.5)

closeBtn.MouseEnter:Connect(function()
    tween(closeBtn, {BackgroundColor3 = THEME.Red, TextColor3 = Color3.new(1, 1, 1)}, 0.2)
    tween(closeStroke, {Color = THEME.Red}, 0.2)
end)
closeBtn.MouseLeave:Connect(function()
    tween(closeBtn, {BackgroundColor3 = Color3.fromRGB(30, 40, 55), TextColor3 = THEME.Dim}, 0.2)
    tween(closeStroke, {Color = THEME.BorderOff}, 0.2)
end)

local overlayConfirm = Instance.new("Frame", mainFrame)
overlayConfirm.Size = UDim2.new(1, 0, 1, 0)
overlayConfirm.BackgroundColor3 = Color3.new(0, 0, 0)
overlayConfirm.BackgroundTransparency = 1
overlayConfirm.Visible = false
overlayConfirm.Active = true
overlayConfirm.ZIndex = 50
corner(overlayConfirm, 12)

local confirmBox = Instance.new("Frame", overlayConfirm)
confirmBox.Size = UDim2.new(0, 220, 0, 110)
confirmBox.Position = UDim2.new(0.5, -110, 0.5, -55)
confirmBox.BackgroundColor3 = THEME.Frame
confirmBox.ZIndex = 51
corner(confirmBox, 10)
stroke(confirmBox, THEME.Red, 2)

local confirmScale = Instance.new("UIScale", confirmBox)
confirmScale.Scale = 0

local confirmText = Instance.new("TextLabel", confirmBox)
confirmText.Size = UDim2.new(1, 0, 0, 50)
confirmText.BackgroundTransparency = 1
confirmText.Text = "¿Destruir KYN Hub?"
confirmText.Font = Enum.Font.GothamBold
confirmText.TextSize = 15
confirmText.TextColor3 = THEME.Neon1
confirmText.ZIndex = 52

local btnYes = Instance.new("TextButton", confirmBox)
btnYes.Size = UDim2.new(0, 90, 0, 30)
btnYes.Position = UDim2.new(0, 15, 0, 65)
btnYes.BackgroundColor3 = THEME.Red
btnYes.Text = "Sí"
btnYes.Font = Enum.Font.GothamBold
btnYes.TextColor3 = Color3.new(1, 1, 1)
btnYes.ZIndex = 52
corner(btnYes, 6)
stroke(btnYes, THEME.Red, 1.5)

local btnNo = Instance.new("TextButton", confirmBox)
btnNo.Size = UDim2.new(0, 90, 0, 30)
btnNo.Position = UDim2.new(1, -105, 0, 65)
btnNo.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
btnNo.Text = "No"
btnNo.Font = Enum.Font.GothamBold
btnNo.TextColor3 = THEME.Dim
btnNo.ZIndex = 52
corner(btnNo, 6)
stroke(btnNo, THEME.BorderOff, 1.5)

closeBtn.Activated:Connect(function()
    overlayConfirm.Visible = true
    tween(overlayConfirm, {BackgroundTransparency = 0.5}, 0.2)
    tween(confirmScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back)
end)

btnNo.Activated:Connect(function()
    tween(overlayConfirm, {BackgroundTransparency = 1}, 0.2)
    local t = TweenService:Create(confirmScale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
    t:Play(); t.Completed:Wait()
    overlayConfirm.Visible = false
end)

btnYes.Activated:Connect(function()
    tween(uiScale, {Scale = 0}, 0.3, Enum.EasingStyle.Back)
    tween(btnDragFrame, {Size = UDim2.new(0, 0, 0, 0)}, 0.3)
    task.wait(0.3)
    gui:Destroy()
end)

local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, 0, 0, 30)
tabContainer.Position = UDim2.new(0, 0, 0, 50)
tabContainer.BackgroundTransparency = 1
tabContainer.ZIndex = 2

local tabLayout = Instance.new("UIListLayout", tabContainer)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Position = UDim2.new(0, 0, 0, 90)
contentFrame.Size = UDim2.new(1, 0, 1, -100)
contentFrame.BackgroundTransparency = 1
contentFrame.ZIndex = 2

local tabs, tabButtons, tabStrokes = {}, {}, {}

local function createTab(name)
    local tab = Instance.new("ScrollingFrame", contentFrame)
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.ScrollBarThickness = 2
    tab.ScrollBarImageColor3 = THEME.Primary
    tab.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    tab.Visible = false
    tab.ZIndex = 2

    local layout = Instance.new("UIListLayout", tab)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local padding = Instance.new("UIPadding", tab)
    padding.PaddingTop    = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 4)
    padding.PaddingLeft   = UDim.new(0, 6)
    padding.PaddingRight  = UDim.new(0, 6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 15)
    end)

    tabs[name] = tab
    return tab
end

local function setActiveTab(name)
    for tabName, tab in pairs(tabs) do
        tab.Visible = (tabName == name)
    end
    for tabName, btn in pairs(tabButtons) do
        local st = tabStrokes[tabName]
        if tabName == name then
            tween(btn, {BackgroundColor3 = THEME.Primary, TextColor3 = THEME.BG}, 0.2)
            tween(st,  {Color = THEME.Primary}, 0.2)
        else
            tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 40, 55), TextColor3 = THEME.Dim}, 0.2)
            tween(st,  {Color = THEME.BorderOff}, 0.2)
        end
    end
end

local function createTabButton(text, tabName)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0, 85, 0, 28)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    corner(btn, 6)

    local st = stroke(btn, THEME.BorderOff, 1.5)
    tabStrokes[tabName] = st
    tabButtons[tabName] = btn

    btn.Activated:Connect(function() setActiveTab(tabName) end)
end

createTab("Main"); createTab("Visual"); createTab("Misc")
createTabButton("Main", "Main"); createTabButton("Visual", "Visual"); createTabButton("Misc", "Misc")
setActiveTab("Main")

_G.KYNAddToggle = function(tabName, data)
    local tab = tabs[tabName]
    if not tab then return end

    local btn = Instance.new("TextButton", tab)
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = THEME.Frame
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    corner(btn, 8)

    local bStroke = stroke(btn, THEME.BorderOff, 1.5)

    local track = Instance.new("Frame", btn)
    track.Size = UDim2.new(0, 36, 0, 16)
    track.Position = UDim2.new(1, -48, 0.5, -8)
    track.BackgroundColor3 = Color3.fromRGB(30, 45, 70)
    track.ZIndex = 2
    corner(track, 50)

    local trackStroke = stroke(track, THEME.BorderOff, 1)

    local dot = Instance.new("Frame", track)
    dot.Size = UDim2.new(0, 12, 0, 12)
    dot.Position = UDim2.new(0, 2, 0.5, -6)
    dot.BackgroundColor3 = Color3.new(1, 1, 1)
    dot.ZIndex = 2
    corner(dot, 50)

    if data.Disabled then
        btn.Text = "   " .. (data.Name or "Toggle") .. "  (Próximamente)"
        btn.TextColor3 = Color3.fromRGB(55, 65, 85)
        track.BackgroundColor3 = Color3.fromRGB(20, 28, 45)
        dot.BackgroundColor3 = Color3.fromRGB(50, 60, 80)
        return {}
    end

    btn.Text = "   " .. (data.Name or "Toggle")
    btn.TextColor3 = THEME.Dim

    local configKey = tabName .. "_" .. (data.Name or "Toggle")
    local state = false

    local function applyVisual(s)
        TweenService:Create(dot,         TweenInfo.new(0.25, Enum.EasingStyle.Back), {Position = s and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play()
        TweenService:Create(track,       TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {BackgroundColor3 = s and THEME.Primary or Color3.fromRGB(30,45,70)}):Play()
        TweenService:Create(btn,         TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {TextColor3 = s and THEME.Neon1 or THEME.Dim}):Play()
        TweenService:Create(bStroke,     TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Color = s and THEME.Primary or THEME.BorderOff}):Play()
        TweenService:Create(trackStroke, TweenInfo.new(0.2,  Enum.EasingStyle.Quint), {Color = s and THEME.Primary or THEME.BorderOff}):Play()
    end

    local controller = {}
    function controller:SetState(newState, silent)
        state = newState
        applyVisual(state)
        kynConfig[configKey] = state
        saveKYNConfig()
        if not silent and data.Callback then
            pcall(data.Callback, state)
        end
    end
    function controller:GetState() return state end

    btn.Activated:Connect(function()
        if controller.ExclusiveGroup then
            for _, other in ipairs(controller.ExclusiveGroup) do
                if other ~= controller and other.GetState and other:GetState() then
                    other:SetState(false)
                end
            end
        end
        controller:SetState(not state)
    end)

    if kynConfig[configKey] == true then
        table.insert(pendingRestores, function()
            state = true
            applyVisual(true)
            if data.Callback then
                pcall(data.Callback, true)
            end
        end)
    end

    return controller
end

local speed = 2.5
local distance = 6

RunService.RenderStepped:Connect(function()
    btnGradient.Rotation  = (btnGradient.Rotation  + 2)   % 360
    mainGradient.Rotation = (mainGradient.Rotation + 1.5) % 360
    local wave = math.sin(tick() * speed) * distance
    toggleBtn.Position = UDim2.new(0, 0, 0, wave)
    mainFrame.Position = UDim2.new(0, 0, 0, wave)
    for i = #espGradients, 1, -1 do
        local g = espGradients[i]
        if g and g.Parent then
            g.Rotation = (g.Rotation + 2) % 360
        else
            table.remove(espGradients, i)
        end
    end
end)

local isOpen = false
local isAnimating = false

local function toggleMenu()
    if isAnimating then return end
    isAnimating = true
    isOpen = not isOpen
    if isOpen then
        mainDragFrame.Visible = true
        local t = TweenService:Create(uiScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1})
        t:Play(); t.Completed:Wait()
    else
        local t = TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
        t:Play(); t.Completed:Wait()
        mainDragFrame.Visible = false
    end
    isAnimating = false
end

local btnClickStartPos = Vector2.new()
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnClickStartPos = input.Position
    end
end)
toggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local delta = (input.Position - btnClickStartPos).Magnitude
        if delta < 5 then toggleMenu() end
    end
end)

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

-- ============================================================
-- // LÓGICA DE LOS SCRIPTS (SIN GUIs EXTERNAS)
-- ============================================================

-- ===========================
-- AUTO STEAL (INSTA-GRAB + ESP)
-- ===========================
local autoStealActive = false
local autoStealGui = nil
local autoStealLoop1 = nil
local autoStealLoop2 = nil

local function startAutoSteal()
    if autoStealActive then return end
    autoStealActive = true

    local Packages = ReplicatedStorage:WaitForChild("Packages")
    local Datas = ReplicatedStorage:WaitForChild("Datas")
    local Shared = ReplicatedStorage:WaitForChild("Shared")
    local Utils = ReplicatedStorage:WaitForChild("Utils")

    local Synchronizer = require(Packages:WaitForChild("Synchronizer"))
    local AnimalsData = require(Datas:WaitForChild("Animals"))
    local AnimalsShared = require(Shared:WaitForChild("Animals"))
    local NumberUtils = require(Utils:WaitForChild("NumberUtils"))

    local validKeywords = {"steal", "robar", "grab", "take", "tomar", "agarrar", "saquear"}
    local manualTargetUid, currentTargetUid, activeTargetData, lastKnownHighestUid = nil, nil, nil, nil
    local COOLDOWN_TIME = 0.05
    local LastGrabTime = 0

    local currentBeam, att0, att1, currentBillboard = nil, nil, nil, nil

    local function clearVisuals()
        if currentBeam then currentBeam:Destroy() currentBeam = nil end
        if att0 then att0:Destroy() att0 = nil end
        if att1 then att1:Destroy() att1 = nil end
        if currentBillboard then currentBillboard:Destroy() currentBillboard = nil end
    end

    local function getTargetPart(plotName, slot)
        local plot = Workspace.Plots:FindFirstChild(plotName)
        if plot then
            local pod = plot:FindFirstChild("AnimalPodiums") and plot.AnimalPodiums:FindFirstChild(slot)
            if pod then
                return pod:FindFirstChild("Base") and pod.Base:FindFirstChild("Spawn")
            end
        end
        return nil
    end

    local function updateVisuals(target)
        if not target then clearVisuals() return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local targetPart = getTargetPart(target.plot, target.slot)

        if not hrp or not targetPart then clearVisuals() return end

        if not att0 or att0.Parent ~= hrp then
            if att0 then att0:Destroy() end
            att0 = Instance.new("Attachment", hrp)
        end
        if not att1 or att1.Parent ~= targetPart then
            if att1 then att1:Destroy() end
            att1 = Instance.new("Attachment", targetPart)
        end

        if not currentBeam then
            currentBeam = Instance.new("Beam")
            currentBeam.FaceCamera = true
            currentBeam.Width0 = 0.6
            currentBeam.Width1 = 0.6
            currentBeam.Color = ColorSequence.new(THEME.Primary)
            currentBeam.Transparency = NumberSequence.new(0.3)
            currentBeam.Parent = Workspace
        end
        currentBeam.Attachment0 = att0
        currentBeam.Attachment1 = att1

        if not currentBillboard or currentBillboard.Adornee ~= targetPart then
            if currentBillboard then currentBillboard:Destroy() end
            currentBillboard = Instance.new("BillboardGui")
            currentBillboard.Name = "AutoGrabESP"
            currentBillboard.Size = UDim2.new(0, 160, 0, 45)
            currentBillboard.StudsOffset = Vector3.new(0, 3.5, 0)
            currentBillboard.AlwaysOnTop = true
            currentBillboard.Adornee = targetPart
            currentBillboard.Parent = CoreGui

            local bg = Instance.new("Frame", currentBillboard)
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            bg.BackgroundTransparency = 0.45
            bg.BorderSizePixel = 0
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)
            
            -- BORDE GIRATORIO (IGUAL QUE LOS OTROS ESP)
            local stroke = Instance.new("UIStroke", bg)
            stroke.Thickness = 2
            stroke.Color = Color3.new(1, 1, 1)
            stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local grad = Instance.new("UIGradient", stroke)
            grad.Color = espGradientColor
            grad.Rotation = 0
            table.insert(espGradients, grad)

            local nameLbl = Instance.new("TextLabel", bg)
            nameLbl.Name = "PetName"
            nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
            nameLbl.Position = UDim2.new(0, 0, 0, 2)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBlack
            nameLbl.TextSize = 13
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            local valLbl = Instance.new("TextLabel", bg)
            valLbl.Name = "PetVal"
            valLbl.Size = UDim2.new(1, 0, 0.5, 0)
            valLbl.Position = UDim2.new(0, 0, 0.5, -2)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = Enum.Font.GothamBold
            valLbl.TextSize = 12
            valLbl.TextColor3 = THEME.Primary
        end

        if currentBillboard then
            local bg = currentBillboard:FindFirstChildOfClass("Frame")
            if bg then
                bg.PetName.Text = target.name
                bg.PetVal.Text = target.genText
            end
        end
    end

    if CoreGui:FindFirstChild("KYN_AutoStealGUI") then CoreGui.KYN_AutoStealGUI:Destroy() end
    autoStealGui = Instance.new("ScreenGui", CoreGui)
    autoStealGui.Name = "KYN_AutoStealGUI"
    autoStealGui.ResetOnSpawn = false

    local asMain = Instance.new("Frame", autoStealGui)
    asMain.Size = UDim2.new(0, 300, 0, 350)
    asMain.Position = UDim2.new(0.5, 160, 0.5, -175)
    asMain.BackgroundColor3 = THEME.BG
    asMain.BorderSizePixel = 0
    asMain.Active = true
    corner(asMain, 12)

    local asStroke = stroke(asMain, THEME.Primary, 2)
    local asGrad = Instance.new("UIGradient", asStroke)
    asGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, THEME.Secondary),
        ColorSequenceKeypoint.new(0.50, THEME.Primary),
        ColorSequenceKeypoint.new(1.00, THEME.Secondary)
    })
    
    task.spawn(function()
        while autoStealGui and autoStealGui.Parent do
            asGrad.Rotation = (asGrad.Rotation + 4) % 360
            task.wait(0.02)
        end
    end)

    local title = Instance.new("TextLabel", asMain)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "⚡ KYN HUB - INSTA-GRAB"
    title.TextColor3 = THEME.Primary
    title.TextSize = 16
    title.Font = Enum.Font.GothamBlack

    local divider = Instance.new("Frame", asMain)
    divider.Size = UDim2.new(0.9, 0, 0, 2)
    divider.Position = UDim2.new(0.05, 0, 0, 45)
    divider.BackgroundColor3 = THEME.Primary
    divider.BackgroundTransparency = 0.5
    divider.BorderSizePixel = 0

    local statusTitle = Instance.new("TextLabel", asMain)
    statusTitle.Size = UDim2.new(1, -20, 0, 20)
    statusTitle.Position = UDim2.new(0, 10, 0, 50)
    statusTitle.BackgroundTransparency = 1
    statusTitle.Text = "Buscando objetivos..."
    statusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusTitle.Font = Enum.Font.GothamBold
    statusTitle.TextSize = 13
    statusTitle.TextXAlignment = Enum.TextXAlignment.Center

    local barBG = Instance.new("Frame", asMain)
    barBG.Size = UDim2.new(0.9, 0, 0, 8)
    barBG.Position = UDim2.new(0.05, 0, 0, 85)
    barBG.BackgroundColor3 = THEME.Frame
    barBG.BorderSizePixel = 0
    barBG.ClipsDescendants = true
    barBG.BackgroundTransparency = 0.5
    corner(barBG, 50)

    local barFill = Instance.new("Frame", barBG)
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = THEME.Primary
    barFill.BorderSizePixel = 0
    corner(barFill, 50)

    local ListTitle = Instance.new("TextLabel", asMain)
    ListTitle.Size = UDim2.new(1, -20, 0, 20)
    ListTitle.Position = UDim2.new(0, 10, 0, 105)
    ListTitle.BackgroundTransparency = 1
    ListTitle.Text = "MASCOTAS DISPONIBLES (Click para forzar)"
    ListTitle.TextColor3 = THEME.Dim
    ListTitle.Font = Enum.Font.GothamBold
    ListTitle.TextSize = 11
    ListTitle.TextXAlignment = Enum.TextXAlignment.Left

    local ListScroll = Instance.new("ScrollingFrame", asMain)
    ListScroll.Size = UDim2.new(1, -20, 1, -135)
    ListScroll.Position = UDim2.new(0, 10, 0, 125)
    ListScroll.BackgroundTransparency = 1
    ListScroll.BorderSizePixel = 0
    ListScroll.ScrollBarThickness = 4
    ListScroll.ScrollBarImageColor3 = THEME.Primary
    local UIListLayout = Instance.new("UIListLayout", ListScroll)
    UIListLayout.Padding = UDim.new(0, 5)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    MakeDraggable(asMain)

    local function formatMoney(val)
        local success, result = pcall(function() return NumberUtils:ToString(val) end)
        return success and ("$" .. result .. "/s") or ("$" .. tostring(val) .. "/s")
    end

    local function getAvailablePets()
        local pets = {}
        local plots = Workspace:FindFirstChild("Plots")
        if not plots then return pets end

        for _, plot in ipairs(plots:GetChildren()) do
            local channel = Synchronizer:Get(plot.Name)
            if channel then
                local owner = channel:Get("Owner")
                local isMine = false
                if typeof(owner) == "Instance" and owner == LocalPlayer then isMine = true end
                if typeof(owner) == "table" and owner.UserId == LocalPlayer.UserId then isMine = true end

                if not isMine then
                    local animalList = channel:Get("AnimalList")
                    if animalList then
                        for slot, data in pairs(animalList) do
                            if type(data) == "table" then
                                local aName = data.Index
                                local aInfo = AnimalsData[aName]
                                local displayName = aInfo and aInfo.DisplayName or aName
                                local genValue = AnimalsShared:GetGeneration(aName, data.Mutation, data.Traits, nil)
                                table.insert(pets, {
                                    uid = plot.Name .. "_" .. tostring(slot),
                                    plot = plot.Name,
                                    slot = tostring(slot),
                                    name = displayName,
                                    genValue = genValue,
                                    genText = formatMoney(genValue)
                                })
                            end
                        end
                    end
                end
            end
        end
        return pets
    end

    local function UpdateUI(sortedPets)
        for _, child in ipairs(ListScroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        local count = #sortedPets
        for i = 1, count do
            local pet = sortedPets[i]
            local isTarget = (pet.uid == currentTargetUid)
            
            local ItemBtn = Instance.new("TextButton", ListScroll)
            ItemBtn.Size = UDim2.new(1, -8, 0, 28)
            ItemBtn.BackgroundColor3 = isTarget and THEME.DarkBlue or THEME.Frame
            ItemBtn.BorderSizePixel = 0; ItemBtn.Text = ""; ItemBtn.AutoButtonColor = false
            corner(ItemBtn, 4)
            
            ItemBtn.MouseButton1Click:Connect(function() manualTargetUid = pet.uid end)
            
            if isTarget then
                local Stroke = Instance.new("UIStroke", ItemBtn)
                Stroke.Color = THEME.Primary; Stroke.Thickness = 1
            end
            
            local RankLbl = Instance.new("TextLabel", ItemBtn)
            RankLbl.Size = UDim2.new(0, 20, 1, 0); RankLbl.Position = UDim2.new(0, 5, 0, 0)
            RankLbl.BackgroundTransparency = 1; RankLbl.Text = "#" .. i
            RankLbl.TextColor3 = isTarget and THEME.Primary or THEME.Dim
            RankLbl.Font = Enum.Font.GothamBlack; RankLbl.TextSize = 12
            
            local NameLbl = Instance.new("TextLabel", ItemBtn)
            NameLbl.Size = UDim2.new(1, -95, 1, 0); NameLbl.Position = UDim2.new(0, 30, 0, 0)
            NameLbl.BackgroundTransparency = 1; NameLbl.Text = pet.name
            NameLbl.TextColor3 = Color3.new(1,1,1); NameLbl.Font = Enum.Font.GothamMedium
            NameLbl.TextSize = 11; NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            
            local ValLbl = Instance.new("TextLabel", ItemBtn)
            ValLbl.Size = UDim2.new(0, 60, 1, 0); ValLbl.Position = UDim2.new(1, -65, 0, 0)
            ValLbl.BackgroundTransparency = 1; ValLbl.Text = pet.genText
            ValLbl.TextColor3 = THEME.Neon1; ValLbl.Font = Enum.Font.GothamBold
            ValLbl.TextSize = 10; ValLbl.TextXAlignment = Enum.TextXAlignment.Right
        end
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 33)
    end

    local function isTargetPrompt(prompt)
        if not prompt:IsA("ProximityPrompt") then return false end
        local textToSearch = string.lower((prompt.ActionText or "") .. " " .. (prompt.Name or "") .. " " .. (prompt.ObjectText or ""))
        for _, word in ipairs(validKeywords) do
            if string.find(textToSearch, word) then return true end
        end
        return false
    end

    local function findTargetPrompt(plotName, slot)
        local spawnPart = getTargetPart(plotName, slot)
        if not spawnPart then return nil end
        local base = spawnPart.Parent
        if base then
            for _, obj in ipairs(base:GetDescendants()) do
                if isTargetPrompt(obj) then return obj end
            end
        end
        return nil
    end

    local function executeGodGrab(prompt)
        pcall(function()
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 50 
            prompt.HoldDuration = 0 
            prompt.Enabled = true
            task.spawn(function()
                prompt:InputHoldBegin()
                task.wait() 
                prompt:InputHoldEnd()
            end)
            if fireproximityprompt then fireproximityprompt(prompt) end
        end)
    end

    local isVisualizing = false
    local function triggerBarEffect()
        if isVisualizing then return end
        isVisualizing = true
        barFill.Size = UDim2.new(0, 0, 1, 0)
        barBG.BackgroundTransparency = 0
        TweenService:Create(barFill, TweenInfo.new(0.05, Enum.EasingStyle.Linear), {Size = UDim2.new(1, 0, 1, 0)}):Play()
        task.wait(0.15)
        TweenService:Create(barFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 1, 0)}):Play()
        barBG.BackgroundTransparency = 0.5
        task.wait(0.1)
        isVisualizing = false
    end

    autoStealLoop1 = task.spawn(function()
        while autoStealActive do
            task.wait(0.5)
            local allPets = getAvailablePets()
            table.sort(allPets, function(a, b) return a.genValue > b.genValue end)
            
            if #allPets > 0 then
                local newTop1 = allPets[1]
                if newTop1.uid ~= lastKnownHighestUid then
                    lastKnownHighestUid = newTop1.uid
                    manualTargetUid = nil 
                end
                local foundManual = false
                if manualTargetUid then
                    for _, p in ipairs(allPets) do
                        if p.uid == manualTargetUid then
                            foundManual = true
                            currentTargetUid = manualTargetUid
                            activeTargetData = p
                            break
                        end
                    end
                end
                if not foundManual then
                    manualTargetUid = nil
                    currentTargetUid = newTop1.uid
                    activeTargetData = newTop1
                end
                local isManual = manualTargetUid and " [Fijado]" or ""
                statusTitle.Text = string.format("🎯 %s%s", activeTargetData.name, isManual)
                updateVisuals(activeTargetData)
            else
                currentTargetUid = nil
                activeTargetData = nil
                statusTitle.Text = "No hay objetivos en el mapa"
                updateVisuals(nil)
            end
            UpdateUI(allPets)
        end
    end)

    autoStealLoop2 = RunService.Heartbeat:Connect(function()
        if not activeTargetData then return end
        local now = os.clock()
        if (now - LastGrabTime) < COOLDOWN_TIME then return end
        local prompt = findTargetPrompt(activeTargetData.plot, activeTargetData.slot)
        if prompt and prompt.Parent and prompt.Enabled then
            LastGrabTime = now
            executeGodGrab(prompt)
            task.spawn(triggerBarEffect)
        end
    end)
end

local function stopAutoSteal()
    autoStealActive = false
    if autoStealLoop1 then task.cancel(autoStealLoop1); autoStealLoop1 = nil end
    if autoStealLoop2 then autoStealLoop2:Disconnect(); autoStealLoop2 = nil end
    if autoStealGui then autoStealGui:Destroy(); autoStealGui = nil end
    for _, v in pairs(CoreGui:GetChildren()) do
        if v.Name == "AutoGrabESP" then v:Destroy() end
    end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        for _, v in pairs(char.HumanoidRootPart:GetChildren()) do
            if v:IsA("Attachment") then v:Destroy() end
        end
    end
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Beam") then v:Destroy() end
    end
end


-- ===========================
-- VISUAL: ESP PLAYER
-- ===========================
local espPlayerConn
local espPlayerFolder

local function startESPPlayer()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    if espPlayerFolder then espPlayerFolder:Destroy() end
    espPlayerFolder = Instance.new("Folder")
    espPlayerFolder.Name = "KYN_PlayerESP"
    espPlayerFolder.Parent = PlayerGui

    local function createOrUpdatePlayerESP(player)
        if player == LocalPlayer then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart

        local highlight = espPlayerFolder:FindFirstChild(player.Name .. "_Highlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = player.Name .. "_Highlight"
            highlight.FillColor = Color3.fromRGB(0, 0, 255)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = espPlayerFolder
        end
        highlight.Adornee = player.Character

        local billboard = hrp:FindFirstChild("KYN_PlayerBB")
        local textLabel
        if not billboard then
            billboard, textLabel = makeStyledBillboard(
                hrp,
                UDim2.new(0, 160, 0, 36),
                Vector3.new(0, 3.2, 0),
                Color3.fromRGB(0, 255, 255),
                player.Name,
                espGradientColor
            )
            billboard.Name = "KYN_PlayerBB"
        else
            textLabel = billboard:FindFirstChild("Label", true)
        end
        if textLabel then textLabel.Text = player.Name end
    end

    espPlayerConn = RunService.Heartbeat:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            pcall(function() createOrUpdatePlayerESP(player) end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if not espPlayerFolder then return end
        local hl = espPlayerFolder:FindFirstChild(player.Name .. "_Highlight")
        if hl then hl:Destroy() end
        if player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local bb = hrp:FindFirstChild("KYN_PlayerBB")
                if bb then bb:Destroy() end
            end
        end
    end)
end

local function stopESPPlayer()
    if espPlayerConn then espPlayerConn:Disconnect(); espPlayerConn = nil end
    if espPlayerFolder then espPlayerFolder:Destroy(); espPlayerFolder = nil end
end

-- ===========================
-- VISUAL: ESP BASE TIME
-- ===========================
local espBaseConn

local function startESPBase()
    local function getOwnBasePosition()
        local Plots = Workspace:FindFirstChild("Plots")
        if not Plots then return nil end
        for _, plot in ipairs(Plots:GetChildren()) do
            local sign = plot:FindFirstChild("PlotSign")
            local base = plot:FindFirstChild("DeliveryHitbox")
            if sign and sign:FindFirstChild("YourBase") and sign.YourBase.Enabled and base then
                return base.Position
            end
        end
        return nil
    end

    local function updatePlotESP(plot, ownBasePos)
        local purchases = plot:FindFirstChild("Purchases")
        if not purchases then return end
        local plotBlock = purchases:FindFirstChild("PlotBlock")
        if not plotBlock or not plotBlock:FindFirstChild("Main") then return end
        local main = plotBlock.Main
        local baseBillboard = main:FindFirstChildOfClass("BillboardGui")
        local remainingTimeGui = baseBillboard and baseBillboard:FindFirstChild("RemainingTime")
        local base = plot:FindFirstChild("DeliveryHitbox")
        if base and ownBasePos and (base.Position - ownBasePos).Magnitude < 1 then return end

        local billboard = main:FindFirstChild("KYN_ESP_Billboard")
        local textLabel
        if not billboard then
            billboard, textLabel = makeStyledBillboard(
                main,
                UDim2.new(0, 180, 0, 36),
                Vector3.new(0, 5, 0),
                Color3.fromRGB(255, 255, 255),
                "Loading...",
                espGradientColor
            )
            billboard.Name = "KYN_ESP_Billboard"
        else
            textLabel = billboard:FindFirstChild("Label", true)
        end

        if textLabel and remainingTimeGui then
            if remainingTimeGui:IsA("TextLabel") then
                local text = remainingTimeGui.Text
                if text == "0s" or text == "0" then
                    textLabel.Text = "✅ Unlocked"
                    textLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                else
                    textLabel.Text = "⏱ " .. text
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            elseif remainingTimeGui:IsA("NumberValue") then
                if remainingTimeGui.Value <= 0 then
                    textLabel.Text = "✅ Unlocked"
                    textLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
                else
                    textLabel.Text = "⏱ " .. remainingTimeGui.Value .. "s"
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end

    espBaseConn = RunService.Heartbeat:Connect(function()
        local Plots = Workspace:FindFirstChild("Plots")
        if not Plots then return end
        local ownBasePos = getOwnBasePosition()
        for _, plot in pairs(Plots:GetChildren()) do
            pcall(function() updatePlotESP(plot, ownBasePos) end)
        end
    end)
end

local function stopESPBase()
    if espBaseConn then espBaseConn:Disconnect(); espBaseConn = nil end
    local Plots = Workspace:FindFirstChild("Plots")
    if not Plots then return end
    for _, plot in pairs(Plots:GetChildren()) do
        pcall(function()
            local purchases = plot:FindFirstChild("Purchases")
            if not purchases then return end
            local plotBlock = purchases:FindFirstChild("PlotBlock")
            if not plotBlock or not plotBlock:FindFirstChild("Main") then return end
            local b = plotBlock.Main:FindFirstChild("KYN_ESP_Billboard")
            if b then b:Destroy() end
        end)
    end
end

-- ===========================
-- VISUAL: ESP STEALERS
-- ===========================
local espStealersConn
local espStealersActive = false

local function startESPStealers()
    espStealersActive = true

    local function getJugadoresRobando()
        local ladrones = {}
        local objetosRobados = CollectionService:GetTagged("ClientRenderBrainrot")
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if char then
                for _, obj in pairs(objetosRobados) do
                    if obj:IsDescendantOf(char) then
                        ladrones[player] = true
                        break
                    end
                    local isStolenAttr = obj:GetAttribute("__render_stolen")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if isStolenAttr == true and root and obj:IsA("BasePart") then
                        if (obj.Position - root.Position).Magnitude < 7 then
                            ladrones[player] = true
                            break
                        end
                    end
                end
            end
        end
        return ladrones
    end

    local function aplicarESPStealer(character, player)
        local highlight = Instance.new("Highlight")
        highlight.Name = "KYN_StealerHighlight"
        highlight.FillColor = Color3.fromRGB(255, 140, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 220, 0)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = character

        local rootPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if rootPart and not rootPart:FindFirstChild("KYN_StealerBB") then
            local bb, lbl = makeStyledBillboard(
                rootPart,
                UDim2.new(0, 160, 0, 36),
                Vector3.new(0, 4.5, 0),
                Color3.fromRGB(255, 180, 0),
                "🎒 " .. player.Name,
                espStealerGradientColor
            )
            bb.Name = "KYN_StealerBB"
        end
    end

    espStealersConn = RunService.Heartbeat:Connect(function()
        if not espStealersActive then return end
        local jugadoresRobando = getJugadoresRobando()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = player.Character
            if char then
                local tieneESP = char:FindFirstChild("KYN_StealerHighlight")
                if jugadoresRobando[player] then
                    if not tieneESP then aplicarESPStealer(char, player) end
                else
                    if tieneESP then tieneESP:Destroy() end
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local bb = root:FindFirstChild("KYN_StealerBB")
                        if bb then bb:Destroy() end
                    end
                end
            end
        end
    end)
end

local function stopESPStealers()
    espStealersActive = false
    if espStealersConn then espStealersConn:Disconnect(); espStealersConn = nil end
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if char then
            local hl = char:FindFirstChild("KYN_StealerHighlight")
            if hl then hl:Destroy() end
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local bb = root:FindFirstChild("KYN_StealerBB")
                if bb then bb:Destroy() end
            end
        end
    end
end

-- ===========================
-- VISUAL: ESP MINE
-- ===========================
local espMineConn
local espMineFolder

local function startESPMine()
    if espMineFolder then espMineFolder:Destroy() end
    espMineFolder = Instance.new("Folder", CoreGui)
    espMineFolder.Name = "KYN_MineESP"

    espMineConn = RunService.Heartbeat:Connect(function()
        local toolsAdds = Workspace:FindFirstChild("ToolsAdds")
        if not toolsAdds then return end
        
        for _, obj in ipairs(toolsAdds:GetChildren()) do
            if obj.Name:find("SubspaceTripmine") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part and not part:FindFirstChild("KYN_MineBB") then
                    local bb, lbl = makeStyledBillboard(
                        part,
                        UDim2.new(0, 120, 0, 30),
                        Vector3.new(0, 2, 0),
                        THEME.Purple,
                        "💣 Mine",
                        espMineGradientColor
                    )
                    bb.Name = "KYN_MineBB"
                    
                    local hl = Instance.new("Highlight")
                    hl.Name = "KYN_MineHL"
                    hl.FillColor = THEME.Purple
                    hl.OutlineColor = Color3.fromRGB(200, 100, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = part
                end
            end
        end
    end)
end

local function stopESPMine()
    if espMineConn then espMineConn:Disconnect() espMineConn = nil end
    if espMineFolder then espMineFolder:Destroy() espMineFolder = nil end
    local toolsAdds = Workspace:FindFirstChild("ToolsAdds")
    if toolsAdds then
        for _, obj in ipairs(toolsAdds:GetChildren()) do
            if obj.Name:find("SubspaceTripmine") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local bb = part:FindFirstChild("KYN_MineBB")
                    if bb then bb:Destroy() end
                    local hl = part:FindFirstChild("KYN_MineHL")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
end

-- ===========================
-- VISUAL: X-RAY BASE
-- ===========================
local xrayConn

local function startXRay()
    if xrayConn then xrayConn:Disconnect(); xrayConn = nil end
    xrayConn = RunService.Heartbeat:Connect(function()
        local Plots = Workspace:FindFirstChild("Plots")
        if not Plots then return end
        for _, Plot in ipairs(Plots:GetChildren()) do
            if Plot:IsA("Model") and Plot:FindFirstChild("Decorations") then
                for _, Part in ipairs(Plot.Decorations:GetDescendants()) do
                    if Part:IsA("BasePart") then
                        Part.Transparency = 0.8
                    end
                end
            end
        end
    end)
end

local function stopXRay()
    if xrayConn then xrayConn:Disconnect(); xrayConn = nil end
    local Plots = Workspace:FindFirstChild("Plots")
    if not Plots then return end
    for _, Plot in ipairs(Plots:GetChildren()) do
        if Plot:IsA("Model") and Plot:FindFirstChild("Decorations") then
            for _, Part in ipairs(Plot.Decorations:GetDescendants()) do
                if Part:IsA("BasePart") then
                    Part.Transparency = 1
                end
            end
        end
    end
end

-- ===========================
-- MISC: INFINITE JUMP (ANTI-CHEAT SAFE)
-- ===========================
local infiniteJumpConn
local infiniteJumpEnabled = false

local function startInfiniteJump()
    infiniteJumpEnabled = true
    infiniteJumpConn = UIS.JumpRequest:Connect(function()
        if not infiniteJumpEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp then
            local randomForce = math.random(45, 52)
            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                randomForce,
                hrp.AssemblyLinearVelocity.Z
            )
        end
    end)
end

local function stopInfiniteJump()
    infiniteJumpEnabled = false
    if infiniteJumpConn then infiniteJumpConn:Disconnect(); infiniteJumpConn = nil end
end

-- ===========================
-- MISC: ANTI RAGDOLL
-- ===========================
local antiRagdollMode = nil
local ragdollConnections = {}
local cachedCharData = {}
local isBoosting = false 

local BOOST_SPEED = 400 
local DEFAULT_SPEED = 16

local function cacheCharacterData()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not root then return false end
    
    cachedCharData = {
        character = char,
        humanoid = hum,
        root = root
    }
    return true
end

local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if isForcingReset then return false end 
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    
    local ragdollStates = {
        [Enum.HumanoidStateType.Physics] = true,
        [Enum.HumanoidStateType.Ragdoll] = true,
        [Enum.HumanoidStateType.FallingDown] = true
    }
    
    if ragdollStates[state] then return true end
    
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
        return true
    end
    
    return false
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    
    pcall(function()
        LocalPlayer:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)
    
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("BallSocketConstraint") or (descendant:IsA("Attachment") and descendant.Name:find("RagdollAttachment")) then
            descendant:Destroy()
        end
    end
    
    if not isBoosting then
        isBoosting = true
        cachedCharData.humanoid.WalkSpeed = BOOST_SPEED
    end
    
    if cachedCharData.humanoid.Health > 0 then
        cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
    
    cachedCharData.root.Anchored = false
end

local function v1HeartbeatLoop()
    while antiRagdollMode == "v1" do
        task.wait()
        local currentlyRagdolled = isRagdolled()
        
        if currentlyRagdolled then
            forceExitRagdoll()
        elseif isBoosting and not currentlyRagdolled then
            isBoosting = false
            if cachedCharData.humanoid then
                cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED
            end
        end
    end
end

local function startAntiRagdoll()
    if antiRagdollMode == "v1" then return end
    if not cacheCharacterData() then return end
    
    antiRagdollMode = "v1"
    
    local camConn = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam and cachedCharData.humanoid then
            cam.CameraSubject = cachedCharData.humanoid
        end
    end)
    table.insert(ragdollConnections, camConn)
    
    local respawnConn = LocalPlayer.CharacterAdded:Connect(function()
        isBoosting = false 
        task.wait(0.5)
        cacheCharacterData()
    end)
    table.insert(ragdollConnections, respawnConn)

    task.spawn(v1HeartbeatLoop)
end

local function stopAntiRagdoll()
    antiRagdollMode = nil
    if isBoosting and cachedCharData.humanoid then
        cachedCharData.humanoid.WalkSpeed = DEFAULT_SPEED
    end
    isBoosting = false
    disconnectAllRagdoll()
    cachedCharData = {}
end

-- ===========================
-- MISC: ANTI LAG
-- ===========================
local antiLagEnabled = false
local antiLagConn

local function antiLagOptimize(obj)
    pcall(function()
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
        if obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end
    end)
end

local function antiLagApplyAll()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Lighting.Brightness = 1
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
        or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
    local terrain = Workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        terrain.WaterWaveSize = 0
        terrain.WaterWaveSpeed = 0
        terrain.WaterReflectance = 0
        terrain.WaterTransparency = 1
    end
    for _, v in pairs(Workspace:GetDescendants()) do
        antiLagOptimize(v)
    end
end

local function startAntiLag()
    if antiLagEnabled then return end
    antiLagEnabled = true
    antiLagApplyAll()
    antiLagConn = Workspace.DescendantAdded:Connect(antiLagOptimize)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
end

local function stopAntiLag()
    antiLagEnabled = false
    if antiLagConn then antiLagConn:Disconnect(); antiLagConn = nil end
end

-- ===========================
-- MISC: FREEZE ANIMATIONS
-- ===========================
local freezeAnimEnabled = false
local savedAnims = {}
local animWatcher
local freezeSteppedConn

local function saveAndClearAnim(anim)
    for _, v in ipairs(savedAnims) do
        if v.instance == anim then return end
    end
    local ok, id = pcall(function() return anim.AnimationId end)
    if not ok then return end
    table.insert(savedAnims, {instance = anim, id = id})
    pcall(function() anim.AnimationId = "rbxassetid://0" end)
end

local function restoreAllAnims()
    for _, v in ipairs(savedAnims) do
        if v.instance then pcall(function() v.instance.AnimationId = v.id end) end
    end
    savedAnims = {}
end

local function stopAllTracks(hum)
    if not hum then return end
    pcall(function()
        for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            track:Stop(0)
        end
    end)
end

local function scanAndFreezeAllAnims(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if hum then stopAllTracks(hum) end

    local animate = character:FindFirstChild("Animate")
    if animate then
        for _, folder in ipairs(animate:GetChildren()) do
            for _, anim in ipairs(folder:GetChildren()) do
                if anim:IsA("Animation") then
                    saveAndClearAnim(anim)
                end
            end
        end
    end
end

local function startFreezeAnims()
    local char = LocalPlayer.Character
    if not char then return end
    freezeAnimEnabled = true
    savedAnims = {}

    task.spawn(function()
        scanAndFreezeAllAnims(char)

        if animWatcher then animWatcher:Disconnect() end
        animWatcher = char.DescendantAdded:Connect(function(desc)
            if not freezeAnimEnabled then return end
            if desc:IsA("Animation") then
                task.defer(function() saveAndClearAnim(desc) end)
            end
        end)

        if freezeSteppedConn then freezeSteppedConn:Disconnect() end
        freezeSteppedConn = RunService.Stepped:Connect(function()
            if not freezeAnimEnabled then return end
            local c = LocalPlayer.Character
            if not c then return end
            local h = c:FindFirstChildOfClass("Humanoid")
            if h then stopAllTracks(h) end
        end)
    end)
end

local function stopFreezeAnims()
    freezeAnimEnabled = false
    if animWatcher then animWatcher:Disconnect(); animWatcher = nil end
    if freezeSteppedConn then freezeSteppedConn:Disconnect(); freezeSteppedConn = nil end
    restoreAllAnims()
end

LocalPlayer.CharacterAdded:Connect(function(c)
    if freezeAnimEnabled then
        task.spawn(function()
            task.wait(0.5) 
            scanAndFreezeAllAnims(c)
            if animWatcher then animWatcher:Disconnect() end
            animWatcher = c.DescendantAdded:Connect(function(desc)
                if not freezeAnimEnabled then return end
                if desc:IsA("Animation") then
                    task.defer(function() saveAndClearAnim(desc) end)
                end
            end)
        end)
    end
end)

-- ===========================
-- MISC: ANTI TORRET (SENTRY)
-- ===========================
local SENTRY_DETECTION_DISTANCE = 60
local SENTRY_PULL_DISTANCE      = -5
local antiSentryEnabled         = false
local antiSentryConn            = nil
local sentryTarget              = nil

local function getSentryCharacter()
    return LocalPlayer.Character
end

local function getSentryWeapon()
    local char = getSentryCharacter()
    if not char then return nil end
    return LocalPlayer.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
end

local function isSentryValid(obj)
    if not obj or obj.Parent ~= workspace then return false end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then return false end
    local part = obj:IsA("BasePart") and obj or obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
    if not part then return false end
    return true
end

local function findSentryTarget()
    local char = getSentryCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local ownerId = obj.Name:match("Sentry(%d+)")
            if ownerId and tonumber(ownerId) == LocalPlayer.UserId then
                continue
            end
            local part = obj:IsA("BasePart") and obj or obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
            if part and (rootPos - part.Position).Magnitude <= SENTRY_DETECTION_DISTANCE then
                if isSentryValid(obj) then return obj end
            end
        end
    end
    return nil
end

local function moveSentryTarget(obj)
    local char = getSentryCharacter()
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, part in pairs(obj:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    local root = char.HumanoidRootPart
    local cf   = root.CFrame * CFrame.new(0, 0, SENTRY_PULL_DISTANCE)
    if obj:IsA("BasePart") then
        obj.CFrame = cf
    elseif obj:IsA("Model") then
        local main = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if main then main.CFrame = cf end
    end
end

local function attackSentry()
    local char = getSentryCharacter()
    if not char then return end
    local hum    = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local weapon = getSentryWeapon()
    if not weapon then return end
    if weapon.Parent == LocalPlayer.Backpack then
        hum:EquipTool(weapon)
        task.wait(0.1)
    end
    local handle = weapon:FindFirstChild("Handle")
    if handle then handle.CanCollide = false end
    pcall(function() weapon:Activate() end)
    for _, r in pairs(weapon:GetDescendants()) do
        if r:IsA("RemoteEvent") then
            pcall(function() r:FireServer() end)
        end
    end
end

local function startAntiSentry()
    if antiSentryConn then return end
    antiSentryConn = RunService.Heartbeat:Connect(function()
        if not antiSentryEnabled then return end
        if sentryTarget and isSentryValid(sentryTarget) then
            moveSentryTarget(sentryTarget)
            attackSentry()
        else
            sentryTarget = findSentryTarget()
        end
    end)
end

local function stopAntiSentry()
    if antiSentryConn then
        antiSentryConn:Disconnect()
        antiSentryConn = nil
    end
    sentryTarget = nil
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if antiSentryEnabled then startAntiSentry() end
end)

-- ===========================
-- MISC: ANTI BEE & DISCO
-- ===========================
local antiBeeEnabled   = false
local antiBeeConn      = nil
local antiFovConn      = nil
local FOV_LOCK_VALUE   = 70

local beeBlacklist = {
    "BlurEffect","ColorCorrectionEffect","BloomEffect","SunRaysEffect",
    "DepthOfFieldEffect","Atmosphere","Sky","Smoke","ParticleEmitter",
    "Beam","Trail","Highlight","PostEffect","SurfaceAppearance","Fire",
    "Sparkles","Explosion","PointLight","SpotLight","SurfaceLight",
}

local function isBeeBlacklisted(obj)
    for _, name in ipairs(beeBlacklist) do
        if pcall(function() return obj:IsA(name) end) and obj:IsA(name) then
            return true
        end
    end
    return false
end

local function clearBeeEffects()
    for _, v in pairs(Lighting:GetDescendants()) do
        if isBeeBlacklisted(v) then pcall(function() v:Destroy() end) end
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") or v:IsA("Trail") then
            pcall(function() v.Enabled = false end)
        end
    end
end

local function startAntiBee()
    if antiBeeEnabled then return end
    antiBeeEnabled = true
    clearBeeEffects()
    antiBeeConn = Lighting.DescendantAdded:Connect(function(obj)
        task.wait()
        if antiBeeEnabled and isBeeBlacklisted(obj) then
            pcall(function() obj:Destroy() end)
        end
    end)
    antiFovConn = RunService.RenderStepped:Connect(function()
        if not antiBeeEnabled then return end
        local cam = workspace.CurrentCamera
        if cam and cam.FieldOfView ~= FOV_LOCK_VALUE then
            cam.FieldOfView = FOV_LOCK_VALUE
        end
    end)
end

local function stopAntiBee()
    antiBeeEnabled = false
    if antiBeeConn  then antiBeeConn:Disconnect();  antiBeeConn  = nil end
    if antiFovConn  then antiFovConn:Disconnect();  antiFovConn  = nil end
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = 70 end
end

-- ============================================================
-- // LÓGICA: DESYNC
-- ============================================================
local desyncActive       = false
local desyncMode         = nil   
local desyncDebounce     = false
local isIgnoringTeleport = false

-- Respawn cache
local cachedCraftCFrame = nil
local craftMachine      = nil
local desyncCharConn    = nil

local function updateCraftCache()
    craftMachine = Workspace:FindFirstChild("CraftingMachine")
    if craftMachine then
        local part = craftMachine:FindFirstChild("VFX", true)
        if part then
            part = part:FindFirstChild("Secret", true)
            if part and part:FindFirstChild("SoundPart", true) then
                cachedCraftCFrame = part.SoundPart.CFrame
            end
        end
    end
end

updateCraftCache()
Workspace.ChildAdded:Connect(function(c)
    if c.Name == "CraftingMachine" then task.defer(updateCraftCache) end
end)
RunService.Heartbeat:Connect(function()
    if Players.RespawnTime ~= 0 then Players.RespawnTime = 0 end
end)

local function executeDesyncReset()
    local char = LocalPlayer.Character
    if not char then return end
    local hum, hrp = char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return end
    
    isForcingReset = true 
    
    if desyncCharConn then desyncCharConn:Disconnect(); desyncCharConn = nil end
    
    workspace.CurrentCamera.CameraSubject = nil
    desyncCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        desyncCharConn:Disconnect(); desyncCharConn = nil
        workspace.CurrentCamera.CameraSubject = nil
        task.defer(function()
            local newHum = newChar:WaitForChild("Humanoid", 0.5)
            if newHum then workspace.CurrentCamera.CameraSubject = newHum end
        end)
    end)
    
    if cachedCraftCFrame then hrp.CFrame = cachedCraftCFrame
    elseif craftMachine then updateCraftCache(); if cachedCraftCFrame then hrp.CFrame = cachedCraftCFrame end end
    
    Players.RespawnTime = 0
    hum.Health = 0
    hum:ChangeState(Enum.HumanoidStateType.Dead)
    char:BreakJoints()
    task.wait(0.03)
    pcall(function() LocalPlayer:LoadCharacter() end)
    
    task.delay(2, function() isForcingReset = false end)
end

-- Cloner
local CLONER_TOOL_NAME = "Quantum Cloner"
local cloneName        = tostring(LocalPlayer.UserId) .. "_Clone"
local cloneWatchConn   = nil

local function setHiddenState(obj, invisible)
    if obj.Name == "RubberbandHighlight" or obj.Name == "DesyncedServerPosition" then return end
    if obj:IsA("BasePart") then
        obj.Transparency = invisible and 1 or 0
        obj.CanCollide   = not invisible
    elseif obj:IsA("Decal")                                        then obj.Transparency = invisible and 1 or 0
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = not invisible
    elseif obj:IsA("Highlight")                                    then obj.Enabled = not invisible
    elseif obj:IsA("Smoke") or obj:IsA("Fire")                     then obj.Enabled = not invisible
    elseif obj:IsA("ForceField")                                   then obj.Visible  = not invisible
    end
end

local function applyToClone(clone, hide)
    for _, obj in ipairs(clone:GetDescendants()) do setHiddenState(obj, hide) end
    if cloneWatchConn then cloneWatchConn:Disconnect(); cloneWatchConn = nil end
    if hide then
        cloneWatchConn = clone.DescendantAdded:Connect(function(obj)
            setHiddenState(obj, true)
        end)
    end
end

local function equipAndUseClonerTool()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid  = character:WaitForChild("Humanoid")
    local backpack  = LocalPlayer:FindFirstChild("Backpack")
    local tool      = character:FindFirstChild(CLONER_TOOL_NAME)
                   or (backpack and backpack:FindFirstChild(CLONER_TOOL_NAME))
    if not tool then return false end
    if tool.Parent ~= character then humanoid:EquipTool(tool); task.wait(0.15) end
    pcall(function() tool:Activate() end)
    return true
end

local function triggerClonerTeleport()
    pcall(function()
        local qcFrame    = LocalPlayer.PlayerGui:FindFirstChild("QuantumCloner", true)
        local teleportBtn = qcFrame and qcFrame:FindFirstChild("TeleportToClone")
        if teleportBtn then
            isIgnoringTeleport = true 
            if getconnections then
                for _, conn in ipairs(getconnections(teleportBtn.MouseButton1Up)) do conn:Fire() end
            elseif firesignal then
                firesignal(teleportBtn.MouseButton1Up)
            end
            qcFrame.Visible = false
            task.delay(1, function() isIgnoringTeleport = false end)
        end
    end)
end

-- ===========================
-- LAGBACK DETECTOR
-- ===========================
local serverGhost         = nil
local rubberbandLoop      = nil
local lastPlayerPos       = nil
local lagbackWarningEnd   = 0

local rubberbandHL = Instance.new("Highlight")
rubberbandHL.Name               = "RubberbandHighlight"
rubberbandHL.FillTransparency   = 0.5
rubberbandHL.OutlineColor       = THEME.Primary
rubberbandHL.FillColor          = THEME.Primary
rubberbandHL.Enabled            = false
pcall(function() rubberbandHL.Parent = game:GetService("CorePackages") end)

local function createServerGhost(character)
    if serverGhost then serverGhost:Destroy() end
    serverGhost              = Instance.new("Part")
    serverGhost.Name         = "DesyncedServerPosition"
    serverGhost.Size         = Vector3.new(2.5, 2.5, 2.5)
    serverGhost.Shape        = Enum.PartType.Block
    serverGhost.Anchored     = true
    serverGhost.CanCollide   = false
    serverGhost.CanTouch     = false
    serverGhost.CanQuery     = false
    serverGhost.Material     = Enum.Material.ForceField
    serverGhost.Color        = THEME.Primary
    serverGhost.Transparency = 0.2

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then serverGhost.CFrame = hrp.CFrame end

    local bg = Instance.new("BillboardGui", serverGhost)
    bg.Name         = "ServerPosGui"
    bg.Size         = UDim2.new(0, 250, 0, 50)
    bg.StudsOffset  = Vector3.new(0, 2.5, 0)
    bg.AlwaysOnTop  = true

    local txt = Instance.new("TextLabel", bg)
    txt.Name                  = "ServerText"
    txt.Size                  = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text                  = "Server Position"
    txt.TextColor3            = THEME.Primary
    txt.TextStrokeTransparency = 0.2
    txt.Font                  = Enum.Font.GothamBold
    txt.TextScaled            = true

    serverGhost.Parent        = Workspace
    rubberbandHL.Adornee      = serverGhost
    rubberbandHL.Enabled      = true
end

local function updateLagbackDetector()
    if not desyncActive or not serverGhost then return end
    local char = LocalPlayer.Character
    local realHRP = char and char:FindFirstChild("HumanoidRootPart")
    
    if realHRP and serverGhost then
        local currentPos = realHRP.Position
        if lastPlayerPos then
            if (currentPos - lastPlayerPos).Magnitude > 2.5 then
                serverGhost.CFrame = realHRP.CFrame
                if not isIgnoringTeleport then
                    lagbackWarningEnd = os.clock() + 2.5
                end
            end
        end
        lastPlayerPos = currentPos

        local dist = (currentPos - serverGhost.Position).Magnitude
        local txt  = serverGhost:FindFirstChild("ServerPosGui") and serverGhost.ServerPosGui:FindFirstChild("ServerText")
        if txt then
            if os.clock() < lagbackWarningEnd then
                serverGhost.Color         = THEME.Red
                rubberbandHL.FillColor    = THEME.Red
                rubberbandHL.OutlineColor = THEME.Red
                txt.Text                  = "⚠️ LAGBACK DETECTADO ⚠️"
                txt.TextColor3            = THEME.Red
            else
                serverGhost.Color         = THEME.Primary
                rubberbandHL.FillColor    = THEME.Primary
                rubberbandHL.OutlineColor = THEME.Primary
                txt.Text                  = string.format("Server Position\n(%.1f studs)", dist)
                txt.TextColor3            = THEME.Primary
            end
        end
    end
end

local function startLagbackDetector(character)
    lastPlayerPos = nil
    createServerGhost(character)
    if rubberbandLoop then rubberbandLoop:Disconnect() end
    rubberbandLoop = RunService.Heartbeat:Connect(updateLagbackDetector)
end

local function stopLagbackDetector()
    if rubberbandLoop then rubberbandLoop:Disconnect(); rubberbandLoop = nil end
    if serverGhost    then serverGhost:Destroy();       serverGhost    = nil end
    rubberbandHL.Enabled = false
    lastPlayerPos        = nil
end

local function activateDesync(mode)
    if desyncDebounce then return end
    desyncDebounce = true
    desyncActive   = true
    desyncMode     = mode
    pcall(function() raknet.desync(true) end)

    local char = LocalPlayer.Character
    if char then startLagbackDetector(char) end

    if mode == "Respawn" then
        KYNNotify("Desync Respawn", "Ejecutando respawn desync...", "⚡", THEME.Primary)
        isIgnoringTeleport = true
        executeDesyncReset()
        task.delay(1.5, function() isIgnoringTeleport = false end)
    elseif mode == "Cloner" then
        KYNNotify("Desync Cloner", "Usando Quantum Cloner...", "🔀", THEME.Green)
        if equipAndUseClonerTool() then
            local start = os.clock()
            local clone = nil
            while os.clock() - start < 2 do
                clone = Workspace:FindFirstChild(cloneName, true)
                if clone then break end
                task.wait(0.05)
            end
            if clone then
                applyToClone(clone, true)
                task.wait(0.1)
                triggerClonerTeleport()
            end
        end
    end
    task.delay(0.5, function() desyncDebounce = false end)
end

local function deactivateDesync()
    if desyncDebounce then return end
    desyncDebounce = true
    desyncActive   = false
    pcall(function() raknet.desync(false) end)
    stopLagbackDetector()

    if desyncMode == "Respawn" then
        KYNNotify("Desync OFF", "Respawn desync desactivado.", "🔴", THEME.Red, 2)
        isIgnoringTeleport = true
        executeDesyncReset()
        task.delay(1.5, function() isIgnoringTeleport = false end)
    elseif desyncMode == "Cloner" then
        KYNNotify("Desync OFF", "Cloner desync desactivado.", "🔴", THEME.Red, 2)
        local clone = Workspace:FindFirstChild(cloneName, true)
        if clone then applyToClone(clone, false) end
    end
    desyncMode = nil
    task.delay(0.5, function() desyncDebounce = false end)
end

-- ============================================================
-- // FLOAT BUTTON LOGIC (ANTI-CHEAT SAFE + 9 STUDS LIMIT)
-- ============================================================
local floatBtnFrame = nil
local floating = false
local floatBodyVel = nil
local floatRenderConn = nil
local floatStartY = 0
local floatPlat = nil

local function toggleFloatButton(state)
    if state then
        if not floatBtnFrame then
            floatBtnFrame = Instance.new("Frame", gui)
            floatBtnFrame.Size = UDim2.new(0, 55, 0, 55)
            floatBtnFrame.Position = UDim2.new(1, -80, 0.5, 0)
            floatBtnFrame.BackgroundTransparency = 1
            floatBtnFrame.Active = true

            local fBtn = Instance.new("TextButton", floatBtnFrame)
            fBtn.Size = UDim2.new(1, 0, 1, 0)
            fBtn.BackgroundColor3 = THEME.Frame
            fBtn.Text = "Float"
            fBtn.Font = Enum.Font.GothamBold
            fBtn.TextColor3 = THEME.Primary
            fBtn.TextSize = 13
            corner(fBtn, 50)

            local fStroke = stroke(fBtn, Color3.new(1, 1, 1), 3)
            local fGrad = Instance.new("UIGradient", fStroke)
            fGrad.Color = btnGradient.Color
            
            task.spawn(function()
                while floatBtnFrame and floatBtnFrame.Parent do
                    fGrad.Rotation = (fGrad.Rotation + 2) % 360
                    RunService.RenderStepped:Wait()
                end
            end)

            MakeDraggable(floatBtnFrame, fBtn)

            fBtn.Activated:Connect(function()
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum then return end

                floating = not floating
                
                if floating then
                    fBtn.Text = "Float: ON"
                    fBtn.TextColor3 = THEME.Green
                    
                    floatStartY = hrp.Position.Y
                    
                    floatBodyVel = Instance.new("BodyVelocity")
                    floatBodyVel.Name = "FloatVelocity"
                    floatBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    floatBodyVel.Velocity = Vector3.new(0, 20, 0)
                    floatBodyVel.Parent = hrp
                    
                    hum:ChangeState(Enum.HumanoidStateType.Physics)
                    
                    -- Plataforma invisible local para engañar al Anti-Cheat (FloorMaterial)
                    floatPlat = Instance.new("Part")
                    floatPlat.Size = Vector3.new(6, 1, 6)
                    floatPlat.Transparency = 1
                    floatPlat.Anchored = true
                    floatPlat.CanCollide = true
                    floatPlat.Parent = Workspace
                    
                    if not floatRenderConn then
                        floatRenderConn = RunService.RenderStepped:Connect(function()
                            if floating and floatBodyVel and floatBodyVel.Parent then
                                local moveDir = hum.MoveDirection
                                local currentY = hrp.Position.Y
                                
                                local yVel = 0
                                if currentY < floatStartY + 9 then
                                    yVel = 20 -- Subiendo
                                elseif currentY > floatStartY + 9.5 then
                                    yVel = -5 -- Corrección suave si se pasa
                                else
                                    yVel = 0 -- Mantener altura
                                end
                                
                                floatBodyVel.Velocity = (moveDir * 50) + Vector3.new(0, yVel, 0)
                                hrp.RotVelocity = Vector3.zero
                                
                                if floatPlat then
                                    floatPlat.CFrame = hrp.CFrame - Vector3.new(0, 3.2, 0)
                                end
                            end
                        end)
                    end
                else
                    fBtn.Text = "Float: OFF"
                    fBtn.TextColor3 = THEME.Red
                    
                    if floatBodyVel then floatBodyVel:Destroy() floatBodyVel = nil end
                    if floatPlat then
                        game.Debris:AddItem(floatPlat, 5)
                        floatPlat = nil
                    end
                    
                    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
                end
            end)
        end
        floatBtnFrame.Visible = true
    else
        if floatBtnFrame then floatBtnFrame.Visible = false end
        floating = false
        if floatBodyVel then floatBodyVel:Destroy() floatBodyVel = nil end
        if floatPlat then floatPlat:Destroy() floatPlat = nil end
        if floatRenderConn then floatRenderConn:Disconnect() floatRenderConn = nil end
        if floatBtnFrame then
            local fBtn = floatBtnFrame:FindFirstChildOfClass("TextButton")
            if fBtn then
                fBtn.Text = "Float"
                fBtn.TextColor3 = THEME.Primary
            end
        end
    end
end

-- ============================================================
-- // REGISTRO DE TODOS LOS TOGGLES
-- ============================================================

local desyncGroup = {}  

local ctrlDesyncRespawn = _G.KYNAddToggle("Main", {
    Name          = "Desync Respawn",
    Callback      = function(s)
        if s then
            activateDesync("Respawn")
            KYNNotify("Desync Respawn", "Modo Respawn activado ✔", "⚡", THEME.Primary)
        else
            if desyncMode == "Respawn" then deactivateDesync() end
        end
    end,
})
local ctrlDesyncCloner = _G.KYNAddToggle("Main", {
    Name          = "Desync Cloner",
    Callback      = function(s)
        if s then
            activateDesync("Cloner")
            KYNNotify("Desync Cloner", "Modo Cloner activado ✔", "🔀", THEME.Green)
        else
            if desyncMode == "Cloner" then deactivateDesync() end
        end
    end,
})

ctrlDesyncRespawn.ExclusiveGroup = {ctrlDesyncRespawn, ctrlDesyncCloner}
ctrlDesyncCloner.ExclusiveGroup  = {ctrlDesyncRespawn, ctrlDesyncCloner}

_G.KYNAddToggle("Main", {Name = "Auto Steal", Callback = function(s)
    if s then startAutoSteal() else stopAutoSteal() end
    KYNNotify("Auto Steal", s and "Insta-Grab activado ✔" or "Desactivado", "⚡", THEME.Primary, 1.8)
end})

_G.KYNAddToggle("Main", {Name = "Float Button", Callback = function(s)
    toggleFloatButton(s)
    KYNNotify("Float Button", s and "Botón mostrado ✔" or "Oculto", "☁", THEME.Primary, 1.8)
end})

_G.KYNAddToggle("Visual", {Name = "ESP Player", Callback = function(s)
    if s then startESPPlayer() else stopESPPlayer() end
    KYNNotify("ESP Player", s and "Activado ✔" or "Desactivado", "👁", THEME.Primary, 1.8)
end})
_G.KYNAddToggle("Visual", {Name = "ESP Base Time", Callback = function(s)
    if s then startESPBase() else stopESPBase() end
    KYNNotify("ESP Base Time", s and "Activado ✔" or "Desactivado", "👁", THEME.Primary, 1.8)
end})
_G.KYNAddToggle("Visual", {Name = "ESP Stealers", Callback = function(s)
    if s then startESPStealers() else stopESPStealers() end
    KYNNotify("ESP Stealers", s and "Activado ✔" or "Desactivado", "🔶", Color3.fromRGB(255,180,0), 1.8)
end})
_G.KYNAddToggle("Visual", {Name = "ESP Mine", Callback = function(s)
    if s then startESPMine() else stopESPMine() end
    KYNNotify("ESP Mine", s and "Activado ✔" or "Desactivado", "💣", THEME.Purple, 1.8)
end})
_G.KYNAddToggle("Visual", {Name = "X-Ray Base", Callback = function(s)
    if s then startXRay() else stopXRay() end
    KYNNotify("X-Ray Base", s and "Activado ✔" or "Desactivado", "🔵", THEME.Secondary, 1.8)
end})

_G.KYNAddToggle("Misc", {Name = "Infinite Jump", Callback = function(s)
    if s then startInfiniteJump() else stopInfiniteJump() end
    KYNNotify("Infinite Jump", s and "Activado ✔" or "Desactivado", "🦘", THEME.Primary, 1.8)
end})
_G.KYNAddToggle("Misc", {Name = "Anti Ragdoll", Callback = function(s)
    if s then startAntiRagdoll() else stopAntiRagdoll() end
    KYNNotify("Anti Ragdoll", s and "Activado ✔" or "Desactivado", "🛡", THEME.Green, 1.8)
end})
_G.KYNAddToggle("Misc", {Name = "Anti Lag", Callback = function(s)
    if s then startAntiLag() else stopAntiLag() end
    KYNNotify("Anti Lag", s and "Activado ✔" or "Desactivado", "⚙", THEME.Neon1, 1.8)
end})
_G.KYNAddToggle("Misc", {Name = "Freeze Animations", Callback = function(s)
    if s then startFreezeAnims() else stopFreezeAnims() end
    KYNNotify("Freeze Animations", s and "Activado ✔" or "Desactivado", "❄", Color3.fromRGB(150,220,255), 1.8)
end})
_G.KYNAddToggle("Misc", {Name = "Anti Torret", Callback = function(s)
    antiSentryEnabled = s
    if s then startAntiSentry() else stopAntiSentry() end
    KYNNotify("Anti Torret", s and "Activado ✔" or "Desactivado", "🎯", THEME.Red, 1.8)
end})
_G.KYNAddToggle("Misc", {Name = "Anti Bee & Disco", Callback = function(s)
    if s then startAntiBee() else stopAntiBee() end
    KYNNotify("Anti Bee & Disco", s and "Activado ✔" or "Desactivado", "🐝", THEME.Green, 1.8)
end})

task.spawn(function()
    task.wait(1)
    kynRestoring = true
    for _, fn in ipairs(pendingRestores) do
        pcall(fn)
    end
    kynRestoring = false
end)
