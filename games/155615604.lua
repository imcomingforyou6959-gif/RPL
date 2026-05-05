--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.

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
local teamService = cloneref(game:GetService('Teams'))
local workspaceService = cloneref(game:GetService('Workspace'))
local replicatedStorageService = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local guiService = cloneref(game:GetService('GuiService'))
local vimService = cloneref(game:GetService('VirtualInputManager'))
local playerGui = cloneref(playersService.LocalPlayer:WaitForChild("PlayerGui"))

local guardsTeam = teamService.Guards
local criminalsTeam = teamService.Criminals
local inmatesTeam = teamService.Inmates
local neutralTeam = teamService.Neutral

local remotes = replicatedStorageService:WaitForChild("Remotes")
local gunRemotes = replicatedStorageService:WaitForChild("GunRemotes")

local ShootEvent = gunRemotes:WaitForChild("ShootEvent")

local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo

local function notif(...) return vape:CreateNotification(...) end

if identifyexecutor then
    local execName = ({identifyexecutor()})[1]
    local allowed = {Madium = true, Velocity = true, Sirhurt = true, Volt = true, LX63 = true}
    if not allowed[execName] then
        notif('Rawr.xyz', 'Your Executor is too bad to use all features :(', 10, 'alert')
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

for _, v in {
    'SilentAim', 'Reach', 'AntiFall', 'Killaura', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot'
} do vape:Remove(v) end

local t = {
    d = {l = CFrame.new(), s = CFrame.new()},
    bt = {m = false, q = false, p = Vector3.new()},
    sa = {hooks = {}, toggle = nil},
    hn = {e = false}
}

run(function()
    local oldHumanoidNewindex
    oldHumanoidNewindex = hookmetamethod(game, "__newindex", newcclosure(function(self, key, value)
        if typeof(self) == "Instance" and self:IsA("Humanoid") then
            if key == "Jump" and value == false then
                local parent = self.Parent
                if parent and parent:IsA("Model") and parent == lplr.Character then
                    return
                end
            end
        end
        return oldHumanoidNewindex(self, key, value)
    end))
    vape:Clean(function()
        hookmetamethod(game, "__newindex", oldHumanoidNewindex)
    end)
end)

run(function()
    vape:Clean(runService.Heartbeat:Connect(function()
        if lplr and lplr.Character then
            local character = lplr.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and t.d.s ~= CFrame.new() then
                t.d.l = root.CFrame
                root.CFrame = t.d.s
                runService.RenderStepped:Wait()
                if root and character.Parent then
                    root.CFrame = t.d.l
                end
            end
        end
    end))

    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if t.d.s ~= CFrame.new() and not checkcaller() and key == "CFrame" then
            local char = lplr and lplr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp and self == hrp then
                return t.d.l
            end
        end
        return old(self, key)
    end))

    vape:Clean(function() hookmetamethod(game, "__index", old) end)
end)

run(function()
    vape:Clean(gameCamera.ChildAdded:Connect(function(child)
        if typeof(child.Transparency) == "number" then
            child.Transparency = 1
        end
        if child.Name ~= "RayPart" or not child:IsA("BasePart") or not t.bt.m then
            if typeof(child.Transparency) == "number" then
                child.Transparency = 0
            end
            return
        end

        task.spawn(function()
            task.wait()

            local length = child.Size.Z
            local lookVector = child.CFrame.LookVector
            local mid = child.CFrame.Position

            local start = mid - lookVector * (length / 2)
            if entitylib and entitylib.character and entitylib.character.RootPart then
                local dist = (start - entitylib.character.RootPart.Position).Magnitude
                if dist > 5 then return end
            end

            local newEnd = t.bt.p
            local newLength = (newEnd - start).Magnitude
            local newMid = (start + newEnd) / 2

            child.Size = Vector3.new(child.Size.X, child.Size.Y, newLength)
            child.CFrame = CFrame.new(newMid, newEnd)

            if t.bt.q == false then
                t.bt.q = true
                task.delay(1, function()
                    t.bt.m = false
                    t.bt.q = false
                end)
            end
        end)

        child.Transparency = 0
    end))
end)

run(function()
    local old

    old = hookmetamethod(game, '__namecall', function(self, ...)
        if getnamecallmethod() ~= "FireServer" or self ~= ShootEvent then
            return old(self, ...)
        end
        if checkcaller() then return old(self, ...) end

        local args = {...}
        if typeof(args[1]) == "table" and t.sa.hooks.PrisonLife then
            t.sa.hooks.PrisonLife(args)
        end

        return old(self, unpack(args))
    end)

    vape:Clean(function() hookmetamethod(game, "__namecall", old) end)
end)

local teamLookup = {}
local nameLookup = {}

local function loadTeamMembers()
    local url = "https://raw.githubusercontent.com/imcomingforyou6959-gif/whitelists/refs/heads/main/Team.json?t=" .. tick()
    local suc, res = pcall(function() return game:HttpGet(url) end)
    if not suc then return end
    local ok, data = pcall(game.HttpService.JSONDecode, game:GetService("HttpService"), res)
    if not ok or not data or type(data.TeamMembers) ~= "table" then return end
    teamLookup = {}
    nameLookup = {}
    for _, mem in ipairs(data.TeamMembers) do
        if mem.userId then
            teamLookup[mem.userId] = mem
        end
        if mem.username then
            nameLookup[mem.username:lower()] = mem
        end
    end
end

loadTeamMembers()

local function attachNametag(char, role)
    if not char then return end
    local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 5)
    if not head then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = false
    billboard.MaxDistance = 100
    billboard.Parent = char

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "Rawr.xyz | " .. (role or "Team")
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.TextStrokeTransparency = 0.2
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Parent = billboard

    local conn = runService.Heartbeat:Connect(function()
        if billboard and billboard.Parent then
            local t = tick() * 0.8
            local factor = (math.sin(t) + 1) / 2
            label.TextColor3 = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 255, 255), factor)
        elseif conn then
            conn:Disconnect()
        end
    end)

    char.Destroying:Connect(function()
        if billboard then
            billboard:Destroy()
        end
        if conn then
            conn:Disconnect()
        end
    end)
end

local function isTeamMember(player)
    if teamLookup[player.UserId] then
        return teamLookup[player.UserId]
    end
    local name = player.Name:lower()
    if nameLookup[name] then
        return nameLookup[name]
    end
    return nil
end

local function onPlayerDetected(player)
    local info = isTeamMember(player)
    if not info then return end
    notif('Rawr.xyz', 'A Rawr.xyz ' .. info.role .. ' is in the game | ' .. player.Name, 5, 'success')
    if player.Character then attachNametag(player.Character, info.role) end
    player.CharacterAdded:Connect(function(char) attachNametag(char, info.role) end)
end

for _, player in ipairs(playersService:GetPlayers()) do
    onPlayerDetected(player)
end
playersService.PlayerAdded:Connect(onPlayerDetected)

