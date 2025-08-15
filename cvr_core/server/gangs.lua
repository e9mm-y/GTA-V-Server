-- server/gangs.lua

local function msg(src, title, text)
    TriggerClientEvent('chat:addMessage', src, { args = { title or 'Gang', text or '' } })
end

local function getPlayerState(src)
    return CVR and CVR.players and CVR.players[src]
end

local function setPlayerGang(src, gang_id, rank)
    local p = getPlayerState(src); if not p then return end
    p.gang_id = gang_id
    p.gang_rank = rank or 0
    MySQL.update('UPDATE cvr_players SET gang_id=?, gang_rank=? WHERE identifier=?', { gang_id, p.gang_rank, p.identifier })
    TriggerClientEvent('cvr:syncSelf', src, p)
end

-- /gangcreate <name...>
RegisterCommand('gangcreate', function(src, args)
    local name = table.concat(args or {}, ' '):gsub('^%s+', ''):gsub('%s+$', '')
    if name == '' then return msg(src, 'Gang', 'Usage: /gangcreate <name>') end

    local p = getPlayerState(src); if not p then return end
    if p.gang_id then return msg(src, 'Gang', 'You are already in a gang. Use /gangleave first.') end

    local tag = name:sub(1, 4):upper()
    local ok, id = pcall(function()
        return MySQL.insert.await('INSERT INTO cvr_gangs (name, tag) VALUES (?, ?)', { name, tag })
    end)

    if not ok or not id then
        return msg(src, 'Gang', 'Name already taken or DB error.')
    end

    setPlayerGang(src, id, 2) -- leader
    msg(src, 'Gang', ('You created "%s" [%s].'):format(name, tag))
    TriggerClientEvent('chat:addMessage', -1, { args = { 'Gang', ('%s created gang %s'):format(GetPlayerName(src), name) } })
end)

-- Invitations cache (non-persistent): invitee -> { gang_id, inviter, expireAt }
local invites = {}

local function cleanupInvites()
    local now = GetGameTimer()
    for tgt, data in pairs(invites) do
        if not GetPlayerName(tostring(tgt)) or (data.expireAt and data.expireAt < now) then
            invites[tgt] = nil
        end
    end
end

-- /ganginvite <serverId>
RegisterCommand('ganginvite', function(src, args)
    cleanupInvites()
    local target = tonumber(args[1] or '')
    if not target or not GetPlayerName(target) then
        return msg(src, 'Gang', 'Usage: /ganginvite <serverId>')
    end

    local inviter = getPlayerState(src); if not inviter then return end
    if not inviter.gang_id or (inviter.gang_rank or 0) < 1 then
        return msg(src, 'Gang', 'Officer or leader required to invite.')
    end

    local targetP = getPlayerState(target); if not targetP then return end
    if targetP.gang_id then
        return msg(src, 'Gang', 'That player is already in a gang.')
    end

    invites[target] = { gang_id = inviter.gang_id, inviter = src, expireAt = GetGameTimer() + 120000 }
    msg(src, 'Gang', ('Invitation sent to %s. Expires in 2 minutes.'):format(GetPlayerName(target)))
    msg(target, 'Gang', ('You were invited to join gang #%d by %s. Use /gangaccept or /gangdecline.'):format(inviter.gang_id, GetPlayerName(src)))
end)

-- /gangaccept
RegisterCommand('gangaccept', function(src)
    cleanupInvites()
    local inv = invites[src]
    if not inv then return msg(src, 'Gang', 'You have no pending invite.') end

    local p = getPlayerState(src); if not p then return end
    if p.gang_id then
        invites[src] = nil
        return msg(src, 'Gang', 'You are already in a gang.')
    end

    setPlayerGang(src, inv.gang_id, 0)
    invites[src] = nil
    msg(src, 'Gang', 'Joined gang.')
    if GetPlayerName(inv.inviter) then
        msg(inv.inviter, 'Gang', ('%s accepted your invite.'):format(GetPlayerName(src)))
    end
end)

-- /gangdecline
RegisterCommand('gangdecline', function(src)
    cleanupInvites()
    local inv = invites[src]
    if not inv then return msg(src, 'Gang', 'You have no pending invite.') end
    invites[src] = nil
    msg(src, 'Gang', 'Invite declined.')
    if GetPlayerName(inv.inviter) then
        msg(inv.inviter, 'Gang', ('%s declined your invite.'):format(GetPlayerName(src)))
    end
end)

