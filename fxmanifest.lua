fx_version 'cerulean'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

author 'mack'
description 'Gun For Hire - Multi-Mission System for RSG-Core'
version '1.0.0'

dependencies {
    'rsg-core',
    'ox_lib',
    'ox_target',
    'bln_notify'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/init.lua',
    'locales/en.lua'
}

server_scripts {
    'server/callbacks.lua',
    'server/main.lua'
}

client_scripts {
    'client/utils.lua',
    'client/main.lua',
    'client/missions.lua'
}

lua54 'yes'
