fx_version 'cerulean'
game 'gta5'

author 'fourtwenty'
description 'Advanced Blackmarket System'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/locale.lua',
    'shared/bridge.lua',
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/**/*'
}