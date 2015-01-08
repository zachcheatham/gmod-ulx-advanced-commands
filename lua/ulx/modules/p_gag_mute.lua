-------
-- Mute
-------

local function setULXMute(ply, muted)
	if muted then
		ply.gimp = 2
	else
		ply.gimp = nil
	end
	ply:SetNWBool("ulx_muted", muted)
end

function ulx.addPermanentMute(ply)
	setULXMute(ply, true)
	ply:SetPData("ulx_pmuted", true)
end

function ulx.removePermanentMute(ply)
	setULXMute(ply, false)
	ply:RemovePData("ulx_pmuted")
end

function ulx.isPlayerPermanentlyMuted(ply)
	local permanentlyMuted = ply:GetPData("ulx_pmuted", false)
	return permanentlyMuted
end

------
-- Gag
------
local function setULXGag(ply, gagged)
	ply.ulx_gagged = gagged
	ply:SetNWBool("ulx_gagged", gagged)
end

function ulx.addPermanentGag(ply)
	setULXGag(ply, true)
	ply:SetPData("ulx_pgagged", true)
end

function ulx.removePermanentGag(ply)
	setULXGag(ply, false)
	ply:RemovePData("ulx_pgagged")
end

function ulx.isPlayerPermanentlyGagged(ply)
	local permanentlyGagged = ply:GetPData("ulx_pgagged", false)
	return permanentlyGagged
end

--------
-- Hooks
--------

local function playerInitialSpawn(ply)
	if ulx.isPlayerPermanentlyGagged(ply) then
		setULXGag(ply, true)
		ULib.tsayColor(ply, false, Color(255, 140, 39), "You are permanently gagged and will not be able to use your microphone.")
		ZCore.ULX.tsayPlayersWithPermission(ply:Nick() .. " joined permanently gagged.", "ulx pgag")
	end
	
	if ulx.isPlayerPermanentlyMuted(ply) then
		setULXMute(ply, true)
		ULib.tsayColor(ply, false, Color(255, 140, 39), "You are permanently muted and will not be able to chat.")
		ZCore.ULX.tsayPlayersWithPermission(ply:Nick() .. " joined permanently muted.", "ulx pmute")
	end
end
hook.Add("PlayerInitialSpawn", "ULXPermGagMute", playerInitialSpawn)