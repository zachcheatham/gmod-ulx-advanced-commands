util.AddNetworkString("screengrab_request")
util.AddNetworkString("screengrab_response")
util.AddNetworkString("screengrab_request_part")
util.AddNetworkString("screengrab_response_part")
util.AddNetworkString("screengrab_relay_part")
util.AddNetworkString("screengrab_relay_complete")
util.AddNetworkString("screengrab_relay_cancel")

ulx.pendingGrab = false
local completedParts = 0
local totalParts = 0

function ulx.requestScreenGrab(callingPly, ply)
	local grabID = ply:SteamID() .. "-" .. os.time()

	net.Start("screengrab_request")
	net.WriteString(grabID)
	net.Send(ply)

	ulx.pendingGrab = {}
	ulx.pendingGrab.id = grabID
	ulx.pendingGrab.callingPly = callingPly
	ulx.pendingGrab.ply = ply
	ulx.pendingGrab.plyName = ply:Nick()

	timer.Create("screengrab_timeout", 120, 1, function()
		if ulx.pendingGrab then
			net.Start("screengrab_relay_cancel")
			net.Send(ulx.pendingGrab.callingPly)

			ULib.tsayError(ulx.pendingGrab.callingPly, "It seems that " .. ulx.pendingGrab.plyName .. " isn't responding to the screen grab request in time. It has been cancelled.")

			ulx.pendingGrab = false
			completedParts = 0
			totalParts = 0
		end
	end)
end

local function requestNextPart()
	net.Start("screengrab_request_part")
	net.Send(ulx.pendingGrab.ply)
end

local function receivedAllParts()
	timer.Destroy("screengrab_timeout")

	if IsValid(ulx.pendingGrab.callingPly) then
		ULib.tsay(ulx.pendingGrab.callingPly, "Finished screen grab of " .. ulx.pendingGrab.plyName)
	end

	net.Start("screengrab_relay_complete")
	net.WriteString(ulx.pendingGrab.plyName)
	net.Send(ulx.pendingGrab.callingPly)

	ulx.pendingGrab = false
	completedParts = 0
	totalParts = 0
end

net.Receive("screengrab_response", function(len, ply)
	local grabID = net.ReadString()
	local parts = net.ReadUInt(32)

	-- We received a grab for an ID we were not expecting
	-- This could mean either I f***ed up or they've broken our system
	if not ulx.pendingGrab or ulx.pendingGrab.id ~= grabID then
		ZCore.ULX.tsayColorPlayersWithPermission("ulx screengrab", false, Color(255, 140, 39), "Warning: Received invalid screen grab response from " .. ply:Nick())
		return
	end

	totalParts = parts
	requestNextPart()
end)

net.Receive("screengrab_response_part", function(len, ply)
	local grabID = net.ReadString()
	local size = net.ReadUInt(32)
	local data = net.ReadData(size)

	-- We received a grab for an ID we were not expecting
	-- This could mean either I f***ed up or they've broken our system
	if not ulx.pendingGrab or ulx.pendingGrab.id ~= grabID then
		ZCore.ULX.tsayColorPlayersWithPermission("ulx screengrab", false, Color(255, 140, 39), "Warning: Received invalid screen grab response from " .. ply:Nick())
		return
	end

	net.Start("screengrab_relay_part")
	net.WriteUInt(size, 32)
	net.WriteData(data, size)
	net.Send(ulx.pendingGrab.callingPly)

	completedParts = completedParts + 1

	if IsValid(ulx.pendingGrab.callingPly) then
		ULib.tsay(ulx.pendingGrab.callingPly, "Retrieving screen grab of " .. ply:Nick() .. " (" .. math.floor((completedParts / totalParts) * 100) .. "%)" )
	end

	if completedParts >= totalParts then
		receivedAllParts()
	else
		requestNextPart()
	end
end)
