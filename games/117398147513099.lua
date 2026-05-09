-- FB
if not mouse1click then mouse1click = function() return false end end
if not isrbxactive then isrbxactive = function() return true end end
if not iswindowactive then iswindowactive = function() return true end end
if not mouse1press then mouse1press = function() end end
if not mouse1release then mouse1release = function() end end

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
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    for _, v in coreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
        local obj = v:FindFirstAncestorOfClass('ScreenGui')
        if v.Active and v.Visible and obj and obj.Enabled then
            return false
        end
    end
    local scaledGui = vape.gui.ScaledGui
    local clickGuiVisible = scaledGui and scaledGui.ClickGui and scaledGui.ClickGui.Visible
    return not clickGuiVisible and not inputService:GetFocusedTextBox()
end

for _, v in {'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'} do vape:Remove(v) end

local t = { sa = { target = nil, enabled = false } }

run(function()
    local SilentAim
    local AimPart, Smoothness, ClickInterval
    local CircleColor, CircleTransparency, CircleFilled, CircleObject
    local renderConnection, autoClickConnection = nil, nil
    local isLeftDown, isRightDown = false, false
    local lastClickTime = 0
    local aimPart = "Head"
    local smoothness = 1
    local clickInterval = 0.10
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
        if partName == "Head" then
            return player.Character:FindFirstChild("Head")
        elseif partName == "Body" then
            return player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
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

    local function lockCameraToTarget()
        local target = t.sa.target
        if target and target.Character then
            local part = getAimPart(target, aimPart)
            if part then
                local targetPos = part.Position
                local camPos = gameCamera.CFrame.Position
                local goalCF = CFrame.new(camPos, targetPos)
                if smoothness >= 0.99 then
                    gameCamera.CFrame = goalCF
                else
                    gameCamera.CFrame = gameCamera.CFrame:Lerp(goalCF, smoothness)
                end
            end
        end
    end

    local function startAutoClick()
        if autoClickConnection then autoClickConnection:Disconnect() end
        autoClickConnection = runService.Heartbeat:Connect(function()
            if (isLeftDown or isRightDown) and (tick() - lastClickTime >= clickInterval) then
                if not isLobbyVisible() and canClick() then
                    mouse1click()
                    lastClickTime = tick()
                end
            end
        end)
    end

    local function stopAutoClick()
        if autoClickConnection then
            autoClickConnection:Disconnect()
            autoClickConnection = nil
        end
    end

    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftDown = true
            if SilentAim and SilentAim.Enabled then startAutoClick() end
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightDown = true
            if SilentAim and SilentAim.Enabled then startAutoClick() end
        end
    end)
    inputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isLeftDown = false
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            isRightDown = false
        end
        if not isLeftDown and not isRightDown then
            stopAutoClick()
        end
    end)

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'Silent Aim',
        Function = function(callback)
            if callback then
                renderConnection = runService.RenderStepped:Connect(function()
                    if not isLobbyVisible() then
                        t.sa.target = getClosestPlayerToMouse()
                        if t.sa.target then
                            lockCameraToTarget()
                        end
                    end
                end)
            else
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                stopAutoClick()
                t.sa.target = nil
            end
        end,
        Tooltip = 'Locks camera to the closest enemy. Hold Mouse1/Mouse2 to fire.'
    })

    AimPart = SilentAim:CreateDropdown({
        Name = 'Aim Part',
        List = {'Head', 'Body', 'Random'},
        Default = 'Head',
        Function = function(val) aimPart = val end,
        Tooltip = 'Part of the body to lock onto'
    })
    Smoothness = SilentAim:CreateSlider({
        Name = 'Smoothness',
        Min = 1, Max = 100, Default = 100,
        Function = function(val) smoothness = val / 100 end,
        Suffix = '%',
        Tooltip = '100 = instant, lower = smoother'
    })
    ClickInterval = SilentAim:CreateSlider({
        Name = 'Click Interval',
        Min = 1, Max = 50, Default = 10,
        Function = function(val) clickInterval = val / 100 end,
        Suffix = 'ms',
        Tooltip = 'Time between auto-clicks'
    })

    -- Circle sub-options
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

