local pairs 			= pairs
local player_GetAll 		= player.GetAll
local player_GetCount 		= player.GetCount
local CurTime 			= CurTime

local table_insert 		= table.insert
local table_remove		= table.remove
local table_HasValue		= table.HasValue
local table_RemoveByValue	= table.RemoveByValue
local table_Count 		= table.Count

local IsValid 		= IsValid
local type 				= type

local format 			= string.format
local find 				= string.find
local explode 			= string.Explode

local sstr 				= SQLStr
local query 			= sql.Query
local timer_Simple 		= timer.Simple
local net 			= net

local cfg 				= services.cfg
local color_red 			= Color(255, 25, 25)
local color_white 		= Color(255, 255, 255)

local resolved 			= {}

services.playerBans 		= services.playerBans or {}

util.AddNetworkString 'services.initRequests'
util.AddNetworkString 'services.newRequest'
util.AddNetworkString 'services.updateRequest'
util.AddNetworkString 'services.deleteRequest'
util.AddNetworkString 'services.notify'
util.AddNetworkString 'services.requestMenu'
util.AddNetworkString 'services.respondMenu'
util.AddNetworkString 'services.displayRequest'
util.AddNetworkString 'services.resolveRequestRequester'
util.AddNetworkString 'services.closeRequest'
util.AddNetworkString 'services.respond'
util.AddNetworkString 'services.resolve'
util.AddNetworkString 'services.unclaim'

hook.Add('Initialize', 'services.bansInit', function()
	query 'create table if not exists services_bans (playerID varchar(20))'
end)

hook.Add('InitPostEntity', 'services.loadBans', function()
	local data = query 'select playerID from services_bans'

	if data then
		for _, ban in pairs(data) do
			services.playerBans[ban.playerID] = true
		end
	end
end)

function services.notify(pl, ...)
	local msg = {...}

	net.Start 'services.notify'
		net.WriteTable(msg)
	net.Send(pl)
end

function services.findPlayer(data)
	if not data then return end

	data = data:lower()
	local allPlayers = player_GetAll()

	for i = 1, player_GetCount() do
		local pl = allPlayers[i]
		if not pl or not IsValid(pl) then continue end

		if pl:SteamID():lower() == data then
			return pl
		end

		if pl:SteamID64() == data then
			return pl
		end

		if find(pl:Name():lower(), data, 1, true) == 1 then
			return pl
		end
	end

	return nil
end

function services.canSubmit(pl, service)
	if pl.serviceCooldown and pl.serviceCooldown > CurTime() then services.notify(pl, cfg.translate.waitCooldown) return false end

	local serviceData = services.allServices[service]
	if not serviceData then return false end

	if services.isBanned(pl) then
		services.notify(pl, cfg.translate.youAreBanned)
		return false
	end

	if serviceData.teams[pl:Team()] then
		services.notify(pl, cfg.translate.cantCallService)
		return false
	end

	if cfg.needPlayers then
		if #services.getServicePlayers(service) < 1 then
			services.notify(pl, cfg.translate.noneOnline)
			return false
		end
	end

	return true
end

local curNum = 1

function services.submit(pl, service, msg)
	if not services.canSubmit(pl, service) then return end

	if services.getPlayerRequests(pl) and table_Count(services.getPlayerRequests(pl)) > 0 then
		services.notify(pl, 'Deleting your old request and submitting a new one!')
		services.delete(services.getPlayerRequests(pl)[1].id)
	end

	local servicePlayers = services.getServicePlayers(service)
	local serviceData = services.allServices[service]

	local requestData = {
		submitter	 	= pl,
		service 		= service,
		msg 			= msg,
		submitTime		= CurTime(), -- gonna set submitDate in client cuz server doesnt need it
		responder 		= (serviceData.multiAccept and {} or nil),
		requesterClosed	= false,
		id 			= curNum
	}

	table_insert(services.curRequests, requestData)

	net.Start 'services.newRequest'
		net.WriteTable(requestData)
	net.Send(servicePlayers)

	services.notify(servicePlayers, 'New service request from ', color_red, pl:Name() .. '!', color_white, ' View it with !respond')

	if cfg.autoRemoveRequest ~= 0 then
		timer_Simple(cfg.autoRemoveRequest, function()
			if services.getRequestByID(requestData.id) then
				services.delete(requestData.id)

				if IsValid(pl) then
					services.notify(pl, 'Your service was automatically closed!')
				end
			end
		end)
	end

	pl.serviceCooldown = CurTime() + cfg.cooldown
	services.notify(pl, cfg.translate.submittedRequest)
	services.notify(pl, cfg.translate.canReportPlayer)

	net.Start 'services.displayRequest'
	net.Send(pl)

	curNum = curNum + 1
