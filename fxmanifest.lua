

game 'rdr3'
fx_version 'cerulean'

author 'VORP ASHKAN'
description 'VORP Housing'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

lua54 'yes'


shared_scripts {
	"config.lua",
	"locale.lua",
	"languages/*.lua"
}

client_scripts {
   'client/client.lua'
}

server_scripts {
   'server/server.lua',
   '@oxmysql/lib/MySQL.lua'
}


