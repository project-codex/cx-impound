fx_version 'adamant'
game 'gta5'
version '0.0.1'
author = 'choxens'

client_scripts {
    'client/client.lua'
}

server_scripts {
    'server/server.lua',
    '@oxmysql/lib/MySQL.lua'
}

shared_script {
    'config.lua'
}

dependencies {
    'qb-core'
}

lua54 'yes'
