--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

-- FB
if not mouse1click then mouse1click = function() return false end end
if not isrbxactive then isrbxactive = function() return true end end
if not iswindowactive then iswindowactive = function() return true end end
if not mouse1press then mouse1press = function() end end
if not mouse1release then mouse1release = function() end end

local isfile = isfile or function(file) local ok,res = pcall(readfile,file) return ok and res ~= nil and res ~= '' end
local writefile = writefile or function(file,data) end
local isfolder = isfolder or function(folder) return false end
local makefolder = makefolder or function(folder) end
local readfile = readfile or function(file) return '' end
local getcustomaudio = getcustomaudio or function(path) return nil end

local run = function(func, issue)
    if issue then return end
    pcall(func)
end

local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local workspaceService = cloneref(game:GetService('Workspace'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local guiService = cloneref(game:GetService('GuiService'))
local tweenService = game:GetService('TweenService')

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo

local function notif(...) return vape:CreateNotification(...) end

if identifyexecutor then
    local execInfo = {identifyexecutor()}
    local execName = execInfo[1] or "Unknown"
    local execVersion = execInfo[2] or "Unknown"
    notif('Rawr.xyz', 'Executor: ' .. execName .. ' | v' .. execVersion, 5, 'info')
    local allowed = {Madium = true, Velocity = true, Sirhurt = true, Volt = true, LX63 = true}
    if not allowed[execName] then
        notif('Rawr.xyz', 'Your Executor is too bad to use all features :(', 6, 'alert')
    end
end

local function safeCall(desc, func)
    local ok, err = pcall(func)
    if not ok then notif('Rawr.xyz', desc .. ' failed: ' .. tostring(err), 3, 'alert') end
end

local function canClick()
    local mousepos = (inputService:GetMouseLocation() - guiService:GetGuiInset())
    for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then return false end
    end
    for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then return false end
    end
    local scaledGui = vape.gui.ScaledGui
    local clickGuiVisible = scaledGui and scaledGui.ClickGui and scaledGui.ClickGui.Visible
    return not clickGuiVisible and not inputService:GetFocusedTextBox()
end

for _, v in {'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'} do vape:Remove(v) end

local function chid_to_id(chid)
    return string.byte(chid or string.char(0))
end
local function isEnemy(player)
    if not player or player == lplr then return false end
    local myEnv = lplr:GetAttribute("EnvironmentID")
    local myTeam = lplr:GetAttribute("TeamID")
    if not myEnv or not myTeam then return true end
    local targetEnv = player:GetAttribute("EnvironmentID")
    local targetTeam = player:GetAttribute("TeamID")
    if not targetEnv or not targetTeam then return false end
    if chid_to_id(myEnv) ~= chid_to_id(targetEnv) then return false end
    if chid_to_id(myTeam) == chid_to_id(targetTeam) then return false end
    return true
end

local function getClosestPlayerToMouse()
    local closest = nil
    local shortest = math.huge
    local mousePos = inputService:GetMouseLocation()
    for _, player in ipairs(playersService:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character:FindFirstChild("Head") and isEnemy(player) then
            local head = player.Character.Head
            local screenPos, onScreen = gameCamera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist < shortest then
                    closest = player
                    shortest = dist
                end
            end
        end
    end
    return closest
end

local function isLobbyVisible()
    local mainGui = lplr.PlayerGui:FindFirstChild("MainGui")
    if mainGui then
        local mainFrame = mainGui:FindFirstChild("MainFrame")
        if mainFrame then
            local lobby = mainFrame:FindFirstChild("Lobby")
            if lobby then
                local currency = lobby:FindFirstChild("Currency")
                return currency and currency.Visible == true
            end
        end
    end
    return false
end

local targetPlayer = nil
local isLeftMouseDown, isRightMouseDown = false, false
local autoClickConnection = nil
local cameraLockConnection = nil
local silentAimEnabled = false
local lockChance = 100
local clickInterval = 0.10
local aimPartSA = "Head"
local smoothnessSA = 1
local wallCheckSA = true
local ShowTargetSA = nil
local CircleObject = nil
local CircleColor, CircleTransparency, CircleFilled
local lastRightClick = 0

local function lockCameraToHead()
    if not targetPlayer or not targetPlayer.Character then return end
    local part = targetPlayer.Character:FindFirstChild(aimPartSA == "Head" and "Head" or "HumanoidRootPart")
    if not part then return end
    if wallCheckSA then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        rayParams.FilterDescendantsInstances = {lplr.Character, targetPlayer.Character}
        local origin = gameCamera.CFrame.Position
        local direction = (part.Position - origin) * 0.999
        if workspace:Raycast(origin, direction, rayParams) then return end
    end
    local headPosition = gameCamera:WorldToViewportPoint(part.Position)
    if headPosition and headPosition.Z > 0 then
        local goalCF = CFrame.new(gameCamera.CFrame.Position, part.Position)
        if smoothnessSA >= 0.99 then
            gameCamera.CFrame = goalCF
        else
            gameCamera.CFrame = gameCamera.CFrame:Lerp(goalCF, smoothnessSA)
        end
        if ShowTargetSA and ShowTargetSA.Enabled and targetinfo then
            targetinfo.Targets[targetPlayer] = tick() + 1
        end
    end
end

local function startAutoClick()
    if autoClickConnection then autoClickConnection:Disconnect() end
    autoClickConnection = runService.Heartbeat:Connect(function()
        if (isLeftMouseDown or isRightMouseDown) and silentAimEnabled then
            if not isLobbyVisible() and canClick() and (tick() - lastRightClick) >= clickInterval then
                mouse1click()
                lastRightClick = tick()
            end
        else
            if autoClickConnection then autoClickConnection:Disconnect(); autoClickConnection = nil end
        end
    end)
end

inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not isLeftMouseDown then
            isLeftMouseDown = true
            if silentAimEnabled then startAutoClick() end
        end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isRightMouseDown then
            isRightMouseDown = true
            if silentAimEnabled then startAutoClick() end
        end
    end
end)

inputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        isLeftMouseDown = false
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightMouseDown = false
    end
end)

run(function()
    local SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            silentAimEnabled = callback
            if callback then
                cameraLockConnection = runService.Heartbeat:Connect(function()
                    if not isLobbyVisible() then
                        targetPlayer = getClosestPlayerToMouse()
                        if targetPlayer and math.random(100) <= lockChance then
                            lockCameraToHead()
                        end
                    end
                end)
            else
                if cameraLockConnection then cameraLockConnection:Disconnect(); cameraLockConnection = nil end
                if autoClickConnection then autoClickConnection:Disconnect(); autoClickConnection = nil end
                targetPlayer = nil
            end
        end,
        Tooltip = 'Camera lock + auto‑click. Hold Mouse1/Mouse2.'
    })
    SilentAim:CreateDropdown({Name='Aim Part', List={'Head','Body','Random'}, Default='Head', Function=function(v) aimPartSA=v end, Tooltip='Part to lock onto'})
    SilentAim:CreateSlider({Name='Smoothness', Min=1, Max=100, Default=100, Function=function(v) smoothnessSA=v/100 end, Suffix='%', Tooltip='Lock smoothness'})
    SilentAim:CreateToggle({Name='Wall Check', Default=true, Function=function(v) wallCheckSA=v end, Tooltip='Only lock when visible'})
    SilentAim:CreateSlider({Name='Hit Chance', Min=0, Max=100, Default=100, Function=function(v) lockChance=v end, Suffix='%', Tooltip='Chance to lock per check'})
    SilentAim:CreateSlider({Name='Click Interval', Min=1, Max=50, Default=10, Function=function(v) clickInterval=v/100 end, Suffix='s', Tooltip='Time between auto‑clicks'})
    ShowTargetSA = SilentAim:CreateToggle({Name='Show Target Info', Default=true})
    CircleColor = SilentAim:CreateColorSlider({Name='Circle Color', Darker=true, Visible=false, Function=function(h,s,v) if CircleObject then CircleObject.Color=Color3.fromHSV(h,s,v) end end})
    CircleTransparency = SilentAim:CreateSlider({Name='Transparency', Min=0, Max=1, Decimal=10, Default=0.5, Darker=true, Visible=false, Function=function(v) if CircleObject then CircleObject.Transparency=1-v end end})
    CircleFilled = SilentAim:CreateToggle({Name='Circle Filled', Darker=true, Visible=false, Function=function(c) if CircleObject then CircleObject.Filled=c end end})
    SilentAim:CreateToggle({Name='Range Circle', Function=function(c)
        if c then
            CircleObject = Drawing.new('Circle')
            CircleObject.Filled = CircleFilled and CircleFilled.Enabled
            CircleObject.Color = Color3.fromHSV(CircleColor and CircleColor.Hue or 0, 1, 1)
            CircleObject.Position = vape.gui.AbsoluteSize/2
            CircleObject.Radius = 150; CircleObject.NumSides = 100
            CircleObject.Transparency = 1-(CircleTransparency and CircleTransparency.Value or 0.5)
            CircleObject.Visible = silentAimEnabled
        else
            pcall(function() CircleObject:Remove() end); CircleObject = nil
        end
        if CircleColor then CircleColor.Object.Visible=c end
        if CircleTransparency then CircleTransparency.Object.Visible=c end
        if CircleFilled then CircleFilled.Object.Visible=c end
    end})
