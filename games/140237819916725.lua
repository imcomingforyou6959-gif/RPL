

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

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = playersService.LocalPlayer

local vape = shared.vape

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
    local met = getrawmetatable(game)
    if met then
        local oldIdx = met.__index
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
    
    local SilentAim = vape.Categories.Combat:CreateModule({
        Name = "SilentAim",
        Function = function(callback)
            silentEnabled = callback
        end,
        Tooltip = "Redirect bullets to nearest enemy"
    })
    
    SilentAim:CreateToggle({
        Name = "Enable",
        Default = false,
        Function = function(c)
            silentEnabled = c
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
    
    SilentAim:CreateDropdown({
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
            vape:CreateNotification("SilentAim", silentEnabled and "ON" or "OFF", 1, "info")
        end
    end)
end)
