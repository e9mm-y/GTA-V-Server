if IsDuplicityVersion() then return end

-- client/admin.lua
local ADMIN = { allowed = false }
local noclip = false
local speed = 1.0
local showCoords = false
local lastAuthCheck = 0

-- ask server if we're allowed
RegisterNetEvent('cvr:admin:authorized', function(yes)
    ADMIN.allowed = yes and true or false
    if not ADMIN.allowed and noclip then
        noclip = false
        SetEntityCollision(PlayerPedId(), true, true)
        SetEntityInvincible(PlayerPedId(), false)
        SetEntityVisible(PlayerPedId(), true, false)
    end
end)

-- on join, request auth
CreateThread(function()
    while true do
        if (GetGameTimer() - lastAuthCheck) > 5000 then
            TriggerServerEvent('cvr:admin:auth')
            lastAuthCheck = GetGameTimer()
        end
        Wait(3000)
    end
end)

-- ===== Commands =====

-- Toggle coords HUD
RegisterCommand('coords', function()
    if not ADMIN.allowed then return end
    showCoords = not showCoords
    TriggerEvent('cvr:notify', showCoords and 'Coords HUD: ON' or 'Coords HUD: OFF')
end, false)

-- Teleport to waypoint
RegisterCommand('tpm', function()
    if not ADMIN.allowed then return end
    local blip = GetFirstBlipInfoId(8) -- Blip ID 8 = Waypoint
    if not DoesBlipExist(blip) then
        TriggerEvent('cvr:notify', 'No waypoint set.')
        return
    end
    local coord = GetBlipInfoIdCoord(blip)
    local x, y = coord.x + 0.0, coord.y + 0.0

    -- find safe ground Z
    local z = 1000.0
    local found, gz
    for i = 1, 1000 do
        found, gz = GetGroundZFor_3dCoord(x, y, z, false)
        if found then break end
        z = z - 10.0
        if z < -200.0 then break end
    end
    local ped = PlayerPedId()
    SetPedCoordsKeepVehicle(ped, x, y, (found and (gz + 1.0)) or 200.0)
end, false)

-- Teleport to coords: /tp x y z
RegisterCommand('tp', function(_, args)
    if not ADMIN.allowed then return end
    local x = tonumber(args[1] or '')
    local y = tonumber(args[2] or '')
    local z = tonumber(args[3] or '')
    if not (x and y) then
        TriggerEvent('cvr:notify', 'Usage: /tp <x> <y> <z?>')
        return
    end
    local ped = PlayerPedId()
    if not z then
        -- auto ground z
        local found, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
        z = (found and (gz + 1.0)) or 200.0
    end
    SetPedCoordsKeepVehicle(ped, x + 0.0, y + 0.0, z + 0.0)
end, false)

-- Toggle noclip fly
RegisterCommand('noclip', function()
    if not ADMIN.allowed then return end
    noclip = not noclip
    local ped = PlayerPedId()
    if noclip then
        SetEntityCollision(ped, false, false)
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        TriggerEvent('cvr:notify', 'Noclip: ON  (W/S move, A/D strafe, Q/E up/down, Shift faster, Ctrl slower)')
    else
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        TriggerEvent('cvr:notify', 'Noclip: OFF')
    end
end, false)

-- Noclip movement loop
CreateThread(function()
    while true do
        if noclip then
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped)
            local camRot = GetGameplayCamRot(2)
            local heading = math.rad(camRot.z)
            local forward = vector3(-math.sin(heading), math.cos(heading), 0.0)
            local right = vector3(-forward.y, forward.x, 0.0)

            -- speed modifiers
            local spd = speed
            if IsControlPressed(0, 21) then spd = spd * 4.0 end   -- Shift: faster
            if IsControlPressed(0, 36) then spd = spd * 0.25 end  -- Ctrl: slower

            -- input
            local move = vector3(0,0,0)
            if IsControlPressed(0, 32) then move = move + forward end     -- W
            if IsControlPressed(0, 33) then move = move - forward end     -- S
            if IsControlPressed(0, 34) then move = move - right end       -- A
            if IsControlPressed(0, 35) then move = move + right end       -- D
            if IsControlPressed(0, 44) then move = move + vector3(0,0,1) end  -- Q
            if IsControlPressed(0, 51) then move = move - vector3(0,0,1) end  -- E

            -- apply
            local newPos = pos + (move * spd)
            SetEntityCoordsNoOffset(ped, newPos.x, newPos.y, newPos.z, false, false, false)
            SetEntityVelocity(ped, 0.0, 0.0, 0.0)
            DisableControlAction(0, 22, true) -- disable jump
        end
        Wait(0)
    end
end)

-- Simple coords HUD render
CreateThread(function()
    while true do
        if showCoords then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)
            local text = ("x=%.2f  y=%.2f  z=%.2f  h=%.2f"):format(c.x, c.y, c.z, h)
            SetTextFont(4); SetTextScale(0.35, 0.35); SetTextColour(255,255,255,220)
            SetTextOutline()
            SetTextRightJustify(true); SetTextWrap(0.0, 0.985)
            BeginTextCommandDisplayText("STRING"); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayText(0.985, 0.08)
        end
        Wait(0)
    end
end)

-- DEBUG: prove the client file is loaded
RegisterCommand('cvrdebug', function()
    TriggerEvent('cvr:notify', 'Client admin.lua is loaded ✅')
end, false)
