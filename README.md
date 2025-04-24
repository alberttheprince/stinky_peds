## 🪰 **Stinky Peds** – A Dirt System You Never Knew You Needed

Ever looked at a player and thought:
*"Damn... he looks like he hasn't washed his ass since he did the tutorial."*
Well, now you can actually *prove it*.

**Stinky Peds** (or however you want to call it) is a lightweight and hilarious immersion script that adds apersonal hygiene system to your server. Every player starts with a dirt level of 0, but as time passes and bodies do not get washed, you'll start to develop a smell that attracts flies.

### 💩 How It Works:

* 🐛 Dirt builds up over time (every 30 minutes) (or via external triggers) up to a maximum of 200.
* 🪰 When a player reaches **100+ dirt**, a swarm of flies begins orbiting their stanky body.
* 🚿 Players can **go into any water** and press **[E]** to scrub their shame away with a washing animation.
* 🧼 Showering **reduces dirt by 50**. Very refreshing.
* 📊 Use `/checkdirt` to proudly display just how disgusting you’ve become.
* 🧠 The system auto-creates and updates a clean little **database table** in the background, so you don’t have to.
* 📦 Server-wide synch, so everybody can spot and avoid your dirty ass.

### 📦 Features:

* Everything is configurable & easily expandable (if you know what you're doing)
* What more features do you expect from a dirty ass script like this
* Tried to optimize it as good as possible, pullrequest me to it

### 🎯 Why tho?

Because roleplay should be smelly sometimes. Yeah, whatever.
No, to be forreal, I hopped back into FiveM scripting and thats my first output since coming back.

### no config file included, you gotta figure out stuff by yourself brother/sister

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
            print("Couldn't fetch data.")
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
