services 			= services or {
	cfg 			= {},
	curRequests 	= {},
	allServices		= {}
}

local version 		= 1.0

local includeSH 		= SERVER and function(filePath) include(filePath) AddCSLuaFile(filePath) end or include
local includeSV 		= SERVER and include or function() end
local includeCL 		= SERVER and AddCSLuaFile or include

local loadTypes 		= {
	_sh 			= includeSH,
	_sv 			= includeSV,
	_cl 			= includeCL
}

services.include 		= function(filePath)
	if loadTypes[filePath:sub(filePath:len() - 6, filePath:len() - 4)] then
		loadTypes[filePath:sub(filePath:len() - 6, filePath:len() - 4)](filePath)
	end
end

local files, _ = file.Find('bizzy_services/*.lua', 'LUA')
if not files then return end

for _, fileStr in pairs(files) do
	services.include('bizzy_services/' .. fileStr)
end

local msg = {
	[[ ____  _                  _____                 _               ]],
	[[|  _ \(_)                / ____|               (_)              ]],
	[[| |_) |_ _________   _  | (___   ___ _ ____   ___  ___ ___  ___ ]],
	[[|  _ <| |_  /_  / | | |  \___ \ / _ \ '__\ \ / / |/ __/ _ \/ __|]],
	[[| |_) | |/ / / /| |_| |  ____) |  __/ |   \ V /| | (_|  __/\__ \]],
	[[|____/|_/___/___|\__, | |_____/ \___|_|    \_/ |_|\___\___||___/]],
	[[                  __/ |                                         ]],
	[[                 |___/                                          ]],
	[[ Version: ]] .. version .. [[                                                     ]],
	[[      --> Credits:                                              ]],
	[[        - Bizzy: All development of the script                  ]],
	[[        - Ganged: Dank UI design                                ]]
}

timer.Simple(0, function()
	MsgC(Color(25, 255, 25), '====================================================================\n')

	for _, str in pairs(msg) do
		MsgC(Color(25, 255, 25), '||' ..str .. '||\n')
	end

	MsgC(Color(25, 255, 25), '====================================================================\n')
end)

local count = 1

function services.addService(name, multiAccept, description, ...)
	local teams = {...}
	local found = false
	local num = count

	for _, data in ipairs(services.allServices) do
		if data.name == name then
			num = _
			found = true

			break
		end
	end

	services.allServices[num] = {
		name 			= name,
		teams 		= {},
		multiAccept 	= (multiAccept or false),
		desc 			= (description or nil)
	}

	for _, teamID in pairs(teams) do
		services.allServices[num].teams[teamID] = true
	end

	if not found then
		count = count + 1
	end
end