run(function()
    local GunTracers = require(replicatedStorageService:WaitForChild("SharedModules"):WaitForChild("GunTracers"))
    local originalCreateTaser = GunTracers and GunTracers.createTaser or function() end
    local originalCreateSniper = GunTracers and GunTracers.createSniper or function() end
    local originalCreateBullet = GunTracers and GunTracers.createBullet or function() end

    local debris = game:GetService("Debris")
    local tweenService = game:GetService("TweenService")

    local taserColor = Color3.fromRGB(0, 234, 255)
    local sniperColor = Color3.fromRGB(255, 50, 50)
    local bulletColor = Color3.fromRGB(255, 255, 0)

    local customColorsEnabled = false
    local showTracersEnabled = true

    local function createColoredTracer(startPos, endPos, color, sizeThickness, duration, hasLight)
        if not startPos or not endPos or not color then return end
        local distance = (endPos - startPos).magnitude
        local midPoint = (startPos + endPos) / 2

        local part = Instance.new("Part")
        part.Name = "CustomRayPart"
        part.Material = Enum.Material.Neon
        part.Anchored = true
        part.Transparency = 0.5
        part.formFactor = Enum.FormFactor.Custom
        part.Size = Vector3.new(sizeThickness, sizeThickness, distance)
        part.CFrame = CFrame.new(midPoint, endPos)
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.Color = color
        part.Parent = workspace.CurrentCamera

        if hasLight then
            local light = Instance.new("SurfaceLight", part)
            light.Color = color
            light.Range = 7
            light.Face = "Bottom"
            light.Brightness = 5
            light.Angle = 180
            tweenService:Create(light, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Brightness = 0}):Play()
        end

        tweenService:Create(part, TweenInfo.new(duration or 1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
        debris:AddItem(part, duration or 2)
    end

    local function customCreateTaser(startPos, endPos)
        createColoredTracer(startPos, endPos, taserColor, 0.2, 2, true)
    end

    local function customCreateSniper(startPos, endPos)
        createColoredTracer(startPos, endPos, sniperColor, 0.17, 4, false)
    end

    local function customCreateBullet(startPos, endPos)
        createColoredTracer(startPos, endPos, bulletColor, 0.1, 0.05, false)
    end

    local function emptyTracer() end

    local function updateTracerFunctions()
        if not GunTracers then return end
        if not showTracersEnabled then
            GunTracers.createTaser = emptyTracer
            GunTracers.createSniper = emptyTracer
            GunTracers.createBullet = emptyTracer
        elseif customColorsEnabled then
            GunTracers.createTaser = customCreateTaser
            GunTracers.createSniper = customCreateSniper
            GunTracers.createBullet = customCreateBullet
        else
            GunTracers.createTaser = originalCreateTaser
            GunTracers.createSniper = originalCreateSniper
            GunTracers.createBullet = originalCreateBullet
        end
    end

    local TracerVisuals = vape.Categories.Utility:CreateModule({
        Name = "Bullet Tracers",
        Function = function(callback)
            if callback then
                updateTracerFunctions()
            else
                if GunTracers then
                    GunTracers.createTaser = originalCreateTaser
                    GunTracers.createSniper = originalCreateSniper
                    GunTracers.createBullet = originalCreateBullet
                end
            end
        end
    })

    TracerVisuals:CreateToggle({
        Name = "Show Tracers",
        Default = true,
        Function = function(callback)
            showTracersEnabled = callback
            updateTracerFunctions()
        end
    })

    local TaserColorSlider = TracerVisuals:CreateColorSlider({
        Name = "Taser Color",
        Function = function(hue, sat, val)
            taserColor = Color3.fromHSV(hue, sat, val)
            if customColorsEnabled and showTracersEnabled then
                updateTracerFunctions()
            end
        end
    })
    local SniperColorSlider = TracerVisuals:CreateColorSlider({
        Name = "Sniper Color",
        Function = function(hue, sat, val)
            sniperColor = Color3.fromHSV(hue, sat, val)
            if customColorsEnabled and showTracersEnabled then
                updateTracerFunctions()
            end
        end
    })
    local BulletColorSlider = TracerVisuals:CreateColorSlider({
        Name = "Bullet Color",
        Function = function(hue, sat, val)
            bulletColor = Color3.fromHSV(hue, sat, val)
            if customColorsEnabled and showTracersEnabled then
                updateTracerFunctions()
            end
        end
    })

    TaserColorSlider.Object.Visible = false
    SniperColorSlider.Object.Visible = false
    BulletColorSlider.Object.Visible = false

    TracerVisuals:CreateToggle({
        Name = "Custom Colors",
        Default = false,
        Function = function(callback)
            customColorsEnabled = callback
            TaserColorSlider.Object.Visible = callback
            SniperColorSlider.Object.Visible = callback
            BulletColorSlider.Object.Visible = callback
            updateTracerFunctions()
        end
    })
end)

run(function()
    local RequestTeamChange = remotes:WaitForChild("RequestTeamChange")
    local Shippingcontainers = workspaceService:WaitForChild("Shippingcontainers")
    local TeamSwitcher
    local Team

    TeamSwitcher = vape.Categories.Utility:CreateModule({
        Name = "TeamSwitcher",
        Function = function(callback)
            if callback == true then
                notif('Rawr.xyz', 'Please expand this module to use it', 3, 'alert')
                TeamSwitcher:Toggle()
            end
        end
    })
    Team = TeamSwitcher:CreateDropdown({
        Name = "Select Team",
        List = {"Criminals", "Inmates", "Guards", "Neutral"},
        Tooltip = "Select a team to switch to"
    })
    TeamSwitcher:CreateButton({
        Name = "Switch",
        Function = function()
            local team = Team.Value
            if team == "Neutral" then
                safeCall('Team switch (Neutral)', function() RequestTeamChange:InvokeServer(neutralTeam, 1) end)
            elseif team == "Guards" then
                safeCall('Team switch (Neutral->Guards)', function() RequestTeamChange:InvokeServer(neutralTeam, 1) end)
                task.wait(1.5)
                safeCall('Team switch (Guards)', function() RequestTeamChange:InvokeServer(guardsTeam, 1) end)
                task.delay(1, function()
                    if lplr and lplr.Team ~= guardsTeam then
                        notif('Rawr.xyz', 'Failed to switch to guards team, please try again later', 3, 'alert')
                    end
                end)
            elseif team == "Criminals" then
                if lplr and lplr.Team == inmatesTeam and Shippingcontainers then
                    local startTime = tick()
                    repeat
                        t.d.s = Shippingcontainers.WorldPivot
                        task.wait(0.05)
                    until lplr.Team == criminalsTeam or tick()-startTime > 10 or not lplr.Parent
                    t.d.s = CFrame.new()
                else
                    notif('Rawr.xyz', 'Please switch to the inmates team and try again', 3, 'alert')
                end
            elseif team == "Inmates" then
                safeCall('Team switch (Neutral)', function() RequestTeamChange:InvokeServer(neutralTeam, 1) end)
                task.wait(1.5)
                safeCall('Team switch (Inmates)', function() RequestTeamChange:InvokeServer(inmatesTeam, 1) end)
                task.delay(1, function()
                    if lplr and lplr.Team ~= inmatesTeam then
                        notif('Rawr.xyz', 'Failed to switch to inmates team, please try again later', 3, 'alert')
                    end
                end)
            end
        end
    })
end)

entitylib.start()

run(function()
    local AutoReload
    local AutoSwitch
    local reloadConnection
    local backpackConn
    local toolConns = {}

    local OwnShotgun = false
    local OwnSniper = false
    local Shotgun = nil
    local Sniper = nil

    local function reload()
        vimService:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        vimService:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end

    local function getAmmoOrReloading(v)
        if not v then return end
        local reloading = v:GetAttribute("Local_ReloadSession")
        if reloading and reloading == 0 then return true end
        local ammo = v:GetAttribute("Local_CurrentAmmo")
        local maxAmmo = v:GetAttribute("MaxAmmo")
        local serverAmmo = v:GetAttribute("CurrentAmmo")
        if ammo and ammo > 0 or (ammo == 0 and serverAmmo == maxAmmo) then
            return true
        end
    end

    local function getToolWithAmmo()
        if not entitylib.isAlive then return end
        local backpack = lplr and lplr:FindFirstChildOfClass("Backpack")
        local character = entitylib.character and entitylib.character.Character
        if not backpack or not character then return end

        if OwnSniper and Sniper and getAmmoOrReloading(Sniper) then
            character.Humanoid:UnequipTools()
            character.Humanoid:EquipTool(Sniper)
            return
        end

        if OwnShotgun and Shotgun and getAmmoOrReloading(Shotgun) then
            character.Humanoid:UnequipTools()
            character.Humanoid:EquipTool(Shotgun)
            return
        end

        for _, v in pairs(backpack:GetChildren()) do
            if v and v:IsA("Tool") and v.Name ~= "Taser" and getAmmoOrReloading(v) then
                character.Humanoid:UnequipTools()
                character.Humanoid:EquipTool(v)
                return
            end
        end
    end

    local function clearToolConns()
        if toolConns then
            for _, conn in pairs(toolConns) do
                conn:Disconnect()
            end
            table.clear(toolConns)
        end
    end

    local function itemAdded(v)
        if not v or not v:IsA("Tool") then return end
        local behavior = v:GetAttribute("Behavior")
        if behavior == "Sniper" then
            OwnSniper = true
            Sniper = v
        elseif behavior == "Shotgun" then
            OwnShotgun = true
            Shotgun = v
        end

        if toolConns[v] then toolConns[v]:Disconnect() end

        local conn = v:GetAttributeChangedSignal("Local_CurrentAmmo"):Connect(function()
            if not entitylib.isAlive then return end
            local ammo = v:GetAttribute("Local_CurrentAmmo")
            if ammo and ammo <= 0 then
                reload()
                if AutoSwitch and AutoSwitch.Enabled and v.Name ~= "Taser" then
                    local attempts = 0
                    repeat
                        getToolWithAmmo()
                        task.wait()
                        attempts = attempts + 1
                    until (entitylib.character and entitylib.character.Character and
                           entitylib.character.Character:FindFirstChildOfClass("Tool") and
                           entitylib.character.Character:FindFirstChildOfClass("Tool"):GetAttribute("Local_CurrentAmmo") and
                           entitylib.character.Character:FindFirstChildOfClass("Tool"):GetAttribute("Local_CurrentAmmo") > 0)
                           or attempts > 10
                end
            end
        end)

        toolConns[v] = conn

        v.Destroying:Connect(function()
            if toolConns and toolConns[v] then
                toolConns[v]:Disconnect()
                toolConns[v] = nil
            end
        end)
    end

    local function characterAdded(char)
        clearToolConns()
        if backpackConn then backpackConn:Disconnect() end
        if lplr and lplr.Backpack then
            backpackConn = lplr.Backpack.ChildAdded:Connect(function(child)
                itemAdded(child)
            end)
        end
        local character = char and char.Character
        if character then
            local children = character:GetChildren()
            for i = 1, #children do itemAdded(children[i]) end
        end
        local backpack = lplr and lplr.Backpack
        if backpack then
            local children = backpack:GetChildren()
            for i = 1, #children do itemAdded(children[i]) end
        end

        OwnShotgun = false
        OwnSniper = false
        Sniper = nil
        Shotgun = nil
    end

    AutoReload = vape.Categories.Combat:CreateModule({
        Name = "AutoReload",
        Function = function(callback)
            if callback then
                reloadConnection = entitylib.Events.LocalAdded:Connect(function(newChar)
                    characterAdded(newChar)
                end)
                if entitylib and entitylib.isAlive then
                    characterAdded(entitylib.character)
                end
            else
                if reloadConnection then reloadConnection:Disconnect() end
                if backpackConn then backpackConn:Disconnect() end
                clearToolConns()
            end
        end
    })
    AutoSwitch = AutoReload:CreateToggle({
        Name = "AutoSwitch",
        Tooltip = "Auto switches to a gun with ammo. Forces you to always hold a gun."
    })
end)

run(function()
    local crosshairEnabled = false
    local crosshairColor = Color3.fromRGB(128, 128, 128)
    local crosshairSpin = true
    local crosshairLength = 10
    local crosshairRadius = 11
    local crosshairWidth = 1.5
    local drawings = { lines = {}, texts = {} }
    local renderConnection
    local text_x = 0
    local lastSpinAngle = 0

    -- Simplified solve: no caching, very cheap
    local function solve(angle, radius)
        local rad = math.rad(angle)
        return Vector2.new(math.sin(rad) * radius, math.cos(rad) * radius)
    end

    local function createDrawings()
        for i = 1, 8 do
            drawings.lines[i] = Drawing.new('Line')
        end
        drawings.texts[1] = Drawing.new('Text', {
            Size = 13, Font = 2, Outline = true,
            Text = 'Made with love |',
            Color = Color3.new(1, 1, 1)
        })
        drawings.texts[2] = Drawing.new('Text', {
            Size = 13, Font = 2, Outline = true,
            Text = 'Rawr.xyz',
            Color = crosshairColor
        })
        text_x = drawings.texts[1].TextBounds.X + drawings.texts[2].TextBounds.X
    end

    local function updateCrosshair()
        local pos = inputService:GetMouseLocation()
        drawings.texts[1].Visible = crosshairEnabled
        drawings.texts[2].Visible = crosshairEnabled

        if crosshairEnabled then
            if text_x == 0 then
                text_x = drawings.texts[1].TextBounds.X + drawings.texts[2].TextBounds.X
            end
            drawings.texts[1].Position = pos + Vector2.new(-text_x / 2, crosshairRadius + crosshairLength + 15)
            drawings.texts[2].Position = drawings.texts[1].Position + Vector2.new(drawings.texts[1].TextBounds.X, 0)
            drawings.texts[2].Color = crosshairColor

            if crosshairSpin then
                lastSpinAngle = (tick() * 360) % 360
            end

            for idx = 1, 4 do
                local outline = drawings.lines[idx]
                local inline = drawings.lines[idx + 4]
                local angle = (idx - 1) * 90 + lastSpinAngle

                local dir = solve(angle, 1)
                local fromPos = pos + dir * crosshairRadius
                local toPos = pos + dir * (crosshairRadius + crosshairLength)
                local outlineFrom = pos + dir * (crosshairRadius - 1)
                local outlineTo = pos + dir * (crosshairRadius + crosshairLength + 1)

                inline.Visible = true
                inline.Color = crosshairColor
                inline.From = fromPos
                inline.To = toPos
                inline.Thickness = crosshairWidth

                outline.Visible = true
                outline.From = outlineFrom
                outline.To = outlineTo
                outline.Thickness = crosshairWidth + 1.5
            end
        else
            for i = 1, 8 do
                drawings.lines[i].Visible = false
            end
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
                if renderConnection then
                    renderConnection:Disconnect()
                    renderConnection = nil
                end
                for _, d in ipairs(drawings.lines) do if d then d.Visible = false end end
                for _, d in ipairs(drawings.texts) do if d then d.Visible = false end end
            end
        end
    })

    CrosshairModule:CreateColorSlider({
        Name = "Color",
        Function = function(hue, sat, val)
            crosshairColor = Color3.fromHSV(hue, sat, val)
        end
    })
    CrosshairModule:CreateToggle({
        Name = "Spin",
        Default = true,
        Function = function(val)
            crosshairSpin = val
        end
    })
    CrosshairModule:CreateSlider({
        Name = "Length",
        Min = 1, Max = 30, Default = 10,
        Function = function(val) crosshairLength = val end,
        Suffix = "px"
    })
    CrosshairModule:CreateSlider({
        Name = "Radius",
        Min = 0, Max = 30, Default = 11,
        Function = function(val) crosshairRadius = val end,
        Suffix = "px"
    })
    CrosshairModule:CreateSlider({
        Name = "Width",
        Min = 0.5, Max = 5, Default = 1.5, Decimal = 10,
        Function = function(val) crosshairWidth = val end,
        Suffix = "px"
    })
