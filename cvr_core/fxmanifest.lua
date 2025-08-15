fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/gangs.lua',
    'server/territories.lua',
    'server/crime.lua',
    'server/police.lua',
    'server/admin.lua'
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/territories.lua',
    'client/crime.lua',
    'client/police.lua',
    'client/hud.lua',
    'client/admin.lua',
    'client/blips.lua',
    'client/stores_peds.lua',
    'client/rob_aim.lua',
    'client/interact.lua'
}

dependencies {
    'ox_lib'
}
