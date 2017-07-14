if not services.cfg.theme then
	include 'themes_cl.lua'
end

local theme = services.cfg.theme
local clrs = theme.colors

local PANEL = {}

function PANEL:Init()
	theme = services.cfg.theme
	clrs = theme.colors

	self:ShowCloseButton(false)
	self:SetTitle ''
	self:SetDraggable(false)

	self.title = ''
	self.titleDesc = ''
	self.sideTitle = ''
	self.topSize = 50
	self.leftTopSize = 150
end

function PANEL:AddClose()
	local w = self:GetWide()

	self.close = self:Add 'DButton'
		self.close:SetSize(50, 50)
		self.close:SetPos(w - 55, 5)
		self.close:SetText ''

	function self.close:DoClick()
		self:GetParent():SizeTo(0, 0, .3, nil, nil, function()
			self:GetParent():Remove()
		end)
	end

	function self.close:Paint(w, h)
		services.text('X', 30, w / 2, h / 2, color_white, 1, 1)
	end
end

function PANEL:PerformLayout()
	if not self.noPopup then
		self:MakePopup()
	end
end

function PANEL:Paint(w, h)
	if theme.hasBlur then
		services.blurPanel(self)
	end

	services.box(0, 0, w, h, clrs.background)
	services.box(5, 5, self.leftTopSize, self.topSize, clrs.leftTop)
	services.box(5 + self.leftTopSize + 5, 5, w - self.leftTopSize - 15, self.topSize, clrs.topBar)

	services.text(self.sideTitle, 30, 5 + self.leftTopSize / 2, 5 + (self.topSize / 2), clrs.titleTextColor, 1, 1)
	services.text(self.title, 30, 5 + self.leftTopSize + 10, 5 + (self.topSize / 2) - 10, clrs.titleTextColor, 0, 1)
	services.text(self.titleDesc, 24, 5 + self.leftTopSize + 10, 5 + (self.topSize / 2) + 10, clrs.titleTextColor, 0, 1)
end

vgui.Register('services_frame', PANEL, 'DFrame')

PANEL = {}

function PANEL:Init()
	self.panelColor = clrs.dataPanelsBG
	self.outline = true
end

function PANEL:Paint(w, h)
	services.box(0, 0, w, h, self.panelColor)

	if theme.doOutline and self.outline then
		surface.SetDrawColor(color_white)
		surface.DrawOutlinedRect(0, 0, w, h)
	end
end

vgui.Register('services_panel', PANEL, 'DPanel')

PANEL = {}

function PANEL:Init()
	self:SetText ''

	self.text = ''
	self.btnColor = clrs.buttons
	self.lerpHover = 0
	self.isSelected = false
	self.textSize = 20
end

function PANEL:Paint(w, h)
	services.box(0, 0, w, h, self.btnColor)

	if theme.doOutline then
		surface.SetDrawColor(color_white)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	if self:IsHovered() or self.isSelected then
		self.lerpHover = Lerp(.075, self.lerpHover, w - 1)
	else
		self.lerpHover = Lerp(.075, self.lerpHover, theme.sideThingSize)
	end

	services.box(1, 1, self.lerpHover, h - 2, clrs.buttonHover)
	services.text(self.text, self.textSize, w / 2, h / 2, clrs.buttonTextColor, 1, 1)
end

vgui.Register('services_button', PANEL, 'DButton')