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

-- ============================================================
-- // SISTEMA DE SONIDO UI (Global)
-- ============================================================
local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://421058925" -- Sonido de click moderno y limpio
clickSound.Volume = 0.6
pcall(function() clickSound.Parent = game:GetService("SoundService") end)

local function attachSoundToButton(obj)
    -- Verifica si es un botón (TextButton o ImageButton) y si no tiene ya el sonido asignado
    if obj:IsA("GuiButton") and not obj:GetAttribute("HasClickSound") then
        obj:SetAttribute("HasClickSound", true)
        obj.Activated:Connect(function()
            clickSound:Play()
        end)
    end
end

-- ============================================================
-- // WIKI IMAGE SYSTEM (Auto-destrucción de archivos temp)
-- ============================================================
local WIKI_API             = "https://stealabrainrot.fandom.com/api.php"
local brainrotImageCache   = {}   -- [name] = assetId | "loading" | ""

-- Limpieza de residuos de ejecuciones anteriores
pcall(function()
    for _, file in ipairs(listfiles("") or {}) do
        if tostring(file):find("temp_brainrot_") then pcall(delfile, file) end
    end
end)

local function fetchBrainrotImage(name, callback)
    if not name or name == "" then callback("") return end
    if brainrotImageCache[name] then
        if brainrotImageCache[name] ~= "loading" then
            callback(brainrotImageCache[name])
        end
        return
    end
    brainrotImageCache[name] = "loading"
    task.spawn(function()
        -- 1. Consultar la Wiki
        local ok, res = pcall(function()
            return request({
                Url    = WIKI_API .. "?action=query&titles=" .. HttpService:UrlEncode(name)
                       .. "&prop=pageimages&pithumbsize=256&format=json&origin=*",
                Method = "GET"
            })
        end)
        if not ok or not res or res.StatusCode ~= 200 then
            brainrotImageCache[name] = "" ; callback("") ; return
        end
        local data
        pcall(function() data = HttpService:JSONDecode(res.Body) end)
        local thumbUrl = nil
        if data and data.query and data.query.pages then
            for _, page in pairs(data.query.pages) do
                if page.thumbnail then thumbUrl = page.thumbnail.source ; break end
            end
        end
        if not thumbUrl then brainrotImageCache[name] = "" ; callback("") ; return end
        -- 2. Descargar imagen
        local ok2, imgData = pcall(function()
            return request({ Url = thumbUrl, Method = "GET" }).Body
        end)
        if not ok2 or not imgData then brainrotImageCache[name] = "" ; callback("") ; return end
        -- 3. Guardar temporalmente y convertir a asset
        local tempFile = "temp_brainrot_" .. HttpService:GenerateGUID(false):sub(1, 8) .. ".png"
        local asset = ""
        pcall(function()
            writefile(tempFile, imgData)
            asset = getcustomasset(tempFile)
            task.delay(3, function()
                pcall(function() if isfile(tempFile) then delfile(tempFile) end end)
            end)
        end)
        brainrotImageCache[name] = asset
        callback(asset)
    end)
end

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

-- saveKey opcional: si se pasa, guarda/restaura la posición del frame en kynConfig
local function MakeDraggable(dragFrame, handle, saveKey)
    handle = handle or dragFrame
    local dragging, dragInput, dragStart, startPos

    -- Restaurar posición guardada
    if saveKey and kynConfig[saveKey] then
        local p = kynConfig[saveKey]
        pcall(function()
            dragFrame.Position = UDim2.new(p.XS, p.XO, p.YS, p.YO)
        end)
    end

    local function savePos()
        if saveKey then
            local p = dragFrame.Position
            kynConfig[saveKey] = {XS=p.X.Scale, XO=p.X.Offset, YS=p.Y.Scale, YO=p.Y.Offset}
            saveKYNConfig()
        end
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = dragFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    savePos()
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
local gui, toggleBtn, btnGradient, mainDragFrame, mainFrame, uiScale, mainGradient, tabs
do
gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui
gui.DescendantAdded:Connect(attachSoundToButton)

local btnDragFrame = Instance.new("Frame", gui)
btnDragFrame.Size = UDim2.new(0, 55, 0, 55)
btnDragFrame.Position = UDim2.new(0, 20, 0.2, 0)
btnDragFrame.BackgroundTransparency = 1
btnDragFrame.Active = true

toggleBtn = Instance.new("ImageButton", btnDragFrame)
toggleBtn.Size = UDim2.new(1, 0, 1, 0)
toggleBtn.Image = "rbxassetid://82945336379835"
toggleBtn.BackgroundColor3 = THEME.Frame
toggleBtn.Active = true
corner(toggleBtn, 50)

local btnStroke = stroke(toggleBtn, Color3.new(1, 1, 1), 3)
btnGradient = Instance.new("UIGradient", btnStroke)
btnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0,    THEME.Secondary),
    ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
    ColorSequenceKeypoint.new(0.5,  THEME.Primary),
    ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
    ColorSequenceKeypoint.new(1,    THEME.Secondary),
}

MakeDraggable(btnDragFrame, toggleBtn, "pos_toggleBtn")

