-- client code is a little sloppy sry

if not services.cfg.theme then
	include 'themes_cl.lua'
end

local color_blue 		= Color(40, 40, 255, 255)
local color_black 	= Color(0, 0, 0, 255)
local surface		= surface
local cfg 			= services.cfg

local curPl 		= nil
local IsValid 		= IsValid

local draw_SimpleText	= draw.SimpleText

local theme = services.cfg.theme
local clrs = theme.colors

local selected, curData = 1, {}
local ui 			= {}
local resolved 		= {}
local curRequest 		= {}

local closeMat 		= Material('services/close.png', 'noclamp smooth')
local settingsMat 	= Material('services/settings.png', 'noclamp smooth')

local blur 		= Material 'pp/blurscreen'

function services.blurPanel(pnl)
	local x, y = pnl:LocalToScreen(0, 0)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(blur)
	for i = 1, 6 do
		blur:SetFloat('$blur', (i / 3) * 6)
		blur:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
	end
end

local function createFont(size, weight)
	surface.CreateFont('services_font_' .. size, {
		font = 'Arial',
		size = size,
		weight = (weight or 500)
	})
end

createFont(20, 750)
createFont(22, 750)
createFont(25)
createFont(45, 1000)
createFont(24, 300)
createFont(21)
createFont(18)
createFont(30, 1000)

function services.box(x, y, w, h, clr)
	surface.SetDrawColor((clr or clrs.background))
	surface.DrawRect(x, y, w, h)
end

function services.text(txt, size, x, y, clr, alignX, alignY)
	draw_SimpleText(txt, 'services_font_' .. size, x, y, (clr or clrs.textColor), alignX, alignY)
end

local function updateData(num)
	selected = num
	curData = services.allServices[num]

	if ui.bg and IsValid(ui.bg) then
		ui.desc:SetText((curData.desc ~= nil and curData.desc ~= '' and curData.desc or 'No description!'))
	end
end

