-- Don't alter these variables, otherwise you will fuck shit up
local flyEffects = {}
local playerDirt = 0

function spawnFlySwarm(ped)
    if not DoesEntityExist(ped) then return end

    local particleDict = "core"
    local particleName = "ent_amb_fly_swarm" -- Flies particles, you can change it to whatever you want

    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Wait(10)
    end

    UseParticleFxAssetNextCall(particleDict)

    local fx = StartParticleFxLoopedOnEntity( -- I discovered StartNetworkedParticleFxLoopedOnEntity() way too late while making this script, so I didn't bother to rewrite the whole thing
        particleName,
        ped,
        0.0, 0.0, 0.3,
        0.0, 0.0, 0.0,
        1.0,
        false, false, false
    )

    table.insert(flyEffects, fx)
end

function removeAllFlies()
    for _, fx in ipairs(flyEffects) do
        StopParticleFxLooped(fx, 0)
    end
    flyEffects = {}
end

function GetMyDirt(callback)
    RegisterNetEvent("sync_flies:returnDirt", function(dirt)
        callback(dirt)
    end)

    TriggerServerEvent("sync_flies:requestDirt")
end

-- Events
RegisterNetEvent("flies:clientSpawn", function(netId)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        spawnFlySwarm(ped)
    end
end)

RegisterNetEvent("flies:clientRemove", function(netId)
    local ped = NetToPed(netId)
    if DoesEntityExist(ped) then
        if ped == PlayerPedId() then
            removeAllFlies()
        end
    end
end)

RegisterNetEvent("flies:setDirt", function(value)
    playerDirt = value
    notify("Your dirt value is: " .. value .. "/200")

    -- You can adjust the threshold value that triggers flies to spawn, default = 100
    if value >= 100 then 
        local netId = PedToNet(PlayerPedId())
        TriggerServerEvent("flies:syncEffect", netId)
    else
        local netId = PedToNet(PlayerPedId())
        TriggerServerEvent("flies:syncRemove", netId)
    end
end)

-- Trigger on player spawn
AddEventHandler("playerSpawned", function()
    TriggerServerEvent("flies:playerSpawned")
    -- This thread adds +10 dirt to the client every 30 mins.
    CreateThread(function()
        while true do
            Wait(30 * 60 * 1000) -- 30 Mins
            TriggerServerEvent("sync_flies:clientRequestUpdateDirt", 10)
            notify("You are getting dirty and sweaty")
        end
    end)
end)


local wasRecentlyCleaned = false

CreateThread(function()
    local wait = 5000 -- check every 5000 frames if player is in water (optimizing shit?)
    while true do
        
        Wait(wait)

        local ped = PlayerPedId()
        local isInWater = GetEntitySubmergedLevel(ped) > 0.15

        if isInWater then
            wait = 0 -- if player is in water, set that bitch to 0 to properly display the animation and register controls
            helpNotify("Press ~INPUT_CONTEXT~ to wash your ass")

            if IsControlJustReleased(0, 38) and not wasRecentlyCleaned then
                wasRecentlyCleaned = true

                -- Wash animation example, take whatever you think it fits
                local animDict = "mp_safehouseshower@male@"
                local animName = "male_shower_idle_b"

                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Wait(10)
                end

                FreezeEntityPosition(ped, true)
                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 7000, 1, 0, false, false, false)
                TaskPlayAnim()
                Wait(7000)
                ClearPedTasks(ped)
                FreezeEntityPosition(ped, false)

                notify("You washed yourself.")
                TriggerServerEvent("sync_flies:clientRequestUpdateDirt", -50) -- removes 50 dirt after every washing

                Wait(5000) -- Cooldown
                wasRecentlyCleaned = false
            end
        else
            wait = 5000 
        end
    end
end)

RegisterCommand("checkdirt", function()
    GetMyDirt(function(dirt)
        if dirt then
            if dirt > 100 then
                notify("You're a dirty ass. Your dirt-level: " .. dirt .. "/200")
            else
                notify("U good tho. Your dirt-level: " .. dirt .. "/200")
            end
        else
            notify("Couldn't fetch data bro.")
        end
    end)
end)

-- Notify functions
function notify(msg)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(msg)
    DrawNotification(0, 1)
end
    
function helpNotify(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

