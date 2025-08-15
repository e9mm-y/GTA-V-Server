-- client.lua - Simple coord grabber
local grabKey = 56 -- F9

CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, grabKey) then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local msg = ("vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading)
            print(msg) -- prints to F8 console
            TriggerEvent('chat:addMessage', { args = { '^2[Coords]', msg } }) -- optional: also in chat
        end
    end
end)