function services.requestMenu()
	if ui.bg and IsValid(ui.bg) then
		ui.bg:Remove()
	end

	selected = 1

	local w, h = ScrW() * .9, ScrH() * .9
	local sideSize = w * .15
	local sideButtonHeight = 45

	local buttons = {}

	ui.bg = vgui.Create 'services_frame'
		ui.bg:SetSize(w, h)
		ui.bg:AddClose()
		ui.bg:Center()
		ui.bg.title = cfg.translate.title
		ui.bg.titleDesc = cfg.translate.titleDesc
		ui.bg.sideTitle = cfg.translate.sideTitle
		ui.bg.leftTopSize = sideSize

	ui.servicePanel = ui.bg:Add 'services_panel'
		ui.servicePanel:SetSize(sideSize, h - ui.bg.topSize - 15)
		ui.servicePanel:SetPos(5, ui.bg.topSize + 10)
		ui.servicePanel.panelColor = clrs.sidePanel
		ui.servicePanel.outline = false

	ui.serviceList = ui.servicePanel:Add 'DScrollPanel'
		ui.serviceList:SetSize(sideSize - 10, ui.servicePanel:GetTall() - 10)
		ui.serviceList:SetPos(5, 5)
		ui.serviceList:GetVBar():SetWide(0)

	local curY = 0

	for id, data in ipairs(services.allServices) do
		local btn = ui.serviceList:Add 'services_button'
			btn:SetSize(ui.serviceList:GetWide(), sideButtonHeight)
			btn:SetPos(0, curY)
			btn.text = data.name
			btn.isSelected = (id == 1)

		table.insert(buttons, btn)

		function btn:DoClick()
			updateData(id)

			for _, bt in ipairs(buttons) do
				bt.isSelected = false
			end

			self.isSelected = true

			if ui.playerList then
				ui.playerList:ShowPlayers(id)
			end
		end

		ui.serviceList:AddItem(btn)
		curY = curY + sideButtonHeight + 5
	end

	ui.dataBG = ui.bg:Add 'services_panel'
		ui.dataBG:SetSize(w - sideSize - 15, h - ui.bg.topSize - 15)
		ui.dataBG:SetPos(10 + sideSize, ui.bg.topSize + 10)
		ui.dataBG.panelColor = clrs.foreground
		ui.dataBG.outline = false

	local leftData = {
		w = ui.dataBG:GetWide() * .65 - 10,
		h = ui.dataBG:GetTall() * .65 - 10
	}

	ui.leftData = ui.dataBG:Add 'services_panel'
		ui.leftData:SetSize(leftData.w, leftData.h)
		ui.leftData:SetPos(5, 5)
		ui.leftData.outline = false

	function ui.leftData:PaintOver(w, h)
		services.box(5, 5, w - 10, 45, clrs.dataPanels)

		services.box(5, 5, theme.sideThingSize, 45, clrs.buttonHover)

		services.text(services.allServices[selected].name, 45, 5 + theme.sideThingSize + 3, 5 + (45 / 2), clrs.textColor, 0, 1)

		services.box(5, 5 + 45 + 5, w - 10, h - 60, clrs.dataPanels)
		services.box(5, 5 + 45 + 5, theme.sideThingSize, h - 60, clrs.buttonHover)

		if theme.doOutline then
			surface.SetDrawColor(color_white)
			surface.DrawOutlinedRect(5, 5, w - 10, 45)
			surface.DrawOutlinedRect(5, 5 + 45 + 5, w - 10, h - 60)
		end
	end

	ui.desc = ui.leftData:Add 'DLabel'
		ui.desc:SetSize(leftData.w - 10 - theme.sideThingSize, leftData.h - 60)
		ui.desc:SetPos(5 + theme.sideThingSize + 5, 55)
		ui.desc:SetAutoStretchVertical(true)
		ui.desc:SetText((services.allServices[1].desc ~= nil and services.allServices[1].desc ~= '' and services.allServices[1].desc or 'No description'))
		ui.desc:SetFont 'services_font_24'
		ui.desc:SetWrap(true)
		ui.desc:SetTextColor(color_white)

	ui.submitData = ui.dataBG:Add 'services_panel'
		ui.submitData:SetSize(leftData.w, ui.dataBG:GetTall() - leftData.h - 15)
		ui.submitData:SetPos(5, ui.dataBG:GetTall() - ui.submitData:GetTall() - 5)
		ui.submitData.outline = false

	ui.submitMessage = ui.submitData:Add 'DTextEntry'
		ui.submitMessage:SetSize(leftData.w - 10, ui.submitData:GetTall() - 50)
		ui.submitMessage:SetPos(5, 5)
		ui.submitMessage:SetText(cfg.translate.defaultSubmitMessage)
		ui.submitMessage:SetFont 'services_font_20'
		ui.submitMessage:SetWrap(true)
		ui.submitMessage:SetMultiline(true)
		ui.submitMessage:SetEnterAllowed(false)
		ui.submitMessage.outline = true

	function ui.submitMessage:Paint(w, h)
		if theme.doOutline then
			surface.SetDrawColor(color_white)
			surface.DrawOutlinedRect(0, 0, w, h)
		end

		services.box(0, 0, w, h, clrs.dataPanels)
		self:DrawTextEntryText(color_white, Color(100, 100, 100, 100), color_white)
	end

	ui.submit = ui.submitData:Add 'services_button'
		ui.submit:SetSize(leftData.w - 10, 35)
		ui.submit:SetPos(5, ui.submitData:GetTall() - 40)
		ui.submit.text = cfg.translate.submitText

	function ui.submit:DoClick()
		net.Start 'services.newRequest'
			net.WriteInt(selected, 16)
			net.WriteString(ui.submitMessage:GetValue():sub(1, 150))
		net.SendToServer()

		ui.bg:SizeTo(0, 0, .3, nil, nil, function()
			ui.bg:Remove()
		end)
	end

	ui.playersBG = ui.dataBG:Add 'services_panel'
		ui.playersBG:SetSize(ui.dataBG:GetWide() - leftData.w - 13, ui.dataBG:GetTall() - 10)
		ui.playersBG:SetPos(ui.dataBG:GetWide() - ui.playersBG:GetWide() - 5, 5)
		ui.playersBG.outline = false

	function ui.playersBG:PaintOver(w, h)
		services.text('Available players:', 22, w / 2, 5, color_white, 1, 0)
	end

	ui.playerList = ui.playersBG:Add 'DScrollPanel'
		ui.playerList:SetSize(ui.playersBG:GetWide() - 10, ui.playersBG:GetTall() - 37)
		ui.playerList:SetPos(5, 27)
		ui.playerList:GetVBar():SetWide(0)

	function ui.playerList:ShowPlayers(id)
		self:Clear()
		local curY = 0

		for _, pl in ipairs(services.getServicePlayers(id)) do
			local cl = team.GetColor(pl:Team())
			local pnl = ui.playerList:Add 'services_panel'
				pnl:SetSize(ui.playerList:GetWide(), 50)
				pnl:SetPos(0, curY)
				pnl.panelColor = Color(cl.r, cl.g, cl.b, 50)

			function pnl:PaintOver(w, h)
				if not IsValid(pl) then return end

				services.text('Name: ' .. pl:Name(), 20, 53, 3, clrs.textColor)
				services.text('Job: ' .. team.GetName(pl:Team()), 20, 53, 3 + 20, clrs.textColor)
			end

			pnl.avatar = pnl:Add 'AvatarImage'
				pnl.avatar:SetPos(1, 1)
				pnl.avatar:SetSize(48, 48)
				pnl.avatar:SetPlayer(pl)

			ui.playerList:AddItem(pnl)
			curY = curY + 55
		end
	end

	ui.playerList:ShowPlayers(1)
