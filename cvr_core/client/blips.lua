-- client/blips.lua
if IsDuplicityVersion() then return end

local created = {}
local cfg = {}

local function makeBlip(pos, sprite, color, name, scale)
    local b = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(b, sprite)
    SetBlipColour(b, color or 0)
    SetBlipScale(b, scale or 0.8)
    SetBlipAsShortRange(b, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(name)
    EndTextCommandSetBlipName(b)
    return b
end

local function clearBlips()
    for _, b in ipairs(created) do
        if DoesBlipExist(b) then RemoveBlip(b) end
    end
    created = {}
end

local function refreshBlips()
    clearBlips()
    if not cfg then return end

    -- Stores (shopping bag / 52)
    if cfg.Stores then
        for _, s in ipairs(cfg.Stores) do
            if s.pos and s.label then
                created[#created+1] = makeBlip(s.pos, 52, 5, s.label, 0.75)
            end
        end
    end

    -- Bank (dollar / 108)
    if cfg.Bank and cfg.Bank.doorPos then
        local name = cfg.Bank.label or 'Bank (Robbable)'
        created[#created+1] = makeBlip(cfg.Bank.doorPos, 108, 2, name, 0.85)
    end

    -- Territories (flag / 419)
    if cfg.Territories then
        for _, t in ipairs(cfg.Territories) do
            if t.center then
                local name = ('Turf: %s'):format(t.name or t.code or 'Unknown')
                created[#created+1] = makeBlip(t.center, 419, 1, name, 0.8)
            end
        end
    end
end

-- Update cfg + refresh immediately
RegisterNetEvent('cvr:syncConfig', function(c)
    cfg = c or {}
    refreshBlips()
end)

-- First-time build (in case sync arrives late)
CreateThread(function()
    local t = 0
    while not cfg.Stores and t < 80 do
        Wait(250); t = t + 1
    end
    refreshBlips()
end)

RegisterCommand('blips', function()
    refreshBlips()
    TriggerEvent('cvr:notify', 'Blips refreshed')
end, false)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then clearBlips() end
end)
