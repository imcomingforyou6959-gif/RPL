--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

-- FB
if not mouse1click then mouse1click = function() return false end end
if not isrbxactive then isrbxactive = function() return true end end
if not iswindowactive then iswindowactive = function() return true end end
if not mouse1press then mouse1press = function() end end
if not mouse1release then mouse1release = function() end end

-- Environment fallbacks
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
    local success, result = pcall(function()
        return game:HttpGet(blacklistUrl)
    end)
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

if checkBlacklist() then
    while true do task.wait(10) end
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
    if not ok then
        notif('Rawr.xyz', desc .. ' failed: ' .. tostring(err), 3, 'alert')
    end
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

-- Cached target detection
local lastTargetUpdate = 0
local cachedTarget = nil
local TARGET_UPDATE_INTERVAL = 0.1

local function scanWorkspace()
    local targets = {}
    for _, v in ipairs(workspace:GetChildren()) do
        if v:FindFirstChildOfClass("Humanoid") then
            table.insert(targets, v)
        elseif v.Name == "HurtEffect" then
            for _, p in ipairs(v:GetChildren()) do
                if p.ClassName ~= "Highlight" then
                    table.insert(targets, p)
                end
            end
        end
    end
    return targets
end

local function getPredictedPosition(player)
    local head = player:FindFirstChild("Head")
    local root = player:FindFirstChild("HumanoidRootPart")
    if not (head and root) then return nil end
    return head.Position
end

local function getClosestTarget()
    if tick() - lastTargetUpdate < TARGET_UPDATE_INTERVAL then
        return cachedTarget
    end
    local target, min = nil, math.huge
    local char = lplr.Character
    if not char then return nil end
    local targets = scanWorkspace()
    for _, p in ipairs(targets) do
        if p ~= char and p:FindFirstChild("HumanoidRootPart") then
            local pos = getPredictedPosition(p)
            if not pos then continue end
            local screen, vis = gameCamera:WorldToViewportPoint(pos)
            if not screen or not vis then continue end
            local screenVec = Vector2.new(screen.X, screen.Y)
            local centerVec = Vector2.new(gameCamera.ViewportSize.X/2, gameCamera.ViewportSize.Y/2)
            local mag = (centerVec - screenVec).Magnitude
            if mag < min then
                target, min = p, mag
            end
        end
    end
    lastTargetUpdate = tick()
    cachedTarget = target
    return target
end

local function showDamage(position, amount)
    local drawing = Drawing.new("Text")
    drawing.Text = tostring(amount)
    drawing.Font = 2
    drawing.Size = 20
    drawing.Color = Color3.fromRGB(255, 80, 80)
    drawing.Position = gameCamera:WorldToViewportPoint(position) + Vector2.new(0, -30)
    drawing.Outline = true
    drawing.Transparency = 1
    drawing.Visible = true
    local tw = tweenService:Create(drawing, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Transparency = 1, Position = drawing.Position + Vector2.new(0, -40)})
    tw:Play()
    tw.Completed:Connect(function() drawing:Remove() end)
end

-- Silent Aim (Raycast hook)
local ShowTarget = nil
local aimPart = "Head"
local hitChance = 100
local clickInterval = 0.10
local autoClickConnection = nil
local isRightDown = false
local lastRightClick = 0
local CircleObject = nil
local CircleColor, CircleTransparency, CircleFilled

run(function()
    local oldRaycast = gameCamera.Raycast
    gameCamera.Raycast = function(...)
        local args = {...}
        if t.sa.enabled and args[4] == 999 then
            if hitChance < 100 and math.random(1, 100) > hitChance then
                return oldRaycast(unpack(args))
            end
            local target = getClosestTarget()
            if target then
                local pos = getPredictedPosition(target)
                if pos then
                    args[3] = pos
                    local tool = lplr.Character and lplr.Character:FindFirstChildOfClass("Tool")
                    local dmg = tool and tool:GetAttribute("Damage") or 20
                    showDamage(pos, dmg)
                    if ShowTarget and ShowTarget.Enabled and targetinfo then
                        targetinfo.Targets[target] = tick() + 1
                    end
                end
            end
        end
        return oldRaycast(unpack(args))
    end
    vape:Clean(function()
        gameCamera.Raycast = oldRaycast
    end)
end)

