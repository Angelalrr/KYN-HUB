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

local LocalPlayer = Players.LocalPlayer
local configFileName = "KYNHub_Config.json"

local defaultConfig = {
    ToggleStates = {},
}
local currentConfig = {
    ToggleStates = {},
}

local function loadConfig()
    currentConfig = {
        ToggleStates = {},
    }
    for k, v in pairs(defaultConfig) do
        currentConfig[k] = v
    end
    if isfile and readfile and isfile(configFileName) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(configFileName))
            if type(decoded) == "table" then
                for k, v in pairs(decoded) do
                    currentConfig[k] = v
                end
            end
        end)
    end
    if type(currentConfig.ToggleStates) ~= "table" then
        currentConfig.ToggleStates = {}
    end
end

local function saveConfig()
    if writefile then
        pcall(function()
            writefile(configFileName, HttpService:JSONEncode(currentConfig))
        end)
    end
end

loadConfig()

local guiName = "KYNHubGUI_Electric"
local OLD = CoreGui:FindFirstChild(guiName)
if OLD then OLD:Destroy() end
local oldNotif = CoreGui:FindFirstChild("KYNHubNotifications")
if oldNotif then oldNotif:Destroy() end

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

local notifGui = Instance.new("ScreenGui")
notifGui.Name = "KYNHubNotifications"
notifGui.ResetOnSpawn = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.Parent = CoreGui

local notifHolder = Instance.new("Frame", notifGui)
notifHolder.Size = UDim2.new(1, 0, 1, 0)
notifHolder.BackgroundTransparency = 1

local notifLayout = Instance.new("UIListLayout", notifHolder)
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Padding = UDim.new(0, 8)

local notifPadding = Instance.new("UIPadding", notifHolder)
notifPadding.PaddingTop = UDim.new(0, 12)

local function notify(msg, color, lifetime)
    local holder = Instance.new("Frame", notifHolder)
    holder.Size = UDim2.new(0, 320, 0, 48)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = os.clock() * 1000

    local panel = Instance.new("Frame", holder)
    panel.Size = UDim2.new(1, 0, 1, 0)
    panel.Position = UDim2.new(0, 0, 0, -70)
    panel.BackgroundColor3 = THEME.Frame
    corner(panel, 10)

    local panelStroke = stroke(panel, Color3.new(1, 1, 1), 3)
    local panelGrad = Instance.new("UIGradient", panelStroke)
    panelGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, THEME.Secondary),
        ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
        ColorSequenceKeypoint.new(0.5, THEME.Primary),
        ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
        ColorSequenceKeypoint.new(1, THEME.Secondary),
    }

    local txt = Instance.new("TextLabel", panel)
    txt.Size = UDim2.new(1, -16, 1, -10)
    txt.Position = UDim2.new(0, 8, 0, 5)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 13
    txt.TextWrapped = true
    txt.Text = msg
    txt.TextColor3 = color or THEME.Neon1

    tween(panel, {Position = UDim2.new(0, 0, 0, 0)}, 0.32, Enum.EasingStyle.Back)
    task.delay(lifetime or 2.6, function()
        if not panel.Parent then return end
        tween(panel, {Position = UDim2.new(0, 0, 0, -70)}, 0.28, Enum.EasingStyle.Quad)
        task.wait(0.3)
        if holder then holder:Destroy() end
    end)
end

-- ===========================
-- BILLBOARD ESTILIZADO (ESP)
-- ===========================
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

-- // SISTEMA DE ARRASTRE UNIVERSAL //
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

-- ==========================================
-- // BOTÓN FLOTANTE
-- ==========================================
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

-- ==========================================
-- // MAIN GUI FRAME
-- ==========================================
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

-- ==========================================
-- // DIÁLOGO DE CONFIRMACIÓN
-- ==========================================
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

-- ==========================================
-- // TAB CONTAINER & CONTENT
-- ==========================================
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
local toggleControllers = {}

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