end)

local crosshairEnabled = false
local crosshairColor = Color3.fromRGB(128,128,128)
local crosshairStyle = "Cross"
local crosshairSpin = true
local crosshairLength = 10
local crosshairRadius = 11
local crosshairWidth = 1.5
local dotSize = 0
local outlineEnabled = false
local outlineColor = Color3.new(0,0,0)
local outlineThickness = 0.5
local drawings = { lines = {}, texts = {}, dot = nil, outlines = {} }
local crosshairRenderConnection
local text_x = 0
local lastSpinAngle = 0
local drawingsCreated = false

local function solve(angle, radius)
    local rad = math.rad(angle)
    return Vector2.new(math.sin(rad)*radius, math.cos(rad)*radius)
end
local function createDrawings()
    if drawingsCreated then return end
    for i = 1, 8 do drawings.lines[i] = Drawing.new('Line') end
    for i = 1, 4 do drawings.outlines[i] = Drawing.new('Line') end
    drawings.dot = Drawing.new('Circle')
    drawings.texts[1] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=Color3.new(1,1,1)})
    drawings.texts[2] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=crosshairColor})
    drawingsCreated = true
end
local function updateCrosshair()
    local pos = inputService:GetMouseLocation()
    if drawings.texts[1] then drawings.texts[1].Visible = crosshairEnabled end
    if drawings.texts[2] then drawings.texts[2].Visible = crosshairEnabled end
    if crosshairEnabled then
        if text_x == 0 and drawings.texts[1] then text_x = drawings.texts[1].TextBounds.X + drawings.texts[2].TextBounds.X end
        if drawings.texts[1] then drawings.texts[1].Position = pos + Vector2.new(-text_x/2, crosshairRadius+crosshairLength+15) end
        if drawings.texts[2] then
            drawings.texts[2].Position = (drawings.texts[1] and drawings.texts[1].Position or Vector2.new()) + Vector2.new(drawings.texts[1] and drawings.texts[1].TextBounds.X or 0, 0)
            drawings.texts[2].Color = crosshairColor
        end
        if crosshairSpin then lastSpinAngle = (tick()*360) % 360 end
        for i = 1, 8 do if drawings.lines[i] then drawings.lines[i].Visible = false end end
        for i = 1, 4 do if drawings.outlines[i] then drawings.outlines[i].Visible = false end end
        if drawings.dot then drawings.dot.Visible = false end
        if crosshairStyle == "Cross" then
            for idx = 1, 4 do
                local inline = drawings.lines[idx+4]; local outline = drawings.outlines[idx]
                local angle = (idx-1)*90 + lastSpinAngle; local dir = solve(angle,1)
                local fromPos = pos + dir * crosshairRadius; local toPos = pos + dir * (crosshairRadius + crosshairLength)
                inline.Visible = true; inline.Color = crosshairColor; inline.From = fromPos; inline.To = toPos; inline.Thickness = crosshairWidth
                if outlineEnabled then
                    outline.Visible = true; outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2; outline.Color = outlineColor
                end
            end
        elseif crosshairStyle == "Dot" then
            drawings.dot.Visible = true; drawings.dot.Position = pos; drawings.dot.Radius = dotSize; drawings.dot.Filled = true
            drawings.dot.Color = crosshairColor; drawings.dot.Transparency = 0
        elseif crosshairStyle == "Diagonal" then
            local angles = {45, 135}
            for i = 1, 2 do
                local inline = drawings.lines[i]; local outline = drawings.outlines[i]
                local angle = angles[i] + lastSpinAngle; local dir = solve(angle,1)
                inline.Visible = true; inline.Color = crosshairColor; inline.From = pos + dir * crosshairRadius; inline.To = pos + dir * (crosshairRadius + crosshairLength)
                inline.Thickness = crosshairWidth
                if outlineEnabled then
                    outline.Visible = true; outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2; outline.Color = outlineColor
                end
            end
        end
    else
        for i = 1, 8 do if drawings.lines[i] then drawings.lines[i].Visible = false end end
        for i = 1, 4 do if drawings.outlines[i] then drawings.outlines[i].Visible = false end end
        if drawings.dot then drawings.dot.Visible = false end
    end
end

local CrosshairModule = vape.Categories.Utility:CreateModule({
    Name = "Crosshair",
    Function = function(callback)
        crosshairEnabled = callback
        if callback then
            if not drawingsCreated then createDrawings() end
            crosshairRenderConnection = runService.RenderStepped:Connect(updateCrosshair)
        else
            if crosshairRenderConnection then crosshairRenderConnection:Disconnect(); crosshairRenderConnection = nil end
            for i = 1, 8 do if drawings.lines[i] then drawings.lines[i].Visible = false end end
            for i = 1, 4 do if drawings.outlines[i] then drawings.outlines[i].Visible = false end end
            if drawings.dot then drawings.dot.Visible = false end
        end
    end
})
CrosshairModule:CreateDropdown({Name="Style", List={"Cross","Dot","Diagonal"}, Default="Cross", Function=function(v) crosshairStyle=v end})
CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px"})
CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})

run(function()
    local assetSounds = {
        {name="Bameware", id="rbxassetid://3124331820"},{name="Bell", id="rbxassetid://6534947240"},
        {name="Bubble", id="rbxassetid://6534947588"},{name="Pick", id="rbxassetid://1347140027"},
        {name="Pop", id="rbxassetid://198598793"},{name="Rust", id="rbxassetid://1255040462"},
        {name="Sans", id="rbxassetid://3188795283"},{name="Fart", id="rbxassetid://130833677"},
        {name="Big", id="rbxassetid://5332005053"},{name="Vine", id="rbxassetid://5332680810"},
        {name="Bruh", id="rbxassetid://4578740568"},{name="Skeet", id="rbxassetid://5633695679"},
        {name="Neverlose", id="rbxassetid://6534948092"},{name="Fatality", id="rbxassetid://6534947869"},
        {name="Bonk", id="rbxassetid://5766898159"},{name="Minecraft", id="rbxassetid://4018616850"},
    }
    local soundNames, soundMap = {}, {}
    for _, s in ipairs(assetSounds) do table.insert(soundNames, s.name); soundMap[s.name] = s.id end
    local hitsoundEnabled = false
    local currentSoundId = soundMap["Bell"]
    local hitConnection = nil
    local function applySoundReplacement()
        if hitConnection then hitConnection:Disconnect() end
        if not hitsoundEnabled then return end
        local viewModel = nil
        pcall(function()
            viewModel = lplr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:WaitForChild("ClientViewModel", 5)
        end)
        if viewModel then
            hitConnection = viewModel.ChildAdded:Connect(function(v)
                if v:IsA("Sound") and v.SoundId ~= currentSoundId then v.SoundId = currentSoundId; v.Pitch = 1; v.Volume = 1 end
            end)
        end
    end
    local HitsoundModule = vape.Categories.Utility:CreateModule({
        Name = "Hitsound",
        Function = function(callback)
            hitsoundEnabled = callback; applySoundReplacement()
            if not callback and hitConnection then hitConnection:Disconnect(); hitConnection = nil end
        end
    })
    HitsoundModule:CreateToggle({Name="Hitsound", Default=false, Function=function(c) hitsoundEnabled=c; applySoundReplacement() end})
    HitsoundModule:CreateDropdown({Name="Select Sound", List=soundNames, Function=function(val)
        currentSoundId = soundMap[val] or currentSoundId; applySoundReplacement()
        notif('Hitsound', 'Selected: '..val, 2, 'success')
    end})
end)