toggleBtn.MouseEnter:Connect(function()
    tween(toggleBtn, {Size = UDim2.new(1.1, 0, 1.1, 0), Position = UDim2.new(-0.05, 0, -0.05, 0)}, 0.2, Enum.EasingStyle.Back)
end)
toggleBtn.MouseLeave:Connect(function()
    tween(toggleBtn, {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Back)
end)

mainDragFrame = Instance.new("Frame", gui)
mainDragFrame.Size = UDim2.new(0, 300, 0, 370)
mainDragFrame.Position = UDim2.new(0.5, -150, 0.5, -185)
mainDragFrame.BackgroundTransparency = 1
mainDragFrame.Active = true
mainDragFrame.Visible = false

mainFrame = Instance.new("Frame", mainDragFrame)
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = THEME.BG
mainFrame.ClipsDescendants = false
corner(mainFrame, 12)

uiScale = Instance.new("UIScale", mainDragFrame)
uiScale.Scale = 0

local mainStroke = stroke(mainFrame, Color3.new(1, 1, 1), 4)
mainGradient = Instance.new("UIGradient", mainStroke)
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

MakeDraggable(mainDragFrame, header, "pos_mainFrame")

-- Detectar plataforma (Si tiene pantalla táctil y NO tiene teclado físico, es móvil)
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local platformLbl = Instance.new("TextLabel", header)
platformLbl.Size = UDim2.new(0, 70, 0, 26)
platformLbl.Position = UDim2.new(1, -110, 0.5, -13) -- Al lado izquierdo de la X
platformLbl.BackgroundTransparency = 1
platformLbl.Text = isMobile and "📱 Móvil" or "💻 PC"
platformLbl.TextColor3 = THEME.Dim
platformLbl.Font = Enum.Font.GothamBold
platformLbl.TextSize = 12
platformLbl.TextXAlignment = Enum.TextXAlignment.Right

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

tabs, tabButtons, tabStrokes = {}, {}, {}

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
end -- do-block: SETUP PRINCIPAL

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
local doFloatToggle -- forward declaration for F key bind

-- ============================================================
-- // HUD DE FPS / PING (PERMANENTE, ARRASTRABLE)
-- ============================================================
do
    local fpsCount  = 0
    local fpsClock  = os.clock()
    local currentFPS = 0

    local hudFrame = Instance.new("Frame", gui)
    hudFrame.Name              = "KYN_FPS_HUD"
    hudFrame.Size              = UDim2.new(0, 310, 0, 38)
    hudFrame.Position          = UDim2.new(0.5, -155, 0, -50)   -- empieza fuera de pantalla
    hudFrame.BackgroundColor3  = THEME.BG
    hudFrame.Active            = true
    hudFrame.ZIndex            = 50
    corner(hudFrame, 50)

    local hudStroke = stroke(hudFrame, Color3.new(1,1,1), 2.5)
    local hudGrad   = Instance.new("UIGradient", hudStroke)
    hudGrad.Color   = ColorSequence.new{
        ColorSequenceKeypoint.new(0,    THEME.Secondary),
        ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
        ColorSequenceKeypoint.new(0.5,  THEME.Primary),
        ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
        ColorSequenceKeypoint.new(1,    THEME.Secondary),
    }

    -- Nombre del script (con degradado animado)
    local hudTitle = Instance.new("TextLabel", hudFrame)
    hudTitle.Size               = UDim2.new(0, 90, 1, 0)
    hudTitle.Position           = UDim2.new(0, 10, 0, 0)
    hudTitle.BackgroundTransparency = 1
    hudTitle.Text               = "⚡ KYN HUB"
    hudTitle.Font               = Enum.Font.GothamBlack
    hudTitle.TextSize           = 13
    hudTitle.TextColor3         = THEME.Primary
    hudTitle.TextXAlignment     = Enum.TextXAlignment.Left
    hudTitle.ZIndex             = 51

    local hudTitleGrad = Instance.new("UIGradient", hudTitle)
    hudTitleGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   THEME.Primary),
        ColorSequenceKeypoint.new(0.5, THEME.Secondary),
        ColorSequenceKeypoint.new(1,   THEME.Primary),
    }
    hudTitleGrad.Rotation = 0

    -- FPS Label
    local hudFPSLbl = Instance.new("TextLabel", hudFrame)
    hudFPSLbl.Size               = UDim2.new(0, 85, 1, 0)
    hudFPSLbl.Position           = UDim2.new(0, 106, 0, 0)
    hudFPSLbl.BackgroundTransparency = 1
    hudFPSLbl.Text               = "FPS: --"
    hudFPSLbl.Font               = Enum.Font.GothamBold
    hudFPSLbl.TextSize           = 13
    hudFPSLbl.TextColor3         = THEME.Primary
    hudFPSLbl.TextXAlignment     = Enum.TextXAlignment.Left
    hudFPSLbl.ZIndex             = 51

    -- Separador vertical entre FPS y Ping
    local hudSep = Instance.new("Frame", hudFrame)
    hudSep.Size             = UDim2.new(0, 1, 0.5, 0)
    hudSep.Position         = UDim2.new(0, 196, 0.25, 0)
    hudSep.BackgroundColor3 = THEME.BorderOff
    hudSep.BorderSizePixel  = 0

    -- Ping Label
    local hudPingLbl = Instance.new("TextLabel", hudFrame)
    hudPingLbl.Size               = UDim2.new(0, 90, 1, 0)
    hudPingLbl.Position           = UDim2.new(0, 203, 0, 0)
    hudPingLbl.BackgroundTransparency = 1
    hudPingLbl.Text               = "PING: --"
    hudPingLbl.Font               = Enum.Font.GothamBold
    hudPingLbl.TextSize           = 13
    hudPingLbl.TextColor3         = Color3.fromRGB(255, 180, 50)
    hudPingLbl.TextXAlignment     = Enum.TextXAlignment.Left
    hudPingLbl.ZIndex             = 51

    -- Draggable
    MakeDraggable(hudFrame, hudFrame, "pos_fpsHud")

    -- Animación de entrada (desliza desde arriba)
    task.delay(0.6, function()
        TweenService:Create(hudFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Position = UDim2.new(0.5, -155, 0, 8) }):Play()
    end)

    -- Loop de actualización FPS + Ping + animación degradado
    RunService.RenderStepped:Connect(function()
        fpsCount += 1
        hudGrad.Rotation    = (hudGrad.Rotation    + 2) % 360
        hudTitleGrad.Rotation = (hudTitleGrad.Rotation + 1.5) % 360

        local now = os.clock()
        if now - fpsClock >= 0.5 then
            currentFPS = math.round(fpsCount / (now - fpsClock))
            fpsCount   = 0
            fpsClock   = now

            -- Color FPS según rendimiento
            if currentFPS >= 55 then
                hudFPSLbl.TextColor3 = THEME.Green
            elseif currentFPS >= 30 then
                hudFPSLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
            else
                hudFPSLbl.TextColor3 = THEME.Red
            end
            hudFPSLbl.Text = "FPS: " .. currentFPS

            -- Ping
            local pingMs = 0
            pcall(function()
                pingMs = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            if pingMs == 0 then
                pcall(function()
                    pingMs = math.round(Players:GetNetworkPing() * 1000)
                end)
            end

            if pingMs <= 80 then
                hudPingLbl.TextColor3 = THEME.Green
            elseif pingMs <= 150 then
                hudPingLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
            else
                hudPingLbl.TextColor3 = THEME.Red
            end
            hudPingLbl.Text = "PING: " .. pingMs .. "ms"
        end
    end)
end

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
            currentBillboard.Size = UDim2.new(0, 220, 0, 68)
            currentBillboard.StudsOffset = Vector3.new(0, 4.5, 0)
            currentBillboard.AlwaysOnTop = true
currentBillboard.Adornee = targetPart
            if not pcall(function() currentBillboard.Parent = CoreGui end) then
                currentBillboard.Parent = LocalPlayer:WaitForChild("PlayerGui")
            end

            local bg = Instance.new("Frame", currentBillboard)
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            bg.BackgroundTransparency = 0.35
            bg.BorderSizePixel = 0
            Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
            
            -- BORDE GIRATORIO (IGUAL QUE LOS OTROS ESP)
            local bbStroke = Instance.new("UIStroke", bg)
            bbStroke.Thickness = 2
            bbStroke.Color = Color3.new(1, 1, 1)
            bbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local grad = Instance.new("UIGradient", bbStroke)
            grad.Color = espGradientColor
            grad.Rotation = 0
            table.insert(espGradients, grad)

            -- IMAGEN CIRCULAR DEL BRAINROT
            local imgHolder = Instance.new("Frame", bg)
            imgHolder.Name       = "ImgHolder"
            imgHolder.Size       = UDim2.new(0, 52, 0, 52)
            imgHolder.Position   = UDim2.new(0, 6, 0.5, -26)
            imgHolder.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
            imgHolder.BorderSizePixel  = 0
            Instance.new("UICorner", imgHolder).CornerRadius = UDim.new(1, 0)

            local imgCircleStroke = Instance.new("UIStroke", imgHolder)
            imgCircleStroke.Thickness = 2
            imgCircleStroke.Color     = Color3.new(1, 1, 1)
            imgCircleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local imgGrad = Instance.new("UIGradient", imgCircleStroke)
            imgGrad.Color    = espGradientColor
            imgGrad.Rotation = 0
            table.insert(espGradients, imgGrad)

            local brainrotImg = Instance.new("ImageLabel", imgHolder)
            brainrotImg.Name               = "BrainrotImg"
            brainrotImg.Size               = UDim2.new(1, 0, 1, 0)
            brainrotImg.BackgroundTransparency = 1
            brainrotImg.Image              = ""
            brainrotImg.ScaleType          = Enum.ScaleType.Fit
            Instance.new("UICorner", brainrotImg).CornerRadius = UDim.new(1, 0)

            local nameLbl = Instance.new("TextLabel", bg)
            nameLbl.Name = "PetName"
            nameLbl.Size = UDim2.new(1, -66, 0, 30)
            nameLbl.Position = UDim2.new(0, 62, 0, 4)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBlack
            nameLbl.TextSize = 13
            nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            
            local valLbl = Instance.new("TextLabel", bg)
            valLbl.Name = "PetVal"
            valLbl.Size = UDim2.new(1, -66, 0, 26)
            valLbl.Position = UDim2.new(0, 62, 0, 36)
            valLbl.BackgroundTransparency = 1
            valLbl.Font = Enum.Font.GothamBold
            valLbl.TextSize = 12
            valLbl.TextColor3 = THEME.Primary
            valLbl.TextXAlignment = Enum.TextXAlignment.Left
        end

        if currentBillboard then
            local bg = currentBillboard:FindFirstChildOfClass("Frame")
            if bg then
                bg.PetName.Text = target.name
                bg.PetVal.Text  = target.genText
                -- Actualizar imagen circular del brainrot
                local imgHolder = bg:FindFirstChild("ImgHolder")
                if imgHolder then
                    local imgLbl = imgHolder:FindFirstChild("BrainrotImg")
                    if imgLbl then
                        fetchBrainrotImage(target.name, function(asset)
                            if imgLbl and imgLbl.Parent then imgLbl.Image = asset end
                        end)
                    end
                end
            end
        end
    end

-- Buscar primero en CoreGui o PlayerGui para limpiar interfaces repetidas
    local oldASG = CoreGui:FindFirstChild("KYN_AutoStealGUI")
    if not oldASG then
        pcall(function() oldASG = LocalPlayer.PlayerGui:FindFirstChild("KYN_AutoStealGUI") end)
    end
    if oldASG then oldASG:Destroy() end

autoStealGui = Instance.new("ScreenGui")
    autoStealGui.Name = "KYN_AutoStealGUI"
    autoStealGui.ResetOnSpawn = false
    autoStealGui.IgnoreGuiInset = true
    autoStealGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- SOLUCIÓN PC: Enviar al CoreGui o PlayerGui (¡ESTA PARTE FALTABA!)
    if not pcall(function() autoStealGui.Parent = CoreGui end) then
        autoStealGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Detectar botones creados en Auto Steal
    autoStealGui.DescendantAdded:Connect(attachSoundToButton)
    for _, obj in pairs(autoStealGui:GetDescendants()) do attachSoundToButton(obj) end

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

    MakeDraggable(asMain, nil, "pos_autoSteal")

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
            ItemBtn.Size = UDim2.new(1, -8, 0, 38)
            ItemBtn.BackgroundColor3 = isTarget and THEME.DarkBlue or THEME.Frame
            ItemBtn.BorderSizePixel = 0; ItemBtn.Text = ""; ItemBtn.AutoButtonColor = false
            corner(ItemBtn, 6)
            
            ItemBtn.MouseButton1Click:Connect(function() manualTargetUid = pet.uid end)
            
            if isTarget then
                local Stroke = Instance.new("UIStroke", ItemBtn)
                Stroke.Color = THEME.Primary; Stroke.Thickness = 1.5
            end

            -- IMAGEN CIRCULAR DEL BRAINROT EN LA LISTA
            local petImgHolder = Instance.new("Frame", ItemBtn)
            petImgHolder.Name              = "PetImgHolder"
            petImgHolder.Size              = UDim2.new(0, 30, 0, 30)
            petImgHolder.Position          = UDim2.new(0, 5, 0.5, -15)
            petImgHolder.BackgroundColor3  = Color3.fromRGB(10, 15, 30)
            petImgHolder.BorderSizePixel   = 0
            Instance.new("UICorner", petImgHolder).CornerRadius = UDim.new(1, 0)

            local petImgStroke = Instance.new("UIStroke", petImgHolder)
            petImgStroke.Thickness = 1.5
            petImgStroke.Color     = Color3.new(1, 1, 1)
            petImgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            local petImgGrad = Instance.new("UIGradient", petImgStroke)
            petImgGrad.Color    = espGradientColor
            petImgGrad.Rotation = 0
            table.insert(espGradients, petImgGrad)

            local petImgLbl = Instance.new("ImageLabel", petImgHolder)
            petImgLbl.Name                  = "PetImg"
            petImgLbl.Size                  = UDim2.new(1, 0, 1, 0)
            petImgLbl.BackgroundTransparency = 1
            petImgLbl.Image                 = ""
            petImgLbl.ScaleType             = Enum.ScaleType.Fit
            Instance.new("UICorner", petImgLbl).CornerRadius = UDim.new(1, 0)

            -- Cargar imagen en background (usa caché)
            do
                local capturedLbl = petImgLbl
                fetchBrainrotImage(pet.name, function(asset)
                    if capturedLbl and capturedLbl.Parent then capturedLbl.Image = asset end
                end)
            end
            
            local RankLbl = Instance.new("TextLabel", ItemBtn)
            RankLbl.Size = UDim2.new(0, 20, 1, 0); RankLbl.Position = UDim2.new(0, 40, 0, 0)
            RankLbl.BackgroundTransparency = 1; RankLbl.Text = "#" .. i
            RankLbl.TextColor3 = isTarget and THEME.Primary or THEME.Dim
            RankLbl.Font = Enum.Font.GothamBlack; RankLbl.TextSize = 12
            
            local NameLbl = Instance.new("TextLabel", ItemBtn)
            NameLbl.Size = UDim2.new(1, -115, 1, 0); NameLbl.Position = UDim2.new(0, 64, 0, 0)
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
        ListScroll.CanvasSize = UDim2.new(0, 0, 0, count * 43)
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
local _ESP = {
    playerConn     = nil,
    playerFolder   = nil,
    baseConn       = nil,
    stealersConn   = nil,
    stealersActive = false,
    mineConn       = nil,
    mineFolder     = nil,
    xrayConn       = nil,
}

local function startESPPlayer()
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    if _ESP.playerFolder then _ESP.playerFolder:Destroy() end
    _ESP.playerFolder = Instance.new("Folder")
    _ESP.playerFolder.Name = "KYN_PlayerESP"
    _ESP.playerFolder.Parent = PlayerGui

    local function createOrUpdatePlayerESP(player)
        if player == LocalPlayer then return end
        if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = player.Character.HumanoidRootPart

        -- Si ESP Stealers está activo y este jugador está robando, no tocar su billboard
        if _ESP.stealersActive and player:GetAttribute("Stealing") then return end

        local highlight = _ESP.playerFolder:FindFirstChild(player.Name .. "_Highlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = player.Name .. "_Highlight"
            highlight.FillColor = Color3.fromRGB(0, 0, 255)
            highlight.FillTransparency = 0.7
            highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
            highlight.OutlineTransparency = 0
            highlight.Parent = _ESP.playerFolder
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

    _ESP.playerConn = RunService.Heartbeat:Connect(function()
        for _, player in pairs(Players:GetPlayers()) do
            pcall(function() createOrUpdatePlayerESP(player) end)
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        if not _ESP.playerFolder then return end
        local hl = _ESP.playerFolder:FindFirstChild(player.Name .. "_Highlight")
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
    if _ESP.playerConn then _ESP.playerConn:Disconnect(); _ESP.playerConn = nil end
    if _ESP.playerFolder then _ESP.playerFolder:Destroy(); _ESP.playerFolder = nil end
end

-- ===========================
-- VISUAL: ESP BASE TIME
-- ===========================
_ESP.baseConn = nil

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

    _ESP.baseConn = RunService.Heartbeat:Connect(function()
        local Plots = Workspace:FindFirstChild("Plots")
        if not Plots then return end
        local ownBasePos = getOwnBasePosition()
        for _, plot in pairs(Plots:GetChildren()) do
            pcall(function() updatePlotESP(plot, ownBasePos) end)
        end
    end)
end

local function stopESPBase()
    if _ESP.baseConn then _ESP.baseConn:Disconnect(); _ESP.baseConn = nil end
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
_ESP.stealersConn      = nil
_ESP.stealersActive    = false
_ESP.stealerConns      = {}   -- [userId] = {conn1, conn2, charConn}

-- Crea un billboard de dos líneas para el stealer (nombre + brainrot)
local function makeStealerBillboard(rootPart, playerName, brainrotName)
    local bb = Instance.new("BillboardGui")
    bb.Name        = "KYN_StealerBB"
    bb.Size        = UDim2.new(0, 190, 0, 56)
    bb.StudsOffset = Vector3.new(0, 4.8, 0)
    bb.AlwaysOnTop = true
    bb.Adornee     = rootPart
    bb.Parent      = rootPart

    local bg = Instance.new("Frame", bb)
    bg.Size                  = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.38
    bg.BorderSizePixel       = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)

    local bbStroke = Instance.new("UIStroke", bg)
    bbStroke.Thickness      = 2
    bbStroke.Color          = Color3.new(1, 1, 1)
    bbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    local bbGrad = Instance.new("UIGradient", bbStroke)
    bbGrad.Color    = espStealerGradientColor
    bbGrad.Rotation = 0
    table.insert(espGradients, bbGrad)

    -- Línea 1: Nombre del jugador
    local nameLbl = Instance.new("TextLabel", bg)
    nameLbl.Name               = "StealerName"
    nameLbl.Size               = UDim2.new(1, -10, 0, 26)
    nameLbl.Position           = UDim2.new(0, 5, 0, 2)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font               = Enum.Font.GothamBlack
    nameLbl.TextSize            = 14
    nameLbl.TextColor3          = Color3.fromRGB(255, 255, 255)
    nameLbl.TextStrokeTransparency = 0.4
    nameLbl.TextStrokeColor3   = Color3.new(0, 0, 0)
    nameLbl.TextXAlignment     = Enum.TextXAlignment.Center
    nameLbl.Text               = playerName
    nameLbl.ZIndex             = 2

    -- Línea 2: Nombre del brainrot
    local brainLbl = Instance.new("TextLabel", bg)
    brainLbl.Name               = "StealerBrainrot"
    brainLbl.Size               = UDim2.new(1, -10, 0, 20)
    brainLbl.Position           = UDim2.new(0, 5, 0, 30)
    brainLbl.BackgroundTransparency = 1
    brainLbl.Font               = Enum.Font.GothamBold
    brainLbl.TextSize            = 12
    brainLbl.TextColor3          = Color3.fromRGB(255, 200, 50)
    brainLbl.TextStrokeTransparency = 0.5
    brainLbl.TextStrokeColor3   = Color3.new(0, 0, 0)
    brainLbl.TextXAlignment     = Enum.TextXAlignment.Center
    brainLbl.TextTruncate       = Enum.TextTruncate.AtEnd
    brainLbl.Text               = brainrotName ~= "" and ("🎒 " .. brainrotName) or "🎒 Robando..."
    brainLbl.ZIndex             = 2

    return bb
end

-- Oculta/muestra el billboard del ESP Player para un jugador
local function setPlayerESPVisible(player, visible)
    if not _ESP.stealersActive then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local bb = hrp:FindFirstChild("KYN_PlayerBB")
    if bb then bb.Enabled = visible end
    -- También ocultamos el highlight del ESP Player
    if _ESP.playerFolder then
        local hl = _ESP.playerFolder:FindFirstChild(player.Name .. "_Highlight")
        if hl then hl.Enabled = visible end
    end
end

-- Aplica o actualiza el ESP del stealer en un jugador
local function applyStealerESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return end

    -- Ocultar ESP Player si está activo
    setPlayerESPVisible(player, false)

    -- Highlight naranja (solo crear si no existe)
    if not char:FindFirstChild("KYN_StealerHighlight") then
        local hl = Instance.new("Highlight")
        hl.Name              = "KYN_StealerHighlight"
        hl.FillColor         = Color3.fromRGB(255, 130, 0)
        hl.OutlineColor      = Color3.fromRGB(255, 220, 0)
        hl.FillTransparency  = 0.45
        hl.DepthMode         = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent            = char
    end

    -- Billboard: actualizar si ya existe, crear si no
    local brainrotName = tostring(player:GetAttribute("StealingIndex") or "")
    local existingBB = root:FindFirstChild("KYN_StealerBB")
    if existingBB then
        local bg = existingBB:FindFirstChildOfClass("Frame")
        if bg then
            local bl = bg:FindFirstChild("StealerBrainrot")
            if bl then bl.Text = brainrotName ~= "" and ("🎒 " .. brainrotName) or "🎒 Robando..." end
        end
    else
        makeStealerBillboard(root, player.Name, brainrotName)
    end
end

-- Limpia el ESP del stealer y restaura el ESP Player
local function removeStealerESP(player)
    if player == LocalPlayer then return end
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
    -- Restaurar ESP Player si estaba activo
    setPlayerESPVisible(player, true)
end

-- Registra escuchas de atributos para un jugador
local function hookStealerPlayer(player)
    if player == LocalPlayer then return end
    if _ESP.stealerConns[player.UserId] then return end  -- ya conectado

    local function onStealingChanged()
        if not _ESP.stealersActive then return end
        local isStealing = player:GetAttribute("Stealing")
        if isStealing then
            applyStealerESP(player)
        else
            removeStealerESP(player)
        end
    end

    local conn1 = player:GetAttributeChangedSignal("Stealing"):Connect(onStealingChanged)
    local conn2 = player:GetAttributeChangedSignal("StealingIndex"):Connect(function()
        if _ESP.stealersActive and player:GetAttribute("Stealing") then
            applyStealerESP(player)
        end
    end)
    -- Reacción al respawn del personaje
    local conn3 = player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if _ESP.stealersActive then onStealingChanged() end
    end)

    _ESP.stealerConns[player.UserId] = {conn1, conn2, conn3}

    -- Estado inicial
    onStealingChanged()
end

local function unhookStealerPlayer(player)
    local conns = _ESP.stealerConns[player.UserId]
    if conns then
        for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
        _ESP.stealerConns[player.UserId] = nil
    end
    removeStealerESP(player)
end

local function startESPStealers()
    _ESP.stealersActive = true
    _ESP.stealerConns   = {}

    -- Conectar todos los jugadores actuales
    for _, player in ipairs(Players:GetPlayers()) do
        hookStealerPlayer(player)
    end

    -- Nuevos jugadores
    _ESP.stealersConn = Players.PlayerAdded:Connect(function(player)
        if _ESP.stealersActive then hookStealerPlayer(player) end
    end)
end

local function stopESPStealers()
    _ESP.stealersActive = false
    if _ESP.stealersConn then _ESP.stealersConn:Disconnect(); _ESP.stealersConn = nil end

    -- Desconectar y limpiar todos
    for _, player in ipairs(Players:GetPlayers()) do
        unhookStealerPlayer(player)
    end
    _ESP.stealerConns = {}
end

-- ===========================
-- VISUAL: ESP MINE
-- ===========================
_ESP.mineConn = nil
_ESP.mineFolder = nil

local function startESPMine()
    if _ESP.mineFolder then _ESP.mineFolder:Destroy() end
    _ESP.mineFolder = Instance.new("Folder", CoreGui)
    _ESP.mineFolder.Name = "KYN_MineESP"

    _ESP.mineConn = RunService.Heartbeat:Connect(function()
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
    if _ESP.mineConn then _ESP.mineConn:Disconnect() _ESP.mineConn = nil end
    if _ESP.mineFolder then _ESP.mineFolder:Destroy() _ESP.mineFolder = nil end
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
_ESP.xrayConn = nil

local function startXRay()
    if _ESP.xrayConn then _ESP.xrayConn:Disconnect(); _ESP.xrayConn = nil end
    _ESP.xrayConn = RunService.Heartbeat:Connect(function()
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
    if _ESP.xrayConn then _ESP.xrayConn:Disconnect(); _ESP.xrayConn = nil end
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
-- VISUAL: LINE TO BASE
-- ===========================
local ltbEnabled = false
local plotBeam, plotBeamAtt0, plotBeamAtt1
local ltbLoop, ltbCharConn

local function findMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end
    for _, plot in ipairs(plots:GetChildren()) do
        local sign = plot:FindFirstChild("PlotSign")
        if sign then
            local sg = sign:FindFirstChildWhichIsA("SurfaceGui", true)
            if sg then
                local lbl = sg:FindFirstChildWhichIsA("TextLabel", true)
                if lbl then
                    local txt = lbl.Text:lower()
                    if txt:find(LocalPlayer.DisplayName:lower(), 1, true) or txt:find(LocalPlayer.Name:lower(), 1, true) then
                        return plot
                    end
                end
            end
        end
    end
    return nil
end

local function createPlotBeam()
    if not ltbEnabled then return end
    local myPlot = findMyPlot()
    if not myPlot then return end
    
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    if plotBeam then pcall(function() plotBeam:Destroy() end) end
    if plotBeamAtt0 then pcall(function() plotBeamAtt0:Destroy() end) end
    
    plotBeamAtt0 = hrp:FindFirstChild("PlotBeamAttach_Player") or Instance.new("Attachment")
    plotBeamAtt0.Name = "PlotBeamAttach_Player"
    plotBeamAtt0.Parent = hrp
    
    local plotPart = myPlot:FindFirstChild("MainRootPart") or myPlot:FindFirstChildWhichIsA("BasePart")
    if not plotPart then return end
    
    plotBeamAtt1 = plotPart:FindFirstChild("PlotBeamAttach_Plot") or Instance.new("Attachment")
    plotBeamAtt1.Name = "PlotBeamAttach_Plot"
    plotBeamAtt1.Position = Vector3.new(0, 5, 0)
    plotBeamAtt1.Parent = plotPart
    
    plotBeam = hrp:FindFirstChild("PlotBeam") or Instance.new("Beam")
    plotBeam.Name = "PlotBeam"
    plotBeam.Attachment0 = plotBeamAtt0
    plotBeam.Attachment1 = plotBeamAtt1
    plotBeam.FaceCamera = true
    plotBeam.LightEmission = 1
    plotBeam.Color = ColorSequence.new(THEME.Primary)
    plotBeam.Transparency = NumberSequence.new(0)
    plotBeam.Width0 = 0.7
    plotBeam.Width1 = 0.7
    plotBeam.Parent = hrp
end

local function stopLineToBase()
    ltbEnabled = false
    if ltbLoop then ltbLoop:Disconnect(); ltbLoop = nil end
    if ltbCharConn then ltbCharConn:Disconnect(); ltbCharConn = nil end
    if plotBeam then pcall(function() plotBeam:Destroy() end) plotBeam = nil end
    if plotBeamAtt0 then pcall(function() plotBeamAtt0:Destroy() end) plotBeamAtt0 = nil end
    if plotBeamAtt1 then pcall(function() plotBeamAtt1:Destroy() end) plotBeamAtt1 = nil end
end

local function startLineToBase()
    if ltbEnabled then return end
    ltbEnabled = true
    pcall(createPlotBeam)
    
    local checkCounter = 0
    ltbLoop = RunService.Heartbeat:Connect(function()
        if not ltbEnabled then return end
        checkCounter = checkCounter + 1
        if checkCounter >= 30 then
            checkCounter = 0
            if not plotBeam or not plotBeam.Parent or not plotBeamAtt0 or not plotBeamAtt0.Parent then
                pcall(createPlotBeam)
            end
        end
    end)
    
    ltbCharConn = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if ltbEnabled then pcall(createPlotBeam) end
    end)
end

-- ===========================
-- MISC: INFINITE JUMP (ANTI-CHEAT SAFE)
-- ===========================
-- ===========================
-- MISC: INFINITE JUMP
-- ===========================
local IJ = {
    Enabled    = false,
    isJumping  = false,
    JumpPower  = {min = 45, max = 52},
    Cooldown   = {min = 0.05, max = 0.15},
    ClampFall  = -80,
    jumpConn   = nil,
    fallConn   = nil,
    charConn   = nil,
    character  = nil,
}
local function startInfiniteJump()
    IJ.Enabled   = true
    IJ.isJumping = false
    IJ.character  = LocalPlayer.Character

    -- Actualizar referencia al respawnear
    if IJ.charConn then IJ.charConn:Disconnect() end
    IJ.charConn = LocalPlayer.CharacterAdded:Connect(function(char)
        IJ.character = char
    end)

    -- Limitador de caída suave
    if IJ.fallConn then IJ.fallConn:Disconnect() end
    IJ.fallConn = RunService.Heartbeat:Connect(function()
        if not IJ.Enabled or not IJ.character then return end
        local hrp = IJ.character:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Velocity.Y < IJ.ClampFall then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, IJ.ClampFall, hrp.Velocity.Z)
        end
    end)

    -- Salto infinito humanizado via JumpRequest
    if IJ.jumpConn then IJ.jumpConn:Disconnect() end
    IJ.jumpConn = UIS.JumpRequest:Connect(function()
        if not IJ.Enabled or IJ.isJumping or not IJ.character then return end
        local humanoid = IJ.character:FindFirstChildOfClass("Humanoid")
        local hrp      = IJ.character:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp then
            IJ.isJumping = true
            local randomForce = math.random(IJ.JumpPower.min, IJ.JumpPower.max)
            hrp.Velocity = Vector3.new(hrp.Velocity.X, randomForce, hrp.Velocity.Z)
            -- Delay aleatorio para simular comportamiento humano
            task.wait(math.random(IJ.Cooldown.min * 100, IJ.Cooldown.max * 100) / 100)
            IJ.isJumping = false
        end
    end)
end

local function stopInfiniteJump()
    IJ.Enabled   = false
    IJ.isJumping = false
    if IJ.jumpConn  then IJ.jumpConn:Disconnect();  IJ.jumpConn  = nil end
    if IJ.fallConn  then IJ.fallConn:Disconnect();  IJ.fallConn  = nil end
    if IJ.charConn  then IJ.charConn:Disconnect();  IJ.charConn  = nil end
    IJ.character = nil
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
    cachedCharData = { character = char, humanoid = hum, root = root }
    return true
end

local function disconnectAllRagdoll()
    for _, conn in ipairs(ragdollConnections) do
        pcall(function() conn:Disconnect() end)
    end
    ragdollConnections = {}
end

local function isRagdolled()
    if isForcingReset then return false end  -- ← mantiene compatibilidad con Desync
    if not cachedCharData.humanoid then return false end
    local state = cachedCharData.humanoid:GetState()
    local ragdollStates = {
        [Enum.HumanoidStateType.Physics]     = true,
        [Enum.HumanoidStateType.Ragdoll]     = true,
        [Enum.HumanoidStateType.FallingDown] = true
    }
    if ragdollStates[state] then return true end
    local endTime = LocalPlayer:GetAttribute("RagdollEndTime")
    if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then
        return true
    end
    return false
end

-- Obtiene la posición del torso durante el ragdoll
local function getBodyLandingPosition()
    local char = cachedCharData.character
    local torso = char:FindFirstChild("LowerTorso")
                  or char:FindFirstChild("UpperTorso")
                  or char:FindFirstChild("Torso")
    if torso then return torso.Position end
    return nil
end

-- Usa BodyPosition para sincronizar posición con el servidor
local function forceSyncWithBodyPosition(targetPos)
    local root = cachedCharData.root
    if not root then return end
    local old = root:FindFirstChild("_SyncBP")
    if old then old:Destroy() end
    local bp = Instance.new("BodyPosition")
    bp.Name     = "_SyncBP"
    bp.Position = targetPos
    bp.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bp.D        = 100
    bp.P        = 1e5
    bp.Parent   = root
    root.AssemblyLinearVelocity  = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.delay(0.2, function()
        if bp and bp.Parent then bp:Destroy() end
        if cachedCharData.root and antiRagdollMode == "v1" then
            cachedCharData.root.CFrame = CFrame.new(targetPos)
            cachedCharData.root.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function forceExitRagdoll()
    if not cachedCharData.humanoid or not cachedCharData.root then return end
    pcall(function()
        LocalPlayer:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow())
    end)

    -- Captura posición ANTES de reactivar joints
    local landingPos = getBodyLandingPosition()
    local targetPos  = landingPos and (landingPos + Vector3.new(0, 2.5, 0)) or nil

    -- Reactiva Motor6D en vez de destruir constraints
    for _, descendant in ipairs(cachedCharData.character:GetDescendants()) do
        if descendant:IsA("Motor6D") then
            descendant.Enabled = true
        end
    end

    cachedCharData.humanoid.PlatformStand = false
    cachedCharData.root.Anchored = false

    if cachedCharData.humanoid.Health > 0 then
        cachedCharData.humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end

    -- Sincroniza posición con el servidor vía física
    if targetPos then
        forceSyncWithBodyPosition(targetPos)
    end

    if not isBoosting then
        isBoosting = true
        cachedCharData.humanoid.WalkSpeed = BOOST_SPEED
    end
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
        -- 1. Destruir Accesorios y Ropa (Extreme FPS Boost en personajes)
        if obj:IsA("Accessory") or obj:IsA("Hat") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") or obj:IsA("CharacterMesh") then
            obj:Destroy()
            return
        end

        -- 2. Quitar texturas de Meshes (Herramientas en mano, armas y mapa)
        if obj:IsA("SpecialMesh") then
            obj.TextureId = ""
        end
        if obj:IsA("MeshPart") then
            obj.TextureID = ""
            obj.RenderFidelity = Enum.RenderFidelity.Performance
        end

        -- 3. Optimizaciones generales
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.SmoothPlastic -- SmoothPlastic quita detalles de relieve (más FPS)
            obj.Reflectance = 0
            obj.CastShadow = false
        end
        if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
            obj.Enabled = false
        end
        if obj:IsA("UnionOperation") then
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
    
    -- Aplicar al mapa, a los personajes y a los items equipados
    for _, v in pairs(Workspace:GetDescendants()) do
        antiLagOptimize(v)
    end

    -- Aplicar a las herramientas que están GUARDADAS en las mochilas (para que no den lag al equiparse)
    for _, player in pairs(Players:GetPlayers()) do
        local bp = player:FindFirstChild("Backpack")
        if bp then
            for _, v in pairs(bp:GetDescendants()) do
                antiLagOptimize(v)
            end
        end
    end
end

local function startAntiLag()
    if antiLagEnabled then return end
    antiLagEnabled = true
    antiLagApplyAll()
    -- Vigilar en tiempo real cuando alguien se equipa un item, respawnea o lanza algo
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
-- // LÓGICA: DESYNC (CON TU INSTA-RESET EXACTO)
-- ============================================================
local desyncActive       = false
local desyncMode         = nil   
local desyncDebounce     = false
local isIgnoringTeleport = false

local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local desyncPCHookActive = false
local desyncPCHookInitialized = false

local desyncCharConn = nil

RunService.Heartbeat:Connect(function()
    if Players.RespawnTime ~= 0 then Players.RespawnTime = 0 end
end)

-- 2. FUNCIÓN PARA CORTAR/DEVOLVER INTERNET (PC Y MÓVIL)
local function toggleRaknetDesync(state)
    if isMobile then
        pcall(function() raknet.desync(state) end)
    else
        desyncPCHookActive = state
        if state and not desyncPCHookInitialized then
            if typeof(raknet) == "table" and raknet.add_send_hook then
                desyncPCHookInitialized = true
                pcall(function()
                    raknet.add_send_hook(function(packet)
                        if desyncPCHookActive and packet.PacketId == 0x1B then
                            local data = packet.AsBuffer
                            buffer.writeu32(data, 1, 0xFFFFFFFF)
                            packet:SetData(data)
                        end
                    end)
                end)
            else
                KYNNotify("Error", "Tu ejecutor de PC no soporta Raknet", "❌", THEME.Red, 3)
                desyncPCHookActive = false
            end
        end
    end
end

local function executeDesyncReset()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or not hrp or hum.Health <= 0 then return end

    isForcingReset = true 
    
    local Camera = workspace.CurrentCamera
    Camera.CameraSubject = nil

    if desyncCharConn then 
        desyncCharConn:Disconnect() 
    end

    desyncCharConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
        desyncCharConn:Disconnect()
        Camera.CameraSubject = nil
        task.defer(function()
            local newHum = newChar:WaitForChild("Humanoid", 0.5)
            if newHum then
                Camera.CameraSubject = newHum
            end
        end)
    end)

    -- Teletransporte fuera del mapa (Igual que en tu script)
    hrp.CFrame = CFrame.new(50000, 100000, 50000)

    Players.RespawnTime = 0
    hum.Health = 0
    hum:ChangeState(Enum.HumanoidStateType.Dead)
    char:BreakJoints()
    
    task.wait(0.03)
    pcall(function()
        LocalPlayer:LoadCharacter()
    end)

    task.delay(2, function() isForcingReset = false end)
