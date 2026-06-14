

local run = function(func, issue)
    if issue then return end
    pcall(func)
end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local lightingService = cloneref(game:GetService('Lighting'))
local marketplaceService = cloneref(game:GetService('MarketplaceService'))
local teleportService = cloneref(game:GetService('TeleportService'))
local httpService = cloneref(game:GetService('HttpService'))
local guiService = cloneref(game:GetService('GuiService'))
local groupService = cloneref(game:GetService('GroupService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local contextService = cloneref(game:GetService('ContextActionService'))
local coreGui = cloneref(game:GetService('CoreGui'))

local isnetworkowner = identifyexecutor and table.find({'AWP', 'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end
local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local tween = vape.Libraries.tween
local targetinfo = vape.Libraries.targetinfo
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset

for _, v in {
    'SilentAim', 'Reach', 'AntiFall', 'AntiRagdoll', 'Blink',
    'Disabler', 'SafeWalk', 'MurderMystery', 'TriggerBot',
    'ChatSpammer', 'Arrest Highlight', 'HitNotifications',
    'Bullet Tracers', 'Head Pitch Spinbot (Client)', 'AutoArrest',
    'Anti Riot', 'Anti Taze', 'C4 ESP',
    'AutoReset', 'AutoHeal'
} do vape:Remove(v) end

local blacklistu = "https://raw.githubusercontent.com/imcomingforyou6959-gif/whitelists/refs/heads/main/PlayerBlacklist.json" .. "?t=" .. tick()

local originalRequest = request
local cleanFingerprint = (function(func)
    local str = tostring(func)
    str = string.gsub(str, "0x%x+", "0xXXXXX")
    str = string.gsub(str, "function: %d+", "function: X")
    return str
end)(originalRequest)

local function validateEnvironment()
    local currentFingerprint = (function(func)
        local str = tostring(func)
        str = string.gsub(str, "0x%x+", "0xXXXXX")
        str = string.gsub(str, "function: %d+", "function: X")
        return str
    end)(request)
    
    if currentFingerprint ~= cleanFingerprint then
        return false
    end
    
    return true
end

local function fetchBlacklist()
    if not validateEnvironment() then
        return nil, "validation_failed"
    end
    
    local success, response = pcall(function()
        return request({
            Url = blacklistu,
            Method = "GET"
        })
    end)
    
    if not success then
        return nil, "http_failed"
    end
    
    if not response or not response.Success or response.StatusCode ~= 200 then
        return nil, "http_failed"
    end
    
    local ok, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end)
    
    if ok and data and type(data.BlacklistedUsers) == "table" then
        return data.BlacklistedUsers, "success"
    end
    return nil, "parse_failed"
end

local function isBlacklisted(blacklistTable)
    local userId = game.Players.LocalPlayer.UserId
    return blacklistTable and (blacklistTable[tostring(userId)] or blacklistTable[userId])
end

local function haltExecution(reason)
    pcall(function()
        game.Players.LocalPlayer:Kick("Rawr.xyz | https://discord.gg/RJj7vrNwBy | " .. reason)
    end)
    
    pcall(function()
        game:Shutdown()
    end)
    
    pcall(function()
        game:GetService("TeleportService"):Teleport(0)
    end)
    
    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, gui in ipairs(coreGui:GetChildren()) do
            if gui.Name:find("Rawr") or gui.Name:find("Vape") or gui.Name:find("rawr") then
                gui:Destroy()
            end
        end
        if vape and vape.gui then
            vape.gui:Destroy()
        end
        if _G.rawr_gui then
            _G.rawr_gui:Destroy()
        end
    end)
    
    pcall(function()
        local env = getfenv and getfenv() or _G
        env.loadstring = function() return nil end
        env.load = function() return nil end
        if env.debug then env.debug = nil end
    end)
    
    while true do
        task.wait(9e9)
    end
end

local blacklist = nil
local status = nil
local attempts = 0

while attempts < 3 and blacklist == nil do
    blacklist, status = fetchBlacklist()
    if status == "http_failed" or status == "parse_failed" then
        attempts = attempts + 1
        if attempts < 3 then
            task.wait(1)
        end
    else
        break
    end
end

if status == "validation_failed" then
    haltExecution("Environment tampered")
    return true
end

if blacklist and type(blacklist) == "table" and isBlacklisted(blacklist) then
    haltExecution("You have been blacklisted")
    return true
end

if blacklist == nil then
    haltExecution("Cannot verify blacklist table | Check your Internet")
    return true
end

task.spawn(function()
    while true do
        task.wait(60)
        local blist, st = fetchBlacklist()
        if blist and type(blist) == "table" and isBlacklisted(blist) then
            haltExecution("You have been blacklisted")
            break
        end
        if st == "validation_failed" then
            haltExecution("Environment tampered")
            break
        end
        if blist == nil then
            haltExecution("Cannot verify blacklist - Retry again")
            break
        end
    end
end)

local startWait = tick()
repeat
    task.wait()
until (lplr and lplr.PlayerGui and lplr.PlayerGui:FindFirstChild("nil") 
       and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart"))
       or tick() - startWait > 5

local startWait2 = tick()
repeat
    task.wait()
until (replicatedStorageService and replicatedStorageService:FindFirstChild("remotes") 
       and replicatedStorageService.Remotes:FindFirstChild("events"))
       or tick() - startWait2 > 5

task.wait(0.5)

print("Checked Cilent")

run(function()
    local HitSounds
    local headSoundId = "1255040462"
    local limbSoundId = "1255040462"
    local torsoSoundId = "1255040462"
    local hitSoundsEnabled = false
    
    local config = lplr:FindFirstChild("config")
    if not config then
        config = lplr:WaitForChild("config", 10)
    end
    
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
    
    HitSounds = vape.Categories.Utility:CreateModule({
        Name = "Hit Sounds",
        Function = function(callback)
            hitSoundsEnabled = callback
            if callback then applyHitSounds() else resetHitSounds() end
        end,
        Tooltip = "Custom sounds when you hit enemies"
    })
    
    HitSounds:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            hitSoundsEnabled = c
            if c then applyHitSounds() else resetHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Head Sound",
        List = {"1255040462", "6534947240", "6534947588", "1347140027", "198598793", "3188795283", "130833677", "5332005053", "5332680810", "4578740568", "5633695679", "6534947869", "5766898159", "4018616850", "7553397015", "3124331820"},
        Default = "1255040462",
        Function = function(val)
            headSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Limb Sound",
        List = {"1255040462", "6534947240", "6534947588", "1347140027", "198598793", "3188795283", "130833677", "5332005053", "5332680810", "4578740568", "5633695679", "6534947869", "5766898159", "4018616850", "7553397015", "3124331820"},
        Default = "1255040462",
        Function = function(val)
            limbSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
    
    HitSounds:CreateDropdown({
        Name = "Torso Sound",
        List = {"1255040462", "6534947240", "6534947588", "1347140027", "198598793", "3188795283", "130833677", "5332005053", "5332680810", "4578740568", "5633695679", "6534947869", "5766898159", "4018616850", "7553397015", "3124331820"},
        Default = "1255040462",
        Function = function(val)
            torsoSoundId = val
            if hitSoundsEnabled then applyHitSounds() end
        end
    })
end)

run(function()
    local CrosshairChanger
    local crosshairEnabled = false
    local cursorId = "426730675"
    
    local config = lplr:FindFirstChild("config")
    if not config then
        config = lplr:WaitForChild("config", 10)
    end
    
    local function applyCrosshair()
        if not config then return end
        if not crosshairEnabled then return end
        config.cursor_id = cursorId
    end
    
    local function resetCrosshair()
        if not config then return end
        config.cursor_id = ""
    end
    
    CrosshairChanger = vape.Categories.Utility:CreateModule({
        Name = "Crosshair",
        Function = function(callback)
            crosshairEnabled = callback
            if callback then applyCrosshair() else resetCrosshair() end
        end,
        Tooltip = "Change your crosshair"
    })
    
    CrosshairChanger:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            crosshairEnabled = c
            if c then applyCrosshair() else resetCrosshair() end
        end
    })
    
    CrosshairChanger:CreateTextBox({
        Name = "Crosshair ID",
        Placeholder = "Enter asset ID",
        Default = "426730675",
        Function = function(val)
            cursorId = val
            if crosshairEnabled then applyCrosshair() end
        end
    })
end)

run(function()
    local AutoSprint
    local autoSprintEnabled = false
    local sprintToggled = false
    
    local config = lplr:FindFirstChild("config")
    if not config then
        config = lplr:WaitForChild("config", 10)
    end
    
    local function setSprint(value)
        if not config then return end
        if config.sprint_toggle ~= nil then
            config.sprint_toggle = value
        elseif config.auto_sprint ~= nil then
            config.auto_sprint = value
        elseif config.sprint ~= nil then
            config.sprint = value
        else
            if lplr.Character then
                local humanoid = lplr.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:SetAttribute("Sprinting", value)
                end
            end
        end
    end
    
    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not autoSprintEnabled then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            sprintToggled = not sprintToggled
            setSprint(sprintToggled)
            vape:CreateNotification("Auto Sprint", sprintToggled and "Sprint ON" or "Sprint OFF", 1, "info")
        end
    end)
    
    AutoSprint = vape.Categories.Utility:CreateModule({
        Name = "Auto Sprint",
        Function = function(callback)
            autoSprintEnabled = callback
            if not callback then
                sprintToggled = false
                setSprint(false)
            end
        end,
        Tooltip = "Press Shift once to toggle sprint"
    })
    
    AutoSprint:CreateToggle({
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
end)

run(function()
    local NoSpread
    local noSpreadEnabled = false
    
    local function modifySpread()
        local playersFolder = workspace:FindFirstChild("players")
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
        local playersFolder = workspace:FindFirstChild("players")
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
    
    NoSpread = vape.Categories.Combat:CreateModule({
        Name = "No Spread",
        Function = function(callback)
            noSpreadEnabled = callback
            if callback then modifySpread() end
        end,
        Tooltip = "Removes bullet spread"
    })
    
    NoSpread:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            noSpreadEnabled = c
            if c then modifySpread() end
        end
    })
end)

