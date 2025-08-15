-- client/rob_aim.lua
if IsDuplicityVersion() then return end

local cfg
RegisterNetEvent('cvr:syncConfig', function(c) cfg = c end)

local aimingAt, aimStart = nil, 0
local activeStore = nil -- { code, endTime, center, radius, clerkPed }
local activeBank  = nil -- { endTime, center, radius, clerkPed, lootPos, lootR, animPlaying }

local function storeDefaults()
    local d = (cfg and cfg.StoreDefaults) or {}
    return d.robDistance or 3.0, d.aimSeconds or 2.0, d.areaRadius or 12.0
end

local function getClerk(code)
    return exports.cvr_core:GetClerkPed(code)
end

local function getStoreByClerk(ent)
    if not cfg or not cfg.Stores then return nil end
    for _, s in ipairs(cfg.Stores) do
        local ped = getClerk(s.code)
        if ped and ent == ped then return s end
    end
    return nil
end

-- ====== STORE FAIL WATCHER ======
CreateThread(function()
    while true do
        if activeStore then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local deadClerk = (activeStore.clerkPed ~= nil)
                and (IsPedDeadOrDying(activeStore.clerkPed, true) or not DoesEntityExist(activeStore.clerkPed))
            local dist = #(pos - activeStore.center)
            if deadClerk then
                TriggerServerEvent('cvr:crime:failStore', activeStore.code, 'clerk_dead')
                TriggerEvent('cvr:crime:cancelBar')
                activeStore = nil
            elseif dist > activeStore.radius + 0.5 then
                TriggerServerEvent('cvr:crime:failStore', activeStore.code, 'left_area')
                TriggerEvent('cvr:crime:cancelBar')
                activeStore = nil
            elseif GetGameTimer() >= activeStore.endTime then
                activeStore = nil
            end
        end
        Wait(150)
    end
end)

-- ====== STORE AIM-TO-START ======
CreateThread(function()
    while true do
        Wait(0)
        if not cfg or not cfg.Stores then goto cont end

        local myPed = PlayerPedId()
        local armed = IsPedArmed(myPed, 6)
        if armed and IsPlayerFreeAiming(PlayerId()) and not (activeStore or activeBank) then
            local _, ent = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if ent and DoesEntityExist(ent) and IsEntityAPed(ent) then
                local s = getStoreByClerk(ent)
                if s then
                    local robDist, aimSecs, areaR = storeDefaults()
                    robDist  = s.robDistance  or robDist
                    aimSecs  = s.aimSeconds   or aimSecs
                    areaR    = s.areaRadius   or areaR

                    local d = #(GetEntityCoords(myPed) - GetEntityCoords(ent))
                    if d <= robDist and not IsPedDeadOrDying(ent, true) then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName('Keep aiming to intimidate the clerk...')
                        EndTextCommandDisplayHelp(0, false, true, -1)

                        if aimingAt ~= ent then aimingAt = ent; aimStart = GetGameTimer() end
                        if GetGameTimer() - aimStart >= (aimSecs * 1000) then
                            aimingAt, aimStart = nil, 0
                            exports.cvr_core:HandsUpClerk(s.code, (s.timeSec or 80) * 1000 + 5000)
                            TriggerServerEvent('cvr:crime:startStore', s.code)
                            activeStore = {
                                code = s.code,
                                endTime = GetGameTimer() + ((s.timeSec or 80) * 1000),
                                center = s.pos,
                                radius = areaR,
                                clerkPed = ent
                            }
                            while IsPlayerFreeAiming(PlayerId()) do Wait(150) end
                        end
                    else
                        aimingAt, aimStart = nil, 0
                    end
                else
                    aimingAt, aimStart = nil, 0
                end
            else
                aimingAt, aimStart = nil, 0
            end
        else
            aimingAt, aimStart = nil, 0
        end
        ::cont::
    end
end)

