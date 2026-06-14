
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
} do pcall(function() vape:Remove(v) end) end

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
    local fovRadius = 200
    local aimPart = "Head"
    
    local function getClosestToMouse()
        local mousePos = inputService:GetMouseLocation()
        local camera = workspace.CurrentCamera
        local closest, closestDist = nil, math.huge
        
        for _, player in pairs(playersService:GetPlayers()) do
            if player ~= lplr then
                local character = player.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 then
                        local part = character:FindFirstChild(aimPart) or character:FindFirstChild("Head")
                        if part then
                            local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
                            if onScreen and screenPos.Z > 0 then
                                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                                if dist < closestDist and dist <= fovRadius then
                                    closestDist = dist
                                    closest = part
                                end
                            end
                        end
                    end
                end
            end
        end
        return closest
    end
    
    local mouse = lplr:GetMouse()
    local oldIdx
    local met = getrawmetatable(game)
    if met then
        oldIdx = met.__index
        setreadonly(met, false)
        met.__index = newcclosure(function(self, key)
            if silentEnabled and self == mouse and key == "Target" then
                local target = getClosestToMouse()
                if target then
                    return target
                end
            end
            return oldIdx(self, key)
        end)
        setreadonly(met, true)
    end
    
    local SilentAimModule = vape.Categories.Combat:CreateModule({
        Name = "Silent Aim",
        Function = function(callback)
            silentEnabled = callback
        end,
        Tooltip = "Redirect bullets to nearest enemy"
    })
    
    SilentAimModule:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            silentEnabled = c
        end
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
        if input.KeyCode == Enum.KeyCode.C then
            silentEnabled = not silentEnabled
            vape:CreateNotification("Silent Aim", silentEnabled and "ON" or "OFF", 1, "info")
        end
    end)
end)
