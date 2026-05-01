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
    local clickGuiVisible = vape.gui.ScaledGui and vape.gui.ScaledGui.ClickGui and vape.gui.ScaledGui.ClickGui.Visible
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
    vape:Clean(runService.Heartbeat:Connect(function()
        if lplr.Character and t.d.s ~= CFrame.new() then
            local character = lplr.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                t.d.l = root.CFrame
                root.CFrame = t.d.s
                runService.RenderStepped:Wait()
                root.CFrame = t.d.l
            end
        end
    end))

    local old
    old = hookmetamethod(game, "__index", newcclosure(function(self, key)
        if t.d.s ~= CFrame.new() and not checkcaller() and key == "CFrame" and
            lplr.Character and lplr.Character.HumanoidRootPart and self ==
            lplr.Character.HumanoidRootPart then return t.d.l end
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
            local dist = (start - entitylib.character.RootPart.Position).Magnitude
            if dist > 5 then return end

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
        if typeof(args[1]) == "table" then t.sa.hooks.PrisonLife(args) end

        return old(self, unpack(args))
    end)

    vape:Clean(function() hookmetamethod(game, "__namecall", old) end)
end)

playersService.LocalPlayer.CharacterAdded:Connect(function(character)
    local antiJumpScript = character:WaitForChild("AntiJump", 1)
    if antiJumpScript then
        antiJumpScript:Destroy()
    end
end)
if playersService.LocalPlayer.Character then
    local s = playersService.LocalPlayer.Character:WaitForChild("AntiJump", 1)
    if s then s:Destroy() end