end

-- ===========================
-- CLONER LOGIC
-- ===========================
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
            local distance = (currentPos - lastPlayerPos).Magnitude
            local threshold = math.max(1.0, (realHRP.AssemblyLinearVelocity.Magnitude / 45) + 0.2)
            
            if distance > threshold then
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

-- ===========================
-- ACTIVACIÓN / DESACTIVACIÓN
-- ===========================
local function activateDesync(mode)
    if desyncDebounce then return end
    desyncDebounce = true
    desyncActive   = true
    desyncMode     = mode

    -- 1. CORTAR INTERNET PRIMERO
    toggleRaknetDesync(true)

    local char = LocalPlayer.Character
    if char then startLagbackDetector(char) end

    if mode == "Respawn" then
        KYNNotify("Desync Respawn", "Ejecutando respawn desync...", "⚡", THEME.Primary)
        isIgnoringTeleport = true
        -- 2. EJECUTAR TU INSTA RESET EXACTO
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
    
    -- 1. DEVOLVER INTERNET
    toggleRaknetDesync(false)
    stopLagbackDetector()

    if desyncMode == "Respawn" then
        -- YA NO LLAMAMOS A executeDesyncReset() AQUÍ. ASÍ NO MUERES.
        KYNNotify("Desync OFF", "Respawn desync desactivado.", "🔴", THEME.Red, 2)
        isIgnoringTeleport = true
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
-- // FLOAT (PLATFORM-BASED, CUSTOM KEYBIND)
-- ============================================================
local floatBtnFrame   = nil
local floating        = false
local floatPlatform   = nil
local floatLoopThread = nil

