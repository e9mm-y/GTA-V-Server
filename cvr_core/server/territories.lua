-- server/territories.lua

local zones = {}         -- DB state cache
local present = {}       -- players present in each territory: [code] = { [gangId] = count }

-- Ensure all territories exist in DB on resource start
CreateThread(function()
    for _, t in ipairs(Config.Territories) do
        MySQL.insert.await('INSERT IGNORE INTO cvr_territories (name) VALUES (?)', { t.code })
        zones[t.code] = { owner=nil, influence_gang=nil, influence=0 }
    end
end)

-- Presence tracking from clients
RegisterNetEvent('cvr:zone:presence', function(code, gangId, entering)
    local z = present[code] or {}
    if gangId then
        z[gangId] = math.max(0, (z[gangId] or 0) + (entering and 1 or -1))
    end
    present[code] = z
end)

-- Capture logic
local function tickCapture(code)
    local zinfo = present[code] or {}
    local topGang, topCount = nil, 0

    -- Find dominant gang in zone
    for gid, cnt in pairs(zinfo) do
        if cnt > topCount then
            topGang, topCount = gid, cnt
        end
    end

    if not topGang or topCount == 0 then
        -- Decay influence toward zero if no one present
        MySQL.update(
            'UPDATE cvr_territories SET influence = CASE WHEN influence > 0 THEN GREATEST(influence - ?, 0) WHEN influence < 0 THEN LEAST(influence + ?, 0) ELSE 0 END WHERE name = ?',
            { Config.Capture.decayOutside, Config.Capture.decayOutside, code }
        )
        return
    end

    local row = MySQL.single.await('SELECT * FROM cvr_territories WHERE name=?', { code })
    local inf = row and row.influence or 0
    local infGang = row and row.influence_gang_id

    if infGang ~= topGang then
        -- Change contesting gang
        infGang = topGang
        inf = 0
        MySQL.update('UPDATE cvr_territories SET influence_gang_id=?, influence=0 WHERE name=?', { infGang, code })
    else
        -- Add influence toward capturing
        inf = math.min(100, inf + Config.Capture.deltaPerTick)
        MySQL.update('UPDATE cvr_territories SET influence=? WHERE name=?', { inf, code })
    end

    -- Capture complete
    if inf >= Config.Capture.winThreshold then
        MySQL.update('UPDATE cvr_territories SET owner_gang_id=?, influence=0 WHERE name=?', { infGang, code })
        TriggerClientEvent('chat:addMessage', -1, { args={'Territory', ('Gang #%d captured %s'):format(infGang, code)} })
    end
end

-- Global capture loop
CreateThread(function()
    while true do
        Wait(Config.Capture.tickMs)
        for _, t in ipairs(Config.Territories) do
            tickCapture(t.code)
        end
    end
end)

-- Income loop
CreateThread(function()
    while true do
        Wait(Config.Income.intervalMin * 60 * 1000)
        for _, t in ipairs(Config.Territories) do
            local row = MySQL.single.await('SELECT owner_gang_id FROM cvr_territories WHERE name=?', { t.code })
            if row and row.owner_gang_id then
                for src, p in pairs(CVR.players) do
                    if p.gang_id == row.owner_gang_id then
                        CVR.AddCash(src, t.incomePerTick, true) -- dirty cash
                        TriggerClientEvent('cvr:notify', src, ('Territory income +$%d dirty'):format(t.incomePerTick))
                    end
                end
            end
        end
    end
end)