end

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
        local distance = (endPos - startPos).magnitude
        local midPoint = (startPos + endPos) / 2

        local part = Instance.new("Part")
        part.Name = "RayPart"
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
        Name = "Tracer Visuals",
        Function = function(callback)
            if callback then
                updateTracerFunctions()
            else
                GunTracers.createTaser = originalCreateTaser
                GunTracers.createSniper = originalCreateSniper
                GunTracers.createBullet = originalCreateBullet
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
                notif('Vape', 'Please expand this module to use it', 3, 'alert')
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
            if Team.Value == "Neutral" then
                RequestTeamChange:InvokeServer(neutralTeam, 1)
            elseif Team.Value == "Guards" then
                RequestTeamChange:InvokeServer(neutralTeam, 1)
                task.wait(1.5)
                RequestTeamChange:InvokeServer(guardsTeam, 1)
                task.delay(1, function()
                    if lplr.Team ~= guardsTeam then
                        notif('Vape', 'Failed to switch to guards team, please try again later', 3, 'alert')
                    end
                end)
            elseif Team.Value == "Criminals" then
                if lplr.Team == inmatesTeam then
                    repeat
                        t.d.s = Shippingcontainers.WorldPivot
                        task.wait(0.05)
                    until lplr.Team == criminalsTeam
                    t.d.s = CFrame.new()
                else
                    notif('Vape', 'Please switch to the inmates team and try again', 3, 'alert')
                end
            elseif Team.Value == "Inmates" then
                RequestTeamChange:InvokeServer(neutralTeam, 1)
                task.wait(1.5)
                RequestTeamChange:InvokeServer(inmatesTeam, 1)
                task.delay(1, function()
                    if lplr.Team ~= inmatesTeam then
                        notif('Vape', 'Failed to switch to inmates team, please try again later', 3, 'alert')
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
        local backpack = lplr:FindFirstChildOfClass("Backpack")
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
            if v:IsA("Tool") and v.Name ~= "Taser" and getAmmoOrReloading(v) then
                character.Humanoid:UnequipTools()
                character.Humanoid:EquipTool(v)
                return
            end
        end
    end

    local function clearToolConns()
        for _, conn in pairs(toolConns) do
            conn:Disconnect()
        end
        table.clear(toolConns)
    end

    local function itemAdded(v)
        if not v:IsA("Tool") then return end
        if v:GetAttribute("Behavior") == "Sniper" then
            OwnSniper = true
            Sniper = v
        elseif v:GetAttribute("Behavior") == "Shotgun" then
            OwnShotgun = true
            Shotgun = v
        end

        if toolConns[v] then toolConns[v]:Disconnect() end

        toolConns[v] = v:GetAttributeChangedSignal("Local_CurrentAmmo"):Connect(function()
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
    end

    local function characterAdded(char)
        clearToolConns()
        if backpackConn then backpackConn:Disconnect() end
        backpackConn = lplr.Backpack.ChildAdded:Connect(function(child)
            itemAdded(child)
        end)
        local children = char.Character:GetChildren()
        for i = 1, #children do itemAdded(children[i]) end
        children = lplr.Backpack:GetChildren()
        for i = 1, #children do itemAdded(children[i]) end

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
                if entitylib.isAlive then
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
    local rand = Random.new()
    local delayCheck = tick()
    local GunTracers = require(replicatedStorageService:WaitForChild("SharedModules"):WaitForChild("GunTracers"))
    local hud = playerGui:FindFirstChild("Home") and playerGui.Home:FindFirstChild("Hud")
    local Method
    local mouseClicked = false

    local function tryShoot(origin, targetPart, tool)
        if not tool then return end
        local ammo = tool:GetAttribute("Local_CurrentAmmo")
        if not ammo or ammo <= 0 then return end
        local reloadSession = tool:GetAttribute("Local_ReloadSession")
        if reloadSession and reloadSession > 0 then return end

        tool:SetAttribute("Local_IsShooting", true)
        local projectileCount = tool:GetAttribute("ProjectileCount") or 1
        local hits = {}
        for _ = 1, projectileCount do
            local muzzle = (tool:FindFirstChild("muzzle") and tool.muzzle.Position) or origin
            local behavior = tool:GetAttribute("Behavior")
            if behavior == "Sniper" then
                GunTracers.createSniper(muzzle, targetPart.Position)
            elseif behavior == "Taser" then
                GunTracers.createTaser(muzzle, targetPart.Position)
            else
                GunTracers.createBullet(muzzle, targetPart.Position)
            end
            table.insert(hits, {origin, targetPart.Position, targetPart})
        end

        pcall(function()
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
                        if behavior == "Sniper" then
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

    local function getTarget(origin, obj)
        if rand.NextNumber(rand, 0, 100) > (AutoFire and AutoFire.Enabled and 100 or HitChance.Value) then return end
        local headshotChance = (AutoFire and AutoFire.Enabled and 100 or HeadshotChance.Value)
        local targetPart = (rand.NextNumber(rand, 0, 100) < headshotChance) and 'Head' or 'RootPart'
        local wallcheck = Target and Target.Walls.Enabled and (obj or true) or nil
        local ent = entitylib['Entity' .. Mode.Value]({
            Range = Range.Value,
            Wallcheck = wallcheck,
            Part = targetPart,
            Origin = origin,
            Players = Target.Players.Enabled,
            NPCs = Target.NPCs.Enabled
        })
        if ent then targetinfo.Targets[ent] = tick() + 1 end
        return ent, ent and ent[targetPart], origin
    end

    t.sa.hooks.PrisonLife = function(args)
        if not entitylib.isAlive then return end
        local ent, targetPart, origin = getTarget(entitylib.character.Head.Position, nil)
        if not ent or typeof(args[1]) ~= "table" then return end

        local originalHits = args[1]
        local count = math.clamp(#originalHits, 1, 20)
        if SilentAim.Enabled then
            local newHits = table.create(count)
            for i = 1, count do
                newHits[i] = {origin, targetPart.Position, targetPart}
            end
            args[1] = newHits
            if t.hn.e then
                notif('Vape', 'attempted to hit ' .. targetPart.Parent.Name .. "'s " .. targetPart.Name, 3)
            end
        else
            if t.hn.e then
                for _, v in originalHits do
                    local part = v[3]
                    if typeof(part) == "Instance" and part.Parent and part.Parent:FindFirstChild("Humanoid") then
                        notif('Vape', 'hit ' .. part.Parent.Name .. "'s " .. part.Name, 3)
                    end
                end
            end
        end
    end

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = 'SilentAim',
        Function = function(callback)
            if CircleObject then CircleObject.Visible = callback and Mode.Value == 'Mouse' end
            if callback then
                repeat
                    if entitylib.isAlive then
                        local character = entitylib.character.Character
                        local head = entitylib.character.Head
                        if head and character then
                            local origin = head.CFrame
                            local ent = entitylib['Entity' .. Mode.Value]({
                                Range = Range.Value,
                                Wallcheck = Target.Walls.Enabled or nil,
                                Part = 'Head',
                                Origin = origin.Position,
                                Players = Target.Players.Enabled,
                                NPCs = Target.NPCs.Enabled
                            })

                            if ShowTarget.Enabled and ent then
                                targetinfo.Targets[ent] = tick() + 1
                            end

                            if CircleObject then
                                CircleObject.Position = inputService:GetMouseLocation()
                            end

                            if AutoFire.Enabled then
                                local mouseDown = mouse1click()
                                local windowActive = (isrbxactive or iswindowactive)()
                                if mouseDown and windowActive then
                                    if ent and canClick() then
                                        if Method.Value == 'Click' then
                                            if delayCheck < tick() then
                                                if mouseClicked then
                                                    mouse1release()
                                                    mouseClicked = false
                                                    delayCheck = tick() + AutoFireShootDelay.Value
                                                else
                                                    mouse1press()
                                                    mouseClicked = true
                                                    delayCheck = tick() + AutoFireShootDelay.Value
                                                end
                                            end
                                        else
                                            if delayCheck < tick() then
                                                delayCheck = tick() + AutoFireShootDelay.Value
                                                local tool = character:FindFirstChildOfClass("Tool")
                                                if tool then
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

                            if Face.Enabled and ent then
                                local rootPart = ent.Character and ent.Character:FindFirstChild("HumanoidRootPart")
                                if rootPart then
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
                        end
                    end
                    task.wait(0.03)
                until not SilentAim.Enabled
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
            AutoFireShootDelay.Object.Visible = callback
            Method.Object.Visible = callback
        end
    })
    AutoFireShootDelay = SilentAim:CreateSlider({
        Name = 'Next Shot Delay', Min = 0, Max = 1, Decimal = 100, Visible = false, Darker = true,
        Suffix = function(val) return val == 1 and 'second' or 'seconds' end
    })
    Method = SilentAim:CreateDropdown({ Name = 'Shoot Method', List = {'Simulation', 'Click'} })
    SilentAim:CreateToggle({
        Name = 'Range Circle',
        Function = function(callback)
            if callback then
                CircleObject = Drawing.new('Circle')
                CircleObject.Filled = CircleFilled.Enabled
                CircleObject.Color = Color3.fromHSV(CircleColor.Hue, CircleColor.Sat, CircleColor.Value)
                CircleObject.Position = vape.gui.AbsoluteSize / 2
                CircleObject.Radius = Range.Value
                CircleObject.NumSides = 100
                CircleObject.Transparency = 1 - CircleTransparency.Value
                CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
            else
                pcall(function() CircleObject:Remove() end)
                CircleObject = nil
            end
            CircleColor.Object.Visible = callback
            CircleTransparency.Object.Visible = callback
            CircleFilled.Object.Visible = callback
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
                if entitylib.character and entitylib.character.Character and
                   entitylib.character.Character:FindFirstChild("Torso") and
                   entitylib.character.Character.Torso:FindFirstChild("Neck") then
                    Original = entitylib.character.Character.Torso.Neck.C1
                    Pitch:Clean(runService.PreSimulation:Connect(function()
                        if entitylib.isAlive then
                            local character = entitylib.character.Character
                            local torso = character and character:FindFirstChild("Torso")
                            if torso and torso:FindFirstChild("Neck") then
                                torso.Neck.C1 = torso.Neck.C1 * CFrame.Angles(math.rad(145), 0, 0)
                            end
                        end
                    end))
                end
            else
                if entitylib.isAlive then
                    local character = entitylib.character.Character
                    local torso = character and character:FindFirstChild("Torso")
                    if torso and torso:FindFirstChild("Neck") then
                        torso.Neck.C1 = Original
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
            v:SetAttribute("Range", Range.Value)
            v:SetAttribute("AccurateRange", Range.Value)
            v:SetAttribute("SpreadRadius", SpreadRadius.Value)
            v:SetAttribute("FireRate", FireRate.Value)
        end
    end

    local function characterAdded(char)
        GunMods:Clean(char.Character.ChildAdded:Connect(itemAdded))
        GunMods:Clean(lplr.Backpack.ChildAdded:Connect(itemAdded))
        local children = char.Character:GetChildren()
        for i = 1, #children do itemAdded(children[i]) end
        children = lplr.Backpack:GetChildren()
        for i = 1, #children do itemAdded(children[i]) end
    end

    GunMods = vape.Categories.Combat:CreateModule({
        Name = "GunMods",
        Function = function(callback)
            if callback then
                if entitylib.character then characterAdded(entitylib.character) end
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
        if not entitylib.isAlive then return false end
        local backpack = lplr:FindFirstChildOfClass("Backpack")
        local character = entitylib.character.Character
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
        if not entitylib.isAlive then return end
        if checkInv(v, name) then return end
        local handle = v:FindFirstChildWhichIsA("MeshPart") or v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
        if handle then
            local position = handle.CFrame
            local new = CFrame.new(position.X, position.Y - 5, position.Z)
            repeat
                t.d.s = new
                pcall(function() GiverPressed:FireServer(v) end)
                task.wait(0.5)
            until checkInv(v, name) or not entitylib.isAlive
            t.d.s = CFrame.new()
        end
    end

    local function canPickup(v)
        if v and v.Parent and v.Parent.Name == "Model" then
            return entitylib.character.Player.Team == criminalsTeam
        end
        return entitylib.character.Player.Team == inmatesTeam or entitylib.character.Player.Team == guardsTeam
    end

    AutoPickup = vape.Categories.Utility:CreateModule({
        Name = "AutoPickup",
        Function = function(callback)
            if callback then
                AutoPickup:Clean(entitylib.Events.LocalAdded:Connect(function()
                    if entitylib.isAlive then
                        for _, item in pairs(PrisonItems) do
                            if item.Enabled and item.Object and canPickup(item.Object) then
                                pickUp(item.Object, item.Gun)
                            end
                        end
                    end
                end))
                AutoPickup:Clean(workspaceService.ChildAdded:Connect(function(v)
                    if v.Name == "Key card" and Keycard.Enabled and lplr.Team ~= guardsTeam then
                        pickUp(v)
                    elseif v.Name == "M9" and M9.Enabled and lplr.Team ~= guardsTeam then
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
            if not PrisonItems[tool] and tool then
                PrisonItems[tool] = AutoPickup:CreateToggle({
                    Name = tool,
                    Tooltip = "Only works on respawn" ..
                        (i and i.Parent and i.Parent.Name == "Model" and " and as a criminal" or " and as an inmate or guard")
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
    local Particles, Boxes = {}, {}
    local AttackDelay = tick()

    Killaura = vape.Categories.Blatant:CreateModule({
        Name = 'KillAura',
        Function = function(callback)
            if callback then
                repeat
                    local attacked = {}
                    local selfpos = entitylib.character.RootPart.Position
                    local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1,0,1)

                    local plrs = entitylib.AllPosition({
                        Range = AttackRange.Value,
                        Wallcheck = Targets.Walls.Enabled or nil,
                        Part = 'RootPart',
                        Players = Targets.Players.Enabled,
                        NPCs = Targets.NPCs.Enabled,
                        Limit = Max.Value
                    })

                    for i = 1, #plrs do
                        local v = plrs[i]
                        local delta = (v.RootPart.Position - selfpos)
                        local angle = math.acos( localfacing:Dot((delta * Vector3.new(1,0,1)).Unit) )
                        if angle <= (math.rad(AngleSlider.Value) / 2) then
                            table.insert(attacked, {
                                Entity = v,
                                Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
                            })
                            targetinfo.Targets[v] = tick() + 1

                            if AttackDelay < tick() then
                                AttackDelay = tick() + (1 / CPS.GetRandomValue())
                                pcall(function()
                                    meleeEvent:FireServer(v.Player, 1, 1)
                                end)
                            end
                        end
                    end

                    for i, box in ipairs(Boxes) do
                        if attacked[i] then
                            box.Adornee = attacked[i].Entity.RootPart
                            box.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
                            box.Transparency = 1 - attacked[i].Check.Opacity
                            box.Visible = true
                        else
                            box.Adornee = nil
                            box.Visible = false
                        end
                    end

                    for i, part in ipairs(Particles) do
                        if attacked[i] then
                            part.Position = attacked[i].Entity.RootPart.Position
                            part.Parent = gameCamera
                        else
                            part.Parent = nil
                        end
                    end

                    if Face.Enabled and #attacked > 0 then
                        local root = attacked[1].Entity.RootPart
                        if root then
                            local vec = root.Position * Vector3.new(1,0,1)
                            entitylib.character.RootPart.CFrame = CFrame.lookAt(
                                entitylib.character.RootPart.Position,
                                Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z)
                            )
                        end
                    end

                    task.wait(0.03)
                until not Killaura.Enabled
            else
                for _, box in pairs(Boxes) do box.Visible = false; box.Adornee = nil end
                for _, part in pairs(Particles) do part.Parent = nil end
            end
        end,
        Tooltip = 'Attack players around you without aiming at them.'
    })
    Targets = Killaura:CreateTargets({Players = true})
    CPS = Killaura:CreateTwoSlider({ Name='Attacks per Second', Min=1, Max=15, DefaultMin=8, DefaultMax=12 })
    AttackRange = Killaura:CreateSlider({ Name='Attack range', Min=1, Max=30, Default=13, Suffix=function(val) return val==1 and 'stud' or 'studs' end })
    AngleSlider = Killaura:CreateSlider({ Name='Max angle', Min=1, Max=360, Default=90 })
    Max = Killaura:CreateSlider({ Name='Max targets', Min=1, Max=10, Default=10 })
    Killaura:CreateToggle({
        Name = 'Show target',
        Function = function(callback)
            BoxSwingColor.Object.Visible = callback
            BoxAttackColor.Object.Visible = callback
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
                for _, v in pairs(Boxes) do v:Destroy() end
                table.clear(Boxes)
            end
        end
    })
    BoxSwingColor = Killaura:CreateColorSlider({ Name='Target Color', Darker=true, DefaultHue=0.6, DefaultOpacity=0.5, Visible=false })
    BoxAttackColor = Killaura:CreateColorSlider({ Name='Attack Color', Darker=true, DefaultOpacity=0.5, Visible=false })
    Killaura:CreateToggle({
        Name = 'Target particles',
        Function = function(callback)
            ParticleTexture.Object.Visible = callback
            ParticleColor1.Object.Visible = callback
            ParticleColor2.Object.Visible = callback
            ParticleSize.Object.Visible = callback
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
                    particles.Size = NumberSequence.new(ParticleSize.Value)
                    particles.Shape = Enum.ParticleEmitterShape.Sphere
                    particles.Texture = ParticleTexture.Value
                    particles.Transparency = NumberSequence.new(0)
                    particles.Lifetime = NumberRange.new(0.4)
                    particles.Speed = NumberRange.new(16)
                    particles.Rate = 128
                    particles.Drag = 16
                    particles.ShapePartial = 1
                    particles.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
                    })
                    particles.Parent = part
                    Particles[i] = part
                end
            else
                for _, v in pairs(Particles) do v:Destroy() end
                table.clear(Particles)
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

    local function Arrest(player, char)
        if not player or not char then return end
        pcall(function()
            ArrestPlayer:InvokeServer(player, 1)
            InteractWithItem:InvokeServer(char.Head)
        end)
        task.spawn(function()
            while Cooldown > 0 do
                task.wait(0.1)
                Cooldown = math.max(0, Cooldown - 0.1)
            end
        end)
    end

    local function Cleanup(plr)
        if Players[plr] then
            for _, conn in pairs(Players[plr]) do conn:Disconnect() end
            Players[plr] = nil
        end
    end

    local function Auto(v)
        if not AutoArrest.Enabled then return end
        if not entitylib.isAlive then return end

        Cleanup(v)
        Players[v] = {}

        local function Listener(char)
            local TasedConnection = char:GetAttributeChangedSignal("Tased"):Connect(function()
                if tick() - Cooldown < 7.5 then
                    notif('Vape', 'Arrest Cooldown: ' .. math.ceil(7.5 - (tick() - Cooldown)) .. 's', 3)
                    return
                end
                if not entitylib.isAlive then return end
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root then return end
                local dist = (entitylib.character.RootPart.Position - root.Position).Magnitude
                if dist > ArrestRange.Value then return end

                if char:GetAttribute("Tased") == true and lplr.Team == guardsTeam then
                    if v.Team == criminalsTeam or (v.Team == inmatesTeam and (char:GetAttribute("Trespassing") or char:GetAttribute("Hostile"))) then
                        local Handcuffs = char:FindFirstChild("Handcuffs") or lplr.Backpack:FindFirstChild("Handcuffs")
                        if Handcuffs then
                            Handcuffs.Parent = char
                            local start = tick()
                            repeat
                                if not entitylib.isAlive then break end
                                if not char or not char:FindFirstChild("HumanoidRootPart") then break end
                                t.d.s = char.HumanoidRootPart.CFrame
                                Arrest(v, char)
                                task.wait(0.1)
                            until (not char) or char:GetAttribute("Arrested") or (tick()-start > 5)
                            Handcuffs.Parent = lplr.Backpack
                            t.d.s = CFrame.new()
                        end
                    end
                end
            end)
            Players[v].TasedConnection = TasedConnection
        end

        if v.Character then Listener(v.Character) end

        Players[v].leaveConnection = entitylib.Events.EntityRemoved:Connect(function(plr)
            if plr.Player == v then Cleanup(v) end
        end)
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
                for _, conns in pairs(Players) do
                    for _, conn in pairs(conns) do conn:Disconnect() end
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
        Default = lplr.DisplayName or lplr.Name or "",
        Placeholder = "New display name"
    })
    local userNameBox = NameChanger:CreateTextBox({
        Name = "User Name",
        Default = lplr.Name or "",
        Placeholder = "New username"
    })
    NameChanger:CreateButton({
        Name = "Set Names",
        Function = function()
            local newDisplay = displayNameBox.Value
            local newUser = userNameBox.Value
            if newDisplay and newDisplay ~= "" then
                lplr.DisplayName = newDisplay
            end
            if newUser and newUser ~= "" then
                lplr.Name = newUser
            end
            notif('Name Changer', 'Names have been updated!', 2, 'success')
        end
    })
end)

print("Hello, V4.8")