local floatKeybind = kynConfig["floatKeybind"] or "F"

local function enableFloat()
    if floatPlatform then floatPlatform:Destroy() end
    floatPlatform = Instance.new("Part")
    floatPlatform.Name         = "KYN_FloatPlat"
    floatPlatform.Size         = Vector3.new(6, 1, 6)
    floatPlatform.Anchored     = true
    floatPlatform.CanCollide   = true
    floatPlatform.Transparency = 1
    floatPlatform.Parent       = Workspace

    if floatLoopThread then task.cancel(floatLoopThread) end
    floatLoopThread = task.spawn(function()
        while floating and floatPlatform do
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                floatPlatform.CFrame = hrp.CFrame - Vector3.new(0, 3, 0)
            end
            task.wait(0.05)
        end
    end)
end

local function disableFloat()
    if floatPlatform then floatPlatform:Destroy(); floatPlatform = nil end
    if floatLoopThread then task.cancel(floatLoopThread); floatLoopThread = nil end
end

local function doFloatToggle()
    floating = not floating
    local fBtn = floatBtnFrame and floatBtnFrame:FindFirstChildOfClass("TextButton")

    if floating then
        if fBtn then fBtn.Text = "Float ☁"; fBtn.TextColor3 = THEME.Green end
        enableFloat()
    else
        if fBtn then fBtn.Text = "Float"; fBtn.TextColor3 = THEME.Primary end
        disableFloat()
    end
