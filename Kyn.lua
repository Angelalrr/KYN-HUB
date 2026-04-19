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