local function startRightAutoClick()
    if autoClickConnection then autoClickConnection:Disconnect() end
    autoClickConnection = runService.Heartbeat:Connect(function()
        if isRightDown and (tick() - lastRightClick >= clickInterval) then
            if canClick() then
                mouse1click()
                lastRightClick = tick()
            end
        end
    end)
end

local function stopRightAutoClick()
    if autoClickConnection then autoClickConnection:Disconnect(); autoClickConnection = nil end
end

inputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if t.sa.enabled and canClick() then mouse1click() end
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        if not isRightDown then
            isRightDown = true
            if t.sa.enabled then startRightAutoClick() end
        end
    end
end)
inputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isRightDown = false
        stopRightAutoClick()
    end
end)

run(function()
    local SilentAim
    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            t.sa.enabled = callback and true or false
            if not callback then stopRightAutoClick() end
        end,
        Tooltip = 'Fake camera aim – bullets go to the nearest enemy. Left‑click = single, Right‑click = auto.'
    })
    SilentAim:CreateDropdown({
        Name = 'Aim Part', List = {'Head', 'Body', 'Random'}, Default = 'Head',
        Function = function(val) aimPart = val end,
        Tooltip = 'Part of the body to aim at'
    })
    SilentAim:CreateSlider({
        Name = 'Hit Chance', Min = 0, Max = 100, Default = 100,
        Function = function(val) hitChance = val end,
        Suffix = '%', Tooltip = 'Chance to redirect bullets'
    })
    SilentAim:CreateSlider({
        Name = 'Click Interval', Min = 1, Max = 50, Default = 10,
        Function = function(val) clickInterval = val / 100 end,
        Suffix = 'ms', Tooltip = 'Time between auto‑clicks'
    })
    ShowTarget = SilentAim:CreateToggle({
        Name = 'Show Target Info', Default = true,
        Tooltip = 'Display ESP box on target'
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
                CircleObject.Visible = t.sa.enabled
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
local circleThickness = 1.5
local drawings = { lines = {}, texts = {}, dot = nil, outlines = {}, circle = nil }
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
    drawings.circle = Drawing.new('Circle')
    drawings.texts[1] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=Color3.new(1,1,1)})
    drawings.texts[2] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rivals',Color=crosshairColor})
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
        if drawings.circle then drawings.circle.Visible = false end

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
        elseif crosshairStyle == "Circle" then
            drawings.circle.Visible = true
            drawings.circle.Position = pos
            drawings.circle.Radius = crosshairRadius
            drawings.circle.Filled = false
            drawings.circle.Color = crosshairColor
            drawings.circle.Thickness = circleThickness
            drawings.circle.Transparency = 0
        elseif crosshairStyle == "Dot" then
            drawings.dot.Visible = true
            drawings.dot.Position = pos
            drawings.dot.Radius = dotSize
            drawings.dot.Filled = true
            drawings.dot.Color = crosshairColor
            drawings.dot.Transparency = 0
        end
    else
        for i = 1, 8 do if drawings.lines[i] then drawings.lines[i].Visible = false end end
        for i = 1, 4 do if drawings.outlines[i] then drawings.outlines[i].Visible = false end end
        if drawings.dot then drawings.dot.Visible = false end
        if drawings.circle then drawings.circle.Visible = false end
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
            if drawings.circle then drawings.circle.Visible = false end
        end
    end
})

CrosshairModule:CreateDropdown({
    Name = "Style", List = {"Cross", "Circle", "Dot"}, Default = "Cross",
    Function = function(v) crosshairStyle = v end
})
CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth = v; circleThickness = v end, Suffix="px"})
CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px", Tooltip="0 = no dot"})
CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})

