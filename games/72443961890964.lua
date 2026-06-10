local playersService = cloneref(game:GetService('Players'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo


run(function()
    local SilentAim
    local Mode
    local HitPart
    local HitChance
    local AutoShoot
    local Spectate
    local WhitelistEnabled
    local BlacklistEnabled
    local AutoBlockFriends
    local WhitelistPlayers
    local BlacklistPlayers
    local renderConn
    local spectateConn
    local spectateTarget = nil
    local targetPlayer = nil
    local targetPart = nil
    local targetPosition = nil
    local active = false
    local lastHealth = {}
    local wasKnocked = {}
    local stickyTarget = nil
    local pickTime = nil
    local multiTargets = {}
    local highlightObjects = {}
    local lineObjects = {}
    local lineShadows = {}

    local function isAlive(plr)
        if not plr or not plr.Character then return false end
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 0
    end

    local function isKnocked(plr)
        local char = plr.Character
        if char then
            local bodyEffects = char:FindFirstChild("BodyEffects")
            if bodyEffects and bodyEffects:FindFirstChild("K.O") then
                return bodyEffects["K.O"].Value
            end
        end
        return false
    end

    local function isProtected(plr)
        local char = plr.Character
        if char then
            return char:FindFirstChildOfClass("ForceField") ~= nil
        end
        return false
    end

    local function isValid(plr)
        if not plr or plr == lplr then return false end
        if not isAlive(plr) then return false end
        if isKnocked(plr) then return false end
        if isProtected(plr) then return false end

        if AutoBlockFriends and AutoBlockFriends.Enabled then
            if shared.FriendsCache and shared.FriendsCache[plr.UserId] then return false end
        end

        if BlacklistEnabled and BlacklistEnabled.Enabled and BlacklistPlayers then
            local sel = BlacklistPlayers.Value or {}
            local name = plr.Name
            local dname = plr.DisplayName
            if sel[name] or sel[dname] then return false end
        end

        if WhitelistEnabled and WhitelistEnabled.Enabled and WhitelistPlayers then
            local sel = WhitelistPlayers.Value or {}
            if not next(sel) then return true end
            local name = plr.Name
            local dname = plr.DisplayName
            if not (sel[name] or sel[dname]) then return false end
        end

        return true
    end

    local function getClosestToMouse()
        local mousePos = inputService:GetMouseLocation()
        local best, bestDist = nil, math.huge
        for _, plr in ipairs(playersService:GetPlayers()) do
            if not isValid(plr) then continue end
            local head = plr.Character:FindFirstChild("Head")
            if not head then continue end
            local pos, onScreen = gameCamera:WorldToViewportPoint(head.Position)
            if not onScreen then continue end
            local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = plr
            end
        end
        return best
    end

    local function getAllValid()
        local list = {}
        for _, plr in ipairs(playersService:GetPlayers()) do
            if isValid(plr) then table.insert(list, plr) end
        end
        return list
    end

    local function updateTarget()
        local mode = Mode and Mode.Value or "Sticky"

        if mode == "Sticky" then
            if stickyTarget and isValid(stickyTarget) then
                targetPlayer = stickyTarget
            else
                stickyTarget = nil
                targetPlayer = nil
            end
        elseif mode == "Auto Select" then
            stickyTarget = nil
            targetPlayer = getClosestToMouse()
        elseif mode == "Target All" then
            stickyTarget = nil
            local all = getAllValid()
            if #all > 0 then
                if not targetPlayer or not isValid(targetPlayer) then
                    targetPlayer = all[math.random(#all)]
                    pickTime = tick()
                elseif pickTime and tick() - pickTime > 10 then
                    targetPlayer = all[math.random(#all)]
                    pickTime = tick()
                end
            else
                targetPlayer = nil
            end
        elseif mode == "Multi" then
            stickyTarget = nil
            local primary = getClosestToMouse()
            if primary then
                targetPlayer = primary
                multiTargets = {primary}
                local second = nil
                local secondDist = math.huge
                local mousePos = inputService:GetMouseLocation()
                for _, plr in ipairs(playersService:GetPlayers()) do
                    if plr == primary then continue end
                    if not isValid(plr) then continue end
                    local head = plr.Character:FindFirstChild("Head")
                    if not head then continue end
                    local pos, onScreen = gameCamera:WorldToViewportPoint(head.Position)
                    if not onScreen then continue end
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < secondDist then
                        secondDist = dist
                        second = plr
                    end
                end
                if second then table.insert(multiTargets, second) end
            end
        end

        if targetPlayer and targetPlayer.Character then
            targetPart = targetPlayer.Character:FindFirstChild("Head") or targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                targetPosition = targetPart.Position
            end
        end
    end

    local function updateHighlights()
        if Spectate and Spectate.Enabled and targetPlayer and targetPlayer.Character then
            local name = targetPlayer.Name
            if not highlightObjects[name] then
                local hl = Instance.new("Highlight")
                hl.FillColor = Color3.fromRGB(255, 100, 100)
                hl.OutlineColor = Color3.fromRGB(255, 50, 50)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.3
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = targetPlayer.Character
                highlightObjects[name] = hl
            end
            for n, hl in pairs(highlightObjects) do
                if n ~= targetPlayer.Name then
                    hl:Destroy()
                    highlightObjects[n] = nil
                end
            end
        else
            for _, hl in pairs(highlightObjects) do
                hl:Destroy()
            end
            table.clear(highlightObjects)
        end
    end

    local function updateLines()
        if not targetPlayer or not targetPlayer.Character then return end
        local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local pos, onScreen = gameCamera:WorldToViewportPoint(root.Position)
        if not onScreen then return end
        local mousePos = inputService:GetMouseLocation()
        local screenPos = Vector2.new(pos.X, pos.Y)

        if #lineObjects < 1 then
            lineObjects[1] = Drawing.new("Line")
            lineObjects[1].Color = Color3.fromRGB(255, 255, 255)
            lineObjects[1].Thickness = 1
            lineObjects[1].ZIndex = 3
            lineShadows[1] = Drawing.new("Line")
            lineShadows[1].Color = Color3.new(0, 0, 0)
            lineShadows[1].Thickness = 3
            lineShadows[1].ZIndex = 2
        end

        lineShadows[1].From = mousePos
        lineShadows[1].To = screenPos
        lineShadows[1].Visible = true
        lineObjects[1].From = mousePos
        lineObjects[1].To = screenPos
        lineObjects[1].Visible = true
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method:lower() ~= "raycast" or self ~= workspace then return oldNamecall(self, ...) end
        if checkcaller() then return oldNamecall(self, ...) end
        if not active then return oldNamecall(self, ...) end
        if math.random(100) > (HitChance and HitChance.Value or 100) then return oldNamecall(self, ...) end

        local args = {...}
        if targetPart and targetPosition then
            local delta = targetPosition - args[2]
            return {
                Instance = targetPart,
                Position = targetPosition,
                Normal = delta.Unit,
                Distance = delta.Magnitude,
                Material = targetPart.Material
            }
        end
        return oldNamecall(self, ...)
    end)

    SilentAim = vape.Categories.Combat:CreateModule({
        Name = "Silent Aim",
        Function = function(callback)
            active = callback
            if callback then
                stickyTarget = nil
                targetPlayer = nil
                targetPart = nil
                targetPosition = nil
                renderConn = runService.RenderStepped:Connect(function()
                    updateTarget()
                    updateHighlights()
                    updateLines()
                    if AutoShoot and AutoShoot.Enabled and targetPlayer then
                        local tool = lplr.Character and lplr.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate()
                        end
                    end
                    if Spectate and Spectate.Enabled and targetPlayer and targetPlayer.Character then
                        gameCamera.CameraSubject = targetPlayer.Character
                    end
                end)
            else
                if renderConn then renderConn:Disconnect(); renderConn = nil end
                targetPlayer = nil
                targetPart = nil
                targetPosition = nil
                for _, hl in pairs(highlightObjects) do hl:Destroy() end
                table.clear(highlightObjects)
                for _, line in pairs(lineObjects) do line.Visible = false end
                for _, line in pairs(lineShadows) do line.Visible = false end
                gameCamera.CameraSubject = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid") or nil
            end
        end,
        Tooltip = "Silent Aim with multiple targeting modes"
    })

    Mode = SilentAim:CreateDropdown({
        Name = "Mode",
        List = {"Sticky", "Auto Select", "Target All", "Multi"},
        Default = "Sticky",
        Function = function(v)
            stickyTarget = nil
            targetPlayer = nil
            pickTime = nil
            multiTargets = {}
        end
    })

    HitPart = SilentAim:CreateDropdown({
        Name = "Hit Part",
        List = {"Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Head"
    })

    HitChance = SilentAim:CreateSlider({
        Name = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%"
    })

    AutoShoot = SilentAim:CreateToggle({
        Name = "Auto Shoot",
        Default = false
    })

    Spectate = SilentAim:CreateToggle({
        Name = "Spectate Target",
        Default = false,
        Function = function(v)
            if not v then
                gameCamera.CameraSubject = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid") or nil
            end
        end
    })

    WhitelistEnabled = SilentAim:CreateToggle({
        Name = "Whitelist",
        Default = false
    })

    BlacklistEnabled = SilentAim:CreateToggle({
        Name = "Blacklist",
        Default = false
    })

    AutoBlockFriends = SilentAim:CreateToggle({
        Name = "Block Friends",
        Default = true
    })

    local function getPlayerNames()
        local names = {}
        for _, plr in ipairs(playersService:GetPlayers()) do
            if plr ~= lplr then
                table.insert(names, plr.Name)
            end
        end
        return names
    end

    WhitelistPlayers = SilentAim:CreateMultiChoice({
        Name = "Whitelist Players",
        List = getPlayerNames(),
        Default = {},
        Function = function() end
    })

    BlacklistPlayers = SilentAim:CreateMultiChoice({
        Name = "Blacklist Players",
        List = getPlayerNames(),
        Default = {},
        Function = function() end
    })

    vape:Clean(function()
        if renderConn then renderConn:Disconnect() end
        if oldNamecall then hookmetamethod(game, "__namecall", oldNamecall) end
        for _, hl in pairs(highlightObjects) do hl:Destroy() end
        for _, line in pairs(lineObjects) do if line.Remove then line:Remove() end end
        for _, line in pairs(lineShadows) do if line.Remove then line:Remove() end end
    end)
end)