-- ==========================================
-- // FUNCIÓN PARA AGREGAR TOGGLES
-- ==========================================
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
        return
    end

    btn.Text = "   " .. (data.Name or "Toggle")
    btn.TextColor3 = THEME.Dim

    local toggleKey = string.format("%s::%s", tabName, data.Name or "Toggle")
    local state = currentConfig.ToggleStates[toggleKey] == true

    local function applyStateVisual(immediate)
        local targetDotPos = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        local targetTrack = state and THEME.Primary or Color3.fromRGB(30, 45, 70)
        local targetText = state and THEME.Neon1 or THEME.Dim
        local targetStroke = state and THEME.Primary or THEME.BorderOff
        if immediate then
            dot.Position = targetDotPos
            track.BackgroundColor3 = targetTrack
            btn.TextColor3 = targetText
            bStroke.Color = targetStroke
            trackStroke.Color = targetStroke
        else
            tween(dot, {Position = targetDotPos}, 0.25, Enum.EasingStyle.Back)
            tween(track, {BackgroundColor3 = targetTrack}, 0.2)
            tween(btn, {TextColor3 = targetText}, 0.2)
            tween(bStroke, {Color = targetStroke}, 0.2)
            tween(trackStroke, {Color = targetStroke}, 0.2)
        end
    end

    local function runCallback()
        if data.Callback then pcall(data.Callback, state) end
    end

    local controller = {}
    function controller:SetState(newState, silent)
        local nextState = newState == true
        if state == nextState then return end
        state = nextState
        currentConfig.ToggleStates[toggleKey] = state
        saveConfig()
        applyStateVisual(false)
        runCallback()
        if not silent then
            notify(string.format("%s: %s", data.Name or "Toggle", state and "ON" or "OFF"), state and THEME.Green or THEME.Red, 1.8)
        end
    end
    function controller:GetState()
        return state
    end
    toggleControllers[toggleKey] = controller

    applyStateVisual(true)
    task.defer(runCallback)

    btn.Activated:Connect(function()
        controller:SetState(not state, false)
    end)
end

-- ==========================================
-- // ANIMACIONES CONSTANTES
-- ==========================================
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

-- ==========================================
-- // LÓGICA DE ABRIR Y CERRAR
-- ==========================================
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
-- // LÓGICA DE LOS SCRIPTS
-- ============================================================

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
-- MISC: INFINITE JUMP
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
local antiRagdollEnabled = false
local arConnections = {}
local arDisabledRemotes = {}
local arRemoteWatcher
local arFrozen = false

local arBlockedStates = {
    [Enum.HumanoidStateType.Ragdoll]     = true,
    [Enum.HumanoidStateType.FallingDown] = true,
    [Enum.HumanoidStateType.Physics]     = true,
    [Enum.HumanoidStateType.Dead]        = true,
}
local arRemoteKeywords = {"useitem", "combatservice", "ragdoll"}

local function arForceNormal(character)
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    hum.Health = hum.MaxHealth
    hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    if not arFrozen then
        arFrozen = true
        hrp.Anchored = true
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 1.5, 0)
    end
end

local function arRelease(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and arFrozen then
        hrp.Anchored = false
        arFrozen = false
    end
end

local function arRestoreMotors(character)
    for _, v in ipairs(character:GetDescendants()) do
        if v:IsA("Motor6D") then v.Enabled = true
        elseif v:IsA("Constraint") then v.Enabled = false
        end
    end
end

local function arKillRemote(remote)
    if not getconnections then return end
    if not remote:IsA("RemoteEvent") then return end
    if arDisabledRemotes[remote] then return end
    local name = remote.Name:lower()
    for _, key in ipairs(arRemoteKeywords) do
        if name:find(key) then
            arDisabledRemotes[remote] = {}
            for _, c in ipairs(getconnections(remote.OnClientEvent)) do
                if c.Disable then
                    c:Disable()
                    table.insert(arDisabledRemotes[remote], c)
                end
            end
            break
        end
    end
end

local function arInitCharacter(char)
    if not antiRagdollEnabled then return end
    local hum = char:WaitForChild("Humanoid", 10)
    if not hum then return end
    for state in pairs(arBlockedStates) do
        hum:SetStateEnabled(state, false)
    end
    local c1 = hum.StateChanged:Connect(function(_, new)
        if antiRagdollEnabled and arBlockedStates[new] then
            arForceNormal(char)
            arRestoreMotors(char)
        end
    end)
    local c2 = RunService.Stepped:Connect(function()
        if not antiRagdollEnabled then arRelease(char); return end
        if arBlockedStates[hum:GetState()] then arForceNormal(char)
        else arRelease(char) end
        hum.Health = hum.MaxHealth
    end)
    table.insert(arConnections, c1)
    table.insert(arConnections, c2)
end

local function startAntiRagdoll()
    antiRagdollEnabled = true
    arDisabledRemotes = {}
    local char = LocalPlayer.Character
    if char then task.spawn(function() arInitCharacter(char) end) end
    local c = LocalPlayer.CharacterAdded:Connect(function(c2)
        task.wait(0.4)
        arInitCharacter(c2)
    end)
    table.insert(arConnections, c)
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        for _, obj in ipairs(RS:GetDescendants()) do arKillRemote(obj) end
        arRemoteWatcher = RS.DescendantAdded:Connect(arKillRemote)
    end)