end

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

            -- Drag con guardado de posición
            MakeDraggable(floatBtnFrame, fBtn, "pos_floatBtn")

            fBtn.Activated:Connect(doFloatToggle)
        end
        floatBtnFrame.Visible = true
    else
        if floatBtnFrame then floatBtnFrame.Visible = false end
        floating = false
        disableFloat()
        if floatBtnFrame then
            local fBtn = floatBtnFrame:FindFirstChildOfClass("TextButton")
            if fBtn then
                fBtn.Text       = "Float"
                fBtn.TextColor3 = THEME.Primary
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if floating then
        task.wait(0.5)
        enableFloat()
    end
end)

-- ============================================================
-- // STEAL SPEED
-- ============================================================
local ssEnabled   = false
local stealSpeed  = 25
local SS_MIN      = 5
local SS_MAX      = 100
local ssGui       = nil
local ssHeartbeat = nil

local function startStealSpeed()
    ssEnabled = true
    if ssHeartbeat then ssHeartbeat:Disconnect() end
    ssHeartbeat = RunService.Heartbeat:Connect(function()
        if not ssEnabled then return end
        if LocalPlayer:GetAttribute("Stealing") ~= true then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp and hum.Health > 0 then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    md.X * stealSpeed,
                    hrp.AssemblyLinearVelocity.Y,
                    md.Z * stealSpeed
                )
            end
        end
    end)

    -- Crear GUI si no existe
    if ssGui and ssGui.Parent then return end

