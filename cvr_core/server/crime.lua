-- server/crime.lua

local activeRobberies = {} -- [player] = { type='store'/'bank', code=code, pedNet=pedNet, zone=vector3 }
local cooldowns = {}       -- [code] = os.time()

-- ====== Utility Functions ======
local function policeOnline()
    local count = 0
    for _, id in ipairs(GetPlayers()) do
        if CVR.IsCop(id) then count = count + 1 end
    end
    return count
end

local function onCooldown(code)
    return cooldowns[code] and (os.time() - cooldowns[code] < (cooldowns[code .. "_min"] or 0) * 60)
end

local function setCooldown(code, minutes)
    cooldowns[code] = os.time()
    cooldowns[code .. "_min"] = minutes
end

-- ====== START STORE ROBBERY ======
RegisterNetEvent('cvr:crime:startStore', function(code, pedNet, zone)
    local src = source
    local store
    for _, s in ipairs(Config.Stores) do
        if s.code == code then store = s break end
    end
    if not store then return end

    if policeOnline() < store.minPolice then
        TriggerClientEvent('cvr:notify', src, 'Not enough police on duty.')
        return
    end
    if onCooldown(code) then
        TriggerClientEvent('cvr:notify', src, 'This store was recently robbed.')
        return
    end

    setCooldown(code, store.cooldownMin)
    activeRobberies[src] = { type = 'store', code = code, pedNet = pedNet, zone = zone }

    TriggerClientEvent('cvr:crime:runBar', src, code, store.timeSec)
    TriggerClientEvent('cvr:police:dispatch', -1, { type='store', code=code })

    SetTimeout(store.timeSec * 1000, function()
        if not GetPlayerName(src) or not activeRobberies[src] then return end
        if activeRobberies[src].type ~= 'store' then return end
        CVR.AddCash(src, store.base + math.random(-store.variance, store.variance), true)
        TriggerClientEvent('cvr:notify', src, ('Robbery success: +$%d dirty'):format(store.base))
        activeRobberies[src] = nil
    end)
end)

-- ====== START BANK ROBBERY ======
RegisterNetEvent('cvr:crime:startBank', function(pedNet)
    local src = source
    local bank = Config.Bank

    if policeOnline() < bank.minPolice then
        TriggerClientEvent('cvr:notify', src, 'Not enough police on duty.')
        return
    end
    if onCooldown(bank.code) then
        TriggerClientEvent('cvr:notify', src, 'This bank was recently robbed.')
        return
    end

    setCooldown(bank.code, bank.cooldownMin)
    activeRobberies[src] = { type = 'bank', code = bank.code, pedNet = pedNet, zone = bank.doorPos }

    TriggerClientEvent('cvr:crime:bankMarker', src, bank.doorPos)
    TriggerClientEvent('cvr:police:dispatch', -1, { type='bank', code=bank.code })

    SetTimeout(bank.timeSec * 1000, function()
        if not GetPlayerName(src) or not activeRobberies[src] then return end
        if activeRobberies[src].type ~= 'bank' then return end
        CVR.AddCash(src, bank.base + math.random(-bank.variance, bank.variance), true)
        TriggerClientEvent('cvr:notify', src, ('Bank heist success: +$%d dirty'):format(bank.base))
        activeRobberies[src] = nil
        TriggerClientEvent('cvr:crime:hideMarker', src)
    end)
end)

-- ====== FAIL CONDITIONS ======
RegisterNetEvent('cvr:crime:failRobbery', function(reason)
    local src = source
    if activeRobberies[src] then
        TriggerClientEvent('cvr:notify', src, 'Robbery failed: ' .. reason)
        TriggerClientEvent('cvr:crime:hideMarker', src)
        activeRobberies[src] = nil
    end
end)

-- ====== PED DEATH CHECK ======
AddEventHandler('baseevents:onPedKilled', function(victim, killerId)
    if not killerId or killerId == 0 then return end
    local src = killerId
    for pid, rob in pairs(activeRobberies) do
        if pid == src and NetworkGetNetworkIdFromEntity(victim) == rob.pedNet then
            TriggerClientEvent('cvr:crime:failRobbery', src, 'The clerk was killed.')
            activeRobberies[src] = nil
        end
    end
end)

-- ====== PLAYER LEAVE AREA ======
RegisterNetEvent('cvr:crime:leftZone', function()
    local src = source
    if activeRobberies[src] then
        TriggerClientEvent('cvr:crime:failRobbery', src, 'You left the robbery area.')
        activeRobberies[src] = nil
    end
end)