end)

run(function()
    local faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"}
    local defaultMaterials = {
        {"Wood", "3258599312"}, {"WoodPlanks", "8676581022"},
        {"Brick", "8558400252"}, {"Cobblestone", "5003953441"},
        {"Concrete", "7341687607"}, {"DiamondPlate", "6849247561"},
        {"Fabric", "118776397"}, {"Granite", "4722586771"},
        {"Grass", "4722588177"}, {"Ice", "3823766459"},
        {"Marble", "62967586"}, {"Metal", "62967586"},
        {"Sand", "152572215"}
    }
    local customMaterials = {
        {"Wood", "17205543533"}, {"WoodPlanks", "17205543533"},
        {"Brick", "17205598389"}, {"Cobblestone", "17386745691"},
        {"Concrete", "17386745691"}, {"DiamondPlate", "17372377849"},
        {"Fabric", "14003986744"}, {"Granite", "17205543533"},
        {"Grass", "17372377849"}, {"Ice", "15342433592"},
        {"Marble", "15342683277"}, {"Metal", "17372377849"},
        {"Sand", "17372377849"}, {"Slate", "17205627296"}
    }
    local currentSet = "Default"
    local activeMaterials = defaultMaterials
    local texturedParts = {}

    local function applyTexture(part)
        if not part or not part:IsA("BasePart") then return end
        if texturedParts[part] then return end
        local matName = part.Material.Name
        for _, mat in ipairs(activeMaterials) do
            if matName == mat[1] then
                part:SetAttribute("OriginalMaterial", matName)
                for _, faceName in ipairs(faces) do
                    local texture = Instance.new("Texture")
                    texture.Name = "MC_Tex"
                    texture.ZIndex = 2147483647
                    texture.Texture = "rbxassetid://" .. mat[2]
                    texture.Face = Enum.NormalId[faceName]
                    texture.Color3 = part.Color
                    texture.Transparency = part.Transparency
                    texture.Parent = part
                end
                part.Material = "SmoothPlastic"
                part:SetAttribute("MC_Textured", true)
                texturedParts[part] = true
                break
            end
        end
    end

    local function revertTexture(part)
        if texturedParts[part] then
            for _, child in ipairs(part:GetChildren()) do
                if child:IsA("Texture") and child.Name == "MC_Tex" then
                    child:Destroy()
                end
            end
            local origMat = part:GetAttribute("OriginalMaterial")
            if origMat then
                local mat = Enum.Material[origMat]
                if mat then
                    part.Material = mat
                end
            end
            part:SetAttribute("MC_Textured", nil)
            part:SetAttribute("OriginalMaterial", nil)
            texturedParts[part] = nil
        end
    end

    local TexturesModule = vape.Categories.Utility:CreateModule({
    Name = "World Textures",
    Function = function(callback)
        if callback then
            for _, part in ipairs(workspace:GetDescendants()) do
                applyTexture(part)
            end
            local conn; conn = workspace.DescendantAdded:Connect(applyTexture)
            -- Store connection so we can clean it later
            TexturesModule.Conn = conn
        else
            if TexturesModule.Conn then
                TexturesModule.Conn:Disconnect()
                TexturesModule.Conn = nil
            end
            for part in pairs(texturedParts) do
                revertTexture(part)
            end
        end
    end
})

    TexturesModule:CreateDropdown({
        Name = "Texture Set",
        List = {"Default", "Custom"},
        Function = function(val)
            if val == "Default" then
                activeMaterials = defaultMaterials
            else
                activeMaterials = customMaterials
            end
            if TexturesModule.Enabled then
                for part in pairs(texturedParts) do
                    revertTexture(part)
                end
                for _, part in ipairs(workspace:GetDescendants()) do
                    applyTexture(part)
                end
            end
        end
    })

    TexturesModule:CreateButton({
        Name = "Reapply Textures",
        Function = function()
            if TexturesModule.Enabled then
                for part in pairs(texturedParts) do
                    revertTexture(part)
                end
                for _, part in ipairs(workspace:GetDescendants()) do
                    applyTexture(part)
                end
            end
        end
    })
end)