end

-- plz no remove i ned credit 2 feel gud about muhself xd!

timer.Create('lmaoservicecreditsxd', 10 * 60, 0, function()
	chat.AddText(Color(25, 25, 255), '[SERVICES] ', color_white, ' This server is running Bizzy\'s Service System!')

	print()
	MsgC(Color(25, 25, 255), 'This server is running Bizzy\'s Service System! (Free version) \n')
	MsgC(Color(25, 25, 255), 'Github link: \n')
	MsgC(Color(25, 25, 255), 'Author link: http://steamcommunity.com/profiles/76561198273273963/ \n')
	print()
end)

local reui = {}

local curResBG
local newReqBG
local curReqBG

function services.respondMenu()
	if newReqBG and IsValid(newReqBG) then newReqBG:Remove() end
	if curReqBG and IsValid(curReqBG) then LocalPlayer():ChatPrint 'Resolve your current request!' return end
	if curResBG and IsValid(curResBG) then curResBG:Remove() end

	if reui.bg and IsValid(reui.bg) then reui.bg:Remove() end

	if not services.curRequests or table.Count(services.curRequests) <= 0 then
		LocalPlayer():ChatPrint 'No services to claim!'
		return
	end

	local w, h = ScrW() * .6, ScrH() * .9

	reui.bg = vgui.Create 'services_frame'
		reui.bg:SetSize(w, h)
		reui.bg:Center()
		reui.bg:AddClose()
		reui.bg.title = 'Bizzy\'s Services - Respond Menu'
		reui.bg.titleDesc = 'Select a request to respond to!'
		reui.bg.sideTitle = 'Requests'

	reui.list = reui.bg:Add 'DScrollPanel'
		reui.list:SetSize(w - 10, h - reui.bg.topSize - 15)
		reui.list:SetPos(5, reui.bg.topSize + 10)
		reui.list:GetVBar():SetWide(0)

	local curY = 0
	local pnlH = 70

	for _, data in pairs(services.curRequests) do
		if not IsValid(data.submitter) then continue end

		local pl = data.submitter

		local cl = team.GetColor(pl:Team())
		local pnl = reui.list:Add 'services_panel'
			pnl:SetSize(reui.list:GetWide(), pnlH)
			pnl:SetPos(0, curY)
			pnl.panelColor = Color(cl.r, cl.g, cl.b, 10)

		function pnl:PaintOver(w, h)
			if not IsValid(pl) then return end

			services.text('Name: ' .. (IsValid(pl) and pl:Name() or 'DISCONNECTED'), 22, pnlH + 6, 6)
			services.text('Job: ' .. (IsValid(pl) and team.GetName(pl:Team()) or 'DISCONNECTED'), 22, pnlH + 6, 26)
			services.text('Submit date: ' .. (data.submitDate or 'Unknown'), 22, pnlH + 6, 26 + 20)
		end

		pnl.avatar = pnl:Add 'AvatarImage'
			pnl.avatar:SetPos(1, 1)
			pnl.avatar:SetSize(pnlH - 2, pnlH - 2)
			pnl.avatar:SetPlayer(pl)

		pnl.respond = pnl:Add 'services_button'
			pnl.respond:SetSize(pnl:GetWide() * .25, pnlH - 10 - 2)
			pnl.respond:SetPos(pnl:GetWide() - 6 - pnl.respond:GetWide(), 6)
			pnl.respond.text = 'Respond'
			pnl.respond.netMsg = 'services.respond'

		local changed = false

		function pnl:Think()
			if data.responder and (type(data.responder) ~= 'table' and IsValid(data.responder) and data.responder == LocalPlayer() or table.HasValue(data.responder, LocalPlayer())) then
				pnl.respond.text = (resolved[id] and 'Resolve' or 'Unclaim')	
				pnl.respond.netMsg = (resolved[id] and 'services.resolve' or 'services.unclaim')
				changed = true
			end
		end

		function pnl.respond:DoClick()
			net.Start(self.netMsg)
				if not changed then
					net.WriteInt(data.id, 32)
				end
			net.SendToServer()
		end

		curY = curY + pnlH + 5
	end
