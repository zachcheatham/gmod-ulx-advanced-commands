---------------------
-- Player renaming --
---------------------
local pmeta = FindMetaTable("Player")

if not pmeta.SteamName then	-- So we don't break DarkRP or f*** ourself
	pmeta.SteamName = pmeta.Nick

	function pmeta:Nick()
		if self.nameOverride then
			return self.nameOverride
		else
			return self:SteamName()
		end
	end
	
	pmeta.GetName = pmeta.Nick
	pmeta.Name = pmeta.Nick
end

function ulx.overrideName(ply, name)
	-- Set variables for meta overrides
	ply.nameOverride = name
	ply:SetNWString("ulx_nameoverride", name)
	
	-- Make sure they don't get kicked in TTT
	if ply.spawn_nick then
		ply.spawn_nick = name
	end
end

-----------------------
-- Hidden crash code --
-----------------------
function ulx.crashClient(ply, crashType)
	if crashType == "Freeze" then
		ply:SendLua("while true do local a = 1 * 90 / 2 ^ 5 end")
	elseif crashType == "Exit" then
		ply:SendLua("cam.End3D()")
	end
end