-- ====== BANK FAIL WATCHER + LOOT MARKER / ANIM ======
local function playLootAnimLoop()
    local ped = PlayerPedId()
    local dict = 'anim@heists@ornate_bank@grab_cash'
    local name = 'grab'
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) and t < 200 do Wait(25) t = t + 1 end

    TaskPlayAnim(ped, dict, name, 2.0, -2.0, -1, 49, 0, false, false, false)
    activeBank.animPlaying = true

    CreateThread(function()
        while activeBank and activeBank.animPlaying do
            if not IsEntityPlayingAnim(ped, dict, name, 3) then
                TaskPlayAnim(ped, dict, name, 2.0, -2.0, -1, 49, 0, false, false, false)
            end
            Wait(500)
        end
        ClearPedTasks(ped)
    end)
end

CreateThread(function()
    while true do
        if activeBank then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)

            -- Fail checks
            local deadClerk = (activeBank.clerkPed ~= nil)
                and (IsPedDeadOrDying(activeBank.clerkPed, true) or not DoesEntityExist(activeBank.clerkPed))
            local dist = #(pos - activeBank.center)
            if deadClerk then
                TriggerEvent('cvr:crime:cancelBar')
                TriggerServerEvent('cvr:crime:failBank', 'clerk_dead')
                activeBank = nil
                goto sleep
            elseif dist > activeBank.radius + 0.5 then
                TriggerEvent('cvr:crime:cancelBar')
                TriggerServerEvent('cvr:crime:failBank', 'left_area')
                activeBank = nil
                goto sleep
            elseif GetGameTimer() >= activeBank.endTime then
                -- success will be handled server-side
                activeBank = nil
                goto sleep
            end

            -- Loot marker (red)
            local m = cfg.Bank.lootMarker
            DrawMarker(1, m.pos.x, m.pos.y, m.pos.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.9, 0.9, 0.6, 255, 0, 0, 180, false, true, 2, nil, nil, false)

            -- Auto-start anim when inside the marker
            if #(pos - m.pos) <= (m.radius or 1.0) then
                if not activeBank.animPlaying then
                    playLootAnimLoop()
                end
            end

            -- Cancel anim with X
            if activeBank.animPlaying and IsControlJustPressed(0, cfg.Bank.cancelKey or 73) then
                activeBank.animPlaying = false
            end
        end
        ::sleep::
        Wait(0)
    end
end)

-- ====== BANK AIM-TO-START ======
CreateThread(function()
    while true do
        Wait(0)
        if not cfg or not cfg.Bank or activeStore or activeBank then goto cont end

        local myPed = PlayerPedId()
        local armed = IsPedArmed(myPed, 6)
        if armed and IsPlayerFreeAiming(PlayerId()) then
            local _, ent = GetEntityPlayerIsFreeAimingAt(PlayerId())
            local bankClerk = exports.cvr_core:GetBankClerk()
            if ent and bankClerk and ent == bankClerk and not IsPedDeadOrDying(ent, true) then
                -- prompt
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('Keep aiming to intimidate the clerk...')
                EndTextCommandDisplayHelp(0, false, true, -1)

                -- hold to start
                if aimingAt ~= ent then aimingAt = ent; aimStart = GetGameTimer() end
                if GetGameTimer() - aimStart >= ((cfg.Bank.aimSeconds or 2.0) * 1000) then
                    aimingAt, aimStart = nil, 0
                    -- hands up
                    ClearPedTasks(bankClerk)
                    TaskHandsUp(bankClerk, (cfg.Bank.timeSec or 180) * 1000 + 5000, 0, -1, true)
                    -- start server timer
                    TriggerServerEvent('cvr:crime:startBank')
                    -- track locally
                    activeBank = {
                        endTime = GetGameTimer() + ((cfg.Bank.timeSec or 180) * 1000),
                        center = cfg.Bank.doorPos or GetEntityCoords(bankClerk),
                        radius = cfg.Bank.areaRadius or 22.0,
                        clerkPed = bankClerk,
                        lootPos = cfg.Bank.lootMarker and cfg.Bank.lootMarker.pos,
                        lootR = (cfg.Bank.lootMarker and cfg.Bank.lootMarker.radius) or 1.0,
                        animPlaying = false
                    }
                    while IsPlayerFreeAiming(PlayerId()) do Wait(150) end
                end
            else
                aimingAt, aimStart = nil, 0
            end
        else
            aimingAt, aimStart = nil, 0
        end
        ::cont::
    end
end)