end

net.Receive('services.requestMenu', services.requestMenu)
net.Receive('services.respondMenu', services.respondMenu)

net.Receive('services.displayRequest', function()
	if curReqBG and IsValid(curReqBG) then curReqBG:Remove() end

	local w, h = 350, 70

	curReqBG = vgui.Create 'DFrame'
		curReqBG:SetSize(w, h)
		curReqBG:SetPos(ScrW() / 2 - (w / 2), ScrH() - cfg.submittedPanelYPos - h)
		curReqBG:SetTitle ''
		curReqBG:ShowCloseButton(false)
		curReqBG:SetDraggable(true)
		curReqBG.endTime = CurTime() + (cfg.autoRemoveRequest ~= 0 and cfg.autoRemoveRequest or 180)

	function curReqBG:Paint(w, h)
		services.box(0, 0, w, h, clrs.miniPanelsBG)
		services.box(2, 2, w - 4, 22, clrs.topBar)
		services.text('Current service request', 20, w / 2, 3, clrs.textColor, 1)
	end

	function curReqBG:Think()
		if self.endTime < CurTime() then
			self:Remove()
		end
	end

	curReqBG.resolve = curReqBG:Add 'services_button'
		curReqBG.resolve:SetSize(w - 10, 35)
		curReqBG.resolve:SetPos(5, h - 40)
		curReqBG.resolve.text = 'Resolve'

	function curReqBG.resolve:DoClick()
		net.Start 'services.resolveRequestRequester'
		net.SendToServer()

		curReqBG:Remove()
	end
end)

net.Receive('services.notify', function()
	local msg = net.ReadTable()
	chat.AddText(color_blue, '[SERVICES] ', color_white, unpack(msg))
end)

net.Receive('services.initRequests', function()
	services.curRequests = net.ReadTable()
end)