run(function()
    local Lighting = game:GetService("Lighting")
    local origBrightness, origClockTime, origFogEnd, origFogStart, origGlobalShadows, origOutdoorAmbient =
        Lighting.Brightness, Lighting.ClockTime, Lighting.FogEnd, Lighting.FogStart, Lighting.GlobalShadows, Lighting.OutdoorAmbient
    vape.Categories.World:CreateModule({
        Name = "Fullbright",
        Function = function(callback)
            if callback then
                Lighting.Brightness = 3; Lighting.ClockTime = 12; Lighting.FogEnd = 100000; Lighting.FogStart = 100000
                Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime; Lighting.FogEnd = origFogEnd
                Lighting.FogStart = origFogStart; Lighting.GlobalShadows = origGlobalShadows; Lighting.OutdoorAmbient = origOutdoorAmbient
            end
        end
    })
end)

run(function()
    local Lighting = game:GetService("Lighting")
    local origFogEnd, origFogStart = Lighting.FogEnd, Lighting.FogStart
    vape.Categories.World:CreateModule({
        Name = "No Fog",
        Function = function(callback)
            if callback then Lighting.FogEnd = 100000; Lighting.FogStart = 100000
            else Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart end
        end
    })
end)
                                                                                                        
run(function()
    local antiSmokeRunning = false
    local workerConn = nil

    local function handleSmoke(inst)
        if not inst or not inst.Parent then return end
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("ParticleEmitter") then
                d.Enabled = false
            elseif d:IsA("BasePart") then
                d.Transparency = 1
            elseif d:IsA("Decal") or d:IsA("Texture") then
                d.Transparency = 1
            end
        end
        task.defer(function()
            pcall(function()
                if inst and inst.Parent then
                    inst:Destroy()
                end
            end)
        end)
    end

    local function startAntiSmoke()
        if antiSmokeRunning then return end
        antiSmokeRunning = true

        if not workerConn then
            workerConn = workspace.DescendantAdded:Connect(function(child)
                if not antiSmokeRunning then return end
                if child.Name == "Smoke Grenade" then
                    handleSmoke(child)
                end
            end)
        end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v.Name == "Smoke Grenade" then
                handleSmoke(v)
            end
        end
    end

    local function stopAntiSmoke()
        antiSmokeRunning = false
    end

    local cleanupFunc
    cleanupFunc = function()
        if workerConn then
            workerConn:Disconnect()
            workerConn = nil
        end
        antiSmokeRunning = false
    end

    local AntiSmokeModule = vape.Categories.World:CreateModule({
        Name = "Anti-Smoke",
        Function = function(callback)
            if callback then
                startAntiSmoke()
            else
                stopAntiSmoke()
                cleanupFunc()
            end
        end,
        Tooltip = "Removes smoke grenades."
    })

    vape:Clean(cleanupFunc)
end)

run(function()
    local enabled = false
    local wsConn, guiConn = nil, nil
    local playerGui = lplr:FindFirstChild("PlayerGui")
    local lastShow = 0
    local SHOW_THROTTLE = 0.5

    local function showFlashLabel()
        local now = tick()
        if now - lastShow < SHOW_THROTTLE then return end
        lastShow = now
        pcall(function()
            if _G.RivalsTopLabel and _G.RivalsTopLabel.New then
                local lbl = _G.RivalsTopLabel.New("You are flashbanged currently", {TextSize = 14})
                task.delay(3.5, function()
                    if lbl then lbl:Destroy() end
                end)
            end
        end)
    end

    local function handleFlashInstance(inst)
        if not enabled or not inst then return end
        local now = tick()
        if now - lastShow < SHOW_THROTTLE then
            inst:Destroy()
            return
        end
        inst:Destroy()
        showFlashLabel()
    end

    local function startRemover()
        if wsConn then return end
        wsConn = workspace.ChildAdded:Connect(function(child)
            if child.Name == "FlashbangEffect" then handleFlashInstance(child) end
        end)
        if playerGui then
            guiConn = playerGui.ChildAdded:Connect(function(child)
                if child.Name:lower():find("flash") then handleFlashInstance(child) end
            end)
        end
        -- clean
        repeat
            local found = workspace:FindFirstChild("FlashbangEffect", true)
            if found then handleFlashInstance(found) end
        until not found
        if playerGui then
            for _, v in ipairs(playerGui:GetDescendants()) do
                if v.Name:lower():find("flash") then v:Destroy() end
            end
        end
    end

    local function stopRemover()
        if wsConn then wsConn:Disconnect(); wsConn = nil end
        if guiConn then guiConn:Disconnect(); guiConn = nil end
    end

    vape.Categories.World:CreateModule({
        Name = "Anti-Flashbang",
        Function = function(callback)
            enabled = callback
            if callback then
                startRemover()
            else
                stopRemover()
            end
        end,
        Tooltip = "its in the name"
    })

    vape:Clean(function()
        stopRemover()
    end)
end)

run(function()
    local katanaEnabled = false
    local heartbeatConn = nil
    local lastNotifTime = 0
    local NOTIF_COOLDOWN = 5

    local function showKatanaWarning(playerName)
        if tick() - lastNotifTime < NOTIF_COOLDOWN then return end
        lastNotifTime = tick()
        notif('Rawr.xyz', playerName .. ' is holding a Katana!', 5, 'alert')
    end

    local function findWeaponName(player)
        local viewModels = workspace:FindFirstChild("ViewModels")
        if viewModels then
            for _, model in ipairs(viewModels:GetChildren()) do
                if model:IsA("Model") then
                    local parts = string.split(model.Name, " - ")
                    if #parts >= 1 and parts[1] == player.Name then
                        if #parts >= 3 then return parts[3]
                        elseif #parts >= 2 then return parts[2]
                        else return parts[1] end
                    end
                end
            end
        end
        local char = player.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then return tool.Name end
        end
        return nil
    end

    local function detectKatana()
        if not katanaEnabled then return end
        local lpChar = lplr.Character
        local lpRoot = lpChar and (lpChar:FindFirstChild("HumanoidRootPart") or lpChar.PrimaryPart)
        if not lpRoot then return end

        for _, player in ipairs(playersService:GetPlayers()) do
            if player ~= lplr and isEnemy(player) then
                local weaponName = findWeaponName(player)
                if weaponName and string.find(string.lower(weaponName), "katana") then
                    local char = player.Character
                    if char then
                        local rootPart = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
                        if rootPart and (lpRoot.Position - rootPart.Position).Magnitude <= 150 then
                            local dirToUs = (lpRoot.Position - rootPart.Position).Unit
                            local forward = rootPart.CFrame.LookVector
                            local dot = forward:Dot(dirToUs)
                            if dot >= 0.3 then
                                showKatanaWarning(player.Name)
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    local KatanaModule = vape.Categories.Utility:CreateModule({
        Name = "Katana Detection",
        Function = function(callback)
            katanaEnabled = callback
            if callback then
                if not heartbeatConn then
                    heartbeatConn = runService.Heartbeat:Connect(detectKatana)
                end
            else
                if heartbeatConn then
                    heartbeatConn:Disconnect()
                    heartbeatConn = nil
                end
            end
        end,
        Tooltip = "Warns you when an enemy has a katana"
    })

    vape:Clean(function()
        if heartbeatConn then heartbeatConn:Disconnect() end
    end)
end)