end

function services.respond(pl, id)
	if services.isBanned(pl) then
		services.notify(pl, cfg.translate.youAreBanned)
		return false
	end

	if pl.curRequest and services.getRequestByID(pl.curRequest) then
		services.notify(pl, 'Resolve/unclaim your current service request before moving to another!')
		return
	end

	local requestData = services.getRequestByID(id)

	if not requestData then
		services.notify(pl, cfg.translate.doesntExist)
		return
	end

	if not requestData.submitter or not IsValid(requestData.submitter) then
		services.notify(pl, cfg.translate.requesterDisconnect)
		return
	end

	local serviceData = services.allServices[requestData.service]
	local servicePlayers = services.getServicePlayers(requestData.service)

	if not serviceData.teams[pl:Team()] then
		services.notify(pl, cfg.translate.cantAccess)
		return
	end

	if not serviceData.multiRespond and requestData.responder and IsValid(requestData.responder) then
		services.notify(pl, cfg.translate.alreadyResponded)
		return
	end

	if serviceData.multiRespond then
		if not table_HasValue(requestData.responder, pl) then
			table_insert(requestData.responder, pl)
		else
			services.notify(pl, 'You already responded to this!')
		end
	else
		requestData.responder = pl
	end

	pl.curRequest = id

	net.Start 'services.updateRequest'
		net.WriteTable(requestData)
	net.Send(servicePlayers)

	net.Start 'services.respond'
		net.WriteTable(requestData)
	net.Send(pl)

	services.notify(requestData.submitter, color_red, pl:Name(), color_white, ' has responded to your service request and will be there soon!')
	services.notify(servicePlayers, color_red, pl:Name(), color_white, ' has responded to a request made by ', color_red, requestData.submitter:Name() .. '!')
end

function services.resolve(pl, id)
	local requestData = resolved[id]

	if not resolved[id] then
		services.notify(pl, 'The requester has not resolved this service request! Ask them to resolved it if you have finished.')
		return
	end

	if type(requestData) == 'table' and not table_HasValue(requestData, pl) or requestData ~= pl then return end

	if cfg.rewardOnResolve then
		services.rewardPlayer(pl, cfg.rewardAmount)
	end

	services.notify(pl, cfg.translate.serviceResolvedResponder)


	if type(requestData) == 'table' then
		table_RemoveByValue(requestData, pl)

		if table_Count(requestData) <= 0 then
			resolved[id] = nil
		end
	else
		resolved[id] = nil
	end
end

function services.isBanned(pl)
	return (services.playerBans[pl:SteamID()] or false)
end

function services.ban(pl, admin)
	if not cfg.adminRanks[admin:GetUserGroup()] then return end

	if services.isBanned(pl) then
		services.notify(admin, color_red, pl:Name(), color_white, ' is already banned!')
		return
	end

	services.playerBans[pl:SteamID()] = true
	query(format("insert into services_bans (`playerID`) values (%s)", sstr(pl:SteamID())))

	services.notify(player_GetAll(), color_red, admin:Name() .. '(' .. admin:SteamID() .. ')', color_white, ' has banned ', color_red, pl:Name() .. '(' .. pl:SteamID() .. ')', color_white, ' from using the services system!')
end

function services.unban(pl, admin)
	if not cfg.adminRanks[admin:GetUserGroup()] then return end

	if not services.isBanned(pl) then
		services.notify(admin, color_red, pl:Name(), color_white, ' is not banned!')
		return
	end

	services.playerBans[pl:SteamID()] = nil
	query(format("delete from services_bans where playerID = %s", sstr(pl:SteamID())))

	services.notify(player_GetAll(), color_red, admin:Name() .. '(' .. admin:SteamID() .. ')', color_white, ' has unbanned ', color_red, pl:Name() .. '(' .. pl:SteamID() .. ')', color_white, ' from using the services system!')
