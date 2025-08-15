-- client/police.lua

-- Cuffed state
local cuffed = false
RegisterNetEvent('cvr:police:cuffed', function(state)
    cuffed = state and true or false
    local ped = PlayerPedId()
    SetEnableHandcuffs(ped, cuffed)
    DisablePlayerFiring(ped, cuffed)
end)

-- Simple jail: teleport to prison yard and leash
RegisterNetEvent('cvr:police:jail', function(minutes)
    local ped = PlayerPedId()
    local jail = vector3(1754.0, 2479.2, 45.6) -- Bolingbroke yard
    SetEntityCoords(ped, jail)
    local endTime = GetGameTimer() + (math.max(1, tonumber(minutes) or 5) * 60 * 1000)
    while GetGameTimer() < endTime do
        Wait(1000)
        if #(GetEntityCoords(ped) - jail) > 55.0 then SetEntityCoords(ped, jail) end
    end
end)

-- Dispatch pings (shown to everyone by default; later you can filter to cops)
RegisterNetEvent('cvr:police:dispatch', function(data)
    local pos = data.coords or GetEntityCoords(PlayerPedId())
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, (data.type == 'bank') and 161 or 52)
    SetBlipScale(blip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString((data.type == 'bank' and 'Bank Robbery') or 'Store Robbery')
    EndTextCommandSetBlipName(blip)
    SetTimeout(90 * 1000, function() RemoveBlip(blip) end)
end)
