local Identifier = Config.Identifier

CVR = {}
CVR.players = {} -- cache minimal player state

-- Ensure player row exists in database
local function ensurePlayer(identifier)
    MySQL.insert.await('INSERT IGNORE INTO cvr_players (identifier) VALUES (?)', { identifier })
end

AddEventHandler('playerJoining', function()
    local src = source
    local id = Identifier(src)
    ensurePlayer(id)

    local row = MySQL.single.await('SELECT * FROM cvr_players WHERE identifier = ?', { id })
    if row then
        CVR.players[src] = {
            identifier = id,
            gang_id = row.gang_id,
            gang_rank = row.gang_rank or 0,
            cash = row.cash or 0,
            dirty_cash = row.dirty_cash or 0
        }
    end
    TriggerClientEvent('cvr:syncSelf', src, CVR.players[src])
    TriggerClientEvent('cvr:syncConfig', src, Config)
end)

AddEventHandler('playerDropped', function()
    CVR.players[source] = nil
end)

-- Money helpers (fallback if no ox_inventory)
function CVR.AddCash(src, amount, dirty)
    if Config.UseInventory then
        if dirty then
            exports.ox_inventory:AddItem(src, 'markedbills', amount)
        else
            exports.ox_inventory:AddItem(src, 'money', amount)
        end
        return
    end

    local p = CVR.players[src]
    if not p then return end

    if dirty then
        p.dirty_cash = p.dirty_cash + amount
    else
        p.cash = p.cash + amount
    end

    MySQL.update('UPDATE cvr_players SET cash = ?, dirty_cash = ? WHERE identifier = ?',
        { p.cash, p.dirty_cash, p.identifier })

    TriggerClientEvent('cvr:syncSelf', src, p)
end

exports('GetPlayerGang', function(src)
    local p = CVR.players[src]
    if not p then return nil end
    return p.gang_id, p.gang_rank
end)