end

local function stopAntiRagdoll()
    antiRagdollEnabled = false
    for _, c in ipairs(arConnections) do pcall(function() c:Disconnect() end) end
    arConnections = {}
    if arRemoteWatcher then arRemoteWatcher:Disconnect(); arRemoteWatcher = nil end
    for _, conns in pairs(arDisabledRemotes) do
        for _, c in ipairs(conns) do pcall(function() if c.Enable then c:Enable() end end) end
    end
    arDisabledRemotes = {}
    arFrozen = false
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
local antiSentryEnabled = false
local antiSentryConn = nil
local sentryTarget = nil
local DETECTION_DISTANCE = 60
local PULL_DISTANCE = -5

local function getWeapon()
    local char = LocalPlayer.Character
    if not char then return nil end
    return LocalPlayer.Backpack:FindFirstChild("Bat") or char:FindFirstChild("Bat")
end

local function findSentryTarget()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local rootPos = char.HumanoidRootPart.Position
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name:find("Sentry") and not obj.Name:lower():find("bullet") then
            local ownerId = obj.Name:match("Sentry_(%d+)")
            if ownerId and tonumber(ownerId) == LocalPlayer.UserId then continue end
            local part = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
            if part and (rootPos - part.Position).Magnitude <= DETECTION_DISTANCE then
                return obj
            end
        end
    end
    return nil
end

local function moveSentryTarget(obj)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    for _, part in pairs(obj:GetDescendants()) do
        if part:IsA("BasePart") then part.CanCollide = false end
    end
    local root = char.HumanoidRootPart
    local cf = root.CFrame * CFrame.new(0, 0, PULL_DISTANCE)
    if obj:IsA("BasePart") then obj.CFrame = cf
    elseif obj:IsA("Model") then
        local main = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
        if main then main.CFrame = cf end
    end
end

local function attackSentry()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local weapon = getWeapon()
    if not hum or not weapon then return end
    if weapon.Parent == LocalPlayer.Backpack then
        hum:EquipTool(weapon)
        task.wait(0.1)
    end
    local handle = weapon:FindFirstChild("Handle")
    if handle then handle.CanCollide = false end
    pcall(function() weapon:Activate() end)
    for _, r in pairs(weapon:GetDescendants()) do
        if r:IsA("RemoteEvent") then pcall(function() r:FireServer() end) end
    end
end

local function startAntiSentry()
    if antiSentryEnabled then return end
    antiSentryEnabled = true
    antiSentryConn = RunService.Heartbeat:Connect(function()
        if not antiSentryEnabled then return end
        if sentryTarget and sentryTarget.Parent == Workspace then
            moveSentryTarget(sentryTarget)
            attackSentry()
        else
            sentryTarget = findSentryTarget()
        end
    end)
end

local function stopAntiSentry()
    antiSentryEnabled = false
    if antiSentryConn then antiSentryConn:Disconnect(); antiSentryConn = nil end
    sentryTarget = nil
end

-- ===========================
-- MISC: ANTI BEE & DISCO
-- ===========================
local antiBeeDiscoEnabled = false
local abdConns = {}
local FOV_LOCK = 70

