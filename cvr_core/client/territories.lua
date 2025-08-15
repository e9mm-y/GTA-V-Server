-- client/territories.lua
local cfg = {}
local selfState = {}

RegisterNetEvent('cvr:syncSelf', function(p) selfState = p or {} end)
RegisterNetEvent('cvr:syncConfig', function(c) cfg = c or {} end)

-- ox_lib zones if available
CreateThread(function()
    while not cfg.Territories do Wait(250) end

    if lib and lib.zones then
        for _, t in ipairs(cfg.Territories) do
            lib.zones.sphere({
                coords = t.center, radius = t.radius,
                onEnter = function()
                    local gid = selfState.gang_id or 0
                    TriggerServerEvent('cvr:zone:presence', t.code, gid, true)
                    if t.pvpBuff and t.pvpBuff.armorBonus then
                        AddArmourToPed(PlayerPedId(), t.pvpBuff.armorBonus)
                    end
                end,
                onExit = function()
                    local gid = selfState.gang_id or 0
                    TriggerServerEvent('cvr:zone:presence', t.code, gid, false)
                end
            })
        end
        return
    end

    -- Fallback: manual distance checks (less precise)
    local inside = {}
    while true do
        local pos = GetEntityCoords(PlayerPedId())
        for _, t in ipairs(cfg.Territories) do
            local dist = #(pos - t.center)
            local inNow = dist <= (t.radius or 100.0)
            if inNow and not inside[t.code] then
                inside[t.code] = true
                TriggerServerEvent('cvr:zone:presence', t.code, selfState.gang_id or 0, true)
                if t.pvpBuff and t.pvpBuff.armorBonus then
                    AddArmourToPed(PlayerPedId(), t.pvpBuff.armorBonus)
                end
            elseif (not inNow) and inside[t.code] then
                inside[t.code] = false
                TriggerServerEvent('cvr:zone:presence', t.code, selfState.gang_id or 0, false)
            end
        end
        Wait(750)
    end
end)
