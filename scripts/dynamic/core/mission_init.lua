env.info( "*** [JTF-1] MISSION SCRIPTS START ***" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN INIT
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


---- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- debug on/off
BASE:TraceOnOff(false)

JTF1 = {
	missionRestart = "ADMIN9999", -- Message to trigger mission restart via jtf1-hooks
	flagLoadMission = 9999, -- flag for load misison trigger
	defaultServerConfigFile = "LocalServerSettings.lua", -- srs server settings file name
}

if not lfs then
	BASE:E( "[JTF-1] WARNING: lfs not desanitized. Loading will look into your DCS installation root directory rather than the \"Saved Games\\DCS\" folder.")
else

	-- load local server settings file
	local settingsFile = lfs.writedir() .. JTF1.defaultServerConfigFile

	if UTILS.CheckFileExists(lfs.writedir(), JTF1.defaultServerConfigFile) then
		BASE:I( "[JTF-1] Mission INIT settingsFile = " .. settingsFile )
		dofile(settingsFile)
		for _name, _value in pairs(LOCALSERVER) do
			JTF1[_name] = _value
		end
		BASE:I("[JTF-1] Local server settings to follow...")
		BASE:I(JTF1)
	else
		BASE:E("[JTF-1] Error! Server config file not found. Using mission defaults")
	end

end

--- END INIT