run(function()
    local SilentAim
    local enabled = false
    local aimPart = "Head"
    local fovRadius = 200
    local hitChance = 100
    local range = 800
    
    local mainEvent = replicatedStorage:FindFirstChild("remotes")
    if mainEvent then mainEvent = mainEvent:FindFirstChild("events") end
    if mainEvent then mainEvent = mainEvent:FindFirstChild("main_event") end
    
    local function getClosestEnemy()
        local myChar = lplr.Character
        if not myChar then return nil end
        local myHead = myChar:FindFirstChild("Head")
        if not myHead then return nil end
        
        local playersFolder = workspace:FindFirstChild("players")
        if not playersFolder then return nil end
        
        local camera = workspace.CurrentCamera
        local mousePos = inputService:GetMouseLocation()
        
        local closest, closestDist = nil, math.huge
        
        for _, player in pairs(playersFolder:GetChildren()) do
            if player.Name ~= lplr.Name then
                local targetPart = player:FindFirstChild(aimPart) or player:FindFirstChild("Head")
                local hum = player:FindFirstChildOfClass("Humanoid")
                
                if targetPart and hum and hum.Health > 0 then
                    local dist = (targetPart.Position - myHead.Position).Magnitude
                    if dist <= range then
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
        end
        
        return closest
    end
    
    if mainEvent then
        local oldFire = mainEvent.FireServer
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
                        end
                    end
                end
            end
            return oldFire(self, data, token)
        end
    end
    
    SilentAim = vape.Categories.Combat:CreateModule({
        Name = "Silent Aim",
        Function = function(callback)
            enabled = callback
        end,
        Tooltip = "Silently redirect bullets to enemies"
    })
    
    SilentAim:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            enabled = c
        end
    })
    
    SilentAim:CreateDropdown({
        Name = "Aim Part",
        List = {"Head", "Torso", "HumanoidRootPart"},
        Default = "Head",
        Function = function(v)
            aimPart = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 200,
        Suffix = "px",
        Function = function(v)
            fovRadius = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "Range",
        Min = 50,
        Max = 1000,
        Default = 800,
        Suffix = "studs",
        Function = function(v)
            range = v
        end
    })
    
    SilentAim:CreateSlider({
        Name = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%",
        Function = function(v)
            hitChance = v
        end
    })
end)