run(function()
    local SilentAim
    local Target
    local Mode
    local Range
    local HitChance
    local HeadshotChance
    local AutoFire
    local AutoFireShootDelay
    local CircleColor
    local CircleTransparency
    local CircleFilled
    local CircleObject
    local Face
    local ShowTarget
    local filterTeamSA
    local TeamFilterSA
    local rand = Random.new()
    local delayCheck = tick()
    local GunTracers = require(replicatedStorageService:WaitForChild("SharedModules"):WaitForChild("GunTracers"))
    local hud = playerGui:FindFirstChild("Home") and playerGui.Home:FindFirstChild("Hud")
    local Method
    local mouseClicked = false
    local renderStepConnection

    local function tryShoot(origin, targetPart, tool)
        if not tool or not targetPart or not targetPart.Position then return end
        local ammo = tool:GetAttribute("Local_CurrentAmmo")
        if not ammo or ammo <= 0 then return end
        local reloadSession = tool:GetAttribute("Local_ReloadSession")
        if reloadSession and reloadSession > 0 then return end

        tool:SetAttribute("Local_IsShooting", true)
        local projectileCount = tool:GetAttribute("ProjectileCount") or 1
        local hits = {}
        local lastBehavior
        for _ = 1, projectileCount do
            local muzzle = (tool:FindFirstChild("muzzle") and tool.muzzle.Position) or origin
            lastBehavior = tool:GetAttribute("Behavior")
            if GunTracers then
                if lastBehavior == "Sniper" and GunTracers.createSniper then
                    GunTracers.createSniper(muzzle, targetPart.Position)
                elseif lastBehavior == "Taser" and GunTracers.createTaser then
                    GunTracers.createTaser(muzzle, targetPart.Position)
                else
                    if GunTracers.createBullet then
                        GunTracers.createBullet(muzzle, targetPart.Position)
                    end
                end
            end
            table.insert(hits, {origin, targetPart.Position, targetPart})
        end

        safeCall('ShootEvent', function()
            ShootEvent:FireServer(hits)
        end)

        local newAmmo = ammo - 1
        tool:SetAttribute("Local_CurrentAmmo", newAmmo)

        if hud then
            local BottomRightFrame = hud:FindFirstChild("BottomRightFrame")
            if BottomRightFrame then
                local gunFrame = BottomRightFrame:FindFirstChild("GunFrame")
                if gunFrame then
                    local bulletsLabel = gunFrame:FindFirstChild("BulletsLabel")
                    if bulletsLabel then
                        if lastBehavior == "Sniper" then
                            bulletsLabel.Text = newAmmo .. " | " .. (tool:GetAttribute("StoredAmmo") or 0)
                        else
                            bulletsLabel.Text = newAmmo .. "/" .. (tool:GetAttribute("MaxAmmo") or 0)
                        end
                    end
                end
            end
        end

        tool:SetAttribute("Local_IsShooting", false)
    end

    local function passesTeamCheckSA(player)
        if not filterTeamSA then return true end
        return player and player.Team == filterTeamSA
    end

    local function getTarget(origin, obj)
        local enabled = (AutoFire and AutoFire.Enabled)
        local chance = enabled and 100 or (HitChance and HitChance.Value or 0)
        if not rand or rand.NextNumber(rand, 0, 100) > chance then return end
        local headshotChance = enabled and 100 or (HeadshotChance and HeadshotChance.Value or 0)
        local targetPart = (rand.NextNumber(rand, 0, 100) < headshotChance) and 'Head' or 'RootPart'
        local wallcheck = Target and Target.Walls and Target.Walls.Enabled and (obj or true) or nil
        local ent = entitylib['Entity' .. (Mode and Mode.Value or 'Mouse')]({
            Range = Range and Range.Value or 150,
            Wallcheck = wallcheck,
            Part = targetPart,
            Origin = origin,
            Players = Target and Target.Players and Target.Players.Enabled,
            NPCs = Target and Target.NPCs and Target.NPCs.Enabled
        })
        if ent and targetinfo then targetinfo.Targets[ent] = tick() + 1 end
        if ent and ent.Player and not passesTeamCheckSA(ent.Player) then
            return nil
        end
        return ent, ent and ent[targetPart], origin
    end

    t.sa.hooks.PrisonLife = function(args)
    if not entitylib or not entitylib.isAlive then return end
    local ent, targetPart, origin = getTarget(entitylib.character.Head.Position, nil)
    if not ent or not targetPart or typeof(args[1]) ~= "table" then return end

    local originalHits = args[1]
    local count = math.clamp(#originalHits, 1, 20)
    if SilentAim and SilentAim.Enabled then
        local newHits = table.create(count)
        for i = 1, count do
            newHits[i] = {origin, targetPart.Position, targetPart}
        end
        args[1] = newHits
        if t.hn.e and targetPart.Parent then
            notif('Rawr.xyz', 'attempted to hit ' .. targetPart.Parent.Name .. "'s " .. targetPart.Name, 3)
        end
    else
        if t.hn.e then
            for _, v in originalHits do
                local part = v[3]
                if typeof(part) == "Instance" and part.Parent and part.Parent:FindFirstChild("Humanoid") then
                    notif('Rawr.xyz', 'hit ' .. part.Parent.Name .. "'s " .. part.Name, 3)
                end
            end
        end
    end
end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if CircleObject then CircleObject.Visible = callback and Mode and Mode.Value == 'Mouse' end
            if callback then
                renderStepConnection = runService.RenderStepped:Connect(function()
                    if not entitylib or not entitylib.isAlive then return end
                    local character = entitylib.character and entitylib.character.Character
                    local head = entitylib.character and entitylib.character.Head
                    if not head or not character then return end

                    local origin = head.CFrame
                    local ent = entitylib['Entity' .. (Mode and Mode.Value or 'Mouse')]({
                        Range = Range and Range.Value or 150,
                        Wallcheck = Target and Target.Walls and Target.Walls.Enabled or nil,
                        Part = 'Head',
                        Origin = origin.Position,
                        Players = Target and Target.Players and Target.Players.Enabled,
                        NPCs = Target and Target.NPCs and Target.NPCs.Enabled
                    })

                    if ent and ent.Player and not passesTeamCheckSA(ent.Player) then
                        ent = nil
                    end

                    if ShowTarget and ShowTarget.Enabled and ent and targetinfo then
                        targetinfo.Targets[ent] = tick() + 1
                    end

                    if CircleObject then
                        CircleObject.Position = inputService:GetMouseLocation()
                    end

                    if AutoFire and AutoFire.Enabled then
                        local mouseDown = mouse1click()
                        local windowActive = (isrbxactive or iswindowactive)()
                        if mouseDown and windowActive then
                            if ent and canClick() then
                                if Method and Method.Value == 'Click' then
                                    if delayCheck < tick() then
                                        if mouseClicked then
                                            mouse1release()
                                            mouseClicked = false
                                            delayCheck = tick() + (AutoFireShootDelay and AutoFireShootDelay.Value or 0)
                                        else
                                            mouse1press()
                                            mouseClicked = true
                                            delayCheck = tick() + (AutoFireShootDelay and AutoFireShootDelay.Value or 0)
                                        end
                                    end
                                else
                                    if delayCheck < tick() then
                                        delayCheck = tick() + (AutoFireShootDelay and AutoFireShootDelay.Value or 0)
                                        local tool = character:FindFirstChildOfClass("Tool")
                                        if tool and ent.Head then
                                            tryShoot(origin.Position, ent.Head, tool)
                                        end
                                    end
                                end
                            end
                        else
                            if mouseClicked then
                                mouse1release()
                                mouseClicked = false
                            end
                        end
                    end

                    if Face and Face.Enabled and ent then
                        local rootPart = ent.Character and ent.Character:FindFirstChild("HumanoidRootPart")
                        if rootPart and entitylib.character and entitylib.character.RootPart then
                            local vec = rootPart.Position * Vector3.new(1,0,1)
                            entitylib.character.RootPart.CFrame = CFrame.lookAt(
                                entitylib.character.RootPart.Position,
                                Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z)
                            )
                        end
                    end

                    if ent and ent.Character and ent.Character:FindFirstChild("HumanoidRootPart") then
                        t.bt.m = true
                        t.bt.p = ent.HumanoidRootPart.Position
                    end
                end)
            else
                if renderStepConnection then
                    renderStepConnection:Disconnect()
                    renderStepConnection = nil
                end
                if mouseClicked then
                    mouse1release()
                    mouseClicked = false
                end
            end
        end,
        Tooltip = 'Silently adjusts your aim towards the enemy'
    })

    Target = SilentAim:CreateTargets({Players = true})
    Mode = SilentAim:CreateDropdown({
        Name = 'Mode',
        List = {'Mouse', 'Position'},
        Function = function(val)
            if CircleObject then CircleObject.Visible = SilentAim.Enabled and val == 'Mouse' end
        end,
        Tooltip = 'Mouse - Checks for entities near the mouses position\nPosition - Checks for entities near the local character'
    })
    Range = SilentAim:CreateSlider({
        Name = 'Range', Min = 1, Max = 1000, Default = 150,
        Function = function(val) if CircleObject then CircleObject.Radius = val end end,
        Suffix = function(val) return val == 1 and 'stud' or 'studs' end
    })
    HitChance = SilentAim:CreateSlider({ Name = 'Hit Chance', Min = 0, Max = 100, Default = 85, Suffix = '%' })
    HeadshotChance = SilentAim:CreateSlider({ Name = 'Headshot Chance', Min = 0, Max = 100, Default = 65, Suffix = '%' })
    AutoFire = SilentAim:CreateToggle({
        Name = 'AutoFire',
        Function = function(callback)
            if AutoFireShootDelay then AutoFireShootDelay.Object.Visible = callback end
            if Method then Method.Object.Visible = callback end
        end
    })
    AutoFireShootDelay = SilentAim:CreateSlider({
        Name = 'Next Shot Delay', Min = 0, Max = 1, Decimal = 100, Visible = false, Darker = true,
        Suffix = function(val) return val == 1 and 'second' or 'seconds' end
    })
    Method = SilentAim:CreateDropdown({ Name = 'Shoot Method', List = {'Simulation', 'Click'} })
    TeamFilterSA = SilentAim:CreateDropdown({
        Name = 'Team Filter',
        List = {'All', 'Criminals', 'Inmates', 'Guards', 'Neutral'},
        Function = function(val)
            if val == 'Criminals' then filterTeamSA = criminalsTeam
            elseif val == 'Inmates' then filterTeamSA = inmatesTeam
            elseif val == 'Guards' then filterTeamSA = guardsTeam
            elseif val == 'Neutral' then filterTeamSA = neutralTeam
            else filterTeamSA = nil end
        end,
        Tooltip = 'Only target players on the selected team'
    })
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled and CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV((CircleColor and CircleColor.Hue or 0), (CircleColor and CircleColor.Sat or 1), (CircleColor and CircleColor.Value or 1))
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = Range and Range.Value or 150
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - (CircleTransparency and CircleTransparency.Value or 0)
                CircleObject.Visible = SilentAim.Enabled and Mode and Mode.Value == 'Mouse'
            else
                safeCall('Remove Circle', function() CircleObject:Remove() end)
                CircleObject = nil
            end
            if CircleColor then CircleColor.Object.Visible = callback end
            if CircleTransparency then CircleTransparency.Object.Visible = callback end
            if CircleFilled then CircleFilled.Object.Visible = callback end
        end
    })
    CircleColor = SilentAim:CreateColorSlider({
        Name = 'Circle Color', Function = function(hue,sat,val) if CircleObject then CircleObject.Color = Color3.fromHSV(hue,sat,val) end end,
        Darker = true, Visible = false
    })
    CircleTransparency = SilentAim:CreateSlider({
        Name = 'Transparency', Min = 0, Max = 1, Decimal = 10, Default = 0.5,
        Function = function(val) if CircleObject then CircleObject.Transparency = 1 - val end end,
        Darker = true, Visible = false
    })
    CircleFilled = SilentAim:CreateToggle({
        Name = 'Circle Filled', Function = function(callback) if CircleObject then CircleObject.Filled = callback end end,
        Darker = true, Visible = false
    })
    Face = SilentAim:CreateToggle({ Name = 'Face target' })
    ShowTarget = SilentAim:CreateToggle({ Name = "Show Target Info" })