-- ============== CROSSHAIR ==============
run(function()
    local crosshairEnabled = false
    local crosshairColor = Color3.fromRGB(128,128,128)
    local crosshairSpin = true
    local crosshairLength = 10
    local crosshairRadius = 11
    local crosshairWidth = 1.5
    local dotSize = 0
    local outlineEnabled = false
    local outlineColor = Color3.new(0,0,0)
    local outlineThickness = 0.5
    local drawings = { lines = {}, texts = {}, dot = nil, outlines = {} }
    local renderConnection
    local text_x = 0
    local lastSpinAngle = 0

    local function solve(angle, radius)
        local rad = math.rad(angle)
        return Vector2.new(math.sin(rad)*radius, math.cos(rad)*radius)
    end

    local function createDrawings()
        for i = 1, 8 do drawings.lines[i] = Drawing.new('Line') end
        for i = 1, 4 do drawings.outlines[i] = Drawing.new('Line') end
        drawings.dot = Drawing.new('Circle')
        drawings.texts[1] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rawr.xyz',Color=Color3.new(1,1,1)})
        drawings.texts[2] = Drawing.new('Text', {Size=13,Font=2,Outline=true,Text='Rivals',Color=crosshairColor})
    end

    local function updateCrosshair()
        local pos = inputService:GetMouseLocation()
        drawings.texts[1].Visible = crosshairEnabled
        drawings.texts[2].Visible = crosshairEnabled
        drawings.dot.Visible = crosshairEnabled and dotSize > 0

        if crosshairEnabled then
            if text_x == 0 then text_x = drawings.texts[1].TextBounds.X + drawings.texts[2].TextBounds.X end
            drawings.texts[1].Position = pos + Vector2.new(-text_x/2, crosshairRadius+crosshairLength+15)
            drawings.texts[2].Position = drawings.texts[1].Position + Vector2.new(drawings.texts[1].TextBounds.X, 0)
            drawings.texts[2].Color = crosshairColor

            if crosshairSpin then lastSpinAngle = (tick()*360) % 360 end

            if dotSize > 0 then
                drawings.dot.Position = pos
                drawings.dot.Radius = dotSize
                drawings.dot.Filled = true
                drawings.dot.Color = crosshairColor
                drawings.dot.Transparency = 0
            end

            for idx = 1, 4 do
                local inline = drawings.lines[idx+4]
                local outline = drawings.outlines[idx]
                local angle = (idx-1)*90 + lastSpinAngle
                local dir = solve(angle,1)
                local fromPos = pos + dir * crosshairRadius
                local toPos = pos + dir * (crosshairRadius + crosshairLength)

                inline.Visible = true; inline.Color = crosshairColor
                inline.From = fromPos; inline.To = toPos; inline.Thickness = crosshairWidth

                outline.Visible = outlineEnabled
                if outlineEnabled then
                    outline.From = pos + dir * (crosshairRadius - outlineThickness)
                    outline.To = pos + dir * (crosshairRadius + crosshairLength + outlineThickness)
                    outline.Thickness = crosshairWidth + 1.2
                    outline.Color = outlineColor
                end
            end
        else
            for i = 1, 8 do drawings.lines[i].Visible = false end
            for i = 1, 4 do drawings.outlines[i].Visible = false end
            drawings.dot.Visible = false
        end
    end

    local CrosshairModule = vape.Categories.Utility:CreateModule({
        Name = "Crosshair",
        Function = function(callback)
            crosshairEnabled = callback
            if callback then
                if not drawings.lines[1] then createDrawings() end
                renderConnection = runService.RenderStepped:Connect(updateCrosshair)
            else
                if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
                for _, d in ipairs(drawings.lines) do if d then d.Visible = false end end
                for _, d in ipairs(drawings.outlines) do if d then d.Visible = false end end
                drawings.dot.Visible = false
                drawings.texts[1].Visible = false
                drawings.texts[2].Visible = false
            end
        end
    })

    CrosshairModule:CreateColorSlider({Name="Color", Function=function(h,s,v) crosshairColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateToggle({Name="Spin", Default=true, Function=function(v) crosshairSpin=v end})
    CrosshairModule:CreateSlider({Name="Length", Min=1,Max=30,Default=10, Function=function(v) crosshairLength=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Radius", Min=0,Max=30,Default=11, Function=function(v) crosshairRadius=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Thickness", Min=0.5,Max=5,Default=1.5,Decimal=10, Function=function(v) crosshairWidth=v end, Suffix="px"})
    CrosshairModule:CreateSlider({Name="Dot Size", Min=0,Max=10,Default=0, Function=function(v) dotSize=v end, Suffix="px", Tooltip="0 = no dot"})
    CrosshairModule:CreateToggle({Name="Outline", Default=false, Function=function(v) outlineEnabled=v end})
    CrosshairModule:CreateColorSlider({Name="Outline Color", Visible=false, Function=function(h,s,v) outlineColor=Color3.fromHSV(h,s,v) end})
    CrosshairModule:CreateSlider({Name="Outline Thickness", Min=0,Max=3,Default=0.5,Decimal=10, Visible=false, Function=function(v) outlineThickness=v end, Suffix="px"})
end)

-- ============== FULLBRIGHT ==============
run(function()
    local Lighting = game:GetService("Lighting")
    local origBrightness = Lighting.Brightness
    local origClockTime = Lighting.ClockTime
    local origFogEnd = Lighting.FogEnd
    local origFogStart = Lighting.FogStart
    local origGlobalShadows = Lighting.GlobalShadows
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    vape.Categories.World:CreateModule({
        Name = "Fullbright",
        Function = function(callback)
            if callback then
                Lighting.Brightness = 3
                Lighting.ClockTime = 12
                Lighting.FogEnd = 100000
                Lighting.FogStart = 100000
                Lighting.GlobalShadows = false
                Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                Lighting.Brightness = origBrightness
                Lighting.ClockTime = origClockTime
                Lighting.FogEnd = origFogEnd
                Lighting.FogStart = origFogStart
                Lighting.GlobalShadows = origGlobalShadows
                Lighting.OutdoorAmbient = origOutdoorAmbient
            end
        end
    })
end)

-- ============== NO FOG ==============
run(function()
    local Lighting = game:GetService("Lighting")
    local origFogEnd = Lighting.FogEnd; local origFogStart = Lighting.FogStart
    vape.Categories.World:CreateModule({
        Name = "No Fog",
        Function = function(callback)
            if callback then
                Lighting.FogEnd = 100000; Lighting.FogStart = 100000
            else
                Lighting.FogEnd = origFogEnd; Lighting.FogStart = origFogStart
            end
        end
    })
end)

run(function()
    local camera = workspace.CurrentCamera
    local defaultFOV = 70
    local stretchConnection = nil
    local vertFOV = defaultFOV
    local horizScale = 1.0

    local function applyStretch()
        camera.FieldOfView = vertFOV
        if horizScale ~= 1.0 then
            camera.CFrame = camera.CFrame * CFrame.new(0,0,0, 1,0,0, 0, horizScale, 0, 0,0,1)
        end
    end

    local FovModule = vape.Categories.Utility:CreateModule({
        Name = "FOV",
        Function = function(callback)
            if callback then
                stretchConnection = runService.RenderStepped:Connect(applyStretch)
            else
                if stretchConnection then stretchConnection:Disconnect(); stretchConnection = nil end
                camera.FieldOfView = defaultFOV
            end
        end
    })

    FovModule:CreateSlider({Name="Vertical", Min=10, Max=120, Default=defaultFOV, Function=function(v) vertFOV=v end, Suffix="°", Tooltip="Vertical field of view"})
    FovModule:CreateSlider({Name="Horizontal Scale", Min=50, Max=150, Default=100, Function=function(v) horizScale=v/100 end, Suffix="%", Tooltip="Stretches view horizontally"})
end)

run(function()
    local SpeedModule = vape.Categories.Utility:CreateModule({
        Name = "Speed",
        Function = function(callback)
            if not callback then
                if lplr and lplr.Character then
                    local hum = lplr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end
        end
    })

    SpeedModule:CreateSlider({
        Name = "Walk Speed", Min = 10, Max = 100, Default = 16,
        Function = function(val)
            if entitylib and entitylib.character then
                local hum = entitylib.character.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
        Suffix = "studs/s"
    })

    local cframeEnabled = false
    local cframeMultiplier = 2
    local cframeConnection

    local function cframeBoost()
        if not cframeEnabled then return end
        if entitylib and entitylib.isAlive and entitylib.character and entitylib.character.RootPart then
            local root = entitylib.character.RootPart
            local moveDir = root.CFrame.LookVector * cframeMultiplier * 0.1
            root.CFrame = root.CFrame + moveDir
        end
    end

    SpeedModule:CreateToggle({
        Name = "CFrame Speed",
        Default = false,
        Function = function(callback)
            cframeEnabled = callback
            if callback then
                cframeConnection = runService.Heartbeat:Connect(cframeBoost)
            else
                if cframeConnection then cframeConnection:Disconnect(); cframeConnection = nil end
            end
        end
    })

    SpeedModule:CreateSlider({
        Name = "CFrame Multiplier", Min = 1, Max = 10, Default = 2,
        Darker = true,
        Function = function(v) cframeMultiplier = v end,
        Suffix = "x"
    })
end)

entitylib.start()

print("Rawr.xyz V4.1.3")