-- /gangleave
RegisterCommand('gangleave', function(src)
    local p = getPlayerState(src); if not p then return end
    if not p.gang_id then return msg(src, 'Gang', 'You are not in a gang.') end

    -- If leader, warn (simple rule: leaders can leave; gang persists)
    if p.gang_rank == 2 then
        msg(src, 'Gang', 'You were the leader. Consider promoting someone before leaving.')
    end

    setPlayerGang(src, nil, 0)
    msg(src, 'Gang', 'You left your gang.')
end)

-- /gangpromote <serverId>
RegisterCommand('gangpromote', function(src, args)
    local target = tonumber(args[1] or '')
    if not target or not GetPlayerName(target) then
        return msg(src, 'Gang', 'Usage: /gangpromote <serverId>')
    end

    local p = getPlayerState(src); if not p then return end
    if (p.gang_rank or 0) < 2 then return msg(src, 'Gang', 'Only the leader can promote.') end
    if p.gang_id == nil then return msg(src, 'Gang', 'You have no gang.') end

    local tp = getPlayerState(target); if not tp then return end
    if tp.gang_id ~= p.gang_id then return msg(src, 'Gang', 'Target must be in your gang.') end

    local newRank = math.min(1, (tp.gang_rank or 0) + 1) -- cap at officer
    if newRank == (tp.gang_rank or 0) then return msg(src, 'Gang', 'Player is already officer or higher.') end

    tp.gang_rank = newRank
    MySQL.update('UPDATE cvr_players SET gang_rank=? WHERE identifier=?', { newRank, tp.identifier })
    TriggerClientEvent('cvr:syncSelf', target, tp)

    msg(src, 'Gang', ('Promoted %s to officer.'):format(GetPlayerName(target)))
    msg(target, 'Gang', 'You were promoted to officer.')
end)

-- /gangdemote <serverId>
RegisterCommand('gangdemote', function(src, args)
    local target = tonumber(args[1] or '')
    if not target or not GetPlayerName(target) then
        return msg(src, 'Gang', 'Usage: /gangdemote <serverId>')
    end

    local p = getPlayerState(src); if not p then return end
    if (p.gang_rank or 0) < 2 then return msg(src, 'Gang', 'Only the leader can demote.') end
    if p.gang_id == nil then return msg(src, 'Gang', 'You have no gang.') end

    local tp = getPlayerState(target); if not tp then return end
    if tp.gang_id ~= p.gang_id then return msg(src, 'Gang', 'Target must be in your gang.') end

    local newRank = math.max(0, (tp.gang_rank or 0) - 1)
    if newRank == (tp.gang_rank or 0) then return msg(src, 'Gang', 'Player is already lowest rank.') end

    tp.gang_rank = newRank
    MySQL.update('UPDATE cvr_players SET gang_rank=? WHERE identifier=?', { newRank, tp.identifier })
    TriggerClientEvent('cvr:syncSelf', target, tp)

    msg(src, 'Gang', ('Demoted %s.'):format(GetPlayerName(target)))
    msg(target, 'Gang', 'You were demoted.')
end)

-- /gangkick <serverId>
RegisterCommand('gangkick', function(src, args)
    local target = tonumber(args[1] or '')
    if not target or not GetPlayerName(target) then
        return msg(src, 'Gang', 'Usage: /gangkick <serverId>')
    end

    local p = getPlayerState(src); if not p then return end
    if not p.gang_id then return msg(src, 'Gang', 'You have no gang.') end
    if (p.gang_rank or 0) < 1 then return msg(src, 'Gang', 'Officer or leader required to kick.') end

    local tp = getPlayerState(target); if not tp then return end
    if tp.gang_id ~= p.gang_id then return msg(src, 'Gang', 'Target is not in your gang.') end

    -- Officers cannot kick leaders; leaders can kick anyone; officers can kick members
    if tp.gang_rank == 2 and p.gang_rank < 2 then
        return msg(src, 'Gang', 'You cannot kick the leader.')
    end
    if tp.gang_rank == 1 and p.gang_rank < 2 then
        return msg(src, 'Gang', 'Only the leader can kick an officer.')
    end

    setPlayerGang(target, nil, 0)
    msg(src, 'Gang', ('Kicked %s from the gang.'):format(GetPlayerName(target)))
    msg(target, 'Gang', 'You were removed from the gang.')
end)