run(function()
    local camera = workspace.CurrentCamera
    local defaultVert = 70; local defaultHoriz = 100
    local vertFOV = defaultVert; local horizScale = 1.0
    local fovConnection = nil
    local function applyFOV()
        if camera then
            camera.FieldOfView = vertFOV
            if horizScale ~= 1.0 then
                camera.CFrame = camera.CFrame * CFrame.new(0,0,0,1,0,0,0,horizScale,0,0,0,1)
            end
        end
    end
    local FovModule = vape.Categories.Utility:CreateModule({
        Name = "FOV",
        Function = function(callback)
            if callback then
                if not fovConnection then fovConnection = runService.RenderStepped:Connect(applyFOV) end
            else
                if fovConnection then fovConnection:Disconnect(); fovConnection = nil end
                camera.FieldOfView = defaultVert
            end
        end
    })
    FovModule:CreateSlider({Name="Vertical FOV", Min=10, Max=120, Default=defaultVert, Function=function(v) vertFOV=v end, Suffix="°"})
    FovModule:CreateSlider({Name="Horizontal FOV", Min=50, Max=120, Default=defaultHoriz, Function=function(v) horizScale=v/100 end, Suffix="%"})
    FovModule:CreateButton({Name="Reset FOV", Function=function()
        vertFOV = defaultVert; horizScale = 1.0
        notif('FOV', 'Reset to default', 2, 'success')
    end})
end)
                                                                                                                        
run(function()
    local deviceSpoofEnabled = false
    local selectedDevice = "PC"
    local conn = nil
    local remoteCache = nil
    local interval = 1
    local lastSent = nil

    local MAP = {
        PC = "MouseKeyboard",
        Phone = "Touch",
        Controller = "Gamepad",
        VR = "VR",
    }

    local function findRemote()
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if not remotes then return nil end
        local replication = remotes:FindFirstChild("Replication")
        if not replication then return nil end
        local fighter = replication:FindFirstChild("Fighter")
        if not fighter then return nil end
        return fighter:FindFirstChild("SetControls")
    end

    local function sendDevice()
        if not deviceSpoofEnabled then return end
        local mapped = MAP[selectedDevice] or selectedDevice
        if not mapped or mapped == lastSent then return end
        if not remoteCache then remoteCache = findRemote() end
        if not remoteCache then return end
        pcall(function()
            remoteCache:FireServer(mapped)
        end)
        lastSent = mapped
    end

    local DeviceSpoofModule = vape.Categories.Utility:CreateModule({
        Name = "Device Spoofer",
        Function = function(callback)
            deviceSpoofEnabled = callback
            if callback then
                remoteCache = findRemote()
                if not remoteCache then
                    notif('Device Spoof', 'SetControls remote not found!', 3, 'alert')
                    -- keep off
                    DeviceSpoofModule:Toggle()
                    return
                end
                -- heartbeat
                sendDevice()
                local acc = 0
                conn = runService.Heartbeat:Connect(function(dt)
                    acc = acc + dt
                    if acc >= interval then
                        acc = acc - interval
                        sendDevice()
                    end
                end)
            else
                if conn then conn:Disconnect(); conn = nil end
                lastSent = nil
            end
        end,
        Tooltip = "Spoofs your device type."
    })

    DeviceSpoofModule:CreateDropdown({
        Name = "Device Type",
        List = {"PC", "Phone", "Controller", "VR"},
        Default = "PC",
        Function = function(val) selectedDevice = val end
    })
end)
                                                                                                                                            
run(function()
    local DesyncModule = vape.Categories.Combat:CreateModule({
        Name = "Wallbang Method (Might be Detected)",
        Function = function(callback)
            if callback then
                -- Initialize
                if not shared.__s9t0u1 then
                    local __a1b2c3 = setmetatable({}, {
                        __index = function(_, __g7h8i9)
                            local __j0k1l2, __m3n4o5 = pcall(function()
                                return game:GetService(__g7h8i9)
                            end)
                            if __m3n4o5 then
                                return cloneref(__m3n4o5)
                            end
                            return nil
                        end
                    })
                    local __p6q7r8 = getgenv()
                    local __v2w3x4 = __a1b2c3.Players
                    local __y5z6a7 = __a1b2c3.RunService
                    local __b8c9d0 = __a1b2c3.ReplicatedStorage
                    local __e1f2g3 = __a1b2c3.Workspace
                    local __h4i5j6 = __a1b2c3.UserInputService
                    local __k7l8m9 = __v2w3x4.LocalPlayer
                    local __n0o1p2 = __e1f2g3.CurrentCamera
                    local __q3r4s5 = __k7l8m9.PlayerScripts
                    local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
                    local __w9x0y1 = require(__b8c9d0.Modules.Utility)
                    local __z2a3b4 = setmetatable({}, {
                        __index = function(_, __c5d6e7)
                            local __f8g9h0 = __k7l8m9.Character
                            if not __f8g9h0 then return nil end
                            if __c5d6e7 == "__root" then
                                return __f8g9h0:FindFirstChild("HumanoidRootPart")
                            elseif __c5d6e7 == "__head" then
                                return __f8g9h0:FindFirstChild("Head")
                            end
                            return nil
                        end
                    })
                    __p6q7r8.__s9t0u1 = {}
                    do
                        local __i1j2k3 = __p6q7r8.__s9t0u1
                        function __i1j2k3:__init()
                            self.__active = true
                            self.__target = nil
                            self.__desync = false
                            self.__conn1 = nil
                            self.__conn2 = nil
                            self.__task1 = nil
                            self.__oldfunc = nil
                            self:__setup()
                        end
                        function __i1j2k3:__setup()
                            self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
                                if not self.__active then return end
                                self.__target = self:__find()
                            end)
                            local __l4m5n6 = __t6u7v8.StartShooting
                            self.__oldfunc = __l4m5n6
                            __t6u7v8.StartShooting = function(__o7p8q9, ...)
                                local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
                                if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                                    return unpack(__r0s1t2)
                                end
                                local __u3v4w5 = __r0s1t2[3]
                                if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                                    return unpack(__r0s1t2)
                                end
                                __r0s1t2[4] = true
                                local __x6y7z8 = self.__target
                                if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                                    return unpack(__r0s1t2)
                                end
                                if not self.__desync or self.__curr ~= __x6y7z8 then
                                    self:__desync_start(__x6y7z8)
                                    task.wait(0.1)
                                end
                                if self.__task1 then
                                    task.cancel(self.__task1)
                                    self.__task1 = nil
                                end
                                local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
                                if not __a9b0c1 then return unpack(__r0s1t2) end
                                local __d2e3f4 = __a9b0c1.Position
                                local __g5h6i7 = __a9b0c1.CFrame
                                local __j8k9l0 = __d2e3f4 - Vector3.new(0, 5, 0)
                                local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4)
                                local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random(), math.random(), math.random())))
                                __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
                                __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
                                __u3v4w5[utf8.char(2)] = __a9b0c1
                                __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)
                                self.__task1 = task.delay(0.15, function()
                                    self:__desync_stop()
                                end)
                                return unpack(__r0s1t2)
                            end
                        end
                        function __i1j2k3:__find()
                            local __s7t8u9 = nil
                            local __v0w1x2 = math.huge
                            local __y3z4a5 = __h4i5j6:GetMouseLocation()
                            for _, __b6c7d8 in next, __v2w3x4:GetPlayers() do
                                if __b6c7d8 == __k7l8m9 then continue end
                                if __b6c7d8:GetAttribute("TeamID") == __k7l8m9:GetAttribute("TeamID") then continue end
                                local __e9f0g1 = __b6c7d8.Character
                                if not __e9f0g1 then continue end
                                local __h2i3j4 = __e9f0g1:FindFirstChild("HumanoidRootPart")
                                local __k5l6m7 = __e9f0g1:FindFirstChild("Head")
                                local __n8o9p0 = __e9f0g1:FindFirstChildWhichIsA("Humanoid")
                                if not (__h2i3j4 and __k5l6m7 and __n8o9p0 and __n8o9p0.Health > 0) then continue end
                                local __q1r2s3, __t4u5v6 = __n0o1p2:WorldToViewportPoint(__h2i3j4.Position)
                                if not __t4u5v6 then continue end
                                local __w7x8y9 = Vector2.new(__q1r2s3.X, __q1r2s3.Y)
                                local __z0a1b2 = (__y3z4a5 - __w7x8y9).Magnitude
                                if __z0a1b2 < __v0w1x2 then
                                    __v0w1x2 = __z0a1b2
                                    __s7t8u9 = __b6c7d8
                                end
                            end
                            return __s7t8u9
                        end
                        function __i1j2k3:__desync_start(__c3d4e5)
                            if self.__conn2 then self.__conn2:Disconnect() end
                            self.__desync = true
                            self.__curr = __c3d4e5
                            self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
                                if not self.__desync then return end
                                local __f6g7h8 = __z2a3b4.__root
                                if not __f6g7h8 then return end
                                local __i9j0k1 = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("HumanoidRootPart")
                                if not __i9j0k1 then 
                                    self:__desync_stop()
                                    return 
                                end
                                local __l2m3n4 = __f6g7h8.CFrame
                                local __o5p6q7 = __f6g7h8.Velocity
                                local __r8s9t0 = __f6g7h8.RotVelocity
                                __f6g7h8.CFrame = __i9j0k1.CFrame * CFrame.new(0, -5, 0)
                                __y5z6a7:BindToRenderStep("__restore", 101, function()
                                    __f6g7h8.CFrame = __l2m3n4
                                    __f6g7h8.Velocity = __o5p6q7
                                    __f6g7h8.RotVelocity = __r8s9t0
                                    __y5z6a7:UnbindFromRenderStep("__restore")
                                end)
                            end)
                        end
                        function __i1j2k3:__desync_stop()
                            self.__desync = false
                            self.__curr = nil
                            if self.__conn2 then
                                self.__conn2:Disconnect()
                                self.__conn2 = nil
                            end
                        end
                        function __i1j2k3:Shutdown()
                            self.__active = false
                            if self.__conn1 then self.__conn1:Disconnect() end
                            if self.__conn2 then self.__conn2:Disconnect() end
                            if self.__task1 then task.cancel(self.__task1) end
                            if self.__oldfunc then
                                __t6u7v8.StartShooting = self.__oldfunc
                            end
                        end
                        __i1j2k3:__init()
                    end
                end
            else
                if shared.__s9t0u1 then
                    shared.__s9t0u1:Shutdown()
                    shared.__s9t0u1 = nil
                end
            end
        end,
        Tooltip = "Just Shoot"
    })
