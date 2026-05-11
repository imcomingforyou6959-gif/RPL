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

local blacklistUrl = "https://raw.githubusercontent.com/imcomingforyou6959-gif/whitelists/refs/heads/main/PlayerBlacklist.json" .. "?t=" .. tick()
local function checkBlacklist()
    local httpService = game:GetService("HttpService")
    local success, result = pcall(function() return game:HttpGet(blacklistUrl) end)
    if not success then return false end
    local ok, data = pcall(httpService.JSONDecode, httpService, result)
    if not (ok and data and type(data.BlacklistedUsers) == "table") then return false end
    local userId = game.Players.LocalPlayer.UserId
    if data.BlacklistedUsers[tostring(userId)] or data.BlacklistedUsers[userId] then
        pcall(function()
            game.Players.LocalPlayer:Kick("Rawr.xyz | You have been blacklisted. All Appeals Must be Sent in https://discord.gg/RJj7vrNwBy")
        end)
        return true
    end
    return false
end
if checkBlacklist() then while true do task.wait(10) end end

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

local t = { sa = { enabled = false } }

-- Silent Aim
local aimPart = "Head"
local smoothness = 1
local wallCheckEnabled = true
local ShowTarget = nil
local CircleObject = nil
local CircleColor, CircleTransparency, CircleFilled
local cameraConnection = nil
local rand = Random.new()

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

local function getClosestPlayerToMouse()
    local closest = nil
    local shortest = math.huge
    local mousePos = inputService:GetMouseLocation()
    for _, player in ipairs(playersService:GetPlayers()) do
        if player ~= lplr and player.Character and player.Character:FindFirstChild("Head") then
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

local function getAimPart(player, partName)
    if not player or not player.Character then return nil end
    if partName == "Head" then return player.Character:FindFirstChild("Head")
    elseif partName == "Body" then return player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
    elseif partName == "Random" then
        local parts = {}
        local h = player.Character:FindFirstChild("Head")
        local r = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
        if h then table.insert(parts, h) end
        if r then table.insert(parts, r) end
        if #parts > 0 then return parts[rand.NextInteger(rand, 1, #parts)] end
    end
    return player.Character:FindFirstChild("Head")
end

local function isTargetVisible(player)
    if not player or not player.Character then return false end
    local part = getAimPart(player, aimPart)
    if not part then return false end
    local camPos = gameCamera.CFrame.Position
    local origin = camPos
    local direction = (part.Position - origin) * 0.999
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {lplr.Character, player.Character}
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil
end

local function lockCameraToTarget(player)
    if not player or not player.Character then return end
    if wallCheckEnabled and not isTargetVisible(player) then return end
    local part = getAimPart(player, aimPart)
    if not part then return end
    local goalCF = CFrame.new(gameCamera.CFrame.Position, part.Position)
    if smoothness >= 0.99 then
        gameCamera.CFrame = goalCF
    else
        gameCamera.CFrame = gameCamera.CFrame:Lerp(goalCF, smoothness)
    end
    if ShowTarget and ShowTarget.Enabled and targetinfo then
        targetinfo.Targets[player] = tick() + 1
    end
end

local function cameraStep()
    if isLobbyVisible() then return end
    local target = getClosestPlayerToMouse()
    if target then lockCameraToTarget(target) end
end

run(function()
    local SilentAim
    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            if callback then
                cameraConnection = runService.Heartbeat:Connect(cameraStep)
            else
                if cameraConnection then cameraConnection:Disconnect(); cameraConnection = nil end
            end
        end,
        Tooltip = 'Locks camera on the closest enemy. No auto‑fire.'
    })

    SilentAim:CreateDropdown({
        Name = 'Aim Part', List = {'Head', 'Body', 'Random'}, Default = 'Head',
        Function = function(val) aimPart = val end,
        Tooltip = 'Part of the body to lock onto'
    })
    SilentAim:CreateSlider({
        Name = 'Smoothness', Min = 1, Max = 100, Default = 100,
        Function = function(val) smoothness = val / 100 end,
        Suffix = '%', Tooltip = '100 = instant, lower = smoother lock'
    })
    SilentAim:CreateToggle({
        Name = 'Wall Check', Default = true,
        Function = function(val) wallCheckEnabled = val end,
        Tooltip = 'Only lock onto targets with clear line of sight'
    })
    ShowTarget = SilentAim:CreateToggle({
        Name = 'Show Target Info', Default = true
    })
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color', Darker = true, Visible = false,
        Function = function(h,s,v) if CircleObject then CircleObject.Color = Color3.fromHSV(h,s,v) end end
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency', Min = 0, Max = 1, Decimal = 10, Default = 0.5,
        Darker = true, Visible = false,
        Function = function(val) if CircleObject then CircleObject.Transparency = 1 - val end end
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled', Darker = true, Visible = false,
        Function = function(callback) if CircleObject then CircleObject.Filled = callback end end
    })
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled and CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor and CircleColor.Hue or 0, CircleColor and CircleColor.Sat or 1, CircleColor and CircleColor.Value or 1)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = 150
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - (CircleTransparency and CircleTransparency.Value or 0.5)
                CircleObject.Visible = SilentAim.Enabled
            else
                pcall(function() CircleObject:Remove() end)
                CircleObject = nil
            end
            if CircleColor then CircleColor.Object.Visible = callback end
            if CircleTransparency then CircleTransparency.Object.Visible = callback end
            if CircleFilled then CircleFilled.Object.Visible = callback end
        end
    })
