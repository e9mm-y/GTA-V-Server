-- client/interact.lua
local aimingAt, aimStart = nil, 0
local cfg = {}

-- Get config from server
RegisterNetEvent('cvr:syncConfig', function(c)
    cfg = c or {}
end)

-- Helper: check if player is aiming at a ped
local function isAimingAtPed(ped)
    if not DoesEntityExist(ped) then return false end
    if IsPedDeadOrDying(ped) then return false end
    local _, aimedEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
    return aimedEntity == ped
end

-- Loop to detect aiming at clerks
CreateThread(function()
    while true do
        Wait(0)

        local player = PlayerPedId()
        local playerPos = GetEntityCoords(player)

        -- Check stores
        for _, store in ipairs(cfg.Stores or {}) do
            local ped = store.pedEntity
            if ped and isAimingAtPed(ped) and #(playerPos - store.pedPos) <= store.robDistance then
                if not aimingAt then
                    aimStart = GetGameTimer()
                    aimingAt = {type = "store", code = store.code, ped = ped, aimSeconds = store.aimSeconds}
                    TriggerEvent('cvr:notify', ('Intimidating %s...'):format(store.label))
                elseif aimingAt.code == store.code and GetGameTimer() - aimStart >= (store.aimSeconds * 1000) then
                    TriggerServerEvent('cvr:crime:startStore', store.code, PedToNet(ped))
                    aimingAt = nil
                end
            end
        end

        -- Check bank
        if cfg.Bank and cfg.Bank.clerk and cfg.Bank.clerk.entity then
            local ped = cfg.Bank.clerk.entity
            if ped and isAimingAtPed(ped) and #(playerPos - vec3(cfg.Bank.clerk.pos.x, cfg.Bank.clerk.pos.y, cfg.Bank.clerk.pos.z)) <= 3.0 then
                if not aimingAt then
                    aimStart = GetGameTimer()
                    aimingAt = {type = "bank", code = cfg.Bank.code, ped = ped, aimSeconds = 2}
                    TriggerEvent('cvr:notify', ('Intimidating %s...'):format(cfg.Bank.label))
                elseif aimingAt.code == cfg.Bank.code and GetGameTimer() - aimStart >= 2000 then
                    TriggerServerEvent('cvr:crime:startBank', cfg.Bank.code, PedToNet(ped))
                    aimingAt = nil
                end
            end
        end
    end
end)