local abdBlacklist = {
    "BlurEffect", "ColorCorrectionEffect", "BloomEffect", "SunRaysEffect", "DepthOfFieldEffect",
    "Atmosphere", "Sky", "Smoke", "ParticleEmitter", "Beam", "Trail", "Highlight", "PostEffect",
    "SurfaceAppearance", "Fire", "Sparkles", "Explosion", "PointLight", "SpotLight", "SurfaceLight",
    "Shadows", "Blur", "Fog", "ColorGradingEffect", "ToneMappingEffect", "VignetteEffect", "GodRays",
    "Glare", "ChromaticAberrationEffect", "DistortionEffect", "LensFlare", "SunFlare", "LightInfluence",
    "AmbientOcclusionEffect", "RefractionEffect", "HeatDistortion", "GlitchEffect", "ScreenSpaceReflection",
    "MotionBlur", "VolumetricLight", "RainEffect", "SnowEffect", "LightningEffect", "NeonGlow",
    "ContrastCorrection", "ShadowMap", "Bloom", "Clouds", "FogVolume", "WaterEffect", "WindEffect",
    "PixelateEffect", "FilmGrainEffect", "CRTShader", "NightVisionEffect", "InfraredEffect", "HazeEffect",
    "ColorBalanceEffect", "DynamicLight", "AmbientEffect", "ScreenDistortion", "ScanlineEffect",
    "UnderwaterEffect", "ThermalVision", "ShockwaveEffect", "FlashEffect", "ExplosionLight", "VFXPart",
    "GlitchScreen", "ScreenFlash", "OverlayEffect", "ShadowEffect", "GhostEffect", "FogEmitter",
    "WindEmitter", "HeatWave", "SunGlow", "ColorOverlay", "VisionDistort", "EchoEffect", "ScreenOverlay",
    "RenderEffect", "VisualEffect", "LightingEffect", "CameraEffect", "WeatherEffect", "SmokeTrail",
    "FireTrail", "NeonEffect", "RefractionLayer", "PostProcessingEffect", "VisualNoise", "ScreenNoise"
}

local function isAbdBlacklisted(obj)
    for _, name in ipairs(abdBlacklist) do
        if obj:IsA(name) then return true end
    end
    return false
end

local function clearAbdEffects()
    for _, v in pairs(Lighting:GetDescendants()) do
        if isAbdBlacklisted(v) then pcall(function() v:Destroy() end) end
    end
end

local function startAntiBeeDisco()
    if antiBeeDiscoEnabled then return end
    antiBeeDiscoEnabled = true
    clearAbdEffects()

    table.insert(abdConns, Lighting.DescendantAdded:Connect(function(obj)
        task.wait()
        if antiBeeDiscoEnabled and isAbdBlacklisted(obj) then pcall(function() obj:Destroy() end) end
    end))

    local camera = Workspace.CurrentCamera
    table.insert(abdConns, RunService.RenderStepped:Connect(function()
        if not antiBeeDiscoEnabled then return end
        if camera.FieldOfView ~= FOV_LOCK then camera.FieldOfView = FOV_LOCK end
    end))

    local moveVector = Vector3.zero
    table.insert(abdConns, UIS.InputChanged:Connect(function(input)
        if not antiBeeDiscoEnabled then return end
        if input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.KeyCode == Enum.KeyCode.Thumbstick1 then
                moveVector = Vector3.new(input.Position.X, 0, -input.Position.Y)
            end
        end
    end))

    table.insert(abdConns, RunService.RenderStepped:Connect(function()
        if not antiBeeDiscoEnabled then return end
        -- Fix opcional móvil para forzar movimiento pese a los stuns.
        if moveVector.Magnitude > 0 then
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then humanoid:Move(moveVector, true) end
            end
        end
    end))
end

local function stopAntiBeeDisco()
    antiBeeDiscoEnabled = false
    for _, c in ipairs(abdConns) do pcall(function() c:Disconnect() end) end
    abdConns = {}
end

-- ===========================
-- MAIN: AUTO DESYNC
-- ===========================
local autoDesyncEnabled = false
local autoDesyncCharacterConn = nil
local desyncMode = "Respawn"
local DESYNC_MODE_RESPAWN_KEY = "Main::Desync Mode: Respawn"
local DESYNC_MODE_CLONER_KEY = "Main::Desync Mode: Cloner"

local function setDesyncState(state)
    pcall(function()
        if raknet and raknet.desync then
            raknet.desync(state)
        end
    end)
end

local function startAutoDesync()
    if autoDesyncEnabled then return end
    autoDesyncEnabled = true
    setDesyncState(true)
    if autoDesyncCharacterConn then autoDesyncCharacterConn:Disconnect() end
    autoDesyncCharacterConn = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.8)
        if autoDesyncEnabled then
            setDesyncState(true)
            notify("⚡ Auto Desync reactivado tras respawn.", THEME.Primary, 2.4)
        end
    end)
    notify("⚡ Auto Desync activado (" .. desyncMode .. ").", THEME.Green, 2.2)
end