local HitsoundModule
run(function()
    local assetSounds = {
        {name = "Bameware", id = "rbxassetid://3124331820"},
        {name = "Bell", id = "rbxassetid://6534947240"},
        {name = "Bubble", id = "rbxassetid://6534947588"},
        {name = "Pick", id = "rbxassetid://1347140027"},
        {name = "Pop", id = "rbxassetid://198598793"},
        {name = "Rust", id = "rbxassetid://1255040462"},
        {name = "Sans", id = "rbxassetid://3188795283"},
        {name = "Fart", id = "rbxassetid://130833677"},
        {name = "Big", id = "rbxassetid://5332005053"},
        {name = "Vine", id = "rbxassetid://5332680810"},
        {name = "Bruh", id = "rbxassetid://4578740568"},
        {name = "Skeet", id = "rbxassetid://5633695679"},
        {name = "Neverlose", id = "rbxassetid://6534948092"},
        {name = "Fatality", id = "rbxassetid://6534947869"},
        {name = "Bonk", id = "rbxassetid://5766898159"},
        {name = "Minecraft", id = "rbxassetid://4018616850"},
    }

    local soundNames = {}
    local soundMap = {}
    for _, s in ipairs(assetSounds) do
        table.insert(soundNames, s.name)
        soundMap[s.name] = s.id
    end

    local hitsoundEnabled = false
    local currentSoundId = soundMap["Bell"]
    local hitConnection = nil

    local function applySoundReplacement()
        if hitConnection then hitConnection:Disconnect() end
        if not hitsoundEnabled then return end
        local playerScripts = lplr:WaitForChild("PlayerScripts", 5)
        if not playerScripts then return end
        local modules = playerScripts:WaitForChild("Modules", 5)
        if not modules then return end
        local clientRep = modules:WaitForChild("ClientReplicatedClasses", 5)
        if not clientRep then return end
        local fighter = clientRep:WaitForChild("ClientFighter", 5)
        if not fighter then return end
        local clientItem = fighter:WaitForChild("ClientItem", 5)
        if not clientItem then return end
        local viewModel = clientItem:WaitForChild("ClientViewModel", 5)
        if not viewModel then return end

        hitConnection = viewModel.ChildAdded:Connect(function(v)
            if v:IsA("Sound") and v.SoundId ~= currentSoundId then
                v.SoundId = currentSoundId
                v.Pitch = 1
                v.Volume = 1
            end
        end)
    end

    HitsoundModule = vape.Categories.Utility:CreateModule({
        Name = "Hitsound",
        Function = function(callback)
            hitsoundEnabled = callback
            applySoundReplacement()
            if not callback and hitConnection then
                hitConnection:Disconnect()
                hitConnection = nil
            end
        end
    })

    HitsoundModule:CreateToggle({
        Name = "Hitsound",
        Default = false,
        Function = function(callback) hitsoundEnabled = callback; applySoundReplacement() end
    })

    HitsoundModule:CreateDropdown({
        Name = "Select Sound",
        List = soundNames,
        Function = function(val)
            local id = soundMap[val]
            if id then
                currentSoundId = id
                applySoundReplacement()
                notif('Hitsound', 'Selected: ' .. val, 2, 'success')
            end
        end
    })
end)

-- Fullbright
run(function()
    local Lighting = game:GetService("Lighting")
    local origBrightness = Lighting.Brightness; local origClockTime = Lighting.ClockTime
    local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart
    local origGlobalShadows = Lighting.GlobalShadows; local origOutdoorAmbient = Lighting.OutdoorAmbient
    vape.Categories.World:CreateModule({
        Name = "Fullbright",
        Function = function(callback)
            if callback then
                Lighting.Brightness = 3; Lighting.ClockTime = 12
                Lighting.FogEnd = 100000; Lighting.FogStart = 100000
                Lighting.GlobalShadows = false; Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = origBrightness; Lighting.ClockTime = origClockTime
                Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart
                Lighting.GlobalShadows = origGlobalShadows; Lighting.OutdoorAmbient = origOutdoorAmbient
            end
        end
    })
end)

-- No Fog
run(function()
    local Lighting = game:GetService("Lighting")
    local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart
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
    local defaultFOV = 70
    local targetFOV = defaultFOV
    local currentFOV = defaultFOV
    local FOV_LERP_SPEED = 0.1
    local fovConnection = nil

    local function applyFOV()
        if camera then
            if math.abs(currentFOV - targetFOV) > 0.1 then
                currentFOV = currentFOV + (targetFOV - currentFOV) * FOV_LERP_SPEED
                camera.FieldOfView = currentFOV
            else
                camera.FieldOfView = targetFOV
                currentFOV = targetFOV
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
                if camera then camera.FieldOfView = defaultFOV end
            end
        end
    })

    FovModule:CreateSlider({
        Name = "Vertical FOV",
        Min = 10, Max = 120, Default = defaultFOV,
        Function = function(v) targetFOV = v end,
        Suffix = "°"
    })
end)

entitylib.start()

print("Rawr.xyz V4.1.9")