end)

run(function()
    local Pitch
    local Original = CFrame.new()

    Pitch = vape.Categories.Blatant:CreateModule({
        Name = 'Head Pitch Spinbot (Client)',
        Function = function(callback)
            if callback then
                if entitylib and entitylib.character and entitylib.character.Character then
                    local character = entitylib.character.Character
                    local torso = character:FindFirstChild("Torso")
                    local neck = torso and torso:FindFirstChild("Neck")
                    if neck then
                        Original = neck.C1
                        Pitch:Clean(runService.PreSimulation:Connect(function()
                            if entitylib and entitylib.isAlive then
                                local char = entitylib.character.Character
                                local t = char and char:FindFirstChild("Torso")
                                local n = t and t:FindFirstChild("Neck")
                                if n then
                                    n.C1 = n.C1 * CFrame.Angles(math.rad(145), 0, 0)
                                end
                            end
                        end))
                    end
                end
            else
                if entitylib and entitylib.isAlive then
                    local character = entitylib.character.Character
                    local torso = character and character:FindFirstChild("Torso")
                    local neck = torso and torso:FindFirstChild("Neck")
                    if neck then
                        neck.C1 = Original
                    end
                end
            end
        end
    })
end)

run(function()
    vape.Categories.Combat:CreateModule({
        Name = "HitNotifications",
        Function = function(callback) t.hn.e = callback end
    })
end)