local function stopAutoDesync()
    if not autoDesyncEnabled then return end
    autoDesyncEnabled = false
    setDesyncState(false)
    if autoDesyncCharacterConn then autoDesyncCharacterConn:Disconnect(); autoDesyncCharacterConn = nil end
    notify("❌ Auto Desync desactivado.", THEME.Red, 2.2)
end

local function syncDesyncModeToggles(changedMode, isEnabled)
    if not isEnabled then
        local respawnCtrl = toggleControllers[DESYNC_MODE_RESPAWN_KEY]
        local clonerCtrl = toggleControllers[DESYNC_MODE_CLONER_KEY]
        if respawnCtrl and clonerCtrl and not respawnCtrl:GetState() and not clonerCtrl:GetState() then
            respawnCtrl:SetState(true, true)
            desyncMode = "Respawn"
        end
        return
    end

    if changedMode == "Respawn" then
        desyncMode = "Respawn"
        local clonerCtrl = toggleControllers[DESYNC_MODE_CLONER_KEY]
        if clonerCtrl and clonerCtrl:GetState() then
            clonerCtrl:SetState(false, true)
        end
    else
        desyncMode = "Cloner"
        local respawnCtrl = toggleControllers[DESYNC_MODE_RESPAWN_KEY]
        if respawnCtrl and respawnCtrl:GetState() then
            respawnCtrl:SetState(false, true)
        end
    end
    notify("Modo Desync: " .. desyncMode, THEME.Primary, 1.8)
end

-- ============================================================
-- // REGISTRO DE TODOS LOS TOGGLES
-- ============================================================

-- MAIN TAB
_G.KYNAddToggle("Main", {Name = "Auto Steal",  Disabled = true})
_G.KYNAddToggle("Main", {Name = "Auto Desync", Callback = function(s)
    if s then startAutoDesync() else stopAutoDesync() end
end})
_G.KYNAddToggle("Main", {Name = "Desync Mode: Respawn", Callback = function(s)
    syncDesyncModeToggles("Respawn", s)
end})
_G.KYNAddToggle("Main", {Name = "Desync Mode: Cloner", Callback = function(s)
    syncDesyncModeToggles("Cloner", s)
end})

task.defer(function()
    local respawnCtrl = toggleControllers[DESYNC_MODE_RESPAWN_KEY]
    local clonerCtrl = toggleControllers[DESYNC_MODE_CLONER_KEY]
    if not respawnCtrl or not clonerCtrl then return end

    if respawnCtrl:GetState() and clonerCtrl:GetState() then
        clonerCtrl:SetState(false, true)
    elseif not respawnCtrl:GetState() and not clonerCtrl:GetState() then
        respawnCtrl:SetState(true, true)
    end

    desyncMode = clonerCtrl:GetState() and "Cloner" or "Respawn"
end)

-- VISUAL TAB
_G.KYNAddToggle("Visual", {Name = "ESP Player", Callback = function(s)
    if s then startESPPlayer() else stopESPPlayer() end
end})
_G.KYNAddToggle("Visual", {Name = "ESP Base Time", Callback = function(s)
    if s then startESPBase() else stopESPBase() end
end})
_G.KYNAddToggle("Visual", {Name = "ESP Stealers", Callback = function(s)
    if s then startESPStealers() else stopESPStealers() end
end})
_G.KYNAddToggle("Visual", {Name = "X-Ray Base", Callback = function(s)
    if s then startXRay() else stopXRay() end
end})

-- MISC TAB
_G.KYNAddToggle("Misc", {Name = "Infinite Jump", Callback = function(s)
    if s then startInfiniteJump() else stopInfiniteJump() end
end})
_G.KYNAddToggle("Misc", {Name = "Anti Ragdoll", Callback = function(s)
    if s then startAntiRagdoll() else stopAntiRagdoll() end
end})
_G.KYNAddToggle("Misc", {Name = "Anti Lag", Callback = function(s)
    if s then startAntiLag() else stopAntiLag() end
end})
_G.KYNAddToggle("Misc", {Name = "Freeze Animations", Callback = function(s)
    if s then startFreezeAnims() else stopFreezeAnims() end
end})
_G.KYNAddToggle("Misc", {Name = "Anti Torret", Callback = function(s)
    if s then startAntiSentry() else stopAntiSentry() end
end})
_G.KYNAddToggle("Misc", {Name = "Anti Bee & Disco", Callback = function(s)
    if s then startAntiBeeDisco() else stopAntiBeeDisco() end
end})
