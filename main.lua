repeat task.wait() until game:IsLoaded()

if shared.vape then 
    pcall(function() shared.vape:Uninject() end) 
end

local function getExecutorName()
    if not identifyexecutor then return nil end
    local success, name = pcall(identifyexecutor)
    if success and name then
        return name
    end
    return nil
end

local executorName = getExecutorName()
if executorName and table.find({'Argon', 'Wave'}, executorName) then
    getgenv().setthreadidentity = nil
end

local vape
local function safeLoadString(code, chunkName)
    local success, result = pcall(loadstring, code, chunkName)
    if not success and vape then
        vape:CreateNotification('Rawr.xyz', 'Failed to load: '..tostring(result), 30, 'alert')
    end
    return result
end

local queue_on_teleport = queue_on_teleport or function() end

local function fileExists(file)
    local success, result = pcall(readfile, file)
    return success and result ~= nil and result ~= ''
end

local function readFileSafe(file)
    local success, result = pcall(readfile, file)
    if success then return result end
    return nil
end

local function getCommit()
    local commit = readFileSafe('newvape/profiles/commit.txt')
    if not commit or commit == '' then
        return 'main'
    end
    return commit
end

local function downloadFile(path, func)
    if not fileExists(path) then
        local commit = getCommit()
        local relativePath = path:gsub('newvape/', '')
        local url = 'https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/' .. commit .. '/' .. relativePath
        
        local success, res = pcall(function()
            return game:HttpGet(url, true)
        end)
        
        if not success or res == '404: Not Found' then
            error(tostring(res))
        end
        
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
        end
        
        pcall(function() writefile(path, res) end)
    end
    return (func or readfile)(path)
end

local function downloadSounds()
    local soundFiles = {
        "1nn.mp3", "67.mp3", "BatHit.mp3", "Beep.mp3", "Bonk.mp3", "Bow.mp3",
        "Bubble.mp3", "Bubble2.mp3", "CSGO.mp3", "Cod.mp3", "Fairy1.mp3",
        "Fairy2.mp3", "Fatality.mp3", "Fatality2.mp3", "Hentai1.mp3",
        "Hentai2.mp3", "Hentai3.mp3", "Lazer.mp3", "MarioCoins.mp3",
        "MinecraftXP.mp3", "Neverlose.mp3", "OSU.mp3", "PubgPan.mp3",
        "Rifk7.mp3", "RustHeadshot.mp3", "Skeet.mp3", "SpanishMoan.mp3",
        "StaryKrow.mp3", "Steve.mp3", "TF2Crit.mp3", "TF2Default.mp3",
        "Windows.mp3", "boolean.ogg", "disable.ogg", "enable.ogg", "keypress.ogg",
        "keyrelease.ogg", "lobby.mp3", "moan1.ogg", "moan2.ogg", "moan3.ogg",
        "moan4.ogg", "orthodox.ogg", "pmsound.ogg", "rifk.ogg"
    }
    
    local soundFolder = "newvape/assets/sounds/"
    
    pcall(function() makefolder(soundFolder) end)
    
    for _, fileName in ipairs(soundFiles) do
        local filePath = soundFolder .. fileName
        pcall(downloadFile, filePath, nil)
    end
end

local function finishLoading()
    if not vape then return end
    
    vape.Init = nil
    pcall(function() vape:Load() end)
    
    task.spawn(function()
        while vape and vape.Loaded do
            pcall(function() vape:Save() end)
            task.wait(10)
        end
    end)

    pcall(function()
        playersService.LocalPlayer.OnTeleport:Connect(function()
            if not shared.VapeIndependent then
                local teleportScript = [[
                    shared.vapereload = true
                    pcall(function()
                        if shared.VapeDeveloper then
                            loadfile('newvape/loader.lua')()
                        else
                            local commit = pcall(readfile, 'newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or 'main'
                            loadstring(game:HttpGet('https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/']] .. getCommit() .. [[/loader.lua', true))()
                        end
                    end)
                ]]
                
                if shared.VapeDeveloper then
                    teleportScript = 'shared.VapeDeveloper = true\n' .. teleportScript
                end
                if shared.VapeCustomProfile then
                    teleportScript = 'shared.VapeCustomProfile = "' .. shared.VapeCustomProfile .. '"\n' .. teleportScript
                end
                
                pcall(function() vape:Save() end)
                queue_on_teleport(teleportScript)
            end
        end)
    end)

    if not shared.vapereload and vape and vape.Categories and vape.Categories.Main and vape.Categories.Main.Options['GUI bind indicator'] and vape.Categories.Main.Options['GUI bind indicator'].Enabled then
        vape:CreateNotification('Finished Loading', (vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press ' .. table.concat(vape.Keybind or {'RightShift'}, ' + '):upper() .. ' to open GUI'), 5)
    end
end

if not fileExists('newvape/profiles/gui.txt') then
    pcall(function() writefile('newvape/profiles/gui.txt', 'new') end)
end

local gui = readFileSafe('newvape/profiles/gui.txt') or 'new'

pcall(function() makefolder('newvape/assets/' .. gui) end)

local guiCode = downloadFile('newvape/guis/' .. gui .. '.lua', nil)
vape = safeLoadString(guiCode, 'gui')
if not vape then return end

shared.vape = vape

task.spawn(downloadSounds)

if not shared.VapeIndependent then
    local universalCode = downloadFile('newvape/games/universal.lua', nil)
    safeLoadString(universalCode, 'universal')()
    
    local gameFile = 'newvape/games/' .. game.PlaceId .. '.lua'
    if fileExists(gameFile) then
        local gameCode = readFileSafe(gameFile)
        if gameCode then
            safeLoadString(gameCode, tostring(game.PlaceId))(...)
        end
    elseif not shared.VapeDeveloper then
        local commit = getCommit()
        local url = 'https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/' .. commit .. '/games/' .. game.PlaceId .. '.lua'
        local success, res = pcall(game.HttpGet, game, url, true)
        if success and res ~= '404: Not Found' then
            local gameCode = downloadFile('newvape/games/' .. game.PlaceId .. '.lua', nil)
            safeLoadString(gameCode, tostring(game.PlaceId))(...)
        end
    end
    
    finishLoading()
else
    vape.Init = finishLoading
    return vape
end