run(function()
    local GunMods
    local Range
    local SpreadRadius
    local FireRate

    local function itemAdded(v)
        if v and v:IsA("Tool") and v:GetAttribute("Local_ReloadSession") then
            v:SetAttribute("Range", Range and Range.Value)
            v:SetAttribute("AccurateRange", Range and Range.Value)
            v:SetAttribute("SpreadRadius", SpreadRadius and SpreadRadius.Value)
            v:SetAttribute("FireRate", FireRate and FireRate.Value)
        end
    end

    local function characterAdded(char)
        if not char then return end
        local character = char.Character
        if character then
            GunMods:Clean(character.ChildAdded:Connect(itemAdded))
            local children = character:GetChildren()
            for i = 1, #children do itemAdded(children[i]) end
        end
        local backpack = lplr and lplr.Backpack
        if backpack then
            GunMods:Clean(backpack.ChildAdded:Connect(itemAdded))
            local children = backpack:GetChildren()
            for i = 1, #children do itemAdded(children[i]) end
        end
    end

    GunMods = vape.Categories.Combat:CreateModule({
        Name = "GunMods",
        Function = function(callback)
            if callback then
                if entitylib and entitylib.character then characterAdded(entitylib.character) end
                GunMods:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
            end
        end
    })
    Range = GunMods:CreateSlider({ Name = "Range", Min=1, Max=9999, Default=150, Suffix=function(val) return val==1 and 'stud' or 'studs' end })
    SpreadRadius = GunMods:CreateSlider({ Name = "Spread Radius", Min=0, Max=1, Default=0.03, Decimal=100, Suffix='studs' })
    FireRate = GunMods:CreateSlider({ Name = "Fire Rate", Min=0, Max=1, Decimal=100, Default=0.1, Suffix=function(val) return val==1 and 'second' or 'seconds' end })
end)

run(function()
    local AutoPickup
    local PrisonItems = {}
    local Keycard
    local M9
    local GiverPressed = remotes:WaitForChild("GiverPressed")

    local function checkInv(v, name)
        if not entitylib or not entitylib.isAlive then return false end
        local backpack = lplr and lplr:FindFirstChildOfClass("Backpack")
        local character = entitylib.character and entitylib.character.Character
        if not backpack or not character then return false end
        for _, tool in pairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == (name or v.Name) then return true end
        end
        for _, tool in pairs(character:GetChildren()) do
            if tool:IsA("Tool") and tool.Name == (name or v.Name) then return true end
        end
        return false
    end

    local function pickUp(v, name)
        if not entitylib or not entitylib.isAlive then return end
        if checkInv(v, name) then return end
        local handle = v:FindFirstChildWhichIsA("MeshPart") or v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
        if handle then
            local position = handle.CFrame
            local new = CFrame.new(position.X, position.Y - 5, position.Z)
            repeat
                t.d.s = new
                safeCall('GiverPressed', function() GiverPressed:FireServer(v) end)
                task.wait(0.5)
            until not entitylib or not entitylib.isAlive or checkInv(v, name)
            t.d.s = CFrame.new()
        end
    end

    local function canPickup(v)
        if not entitylib or not entitylib.character or not entitylib.character.Player then return false end
        local team = entitylib.character.Player.Team
        if v and v.Parent and v.Parent.Name == "Model" then
            return team == criminalsTeam
        end
        return team == inmatesTeam or team == guardsTeam
    end

    AutoPickup = vape.Categories.Utility:CreateModule({
        Name = "AutoPickup",
        Function = function(callback)
            if callback then
                AutoPickup:Clean(entitylib.Events.LocalAdded:Connect(function()
                    if entitylib and entitylib.isAlive then
                        for _, item in pairs(PrisonItems) do
                            if item and item.Enabled and item.Object and canPickup(item.Object) then
                                pickUp(item.Object, item.Gun)
                            end
                        end
                    end
                end))
                AutoPickup:Clean(workspaceService.ChildAdded:Connect(function(v)
                    if v and v.Name == "Key card" and Keycard and Keycard.Enabled and lplr and lplr.Team ~= guardsTeam then
                        pickUp(v)
                    elseif v and v.Name == "M9" and M9 and M9.Enabled and lplr and lplr.Team ~= guardsTeam then
                        pickUp(v)
                    end
                end))
            end
        end,
        Tooltip = "Automatically picks up guns when you respawn, or keycard and m9 when dropped."
    })

    Keycard = AutoPickup:CreateToggle({ Name = "Key card" })
    M9 = AutoPickup:CreateToggle({ Name = "M9" })

    for _, i in pairs(workspaceService:GetDescendants()) do
        if i.Name == "TouchGiver" then
            local tool = i:GetAttribute("ToolName")
            if tool and not PrisonItems[tool] then
                PrisonItems[tool] = AutoPickup:CreateToggle({
                    Name = tool,
                    Tooltip = "Only works on respawn" ..
                        (i.Parent and i.Parent.Name == "Model" and " and as a criminal" or " and as an inmate or guard")
                })
                PrisonItems[tool].Object = i
                PrisonItems[tool].Gun = tool
            end
        end
    end
end)

