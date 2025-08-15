-- client/hud.lua
local selfState = { cash = 0, dirty_cash = 0 }
local hudEnabled = true

-- get updates from server (on join and after payouts)
RegisterNetEvent('cvr:syncSelf', function(p)
    if not p then return end
    selfState.cash = p.cash or 0
    selfState.dirty_cash = p.dirty_cash or 0
end)

-- optional toggle command
RegisterCommand('hud', function()
    hudEnabled = not hudEnabled
    if hudEnabled then
        TriggerEvent('cvr:notify', 'HUD: ON')
    else
        TriggerEvent('cvr:notify', 'HUD: OFF')
    end
end, false)

-- simple text draw helpers
local function drawText(x, y, text, scale, r, g, b, a, alignRight)
    SetTextFont(4)
    SetTextProportional(0)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextOutline()
    if alignRight then SetTextRightJustify(true); SetTextWrap(0.0, x) end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawBox(x, y, w, h, r, g, b, a)
    DrawRect(x + w/2, y + h/2, w, h, r, g, b, a)
end

-- render loop
CreateThread(function()
    while true do
        if hudEnabled then
            -- top-right padding
            local right = 0.985
            local top   = 0.02

            -- background panel
            local width = 0.20
            local height = 0.062
            drawBox(right - width, top, width, height, 0, 0, 0, 120)

            -- labels
            local cashText  = ("Cash:  $%s"):format(CommaValue(selfState.cash or 0))
            local dirtyText = ("Dirty: $%s"):format(CommaValue(selfState.dirty_cash or 0))

            drawText(right - 0.008, top + 0.008, cashText, 0.35, 255, 255, 255, 230, true)
            drawText(right - 0.008, top + 0.034, dirtyText, 0.35, 255, 180, 60, 230, true)
        end
        Wait(0)
    end
end)

-- number formatting
function CommaValue(n)
    local left,num,right = string.match(tostring(math.floor(tonumber(n) or 0)), '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)','%1,'):reverse()) .. right
end
