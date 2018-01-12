-- Override metatable functions
local pmeta = FindMetaTable("Player")
if not pmeta.SteamName then	-- So we don't break DarkRP or f*** ourself
	pmeta.SteamName = pmeta.Nick

	function pmeta:Nick()
		local name = self:GetNWString("ulx_nameoverride", false)
		if name then
			return name
		else
			return self:SteamName()
		end
	end

	pmeta.GetName = pmeta.Nick
	pmeta.Name = pmeta.Nick
end

-- I'm hoping the base gamemode is the only thing that just put the player entity into chat.AddText
-- Overriding it so that the name in chat is actually ply:Nick()

local gm = gamemode.Get("base") -- I should have no business calling this they say
function gm:OnPlayerChat(ply, text, teamChat, dead)
	local tab = {}

	if (dead) then
		table.insert(tab, Color(255, 30, 40))
		table.insert(tab, "*DEAD* ")
	end

	if (teamChat) then
		table.insert(tab, Color(30, 160, 40))
		table.insert(tab, "(TEAM) ")
	end

	if (IsValid(ply)) then
		-- This is where the magic is
		table.insert(tab, team.GetColor(ply:Team()))
		table.insert(tab, ply:Nick())
	else
		table.insert(tab, "Console")
	end

	table.insert(tab, Color(255, 255, 255))
	table.insert(tab, ": " .. text)

	chat.AddText(unpack(tab))

	return true
end

-----------------
-- Screen Grab --
-----------------
local grabID
local parts
local partIndex = 1

net.Receive("screengrab_request", function()
	grabID = net.ReadString()

	local capture = {}
	capture.format = "jpeg"
	capture.h = ScrH()
	capture.w = ScrW()
	capture.quality = 70
	capture.x = 0
	capture.y = 0

	local imageData = util.Base64Encode(render.Capture(capture))

	-- Reset here in-case we never completed.
	parts = {}
	partIndex = 1

	local i = 1
	local partSize = 20000
	while i <= string.len(imageData) do
		local part = string.sub(imageData, i, i + (partSize - 1))
		table.insert(parts, part)
		i = i + partSize
	end

	net.Start("screengrab_response")
	net.WriteString(grabID)
	net.WriteUInt(table.Count(parts), 32)
	net.SendToServer()
end)

net.Receive("screengrab_request_part", function()
	local part = parts[partIndex]

	local size = string.len(part)
	local data = util.Compress(part)

	net.Start("screengrab_response_part")
	net.WriteString(grabID)
	net.WriteUInt(size, 32)
	net.WriteData(data, size)
	net.SendToServer()

	partIndex = partIndex + 1
	if partIndex > table.Count(parts) then
		grabID = nil
		parts = nil
		partIndex = 1
	end
end)

------------------
-- Screen Relay --
------------------
local receivedParts

net.Receive("screengrab_relay_part", function()
	local size = net.ReadUInt(32)
	local part = net.ReadData(size)

	part = util.Decompress(part)

	if not receivedParts then
		receivedParts = {}
	end

	table.insert(receivedParts, part)
end)

net.Receive("screengrab_relay_cancel", function()
	receivedParts = nil
end)

net.Receive("screengrab_relay_complete", function()
	local plyName = net.ReadString()

	local imageData = string.Implode("", receivedParts)
	receivedParts = nil
	
	local window = vgui.Create("DFrame")
	window:SetPos(0,0)
	window:SetSize(640, 480)
	window:SetTitle("Screen capture of player " .. plyName)
	window:SetVisible(true)
	window:SetDraggable(true)
	window:SetSizable(true)
	window:ShowCloseButton(true)
	window:Center()
	window:MakePopup()

	local image = vgui.Create("HTML", window)
	image:Dock(FILL)
	image:SetHTML([[<img height="100%" src="data:image/jpeg;base64, ]] .. imageData .. [["/> ]])


end)