run(function()
    local meleeEvent = replicatedStorageService:WaitForChild("meleeEvent")
    local Killaura
    local Targets
    local CPS
    local AttackRange
    local AngleSlider
    local Max
    local BoxSwingColor
    local BoxAttackColor
    local ParticleTexture
    local ParticleColor1
    local ParticleColor2
    local ParticleSize
    local Face
    local filterTeamKA
    local TeamFilterKA
    local Particles, Boxes = {}, {}
    local AttackDelay = tick()
    local renderStepConnection

    local function passesTeamCheckKA(player)
        if not filterTeamKA then return true end
        return player and player.Team == filterTeamKA
    end

    Killaura = vape.Categories.Blatant:CreateModule({
        Name = 'KillAura',
        Function = function(callback)
            if callback then
                renderStepConnection = runService.RenderStepped:Connect(function()
                    if not entitylib or not entitylib.isAlive then return end
                    local rootPart = entitylib.character and entitylib.character.RootPart
                    if not rootPart then return end
                    local attacked = {}
                    local selfpos = rootPart.Position
                    local localfacing = rootPart.CFrame.LookVector * Vector3.new(1,0,1)

                    local plrs = entitylib.AllPosition({
                        Range = AttackRange and AttackRange.Value or 13,
                        Wallcheck = Targets and Targets.Walls and Targets.Walls.Enabled or nil,
                        Part = 'RootPart',
                        Players = Targets and Targets.Players and Targets.Players.Enabled,
                        NPCs = Targets and Targets.NPCs and Targets.NPCs.Enabled,
                        Limit = Max and Max.Value or 10
                    })

                    for i = 1, #plrs do
                        local v = plrs[i]
                        if v and v.RootPart and v.RootPart.Position then
                            if v.Player and not passesTeamCheckKA(v.Player) then
                                -- skip
                            else
                                local delta = (v.RootPart.Position - selfpos)
                                local deltaUnit = (delta * Vector3.new(1,0,1)).Unit
                                local dot = localfacing:Dot(deltaUnit)
                                if dot <= 1 and dot >= -1 then
                                    local angle = math.acos(dot)
                                    if angle <= math.rad((AngleSlider and AngleSlider.Value or 90) / 2) then
                                        local distMag = delta.Magnitude
                                        table.insert(attacked, {
                                            Entity = v,
                                            Check = distMag > (AttackRange and AttackRange.Value or 13) and BoxSwingColor or BoxAttackColor
                                        })
                                        if targetinfo then targetinfo.Targets[v] = tick() + 1 end

                                        if AttackDelay < tick() then
                                            local aps = CPS and CPS.GetRandomValue() or 1
                                            if aps > 0 then
                                                AttackDelay = tick() + (1 / aps)
                                            end
                                            safeCall('meleeEvent', function()
                                                meleeEvent:FireServer(v.Player, 1, 1)
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    if Boxes then
                        for i, box in ipairs(Boxes) do
                            if attacked[i] and box then
                                box.Adornee = attacked[i].Entity.RootPart
                                local chk = attacked[i].Check
                                if chk and chk.Hue then
                                    box.Color3 = Color3.fromHSV(chk.Hue, chk.Sat, chk.Value)
                                    box.Transparency = 1 - chk.Opacity
                                end
                                box.Visible = true
                            elseif box then
                                box.Adornee = nil
                                box.Visible = false
                            end
                        end
                    end

                    if Particles then
                        for i, part in ipairs(Particles) do
                            if attacked[i] and part then
                                part.Position = attacked[i].Entity.RootPart.Position
                                part.Parent = gameCamera
                            elseif part then
                                part.Parent = nil
                            end
                        end
                    end

                    if Face and Face.Enabled and #attacked > 0 then
                        local root = attacked[1].Entity.RootPart
                        if root and entitylib.character and entitylib.character.RootPart then
                            local vec = root.Position * Vector3.new(1,0,1)
                            entitylib.character.RootPart.CFrame = CFrame.lookAt(
                                entitylib.character.RootPart.Position,
                                Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z)
                            )
                        end
                    end
                end)
            else
                if renderStepConnection then
                    renderStepConnection:Disconnect()
                    renderStepConnection = nil
                end
                if Boxes then
                    for _, v in pairs(Boxes) do v:Destroy() end
                    table.clear(Boxes)
                end
                if Particles then
                    for _, v in pairs(Particles) do v:Destroy() end
                    table.clear(Particles)
                end
            end
        end,
        Tooltip = 'Attack players around you without aiming at them.'
    })
    Targets = Killaura:CreateTargets({Players = true})
    CPS = Killaura:CreateTwoSlider({ Name='Attacks per Second', Min=1, Max=15, DefaultMin=8, DefaultMax=12 })
    AttackRange = Killaura:CreateSlider({ Name='Attack range', Min=1, Max=30, Default=13, Suffix=function(val) return val==1 and 'stud' or 'studs' end })
    AngleSlider = Killaura:CreateSlider({ Name='Max angle', Min=1, Max=360, Default=90 })
    Max = Killaura:CreateSlider({ Name='Max targets', Min=1, Max=10, Default=10 })
    TeamFilterKA = Killaura:CreateDropdown({
        Name = 'Team Filter',
        List = {'All', 'Criminals', 'Inmates', 'Guards', 'Neutral'},
        Function = function(val)
            if val == 'Criminals' then filterTeamKA = criminalsTeam
            elseif val == 'Inmates' then filterTeamKA = inmatesTeam
            elseif val == 'Guards' then filterTeamKA = guardsTeam
            elseif val == 'Neutral' then filterTeamKA = neutralTeam
            else filterTeamKA = nil end
        end,
        Tooltip = 'Only attack players on the selected team'
    })
    Killaura:CreateToggle({
        Name = 'Show target',
        Function = function(callback)
            if BoxSwingColor then BoxSwingColor.Object.Visible = callback end
            if BoxAttackColor then BoxAttackColor.Object.Visible = callback end
            if callback then
                for i = 1, 10 do
                    local box = Instance.new('BoxHandleAdornment')
                    box.Adornee = nil
                    box.AlwaysOnTop = true
                    box.Size = Vector3.new(3, 5, 3)
                    box.CFrame = CFrame.new(0, -0.5, 0)
                    box.ZIndex = 0
                    box.Visible = false
                    box.Parent = vape.gui
                    Boxes[i] = box
                end
            else
                if Boxes then
                    for _, v in pairs(Boxes) do v:Destroy() end
                    table.clear(Boxes)
                end
            end
        end
    })
    BoxSwingColor = Killaura:CreateColorSlider({ Name='Target Color', Darker=true, DefaultHue=0.6, DefaultOpacity=0.5, Visible=false })
    BoxAttackColor = Killaura:CreateColorSlider({ Name='Attack Color', Darker=true, DefaultOpacity=0.5, Visible=false })
    Killaura:CreateToggle({
        Name = 'Target particles',
        Function = function(callback)
            if ParticleTexture then ParticleTexture.Object.Visible = callback end
            if ParticleColor1 then ParticleColor1.Object.Visible = callback end
            if ParticleColor2 then ParticleColor2.Object.Visible = callback end
            if ParticleSize then ParticleSize.Object.Visible = callback end
            if callback then
                for i = 1, 10 do
                    local part = Instance.new('Part')
                    part.Size = Vector3.new(2, 4, 2)
                    part.Anchored = true
                    part.CanCollide = false
                    part.Transparency = 1
                    part.CanQuery = false
                    part.Parent = Killaura.Enabled and gameCamera or nil
                    local particles = Instance.new('ParticleEmitter')
                    particles.Brightness = 1.5
                    particles.Size = NumberSequence.new(ParticleSize and ParticleSize.Value or 0.2)
                    particles.Shape = Enum.ParticleEmitterShape.Sphere
                    particles.Texture = ParticleTexture and ParticleTexture.Value or 'rbxassetid://14736249347'
                    particles.Transparency = NumberSequence.new(0)
                    particles.Lifetime = NumberRange.new(0.4)
                    particles.Speed = NumberRange.new(16)
                    particles.Rate = 128
                    particles.Drag = 16
                    particles.ShapePartial = 1
                    particles.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1 and ParticleColor1.Hue or 0, ParticleColor1 and ParticleColor1.Sat or 1, ParticleColor1 and ParticleColor1.Value or 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2 and ParticleColor2.Hue or 0.6, ParticleColor2 and ParticleColor2.Sat or 1, ParticleColor2 and ParticleColor2.Value or 1))
                    })
                    particles.Parent = part
                    Particles[i] = part
                end
            else
                if Particles then
                    for _, v in pairs(Particles) do v:Destroy() end
                    table.clear(Particles)
                end
            end
        end
    })
    ParticleTexture = Killaura:CreateTextBox({ Name='Texture', Default='rbxassetid://14736249347', Function=function() for _,v in pairs(Particles) do v.ParticleEmitter.Texture = ParticleTexture.Value end end, Darker=true, Visible=false })
    ParticleColor1 = Killaura:CreateColorSlider({ Name='Color Begin', Function=function(h,s,v) for _,part in pairs(Particles) do part.ParticleEmitter.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromHSV(h,s,v)), ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value)) } end end, Darker=true, Visible=false })
    ParticleColor2 = Killaura:CreateColorSlider({ Name='Color End', Function=function(h,s,v) for _,part in pairs(Particles) do part.ParticleEmitter.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)), ColorSequenceKeypoint.new(1, Color3.fromHSV(h,s,v)) } end end, Darker=true, Visible=false })
    ParticleSize = Killaura:CreateSlider({ Name='Size', Min=0, Max=1, Default=0.2, Decimal=100, Function=function(val) for _,v in pairs(Particles) do v.ParticleEmitter.Size = NumberSequence.new(val) end end, Darker=true, Visible=false })
    Face = Killaura:CreateToggle({ Name='Face target' })
