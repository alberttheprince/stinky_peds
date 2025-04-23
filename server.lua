-- Debug

local dbg = true

function dbgprint(msg)
    if dbg then
        print("^3[STINKY PEDS]^0 "..msg)
    end
end

-- Table name in DB, leave this as it is if you don't know what you're doing
local tableName = "player_dirt"

-- Math-utils n shit (testing & playing around with lua functions)
local utils = {}

utils.clamp = function(val, min, max)
    return math.max(min, math.min(max, val))
end

-- Identifierhelper
local function getIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id:match("^license:") then return id end
    end
    return nil
end

-- Create table in db if not exists
AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    dbgprint("Resoure started, checking database...")

    exports.oxmysql:execute(string.format([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(100) NOT NULL UNIQUE,
            `dirt` INT DEFAULT 0
        );
    ]], tableName), {}, function()
        dbgprint("Table '" .. tableName .. "' is ready.")
    end)
end)

-- Set player dirt value & apply flies on spawn
RegisterNetEvent("flies:playerSpawned", function()
    local src = source
    local identifier = getIdentifier(src)
    if not identifier then
        dbgprint("ERROR: No valid identifier for source: " .. src)
        return
    end

    dbgprint("Player spawned: " .. identifier)

    exports.oxmysql:execute('SELECT dirt FROM player_dirt WHERE identifier = ?', {identifier}, function(result)
        if result[1] then
            local dirt = result[1].dirt
            dbgprint("Dirt value: " .. dirt)
            TriggerClientEvent("flies:setDirt", src, dirt)
        else
            dbgprint("New player detected. Flies are getting ready...")
            exports.oxmysql:insert('INSERT INTO player_dirt (identifier, dirt) VALUES (?, ?)', {identifier, 0}, function()
                TriggerClientEvent("flies:setDirt", src, 0)
            end)
        end
    end)
end)

-- Function to update player dirt value 
local function updateDirt(src, diff)
    local identifier = getIdentifier(src)
    if not identifier then
        dbgprint("ERROR: No valid identifier found.")
        return
    end

    dbgprint("Refreshing dirt value on identifier: " .. identifier .. ", for: " .. diff)

    exports.oxmysql:execute('SELECT dirt FROM player_dirt WHERE identifier = ?', {identifier}, function(result)
        if result[1] then
            local oldDirt = result[1].dirt or 0
            local newDirt = utils.clamp(oldDirt + diff, 0, 200)
            dbgprint("New dirt value: " .. newDirt)

            exports.oxmysql:update('UPDATE player_dirt SET dirt = ? WHERE identifier = ?', {newDirt, identifier}, function(affected)
                if affected > 0 then
                    dbgprint("Dirt successfully refreshed.")
                    TriggerClientEvent("flies:setDirt", src, newDirt)
                else
                    dbgprint("WARNING: Not able to update dirt value.")
                end
            end)
        else
            dbgprint("ERROR: Identifier not found in '"..tableName.."' db-table")
        end
    end)
end

-- Eventhandlers
RegisterNetEvent("sync_flies:updateDirtExtern", function(targetSrc, diff)
    dbgprint("External call: updateDirt on: " .. targetSrc .. ", for: " .. diff)
    updateDirt(targetSrc, diff)
end)

RegisterNetEvent("sync_flies:clientRequestUpdateDirt", function(diff)
    local src = source
    TriggerEvent("sync_flies:updateDirtExtern", src, diff)
end)

-- Testcommands
RegisterCommand("dirtadd", function(source)
    dbgprint("Befehl /dirtadd von " .. source)
    TriggerEvent("sync_flies:updateDirtExtern", source, 10)
end, false)

RegisterCommand("dirtrem", function(source)
    dbgprint("Befehl /dirtrem von " .. source)
    TriggerEvent("sync_flies:updateDirtExtern", source, -10)
end, false)

-- Sync the flies server-wide on your dirty, stinky ass body
RegisterNetEvent("flies:syncEffect", function(netId)
    dbgprint("Spawned flies on dirty ass NetID: " .. tostring(netId))
    TriggerClientEvent("flies:clientSpawn", -1, netId)
end)

RegisterNetEvent("flies:syncRemove", function(netId)
    dbgprint("Removed flies on (now) clean ass NetID: " .. tostring(netId))
    TriggerClientEvent("flies:clientRemove", -1, netId)
end)

-- Export to get the player dirt value server-sided
exports("getDirt", function(source, cb)
    local identifier = getIdentifier(source)
    if not identifier then return cb(nil) end

    exports.oxmysql:execute('SELECT dirt FROM player_dirt WHERE identifier = ?', {identifier}, function(result)
        if result[1] then
            cb(result[1].dirt)
        else
            cb(nil)
        end
    end)
end)

-- Not an export but a function to get the player dirt value client-sided, whyever the fuck you would even need that is up to you.
RegisterNetEvent("sync_flies:requestDirt", function()
    local src = source
    local identifier = getIdentifier(src)
    if not identifier then return end

    exports.oxmysql:execute('SELECT dirt FROM player_dirt WHERE identifier = ?', {identifier}, function(result)
        if result[1] then
            TriggerClientEvent("sync_flies:returnDirt", src, result[1].dirt)
        else
            TriggerClientEvent("sync_flies:returnDirt", src, nil)
        end
    end)
end)