end)

-- Crosshair
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
                local inline = drawings.lines[idx+4]
                local outline = drawings.outlines[idx]
                local angle = (idx-1)*90 + lastSpinAngle
                local dir = solve(angle,1)
                local fromPos = pos + dir * crosshairRadius
                local toPos = pos + dir * (crosshairRadius + crosshairLength)
                inline.Visible = true; inline.Color = crosshairColor
                inline.From = fromPos; inline.To = toPos; inline.Thickness = crosshairWidth
                if outlineEnabled then
                    outline.Visible = true
                    outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2
                    outline.Color = outlineColor
                end
            end
        elseif crosshairStyle == "Dot" then
            drawings.dot.Visible = true
            drawings.dot.Position = pos
            drawings.dot.Radius = dotSize
            drawings.dot.Filled = true
            drawings.dot.Color = crosshairColor
            drawings.dot.Transparency = 0
        elseif crosshairStyle == "Diagonal" then
            local angles = {45, 135}
            for i = 1, 2 do
                local inline = drawings.lines[i]
                local outline = drawings.outlines[i]
                local angle = angles[i] + lastSpinAngle
                local dir = solve(angle,1)
                inline.Visible = true; inline.Color = crosshairColor
                inline.From = pos + dir * crosshairRadius; inline.To = pos + dir * (crosshairRadius + crosshairLength)
                inline.Thickness = crosshairWidth
                if outlineEnabled then
                    outline.Visible = true
                    outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2
                    outline.Color = outlineColor
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

CrosshairModule:CreateDropdown({ Name = "Style", List = {"Cross", "Dot", "Diagonal"}, Default = "Cross", Function = function(v) crosshairStyle = v end })
CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px", Tooltip="0 = no dot"})
CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})

-- Hitsound
run(function()
    local assetSounds = {
        {name = "Bameware", id = "rbxassetid://3124331820"}, {name = "Bell", id = "rbxassetid://6534947240"},
        {name = "Bubble", id = "rbxassetid://6534947588"}, {name = "Pick", id = "rbxassetid://1347140027"},
        {name = "Pop", id = "rbxassetid://198598793"}, {name = "Rust", id = "rbxassetid://1255040462"},
        {name = "Sans", id = "rbxassetid://3188795283"}, {name = "Fart", id = "rbxassetid://130833677"},
        {name = "Big", id = "rbxassetid://5332005053"}, {name = "Vine", id = "rbxassetid://5332680810"},
        {name = "Bruh", id = "rbxassetid://4578740568"}, {name = "Skeet", id = "rbxassetid://5633695679"},
        {name = "Neverlose", id = "rbxassetid://6534948092"}, {name = "Fatality", id = "rbxassetid://6534947869"},
        {name = "Bonk", id = "rbxassetid://5766898159"}, {name = "Minecraft", id = "rbxassetid://4018616850"},
    }
    local soundNames, soundMap = {}, {}
    for _, s in ipairs(assetSounds) do table.insert(soundNames, s.name); soundMap[s.name] = s.id end

    local hitsoundEnabled = false
    local currentSoundId = soundMap["Bell"]
    local hitConnection = nil

    local function applySoundReplacement()
        if hitConnection then hitConnection:Disconnect() end
        if not hitsoundEnabled then return end
        local viewModel = lplr.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:WaitForChild("ClientViewModel", 5)
        if viewModel then
            hitConnection = viewModel.ChildAdded:Connect(function(v)
                if v:IsA("Sound") and v.SoundId ~= currentSoundId then
                    v.SoundId = currentSoundId; v.Pitch = 1; v.Volume = 1
                end
            end)
        end
    end

    local HitsoundModule = vape.Categories.Utility:CreateModule({
        Name = "Hitsound",
        Function = function(callback)
            hitsoundEnabled = callback
            applySoundReplacement()
            if not callback and hitConnection then hitConnection:Disconnect(); hitConnection = nil end
        end
    })
    HitsoundModule:CreateToggle({Name = "Hitsound", Default = false, Function = function(callback) hitsoundEnabled = callback; applySoundReplacement() end})
    HitsoundModule:CreateDropdown({Name = "Select Sound", List = soundNames, Function = function(val)
        currentSoundId = soundMap[val] or currentSoundId
        applySoundReplacement()
        notif('Hitsound', 'Selected: ' .. val, 2, 'success')
    end})
end)

