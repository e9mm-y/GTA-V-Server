Config = {}

Config.Identifier = function(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') then return id end
    end
    return GetPlayerIdentifier(src, 0)
end

Config.Territories = {
    {
        code = 'GROVE',
        name = 'Grove Street',
        center = vector3(-153.8, -1628.1, 34.9),
        radius = 120.0,
        incomePerTick = 350,
        pvpBuff = { armorBonus = 25, damageMult = 1.05 }
    },
}

Config.Stores = {
    {
        code = '247_STRAW', label = '24/7 Strawberry',
        pos = vector3(29.3, -1346.7, 29.5),
        pedPos = vector3(24.37, -1345.55, 29.5), pedHeading = 268.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 900, variance = 300, timeSec = 80, cooldownMin = 20,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = '247_ALTA', label = '24/7 Alta St',
        pos = vector3(2557.2, 382.1, 108.6),
        pedPos = vector3(2555.5, 380.7, 108.6), pedHeading = 355.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 950, variance = 300, timeSec = 80, cooldownMin = 20,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = '247_DAVIS', label = '24/7 Davis',
        pos = vector3(-47.5, -1759.1, 29.4),
        pedPos = vector3(-46.70, -1758.0, 29.42), pedHeading = 51.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 1000, variance = 350, timeSec = 90, cooldownMin = 25,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = '247_HARMONY', label = '24/7 Harmony',
        pos = vector3(549.1, 2671.4, 42.2),
        pedPos = vector3(549.1, 2672.8, 42.2), pedHeading = 93.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 950, variance = 350, timeSec = 85, cooldownMin = 22,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = 'LTD_GROVE', label = 'LTD Grove St',
        pos = vector3(-48.5, -1757.5, 29.4),
        pedPos = vector3(-46.55, -1758.2, 29.42), pedHeading = 51.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 1050, variance = 400, timeSec = 90, cooldownMin = 25,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = 'LTD_MIRROR', label = 'LTD Mirror Park',
        pos = vector3(1165.3, -323.0, 69.2),
        pedPos = vector3(1164.2, -322.0, 69.2), pedHeading = 100.0, pedModel = 'mp_m_shopkeep_01',
        minPolice = 0, base = 1100, variance = 400, timeSec = 95, cooldownMin = 26,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = 'ROBS_VESP', label = "Rob's Liquor Vespucci",
        pos = vector3(-1222.9, -906.9, 12.3),
        pedPos = vector3(-1219.0, -916.0, 11.33), pedHeading = 35.0, pedModel = 's_m_m_autoshop_01',
        minPolice = 0, base = 1050, variance = 350, timeSec = 95, cooldownMin = 26,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = 'ROBS_ROUTE68', label = "Rob's Liquor Route 68",
        pos = vector3(1165.3, 2709.4, 38.2),
        pedPos = vector3(1165.0, 2710.8, 38.2), pedHeading = 180.0, pedModel = 's_m_m_autoshop_01',
        minPolice = 0, base = 950, variance = 350, timeSec = 85, cooldownMin = 22,
        robDistance = 3.0, aimSeconds = 2.0
    },
    {
        code = 'ROBS_SANAND', label = "Rob's Liquor San Andreas Ave",
        pos = vector3(-707.5, -914.2, 19.2),
        pedPos = vector3(-706.0, -913.5, 19.2), pedHeading = 90.0, pedModel = 's_m_m_autoshop_01',
        minPolice = 0, base = 1050, variance = 400, timeSec = 90, cooldownMin = 25,
        robDistance = 3.0, aimSeconds = 2.0
    }
}

-- Defaults if a store doesn't override them
Config.StoreDefaults = {
  robDistance = 3.0,     -- how close you must be to the clerk when aiming
  aimSeconds  = 2.0,     -- how long to aim before robbery starts
  areaRadius  = 12.0,    -- how far you can stray from store.pos during robbery
  clerkRespawnSec = 120, -- time before clerk respawns after death
}


Config.Bank = {
    code = 'BANK_FLECCA_PB',
    label = 'Fleeca Bank - Legion Square',
    clerk = {
        pos = vector4(149.03, -1042.01, 29.37, 342.45),
        model = `cs_bankman`
    },
    doorPos = vector3(146.54, -1044.99, 29.38), -- where red loot marker appears
    minPolice = 4,      -- required police count to start robbery
    timeSec = 180,      -- time in seconds to complete robbery
    base = 20000,       -- base dirty money payout
    variance = 5000,    -- payout random +/- range
    cooldownMin = 30,   -- cooldown after robbery in minutes
    lootAnim = {
        dict = 'anim@heists@ornate_bank@grab_cash',
        anim = 'intro',        -- will play intro first, then loop
        loopAnim = 'grab',
        exitAnim = 'exit',
        bagModel = `hei_p_m_bag_var22_arm_s`,
        propBone = 57005,      -- right hand
        propOffset = vector3(0.12, 0.0, 0.0),
        propRot = vector3(0.0, 90.0, 0.0)
    }
}



Config.UseInventory = GetResourceState('ox_inventory') == 'started'
Config.UseTarget = GetResourceState('ox_target') == 'started'

Config.Capture = { tickMs = 5000, deltaPerTick = 5, winThreshold = 100, decayOutside = 1 }
Config.Income = { intervalMin = 10 }

Config.AutoArmorOnRespawn = 50
Config.LoadoutOnRespawn = { 'WEAPON_PISTOL', 'WEAPON_CARBINERIFLE', 'WEAPON_KNIFE' }

Config.Loadouts = {
    COP = { 'WEAPON_STUNGUN', 'WEAPON_PUMPSHOTGUN', 'WEAPON_CARBINERIFLE' },
    ROBBER = { 'WEAPON_PISTOL', 'WEAPON_SAWNOFFSHOTGUN' }
}

-- Add near the bottom
Config.Launder = {
  pos = vector3(1121.0, -3194.8, -40.4),  -- Example: warehouse interior (change if you want)
  radius = 1.5,
  rate = 0.75,       -- 75% of dirty becomes clean
  minAmount = 500,   -- minimum dirty to launder
  cooldownMin = 5    -- per-player cooldown
}
