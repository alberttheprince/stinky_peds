# Client-sided functions

## TriggerServerEvent("sync_flies:requestDirt")
Example from the script:
```
function GetMyDirt(callback)
    RegisterNetEvent("sync_flies:returnDirt", function(dirt)
        callback(dirt)
    end)

    TriggerServerEvent("sync_flies:requestDirt")
end
RegisterCommand("checkdirt", function()
    GetMyDirt(function(dirt)
        if dirt then
            if dirt > 100 then
                print("You're a dirty ass. Your dirt-level: " .. dirt .. "/200")
            else
                print("U good tho. Your dirt-level: " .. dirt .. "/200")
            end
        else
            print("Daten konnten nicht geladen werden.")
        end
    end)
end)
```

## TriggerServerEvent("sync_flies:clientRequestUpdateDirt", value)
Example:
```
RegisterCommand("removeDirt", function()
   TriggerServerEvent("sync_flies:clientRequestUpdateDirt", -10) -- removes 10 from the dirt value
end, false)

RegisterCommand("addDirt", function()
   TriggerServerEvent("sync_flies:clientRequestUpdateDirt", 100) -- adds 100 to the dirt value
end, false)
```

# Server-sided functions

## TriggerEvent("sync_flies:updateDirtExtern", source, amount) 
Example:
```
RegisterNetEvent("some_other_script:addDirtToSelf", function()
    local src = source
    local amount = 15
    TriggerEvent("sync_flies:updateDirtExtern", src, amount) -- adds 15 to the dirt value on source
end)
```


## exports["sync_flies"]:getDirt(playerId)
Example:
```
RegisterCommand("checkdirt", function(source, args, rawCommand)
    local targetPlayerId = source

    exports["sync_flies"]:getDirt(targetPlayerId, function(dirt)
        if dirt then
            if dirt > 100 then
                print("Player " .. targetPlayerId .. " has " .. dirt .. " dirt. Disgusting! 🤢")
            else
                print("Player " .. targetPlayerId .. " has " .. dirt .. " dirt. Not too bad.")
            end
        else
            print("Player ID not found.")
        end
    end)
end, false)
```