ssGui = Instance.new("ScreenGui")
    ssGui.Name            = "KYN_StealSpeedGUI"
    ssGui.ResetOnSpawn    = false
    ssGui.IgnoreGuiInset  = true
    ssGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    
    -- SOLUCIÓN PC: Asignar el Parent (ESTO SE HABÍA BORRADO)
    if not pcall(function() ssGui.Parent = CoreGui end) then
        ssGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Detectar botones creados en Steal Speed
    ssGui.DescendantAdded:Connect(attachSoundToButton)
    for _, obj in pairs(ssGui:GetDescendants()) do attachSoundToButton(obj) end

    local ssFrame = Instance.new("Frame", ssGui)
    ssFrame.Size              = UDim2.new(0, 260, 0, 175)
    ssFrame.Position          = UDim2.new(0.5, -130, 0.5, 100)
    ssFrame.BackgroundColor3  = THEME.BG
    ssFrame.BorderSizePixel   = 0
    ssFrame.Active            = true
    corner(ssFrame, 12)

    local ssStroke = stroke(ssFrame, Color3.new(1,1,1), 3)
    local ssGrad   = Instance.new("UIGradient", ssStroke)
    ssGrad.Color   = ColorSequence.new{
        ColorSequenceKeypoint.new(0,    THEME.Secondary),
        ColorSequenceKeypoint.new(0.25, THEME.DarkBlue),
        ColorSequenceKeypoint.new(0.5,  THEME.Primary),
        ColorSequenceKeypoint.new(0.75, THEME.DarkBlue),
        ColorSequenceKeypoint.new(1,    THEME.Secondary),
    }
    task.spawn(function()
        while ssGui and ssGui.Parent do
            ssGrad.Rotation = (ssGrad.Rotation + 2) % 360
            RunService.RenderStepped:Wait()
        end
    end)

    -- Header
    local ssHeader = Instance.new("Frame", ssFrame)
    ssHeader.Size             = UDim2.new(1, 0, 0, 38)
    ssHeader.BackgroundColor3 = THEME.Frame
    ssHeader.BorderSizePixel  = 0
    ssHeader.Active           = true
    corner(ssHeader, 12)
    local ssHeaderPatch = Instance.new("Frame", ssHeader)
    ssHeaderPatch.Size            = UDim2.new(1, 0, 0, 10)
    ssHeaderPatch.Position        = UDim2.new(0, 0, 1, -10)
    ssHeaderPatch.BackgroundColor3 = THEME.Frame
    ssHeaderPatch.BorderSizePixel = 0

    local ssTitle = Instance.new("TextLabel", ssHeader)
    ssTitle.Size                = UDim2.new(1, -12, 1, 0)
    ssTitle.Position            = UDim2.new(0, 12, 0, 0)
    ssTitle.BackgroundTransparency = 1
    ssTitle.Text                = "⚡ Steal Speed"
    ssTitle.Font                = Enum.Font.GothamBlack
    ssTitle.TextSize            = 14
    ssTitle.TextColor3          = THEME.Primary
    ssTitle.TextXAlignment      = Enum.TextXAlignment.Left

    MakeDraggable(ssFrame, ssHeader, "pos_stealSpeed")

    -- Estado
    local ssStatus = Instance.new("TextLabel", ssFrame)
    ssStatus.Size               = UDim2.new(1, -16, 0, 18)
    ssStatus.Position           = UDim2.new(0, 8, 0, 44)
    ssStatus.BackgroundTransparency = 1
    ssStatus.Text               = "● No estás robando"
    ssStatus.TextColor3         = THEME.Dim
    ssStatus.Font               = Enum.Font.GothamMedium
    ssStatus.TextSize           = 11
    ssStatus.TextXAlignment     = Enum.TextXAlignment.Left
    pcall(function()
        LocalPlayer:GetAttributeChangedSignal("Stealing"):Connect(function()
            if LocalPlayer:GetAttribute("Stealing") == true then
                ssStatus.Text      = "● Speed Activo"
                ssStatus.TextColor3 = THEME.Green
            else
                ssStatus.Text      = "● No estás robando"
                ssStatus.TextColor3 = THEME.Dim
            end
        end)
    end)

    -- Label velocidad
    local ssSpeedLbl = Instance.new("TextLabel", ssFrame)
    ssSpeedLbl.Size               = UDim2.new(0, 160, 0, 18)
    ssSpeedLbl.Position           = UDim2.new(0, 8, 0, 66)
    ssSpeedLbl.BackgroundTransparency = 1
    ssSpeedLbl.Text               = "Velocidad: " .. stealSpeed
    ssSpeedLbl.TextColor3         = THEME.Neon1
    ssSpeedLbl.Font               = Enum.Font.GothamBold
    ssSpeedLbl.TextSize           = 12
    ssSpeedLbl.TextXAlignment     = Enum.TextXAlignment.Left

    -- Campo de texto
    local ssInput = Instance.new("TextBox", ssFrame)
    ssInput.Size                = UDim2.new(0, 52, 0, 20)
    ssInput.Position            = UDim2.new(1, -60, 0, 64)
    ssInput.BackgroundColor3    = THEME.DarkBlue
    ssInput.Text                = tostring(stealSpeed)
    ssInput.TextColor3          = THEME.Primary
    ssInput.Font                = Enum.Font.GothamBold
    ssInput.TextSize            = 12
    ssInput.PlaceholderText     = "val"
    ssInput.ClearTextOnFocus    = false
    corner(ssInput, 6)
    stroke(ssInput, THEME.Primary, 1.2)

    -- Slider track
    local ssBg = Instance.new("Frame", ssFrame)
    ssBg.Size             = UDim2.new(1, -16, 0, 6)
    ssBg.Position         = UDim2.new(0, 8, 0, 94)
    ssBg.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
    ssBg.BorderSizePixel  = 0
    corner(ssBg, 50)

    local ssFill = Instance.new("Frame", ssBg)
    local initPct = (stealSpeed - SS_MIN) / (SS_MAX - SS_MIN)
    ssFill.Size             = UDim2.new(initPct, 0, 1, 0)
    ssFill.BackgroundColor3 = THEME.Primary
    ssFill.BorderSizePixel  = 0
    corner(ssFill, 50)

    local ssKnob = Instance.new("Frame", ssBg)
    ssKnob.Size        = UDim2.new(0, 14, 0, 14)
    ssKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    ssKnob.Position    = UDim2.new(initPct, 0, 0.5, 0)
    ssKnob.BackgroundColor3 = Color3.new(1,1,1)
    ssKnob.BorderSizePixel  = 0
    corner(ssKnob, 50)

    local function applySpeed(v)
        stealSpeed          = math.clamp(math.floor(v), SS_MIN, SS_MAX)
        local pct           = (stealSpeed - SS_MIN) / (SS_MAX - SS_MIN)
        ssFill.Size         = UDim2.new(pct, 0, 1, 0)
        ssKnob.Position     = UDim2.new(pct, 0, 0.5, 0)
        ssSpeedLbl.Text     = "Velocidad: " .. stealSpeed
        ssInput.Text        = tostring(stealSpeed)
        -- Guardar en config
        kynConfig["stealSpeed"] = stealSpeed
        saveKYNConfig()
    end

    -- Restaurar valor guardado
    if kynConfig["stealSpeed"] then
        applySpeed(kynConfig["stealSpeed"])
    end

    -- Slider drag
    local ssDragging = false
    local function updateSlider(input)
        local pos = math.clamp(input.Position.X - ssBg.AbsolutePosition.X, 0, ssBg.AbsoluteSize.X)
        applySpeed(SS_MIN + (pos / ssBg.AbsoluteSize.X) * (SS_MAX - SS_MIN))
    end
    ssBg.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            ssDragging = true
            updateSlider(inp)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            ssDragging = false
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if ssDragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(inp)
        end
    end)

    -- TextBox confirmar con Enter
    ssInput.FocusLost:Connect(function()
        local n = tonumber(ssInput.Text)
        if n then applySpeed(n) else ssInput.Text = tostring(stealSpeed) end
    end)

    -- Info min/max
    local ssRange = Instance.new("TextLabel", ssFrame)
    ssRange.Size               = UDim2.new(1, -16, 0, 14)
    ssRange.Position           = UDim2.new(0, 8, 0, 104)
    ssRange.BackgroundTransparency = 1
    ssRange.Text               = SS_MIN .. "  ←  rango  →  " .. SS_MAX
    ssRange.TextColor3         = THEME.Dim
    ssRange.Font               = Enum.Font.Gotham
    ssRange.TextSize           = 10
    ssRange.TextXAlignment     = Enum.TextXAlignment.Center

    -- Línea separadora
    local ssDivider = Instance.new("Frame", ssFrame)
    ssDivider.Size            = UDim2.new(0.9, 0, 0, 1)
    ssDivider.Position        = UDim2.new(0.05, 0, 0, 124)
    ssDivider.BackgroundColor3 = THEME.Primary
    ssDivider.BackgroundTransparency = 0.6
    ssDivider.BorderSizePixel = 0

    -- Toggle ON/OFF interno de la GUI
    local ssToggle = Instance.new("TextButton", ssFrame)
    ssToggle.Size              = UDim2.new(1, -16, 0, 32)
    ssToggle.Position          = UDim2.new(0, 8, 0, 132)
    ssToggle.BackgroundColor3  = THEME.Green
    ssToggle.Text              = "ACTIVADO"
    ssToggle.TextColor3        = THEME.BG
    ssToggle.Font              = Enum.Font.GothamBold
    ssToggle.TextSize          = 13
    ssToggle.AutoButtonColor   = false
    corner(ssToggle, 8)

    ssToggle.Activated:Connect(function()
        ssEnabled = not ssEnabled
        if ssEnabled then
            tween(ssToggle, {BackgroundColor3 = THEME.Green}, 0.2)
            ssToggle.Text      = "ACTIVADO"
            ssToggle.TextColor3 = THEME.BG
        else
            tween(ssToggle, {BackgroundColor3 = THEME.Red}, 0.2)
            ssToggle.Text      = "DESACTIVADO"
            ssToggle.TextColor3 = Color3.new(1,1,1)
        end
    end)