end)
                                                                                                                                                
run(function()
    if not hookfunction then
        notif('Gun Mods', 'Your executor does not support hookfunction.', 5, 'alert')
        return
    end

    local gunModsEnabled = false
    local oldInput = nil
    local hookActive = false
    local pendingTask = nil

    local recoilVal = 0
    local spreadVal = 0
    local projSpeedVal = 99999999
    local shootCooldownVal = 0
    local quickShotCooldownVal = 0

    local function tryApplyHook()
        --
        if not gunModsEnabled then return end

        --
        local lobbyVisible
        pcall(function() lobbyVisible = isLobbyVisible() end)
        if lobbyVisible then
            --
            if gunModsEnabled then
                pendingTask = task.delay(10, tryApplyHook)
            end
            return
        end

        --
        if hookActive then return end

        --
        local ok, clientItemModule = pcall(function()
            return require(lplr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
        end)
        if not ok or not clientItemModule or not clientItemModule.Input then
            --
            if gunModsEnabled then
                pendingTask = task.delay(10, tryApplyHook)
            end
            return
        end

        -- hook here
        local inputFunc = clientItemModule.Input
        oldInput = hookfunction(inputFunc, function(...)
            local args = {...}
            local data = args[1]
            if type(data) == "table" then
                local info = data.Info
                if type(info) == "table" then
                    info.ShootRecoil = recoilVal
                    info.ShootSpread = spreadVal
                    info.ProjectileSpeed = projSpeedVal
                    info.ShootCooldown = shootCooldownVal
                    info.QuickShotCooldown = quickShotCooldownVal
                end
            end
            return oldInput(...)
        end)
        hookActive = true
    end

    local function cancelPending()
        if pendingTask then
            pcall(task.cancel, pendingTask)
            pendingTask = nil
        end
    end

    local function removeHook()
        cancelPending()   -- don't re‑hook

        if not hookActive or not oldInput then return end

        local ok, clientItemModule = pcall(function()
            return require(lplr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
        end)
        if ok and clientItemModule and clientItemModule.Input then
            pcall(function() hookfunction(clientItemModule.Input, oldInput) end)
            pcall(function() clientItemModule.Input = oldInput end)
        end

        hookActive = false
        oldInput = nil
    end

    local GunModsModule = vape.Categories.Utility:CreateModule({
        Name = "Gun Mods",
        Function = function(callback)
            gunModsEnabled = callback
            if callback then
                -- Start initia
                cancelPending()   -- just in case
                pendingTask = task.delay(15, tryApplyHook)
            else
                removeHook()
            end
        end,
        Tooltip = "Your better than them <3."
    })

    GunModsModule:CreateSlider({
        Name = "Recoil",
        Min = 0, Max = 10, Default = 0, Decimal = 10,
        Function = function(v) recoilVal = v end,
        Suffix = "x"
    })
    GunModsModule:CreateSlider({
        Name = "Spread",
        Min = 0, Max = 10, Default = 0, Decimal = 10,
        Function = function(v) spreadVal = v end,
        Suffix = "x"
    })
    GunModsModule:CreateSlider({
        Name = "Projectile Speed",
        Min = 100, Max = 99999, Default = 99999999,
        Function = function(v) projSpeedVal = v end,
        Suffix = "studs/s"
    })
    GunModsModule:CreateSlider({
        Name = "Shoot Cooldown",
        Min = 0, Max = 1, Default = 0, Decimal = 100,
        Function = function(v) shootCooldownVal = v end,
        Suffix = "s"
    })
    GunModsModule:CreateSlider({
        Name = "Quick Shot Cooldown",
        Min = 0, Max = 1, Default = 0, Decimal = 100,
        Function = function(v) quickShotCooldownVal = v end,
        Suffix = "s"
    })
end)
                                                                                                                                                          
run(function()
    if hookmetamethod and getnamecallmethod then
        local SkinModule = vape.Categories.Utility:CreateModule({Name = "Skin Unlocker", Function = function(callback)
            if callback and not shared.VapeSkinUnlockerActive then
                shared.VapeSkinUnlockerActive = true
                pcall(function()
                    -- Services
                    local Players = game:GetService("Players")
                    local ReplicatedStorage = game:GetService("ReplicatedStorage")
                    local HttpService = game:GetService("HttpService")
                    local player = Players.LocalPlayer
                    local playerScripts = player.PlayerScripts
                    local controllers = playerScripts.Controllers
                    local EnumLibrary = require(ReplicatedStorage.Modules:WaitForChild("EnumLibrary", 10))
                    if EnumLibrary then EnumLibrary:WaitForEnumBuilder() end
                    local CosmeticLibrary = require(ReplicatedStorage.Modules:WaitForChild("CosmeticLibrary", 10))
                    local ItemLibrary = require(ReplicatedStorage.Modules:WaitForChild("ItemLibrary", 10))
                    local DataController = require(controllers:WaitForChild("PlayerDataController", 10))
                    local equipped, favorites = {}, {}
                    local constructingWeapon, viewingProfile = nil, nil
                    local lastUsedWeapon = nil

                    local function cloneCosmetic(name, cosmeticType, options)
                        local base = CosmeticLibrary.Cosmetics[name]
                        if not base then return nil end
                        local data = {}
                        for key, value in pairs(base) do data[key] = value end
                        data.Name = name
                        data.Type = data.Type or cosmeticType
                        data.Seed = data.Seed or math.random(1, 1000000)
                        if EnumLibrary then
                            local success, enumId = pcall(EnumLibrary.ToEnum, EnumLibrary, name)
                            if success and enumId then data.Enum, data.ObjectID = enumId, data.ObjectID or enumId end
                        end
                        if options then
                            if options.inverted ~= nil then data.Inverted = options.inverted end
                            if options.favoritesOnly ~= nil then data.OnlyUseFavorites = options.favoritesOnly end
                        end
                        return data
                    end

                    local saveFile = "unlockall/config.json"
                    local function saveConfig()
                        if not writefile then return end
                        pcall(function()
                            local config = {equipped = {}, favorites = favorites}
                            for weapon, cosmetics in pairs(equipped) do
                                config.equipped[weapon] = {}
                                for cosmeticType, cosmeticData in pairs(cosmetics) do
                                    if cosmeticData and cosmeticData.Name then
                                        config.equipped[weapon][cosmeticType] = {name = cosmeticData.Name, seed = cosmeticData.Seed, inverted = cosmeticData.Inverted}
                                    end
                                end
                            end
                            makefolder("unlockall")
                            writefile(saveFile, HttpService:JSONEncode(config))
                        end)
                    end

                    local function loadConfig()
                        if not readfile or not isfile or not isfile(saveFile) then return end
                        pcall(function()
                            local config = HttpService:JSONDecode(readfile(saveFile))
                            if config.equipped then
                                for weapon, cosmetics in pairs(config.equipped) do
                                    equipped[weapon] = {}
                                    for cosmeticType, cosmeticData in pairs(cosmetics) do
                                        local cloned = cloneCosmetic(cosmeticData.name, cosmeticType, {inverted = cosmeticData.inverted})
                                        if cloned then cloned.Seed = cosmeticData.seed equipped[weapon][cosmeticType] = cloned end
                                    end
                                end
                            end
                            favorites = config.favorites or {}
                        end)
                    end

                    CosmeticLibrary.OwnsCosmeticNormally = function(self, inventory, name, weapon)
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and cosmetic.Type == "Skin" then return true end
                        return false
                    end
                    CosmeticLibrary.OwnsCosmeticUniversally = function(self, inventory, name, weapon)
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and cosmetic.Type == "Skin" then return true end
                        return false
                    end
                    CosmeticLibrary.OwnsCosmeticForWeapon = function(self, inventory, name, weapon)
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and cosmetic.Type == "Skin" then return true end
                        return false
                    end

                    local originalOwnsCosmetic = CosmeticLibrary.OwnsCosmetic
                    CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
                        if name:find("MISSING_") then return originalOwnsCosmetic(self, inventory, name, weapon) end
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and cosmetic.Type == "Skin" then return true end
                        return originalOwnsCosmetic(self, inventory, name, weapon)
                    end

                    local originalGet = DataController.Get
                    DataController.Get = function(self, key)
                        local data = originalGet(self, key)
                        if key == "CosmeticInventory" then
                            local proxy = {}
                            if data then for k, v in pairs(data) do
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and cosmetic.Type == "Skin" then proxy[k] = v end
                            end end
                            return setmetatable(proxy, {__index = function(t, k)
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and cosmetic.Type == "Skin" then return true end
                                return nil
                            end})
                        end
                        if key == "FavoritedCosmetics" then
                            local result = data and table.clone(data) or {}
                            for weapon, favs in pairs(favorites) do
                                result[weapon] = result[weapon] or {}
                                for name, isFav in pairs(favs) do
                                    local cosmetic = CosmeticLibrary.Cosmetics[name]
                                    if cosmetic and cosmetic.Type == "Skin" then result[weapon][name] = isFav end
                                end
                            end
                            return result
                        end
                        return data
                    end

                    local originalGetWeaponData = DataController.GetWeaponData
                    DataController.GetWeaponData = function(self, weaponName)
                        local data = originalGetWeaponData(self, weaponName)
                        if not data then return nil end
                        local merged = {}
                        for key, value in pairs(data) do merged[key] = value end
                        merged.Name = weaponName
                        if equipped[weaponName] then
                            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                                if cosmeticType == "Skin" then merged[cosmeticType] = cosmeticData end
                            end
                        end
                        return merged
                    end

                    local FighterController
                    pcall(function() FighterController = require(controllers:WaitForChild("FighterController", 10)) end)

                    if hookmetamethod then
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        local dataRemotes = remotes and remotes:FindFirstChild("Data")
                        local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
                        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
                        local replicationRemotes = remotes and remotes:FindFirstChild("Replication")
                        local fighterRemotes = replicationRemotes and replicationRemotes:FindFirstChild("Fighter")
                        local useItemRemote = fighterRemotes and fighterRemotes:FindFirstChild("UseItem")

                        if equipRemote then
                            local oldNamecall
                            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                                local args = {...}
                                if useItemRemote and self == useItemRemote then
                                    local objectID = args[1]
                                    if FighterController then
                                        pcall(function()
                                            local fighter = FighterController:GetFighter(player)
                                            if fighter and fighter.Items then
                                                for _, item in pairs(fighter.Items) do
                                                    if item:Get("ObjectID") == objectID then lastUsedWeapon = item.Name break end
                                                end
                                            end
                                        end)
                                    end
                                end
                                if self == equipRemote then
                                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                                    if cosmeticType ~= "Skin" then return oldNamecall(self, ...) end
                                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                                        local inventory = DataController:Get("CosmeticInventory")
                                        if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                                    end
                                    equipped[weaponName] = equipped[weaponName] or {}
                                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                        equipped[weaponName][cosmeticType] = nil
                                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                                    else
                                        local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                        if cloned then equipped[weaponName][cosmeticType] = cloned end
                                    end
                                    task.defer(function()
                                        pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                                        task.wait(0.2); saveConfig()
                                    end)
                                    return
                                end
                                if self == favoriteRemote then
                                    local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                                    if cosmetic and cosmetic.Type == "Skin" then
                                        favorites[args[1]] = favorites[args[1]] or {}
                                        favorites[args[1]][args[2]] = args[3] or nil
                                        saveConfig()
                                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                                    end
                                    return
                                end
                                return oldNamecall(self, ...)
                            end)
                        end
                    end

                    local ClientItem
                    pcall(function() ClientItem = require(player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem) end)
                    if ClientItem and ClientItem._CreateViewModel then
                        local originalCreateViewModel = ClientItem._CreateViewModel
                        ClientItem._CreateViewModel = function(self, viewmodelRef)
                            local weaponName = self.Name
                            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                            constructingWeapon = (weaponPlayer == player) and weaponName or nil
                            if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Skin and viewmodelRef then
                                local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")
                                if viewmodelRef[dataKey] then
                                    viewmodelRef[dataKey][skinKey] = equipped[weaponName].Skin; viewmodelRef[dataKey][nameKey] = equipped[weaponName].Skin.Name
                                elseif viewmodelRef.Data then
                                    viewmodelRef.Data.Skin = equipped[weaponName].Skin; viewmodelRef.Data.Name = equipped[weaponName].Skin.Name
                                end
                            end
                            local result = originalCreateViewModel(self, viewmodelRef)
                            constructingWeapon = nil
                            return result
                        end
                    end

                    local viewModelModule = player.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
                    if viewModelModule then
                        local ClientViewModel = require(viewModelModule)
                        local originalNew = ClientViewModel.new
                        ClientViewModel.new = function(replicatedData, clientItem)
                            local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
                            local weaponName = constructingWeapon or clientItem.Name
                            if weaponPlayer == player and equipped[weaponName] then
                                local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
                                local dataKey = ReplicatedClass:ToEnum("Data")
                                replicatedData[dataKey] = replicatedData[dataKey] or {}
                                local cosmetics = equipped[weaponName]
                                if cosmetics.Skin then replicatedData[dataKey][ReplicatedClass:ToEnum("Skin")] = cosmetics.Skin end
                            end
                            local result = originalNew(replicatedData, clientItem)
                            return result
                        end
                    end

                    local originalGetViewModelImage = ItemLibrary.GetViewModelImageFromWeaponData
                    ItemLibrary.GetViewModelImageFromWeaponData = function(self, weaponData, highRes)
                        if not weaponData then return originalGetViewModelImage(self, weaponData, highRes) end
                        local weaponName = weaponData.Name
                        local shouldShowSkin = (weaponData.Skin and equipped[weaponName] and weaponData.Skin == equipped[weaponName].Skin) or (viewingProfile == player and equipped[weaponName] and equipped[weaponName].Skin)
                        if shouldShowSkin and equipped[weaponName] and equipped[weaponName].Skin then
                            local skinInfo = self.ViewModels[equipped[weaponName].Skin.Name]
                            if skinInfo then return skinInfo[highRes and "ImageHighResolution" or "Image"] or skinInfo.Image end
                        end
                        return originalGetViewModelImage(self, weaponData, highRes)
                    end

                    -- VERSION CHARMS
                    local originalOwnsCosmeticCharm = CosmeticLibrary.OwnsCosmetic
                    CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
                        if name:find("MISSING_") then return originalOwnsCosmeticCharm(self, inventory, name, weapon) end
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and (cosmetic.Type == "Charm" or name:lower():find("charm")) then return true end
                        return originalOwnsCosmeticCharm(self, inventory, name, weapon)
                    end
                    local originalGetCharm = DataController.Get
                    DataController.Get = function(self, key)
                        local data = originalGetCharm(self, key)
                        if key == "CosmeticInventory" then
                            local proxy = {}
                            if data then for k, v in pairs(data) do
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Charm" or k:lower():find("charm")) then proxy[k] = v end
                            end end
                            return setmetatable(proxy, {__index = function(t, k)
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Charm" or k:lower():find("charm")) then return true end
                                return nil
                            end})
                        end
                        if key == "FavoritedCosmetics" then
                            local result = data and table.clone(data) or {}
                            for weapon, favs in pairs(favorites) do
                                result[weapon] = result[weapon] or {}
                                for name, isFav in pairs(favs) do
                                    local cosmetic = CosmeticLibrary.Cosmetics[name]
                                    if cosmetic and (cosmetic.Type == "Charm" or name:lower():find("charm")) then result[weapon][name] = isFav end
                                end
                            end
                            return result
                        end
                        return data
                    end
                    local originalGetWeaponDataCharm = DataController.GetWeaponData
                    DataController.GetWeaponData = function(self, weaponName)
                        local data = originalGetWeaponDataCharm(self, weaponName)
                        if not data then return nil end
                        local merged = {}
                        for key, value in pairs(data) do merged[key] = value end
                        merged.Name = weaponName
                        if equipped[weaponName] then
                            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                                if cosmeticType == "Charm" then merged[cosmeticType] = cosmeticData end
                            end
                        end
                        return merged
                    end
                    if hookmetamethod then
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        local dataRemotes = remotes and remotes:FindFirstChild("Data")
                        local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
                        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
                        if equipRemote then
                            local oldNamecall
                            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                                local args = {...}
                                if self == equipRemote then
                                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                                    if cosmeticType ~= "Charm" then return oldNamecall(self, ...) end
                                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                                        local inventory = DataController:Get("CosmeticInventory")
                                        if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                                    end
                                    equipped[weaponName] = equipped[weaponName] or {}
                                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                        equipped[weaponName][cosmeticType] = nil
                                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                                    else
                                        local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                        if cloned then equipped[weaponName][cosmeticType] = cloned end
                                    end
                                    task.defer(function()
                                        pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                                        task.wait(0.2); saveConfig()
                                    end)
                                    return
                                end
                                if self == favoriteRemote then
                                    local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                                    if cosmetic and (cosmetic.Type == "Charm" or args[2]:lower():find("charm")) then
                                        favorites[args[1]] = favorites[args[1]] or {}
                                        favorites[args[1]][args[2]] = args[3] or nil
                                        saveConfig()
                                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                                    end
                                    return
                                end
                                return oldNamecall(self, ...)
                            end)
                        end
                    end
                    if ClientItem and ClientItem._CreateViewModel then
                        local originalCreateViewModelCharm = ClientItem._CreateViewModel
                        ClientItem._CreateViewModel = function(self, viewmodelRef)
                            local weaponName = self.Name
                            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                            constructingWeapon = (weaponPlayer == player) and weaponName or nil
                            if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Charm and viewmodelRef then
                                local dataKey, charmKey, nameKey = self:ToEnum("Data"), self:ToEnum("Charm"), self:ToEnum("Name")
                                if viewmodelRef[dataKey] then
                                    viewmodelRef[dataKey][charmKey] = equipped[weaponName].Charm; viewmodelRef[dataKey][nameKey] = equipped[weaponName].Charm.Name
                                elseif viewmodelRef.Data then
                                    viewmodelRef.Data.Charm = equipped[weaponName].Charm; viewmodelRef.Data.Name = equipped[weaponName].Charm.Name
                                end
                            end
                            local result = originalCreateViewModelCharm(self, viewmodelRef)
                            constructingWeapon = nil
                            return result
                        end
                    end

                    -- VERSION DANCES
                    local originalOwnsCosmeticDance = CosmeticLibrary.OwnsCosmetic
                    CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
                        if name:find("MISSING_") then return originalOwnsCosmeticDance(self, inventory, name, weapon) end
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then return true end
                        return originalOwnsCosmeticDance(self, inventory, name, weapon)
                    end
                    local originalGetDance = DataController.Get
                    DataController.Get = function(self, key)
                        local data = originalGetDance(self, key)
                        if key == "CosmeticInventory" then
                            local proxy = {}
                            if data then for k, v in pairs(data) do
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or k:lower():find("dance") or k:lower():find("emote")) then proxy[k] = v end
                            end end
                            return setmetatable(proxy, {__index = function(t, k)
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or k:lower():find("dance") or k:lower():find("emote")) then return true end
                                return nil
                            end})
                        end
                        if key == "FavoritedCosmetics" then
                            local result = data and table.clone(data) or {}
                            for weapon, favs in pairs(favorites) do
                                result[weapon] = result[weapon] or {}
                                for name, isFav in pairs(favs) do
                                    local cosmetic = CosmeticLibrary.Cosmetics[name]
                                    if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or name:lower():find("dance") or name:lower():find("emote")) then result[weapon][name] = isFav end
                                end
                            end
                            return result
                        end
                        return data
                    end
                    local originalGetWeaponDataDance = DataController.GetWeaponData
                    DataController.GetWeaponData = function(self, weaponName)
                        local data = originalGetWeaponDataDance(self, weaponName)
                        if not data then return nil end
                        local merged = {}
                        for key, value in pairs(data) do merged[key] = value end
                        merged.Name = weaponName
                        return merged
                    end
                    if hookmetamethod then
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        local dataRemotes = remotes and remotes:FindFirstChild("Data")
                        local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
                        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
                        if equipRemote then
                            local oldNamecall
                            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                                local args = {...}
                                if self == equipRemote then
                                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                                    if cosmeticType == "Dance" or cosmeticType == "Emote" or (cosmeticName and (cosmeticName:lower():find("dance") or cosmeticName:lower():find("emote"))) then
                                        equipped.Dances = equipped.Dances or {}
                                        if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then equipped.Dances[cosmeticType] = nil
                                        else
                                            local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                            if cloned then equipped.Dances[cosmeticType] = cloned end
                                        end
                                        task.defer(function()
                                            pcall(function() DataController.CurrentData:Replicate("CosmeticInventory") end)
                                            task.wait(0.2); saveConfig()
                                        end)
                                        return
                                    end
                                    return oldNamecall(self, ...)
                                end
                                if self == favoriteRemote then
                                    local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                                    if cosmetic and (cosmetic.Type == "Dance" or cosmetic.Type == "Emote" or args[2]:lower():find("dance") or args[2]:lower():find("emote")) then
                                        favorites[args[1]] = favorites[args[1]] or {}
                                        favorites[args[1]][args[2]] = args[3] or nil
                                        saveConfig()
                                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                                    end
                                    return
                                end
                                return oldNamecall(self, ...)
                            end)
                        end
                    end

                    -- VERSION WRAPS
                    local originalOwnsCosmeticWrap = CosmeticLibrary.OwnsCosmetic
                    CosmeticLibrary.OwnsCosmetic = function(self, inventory, name, weapon)
                        if name:find("MISSING_") then return originalOwnsCosmeticWrap(self, inventory, name, weapon) end
                        local cosmetic = CosmeticLibrary.Cosmetics[name]
                        if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or name:lower():find("wrap")) then return true end
                        return originalOwnsCosmeticWrap(self, inventory, name, weapon)
                    end
                    local originalGetWrapVer = DataController.Get
                    DataController.Get = function(self, key)
                        local data = originalGetWrapVer(self, key)
                        if key == "CosmeticInventory" then
                            local proxy = {}
                            if data then for k, v in pairs(data) do
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or k:lower():find("wrap")) then proxy[k] = v end
                            end end
                            return setmetatable(proxy, {__index = function(t, k)
                                local cosmetic = CosmeticLibrary.Cosmetics[k]
                                if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or k:lower():find("wrap")) then return true end
                                return nil
                            end})
                        end
                        if key == "FavoritedCosmetics" then
                            local result = data and table.clone(data) or {}
                            for weapon, favs in pairs(favorites) do
                                result[weapon] = result[weapon] or {}
                                for name, isFav in pairs(favs) do
                                    local cosmetic = CosmeticLibrary.Cosmetics[name]
                                    if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or name:lower():find("wrap")) then result[weapon][name] = isFav end
                                end
                            end
                            return result
                        end
                        return data
                    end
                    local originalGetWeaponDataWrap = DataController.GetWeaponData
                    DataController.GetWeaponData = function(self, weaponName)
                        local data = originalGetWeaponDataWrap(self, weaponName)
                        if not data then return nil end
                        local merged = {}
                        for key, value in pairs(data) do merged[key] = value end
                        merged.Name = weaponName
                        if equipped[weaponName] then
                            for cosmeticType, cosmeticData in pairs(equipped[weaponName]) do
                                if cosmeticType == "Wrap" or cosmeticType == "Wrapping" then merged[cosmeticType] = cosmeticData end
                            end
                        end
                        return merged
                    end
                    if hookmetamethod then
                        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                        local dataRemotes = remotes and remotes:FindFirstChild("Data")
                        local equipRemote = dataRemotes and dataRemotes:FindFirstChild("EquipCosmetic")
                        local favoriteRemote = dataRemotes and dataRemotes:FindFirstChild("FavoriteCosmetic")
                        if equipRemote then
                            local oldNamecall
                            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                                if getnamecallmethod() ~= "FireServer" then return oldNamecall(self, ...) end
                                local args = {...}
                                if self == equipRemote then
                                    local weaponName, cosmeticType, cosmeticName, options = args[1], args[2], args[3], args[4] or {}
                                    if cosmeticType ~= "Wrap" and cosmeticType ~= "Wrapping" then return oldNamecall(self, ...) end
                                    if cosmeticName and cosmeticName ~= "None" and cosmeticName ~= "" then
                                        local inventory = DataController:Get("CosmeticInventory")
                                        if inventory and rawget(inventory, cosmeticName) then return oldNamecall(self, ...) end
                                    end
                                    equipped[weaponName] = equipped[weaponName] or {}
                                    if not cosmeticName or cosmeticName == "None" or cosmeticName == "" then
                                        equipped[weaponName][cosmeticType] = nil
                                        if not next(equipped[weaponName]) then equipped[weaponName] = nil end
                                    else
                                        local cloned = cloneCosmetic(cosmeticName, cosmeticType, {inverted = options.IsInverted, favoritesOnly = options.OnlyUseFavorites})
                                        if cloned then equipped[weaponName][cosmeticType] = cloned end
                                    end
                                    task.defer(function()
                                        pcall(function() DataController.CurrentData:Replicate("WeaponInventory") end)
                                        task.wait(0.2); saveConfig()
                                    end)
                                    return
                                end
                                if self == favoriteRemote then
                                    local cosmetic = CosmeticLibrary.Cosmetics[args[2]]
                                    if cosmetic and (cosmetic.Type == "Wrap" or cosmetic.Type == "Wrapping" or args[2]:lower():find("wrap")) then
                                        favorites[args[1]] = favorites[args[1]] or {}
                                        favorites[args[1]][args[2]] = args[3] or nil
                                        saveConfig()
                                        task.spawn(function() pcall(function() DataController.CurrentData:Replicate("FavoritedCosmetics") end) end)
                                    end
                                    return
                                end
                                return oldNamecall(self, ...)
                            end)
                        end
                    end
                    if ClientItem and ClientItem._CreateViewModel then
                        local originalCreateViewModelWrap = ClientItem._CreateViewModel
                        ClientItem._CreateViewModel = function(self, viewmodelRef)
                            local weaponName = self.Name
                            local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
                            constructingWeapon = (weaponPlayer == player) and weaponName or nil
                            if weaponPlayer == player and equipped[weaponName] and equipped[weaponName].Wrap and viewmodelRef then
                                local dataKey, wrapKey, nameKey = self:ToEnum("Data"), self:ToEnum("Wrap"), self:ToEnum("Name")
                                if viewmodelRef[dataKey] then
                                    viewmodelRef[dataKey][wrapKey] = equipped[weaponName].Wrap; viewmodelRef[dataKey][nameKey] = equipped[weaponName].Wrap.Name
                                elseif viewmodelRef.Data then
                                    viewmodelRef.Data.Wrap = equipped[weaponName].Wrap; viewmodelRef.Data.Name = equipped[weaponName].Wrap.Name
                                end
                            end
                            local result = originalCreateViewModelWrap(self, viewmodelRef)
                            constructingWeapon = nil
                            return result
                        end
                    end

                    -- FINAL
                    pcall(function()
                        local ViewProfile = require(player.PlayerScripts.Modules.Pages.ViewProfile)
                        if ViewProfile and ViewProfile.Fetch then
                            local originalFetch = ViewProfile.Fetch
                            ViewProfile.Fetch = function(self, targetPlayer)
                                viewingProfile = targetPlayer
                                return originalFetch(self, targetPlayer)
                            end
                        end
                    end)
                    loadConfig()
                end)
            end
        end})
    end
end)

entitylib.start()
print("Rawr.xyz V4.2.8")
