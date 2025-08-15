if not IsDuplicityVersion() then return end

-- DEBUG: prove the server file is loaded + show ACE result
RegisterCommand('srvdebug', function(src)
    local ok = IsPlayerAceAllowed(src, 'cvr.admin') or IsPlayerAceAllowed(src, 'group.admin')
    print(('[CVR] srvdebug from %s | cvr.admin=%s | group.admin=%s'):format(
        tostring(src),
        tostring(IsPlayerAceAllowed(src, 'cvr.admin')),
        tostring(IsPlayerAceAllowed(src, 'group.admin'))
    ))
    TriggerClientEvent('cvr:notify', src, ok and 'Server admin OK ✅' or 'Server admin ❌')
end)

-- normal auth path used by the client script
RegisterNetEvent('cvr:admin:auth', function()
    local src = source
    local ok = IsPlayerAceAllowed(src, 'cvr.admin') or IsPlayerAceAllowed(src, 'group.admin')
    TriggerClientEvent('cvr:admin:authorized', src, ok)
end)

-- print your identifiers
RegisterCommand('ids', function(src)
    if src == 0 then return print('Run /ids in-game') end
    print(('[CVR] Identifiers for %s:'):format(GetPlayerName(src)))
    for _, id in ipairs(GetPlayerIdentifiers(src)) do print('  - '..id) end
    TriggerClientEvent('cvr:notify', src, 'Identifiers printed to server console.')
end)
