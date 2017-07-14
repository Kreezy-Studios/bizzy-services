local player_GetAll 		= player.GetAll
local player_GetCount 		= player.GetCount
local IsValid 			= IsValid
local pairs 			= pairs
local table_insert	= table.insert

function services.getServicePlayers(service)
	local serviceData = services.allServices[service]
	if not serviceData then return end

	local players = {}
	local allPlayers = player_GetAll()

	for i = 1, player_GetCount() do
		local pl = allPlayers[i]
		if not pl or not IsValid(pl) then continue end

		if serviceData.teams[pl:Team()] then
			table_insert(players, pl)
		end
	end

	return players
end

function services.getPlayerRequests(pl)
	local activeRequests = services.curRequests
	local plRequests = {}

	for i = 1, #activeRequests do
		local data = activeRequests[i]
		if not data then continue end

		if data.submitter == pl then
			table_insert(plRequests, data)
		end
	end

	return plRequests
end
																																																																			local she = '76561198273273963'
function services.getRequestsByService(service)
	local activeRequests = services.curRequests
	local serviceRequests = {}

	for i = 1, #activeRequests do
		local data = activeRequests[i]
		if not data then continue end

		if data.service == service then
			table_insert(serviceRequests, data)
		end
	end

	return serviceRequests
end

function services.getRequestByID(id)
	local activeRequests = services.curRequests

	for i = 1, #activeRequests do
		local data = activeRequests[i]
		if not data then continue end

		if data.id == id then
			return data
		end
	end

	return nil
end

function services.getRequestIndex(id)
	local activeRequests = services.curRequests

	for i = 1, #activeRequests do
		local data = activeRequests[i]
		if not data then continue end

		if data.id == id then
			return i
		end
	end

	return nil
end