-- Fullbright
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

-- No Fog
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

-- FOV Changer
run(function()
    local camera = workspace.CurrentCamera
    local defaultVert = 70
    local defaultHoriz = 100
    local vertFOV = defaultVert
    local horizScale = 1.0
    local fovConnection = nil

    local function applyFOV()
        if camera then
            camera.FieldOfView = vertFOV
            if horizScale ~= 1.0 then
                camera.CFrame = camera.CFrame * CFrame.new(0,0,0, 1,0,0, 0, horizScale, 0, 0,0,1)
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

    FovModule:CreateSlider({Name = "Vertical FOV", Min = 10, Max = 120, Default = defaultVert,
        Function = function(v) vertFOV = v end, Suffix = "°"})
    FovModule:CreateSlider({Name = "Horizontal FOV", Min = 50, Max = 120, Default = defaultHoriz,
        Function = function(v) horizScale = v / 100 end, Suffix = "%"})
    FovModule:CreateButton({Name = "Reset FOV", Function = function()
        vertFOV = defaultVert; horizScale = 1.0
        notif('FOV', 'Reset to default (70°, 100%)', 2, 'success')
    end})
end)

-- Ragebot
run(function()
    local RagebotModule = vape.Categories.Blatant:CreateModule({Name = "Ragebot", Function = function(callback) end})

    local strafeEnabled = false
    local strafeSpeed = 10
    local strafeDistance = 8
    local antiVoidEnabled = false
    local resolverEnabled = false
    local lastPos = nil
    local resolverConnection, strafeConnection

    RagebotModule:CreateToggle({Name = "Target Strafe", Default = false, Function = function(v)
        strafeEnabled = v
        if v then
            strafeConnection = runService.Heartbeat:Connect(function()
                if not entitylib.isAlive then return end
                local target = getClosestPlayerToMouse()
                if not target or not target.Character or not target.Character:FindFirstChild("Head") then return end
                local targetHead = target.Character.Head.Position
                local root = entitylib.character.RootPart
                local angle = tick() * strafeSpeed % (math.pi * 2)
                local offset = Vector3.new(math.sin(angle) * strafeDistance, 0, math.cos(angle) * strafeDistance)
                root.CFrame = CFrame.new(targetHead + offset, targetHead)
            end)
        else
            if strafeConnection then strafeConnection:Disconnect(); strafeConnection = nil end
        end
    end})
    RagebotModule:CreateSlider({Name = "Strafe Speed", Min = 1, Max = 30, Default = 10, Function = function(v) strafeSpeed = v end, Suffix = "rad/s"})
    RagebotModule:CreateSlider({Name = "Strafe Distance", Min = 2, Max = 20, Default = 8, Function = function(v) strafeDistance = v end, Suffix = "studs"})

    RagebotModule:CreateToggle({Name = "Anti Void", Default = false, Function = function(v)
        antiVoidEnabled = v
        workspace.FallenPartsDestroyHeight = v and -99999 or 0
    end})

    RagebotModule:CreateToggle({Name = "Position Resolver", Default = false, Function = function(v)
        resolverEnabled = v
        if v then
            resolverConnection = runService.Heartbeat:Connect(function()
                if not entitylib.isAlive then return end
                local root = entitylib.character.RootPart
                if lastPos then
                    local vel = (root.Position - lastPos) * 30
                    root.Velocity = vel
                    root.AssemblyLinerVelocity = vel
                end
                lastPos = root.Position
            end)
        else
            if resolverConnection then resolverConnection:Disconnect(); resolverConnection = nil end
            lastPos = nil
        end
    end})
end)

entitylib.start()

print("Rawr.xyz V4.2.1")
