--[[
    Prison Duels Script
    Modules: Hit Sounds, Crosshair, Auto Sprint, No Spread, Silent Aim
]]

-- ============================================
-- GLOBALS & SETUP
-- ============================================

local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")
local inputService = game:GetService("UserInputService")
local workspaceService = game:GetService("Workspace")

local lplr = playersService.LocalPlayer
local vape = shared.vape

-- Find available categories
local category = nil
if vape.Categories then
    if vape.Categories.Utility then
        category = vape.Categories.Utility
    elseif vape.Categories.Misc then
        category = vape.Categories.Misc
    elseif vape.Categories.Other then
        category = vape.Categories.Other
    else
        for _, cat in pairs(vape.Categories) do
            category = cat
            break
        end
    end
end

local function createModule(name, callback)
    if category then
        return category:CreateModule({Name = name, Function = callback})
    else
        return vape:CreateModule({Name = name, Function = callback})
    end
end

local config = lplr:FindFirstChild("config")
if not config then
    config = lplr:WaitForChild("config", 10)
end

local mainEvent = replicatedStorage:FindFirstChild("remotes") and 
                  replicatedStorage.remotes:FindFirstChild("events") and
                  replicatedStorage.remotes.events:FindFirstChild("main_event")

local function notif(...) 
    if vape and vape.CreateNotification then
        return vape:CreateNotification(...)
    end
end

local soundIds = {
    "1255040462",  -- Rust
    "6534947240",  -- Bell
    "6534947588",  -- Bubble
    "1347140027",  -- Pick
    "198598793",   -- Pop
    "3188795283",  -- Sans
    "130833677",   -- Fart
    "5332005053",  -- Big
    "5332680810",  -- Vine
    "4578740568",  -- Bruh
    "5633695679",  -- Skeet
    "6534947869",  -- Fatality
    "5766898159",  -- Bonk
    "4018616850",  -- Minecraft
    "7553397015",  -- TomScream
    "3124331820",

local soundNames = {}
for _, id in ipairs(soundIds) do
    table.insert(soundNames, id)
end

do
    local headSoundId = "1255040462"
    local limbSoundId = "1255040462"
    local torsoSoundId = "1255040462"
    local hitSoundsEnabled = false
    local module = nil
    
    local function applyHitSounds()
        if not config then return end
        if not hitSoundsEnabled then return end
        config.head_hit_sound = headSoundId
        config.limb_hit_sound = limbSoundId
        config.torso_hit_sound = torsoSoundId
    end
    
    local function resetHitSounds()
        if not config then return end
        config.head_hit_sound = ""
        config.limb_hit_sound = ""
        config.torso_hit_sound = ""
    end
    
    module = createModule("Hit Sounds", function(callback)
        hitSoundsEnabled = callback
        if callback then applyHitSounds() else resetHitSounds() end
    end)
    
    if module then
        module:CreateToggle({
            Name = "Enable",
            Default = false,
            Function = function(c)
                hitSoundsEnabled = c
                if c then applyHitSounds() else resetHitSounds() end
            end
        })
        
        module:CreateDropdown({
            Name = "Head Sound",
            List = soundNames,
            Default = "1255040462",
            Function = function(val)
                headSoundId = val
                if hitSoundsEnabled then applyHitSounds() end
            end
        })
        
        module:CreateDropdown({
            Name = "Limb Sound",
            List = soundNames,
            Default = "1255040462",
            Function = function(val)
                limbSoundId = val
                if hitSoundsEnabled then applyHitSounds() end
            end
        })
        
        module:CreateDropdown({
            Name = "Torso Sound",
            List = soundNames,
            Default = "1255040462",
            Function = function(val)
                torsoSoundId = val
                if hitSoundsEnabled then applyHitSounds() end
            end
        })
    end
end

do
    local crosshairEnabled = false
    local cursorId = "426730675"
    local module = nil
    
    local function applyCrosshair()
        if not config then return end
        if not crosshairEnabled then return end
        config.cursor_id = cursorId
    end
    
    local function resetCrosshair()
        if not config then return end
        config.cursor_id = ""
    end
    
    module = createModule("Crosshair", function(callback)
        crosshairEnabled = callback
        if callback then applyCrosshair() else resetCrosshair() end
    end)
    
    if module then
        module:CreateToggle({
            Name = "Enable",
            Default = false,
            Function = function(c)
                crosshairEnabled = c
                if c then applyCrosshair() else resetCrosshair() end
            end
        })
        
        module:CreateTextBox({
            Name = "Crosshair ID",
            Placeholder = "Enter asset ID",
            Default = "426730675",
            Function = function(val)
                cursorId = val
                if crosshairEnabled then applyCrosshair() end
            end
        })
    end
end

do
    local autoSprintEnabled = false
    local sprintToggled = false
    local module = nil
    
    local function setSprint(value)
        if not config then return end
        config.toggle_sprint = value
    end
    
    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not autoSprintEnabled then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            sprintToggled = not sprintToggled
            setSprint(sprintToggled)
            if notif then notif("Auto Sprint", sprintToggled and "Sprint ON" or "Sprint OFF", 1, "info") end
        end
    end)
    
    module = createModule("Auto Sprint", function(callback)
        autoSprintEnabled = callback
        if not callback then
            sprintToggled = false
            setSprint(false)
        end
    end)
    
    if module then
        module:CreateToggle({
            Name = "Enable",
            Default = false,
            Function = function(c)
                autoSprintEnabled = c
                if not c then
                    sprintToggled = false
                    setSprint(false)
                end
            end
        })
    end
