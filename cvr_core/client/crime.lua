-- client/crime.lua
local cfg = {}
RegisterNetEvent('cvr:syncConfig', function(c) cfg = c or {} end)

-- Commands (fallback if you don't use ox_target)
RegisterCommand('robstore', function(_, args)
    local code = args[1]
    if not code then TriggerEvent('cvr:notify', '/robstore <code>') return end
    TriggerServerEvent('cvr:crime:startStore', code)
end, false)

RegisterCommand('bank', function()
    TriggerServerEvent('cvr:crime:startBank')
end, false)

-- If using ox_target, place interactables at configured stores
CreateThread(function()
    while not cfg.Stores do Wait(250) end
    if not (GetResourceState('ox_target') == 'started') then return end
    for _, s in ipairs(cfg.Stores) do
        exports.ox_target:addSphereZone({
            coords = s.pos, radius = 1.25,
            options = {{
                name = 'cvr_rob_'..s.code,
                icon = 'fa-solid fa-sack-dollar',
                label = ('Rob %s'):format(s.label),
                onSelect = function() TriggerServerEvent('cvr:crime:startStore', s.code) end
            }}
        })
    end
end)

-- === Launder interaction ===
CreateThread(function()
    while not Config or not Config.Launder do Wait(250) end
    local L = Config.Launder

    -- Fallback command if you don't want to go to the spot:
    RegisterCommand('launder', function(_, args)
        local amt = tonumber(args[1] or '0') or 0
        if amt <= 0 then TriggerEvent('cvr:notify','/launder <amount>') return end
        TriggerServerEvent('cvr:crime:launder', amt)
    end, false)

    -- Zone interaction (no ox_target needed)
    local inside = false
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local dist = #(GetEntityCoords(ped) - L.pos)
            if dist <= L.radius then
                if not inside then inside = true end
                -- 3D help text
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ to launder (min $%d dirty)'):format(L.minAmount))
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustPressed(0, 51) then -- E
                    local amount = 0
                    AddTextEntry('CVR_LAUNDER', 'Enter amount to launder:')
                    DisplayOnscreenKeyboard(1, 'CVR_LAUNDER', '', '', '', '', '', 10)
                    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
                    if GetOnscreenKeyboardResult() then amount = tonumber(GetOnscreenKeyboardResult()) or 0 end
                    if amount > 0 then TriggerServerEvent('cvr:crime:launder', amount) end
                end
            else
                if inside then inside = false end
            end
            Wait(0)
        end
    end)
end)
