-- server/police.lua

-- Cuff a player
RegisterNetEvent('cvr:police:cuff', function(target)
    local src = source
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    if not target or not GetPlayerName(target) then return end
    TriggerClientEvent('cvr:police:cuffed', target, true)
    TriggerClientEvent('cvr:notify', target, 'You have been cuffed by police.')
end)

-- Uncuff a player
RegisterNetEvent('cvr:police:uncuff', function(target)
    local src = source
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    if not target or not GetPlayerName(target) then return end
    TriggerClientEvent('cvr:police:cuffed', target, false)
    TriggerClientEvent('cvr:notify', target, 'You have been uncuffed by police.')
end)

-- Jail a player for X minutes
RegisterNetEvent('cvr:police:jail', function(target, minutes)
    local src = source
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    if not target or not GetPlayerName(target) then return end
    local jailTime = tonumber(minutes) or 5
    TriggerClientEvent('cvr:police:jail', target, jailTime)
    TriggerClientEvent('cvr:notify', target, ('You have been jailed for %d minutes.'):format(jailTime))
end)

-- Optional: Simple /cuff, /uncuff, /jail commands for cops
RegisterCommand('cuff', function(src, args)
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    local target = tonumber(args[1] or '')
    if target then TriggerEvent('cvr:police:cuff', target) end
end)

RegisterCommand('uncuff', function(src, args)
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    local target = tonumber(args[1] or '')
    if target then TriggerEvent('cvr:police:uncuff', target) end
end)

RegisterCommand('jail', function(src, args)
    if not IsPlayerAceAllowed(src, 'cvr.cop') then return end
    local target = tonumber(args[1] or '')
    local minutes = tonumber(args[2] or '5')
    if target then TriggerEvent('cvr:police:jail', target, minutes) end
end)