end

do
    local noSpreadEnabled = false
    local module = nil
    
    local function modifySpread()
        local playersFolder = workspaceService:FindFirstChild("players")
        if not playersFolder then return end
        
        for _, player in pairs(playersFolder:GetChildren()) do
            for _, tool in pairs(player:GetChildren()) do
                if tool:IsA("Tool") and noSpreadEnabled then
                    tool:SetAttribute("spread", 0)
                end
            end
        end
    end
    
    local function watchForWeapons()
        local playersFolder = workspaceService:FindFirstChild("players")
        if not playersFolder then return end
        
        playersFolder.ChildAdded:Connect(function(player)
            player.ChildAdded:Connect(function(tool)
                task.wait(0.1)
                modifySpread()
            end)
        end)
        
        for _, player in pairs(playersFolder:GetChildren()) do
            player.ChildAdded:Connect(function(tool)
                task.wait(0.1)
                modifySpread()
            end)
        end
    end
    
    task.spawn(watchForWeapons)
    
    module = createModule("No Spread", function(callback)
        noSpreadEnabled = callback
        if callback then modifySpread() end
    end)
    
    if module then
        module:CreateToggle({
            Name = "Enable",
            Default = false,
            Function = function(c)
                noSpreadEnabled = c
                if c then modifySpread() end
            end
        })
    end
end

do
    local enabled = false
    local aimPart = "Head"
    local fovRadius = 200
    local hitChance = 100
    local range = 800
    local module = nil
    local oldFire = nil
    
    local function getClosestEnemy()
        local myChar = lplr.Character
        if not myChar then return nil end
        local myHead = myChar:FindFirstChild("Head")
        if not myHead then return nil end
        
        local playersFolder = workspaceService:FindFirstChild("players")
        if not playersFolder then return nil end
        
        local camera = workspaceService.CurrentCamera
        local mousePos = inputService:GetMouseLocation()
        
        local closest, closestDist = nil, math.huge
        
        for _, player in pairs(playersFolder:GetChildren()) do
            if player.Name ~= lplr.Name then
                local targetPart = player:FindFirstChild(aimPart) or player:FindFirstChild("Head")
                local hum = player:FindFirstChildOfClass("Humanoid")
                
                if targetPart and hum and hum.Health > 0 then
                    local dist = (targetPart.Position - myHead.Position).Magnitude
                    if dist > range then continue end
                    
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen and screenPos.Z > 0 then
                        local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if fovDist < closestDist and fovDist <= fovRadius then
                            closestDist = fovDist
                            closest = targetPart
                        end
                    end
                end
            end
        end
        
        return closest
    end
    
    if mainEvent then
        oldFire = mainEvent.FireServer
        mainEvent.FireServer = function(self, data, token)
            if enabled and data and type(data) == "table" and math.random(100) <= hitChance then
                local target = getClosestEnemy()
                if target then
                    local myHead = lplr.Character and lplr.Character:FindFirstChild("Head")
                    if myHead then
                        if type(data) == "table" then
                            for i, hit in pairs(data) do
                                if type(hit) == "table" then
                                    hit[2] = target.Position
                                    hit[3] = target
                                end
                            end
                        elseif data[1] and type(data[1]) == "table" then
                            for i, hit in pairs(data) do
                                if type(hit) == "table" then
                                    hit[2] = target.Position
                                    hit[3] = target
                                end
                            end
                        end
                    end
                end
            end
            return oldFire(self, data, token)
        end
    else
        warn("Silent Aim: Could not find main_event remote")
    end
    
    module = createModule("Silent Aim", function(callback)
        enabled = callback
    end)
    
    if module then
        module:CreateToggle({
            Name = "Enable",
            Default = false,
            Function = function(c)
                enabled = c
            end
        })
        
        module:CreateDropdown({
            Name = "Aim Part",
            List = {"Head", "Torso", "HumanoidRootPart"},
            Default = "Head",
            Function = function(v)
                aimPart = v
            end
        })
        
        module:CreateSlider({
            Name = "FOV",
            Min = 10,
            Max = 500,
            Default = 200,
            Suffix = "px",
            Function = function(v)
                fovRadius = v
            end
        })
        
        module:CreateSlider({
            Name = "Range",
            Min = 50,
            Max = 1000,
            Default = 800,
            Suffix = "studs",
            Function = function(v)
                range = v
            end
        })
        
        module:CreateSlider({
            Name = "Hit Chance",
            Min = 0,
            Max = 100,
            Default = 100,
            Suffix = "%",
            Function = function(v)
                hitChance = v
            end
        })
    end
end

if vape and vape.Clean then
    vape:Clean(function()
        if config then
            config.head_hit_sound = ""
            config.limb_hit_sound = ""
            config.torso_hit_sound = ""
            config.cursor_id = ""
            config.toggle_sprint = false
        end
        
        if mainEvent and oldFire then
            mainEvent.FireServer = oldFire
        end
        
        if notif then notif("Prison Duels", "All modules cleaned up", 2, "info") end
    end)
end

if notif then notif("Prison Duels", "Loaded successfully!", 3, "success") end