end)

run(function()
    local ArrestPlayer = remotes:WaitForChild("ArrestPlayer")
    local InteractWithItem = remotes:WaitForChild("InteractWithItem")
    local Cooldown = 0
    local Players = {}
    local AutoArrest
    local ArrestRange

    local function disconnectPlayerConnections(plr)
    if Players[plr] then
        for _, conn in pairs(Players[plr]) do
            pcall(function() conn:Disconnect() end)
        end
        Players[plr] = nil
    end
end
    local function Arrest(player, char)
        if not player or not char then return end
        safeCall('Arrest', function()
            ArrestPlayer:InvokeServer(player, 1)
            InteractWithItem:InvokeServer(char.Head)
        end)
        Cooldown = tick() + 7.5
    end

    local function Cleanup(plr)
        disconnectPlayerConnections(plr)
    end

    local function Auto(v)
    if not AutoArrest or not AutoArrest.Enabled then return end
    if not entitylib or not entitylib.isAlive then return end

    disconnectPlayerConnections(v)
    Players[v] = {}

    local localChar = lplr.Character
    local deathConn
    if localChar then
        local humanoid = localChar:FindFirstChildOfClass("Humanoid")
        if humanoid then
            deathConn = humanoid.Died:Connect(function()
                t.d.s = CFrame.new()
            end)
        end
    end

    local function Listener(char)
        if not char then return end
        local TasedConnection = char:GetAttributeChangedSignal("Tased"):Connect(function()
            if tick() < Cooldown then
                notif('Rawr.xyz', 'Arrest Cooldown: ' .. math.ceil(Cooldown - tick()) .. 's', 3)
                return
            end
            if not entitylib or not entitylib.isAlive then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local dist = (entitylib.character.RootPart.Position - root.Position).Magnitude
            if dist > (ArrestRange and ArrestRange.Value or 100) then return end

            if char:GetAttribute("Tased") == true and lplr and lplr.Team == guardsTeam then
                if v and v.Team then
                    if v.Team == criminalsTeam or (v.Team == inmatesTeam and (char:GetAttribute("Trespassing") or char:GetAttribute("Hostile"))) then
                        local Handcuffs = char:FindFirstChild("Handcuffs") or (lplr and lplr.Backpack and lplr.Backpack:FindFirstChild("Handcuffs"))
                        if Handcuffs then
                            Handcuffs.Parent = char
                            local start = tick()
                            repeat
                                if not entitylib or not entitylib.isAlive then break end
                                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                                t.d.s = char.HumanoidRootPart.CFrame
                                Arrest(v, char)
                                task.wait(0.1)
                            until not char or char:GetAttribute("Arrested") or (tick()-start > 5)
                            Handcuffs.Parent = lplr and lplr.Backpack
                            t.d.s = CFrame.new()
                        end
                    end
                end
            end
        end)
        Players[v].TasedConnection = TasedConnection

        char.Destroying:Connect(function()
            disconnectPlayerConnections(v)
        end)
    end

    if v and v.Character then Listener(v.Character) end

    Players[v].leaveConnection = entitylib.Events.EntityRemoved:Connect(function(plr)
        if plr.Player == v then disconnectPlayerConnections(v) end
    end)

    Players[v].DeathConn = deathConn
end

    AutoArrest = vape.Categories.Blatant:CreateModule({
        Name = "AutoArrest",
        Function = function(callback)
            if callback then
                local function setup(plr)
                    AutoArrest:Clean(plr.CharacterAdded:Connect(function() Auto(plr) end))
                    if plr.Character then Auto(plr) end
                end
                for _, plr in pairs(entitylib.List) do setup(plr.Player) end
                AutoArrest:Clean(entitylib.Events.EntityAdded:Connect(function(plr) setup(plr.Player) end))
            else
                for plr, conns in pairs(Players) do
                    for _, conn in pairs(conns) do
                        pcall(function() conn:Disconnect() end)
                    end
                end
                Players = {}
            end
        end
    })
    ArrestRange = AutoArrest:CreateSlider({ Name = "Arrest Range", Min=1, Max=1000, Default=100, Suffix=function(val) return val==1 and 'stud' or 'studs' end })
end)

run(function()
    local NameChanger = vape.Categories.Utility:CreateModule({
        Name = "Name Changer",
        Function = function(callback) end
    })

    local displayNameBox = NameChanger:CreateTextBox({
        Name = "Display Name",
        Default = lplr and (lplr.DisplayName or lplr.Name) or "",
        Placeholder = "New display name"
    })
    local userNameBox = NameChanger:CreateTextBox({
        Name = "User Name",
        Default = lplr and lplr.Name or "",
        Placeholder = "New username"
    })
    NameChanger:CreateButton({
        Name = "Set Names",
        Function = function()
            local newDisplay = displayNameBox and displayNameBox.Value
            local newUser = userNameBox and userNameBox.Value
            local success = false
            if newDisplay and newDisplay ~= "" and #newDisplay <= 100 then
                if lplr then
                    lplr.DisplayName = newDisplay
                    success = true
                end
            end
            if newUser and newUser ~= "" and #newUser <= 100 then
                if lplr then
                    lplr.Name = newUser
                    success = true
                end
            end
            if success then
                notif('Name Changer', 'Names have been updated!', 2, 'success')
            else
                notif('Name Changer', 'Failed to update names.', 2, 'alert')
            end
        end
    })
end)

print("Hello, V4.9.5.2")
if identifyexecutor then
    local execInfo = {identifyexecutor()}
    local execName = execInfo[1] or "Unknown"
    local execVersion = execInfo[2] or "Unknown"
    print("Executor: " .. execName .. " | Version: " .. execVersion)
    notif('Rawr.xyz', 'Executor: ' .. execName .. ' | v' .. execVersion, 5, 'info')
end
