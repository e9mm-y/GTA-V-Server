-- client/ui.lua
if IsDuplicityVersion() then return end

local barActive = false

-- Robbery progress bar
RegisterNetEvent('cvr:crime:runBar', function(code, seconds)
    local duration = (seconds or 60) * 1000
    if lib and lib.progressBar then
        barActive = true
        lib.progressBar({
            duration = duration,
            label = ('Robbing %s...'):format(code),
            useWhileDead = false,
            canCancel = false,
            -- allow movement/combat so player can fight
            disable = { move = false, car = false, combat = false }
        })
        barActive = false
    else
        Wait(duration)
    end
end)

-- Force-cancel the progress bar (on fail or cleanup)
RegisterNetEvent('cvr:crime:cancelBar', function()
    if lib and lib.cancelProgressBar then
        lib.cancelProgressBar()
    end
    barActive = false
end)

-- If the resource restarts mid-robbery, make sure the HUD clears
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if barActive then
        TriggerEvent('cvr:crime:cancelBar')
    end
end)
