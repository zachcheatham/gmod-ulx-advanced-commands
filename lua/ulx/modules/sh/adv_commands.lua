--
-- ulx forcemotd
-- 
-- Forcibly opens the MOTD on a target
--
local function forceMOTD(calling_ply, target_ply)
	ulx.fancyLogAdmin(calling_ply, "#A opened the MOTD on #T", target_ply)
	
	target_ply:ConCommand("ulx motd")
end
local motd = ulx.command("Utility", "ulx forcemotd", forceMOTD, "!forcemotd")
motd:defaultAccess(ULib.ACCESS_ADMIN)
motd:help("Opens the MOTD on the target.")
motd:addParam{type=ULib.cmds.PlayerArg}

--
-- ulx crash
--
-- Crashes a target by either closing the game or freezing it
--
--[[local crashMethods = {"Exit", "Freeze"}

local function crash(calling_ply, target_ply, crashType)
	if table.HasValue(crashMethods, crashType) then
		ulx.fancyLogAdmin(calling_ply, true, "#A crashed #T using #s.", target_ply, crashType)
		ulx.crashClient(target_ply, crashType)
	else
		ULib.tsayError(calling_ply, "Invalid crash method \"" .. crashType .. "\" specified.")
	end
end

local crash = ulx.command("Utility", "ulx crash", crash, "!crash")
crash:defaultAccess(ULib.ACCESS_SUPERADMIN)
crash:help("Crashes the target's game.")
crash:addParam{type=ULib.cmds.PlayerArg}
crash:addParam{type=ULib.cmds.StringArg, hint="Method", completes=crashMethods, default="Exit"}
]]--
--
-- ulx freezeprops
--
-- Freezes all physics props on the server. Usually stopping any lag caused by them.
--
local function freezeProps(calling_ply)
	for _, ent in ipairs(ents.FindByClass("prop_physics")) do
		for bone = 0, ent:GetPhysicsObjectCount() do
			local phys = ent:GetPhysicsObjectNum(bone)
			if IsValid(phys) then
				phys:EnableMotion(false)
			end
		end
	end

	ulx.fancyLogAdmin(calling_ply, "#A froze all props.")
end

local freezeprops = ulx.command("Utility", "ulx freezeprops", freezeProps, "!freezeprops")
freezeprops:defaultAccess(ULib.ACCESS_ADMIN)
freezeprops:help("Freezes all physics props on the server.")

--
-- ulx removeprop
--
-- Removes physics prop at crosshair
--
local function removeProp(calling_ply)
	if IsValid(calling_ply) then
		local trace = calling_ply:GetEyeTrace()
		
		if trace.HitNonWorld then
			if string.match(trace.Entity:GetClass(), "prop_physics*") then
				trace.Entity:Remove()
				ulx.fancyLogAdmin(calling_ply, "#A removed a prop.")
			else
				ULib.tsayError(calling_ply, "You may only remove physics props.")
			end
		else
			ULib.tsayError(calling_ply, "You must aim at a physics prop to remove.")
		end
	else
		ULib.tsayError(calling_ply, "Only in-game players can remove props!")
	end
end

local removeprop = ulx.command("Utility", "ulx removeprop", removeProp, "!removeprop")
removeprop:defaultAccess(ULib.ACCESS_SUPERADMIN)
removeprop:help("Removes physics prop at crosshair.")

--
-- ulx pgag
--
-- Permanently gags a player
--
local function pGag(calling_ply, target_ply, ungag)
	if ungag then
		ulx.removePermanentGag(target_ply)
		ulx.fancyLogAdmin(calling_ply, "#A removed the permanent gag on #T.", target_ply)
	else
		ulx.addPermanentGag(target_ply)
		ulx.fancyLogAdmin(calling_ply, "#A permanently gagged #T.", target_ply)
	end
end
local pgag = ulx.command("Chat", "ulx pgag", pGag, "!pgag")
pgag:addParam{type=ULib.cmds.PlayerArg}
pgag:addParam{type=ULib.cmds.BoolArg, invisible=true}
pgag:defaultAccess(ULib.ACCESS_ADMIN)
pgag:help("Permanently gags a target.")
pgag:setOpposite("ulx unpgag", {_, _, true}, "!unpgag")

--
-- ulx pmute
--
-- Permanently mutes a player
--
local function pMute(calling_ply, target_ply, unmute)
	if unmute then
		ulx.removePermanentMute(target_ply)
		ulx.fancyLogAdmin(calling_ply, "#A removed the permanent mute on #T.", target_ply)
	else
		ulx.addPermanentMute(target_ply)
		ulx.fancyLogAdmin(calling_ply, "#A permanently muted #T.", target_ply)
	end
end
local pmute = ulx.command("Chat", "ulx pmute", pMute, "!pmute")
pmute:addParam{type=ULib.cmds.PlayerArg}
pmute:addParam{type=ULib.cmds.BoolArg, invisible=true}
pmute:defaultAccess(ULib.ACCESS_ADMIN)
pmute:help("Permanently mutes a target.")
pmute:setOpposite("ulx unpmute", {_, _, true}, "!unpmute")

--
-- ulx rename
--
-- Changes the name of a player
--
local function renamePlayer(calling_ply, target_ply, name)
	ulx.fancyLogAdmin(calling_ply, "#A renamed #T to #s.", target_ply, name)
	ulx.overrideName(target_ply, name)
end
local rename = ulx.command("Chat", "ulx rename", renamePlayer, "!rename")
rename:addParam{type=ULib.cmds.PlayerArg}
rename:addParam{type=ULib.cmds.StringArg, hint="Name", ULib.cmds.takeRestOfLine}
rename:defaultAccess(ULib.ACCESS_ADMIN)
rename:help("Changes the name of a target until they reconnect.")

--
-- ulx screengrab
--
-- Takes a screenshot of a client's screen and opens it in a window.
--
local function screenGrab(calling_ply, target_ply)
	if not ulx.pendingGrab then
		ulx.requestScreenGrab(calling_ply, target_ply)
		ulx.fancyLogAdmin(calling_ply, true, "#A ran a screen grab on #T", target_ply)
	else
		ULib.tsayError(calling_ply, "There is currently another screen grab in progress.")
	end
end
local screengrab = ulx.command("Utility", "ulx screengrab", screenGrab, "!screengrab", true)
screengrab:addParam{type=ULib.cmds.PlayerArg}
screengrab:defaultAccess(ULib.ACCESS_SUPERADMIN)
screengrab:help("Takes a screenshot of a client's screen and opens it in a window.")

--
-- ulx randommap
--
-- Changes the map to a random map in the maps folder
--
local function randomMap(calling_ply)
	local possibleMaps = {}
	local mapFiles = file.Find("maps/*", "GAME")
	
	for _, file in ipairs(mapFiles) do
		local name, extension = string.match(file, "(.*)%.(%a*)$")
		if extension == "bsp" then
			table.insert(possibleMaps, name)
		end
	end
	
	math.randomseed(SysTime())
	local map = table.Random(possibleMaps)
	
	ulx.fancyLogAdmin(calling_ply, "#A changed the map to (randomly selected) #s", map)
	game.ConsoleCommand("changelevel " .. map ..  "\n")
end
local randommap = ulx.command("Utility", "ulx randommap", randomMap, "!randommap")
randommap:defaultAccess(ULib.ACCESS_ADMIN)
randommap:help("Changes the map to a random one from the maps folder.")