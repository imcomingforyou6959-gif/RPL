repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

-- test
local function httpGet(url, binary)
    local timeout = 10
    if syn and syn.request then
        local response = syn.request({
            Url = url,
            Method = "GET",
            Timeout = timeout,
            Headers = {["Cache-Control"] = "no-cache"}
        })
        if response and response.Body then
            return response.Body
        else
            error("HTTP request failed or timed out")
        end
    elseif http_request then
        local response = http_request({
            Url = url,
            Method = "GET",
            Timeout = timeout
        })
        if response and response.Body then
            return response.Body
        else
            error("HTTP request failed or timed out")
        end
    end
    -- test
    return game:HttpGet(url, binary)
end

if identifyexecutor then
    if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
        getgenv().setthreadidentity = nil
    end
end

local vape
local loadstring = function(...)
    local res, err = loadstring(...)
    if err and vape then
        vape:CreateNotification('Rawr.xyz', 'Failed to load : '..err, 30, 'alert')
    end
    return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
    local suc, res = pcall(function()
        return readfile(file)
    end)
    return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
    return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
    if not isfile(path) then
        local suc, res = pcall(function()
            return httpGet('https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
        end)
        if not suc or res == '404: Not Found' then
            error(res)
        end
        if path:find('.lua') then
            res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
        end
        writefile(path, res)
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
        "Windows.mp3",
        "boolean.ogg", "disable.ogg", "enable.ogg", "keypress.ogg",
        "keyrelease.ogg", "lobby.mp3", "moan1.ogg", "moan2.ogg", "moan3.ogg",
        "moan4.ogg", "orthodox.ogg", "pmsound.ogg", "rifk.ogg"
    }
    local soundFolder = "newvape/assets/sounds/"
    if not isfolder(soundFolder) then
        makefolder(soundFolder)
    end
    for _, fileName in ipairs(soundFiles) do
        local filePath = soundFolder .. fileName
        local success, err = pcall(downloadFile, filePath, nil)
        if not success then
            warn("Failed to download sound: " .. fileName .. " - " .. tostring(err))
        end
    end
end

local function finishLoading()
    vape.Init = nil
    vape:Load()
    task.spawn(function()
        repeat
            vape:Save()
            task.wait(10)
        until not vape.Loaded
    end)

    local teleportedServers
    vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
        if (not teleportedServers) and (not shared.VapeIndependent) then
            teleportedServers = true
            local teleportScript = [[
                shared.vapereload = true
                if shared.VapeDeveloper then
                    loadstring(readfile('newvape/loader.lua'), 'loader')()
                else
                    loadstring(game:HttpGet('https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
                end
            ]]
            if shared.VapeDeveloper then
                teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
            end
            if shared.VapeCustomProfile then
                teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
            end
            vape:Save()
            queue_on_teleport(teleportScript)
        end
    end))

    if not shared.vapereload then
        if not vape.Categories then return end
        if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
            vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
        end
    end
end

if not isfile('newvape/profiles/gui.txt') then
    writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
    makefolder('newvape/assets/'..gui)
end
vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

downloadSounds()

if not shared.VapeIndependent then
    loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
    if isfile('newvape/games/'..game.PlaceId..'.lua') then
        loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
    else
        if not shared.VapeDeveloper then
            local suc, res = pcall(function()
                return httpGet('https://raw.githubusercontent.com/imcomingforyou6959-gif/RPL/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
            end)
            if suc and res ~= '404: Not Found' then
                loadstring(downloadFile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
            end
        end
    end
    finishLoading()
else
    vape.Init = finishLoading
    return vape
end