net.Receive('services.newRequest', function()
	local data = net.ReadTable()
	data.submitDate = os.date()
	table.insert(services.curRequests, data)

	if newReqBG and IsValid(newReqBG) then newReqBG:Remove() end
	if curReqBG and IsValid(curReqBG) then return end

	local w, h = 350, 110

	newReqBG = vgui.Create 'DFrame'
		newReqBG:SetSize(w, h)
		newReqBG:SetPos(ScrW() / 2 - (w / 2), ScrH() - cfg.submittedPanelYPos - h)
		newReqBG:SetTitle ''
		newReqBG:ShowCloseButton(false)
		newReqBG:SetDraggable(true)
		newReqBG.endTime = CurTime() + 15

	function newReqBG:Paint(w, h)
		services.box(0, 0, w, h, clrs.miniPanelsBG)
		services.box(2, 2, w - 4, 22, clrs.topBar)
		services.text('New service request!', 20, w / 2, 3, clrs.textColor, 1)
		services.text('Service: ' .. services.allServices[data.service].name, 20, 5, 22, clrs.textColor)
		services.text('Submitter: ' .. (IsValid(data.submitter) and data.submitter:Name() or 'DISCONNECTED'), 20, 5, 37, clrs.textColor)
		services.text('Message: ' .. data.msg:sub(1, 30) .. '...', 20, 5, 52, clrs.textColor)
	end

	function newReqBG:Think()
		if self.endTime < CurTime() then
			self:Remove()
		end
	end

	newReqBG.resolve = newReqBG:Add 'services_button'
		newReqBG.resolve:SetSize(w - 10, 35)
		newReqBG.resolve:SetPos(5, h - 40)
		newReqBG.resolve.text = 'Respond'

	function newReqBG.resolve:DoClick()
		net.Start 'services.respond'
			net.WriteInt(data.id, 32)
		net.SendToServer()

		newReqBG:Remove()
	end
end)

net.Receive('services.respond', function()
	local data = net.ReadTable()
	local curClaim = data.id

	if curResBG and IsValid(curResBG) then curResBG:Remove() end

	local w, h = 350, 110

	local pl = data.submitter
	if not IsValid(pl) then return end

	curRequest = data

	curResBG = vgui.Create 'DFrame'
		curResBG:SetSize(w, h)
		curResBG:SetPos(ScrW() / 2 - (w / 2), ScrH() - cfg.submittedPanelYPos - h)
		curResBG:SetTitle ''
		curResBG:ShowCloseButton(false)
		curResBG:SetDraggable(true)

	function curResBG:Paint(w, h)
		services.box(0, 0, w, h, clrs.miniPanelsBG)
		services.box(2, 2, w - 4, 22, clrs.topBar)
		services.text('Current service request!', 20, w / 2, 3, clrs.textColor, 1)
		services.text('Service: ' .. services.allServices[data.service].name, 20, 5, 22, clrs.textColor)
		services.text('Submitter: ' .. (IsValid(data.submitter) and data.submitter:Name() or 'DISCONNECTED'), 20, 5, 37, clrs.textColor)
		services.text('Message: ' .. data.msg:sub(1, 30) .. '...', 20, 5, 52, clrs.textColor)
	end

	curResBG.resolve = curResBG:Add 'services_button'
		curResBG.resolve:SetSize(w - 10, 35)
		curResBG.resolve:SetPos(5, h - 40)
		curResBG.resolve.text = 'Unclaim'
		curResBG.netMsg = 'services.unclaim'

	function curResBG:Think()
		if resolved[curClaim] and not self.isResolved then
			self.resolve.text = 'Resolve'
			self.netMsg = 'services.resolve'
			self.isResolved = true
		end
	end

	function curResBG.resolve:DoClick()
		net.Start(self:GetParent().netMsg)
		net.SendToServer()

		curResBG:Remove()
	end
end)

net.Receive('services.resolveRequestRequester', function()
	local id = net.ReadInt(32)
	resolved[id] = true
end)

net.Receive('services.updateRequest', function()
	local requestData = net.ReadTable()
	local index = services.getRequestIndex(requestData.id)

	if index then
		services.curRequests[index] = requestData
	end
end)

net.Receive('services.deleteRequest', function()
	local id = net.ReadInt(32)
	local index = services.getRequestIndex(id)

	if index then
		services.curRequests[index] = nil
	end
end)

hook.Add('HUDPaint', 'services.drawRequesterXDLmaoRawr!', function()
	if curRequest and curRequest ~= nil and services.getRequestIndex(curRequest.id) then
		local pl = curRequest.submitter
		if not pl or not IsValid(pl) then curRequest = {} return end

		local pos = pl:GetPos():ToScreen()
		local msg = curRequest.msg
		local service = curRequest.service

		services.text('Service requester!', 20, pos.x + 25, pos.y - 25, nil, 1)
		services.text('Name: ' .. pl:Name(), 20, pos.x + 25, pos.y - 5, nil, 1)
		services.text('Message: ' .. msg, 20, pos.x + 25, pos.y + 15, nil, 1)
	else
		curRequest = {}
	end
end)