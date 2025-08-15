-- client/stores_peds.lua
if IsDuplicityVersion() then return end

local cfg = {}
local clerks = {} -- [code] = {ped=ped, respawning=false}

RegisterNetEvent('cvr:syncConfig', function(c) cfg = c or {} end)

local function loadModel(model)
  local hash = type(model) == 'number' and model or GetHashKey(model)
  RequestModel(hash)
  local tries = 0
  while not HasModelLoaded(hash) and tries < 200 do Wait(25); tries+=1 end
  return hash
end

local function spawnClerk(store)
  if not store.pedPos or not store.pedModel then return end
  local rec = clerks[store.code] or {}
  if rec.ped and DoesEntityExist(rec.ped) then return end

  local hash = loadModel(store.pedModel); if not hash then return end
  local p = CreatePed(4, hash, store.pedPos.x, store.pedPos.y, store.pedPos.z - 1.0, store.pedHeading or 0.0, false, true)
  SetEntityAsMissionEntity(p, true, true)
  SetBlockingOfNonTemporaryEvents(p, true)
  SetPedFleeAttributes(p, 0, false)
  SetPedCombatAttributes(p, 46, true) -- allow fear, but no combat AI
  SetPedCanRagdoll(p, true)
  TaskStartScenarioInPlace(p, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)

  clerks[store.code] = { ped = p, respawning = false }
end

local function ensureClerks()
  if not cfg or not cfg.Stores then return end
  for _, s in ipairs(cfg.Stores) do spawnClerk(s) end
end

-- initial spawn when config arrives
CreateThread(function()
  while not cfg.Stores do Wait(250) end
  ensureClerks()
end)

-- watch for dead clerks, schedule respawn
CreateThread(function()
  while true do
    if cfg and cfg.Stores then
      for _, s in ipairs(cfg.Stores) do
        local rec = clerks[s.code]
        if rec and rec.ped and DoesEntityExist(rec.ped) then
          if IsPedDeadOrDying(rec.ped, true) and not rec.respawning then
            rec.respawning = true
            local delay = (s.clerkRespawnSec or (cfg.StoreDefaults and cfg.StoreDefaults.clerkRespawnSec) or 120)
            SetTimeout(delay * 1000, function()
              -- delete old + respawn
              if rec.ped and DoesEntityExist(rec.ped) then DeletePed(rec.ped) end
              clerks[s.code] = { ped = nil, respawning = false }
              spawnClerk(s)
            end)
          end
        elseif s.pedPos and not (rec and rec.respawning) then
          -- ped missing? respawn
          spawnClerk(s)
        end
      end
    end
    Wait(1000)
  end
end)

-- helpers for other client files
exports('GetClerkPed', function(code)
  return clerks[code] and clerks[code].ped or nil
end)

exports('HandsUpClerk', function(code, ms)
  local ped = clerks[code] and clerks[code].ped
  if ped and DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
    ClearPedTasks(ped)
    TaskHandsUp(ped, ms or 10000, 0, -1, true)
  end
end)

-- === BANK CLERK SPAWN ===
local bankClerk = nil

local function spawnBankClerk()
    if not cfg or not cfg.Bank or not cfg.Bank.clerk then return end
    if bankClerk and DoesEntityExist(bankClerk) then return end

    local c = cfg.Bank.clerk
    local hash = type(c.model) == 'number' and c.model or GetHashKey(c.model)
    RequestModel(hash)
    local tries = 0
    while not HasModelLoaded(hash) and tries < 200 do Wait(25) tries = tries + 1 end
    if not HasModelLoaded(hash) then return end

    bankClerk = CreatePed(4, hash, c.pos.x, c.pos.y, c.pos.z - 1.0, c.heading or 0.0, false, true)
    SetEntityAsMissionEntity(bankClerk, true, true)
    SetBlockingOfNonTemporaryEvents(bankClerk, true)
    SetPedFleeAttributes(bankClerk, 0, false)
    SetPedCanRagdoll(bankClerk, true)
    TaskStartScenarioInPlace(bankClerk, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
end

-- spawn bank clerk when config arrives
CreateThread(function()
    while not cfg do Wait(250) end
    Wait(500)
    spawnBankClerk()
end)

exports('GetBankClerk', function()
    return bankClerk
end)
