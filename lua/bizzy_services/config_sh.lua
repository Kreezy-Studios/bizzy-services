services.cfg.cooldown 			= 120 -- how often a player can call for a service (in seconds)
services.cfg.needPlayers 		= true -- wether or not a player needs to be available in the service in order for it to be called
services.cfg.autoRemoveRequest 	= 180 -- after how many seconds is a service automatically deleted (set to 0 for never)
services.cfg.rewardOnResolve 		= true -- should the people responding be rewarded when they resolve this?
services.cfg.rewardAmount 		= 500 -- if rewardOnResolve is true, the player will be rewarded this amount of resolving the service request
services.cfg.messageLengthLimit	= 125 -- limit of the message a player can write in their request

services.cfg.submittedPanelYPos	= 35 -- distance from bottom of screen the little notifications/panels appear on

services.cfg.adminRanks 		= { -- ranks that can use the !servicesban and !servicesunban commands.
	['superadmin'] 			= true,
	['admin'] 				= true,
	['owner'] 				= true
}

services.cfg.banCommand 		= '!servicesban'
services.cfg.unbanCommand 		= '!servicesunban'

services.cfg.menuCommands 		= { -- to add a command, do the following: ['!command'] = true
	requestMenu 			= { -- this is a list of commands that open the request menu.
		['!services']		= true,
		['!request'] 		= true,
		['!servicerequest'] 	= true
	},
	respondMenu 			= {
		['!respond'] 		= true,
		['!servicesrespond'] 	= true
	}
}

services.cfg.translate 			= {
	-- menus
	title 				= 'Select a service to request it!',
	titleDesc 				= 'Make role-playing easier and more realistic!',
	defaultSubmitMessage 		= 'Enter a message to send to the responders.',
	submitText 				= 'Submit Request',
	sideTitle 				= 'Services',

	-- messages
	submittedRequest 			= 'You successfully submitted a service request!',
	cantCallService 			= 'You can\'t call this service!',
	noneOnline 				= 'There are no players available for this service!',
	doesntExist 			= 'This request no longer exists :(',
	alreadyResponded 			= 'Someone has already responded to this request!',
	cantAccess 				= 'You cannot access this request!',
	requesterDisconnect 		= 'The person that made the request is no longer online!',
	serviceResolvedRequester 	= 'Your service request has been resolved!',
	serviceResolvedResponder 	= 'One of the services you responded to was resolved!',
	youAreBanned 			= 'You are banned from using the service system!',
	waitCooldown			= 'Waitout your request cooldown!',
	canReportPlayer 			= 'If your responder doesnt show up, you can report him to the admins!'
}

timer.Simple(0, function() -- ignore this timer, just add the teams before the "end)" line

--
-- It's very easy to add a service.
-- Just follow this mini guide.
-- How to add a service:
--
-- services.addService(name, multiAccept, description, teams)
-- Replace name with the service name (example: Gun Dealer)
-- Replace multiAccept with true/false. true for multiple responses, false for only 1
-- Replace Description with a description of the service. Set to nil or "" to disable description!
-- Replace teams with the list of teams that can respond to the service
--
-- Examples:
--

services.addService('Police', true, 'Call 911 to help the situation you are currently in! It\'s good to describe your situation so the police can know in what way to come help you.', TEAM_POLICE, TEAM_CHIEF, TEAM_MAYOR)
services.addService('Gun Dealer', false, '', TEAM_GUN, TEAM_BMD)

end)

--
-- if you want to change the way a player is rewarded,
-- modify this function to whatever you want
--
-- for pointshop, change this function to this
--
-- function services.rewardPlayer(pl, amount)
--       pl:PS2_AddStandardPoints(amount)
-- end
--
-- if you need any help.explanation just message me/submit a ticket on gmodstore!
--

function services.rewardPlayer(pl, amount)
	pl:addMoney(amount)
end