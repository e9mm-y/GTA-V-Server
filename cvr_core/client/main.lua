-- client/main.lua
local selfState = {}
local cfg = {}

RegisterNetEvent('cvr:syncSelf', function(p) selfState = p or {} end)
RegisterNetEvent('cvr:syncConfig', function(c) cfg = c or {} end)

-- Simple notify fallback (use ox_lib if present)
RegisterNetEvent('cvr:notify', function(msg)
    if lib and lib.notify then lib.notify({ description = msg }) return end
    BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(msg); EndTextCommandThefeedPostTicker(false, false)
end)

-- Respawn QoL: armor + basic loadout
AddEventHandler('playerSpawned', function()
    Wait(1500)
    if cfg.AutoArmorOnRespawn then SetPedArmour(PlayerPedId(), cfg.AutoArmorOnRespawn or 0) end
    if cfg.LoadoutOnRespawn then
        for _, w in ipairs(cfg.LoadoutOnRespawn) do
            GiveWeaponToPed(PlayerPedId(), GetHashKey(w), 250, false, true)
        end
    end
end)