end

function services.delete(id)
	local index = services.getRequestIndex(id)
	if not index then return end

	local servicePlayers = services.getServicePlayers(services.curRequests[index].service)

	table_remove(services.curRequests, index)

	net.Start 'services.deleteRequest'
		net.WriteInt(id, 32)
	net.Send(servicePlayers)
end

function services.unclaim(pl, id)
	local requestData = services.getRequestByID(id)
	if not requestData then return end

	local servicePlayers = services.getServicePlayers(requestData.service)

	if requestData.responder then
		if type(requestData.responder) == 'table' and table_HasValue(requestData.responder, pl) then
			table_RemoveByValue(requestData.responder)
		elseif requestData.responder == pl then
			requestData.responder = nil
		end
	end

	if servicePlayers then
		services.notify(servicePlayers, color_red, pl:Name(), color_white, ' has unclaimed a service request! View it with !respond.')
	end

	if IsValid(requestData.submitter) then
		services.notify(requestData.submitter, color_red, pl:Name(), color_white, ' has unclaimed your service request!')
	end
end

function services.initRequests(pl)
	local allServices = services.allServices
	local plServices = {}

	for i = 1, #allServices do
		local data = allServices[i]
		if not data then continue end

		if data.teams[pl:Team()] then
			plServices = services.getRequestsByService(i)
		end
	end

	net.Start 'services.initRequests'
		net.WriteTable(plServices)
	net.Send(pl)
end

hook.Add('PlayerInitialSpawn', 'services.initSpawn', services.initRequests)
hook.Add('OnPlayerChangedTeam', 'services.teamChange', services.initRequests)

hook.Add('PlayerDisconnected', 'services.playerDC', function(pl)
	local allRequests = services.getPlayerRequests(pl)

	if allRequests and #allRequests >= 1 then
		for i = 1, #allRequests do
			local data = allRequests[i]
			if not data then continue end

			services.delete(data.id)
		end
	end

	if pl.curRequest and services.getRequestIndex(pl.curRequest) then
		services.unclaim(pl, pl.curRequest)
	end
end)

hook.Add('PlayerSay', 'services.menuCommands', function(pl, txt)
	local args = explode(' ', txt)

	if args and args[1] then
		if args[1] == cfg.banCommand then
			local targ = services.findPlayer((args[2] or ''))

			if targ and IsValid(targ) then
				services.ban(targ, pl)
			else
				services.notify(pl, 'Player not found!')
			end

			return ''
		end

		if args[1] == cfg.unbanCommand then
			local targ = services.findPlayer((args[2] or ''))

			if targ and IsValid(targ) then
				services.unban(targ, pl)
			else
				services.notify(pl, 'Player not found!')
			end

			return ''
		end

		if cfg.menuCommands.requestMenu[args[1]] then
			net.Start 'services.requestMenu'
			net.Send(pl)
		elseif cfg.menuCommands.respondMenu[args[1]] then
			net.Start 'services.respondMenu'
			net.Send(pl)
		end
	end
end)

net.Receive('services.newRequest', function(_, pl)
	local service = net.ReadInt(16)
	if not services.allServices[service] then return end

	local msg = net.ReadString()
	msg = msg:sub(1, cfg.messageLengthLimit)

	services.submit(pl, service, msg)
end)

net.Receive('services.resolveRequestRequester', function(_, pl)
	local plService = services.getPlayerRequests(pl)
	if not plService or not (#plService > 0) then return end

	plService = plService[1]
	resolved[plService.id] = plService.responder
	services.delete(plService.id)

	services.notify(pl, 'You resolved your request!')

	if plService.responder then
		services.notify(plService.responder, 'The requester has resolved the request, you can now resolve it!')

		net.Start 'services.resolveRequestRequester'
			net.WriteInt(plService.id, 32)
		net.Send(plService.responder)
	end
end)

net.Receive('services.respond', function(_, pl)
	local id = net.ReadInt(32)
	services.respond(pl, id)
end)

net.Receive('services.resolve', function(_, pl)
	local id = pl.curRequest
	services.resolve(pl, id)
end)

net.Receive('services.unclaim', function(_, pl)
	local id = pl.curRequest
	services.unclaim(pl, id)
end)