end

local function stopStealSpeed()
    ssEnabled = false
    if ssHeartbeat then ssHeartbeat:Disconnect(); ssHeartbeat = nil end
    if ssGui       then ssGui:Destroy();          ssGui       = nil end
end

-- ============================================================
-- // BOTONES DE DESYNC (IGUALES PARA PC Y MÓVIL)
-- ============================================================
local ctrlDesyncRespawn = _G.KYNAddToggle("Main", {
    Name          = "Desync Respawn",
    Callback      = function(s)
        if s then
            activateDesync("Respawn")
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

do
    local floatTab = tabs["Main"]
    if floatTab then
        local kbFrame = Instance.new("Frame", floatTab)
        kbFrame.Size = UDim2.new(1, 0, 0, 28)
        kbFrame.BackgroundColor3 = THEME.Frame
        kbFrame.BackgroundTransparency = 0.5
        kbFrame.BorderSizePixel = 0
        corner(kbFrame, 6)

        local kbLabel = Instance.new("TextLabel", kbFrame)
        kbLabel.Size = UDim2.new(0.7, 0, 1, 0)
        kbLabel.Position = UDim2.new(0, 8, 0, 0)
        kbLabel.BackgroundTransparency = 1
        kbLabel.Text = "   Float Keybind"
        kbLabel.TextColor3 = THEME.Dim
        kbLabel.Font = Enum.Font.GothamSemibold
        kbLabel.TextSize = 12
        kbLabel.TextXAlignment = Enum.TextXAlignment.Left

        local kbBtn = Instance.new("TextButton", kbFrame)
        kbBtn.Size = UDim2.new(0, 52, 0, 20)
        kbBtn.Position = UDim2.new(1, -60, 0.5, -10)
        kbBtn.BackgroundColor3 = THEME.DarkBlue
        kbBtn.Text = floatKeybind
        kbBtn.TextColor3 = THEME.Primary
        kbBtn.Font = Enum.Font.GothamBold
        kbBtn.TextSize = 12
        kbBtn.AutoButtonColor = false
        corner(kbBtn, 6)
        stroke(kbBtn, THEME.Primary, 1.2)

local listening = false
        
        kbBtn.Activated:Connect(function()
            if listening then return end
            listening = true
            kbBtn.Text = "..."
            kbBtn.TextColor3 = THEME.Neon1

            local conn
            conn = UIS.InputBegan:Connect(function(input, gp)
                if gp then return end
                -- Verificar que sea del teclado (Igual a tu ejemplo)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local keyName = input.KeyCode.Name
                    if keyName and keyName ~= "Unknown" then
                        floatKeybind = keyName
                        kynConfig["floatKeybind"] = keyName
                        saveKYNConfig()
                        kbBtn.Text = keyName
                        kbBtn.TextColor3 = THEME.Primary
                        KYNNotify("Float Keybind", "Tecla asignada: " .. keyName, "⌨", THEME.Primary, 1.5)
                        listening = false
                        conn:Disconnect()
                    end
                end
            end)

            task.delay(5, function()
                if listening then
                    listening = false
                    if conn then conn:Disconnect() end
                    kbBtn.Text = floatKeybind
                    kbBtn.TextColor3 = THEME.Primary
                end
            end)
        end)

        -- EVENTO GLOBAL PARA ACTIVAR EL FLOAT (Igual a tu código de ejemplo)
        UIS.InputBegan:Connect(function(input, gp)
            -- Si está escribiendo en el chat (gp) o está configurando la tecla (listening), ignorar
            if gp or listening then return end
            
            -- Obtener la tecla guardada sin que crashee el script
            local success, targetKey = pcall(function() return Enum.KeyCode[floatKeybind] end)
            
            -- Si presionas la tecla correcta, activa el float
            if success and input.KeyCode == targetKey then
                if not floatBtnFrame or not floatBtnFrame.Visible then
                    toggleFloatButton(true)
                end
                doFloatToggle()
            end
        end)
    end
end

_G.KYNAddToggle("Main", {Name = "Steal Speed", Callback = function(s)
    if s then startStealSpeed() else stopStealSpeed() end
    KYNNotify("Steal Speed", s and "GUI abierta ✔" or "Desactivado", "💨", THEME.Green, 1.8)
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
_G.KYNAddToggle("Visual", {Name = "Line to Base", Callback = function(s)
    if s then startLineToBase() else stopLineToBase() end
    KYNNotify("Line to Base", s and "Rayo a la base activado ✔" or "Desactivado", "📍", THEME.Primary, 1.8)
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
