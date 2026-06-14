
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

run(function()
    local hitSound = Instance.new("Sound")
    hitSound.SoundId = "rbxassetid://1255040462"
    hitSound.Volume = 0.5
    hitSound.Parent = game:GetService("SoundService")
    
    local hitSoundEnabled = false
    local lastHealth = {}
    
    local function checkHit(player)
        if not player or not player.Character then return end
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local oldHealth = lastHealth[player.Name] or humanoid.Health
            if humanoid.Health < oldHealth then
                hitSound:Play()
            end
            lastHealth[player.Name] = humanoid.Health
        end
    end
    
    local function monitorHealth()
        for _, player in pairs(playersService:GetPlayers()) do
            if player ~= lplr then
                if player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        lastHealth[player.Name] = humanoid.Health
                        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                            if hitSoundEnabled then
                                checkHit(player)
                            end
                        end)
                    end
                end
                player.CharacterAdded:Connect(function(char)
                    char:WaitForChild("Humanoid", 5)
                    local humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        lastHealth[player.Name] = humanoid.Health
                        humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                            if hitSoundEnabled then
                                checkHit(player)
                            end
                        end)
                    end
                end)
            end
        end
    end
    
    task.spawn(monitorHealth)
    
    local HitSoundsModule = vape.Categories.Utility:CreateModule({
        Name = "Hit Sounds",
        Function = function(callback)
            hitSoundEnabled = callback
        end,
        Tooltip = "Plays sound when you hit an enemy"
    })
    
    HitSoundsModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            hitSoundEnabled = c
        end
    })
    
    HitSoundsModule:CreateSlider({
        Name = "Volume",
        Min = 0,
        Max = 100,
        Default = 50,
        Function = function(v)
            hitSound.Volume = v / 100
        end,
        Suffix = "%"
    })
end)

run(function()
    local silentEnabled = false
    local silentActive = false
    local targetPlayer = nil
    local targetPart = nil
    local targetPosition = nil
    local fovRadius = 200
    local hitChance = 100
    local aimPart = "Head"
    
    local function isValidTarget(player)
        if not player then return false end
        if player == lplr then return false end
        local character = player.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return false end
        return true
    end
    
    local function getClosestToMouse()
        local mousePos = inputService:GetMouseLocation()
        local camera = workspace.CurrentCamera
        local closest, closestDist = nil, math.huge
        
        for _, player in pairs(playersService:GetPlayers()) do
            if isValidTarget(player) then
                local part = player.Character:FindFirstChild(aimPart) or player.Character:FindFirstChild("Head")
                if part then
                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and screenPos.Z > 0 then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < closestDist and dist <= fovRadius then
                            closestDist = dist
                            closest = player
                            targetPart = part
                            targetPosition = part.Position
                        end
                    end
                end
            end
        end
        return closest
    end
    
    runService.RenderStepped:Connect(function()
        if silentEnabled and silentActive then
            targetPlayer = getClosestToMouse()
        end
    end)
    
    local mouse = lplr:GetMouse()
    local rawMeta = getrawmetatable(game)
    local oldIndex = rawMeta.__index
    
    setreadonly(rawMeta, false)
    rawMeta.__index = newcclosure(function(self, key)
        if silentEnabled and silentActive and self == mouse then
            if key == "Hit" and targetPosition then
                return CFrame.new(targetPosition)
            elseif key == "Target" and targetPart then
                return targetPart
            elseif (key == "X" or key == "Y") and targetPosition then
                local screenPos = workspace.CurrentCamera:WorldToViewportPoint(targetPosition)
                if key == "X" then
                    return screenPos.X
                else
                    return screenPos.Y
                end
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(rawMeta, true)
    
    local SilentAimModule = vape.Categories.Combat:CreateModule({
        Name = "Silent Aim",
        Function = function(callback)
            silentEnabled = callback
            if not callback then
                silentActive = false
                targetPlayer = nil
                targetPart = nil
                targetPosition = nil
            end
        end,
        Tooltip = "Redirect bullets to nearest enemy"
    })
    
    SilentAimModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            silentEnabled = c
            if not c then
                silentActive = false
            end
        end
    })
    
    SilentAimModule:CreateToggle({
        Name = "Active",
        Default = false,
        Function = function(c)
            silentActive = c
        end,
        Tooltip = "Toggle to activate silent aim"
    })
    
    SilentAimModule:CreateSlider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Default = 200,
        Suffix = "px",
        Function = function(v)
            fovRadius = v
        end
    })
    
    SilentAimModule:CreateSlider({
        Name = "Hit Chance",
        Min = 0,
        Max = 100,
        Default = 100,
        Suffix = "%",
        Function = function(v)
            hitChance = v
        end
    })
    
    SilentAimModule:CreateDropdown({
        Name = "Aim Part",
        List = {"Head", "Torso", "HumanoidRootPart"},
        Default = "Head",
        Function = function(v)
            aimPart = v
        end
    })
    
    inputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not silentEnabled then return end
        if input.KeyCode == Enum.KeyCode.C then
            silentActive = not silentActive
            vape:CreateNotification("Silent Aim", silentActive and "ON" or "OFF", 1, "info")
        end
    end)
end)
