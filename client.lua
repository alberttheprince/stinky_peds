--[[
    Why we use hardcoded shower coordinates instead of relying on interior hashes:
    While it's technically possible to detect if a player is inside a specific interior using GetInteriorFromEntity() 
    or GetInteriorAtCoords(), the documentation and mapping of interior hashes in GTA V is extremely limited, 
    inconsistent, and often unreliable across different game builds and modded maps (MLOs).
    Many interiors, especially custom or MLO-based ones, either return undefined hashes or share the same hash, 
    making it impossible to accurately identify whether a location contains a shower.

    TL;DR: Hardcoded shower positions = more reliable and portable across any map setup.
]]

-- Add your shower coords here
Showers = {
    {x = 254.4536, y = -1000.7904, z = -98.9275}, -- Low End Appartement
    {x = -788.1212, y = 329.8235, z = 201.4610}, -- High End Appartement 1
    {x = -788.5336, y = 330.3257, z = 153.8416}, -- High End Appartement 2
    {x = -911.2310, y = -371.1954, z = 79.3205}, -- High End Appartement 3
    {x = -897.1279, y = -368.6649, z = 113.1114}, -- High End Appartement 4
}

-- Set this to true if you want npc's to react to your stinky ass ped
local useNpcReactions = true 
local debugPrints = true

-- Don't alter these variables, otherwise you will fuck shit up
local flyEffects = {}
local playerDirt = 0
local lastReactionTime = {}

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

function isNearShower(ped)
    local playerCoords = GetEntityCoords(ped)
    for _, showerPos in pairs(Showers) do
        if #(playerCoords - vector3(showerPos.x, showerPos.y, showerPos.z)) < 2.0 then
            return true
        end
    end
    return false
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
        local nearShower = isNearShower(ped)

        if isInWater or nearShower then
            wait = 0 -- if player is in water, set that bitch to 0 to properly display the animation and register controls
            helpNotify("Press ~INPUT_CONTEXT~ to wash your ass")

            if IsControlJustReleased(0, 38) and not wasRecentlyCleaned then
                wasRecentlyCleaned = true
                busySpinner("You are finally washing your ass")
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
                BusyspinnerOff()
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

function busySpinner(message)
    BeginTextCommandBusyspinnerOn('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandBusyspinnerOn(3)
end

function dbgPrint(msg)
	if debugPrints then
		print("^3[DEBUG]^0 " .. tostring(msg))
	end
end

function getRandomDisgustAnim()
    local anims = {
        {dict = "re@construction", anim = "out_of_breath"},
        {dict = "gestures@m@standing@casual", anim = "gesture_no_way"},
        {dict = "anim@mp_player_intcelebrationfemale@stinker", anim = "stinker"}
    }
    local choice = anims[math.random(#anims)]
    dbgPrint("Random animation: " .. choice.dict .. " - " .. choice.anim)
    return choice.dict, choice.anim
end

function EnumeratePeds()
    return coroutine.wrap(function()
        local handle, ped = FindFirstPed()
        local success
        repeat
            if not IsEntityDead(ped) then
                coroutine.yield(ped)
            end
            success, ped = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end)
end

-- this threads needs a little bit of optimization, I'm on it. I promise <3

CreateThread(function() -- thread to let npc's react if you don't wash your ass
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
		local rndm = math.random(1, 2)
        for ped in EnumeratePeds() do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
                local pedCoords = GetEntityCoords(ped)
                local dist = #(playerCoords - pedCoords)

                if dist < 6.0 then
                    local pedId = tostring(ped)

                    if not lastReactionTime[pedId] then
						if not IsPedInAnyVehicle(ped) then
							if rndm == 1 then
								dbgPrint("Ped " .. ped .. " is close enough, playing animation.")
	
								-- Take control if necessary
								if not NetworkHasControlOfEntity(ped) then
									NetworkRequestControlOfEntity(ped)
									Wait(50)
								end
								ClearPedTasks(ped)
								local dict, anim = getRandomDisgustAnim()
								RequestAnimDict(dict)
								while not HasAnimDictLoaded(dict) do
									Wait(10)
								end
	
								TaskPlayAnim(ped, dict, anim, 8.0, -8.0, 3000, 49, 0, false, false, false)
								dbgPrint("Played animation on Ped " .. ped .. ": " .. dict .. " - " .. anim)
	
								lastReactionTime[pedId] = true
								SetTimeout(10000, function()
									lastReactionTime[pedId] = nil
									dbgPrint("Cooldown ended for Ped " .. pedId)
								end)
								
							else
								dbgPrint("Random check skipped animation for Ped " .. ped)
							end
						end
                    else
                        dbgPrint("Ped " .. ped .. " is on cooldown.")
                    end
                end
            end
        end
        Wait(5000)
    end
end)
