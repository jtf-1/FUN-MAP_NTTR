 env.info("[JTF-1] MISSION BUILD 2024-08-21T15:54:55.03")  
  
--------------------------------[core\mission_init.lua]-------------------------------- 
 
env.info( "*** [JTF-1] MISSION SCRIPTS START ***" )
---- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- debug on/off
BASE:TraceOnOff(false)

JTF1 = {
	traceTitle = "[JTF-1 MISSIONINIT] ",
	trace = false,
	missionRestart = "MISSION_RESTART", -- Message to trigger mission restart via jtf1-hooks
	flagLoadMission = 9999, -- flag for load misison trigger
	defaultServerConfigFile = "LocalServerSettings.lua", -- srs server settings file name
	menu = {},
}

function JTF1:Start()
	if not lfs then
		_msg = JTF1.traceTitle .. "WARNING: lfs not desanitized. Loading will look into your DCS installation root directory rather than the \"Saved Games\\DCS\" folder."
		BASE:E(_msg)
	else

		-- load local server settings file
		local settingsFile = lfs.writedir() .. JTF1.defaultServerConfigFile

		if UTILS.CheckFileExists(lfs.writedir(), JTF1.defaultServerConfigFile) then
			_msg = string.format("%sServer Settings File = %s", JTF1.traceTitle, settingsFile) 
			BASE:I(_msg)
			local msgServerSettings = ""
			dofile(settingsFile)
			for _name, _value in pairs(LOCALSERVER) do
				JTF1[_name] = _value
				msgServerSettings = msgServerSettings .. _name .. " = " .. tostring(_value) .. "\n"
			end
			_msg = string.format("%sServer Settings follow;\n\n%s\n",
				JTF1.traceTitle,
				msgServerSettings
			)
			BASE:I(_msg)
		else
			_msg = JTF1.traceTitle .. "Error! Server config file not found. Using mission defaults"
			BASE:E(_msg)
		end

	end

	-- add root menu for JTF-1 if activated in data file
	if JTF1.jtfmenu then
		JTF1.menu.root = MENU_MISSION:New("JTF-1")
	end

end


--- END INIT  
--------------------------------[mission_init_data.lua]-------------------------------- 
 
env.info( "[JTF-1] mission_init_data.lua" )

--- MISSION JTF1 SETTINGS FOR MIZ
--
-- This file MUST be loaded AFTER mission_init.lua
--
-- These values are specific to the miz and will override the default values in JTF1
--

-- Error prevention. Create empty container if module core lua not loaded.
if not JTF1 then 
	JTF1 = {}
	JTF1.traceTitle = "[JTF-1 MISSIONINIT] "
	_msg = JTF1.traceTitle .. "CORE FILE NOT LOADED!"
	BASE:E(_msg)
end

-- table of values to override default JTF1 values for this miz
JTF1.menuAllSlots = false
JTF1.jtfmenu = false

-- start the mission timer
if JTF1.Start then
	_msg = JTF1.traceTitle .. "Call Start()"
	BASE:T(_msg)
	JTF1:Start()  
end
  
--------------------------------[core\devcheck.lua]-------------------------------- 
 
env.info( "[JTF-1] devcheck" )
--- Check for Static or Dynamic mission file loading flag
-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 and JTF1.trace then
	
	local msgLog = "[JTF-1 DEVCHECK] "
	local msgText = ""

	if devState == 1 then
		msgText = "Dynamic Loading is ON!"
	end

	if JTF1.trace then
		msgText = msgText .. " TRACE is ON!"
		-- trace all events
		BASE:TraceOnOff(true)
		BASE:TraceAll(true)
	end

	_msg = msgLog .. msgText
	BASE:E(_msg)
	MESSAGE:New(msgText):ToAll()

	DEV_MENU = {
		traceOn = true, -- default tracestate false == trace off, true == trace on.
		flagLoadMission = (JTF1.flagLoadMission and JTF1.flagLoadMission or 9999), -- flag for load misison trigger
		missionRestartMsg = (JTF1.missionRestartMsg and JTF1.missionRestartMsg or "ADMIN9999"), -- Message to trigger mission restart via jtf1-hooks
	}
	
	function DEV_MENU:toggleTrace()
		if BASE:IsTrace() then
		BASE:TraceOff()
		else
		BASE:TraceOn()
		end
		_msg = string.format("[JTF-1 DEVCHECK] Trace toggled", tostring(BASE:IsTrace()))
		BASE:E(_msg)
	end

	-- function DEV_MENU:testLua() --check encoding
	--   local base = _G
	--   local f = assert( base.loadfile( 'E:/GitHub/FUN-MAP_NTTR/scripts/dynamic/test.lua' ) )
	--   if f == nil then
	--     error ("Mission Loader: could not load test.lua." )
		--   else
	--     env.info( "[JTF-1] Mission Loader: test.lua dynamically loaded." )
	--     --return f()
	--   end
	-- end

	function DEV_MENU:restartMission()
		trigger.action.setUserFlag(ADMIN.flagLoadMission, 99)
	end

	-- Add Dev submenu to F10 Other
	if JTF1.menu.root then
		DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU", JTF1.menu.root)
	else
		DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
	end
	MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, DEV_MENU.toggleTrace)
	--MENU_MISSION_COMMAND:New("Reload Test LUA.", DEV_MENU.topmenu, DEV_MENU.testLua)
	MENU_MISSION_COMMAND:New("Restart Mission", DEV_MENU.topmenu, DEV_MENU.restartMission)

	if DEV_MENU.traceOn then
		BASE:TraceOn()
	end  

else
	local _msg = "[JTF-1] DEV flag is OFF."
	BASE:I(_msg)
end

--- END DEVCHECK  
--------------------------------[core\missionsrs.lua]-------------------------------- 
 
env.info( "[JTF-1] missionsrs.lua" )
--
-- Send messages through SRS using STTS
--
-- Two files are used by this module;
--     missionsrs.lua
--     missionsrs_data.lua
--
-- 1. missionsrs.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. missionsrs_data.lua
-- Contains settings that are specific to the miz.
-- Optional. If not use, uncomment MISSIONSRS:Start() at the end of this file.
-- If used, MISSIONSRS:Start() in this file MUST be commented out.
--
-- For custom settings to be used, load order in miz MUST be;
--     1. missionsrs.lua
--     2. missionsrs_data.lua
--
-- If the missionsrs_data.lua is not used the defaults for srs_path and srs_port will be used.
--
-- Message text will be formatted as a SOUNDTEXT object.
-- 
-- Use MISSIONSRS:SendRadio() to transmit on SRS
--
-- msgText        - [required] STRING. Text of message. Can be plain text or a MOOSE SOUNDTEXT obkect
-- msfFreqs       - [optional] STRING. frequency, or table of frequencies (without any spaces). Default freqs AND modulations will be applied if this is not specified.
-- msgModulations - [optional] STRING. modulation, or table of modulations (without any spaces) if multiple freqs passed. Ignored if msgFreqs is not defined. Default modulations will be applied if this is not specified
--

MISSIONSRS = {}

MISSIONSRS = {
  srsPath = "C:/PROGRA~1/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  srsPort = 5002,                                          -- default SRS port to use if settings file is not available
  msg = "No Message Defined!",                             -- default message if text is nil
  freqs = {243,251,327,377.8,30},                          -- transmit on guard, CTAF, NTTR TWR, NTTR BLACKJACK and 30FM as default frequencies
  modulations = {AM,AM,AM,AM,FM},                          -- default modulation (count *must* match qty of freqs)
  vol = "1.0",                                             -- default to full volume
  name = "Server",                                         -- default to server as sender
  coalition = 0,                                           -- default to spectators
  vec3 = nil,                                              -- point from which transmission originates
  speed = 2,                                               -- speed at which message should be played
  gender = "female",                                       -- default gender of sender
  culture = "en-US",                                       -- default culture of sender
  voice = "",                                              -- default voice to use
}

local _msg

function MISSIONSRS:Start()
  local useSRS = JTF1.useSRS
  if useSRS == false then
    _msg = "[JTF-1 MISSIONSRS] Server SRS is OFF!"
    BASE:E(_msg)
  end
  self.srsPath = JTF1.srsPath or self.srsPath
  self.srsPort = JTF1.srsPort or self.srsPort
  self:AddRadio()
  BASE:T({"[JTF-1 MISSIONSRS]",{self}})
end

function MISSIONSRS:AddRadio()
  self.Radio = MSRS:New(self.srsPath, self.freqs, self.modulations)
  self.Radio:SetPort(self.srsPort)
  self.Radio:SetGender(self.gender)
  self.Radio:SetCulture(self.culture)
  self.Radio.name = self.name
  self.Radio.active = true
end

function MISSIONSRS:SendRadio(msgText, msgFreqs, msgModulations)

  BASE:T({"[JTF-1 MISSIONSRS] SendRadio", {msgText}, {msgFreqs}, {msgModulations}})
  if msgFreqs then
    BASE:T("[JTF-1 MISSIONSRS] tx with freqs change.")
    if msgModulations then
      BASE:T("[JTF-1 MISSIONSRS] tx with mods change.")
    end
  end
  if msgText == (nil or "") then 
    msgText = self.msg
  end
  local text = msgText
  local tempFreqs = msgFreqs or self.freqs
  local tempModulations = msgModulations or self.modulations
  if not msgText.ClassName then
    BASE:T("[JTF-1 MISSIONSRS] msgText NOT SoundText object.")
    text = SOUNDTEXT:New(msgText) -- convert msgText to SOundText object
  end
  self.Radio:SetFrequencies(tempFreqs)
  self.Radio:SetModulations(tempModulations)
  self.Radio:PlaySoundText(text)
  self.Radio:SetFrequencies(self.freqs) -- reset freqs to default
  self.Radio:SetModulations(self.modulations) -- rest modulation to default

end

--MISSIONSRS:Start() -- uncomment if missionsrs_data.lua is not used
  
--------------------------------[core\adminmenu.lua]-------------------------------- 
 
env.info( "[JTF-1] adminmenu.lua" )

--- Admin menu
--
-- Add F10 command menus for selecting a mission to load, or restarting the current mission.
--
-- In the Mission Editor, add (a) switched condition trigger(s) with a 
-- FLAG EQUALS condition, where flag number is ADMIN.flagLoadMission value
-- and flag value is the ADMIN.missionList[x].missionFlagValue (see below).
-- A missionFlagValue == 0 is used to trigger restart of the current
-- mission using jtf1-hooks.lua.
--
-- If the menu should only appear for restricted client slots, set
-- ADMIN.menuAllSlots to FALSE and add a client slot with the group name
-- *prefixed* with the value set in ADMIN.adminMenuName.
--
-- If the menu should be available in all mission slots, set ADMIN.menuAllSlots
-- to TRUE.|
-- 

ADMIN = {
	ClassName = "ADMIN",
	traceTitle = "[JTF-1] ",
	version = "0.1",
	menuAllSlots = false, -- Set to true for admin menu to appear in all player slots
	defaultMissionRestart = "MISSION_RESTART",
	defaultMissionLoad = "MISSION_LOAD",
	defaultMissionFile = "missions.lua",
	defaultMissionFolder = "missions",
	defaultMissionPath = "C:\\Users\\jtf-1\\Saved Games\\missions",
	adminUnitName = "XX_", -- String to locate within unit name for admin slots
}

ADMIN.missionRestart = JTF1.missionRestart or ADMIN.defaultMissionRestart
ADMIN.missionLoad = JTF1.missionLoad or ADMIN.defaultMissionLoad
ADMIN.missionFile = JTF1.missionFile or ADMIN.defaultMissionFile

-- inherit methods,  properties etc from BASE for event handler, trace etc
ADMIN = BASE:Inherit(ADMIN, BASE:New())
-- ADMIN event handler
ADMIN:HandleEvent(EVENTS.PlayerEnterAircraft)



function ADMIN:Start()
	-- check if mission is in devmode.
	local devState = trigger.misc.getUserFlag(8888)
	-- add admin menu to all slots if dev mode is active
	if devState == 1 then
		ADMIN.menuAllSlots = true
	end

	-- check if a server config file has defined the path to the missions file.
	if JTF1.missionPath then
		ADMIN.missionPath = JTF1.missionPath
		_msg = string.format(ADMIN.traceTitle .. "missionPath = %s", ADMIN.missionPath)
		self:T(_msg)
	else
		if lfs then -- check if game environment is desanitised
			ADMIN.missionPath = (lfs.writedir() .. "\\" .. ADMIN.defaultMissionFolder) -- set mission path to current write directory
		else
			ADMIN.missionPath = "" -- empty mission path will bypass all but restart mission menu option
		end
	end

	-- set full path to mission list
	local missionPathFile = ADMIN.missionPath .. "\\" .. ADMIN.missionFile
	self:T(ADMIN.traceTitle .. "mission list file: " .. missionPathFile)
	-- check mission list lua file exists. If it does run it. 
	if UTILS.CheckFileExists(ADMIN.missionPath, ADMIN.missionFile) then
		self:T( ADMIN.traceTitle .. "Mission list file exists")
		dofile(missionPathFile)
		ADMIN.missionList = MISSIONLIST -- map mission list values to ADMIN.missionList
		self:T({ADMIN.traceTitle .. "ADMIN.missionList", ADMIN.missionList})
		-- if present insert local server mission list at top of ADMIN.missionList
		if JTF1.missionList then
			self:T({ADMIN.traceTitle .. "JTF1.missionList", ADMIN.missionList})
			table.insert(ADMIN.missionList, 1, JTF1.missionList[1])
			self:T({ADMIN.traceTitle .. "ADMIN.missionList with local server list", ADMIN.missionList})
		end
	else
		self:E(ADMIN.traceTitle .. "Error! Mission list file not found.")        
	end

end

function ADMIN:GetPlayerUnitAndName(unitName)
	if unitName ~= nil then
		-- Get DCS unit from its name.
		local DCSunit = Unit.getByName(unitName)
		if DCSunit then
			local playername=DCSunit:getPlayerName()
			local unit = UNIT:Find(DCSunit)
		if DCSunit and unit and playername then
			return unit, playername
		end
		end
	end
	-- Return nil if we could not find a player.
	return nil,nil
end

-- when player enters a slot, check if it's an admin slot and add F10 admin menu if it is
function ADMIN:OnEventPlayerEnterAircraft(EventData)
	local unitName = EventData.IniUnitName
	local unit, playername = ADMIN:GetPlayerUnitAndName(unitName)
	if unit and playername then
		-- add a scheduled task to create F10 menu if it's an admin slot or if menuAllslots is set to true
		if string.find(unitName, ADMIN.adminUnitName) or ADMIN.menuAllSlots then
			-- delay task to allow client to finish spawning
			SCHEDULER:New(nil, ADMIN.BuildAdminMenu, {self, unit, playername}, 0.5)
		end
	end
end

--- Load mission requested from menu
function ADMIN:LoadMission(playerName, missionFile)
	local adminMessage = ADMIN.missionRestart
	if playerName then
		self:T(ADMIN.traceTitle .. "Restart or load called by player name: " .. playerName)
	else
		self:T(ADMIN.traceTitle .. "Restart or load called by non-player!")
	end
	if missionFile then
		adminMessage = ADMIN.missionLoad .. "-" .. missionFile
	end
	MESSAGE:New(adminMessage):ToAll()
end

--- Add admin menu and commands if client is in an ADMIN spawn
function ADMIN:BuildAdminMenu(unit,playername)
	local adminGroup = unit:GetGroup()
	-- add ADMIN menu to F10
	local adminMenu
	if JTF1.menu.root then
		-- add root to JTF1 menu
		adminMenu = MENU_GROUP:New(adminGroup, "Admin", JTF1.menu.root)
	else
		-- add root to main F10 menu
		adminMenu = MENU_GROUP:New(adminGroup, "Admin")
	end
	
	-- add command to restart current mission  
	MENU_GROUP_COMMAND:New( adminGroup, "Restart Current Mission", adminMenu, ADMIN.LoadMission, self, playername)
	-- if a mission list has been found add submenus for it
	if ADMIN.missionList then
		self:T(ADMIN.traceTitle .. "Build missionList.")
		-- add menus to load missions
		for i, missionList in ipairs(ADMIN.missionList) do
			self:T(missionList)
			-- add menu for mission group  
			local missionName = MENU_GROUP:New(adminGroup, missionList.missionName, adminMenu)
			-- add menus for each mission file in the group
			for j, missionMenu in ipairs(missionList.missionMenu) do
				self:T(missionMenu)
				-- add full path to mission file if defined
				local missionFile = ADMIN.missionPath .. "\\" .. missionMenu.missionFile
				-- add command to load mission
				MENU_GROUP_COMMAND:New( adminGroup, missionMenu.menuText, missionName, ADMIN.LoadMission, self, playername, missionFile )
				_msg = string.format(ADMIN.traceTitle .. "Admin Menu Mission %s", missionFile)
				self:T(_msg)
			end
		end
	end
end

--- END ADMIN MENU SECTION  
--------------------------------[core\missiontimer.lua]-------------------------------- 
 
env.info( "[JTF-1] missiontimer.lua" )

--- Mission Timer
--
-- Add schedules to display messages at set intervals prior to restarting the base mission.
-- ME switched triggers should be set to a FLAG EQUALS condition for the flag flagLoadMission
-- value (defined in script header). Sending missionRestart text will trigger restarting the
-- current mission via jtf1-hooks.lua.
--
MISSIONTIMER = {}
-- debug messages title
MISSIONTIMER.traceTitle = "[JTF-1 MISSIONTIMER] "
 -- schedule container
MISSIONTIMER.msgWarning = {}
-- DEFAULT settings. WIll be oiverwritten by values defined in _data file.
MISSIONTIMER.missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ) -- Message to trigger mission restart via jtf1-hooks
MISSIONTIMER.durationHrs = 24 -- Mission run time in HOURS
MISSIONTIMER.msgSchedule = {60, 30, 10, 5} -- Schedule for mission restart warning messages. Time in minutes.
MISSIONTIMER.restartDelay =  10 -- time in minutes to delay restart if active clients are present.
MISSIONTIMER.useSRS = true -- default flag to determine if htis module should send messages through SRS.

local useSRS
local _msg

-- function to start the mission timer
function MISSIONTIMER:Start()
	self.useSRS = (JTF1.useSRS and self.useSRS) and MISSIONSRS.Radio.active -- default to not using SRS unless both the server AND the module request it AND MISSIONSRS.Radio.active is true
	BASE:I({"[JTF-1 MISSIONTIMER] useSRS", self.useSRS})
	self.durationSecs = self.durationHrs * 3600 -- Mission run time in seconds
	BASE:T({"[JTF-1 MISSIONTIMER] settings",{self}})
	self:AddSchedules()
end

--- function to add scheduled messages for mission restart warnings and restart at end of mission duration
function MISSIONTIMER:AddSchedules()
	if self.msgSchedule ~= nil then
		BASE:I({"[JTF-1 MISSIONTIMER] Schedule", self.msgSchedule})
		for i, msgTime in ipairs(self.msgSchedule) do
		self.msgWarning[i] = SCHEDULER:New( nil, 
			function()
			_msg = string.format("[JTF-1 MISSIONTIMER] TIMER WARNING CALLED at %d minutes remaining.", msgTime)
			BASE:T(_msg)
			_msg = string.format("All players, mission is scheduled to restart in %d minutes!", msgTime)
			if self.useSRS then -- if MISSIONSRS radio object has been created, send message via default broadcast.
				MISSIONSRS:SendRadio(_msg)
			else -- otherwise, send in-game text message
				MESSAGE:New(_msg):ToAll()
			end
			end,
		{msgTime}, self.durationSecs - (msgTime * 60))
		end
	end
	self.msgWarning["restart"] = SCHEDULER:New( nil,
		function()
			MISSIONTIMER:Restart()
		end,
		{ }, self.durationSecs
	)
end

-- function to restart the mission after the end of the scheduled duration
-- restart will be delayed until all pplayers have left the mission
function MISSIONTIMER:Restart()
	if not self.clientList then
		self.clientList = SET_CLIENT:New()
		self.clientList:FilterActive()
		self.clientList:FilterStart()
	end
	if self.clientList:CountAlive() > 0 then
		local delayTime = self.restartDelay
		local msg  = "All players, mission will restart when no active clients are present. Next check will be in " .. tostring(delayTime) .." minutes." 
		if self.useSRS then -- if MISSIONSRS radio object has been created, send message via default broadcast.
			MISSIONSRS:SendRadio(msg)
		else -- otherwise, send in-game text message
			MESSAGE:New(msg):ToAll()
		end
		self.msgWarning["restart"] = SCHEDULER:New( nil,
			function()
				MISSIONTIMER:Restart()
			end,
			{ }, (self.restartDelay * 60)
		)
	else
		BASE:I("[JTF-1 MISSIONTIMER] RESTART MISSION")
		MESSAGE:New(self.missionRestart):ToAll()
	end
end

--- END MISSION TIMER  
--------------------------------[core\supportaircraft.lua]-------------------------------- 
 
env.info( "[JTF-1] supportaircraft.lua" )

--
--- Support Aircraft
--
-- **NOTE** THIS FILE MUST BE LOADED BEFORE SUPPORTAIRCRAFT_DATA.LUA IS LOADED
--
-- Spawn support aircraft (tankers, awacs) at zone markers placed in the mission editor.
--
-- Two files are required for this module;
--     supportaircraft.lua
--     supportaircraft_data.lua
--
-- 1. supportaircraft.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. supportaircraft_data.lua
-- Contains settings that are specific to the miz.
--
-- Load order in miz MUST be;
--     1. supportaircraft.lua
--     2. supportaircraft_data.lua
--
-- In the mission editor, place a zone where you want the support aircraft to spawn.
-- Under SUPPORTAC.mission, add a config block for the aircraft you intend to spawn.
-- See the comments in the example block for explanations of each config option.
--
-- if the predefined templates are not being used a late activated template must be added 
-- to the miz for for each support *type* that is to be spawned.
-- The template should use the same name as the type in the SUPPORTAC.type data block, 
-- eg "KC-135" or "AWACS-E3A" etc.
--
-- Available support aircraft categories and types for which predefined templates are available [category] = [template name];
--
-- Category: tanker
--    tankerBoom = "KC-135" - SPAWNTEMPLATES.templates["KC-135"]
--    tankerProbe = KC-135MPRS" - SPAWNTEMPLATES.templates["KC-135MPRS"]
--    WIP** tankerProbeC130 = "KC-130" - SPAWNTEMPLATES.templates["KC-130"]
--
-- Category: awacs
-- awacsE3a = "AWACS-E3A" - SPAWNTEMPLATES.templates["AWACS-E3A"]
-- awacsE2d = "AWACS-E3A" - SPAWNTEMPLATES.templates["AWACS-E3A"]
--

SUPPORTAC = {}
SUPPORTAC = BASE:Inherit(SUPPORTAC, BASE:New())
SUPPORTAC.traceTitle = "[JTF-1 SUPPORTAC] "
SUPPORTAC.ClassName = "SUPPORTAC"
SUPPORTAC.useSRS = true -- if true, messages will be sent over SRS using the MISSIONSRS module. If false, messages will be sent as in-game text.
SUPPORTAC.trace = false -- tracing off by default if false

local _msg -- used for debug messages only
local useSRS

if JTF1 then
	SUPPORTAC.trace = JTF1.trace
end

-- function to start the SUPPORTAC module.
function SUPPORTAC:Start()
	_msg = string.format(self.traceTitle .. "Start()")
	self:T(_msg)

	-- set tracing on or off
	self:TraceOnOff(self.trace)
	self:TraceAll(self.trace)

	-- default to not using SRS unless both the server AND the module request it AND MISSIONSRS.Radio.active is true
	useSRS = (JTF1.useSRS and self.useSRS) and MISSIONSRS.Radio.active 
	self:I({self.traceTitle .. "useSRS", self.useSRS})

	for index, mission in ipairs(SUPPORTAC.mission) do -- FOR-DO LOOP
		_msg = string.format("%sStart - mission %s", self.traceTitle, mission.name)
		SUPPORTAC:T(_msg)

		local skip = false -- check value to exit early from the current for/do iteration

		local missionZone = ZONE:FindByName(mission.zone)
		-- check zone is present in miz
		if missionZone then -- CHECK MISSION ZONE
		
			-- if trace is on, draw the zone on the map
			if self.trace then 
				-- draw mission zone on map
				missionZone:DrawZone()
			end

			-- airbase to which aircraft will fly on RTB
			local missionTheatre = env.mission.theatre
			_msg = SUPPORTAC.traceTitle .. tostring(missionTheatre)
			self:T(_msg)
			local missionHomeAirbase = SUPPORTAC.homeAirbase["Nevada"]--mission.homeAirbase or SUPPORTAC.homeAirbase[missionTheatre]
			_msg = SUPPORTAC.traceTitle .. tostring(missionHomeAirbase)
			self:T(_msg)
			_msg = string.format("%sstart - Mission %s set to use %s as home base.", self.traceTitle, mission.name, missionHomeAirbase)
			SUPPORTAC:T(_msg)
			if missionHomeAirbase then -- CHECK HOME AIRBASE
				_msg = string.format("%sStart - Mission %s using %s as home base.", self.traceTitle, mission.name, missionHomeAirbase)
				SUPPORTAC:T(_msg)

				-- set home airbase in mission
				mission.homeAirbase = missionHomeAirbase

				-- values used to create mission spawn prefix
				local missionName = mission.name or SUPPORTAC.missionDefault.name
				local missionSpawnType = mission.type or SUPPORTAC.missionDefault.type
				-- set spawn prefix unique to support mission
				local missionSpawnAlias = string.format("M%02d_%s_%s", index, missionName, missionSpawnType)

				-- values used to define mission, spawn and waypoint locations
				local missionFlightLevel = mission.flightLevel or SUPPORTAC.missionDefault.flightLevel
				local missionSpawnDistance = mission.spawnDistance or SUPPORTAC.missionDefault.spawnDistance
				local missionAltitude = UTILS.FeetToMeters(missionFlightLevel * 100)
				local spawnDistance = UTILS.NMToMeters(missionSpawnDistance)
				local spawnHeading = mission.heading or SUPPORTAC.missionDefault.heading
				local spawnAngle = spawnHeading + 180
				if spawnAngle > 360 then 
					spawnAngle = spawnHeading - 180
				end
				local spawnUnlimitedFuel = mission.unlimitedFuel or SUPPORTAC.missionDefault.unlimitedFuel

				-- coordinate used for the AUFTRAG
				local missionCoordinate = missionZone:GetCoordinate()
				missionCoordinate:SetAltitude(missionAltitude)
				mission.missionCoordinate = missionCoordinate

				-- coordinate used for the mission spawn template
				local spawnCoordinate = missionCoordinate
				spawnCoordinate:Translate(spawnDistance, spawnAngle, true, true)
				mission.spawnCoordinate = spawnCoordinate

				-- coordinate used for an initial waypoint for the flightgroup
				local waypointCoordinate = missionCoordinate
				waypointCoordinate = waypointCoordinate:Translate(spawnDistance/2, spawnAngle, true, true)
				mission.waypointCoordinate = waypointCoordinate

				if GROUP:FindByName(missionSpawnType) then -- FIND MISSION SPAWN TEMPLATE - use from mission block
					_msg = string.format("%sStart - Using spawn template from miz for %s.", self.traceTitle, missionSpawnType)
					SUPPORTAC:T(_msg)

					-- add mission spawn object using template in miz
					mission.missionSpawnTemplate = SPAWN:NewWithAlias(missionSpawnType, missionSpawnAlias)
				elseif SPAWNTEMPLATES.templates[missionSpawnType] then -- ELSEIF FIND MISSION SPAWN TEMPLATE-- Use predfined template from SPAWNTEMPLATES.templates[missionSpawnType]
					_msg = string.format("%sStart - Using spawn template from SPAWNTEMPLATES.templates for %s.", self.traceTitle, missionSpawnType)
					SUPPORTAC:T(_msg)

					-- get template to use for spawn
					local spawnTemplate = SPAWNTEMPLATES.templates[missionSpawnType]

					-- check "category" has been set in template
					-- if not spawnTemplate["category"] then
					-- 	spawnTemplate["category"] = Group.Category.AIRPLANE
					-- end
					
					-- apply mission callsign to template (for correct display in F10 map)
					local missionCallsignId = mission.callsign
					local missionCallsignNumber = mission.callsignNumber or 1

					-- default callsign name to use if not found
					local missionCallsignName = "Ghost"

					if missionCallsignId then
						-- table of callsigns to search for callsign name
						local callsignTable = CALLSIGN.Tanker
						if mission.category == SUPPORTAC.category.awacs then
							callsignTable = CALLSIGN.AWACS
						end

						for name, value in pairs(callsignTable) do
							if value == missionCallsignId then
								missionCallsignName = name
							end
						end
						
					else
						missionCallsignId = 1
					end

					local missionUnit = spawnTemplate.units[1]

					if type(missionUnit["callsign"]) == "table" then
						-- local missionCallsign = string.format("%s%d1", missionCallsignName, missionCallsignNumber)
						missionUnit["callsign"]["name"] = string.format("%s%d1", missionCallsignName, missionCallsignNumber)
						missionUnit["callsign"][1] = missionCallsignId
						missionUnit["callsign"][2] = missionCallsignNumber
						missionUnit["callsign"][3] = 1
					elseif type(missionUnit["callsign"]) == "number" then
						missionUnit["callsign"] = tonumber(missionCallsignId)
					else
						missionUnit["callsign"] = missionCallsignId
					end
					
					local missionCountryid = mission.countryid or SUPPORTAC.missionDefault.countryid
					local missionCoalition = mission.coalition or SUPPORTAC.missionDefault.coalition
					local missionGroupCategory = mission.groupCategory or SUPPORTAC.missionDefault.groupCategory

					-- add mission spawn object using template in SPAWNTEMPLATES.templates[missionSpawnType]
					mission.missionSpawnTemplate = SPAWN:NewFromTemplate(spawnTemplate, missionSpawnType, missionSpawnAlias)
						:InitCountry(missionCountryid) -- set spawn countryid
						:InitCoalition(missionCoalition) -- set spawn coalition
						:InitCategory(missionGroupCategory) -- set category
				else -- FIND MISSION SPAWN TEMPLATE
						skip = true -- can't exit to the next iteration so skip the rest of the mission creation
				end -- FIND MISSION SPAWN TEMPLATE

				-- if missionSpawnTamplate was not created continue to next iteration, otherwise set spawn inits and create a new mission
				if skip then -- CHECK SKIP
					_msg = string.format(self.traceTitle .. "Start - template for type %s for mission %s is not present in MIZ or as a predefined template!", missionSpawnType, missionSpawnAlias)
					SUPPORTAC:E(_msg)
				else -- CHECK SKIP
					-- mission spawn object defaults
					mission.missionSpawnTemplate:InitLateActivated() -- set template to late activated
					mission.missionSpawnTemplate:InitPositionCoordinate(mission.spawnCoordinate) -- set the default location at which the template is created
					mission.missionSpawnTemplate:InitHeading(mission.heading) -- set the default heading for the spawn template
					if mission.livery then
						mission.missionSpawnTemplate:InitLivery(mission.livery)
					end
					mission.missionSpawnTemplate:OnSpawnGroup(
						function(spawngroup)
							local spawnGroupName = spawngroup:GetName()
							-- _msg = string.format(SUPPORTAC.traceTitle .. "Spawned Group %s", spawnGroupName)
							-- self:T(_msg)
		
							spawngroup:CommandSetUnlimitedFuel(spawnUnlimitedFuel)
							spawngroup:CommandSetCallsign(mission.callsign, mission.callsignNumber) -- set the template callsign
						end
						,mission
					)

					--_msg = string.format(self.traceTitle .. "New late activated mission spawn template added for %s", missionSpawnAlias)
					--SUPPORTAC:T(_msg)
					
					-- call NewMission() to create the initial mission for the support aircraft
					-- subsequent mission restarts will be called after the mission's AUFTRAG is cancelled
					SUPPORTAC:NewMission(mission, 0) -- create new mission with specified delay to flightgroup activation
				end -- CHECK SKIP
			
			else -- CHECK HOME AIRBASE
				
				_msg = string.format(self.traceTitle .. "Start - Default Home Airbase for %s not defined! Mission skipped.", missionTheatre)
				SUPPORTAC:E(_msg)

			end -- CHECK HOME AIRBASE

		else -- CHECK MISSION ZONE
			_msg = string.format(self.traceTitle .. "Start - Zone %s not found! Mission skipped.", mission.zone)
			SUPPORTAC:E(_msg)
		end -- CHECK MISSION ZONE

	end -- FOR-DO LOOP

end -- SUPPORTAC:Start()

-- function to create new support mission and flightGroup
function SUPPORTAC:NewMission(mission, initDelay)
	_msg = string.format(self.traceTitle .. "Create new mission for %s", mission.name)
	SUPPORTAC:T(_msg)

	-- create new mission
	local newMission = {}
	local missionCoordinate = mission.missionCoordinate
	local missionAltitude = mission.flightLevel * 100
	local missionSpeed = mission.speed
	local missionHeading = mission.heading
	local missionDespawn = mission.despawn or SUPPORTAC.missionDefault.despawn
	
	-- use appropriate AUFTRAG type for mission
	if mission.category == SUPPORTAC.category.tanker then
		local missionLeg = mission.leg or SUPPORTAC.missionDefault.tankerLeg -- set leg length. Either mission defined or use default for tanker.
		-- create new tanker AUFTRAG mission
		newMission = AUFTRAG:NewTANKER(
		missionCoordinate, 
		missionAltitude, 
		missionSpeed, 
		missionHeading, 
		missionLeg
		)
		_msg = string.format(self.traceTitle .. "New mission created: %s", newMission:GetName())
		SUPPORTAC:T(_msg)
	elseif mission.category == SUPPORTAC.category.awacs then
		local missionLeg = mission.leg or SUPPORTAC.missionDefault.awacsLeg -- set leg length. Either mission defined or use default for AWACS.
		-- create new AWACS AUFTRAG mission
		newMission = AUFTRAG:NewAWACS(
		missionCoordinate,
		missionAltitude,
		missionSpeed,
		missionHeading,
		missionLeg
		)
		_msg = string.format(self.traceTitle .. "New mission created: %s", newMission:GetName())
		SUPPORTAC:T(_msg)
	else
		_msg = self.traceTitle .. "Mission category not defined!"
		SUPPORTAC:E(_msg)
		return -- exit mission creation
	end

	newMission:SetEvaluationTime(5)

	if mission.tacan ~= nil then
		newMission:SetTACAN(mission.tacan, mission.tacanid)
	end

	newMission:SetRadio(mission.radio)

	local despawnDelay = mission.despawnDelay or SUPPORTAC.missionDefault.despawnDelay
	local activateDelay = (mission.activateDelay or SUPPORTAC.missionDefault.activateDelay) + despawnDelay

	-- spawn new group
	local spawnGroup = mission.missionSpawnTemplate:SpawnFromCoordinate(mission.spawnCoordinate)
	_msg = string.format(self.traceTitle .. "New late activated group %s spawned.", spawnGroup:GetName())
	SUPPORTAC:T(_msg)

	-- create new flightGroup
	local flightGroup = FLIGHTGROUP:New(spawnGroup)
		:SetDefaultCallsign(mission.callsign, mission.callsignNumber)
		:SetDefaultRadio(SUPPORTAC.missionDefault.radio)
		--:SetDefaultAltitude(mission.flightLevel * 100)
		:SetDefaultSpeed(mission.speed) -- mission.speed + (mission.flightLevel / 2)
		
	-- add an initial waypoint between the aircraft and the mission zone
	--flightGroup:AddWaypoint(mission.waypointCoordinate, missionSpeed)
	flightGroup:SetHomebase(mission.homeAirbase)

	flightGroup:Activate(activateDelay)

	-- function call after flightGroup is spawned
	-- assign mission to new ac
	function flightGroup:OnAfterSpawned()
		_msg = string.format("%sFlightgroup %s activated.", SUPPORTAC.traceTitle, self:GetName())
		SUPPORTAC:T(_msg)
		-- assign mission to flightGroup
		self:AddMission(newMission)
	end

	-- function called after flightGroup starts mission
	-- set RTB criteria
	function flightGroup:OnAfterMissionStart()
		local missionName = newMission:GetName()
		local flightGroupName = self:GetName()
		local flightGroupCallSign = SUPPORTAC:GetCallSign(self)

		_msg = string.format("%sMission %s for Flightgroup %s, %s has started.", SUPPORTAC.traceTitle, missionName, flightGroupName, flightGroupCallSign) -- self:GetCallsignName(true)
		SUPPORTAC:T(_msg)

		self:SetFuelLowRefuel(false)
		local fuelLowThreshold = mission.fuelLowThreshold or SUPPORTAC.missionDefault.fuelLowThreshold

		if fuelLowThreshold > 0 then
			self:SetFuelLowThreshold(fuelLowThreshold) -- tune fuel RTB trigger for each support mission
		end

		self:SetFuelLowRTB()

		function flightGroup:OnAfterRTB()
			_msg = string.format(SUPPORTAC.traceTitle .. "Flightgroup %s is RTB.", flightGroupName)
			SUPPORTAC:T(_msg)
		end

		function newMission:OnAfterDone()
			local missionName = self.name
			local missionFreq = mission.radio
			local flightGroupName = flightGroup:GetName()
			local flightGroupCallSign = SUPPORTAC:GetCallSign(flightGroup)
		
			_msg = string.format("%snewMission OnAfterDone - Mission %s for Flightgroup %s is done.", SUPPORTAC.traceTitle, missionName, flightGroupName)
			SUPPORTAC:T(_msg)

			-- prepare off-station advisory message
			local msgText = string.format("All players, %s is going off station. A new aircraft will be on station shortly.", flightGroupCallSign)
			-- send off station advisory message
			SUPPORTAC:SendMessage(msgText, missionFreq)
			-- create a new mission to replace the departing support aircraft 
			SUPPORTAC:NewMission(mission)

			-- despawn this flightgroup, if it's still alive
			if flightGroup:IsAlive() and missionDespawn then
				_msg = string.format("%snewMission OnAfterDone - Flightgroup %s will be despawned after %d seconds.", SUPPORTAC.traceTitle, flightGroupName, despawnDelay)
				SUPPORTAC:T(_msg)

				flightGroup:Despawn(despawnDelay)
			end

		end -- newMission:OnAfterDone()

	end -- flightGroup:OnAfterMissionStart()

end -- SUPPORTAC:NewMission()

-- function called to send message
-- if MISSIONSRS is loaded, message will be sent on aupport aircraft freq.
-- Otherwise, message will be sent as text to all.
function SUPPORTAC:SendMessage(msgText, msgFreq)
	local _msg = string.format(self.traceTitle .. "SendMessage: %s", msgText)
	SUPPORTAC:T(_msg)
	if useSRS then
		MISSIONSRS:SendRadio(msgText, msgFreq)
	else
		MESSAGE:New(msgText):ToAll()
	end
end -- SUPPORTAC:SendMessage()

-- function called to return callsign name with major number only
function SUPPORTAC:GetCallSign(flightGroup)
	local callSign=flightGroup:GetCallsignName()
	if callSign then
		local callsignroot = string.match(callSign, '(%a+)') or "Ghost" -- Uzi
		local callnumber = string.match(callSign, "(%d+)$" ) or "91" -- 91
		local callnumbermajor = string.char(string.byte(callnumber,1)) -- 9
		callSign = callsignroot.." "..callnumbermajor -- Uzi/Victory 9
		return callSign
	end
	-- default callsign to return if it cannot be determined
	return "Ghostrider 1"
end -- SUPPORTAC:GetCallSign()

-- Support categories used to define which AUFTRAG type is used
SUPPORTAC.category = {
	tanker = 1,
	awacs = 2,
} -- end SUPPORTAC.category

-- Support aircraft types. Used to define the late activated group to be used as the spawn template
-- for the type. A check is made to ensure the template exists in the miz or that the value is the
-- same as the ID in the SPAWNTEMPLATES.templates block (see supportaircraft.lua)
SUPPORTAC.type = {
	tankerBoom = "KC-135", -- template to be used for type = "tankerBoom" OR SPAWNTEMPLATES.templates["KC-135"]
	tankerProbe = "KC-135MPRS", -- template to be used for type = "tankerProbe" OR SPAWNTEMPLATES.templates["KC-135MPRS"]
	tankerProbeC130 = "KC-130", -- template for type = "tankerProbeC130" OR SPAWNTEMPLATES.templates["KC-130"]
	awacsE3a = "AWACS-E3A", -- template to be used for type = "awacsE3a" OR SPAWNTEMPLATES.templates["AWACS-E3A"]
	awacsE2d = "AWACS-E2D", -- template to be used for type = "awacsE2d" OR SPAWNTEMPLATES.templates["AWACS-E2D"]
	awacsA50 = "AWACS-A50", -- template to be used for type = "awacsA50" OR SPAWNTEMPLATES.templates["AWACS-A50"]
} -- end SUPPORTAC.type

-- Default home airbase. Added to the mission spawn template if not defined in
-- the mission data block
SUPPORTAC.homeAirbase = {
	["Nevada"] = AIRBASE.Nevada.Nellis,
	["Caucasus"] = AIRBASE.Caucasus.Tbilisi_Lochini,
	["PersianGulf"] = AIRBASE.PersianGulf.Al_Dhafra_AB,
	["Syria"] = AIRBASE.Syria.Incirlik,
	["Sinai"] = AIRBASE.Sinai.Cairo_International_Airport,
	["MarianaIslands"] = AIRBASE.MarianaIslands.Andersen_AFB,
	["Afghanistan"] = "Kandahar",
} -- end SUPPORTAC.homeAirbase

-- default mission values to be used if not specified in the flight's mission data block
SUPPORTAC.missionDefault = {
	name = "TKR", -- default name for the mission
	category = SUPPORTAC.category.tanker, -- default aircraft category
	type = SUPPORTAC.type.tankerBoom, -- default spawn template that will be used
	callsign = CALLSIGN.Tanker.Texaco, -- default callsign
	callsignNumber = 1, -- default calsign number
	tacan = 100, -- default TACAN preset
	tacanid = "TEX", -- default TACAN ID
	radio = 251, -- default radio freq the ac will use when not on mission
	flightLevel = 200, -- default FL at which to fly mission
	speed = 315, -- default speed at which to fly mission
	heading = 90, --default heading on which to spawn aircraft
	tankerLeg = 50, -- default tanker racetrack leg length
	awacsLeg = 70, -- default awacs racetrack leg length
	activateDelay = 10, -- delay, in seconds, after the previous ac has despawned before the new ac will be activated 
	despawnDelay = 30, -- delay, in seconds, before the old ac will be despawned
	unlimitedFuel = true, -- default unlimited fuel. Set to false in data if fuel RTB is desired
	fuelLowThreshold = 30, -- default % fuel low level to trigger RTB
	spawnDistance = 1, -- default distance in NM from the mission zone at which to spawn aircraft
	countryid = country.id.USA, -- default country to be used for predfined templates
	coalition = coalition.side.BLUE, -- default coalition to use for predefined templates
	groupCategory = Group.Category.AIRPLANE, -- default group category to use for predefined templates
	despawn = true, -- default deSpawn option. if false or nil the aircraft will fly to hom base on RTB
} -- end SUPPORTAC.missionDefault


-- END SUPPORT AIRCRAFT SECTION    
--------------------------------[core\staticranges.lua]-------------------------------- 
 
env.info( "[JTF-1] staticranges.lua" )

--
-- Add static bombing and strafing range(s)
--
-- Two files are used by this module;
--     staticranges.lua
--     staticranges_data.lua
--
-- 1. staticranges.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. staticranges_data.lua
-- Contains settings that are specific to the miz.
-- Settings in staticranges_data.lua will override the defaults in the core file.
--
-- Load order in miz MUST be;
--     1. staticranges.lua
--     2. staticranges_data.lua
--

STATICRANGES = {}
STATICRANGES.traceTitle = "[JTF-1 STATICRANGES] "

local _msg

STATICRANGES.default = {
	strafeMaxAlt             = 1525, -- [5000ft] in metres. Height of strafe box.
	strafeBoxLength          = 3050, -- [10000ft] in metres. Length of strafe box.
	strafeBoxWidth           = 366, -- [1200ft] in metres. Width of Strafe pit box (from 1st listed lane).
	strafeFoullineDistance   = 305, -- [1000ft] in metres. Min distance for from target for rounds to be counted.
	strafeGoodPass           = 20, -- Min hits for a good pass.
	--rangeSoundFilesPath      = "Range Soundfiles/" -- Range sound files path in miz
}

function STATICRANGES:Start()
	_msg = self.traceTitle .. "Start()."
	BASE:T(_msg)
	-- set defaults
	self.strafeMaxAlt = self.strafeMaxAlt or self.default.strafeMaxAlt
	self.strafeBoxLength = self.strafeBoxLength or self.default.strafeBoxLength
	self.strafeBoxWidth = self.strafeBoxWidth or self.default.strafeBoxWidth
	self.strafeFoullineDistance = self.strafeFoullineDistance or self.default.strafeFoullineDistance
	self.strafeGoodPass = self.strafeGoodPass or self.default.strafeGoodPass
	-- Parse STATICRANGES.Ranges and build each range
	if self.Ranges then
		_msg = self.traceTitle .. "Add ranges."
		BASE:T({_msg,self.Ranges})
		self:AddStaticRanges(self.Ranges)
	else
		_msg = self.traceTitle .. "No Ranges defined!"
		BASE:E(_msg)
	end
end

function STATICRANGES:AddStaticRanges(ranges)
	_msg = self.traceTitle .. "AddStaticRanges()."
	BASE:T(_msg)
	for rangeIndex, rangeData in ipairs(ranges) do

		-- create RANGE object
		local range = RANGE:New(rangeData.rangeName)
			:DebugOFF()
			:SetMaxStrafeAlt(self.strafeMaxAlt)
			:SetDefaultPlayerSmokeBomb(false)

		-- add range zone if defined
		local rangeZone = ZONE:FindByName(rangeData.rangeZone) or ZONE_POLYGON:FindByName(rangeData.rangeZone)
		if not rangeZone then
			_msg = string.format(self.traceTitle .. "Range Zone for %s not defined!", rangeData.rangeName)
			BASE:E(_msg)
		else
			_msg = string.format(self.traceTitle .. "Add Range Zone %s for %s.", rangeZone:GetName(), rangeData.rangeName)
			BASE:T(_msg)
			range:SetRangeZone(rangeZone)
		end

		-- add groups of targets
		if rangeData.groups ~= nil then 
			_msg = string.format(self.traceTitle .. "Add range groups for %s.", rangeData.rangeName) 
			BASE:T(_msg)
			for tgtIndex, tgtName in ipairs(rangeData.groups) do
				range:AddBombingTargetGroup(GROUP:FindByName(tgtName))
			end
		end
		
		-- add individual targets
		if rangeData.units ~= nil then 
			_msg = string.format(self.traceTitle .. "Add range units for %s.", rangeData.rangeName)
			BASE:T(_msg)
			for tgtIndex, tgtName in ipairs(rangeData.units) do
				range:AddBombingTargets( tgtName )
			end
		end
		
		-- add strafe targets
		if rangeData.strafepits ~= nil then 
			_msg = string.format(self.traceTitle .. "Add range strafe pits for %s.", rangeData.rangeName)
			BASE:T(_msg)
			for strafepitIndex, strafepit in ipairs(rangeData.strafepits) do
				range:AddStrafePit(strafepit, self.strafeBoxLength, self.strafeBoxWidth, nil, true, self.strafeGoodPass, self.strafeFoullineDistance)
			end  
		end

		-- add range radio
		if rangeData.rangeControlFrequency ~= nil then
			_msg = string.format(self.traceTitle .. "Range Control frequency = %.3f for %s.", rangeData.rangeControlFrequency, rangeData.rangeName)
			BASE:T(_msg)
		end

		-- Start the Range
		range:Start()
	end
end

--- END STATIC RANGES  
--------------------------------[core\activeranges.lua]-------------------------------- 
 
env.info( "[JTF-1] activeranges.lua" )
--
-- Creates dynamic ranges using group objects with names prefixed with ""ACTIVE_"
-- each object acts as a template and MUST be set to LATE ACTIVATED in the Mission Editor
--
-- Two files are used by this module;
--     activeranges.lua
--     activeranges_data.lua
--
-- 1. activeranges.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. activeranges_data.lua
-- Contains settings that are specific to the miz.
-- Optional. If not use, uncomment ACTIVERANGES:Start() at the end of this file.
-- If used, ACTIVERANGES:Start() in this file MUST be commented out.
--
-- For custom settings to be used, load order in miz MUST be;
--     1. activeranges.lua
--     2. activeranges_data.lua
--
-- If the activeranges_data.lua is not used the defaults in activeranges.lua will be used.
--

ACTIVERANGES = {}

ACTIVERANGES = BASE:Inherit(ACTIVERANGES, BASE:New())

ACTIVERANGES.traceTitle = "[JTF-1 ACTIVERANGES] "
ACTIVERANGES.version = "0.1"
ACTIVERANGES.ClassName = "ACTIVERANGES"


ACTIVERANGES.default = {
  rangeRadio = "377.8",
  useSRS = true,
}
local _msg
local useSRS

ACTIVERANGES.menu = {}
--ACTIVERANGES.rangeRadio = "377.8"
ACTIVERANGES.menu.menuTop = MENU_COALITION:New(coalition.side.BLUE, "Active Ranges")
ACTIVERANGES.spawnatstart = true -- default to spawn targets at mission start
ACTIVERANGES.activeatstart = false -- default to inactive AI if spawned at mission start
  
function ACTIVERANGES:Start()	
	_msg = "[JTF-1 ACTIVERANGES] Start()."
	self:T(_msg)
	self.rangeRadio = self.rangeRadio or self.default.rangeRadio
	self.SetInitActiveRangeGroups = SET_GROUP:New():FilterPrefixes("ACTIVE_"):FilterOnce() -- create list of group objects with prefix "ACTIVE_"
	self.SetInitActiveRangeGroups:ForEachGroup(
	function(group)
		if ACTIVERANGES.spawnatstart then
			ACTIVERANGES:initActiveRange(group, ACTIVERANGES.activeatstart) -- [group] group object for target, [true/false] refresh or create
		end
	end
	)
end

--- Spawn ACTIVE range groups.
-- @function initActiveRange
-- @param #table rangeTemplateGroup Target spawn template GROUP object
-- @param #string refreshRange If false, turn off target AI and add menu option to activate the target
function ACTIVERANGES:initActiveRange(rangeTemplateGroup, refreshRange)
	local initGroupName = rangeTemplateGroup:GetName()
	_msg = string.format("%sinitActiveRange %s.", 
		self.traceTitle,
		initGroupName
	)
	self:T({_msg, initGroupName, refreshRange})
	local rangeTemplate = rangeTemplateGroup.GroupName
	local activeRange = SPAWN:New(rangeTemplate)
	if refreshRange == false then 
		activeRange:InitAIOnOff(false) -- turn off AI if we're not resfreshing an already active target
	end
	activeRange:OnSpawnGroup(
		function (spawnGroup)
			local rangeName = spawnGroup:GetName()
			local rangePrefix = string.sub(rangeName, 8, 12)
			if refreshRange == false then
				ACTIVERANGES:addActiveRangeMenu(spawnGroup, rangePrefix)
			end
		end
		, refreshRange 
	)

	local rangeGroup = activeRange:Spawn()

	--local rangeGroup = activeRange:GetLastAliveGroup()
	rangeGroup:OptionROE(ENUMS.ROE.WeaponHold)
	rangeGroup:OptionROTEvadeFire()
	rangeGroup:OptionAlarmStateGreen()
	rangeGroup:SetAIOnOff(false)
	return rangeGroup
end

--- Add menus for range target.
-- @function addActiveRangeMenu
-- @param #table rangeGroup Target group object
-- @param #string rangePrefix Range prefix
function ACTIVERANGES:addActiveRangeMenu(rangeGroup, rangePrefix)
	_msg = string.format("%saddActiveRangeMenu %s.", 
		self.traceTitle, 
		rangePrefix
	)
	self:T(_msg)
	local rangeIdent = string.sub(rangePrefix, 1, 2)
	if ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent] == nil then
		ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent] = MENU_COALITION:New(coalition.side.BLUE, "R" .. rangeIdent, ACTIVERANGES.menu.menuTop)
	end
	ACTIVERANGES.menu["rangeMenu_" .. rangePrefix] = MENU_COALITION:New(coalition.side.BLUE, rangePrefix, ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent])
	MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], ACTIVERANGES.activateRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], false )
	local samTemplate = "SAM_" .. rangePrefix
	if GROUP:FindByName(samTemplate) ~= nil then
		MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix .. " with SAM" , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], ACTIVERANGES.activateRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], true )
	end
	return ACTIVERANGES.menu["rangeMenu_" .. rangePrefix]
end

--- Activate selected range target.
-- @function activateRangeTarget
-- @param #table rangeGroup Target GROUP object.
-- @param #string rangePrefix Range name prefix.
-- @param #table rangeMenu Menu that should be removed and/or to which sub-menus should be added
-- @param #boolean withSam Spawn and activate associated SAM target
-- @param #boolean refreshRange True if target is to being refreshed. False if it is being deactivated.
function ACTIVERANGES:activateRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)
	_msg = string.format("%sactivateRangeTarget %s.", 
		self.traceTitle, 
		rangePrefix
	)
	self:T(_msg)
	local deactivateText = "Deactivate " .. rangePrefix
	local refreshText = "Refresh " .. rangePrefix
	local samTemplate = "SAM_" .. rangePrefix
	local menuName = "rangeMenu_" .. rangePrefix

	if refreshRange == nil then
		rangeMenu:Remove()
		_msg = string.format("%sRemove menu %s", self.traceTitle, menuName)
		self:T(_msg)
		ACTIVERANGES.menu[menuName] = MENU_COALITION:New(coalition.side.BLUE, "Reset " .. rangePrefix, ACTIVERANGES.menu.menuTop)
	end

	rangeGroup:OptionROE(ENUMS.ROE.WeaponFree)
	rangeGroup:OptionROTEvadeFire()
	rangeGroup:OptionAlarmStateRed()
	rangeGroup:SetAIOnOff(true)

	if withSam then
		local activateSam = SPAWN:New(samTemplate)
		activateSam:OnSpawnGroup(
			function (spawnGroup)
			MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , ACTIVERANGES.menu[menuName], ACTIVERANGES.resetRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu[menuName], spawnGroup, false)
			MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " with SAM" , ACTIVERANGES.menu[menuName], ACTIVERANGES.resetRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu[menuName], spawnGroup, true)
			local msg = "All players, dynamic target " .. rangePrefix .. " is active, with SAM."
			if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
				MISSIONSRS:SendRadio(msg, ACTIVERANGES.rangeRadio)
			else -- otherwise, send in-game text message
				MESSAGE:New(msg):ToAll()
			end
			--MESSAGE:New("Target " .. rangePrefix .. " is active, with SAM."):ToAll()
			spawnGroup:OptionROE(ENUMS.ROE.WeaponFree)
			spawnGroup:OptionROTEvadeFire()
			spawnGroup:OptionAlarmStateRed()
			end
			, rangeGroup, rangePrefix, rangeMenu, withSam, deactivateText, refreshText
		)
	:Spawn()
	else
		MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , ACTIVERANGES.menu[menuName], ACTIVERANGES.resetRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu[menuName], withSam, false)
	if GROUP:FindByName(samTemplate) ~= nil then
		MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " NO SAM" , ACTIVERANGES.menu[menuName], ACTIVERANGES.resetRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu[menuName], withSam, true)
	else
		MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText , ACTIVERANGES.menu[menuName], ACTIVERANGES.resetRangeTarget, ACTIVERANGES, rangeGroup, rangePrefix, ACTIVERANGES.menu[menuName], withSam, true)
	end
	local msg = "All players, dynamic target " .. rangePrefix .. " is active."
	if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
		MISSIONSRS:SendRadio(msg, ACTIVERANGES.rangeRadio)
	else -- otherwise, send in-game text message
		MESSAGE:New(msg):ToAll()
	end
	-- MESSAGE:New("Target " .. rangePrefix .. " is active."):ToAll()
	end
end

--- Deactivate or refresh target group and associated SAM
-- @function resetRangeTarget
-- @param #table rangeGroup Target GROUP object.
-- @param #string rangePrefix Range nname prefix.
-- @param #table rangeMenu Parent menu to which submenus should be added.
-- @param #bool withSam Find and destroy associated SAM group.
-- @param #bool refreshRange True if target is to be refreshed. False if it is to be deactivated. 
function ACTIVERANGES:resetRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)
	_msg = string.format("%sresetRangeTarget %s.", 
		self.traceTitle, 
		rangePrefix
	)
	self:T(_msg)
	local rangeName  = "ACTIVE_" .. rangePrefix
	if rangeGroup:IsActive() then
		rangeGroup:Destroy(false)
		if withSam then
			withSam:Destroy(false)
		end
		if refreshRange == false then
			rangeMenu:Remove()
			local reactivateRangeGroup = self:initActiveRange(GROUP:FindByName(rangeName), false )
			reactivateRangeGroup:OptionROE(ENUMS.ROE.WeaponHold)
			reactivateRangeGroup:OptionROTEvadeFire()
			reactivateRangeGroup:OptionAlarmStateGreen()
			local msg = "All players, Target " .. rangePrefix .. " has been deactivated."
			if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
				MISSIONSRS:SendRadio(msg, ACTIVERANGES.rangeRadio)
			else -- otherwise, send in-game text message
				MESSAGE:New(msg):ToAll()
			end
			--MESSAGE:New("Target " .. rangePrefix .. " has been deactivated."):ToAll()
		else
			local refreshRangeGroup = self:initActiveRange(GROUP:FindByName(rangeName), true)
			self:activateRangeTarget(refreshRangeGroup, rangePrefix, rangeMenu, withSam, true)      
		end
		local zoneName = "ACTIVE_"
		self:removeJunk(rangeName)
	end
end

function ACTIVERANGES:removeJunk(_zoneName)
	_msg = string.format("%sremoveJunk for zone %s.", 
		self.traceTitle, 
		_zoneName
	)
	self:T(_msg)

	if _zoneName then
		if ZONE:FindByName(_zoneName) then
			local cleanup = trigger.misc.getZone(_zoneName)
			cleanup.point.y = land.getHeight({x = cleanup.point.x, y = cleanup.point.z})
			local volS = {
				id = world.VolumeType.SPHERE,
				params= {
					point = cleanup.point,
					radius = cleanup.radius
				}
			}
			world.removeJunk(volS)
		else
			_msg = string.format("%sError! Zone %s cannot be found.",
				self.traceTitle,
				_zoneName
			)
			self:E(_msg)
		end
	else
		_msg = string.format("%sError! No zone defined for cleanup.",
			self.traceTitle
		)
		self:E(_msg)
	end

end

ACTIVERANGES:Start()

--- END ACTIVE RANGES  
--------------------------------[core\missiletrainer.lua]-------------------------------- 
 
env.info( "[JTF-1] missiletrainer.lua" )
--
-- Tracks and destroys missiles fired at the player, if activated from F10 menu
--
-- Two files are used by this module;
--     missiletrainer.lua
--     missiletrainer_data.lua
--
-- 1. missiletrainer.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. missiletrainer_data.lua
-- Contains settings that are specific to the miz.
-- Optional. If NOT used, uncomment MTRAINER:Start() at the end of this file.
-- If used, MTRAINER:Start() in this file MUST be commented out.
--
-- Load order in miz MUST be;
--     1. missiletrainer.lua
--     2. missiletrainer_data.lua
--
-- Settings in missiletrainer_data.lua will override the defaults in the core file.
--

-- Create MTRAINER container and defaults
MTRAINER = {
  menuadded = {},
  MenuF10   = {},
  safeZone = nil, -- safezone to use, otherwise nil --"ZONE_FOX"
  launchZone = nil, -- launchzone to use, otherwise nil --"ZONE_FOX"
  DefaultLaunchAlerts = false,
  DefaultMissileDestruction = false,
  DefaultLaunchMarks = false,
  ExplosionDistance = 300,
  useSRS = true,
}

local _msg

function MTRAINER:Start()
	_msg = "[JTF-1 MTRAINER] Start()."
	BASE:T(_msg)

	MTRAINER = BASE:Inherit(MTRAINER, BASE:New())

	-- add event handlers
	-- MTRAINER.eventHandler = EVENTHANDLER:New()
	MTRAINER:HandleEvent(EVENTS.PlayerEnterAircraft) -- trap player entering a slot
	MTRAINER:HandleEvent(EVENTS.PlayerLeaveUnit) -- trap player leaving a slot
	
	-- set whether module should use SRS to send radio messages
	self.useSRS = (JTF1.useSRS and self.useSRS) and MISSIONSRS.Radio.active -- default to not using SRS unless both the server AND the module request it AND MISSIONSRS.Radio.active is true
	BASE:I({"[JTF-1 MTRAINER] useSRS", self.useSRS})

	-- add new FOX class to the Missile Trainer
	MTRAINER.fox = FOX:New()

	--- FOX Default Settings
	MTRAINER.fox:SetDefaultLaunchAlerts(MTRAINER.DefaultLaunchAlerts)
	MTRAINER.fox:SetDefaultMissileDestruction(MTRAINER.DefaultMissileDestruction)
	MTRAINER.fox:SetDefaultLaunchMarks(MTRAINER.DefaultLaunchMarks)
	MTRAINER.fox:SetExplosionDistance(MTRAINER.ExplosionDistance)
	MTRAINER.fox:SetDebugOnOff()
	MTRAINER.fox:SetDisableF10Menu()

	-- zone in which players will be protected
	if MTRAINER.safeZone then
		MTRAINER.fox:AddSafeZone(ZONE:New(MTRAINER.safeZone))
	end

	-- zone in which launches will be tracked
	if MTRAINER.launchZone then
		MTRAINER.fox:AddLaunchZone(ZONE:New(MTRAINER.launchZone))
	end

	-- start the missile trainer
	MTRAINER.fox:Start()

end

-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function MTRAINER:OnEventPlayerEnterAircraft(EventData)
	_msg = "[JTF-1 MTRAINER] OnEventPlayerEnterAircraft()."
	BASE:T(_msg)

	local unitname = EventData.IniUnitName
	local unit, playerName = MTRAINER:GetPlayerUnitAndName(unitname)
	if unit and playerName then
		SCHEDULER:New(nil, MTRAINER.AddMenu, {MTRAINER, unitname, true},0.1)
	end
end

-- check player is present and unit is alive
function MTRAINER:GetPlayerUnitAndName(unitname)
	_msg = "[JTF-1 MTRAINER] GetPlayerUnitAndName()."
	BASE:T(_msg)
	
	if unitname ~= nil then
		local DCSunit = Unit.getByName(unitname)
		if DCSunit then
			local playerName=DCSunit:getPlayerName()
			local unit = UNIT:Find(DCSunit)
			if DCSunit and unit and playerName then
				return unit, playerName
			end
		end
	end
	-- Return nil if we could not find a player.
	return nil,nil
end

--- Add Missile Trainer for GROUP|UNIT in F10 root menu.
-- @param #string unitname Name of unit occupied by client
function MTRAINER:AddMenu(unitname)
	_msg = "[JTF-1 MTRAINER] AddMenu()"
	BASE:T(_msg)

	local unit, playerName = self:GetPlayerUnitAndName(unitname)
	if unit and playerName then
		local group = unit:GetGroup()
		local gid = group:GetID()
		local uid = unit:GetID()
		if group and gid then
			-- only add menu once!
			if MTRAINER.menuadded[uid] == nil then
				-- add GROUP menu if not already present
				if MTRAINER.MenuF10[gid] == nil then
					BASE:T("[JTF-1 MTRAINER] Adding menu for group: " .. group:GetName())
					MTRAINER.MenuF10[gid] = MENU_GROUP:New(group, "Missile Trainer")
				end
				if MTRAINER.MenuF10[gid][uid] == nil then
					BASE:T("[JTF-1 MTRAINER] Add submenu for player: " .. playerName)
					MTRAINER.MenuF10[gid][uid] = MENU_GROUP:New(group, playerName, MTRAINER.MenuF10[gid])
					BASE:T("[JTF-1 MTRAINER] Add commands for player: " .. playerName)
					MENU_GROUP_COMMAND:New(group, "Missile Trainer On/Off", MTRAINER.MenuF10[gid][uid], MTRAINER.ToggleTrainer, MTRAINER, unitname)
					MENU_GROUP_COMMAND:New(group, "My Status", MTRAINER.MenuF10[gid][uid], MTRAINER.fox._MyStatus, MTRAINER.fox, unitname)
				end
				MTRAINER.menuadded[uid] = true
			end
		else
			BASE:T(string.format("[JTF-1 MTRAINER] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
		end
	else
		BASE:T(string.format("[JTF-1 MTRAINER] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
	end
end

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #string unitname name of client unit
function MTRAINER:ToggleTrainer(unitname)
	_msg = "[JTF-1 MTRAINER] ToggleTrainer()"
	BASE:T(_msg)

	self.fox:_ToggleLaunchAlert(unitname)
	self.fox:_ToggleDestroyMissiles(unitname)
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function MTRAINER:OnEventPlayerLeaveUnit(EventData)
	_msg = "[JTF-1 MTRAINER] OnEventPlayerLeaveUnit()"
	BASE:T(_msg)

	local playerName = EventData.IniPlayerName
	local unit = EventData.IniUnit
	local gid = EventData.IniGroup:GetID()
	local uid = EventData.IniUnit:GetID()
	local unitName = unit:GetName()
	if gid and uid then
		_msg = string.format("[JTF-1 MTRAINER] %s left unit: %s with UID: %s", playerName,  unitName, uid)
		BASE:T(_msg)
		if MTRAINER.MenuF10[gid] then
			_msg = string.format("[JTF-1 MTRAINER] Removing menu for unit UID: %s", uid)
			BASE:T(_msg)
			MTRAINER.MenuF10[gid][uid]:Remove()
			MTRAINER.MenuF10[gid][uid] = nil
			MTRAINER.menuadded[uid] = nil
		end
	end
end

-- MTRAINER:Start() -- uncomment if module is used without missiletrainer_data.lua

--- END MISSILE TRAINER  
--------------------------------[core\markspawn.lua]-------------------------------- 
 
env.info( "[JTF-1] markspawn" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MARK SPAWN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Sourced from Virtual 57th and refactored for JTF-1
--
--
-- **NOTE**: MARKSPAWN_TEMPLATES.LUA MUST BE LOADED AFTER THIS FILE IS LOADED!
--
-- This file contains functions and key values and should be loaded first.
-- The file markspawn_templates.lua contains the built-in templates used for spawning assets.
--
-- If MARKSPAWN_DATA.LUA is used it should be loaded after MARKSPAWN.LUA and 
-- MARKSPAWN_TEMPLATES.LUA and the call to MARKSPAWN:Start() at the end of the templates
-- file should be commented out.
--
-- Load order in miz MUST be;
--     1. markspawn.lua
--     2. markspawn_templates.lua
--     3. [OPTIONAL] markspawn_data.lua
--
-- Use F10 map marks to spawn BVR opponents or ground threats anywhere on the map. 
-- Add mark to map then type the CMD syntax below in the map mark text field. 
-- The command will execute on mouse-clicking out of the text box.
--
-- COMMANDS
-- ========
-- 
-- - ASPAWN: = Spawn Air Group
-- - GSPAWN: = Spawn Ground Group
-- - NSPAWN: = Spawn Navy Group
-- - WXREPORT: = display message with weather conditions
-- - DELETE: = Delete one, or more, Group(s)
-- 
-- Airspawn syntax
-- ---------------
-- 
-- CMD ASPAWN: [type][, [option]: [value]][...]
-- 
-- 
-- Airspawn Types
-- --------------
-- 
-- - F4
-- - SU25
-- - SU27
-- - MIG29
-- - SU25
-- - MIG23
-- - F16
-- - F18
-- - F16SEAD
-- - F18SEAD
-- - OPTIONS	(will list the types available for this command)
-- 
-- 
-- Airspawn Options
-- ----------------
-- 
-- - HDG: [degrees] - default 000
-- - ALT: [flight level] - default 280 (28,000ft)
-- - DIST:[nm] - default 0 (spawn on mark point)
-- - NUM: [1-4] - default 1
-- - SPD: [knots] - default 425
-- - SKILL: [AVERAGE, GOOD, HIGH, EXCELLENT, RANDOM] - default AVERAGE
-- - TASK: [CAP] - default NOTHING
-- - SIDE: [RED, BLUE, NEUTRAL] - default RED (Russia)
-- 
-- 
-- Example
-- -------
-- 
-- CMD ASPAWN: MIG29, NUM: 2, HDG: 180, SKILL: GOOD
-- 
-- Will spawn 2x MiG29 at the default speed of 425 knots, with heading 180 and skill level GOOD.
-- 
-- 
-- Groundspawn Syntax
-- ------------------
-- 
-- CMD GSPAWN: [groundspawn type][, [option]: [value]][...]
-- 
-- 
-- Groundspawn Types
-- -----------------
-- 
-- - SA2		(battery)
-- - SA3		{battery)
-- - SA6		(battery)
-- - SA8		(single)
-- - SA10		(battery)
-- - SA11		(battery)
-- - SA15		(single)
-- - SA19		(single)
-- - ZSU23		(ZSU23 Shilka)
-- - ZU23EMP	(ZU23 fixed emplacement)
-- - ZU23URAL	(ZU23 mounted on Ural)
-- - CONLIGHT      (Supply convoy)
-- - CONHEAVY	(Armoured convoy) 
-- - OPTIONS	(will list the types available for this command)
-- 
-- 
-- Groundspawn Options
-- ----------------
-- 
-- - ALERT: [GREEN, AUTO, RED] - default RED 
-- - SKILL: [AVERAGE, GOOD, HIGH, EXCELLENT, RANDOM] - default AVERAGE
-- 
-- 
-- Example
-- -------
-- 
-- CMD GSPAWN: SA6, ALERT: GREEN, SKILL: HIGH
-- 
-- Will spawn an SA6 Battery on the location of the map mark, in alert state GREEN and with skill level HIGH.
-- 
-- 
-- Weather Report Syntax
-- ---------------------
-- 
-- CMD WXREPORT: [QFE, METRIC]
-- 
-- 
-- Weather Report Options
-- ----------------------
-- 
-- - QFE   (Pressure displayed as QFE) - default QNH
-- - METRIC  (Produces the report in Metric format (mp/s, hPa) - default Imperial
-- 
-- 
-- Example
-- -------
-- 
-- CMD WXREPORT:
-- 
-- Will report Wind in knots, QNH in inHg, temperature in centigrade at the mark's position
-- 
-- CMD WXREPORT: QFE
-- 
-- Will report wind in knots, QFE in inHg, temperature in centigrade at the mark's position
-- 
-- 
-- Delete Spawn Syntax
-- -------------------
-- 
-- CMD DELETE: [object] [object option[s]]
-- 
-- 
-- Delete Spawn Objects
-- --------------------
-- 
-- - GROUP [requires name of Command Spawned Group in F10 map]
-- - KIND [requires option CAT and/or TYPE and/or ROLE] [SIDE]
-- - AREA  [Zone radius defined by RAD option] [CAT, TYPE, ROLE, SIDE]
-- - NEAREST [CAT, TYPE, ROLE, SIDE]
-- - ALL
-- 
-- 
-- Delete Spawn Options
-- --------------------
-- 
-- - CAT: [AIR, GROUND] - default ALL
-- - TYPE: [the spawned object Type] - default ALL
-- - ROLE: [CAS, SEAD, SAM, AAA, CVY] - default ALL
-- - SIDE: [RED, BLUE, NEUTRAL, ALL] - default RED
-- - RAD: [radius from mark in NM] - default 5NM
-- 
-- 
-- Example
-- -------
-- 
-- CMD DELETE: GROUP MIG29#001 
-- 
-- - Will remove the spawned group named MIG29#001
-- 
-- CMD DELETE: KIND TYPE: SA15
-- 
-- - will remove all SA15 groups
-- 
-- CMD DELETE: KIND ROLE: SAM
-- 
-- - will remove all groups with the SAM role
-- 
-- CMD DELETE: AREA TYPE: SA8
-- 
-- - will remove all SA8 groups within 5NM of mark
-- 
-- CMD DELETE: AREA RAD: 1 ROLE: SAM SIDE: ALL
-- 
-- - will remove all groups within 5NM of the mark, with the SAM role, on Red, Blue and Neutral sides 
-- 
-- 
-- Cut-n-Paste Command Examples
-- ----------------------------
-- 
-- CMD GSPAWN: SA8, ALERT: RED, SKILL: HIGH
-- 
-- CMD GSPAWN: SA15, ALERT: RED, SKILL: HIGH
-- 
-- CMD ASPAWN: MIG29, NUM: 2, HDG: 90, SKILL: GOOD, ALT: 280, TASK: CAP, SIDE: RED
--
-- CMD DELETE: GROUP MIG29A#001
--
-- TASK TYPES
-- ----------
-- CAP, REFUELING, CAS, SEAD, TASMO, AWACS, AFAC
--


MARKSPAWN = {}
-- inherit methods,  properties etc from BASE for event handler, trace etc
MARKSPAWN = BASE:Inherit( MARKSPAWN, BASE:New() )

MARKSPAWN.traceTitle = "[JTF-1] "
MARKSPAWN.version = "1.0"
MARKSPAWN.ClassName = "MARKSPAWN"

--MARKSPAWN.MLTgtArray = {}
MARKSPAWN.radioPresets = {}
MARKSPAWN.MLSpawnedGroups = {}
--MARKSPAWN.templates = {}

MARKSPAWN.default = {
	-- DEFAULT VALUES
	DEFAULT_BLUE_COUNTRY = 2, -- USA
	DEFAULT_RED_COUNTRY = 0, -- RUSSIA
	DEFAULT_NEUTRAL_COUNTRY = 7, -- USAF AGRRESSORS
	MLDefaultAirAlt = 200, -- altitude Flight Level
	MLDefaultHdg = 000,
	MLDefaultSkill = "AVERAGE",
	MLDefaultDistance = 0,
	MLDefaultGroundDistance = 0,
	MLDefaultROE = "FREE",
	MLDefaultROT = "EVADE",
	MLDefaultFreq = 251,
	MLDefaultNum = 1,
	MLDefaultAirSpeed = 425,
	MLDefaultGroundSpeed = 21,
	MLDefaultAlert = "RED",
	MLDefaultGroundTask = "NOTHING",
}

-- SPAWNABLE GROUP TYPES
MARKSPAWN.spawnTypes = { -- types available for spawning
	------------------------ BVR ------------------------
    { template = "BVR_MIG23",  	msType = "MIG23",   	category = "air",     role = "CAP"},
    { template = "BVR_SU25",   	msType = "SU25",    	category = "air",     role = "CAP"},
    { template = "BVR_MIG29A", 	msType = "MIG29",   	category = "air",     role = "CAP"},
    { template = "BVR_SU27",   	msType = "SU27",    	category = "air",     role = "CAP"},
    { template = "BVR_F4",     	msType = "F4",      	category = "air",     role = "CAP"},
    { template = "BVR_F16",    	msType = "F16",     	category = "air",     role = "CAP"},
    { template = "BVR_F18",    	msType = "F18",     	category = "air",     role = "CAP"},
    ------------------------ CAS ------------------------
    { template = "CAS_MQ9",    	msType = "MQ9",     	category = "air",     role = "CAS"},
    { template = "CAS_WINGLOON",msType = "WINGLOON",    category = "air",     role = "CAS"},
    ------------------------ SEAD ------------------------
	{ template = "SEAD_F16",    msType = "F16SEAD",	category = "air",     role = "SEAD"},
	{ template = "SEAD_F18",    msType = "F18SEAD",	category = "air",     role = "SEAD"},
	------------------------ SAM ------------------------
    { template = "SA2",    		msType = "SA2",	  		category = "ground",  role = "SAM"},
    { template = "SA3",    		msType = "SA3",	  		category = "ground",  role = "SAM"},
    { template = "SA6",    		msType = "SA6",	  		category = "ground",  role = "SAM"},
    { template = "SA8",    		msType = "SA8", 		category = "ground",  role = "SAM"},
    { template = "SA10",   		msType = "SA10", 		category = "ground",  role = "SAM"},
    { template = "SA11",   		msType = "SA11", 		category = "ground",  role = "SAM"},
    { template = "SA15",   		msType = "SA15", 		category = "ground",  role = "SAM"},
    { template = "SA19",   		msType = "SA19", 		category = "ground",  role = "SAM"},
	------------------------ AAA ------------------------
    { template = "ZSU23_Shilka",msType = "ZSU23",		category = "ground",  role = "AAA"},
    { template = "ZU23_Emp",	msType = "ZU23EMP",		category = "ground",  role = "AAA"},
    { template = "ZU23_Ural",	msType = "ZU23URAL",	category = "ground",  role = "AAA"},
    { template = "ZU23_Closed",	msType = "ZU23CLOSED",	category = "ground",  role = "AAA"},
	------------------------ CONVOY ------------------------
    { template = "CON_light",	msType = "CONLIGHT",	category = "ground",  role = "CON"},
    { template = "CON_heavy",	msType = "CONHEAVY",	category = "ground",  role = "CON"},
	------------------------ ARTILLERY ------------------------
	------------------------ INFANTRY ------------------------
	------------------------ SHIP ------------------------
}

-----------------
-- START MARKSPAWN
-----------------

function MARKSPAWN:Start()
	_msg = string.format("%sVERSION %s", self.traceTitle, self.version)
	self:T(_msg)

	-----------------
	-- ADD SPAWNS
	-----------------

	-- Add SPAWN objects to each template
	-- Spawn Late Activated groups using built-in templates if the template group is not
	-- being sourrced from in the mission itself

	for index, spawnType in ipairs(self.spawnTypes) do
		local templateName = spawnType.template
		local spawnAlias = "MS_" .. templateName

		-- if a late activated group is present in the mission, use that as a spawn template
		if GROUP:FindByName(templateName) then
			_msg = string.format("%sSpawn Template %s found in mission.",
				self.traceTitle,
				templateName
			)
			self:T(_msg)

			spawnType.spawn = SPAWN:NewWithAlias(templateName, spawnAlias)

		-- if a late activated group is NOT found in the mission, look for a built-in template
		else 

			local spawnTemplate
	
			-- look in MARKSPAWN templates
			if SPAWNTEMPLATES.templates[templateName] then
				_msg = string.format("%sUse spawn template from SPAWNTEMPLATES.templates for %s.",
					self.traceTitle,
					templateName
				)
				self:T(_msg)

				spawnTemplate = SPAWNTEMPLATES.templates[templateName]
			end

			-- If we have a template, generate the SPAWN object
			if spawnTemplate ~= nil then
				_msg = string.format("%sSpawn Group and use as SPAWN for type %s.",
					self.traceTitle,
					templateName
				)
				self:T(_msg)

				local spawnCategory =  spawnTemplate.category
				local spawnCoordinate = COORDINATE:New(0,0,0)
				local spawnCountryid = self.default.DEFAULT_RED_COUNTRY
				local spawnCoalition = coalition.side.RED

				-- add a late activated group to be used as the spawn template
				local spawn = SPAWN:NewFromTemplate(spawnTemplate, templateName, spawnAlias, true)
					:InitCountry(spawnCountryid)
					:InitCoalition(spawnCoalition)
					:InitCategory(spawnCategory)
					--:InitPositionCoordinate(spawnCoordinate)
					:InitLateActivated()
				
				spawn:OnSpawnGroup(
					function(spawngroup)
						local groupName = spawngroup:GetName()
						spawnType.spawn = SPAWN:New(groupName)
					end
					,spawnType
				)
				spawn:Spawn()
			
			-- Template cannot be found in miz or SPAWNTEMPLATES.templates
			else
				_msg = string.format("%sError! Could not find template %s.",
					self.traceTitle,
					templateName
				)
				self:E(_msg)
			end
		end
	end

	-----------------
	-- MARK POINT EVENT HANDLER
	-----------------
	self:HandleEvent(EVENTS.MarkChange)
	
	-- IF MARK IS A "CMD", SEND MARK DATA TO PARSER
	function self:OnEventMarkChange( EventData )
		_msg = string.format("%sMARK CHANGE EVENT", self.traceTitle)
		self:T(_msg)
		local text = EventData.text
		local x, _ = string.find(text, "CMD")
		if(x ~= nil) then
			self:parseMark(EventData)
			self:MLRemoveMark(EventData.idx)
		else
			return
		end
	end
	
end

-----------------
-- CMD PARSER
-----------------

function MARKSPAWN:parseMark(mark)

	_msg = self.traceTitle
	self:T({_msg, text = mark.text, pos = mark.pos})

	local cmdOption = false
	local text = mark.text
	local pos = mark.pos

	-- Command Search patterns
	local cmdASPAWN = "ASPAWN:%s*(%w+)"
	local cmdGSPAWN = "GSPAWN:%s*(%w+)"
	local cmdNSPAWN = "NSPAWN:%s*(%w+)"
	local cmdRADIO = "RADIO:%s*(%w+)"
	local cmdWX = "WXREPORT:%s*(.*)"
	local cmdDELETE = "DELETE:%s*(%w+)"
	-- Option search patterns
	local optionOpt = "OPTIONS"
	local optionHdg = "HDG:%s*(%d+)"
	local optionAlt = "ALT:%s*(%d+)"
	local optionTask = "TASK:%s*(%w+)"
	local optionSkill = "SKILL:%s*(%w+)"
	local optionDist = "DIST:%s*(%d+)"
	local optionROE = "ROE:%s*(%w+)"
	local optionWPS = "WPS:%s*{(.*)}"
	local optionFreq = "FREQ:%s*(%d[%d.]+)"
	local optionBand = "BAND:%s*(%w+)"
	local optionPwr = "PWR:%s*(%d+)"
	local optionNum = "NUM:%s*(%d+)"
	local optionSpd = "SPD:%s*(%d+)"
	local optionSide = "SIDE:%s*(%w+)"
	local optionForm = "FORM:%s*(%w+)"
	local optionBase = "BASE:%s*(%w+)"
	local optionName = "NAME:%s*(%w+)"
	local optionROT = "ROT:%s*(%w+)"
	local optionAlert = "ALERT:%s*(%w+)"
	local optionTGT = "TGT:%s*(%w+)"
	-- Delete Class patterns
	local optionDelGrp = "GROUP%s*(.+)"
	-- Delete Option patterns
	local optionDelCat = "CAT:%s*(%w+)"
	local optionDelSide = "SIDE:%s*(%w+)"
	local optionDelRad = "RAD:%s*(%d+)"
	local optionDelType = "TYPE:%s*(%w+)"
	local optionDelRole = "ROLE:%s*(%w+)"

	-----------------
	-- CMD AIR GROUP
	-----------------

	local i, _, spawnValue = string.find(text, cmdASPAWN)
	if(i ~= nil) then
		cmdOption = true
		if(spawnValue:upper() == optionOpt) then
			self:MLListSpawnOptions("air", mark)
		else
			local _, _, heading = string.find(text, optionHdg)
			local _, _, altitude = string.find(text, optionAlt)
			local _, _, task = string.find(text,optionTask)
			local _, _, skill = string.find(text,optionSkill)
			local _, _, distance = string.find(text,optionDist)
			local _, _, ROE = string.find(text, optionROE)
			local _, _, WPS = string.find(text, optionWPS)
			local _, _, freq = string.find(text, optionFreq)
			local _, _, num = string.find(text, optionNum)
			local _, _, speed = string.find(text, optionSpd)
			local _, _, side = string.find(text, optionSide)
			local _, _, formation = string.find(text, optionForm)
			local _, _, base = string.find(text, optionBase)
			local _, _, groupName = string.find(text, optionName)
			local _, _, ROT = string.find(text, optionROT)

			local spawnTable = {
				msType = spawnValue,
				heading = heading,
				altitude = altitude,
				task = task, 
				skill = skill, 
				distance = distance, 
				roe = ROE, 
				WP = WPS, 
				pos = pos, 
				freq = freq, 
				num = num, 
				speed = speed,
				side = side, 
				formation = formation,
				base = base,
				groupName = groupName,
				rot = ROT,
			}

			self:MLAirSpawn(spawnTable)
		end
	end
	
	-----------------
	-- CMD GROUND GROUP
	-----------------

	local j, _, spawnValue = string.find(text, cmdGSPAWN)
	if(j ~= nil) then
		cmdOption = true
		if(spawnValue:upper() == optionOpt) then
			self:MLListSpawnOptions("ground", mark)
		else
			local _, _, heading = string.find(text, optionHdg)
			local _, _, skill = string.find(text,optionSkill)
			local _, _, distance = string.find(text,optionDist)
			local _, _, ROE = string.find(text, optionROE)
			local _, _, WP = string.find(text, optionWPS)
			local _, _, alert = string.find(text, optionAlert)
			local _, _, speed = string.find(text, optionSpd)
			local _, _, side = string.find(text, optionSide)
			local _, _, formation = string.find(text, optionForm)  
			local _, _, groupName = string.find(text, optionName)
			local _, _, tgtName = string.find(text, optionTGT)

			local spawnTable = {
				msType = spawnValue,
				heading = heading,
				skill = skill, 
				distance = distance, 
				roe = ROE, 
				WP = WP, 
				pos = pos,
				speed = speed,
				coalition = side,
				formation = formation,
				alert = alert,
				side = side,
				groupName = groupName,
				tgt = tgtName
			}

			self:MLGroundSpawn(spawnTable)
		end
	end
		
	-----------------
	-- CMD RADIO
	-----------------

	local k, _, spawnValue = string.find(text, cmdRADIO)
	if(k ~= nil) then
		cmdOption = true
		self:T("[JTF-1] SpawnValue: " .. spawnValue)
		self:T("[JTF-1] Other Text: " .. k)
		local _, _, freq = string.find(text, optionFreq)
		local _, _, band = string.find(text,optionBand)
		local _, _, power = string.find(text,optionPwr)
		
		local spawnTable = {
			song = spawnValue,
			freq = freq,
			band = band, 
			power = power, 
		}

		_msg = string.format("%sRADIO: ", self.traceTitle)
		self:T({"[JTF-1] RADIO: ", spawnTable})
		--self:MLRadioSpawn(spawnTable)
	end
	
	-----------------
	-- CMD NAVY GROUP
	-----------------

	--spawn a naval group
	local l, _, spawnValue = string.find(text, cmdNSPAWN)
	if(l ~= nil) then
		cmdOption = true
		if(spawnValue:upper() == optionOpt) then
		self:MLListSpawnOptions("naval", mark)
		else
		local _, _, heading = string.find(text, optionHdg)
		local _, _, skill = string.find(text,optionSkill)
		local _, _, distance = string.find(text,optionDist)
		local _, _, ROE = string.find(text, optionROE)
		local _, _, WP = string.find(text, optionWPS)
		local _, _, alert = string.find(text, optionAlert)
		local _, _, speed = string.find(text, optionSpd)
		local _, _, side = string.find(text, optionSide)
		local _, _, formation = string.find(text, optionForm)  
		local _, _, groupName = string.find(text, optionName)
		local _, _, tgtName = string.find(text, optionTGT)
		
		local spawnTable = {
			msType = spawnValue,
			heading = heading,
			skill = skill, 
			distance = distance, 
			roe = ROE, 
			WP = WP, 
			pos = pos,
			speed = speed,
			coalition = side,
			formation = formation,
			alert = alert,
			side = side,
			groupName = groupName,
			tgt = tgtName
		}

		self:T({"[JTF-1] NSPAWN: ", spawnTable})
		self:MLNavalSpawn(spawnTable)
		end
	end
	
	-----------------
	-- CMD DELETE GROUP
	-----------------

	--Delete one or more groups
	local l, _, deleteCMD = string.find(text, cmdDELETE)
	if(l ~= nil) then
		cmdOption = true
		local _, _, category = string.find(text, optionDelCat) -- "CAT (%w+)"
		local _, _, side = string.find(text,optionDelSide) -- "SIDE (%w+)"
		local _, _, radius = string.find(text,optionDelRad) -- "RAD (%d+)"
		local _, _, msType = string.find(text,optionDelType) -- "TYPE (%w+)"
		-- local _, _, template = string.find(text,optionDelType) -- "TYPE (%w+)"
		local _, _, groupName = string.find(text, optionDelGrp) -- "GROUP%s*(.+)"
		local _, _, role = string.find(text, optionDelRole) -- "ROLE (.+)"
		
		local spawnTable = {
			cmd = deleteCMD,
			category = category,
			side = side,
			radius = radius,
			msType = msType,
			groupName = groupName,
			role = role
		}

		self:MLDeleteGroup(spawnTable, mark)
	end

	-----------------
	-- CMD WX REPORT
	-----------------

	local m, _, repoString = string.find(text, cmdWX)
	if(m ~= nil) then
		cmdOption = true
		self:MLWxReport(repoString, mark)
	end

	if not cmdOption then
		self:E("[JTF-1] ERROR! CMD not found.")
	end

end
  
-----------------
-- SPAWN AIR GROUP(S)
-----------------

function MARKSPAWN:MLAirSpawn(SpawnTable)

	local msType = SpawnTable.msType
	local heading = tonumber(SpawnTable.heading) or self.default.MLDefaultHdg
	local altitude = tonumber(SpawnTable.altitude) or self.default.MLDefaultAirAlt
	altitude = UTILS.FeetToMeters(altitude * 100)
	local task = SpawnTable.task or "C"
	local skill = self:MLSkillCheck(SpawnTable.skill) or self.default.MLDefaultSkill
	local distance = tonumber(SpawnTable.distance) or self.default.MLDefaultDistance
	local ROE = SpawnTable.roe or self.default.MLDefaultROE
	local ROT = SpawnTable.rot or self.default.MLDefaultROT
	local freq = tonumber(SpawnTable.freq) or self.default.MLDefaultFreq
	local num = tonumber(SpawnTable.num) or self.default.MLDefaultNum
	local speed = tonumber(SpawnTable.speed) or self.default.MLDefaultAirSpeed
	local form = SpawnTable.formation or nil
	local base = SpawnTable.base or nil
	local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos):SetAltitude(altitude,true)
	local spawner = self:comparator(msType)
	local category = self:GetProperty(msType, "category")
	local role = self:GetProperty(msType, "role")

	if(spawner == nil) then
		return
	end

	local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
	local waypointNameString = SpawnTable.WP or nil
	
	-- switch country/coalition if desired
	local coal, country
	if(SpawnTable.side) then
		coal, country = self:MLSideComparator(SpawnTable.side, template)
	else
		coal = template:GetCoalition()
		country = template:GetCountry()
	end
	local group
	
	-- spawn the group
	if(base) then
		local airbase
		if(base == "NEAREST") then 
			self:T("[JTF-1] learn 2 spell, scrub")
			local theater = env.mission.theatre
			local distance = 0
		else
			airbase = AIRBASE:FindByName(base)
			if(airbase == nil) then 
				airbase = AIRBASE:GetAllAirbases()[1]
			end
		end
		group = spawner:InitGrouping(num):InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnAtAirbase(airbase,SPAWN.Takeoff.Cold,nil)
	else
		self:T("[JTF-1] ASPAWN: " .. coal .. " " .. country)
		group = spawner:InitGrouping(num):InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
		_groupName = group.GroupName
		self:T("[JTF-1] ASPAWN: " .. _groupName)
	end
	
	self.MLSpawnedGroups[#self.MLSpawnedGroups + 1] = {group = group, side = coal, msType = msType, category = category, role = role}
	-- set ROE
	self:MLSetROE(ROE,group)
	-- set ROT
	self:MLSetROT(ROT,group)
	--if no distance, then we orbit
	if(waypointNameString) then
		local waypointCoords = self:MLFindWaypoints(waypointNameString)
		if(#waypointCoords > 0) then
			self:T('[JTF-1] MORE WAYPOINTS')
			local route = {}
			route[#route + 1] = spawnCoord:WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
			for idx, waypoint in pairs(waypointCoords) do
				route[#route + 1] = waypoint:SetAltitude(altitude,true):WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
			end
			group:Route(route)
		else
			local orbitEndPoint = spawnCoord:Translate(UTILS.NMToMeters(15),heading)
			local orbit = { 
				id = 'Orbit', 
				params = { 
					pattern = AI.Task.OrbitPattern.RACE_TRACK,
					point = spawnCoord:GetVec2(),
					point2 = orbitEndPoint:GetVec2(),
					speed = UTILS.KnotsToMps(speed),
					altitude = altitude
				} 
			}

			group:SetTask( orbit, 2 )
		end
	elseif(distance == 0) then
		local orbitEndPoint = spawnCoord:Translate(UTILS.NMToMeters(15),heading)
		local orbit = { 
			id = 'Orbit', 
			params = { 
				pattern = AI.Task.OrbitPattern.RACE_TRACK,
				point = spawnCoord:GetVec2(),
				point2 = orbitEndPoint:GetVec2(),
				speed = UTILS.KnotsToMps(speed),
				altitude = altitude
			} 
		}

		group:SetTask( orbit, 2 )
	--if distance, we create a waypoint way the fuck out in the boonies
	elseif(distance > 0) then
		local WP1 = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
		:WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
		local WP2 = spawnCoord:Translate(UTILS.NMToMeters(distance),heading * 2)
		:WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
		
		local route = {WP1, WP2}
		group:Route(route)
	else
		self:T("[JTF-1] We Fucked Up")
	end
	local taskTable = {}
	if(task ~= "NOTHING") then
		taskTable = self:MLSetTask(task,group)
		group:PushTask ( group:TaskCombo( self:MLSetTask(task,group) ) , 3 )
	end
	--set group frequency
	if(freq) then
		if(freq <= 20) then
			freq = self:MLRadioPreset(freq)
		end
			self:T("[JTF-1] freq:".. freq)
			freq = freq * 1000000
			local SetFrequency = { 
			id = 'SetFrequency', 
			params = { 
				frequency = freq, 
				modulation = 0, 
			}
		}
		group:SetCommand(SetFrequency)
	end

 end

-----------------
-- SPAWN GROUND GROUP(S)
-----------------

function MARKSPAWN:MLGroundSpawn(SpawnTable)
	local msType = SpawnTable.msType
	local heading = tonumber(SpawnTable.heading) or self.default.MLDefaultHdg
	local task = SpawnTable.task or self.default.MLDefaultGroundTask
	local skill = self:MLSkillCheck(SpawnTable.skill) or self.default.MLDefaultSkill
	local distance = tonumber(SpawnTable.distance) or self.default.MLDefaultGroundDistance
	local ROE = SpawnTable.roe or self.default.MLDefaultROE
	local freq = tonumber(SpawnTable.freq) or self.default.MLDefaultFreq
	local speed = tonumber(SpawnTable.speed) or self.default.MLDefaultGroundSpeed 
	local form = SpawnTable.formation or nil
	local alert = SpawnTable.alert or self.default.MLDefaultAlert
	local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
	local spawner = self:comparator(msType)
	local category = self:GetProperty(msType, "category")
	local role = self:GetProperty(msType, "role")

	if(spawner == nil) then
		self:E("[JTF-1] ERROR! spawner not found in spawnOptions.")
		return
	end

	local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
	local waypointNameString = SpawnTable.WP or nil
	
	--local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
	local coal, country

	if(SpawnTable.side) then
		coal, country = self:MLSideComparator(SpawnTable.side, template)
	else
		coal = template:GetCoalition()
		country = template:GetCountry()
	end

	
	local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):SpawnFromVec3(spawnCoord:GetVec3())

	local _group = group.GroupName
	self:T("[JTF-1] GSPAWN: " .. _group)
	
	self.MLSpawnedGroups[#self.MLSpawnedGroups + 1] = {group = group, side = coal, msType = msType, category = category, role = role}
	
	self:MLSetROE(ROE,group)
	self:MLSetAlarm(alert,group)
	-- add waypoints
	--if no distance, then we orbit
	if(waypointNameString) then
		local waypointCoords = self:MLFindWaypoints(waypointNameString)
		self:T('MORE WAYPOINTS')
		local route = {}
		for idx, waypoint in pairs(waypointCoords) do
		route[#route + 1] = waypoint:WaypointGround(UTILS.KnotsToKmph(speed),form)
		end
		group:Route(route)
	elseif(distance > 0) then
		local WP = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
		group:RouteGroundTo(WP, speed, form, 1)
	end
end
  
-----------------
-- SPAWN NAVY GROUP(S)
-----------------

function MARKSPAWN:MLNavalSpawn(SpawnTable)
	local msType = SpawnTable.msType
	local heading = tonumber(SpawnTable.heading) or 000
	local task = SpawnTable.task or "NOTHING"
	local skill = self:MLSkillCheck(SpawnTable.skill) or "AVERAGE"
	local distance = tonumber(SpawnTable.distance) or 0
	local ROE = SpawnTable.roe or "FREE"
	local freq = tonumber(SpawnTable.freq) or 251
	local speed = tonumber(SpawnTable.speed) or 30
	local form = SpawnTable.formation or nil
	local alert = SpawnTable.alert or "AUTO"
	local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
	local spawner = self:comparator(msType)
	local category = self:GetProperty(msType, "category")
	local role = self:GetProperty(msType, "role")
	local tgt = nil
	if(spawner == nil) then
		return
	end
	local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
	local waypointNameString = SpawnTable.WP or nil
	
	local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
	local coal, country
	if(SpawnTable.side) then
		coal, country = self:MLSideComparator(SpawnTable.side, template)
	else
		coal = template:GetCoalition()
		country = template:GetCountry()
	end

	local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
	self.MLSpawnedGroups[#self.MLSpawnedGroups + 1] = {group = group, side = coal, msType = msType, category = category, role = role}

	self:MLSetROE(ROE,group)
	--MLSetAlarm(alert,group)
	-- LETS DO WAYPOINTS YE JAMMY FOOKERS!
	--if no distance, then we orbit
	if(waypointNameString) then
		local waypointCoords = self:MLFindWaypoints(waypointNameString)
		self:T('MORE WAYPOINTS')
		local route = {}
		for idx, waypoint in pairs(waypointCoords) do
		route[#route + 1] = waypoint:WaypointGround(UTILS.KnotsToKmph(speed),nil)
		end
		group:Route(route)
	elseif(distance >= 0) then
		local WP = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
		group:RouteGroundTo(WP, speed, nil, 1)
	end
end
  
-----------------
-- DELETE SPAWN GROUP
-----------------

function MARKSPAWN:MLDeleteGroup(spawnTable,mark)

	local deleteCMD = spawnTable.cmd:upper()
	
	self:T(self.traceTitle .. " DELETE: " .. deleteCMD)

	local tblProperties = {}

	local coal = spawnTable.side or "RED"
	coal = coal:upper()
	local category = spawnTable.category or "ALL"
	category = category:upper()
	local msType = spawnTable.msType or "ALL"
	msType = msType:upper()
	local role = spawnTable.role or "ALL"
	role = role:upper()


	local radius =  spawnTable.radius or 5
	radius = UTILS.NMToMeters(radius)

	local template = spawnTable.template or nil

	if template then
		template = template:upper()
	end
	
	if (coal == "BLUE") then 
		coal = 2 
	elseif (coal == "NEUTRAL") then
		coal = 0 
	elseif (coal == "ALL") or (coal:upper() == "ANY") then
		coal = 99
	else -- default to RED
		coal = 1
	end
	
	_msg = string.format("%sDELETE - OPTIONS CMD: %s, SIDE: %s, TYPE: %s, CATEGORY: %s,  ROLE: %s, RADIUS: %d", 
		self.traceTitle,
		deleteCMD,
		tostring(coal or 99),
		(msType or "nil"),
		(category or "nil"),
		(role or "nil"),
		(radius or 0)
	)
	self:T(_msg)

	-- Delete by GROUP
	if(deleteCMD == "GROUP") then
		_msg = string.format("%sDELETE: Option GROUP.", self.traceTitle)
		self:T(_msg)

		local groupName = spawnTable.groupName 
		_msg = string.format("%sDELETE - groupName = %s", 
			self.traceTitle,
			(groupName or "nil")
		)
		self:T(_msg)

		local victim = GROUP:FindByName(groupName) or nil
		if victim then
			victim:Destroy(false)
		else
			self:T(self.traceTitle .. " DELETE -  GROUP not found!")
		end

	-- Delete by AREA
	elseif(deleteCMD == "AREA") then
		_msg = string.format("%sDELETE: Option RAD.", self.traceTitle)
		self:T(_msg)

		local deleteZone = ZONE_RADIUS:New("DeleteZone",COORDINATE:NewFromVec3(mark.pos):GetVec2(),radius)
		self:T({self.traceTitle .. " Marker Pos: ", mark.pos, " Zone Pos: ", deleteZone:GetVec2(), "Radius: ", deleteZone:GetRadius()})
		for idx, entry in pairs (self.MLSpawnedGroups) do
			if entry.group:IsAlive() then 

				local isCategory = (entry.category == category) or (category == "ALL")
				local isType = (entry.msType:upper() == msType) or (msType == "ALL")
				local isRole = (entry.role:upper() == role) or (role == "ALL")
				local isSide = (entry.side == coal) or (coal == 99)
				
				_msg = string.format("%sisCategory: %s, isType: %s, isRole: %s", 
					self.traceTitle,
					((isCategory and "True") or "False"),
					((isType and "True") or "False"),
					((isRole and "True") or "False"),
					((isSide and "True") or "False")
				)
				self:T(_msg)

				local groupPos = entry.group:GetVec2()
				local zoneVec2 = deleteZone:GetVec2()
				local isThere = ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5 <= tonumber(deleteZone:GetRadius())

				self:T(self.traceTitle .. " ZONE: " .. ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5)

				if(isThere) then
					self:T("self.traceTitle ..  Group in zone")
					if isType and (isCategory and isRole) then
						self:T(self.traceTitle .. " Type, Category and Role correct")
						self:T(self.traceTitle .. " Function Side: " .. coal .. "Group Side: " .. entry.side)
						if coal and ((entry.side == coal) or (coal == 99)) then
							self:T(self.traceTitle .. " Side correct")
							local victim = entry.group
							victim:Destroy(false)
							self.MLSpawnedGroups[idx] = nil
						end
					end
				else
					self:T(self.traceTitle .. " Group out of Zone")
				end
			else
				self:T(self.traceTitle .. " Group is not ALIVE")
				self.MLSpawnedGroups[idx] = nil
			end
		end
	
	-- Delete by NEAREST
	elseif(deleteCMD == "NEAREST") then
		_msg = string.format("%sDELETE: Option NEAREST.", self.traceTitle)
		self:T(_msg)

		local minDistance = -1
		local closest = 1
		local markPos = COORDINATE:NewFromVec3(mark.pos):GetVec2()

		if(self.MLSpawnedGroups[1].group:IsAlive()) then
			local groupPos = self.MLSpawnedGroups[1].group:GetVec2()
			minDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5

			_msg = string.format("%sGroup idx 1 is alive. Min dist = ", 
				self.traceTitle
			)
			self:T({_msg, minDistance})
			
			-- find nearest group that meets the required criteria
			for idx, entry in pairs (self.MLSpawnedGroups) do
				if entry.group:IsAlive() then

					local isCategory = (entry.category == category) or (category == "ALL")
					local isType = (entry.msType:upper() == msType) or (msType == "ALL")
					local isRole = (entry.role:upper() == role) or (role == "ALL")
					local isSide = (entry.side == coal) or (coal == 99)

					_msg = string.format("%sisCategory: %s, isType: %s, isRole: %s", 
						self.traceTitle,
						((isCategory and "True") or "False"),
						((isType and "True") or "False"),
						((isRole and "True") or "False"),
						((isSide and "True") or "False")
					)
					self:T(_msg)
					
					if isType and (isCategory and isRole) then
						if(coal and ((entry.side == coal) or coal == 99)) then
							local groupPos = entry.group:GetVec2()
							local currentDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5
							if(currentDistance < minDistance) then
								minDistance = currentDistance
								closest = idx
							end
						end
					end
				else
					self:T(self.traceTitle .. " Group is not ALIVE")
					self.MLSpawnedGroups[idx] = nil
				end
			end
			local closestEntry = self.MLSpawnedGroups[closest]

			local victim = closestEntry.group
			victim:Destroy(false)
			self.MLSpawnedGroups[closest] = nil

		end
	
	-- Delete by KIND
	elseif(deleteCMD == "KIND") then
		_msg = string.format("%sDELETE: Option TYPE.", self.traceTitle)
		self:T(_msg)

		if (category and msType) and role then
			_msg = string.format("%sDELETE: Filter Category, Type, Role.", self.traceTitle)
			self:T(_msg)
	
			for idx, entry in pairs (self.MLSpawnedGroups) do
				if entry.group:IsAlive() then
					_msg = string.format("%sentry.category: %s, cmd: %s, entry.msType: %s, cmd: %s, entry.role: %s, cmd: %s, entry.side: %s, cmd: %s", 
						self.traceTitle,
						(entry.category or "nil"),
						category,
						(entry.msType or "nil"),
						msType,
						(entry.role or "nil"),
						role,
						(entry.side or "nil"),
						tostring(coal)
					)
					self:T(_msg)

					local isCategory = (entry.category:upper() == category) or (category == "ALL")
					local isType = (entry.msType:upper() == msType) or (msType == "ALL")
					local isRole = (entry.role:upper() == role) or (role == "ALL")
					local isSide = (entry.side == coal) or (coal == 99)
					
					--_msg = string.format("%sCheck match", self.traceTitle)
					_msg = string.format("%sisCategory: %s, isType: %s, isRole: %s, isSide: %s", 
						self.traceTitle,
						((isCategory and "True") or "False"),
						((isType and "True") or "False"),
						((isRole and "True") or "False"),
						((isSide and "True") or "False")
					)
					self:T(_msg)
					-- self:T({_msg, isCategory = isCategory, isType = isType, isRole = isRole, isSide = isSide})
	
					if isType and (isCategory and isRole) then
						if(coal and ((entry.side == coal) or (coal == 99))) then
							self:T(self.traceTitle .. " Side correct")
							local victim = entry.group
							victim:Destroy(false)
							self.MLSpawnedGroups[idx] = nil
						end
					else
						self:T(self.traceTitle .. "category or type or side do not match entry")
					end
				else
					self:T("[JTF-1] Group is not alive.")
					self.MLSpawnedGroups[idx] = nil
				end
			end
		else
			self:E("[JTF-1] CATEGORY, TYPE or ROLE option not defined")
		end

	-- Delete ALL
	elseif(deleteCMD == "ALL") then
		_msg = string.format("%sDELETE: Option ALL.", self.traceTitle)
		self:T(_msg)

		for idx, entry in pairs (self.MLSpawnedGroups) do
			if entry.group:IsAlive() then

				_msg = string.format("%sentry.class: %s, entry.msType: %s, entry.role: %s, entry.side: %s", 
				self.traceTitle,
					(entry.category or "nil"),
					(entry.msType or "nil"),
					(entry.role or "nil"),
					(entry.side or "nil")
				)
				self:T(_msg)

				local isCategory = (entry.category == category) or (category == "ALL")
				local isType = (entry.msType:upper() == msType) or (msType == "ALL")
				local isRole = (entry.role:upper() == role) or (role == "ALL")
				local isSide = (entry.side == coal) or (coal == 99)
				
				_msg = string.format("%sisCategory: %s, isType: %s, isRole: %s, isSide: %s", 
					self.traceTitle,
					((isCategory and "True") or "False"),
					((isType and "True") or "False"),
					((isRole and "True") or "False"),
					((isSide and "True") or "False")
				)
				self:T(_msg)

				if isType and (isCategory and isRole) then
					if(coal and ((entry.side == coal) or coal == 99)) then
						self:T(self.traceTitle .. " Side correct")
						local victim = entry.group
						victim:Destroy(false)
						self.MLSpawnedGroups[idx] = nil
					end
				end
			else
				self.MLSpawnedGroups[idx] = nil
			end
		end
	else
		_msg = string.format("%sDELETE: Nothing done!", self.traceTitle)
		self:E(_msg)
	end
end

-----------------
-- WX REPORT
-----------------

function MARKSPAWN:MLWxReport(repoString, mark)
	_msg = string.format("%s WXREPORT. repostring = %s", 
		self.traceTitle,
		repoString
	)
	self:T(_msg)

	local qfe = false
	local metric = false
	local options = self:split(repoString, ",")
	--local pos = mark:GetCoordinate()
	self:T({options = options, markpos = {mark.pos}})

	for idx, option in pairs (options) do
		option = option:gsub("%s+", "")
		self:T({option_sub = option})
		if(option:upper() == "METRIC") then
		metric = true
		elseif(option:upper() == "QFE") then
		qfe = true
		end
	end
	
	local wxPos = COORDINATE:NewFromVec3(mark.pos) -- COORDINATE:NewFromVec3(self:MLConvertMarkPos(mark.pos))
	local wxLandHeight = wxPos:GetLandHeight()
	local heading, windSpeedMPS = wxPos:GetWind()
	
	_msg = string.format("%s Land Height: %d, Heading: %d, Speed m/s: %4.2f", 
		self.traceTitle,
		wxLandHeight,
		heading,
		windSpeedMPS
	)
	self:T(_msg)
	
	--heading = self:_Heading(heading + 180)
	local windSpeedKnots = UTILS.MpsToKnots(windSpeedMPS)
	local temperature = wxPos:GetTemperature()
	
	local pressure_hPa,pressure_inHg
	if(qfe) then
		pressure_hPa = wxPos:GetPressure(wxLandHeight)
	else
		pressure_hPa = wxPos:GetPressure(0)
	end
	pressure_inHg = pressure_hPa * 0.0295299830714
	
	local coal
	if(mark.initiator) then
		coal = UNIT:Find(mark.initiator):GetGroup():GetCoalition()
	else
		coal = mark.coalition
	end

	local msgWx = ""
	local msgWind, msgPressure, msgTemperature

	-- requested in Metric
	if(metric) then
		msgWind = string.format("Wind is from %03d Degrees at %.2f Mps",heading, windSpeedMPS)
		if(qfe) then
			msgPressure = string.format("QFE is %4.2f hPa", pressure_hPa)
		else
			msgPressure = string.format("QNH is %4.2f hPa", pressure_hPa)
		end
	-- requested in Imperial
	else
		msgWind = string.format("Wind is from %03d Degrees at %d Knots",heading, windSpeedKnots)
		if(qfe) then
			msgPressure = string.format("QFE is %4.2f inHg", pressure_inHg)
		else
			msgPressure = string.format("QNH is %4.2f inHg", pressure_inHg)
		end
	end
	
	msgTemperature = string.format("Temperature is %d Degrees C", temperature)

	msgWx = string.format("%s\n%s\n%s", 
		msgWind,
		msgPressure,
		msgTemperature
	)
	wxPos:MarkToCoalition(msgWx,coal,false,nil)

	_msg = string.format("%s%s", 
		self.traceTitle,
		(string.gsub(msgWx, "%c", " | "))
	)
	self:T(_msg)
	-- _msg = string.format("%s %s | %s | %s", 
	-- 	self.traceTitle,
	-- 	msgWind,
	-- 	msgPressure,
	-- 	msgTemperature
	-- )
	-- self:T(_msg)
end

-----------------
-- REMOVE CMD MARK POINT
-----------------

function MARKSPAWN:MLRemoveMark(markId)
	local allMarks = world.getMarkPanels()
	for idx, mark in pairs(allMarks) do
		if markId == mark.idx then
		trigger.action.removeMark(markId)
		allMarks[idx] = nil
		return
		end
	end
end

-----------------
-- SPAWN RADIO
-----------------

function MARKSPAWN:MLRadioSpawn(SpawnTable)
	local song = SpawnTable.song
	local freq = tonumber(SpawnTable.freq) or 251

	local band = SpawnTable.band or "AM"
	if(band == "FM") then
		band = 1
	else
		band = 0
	end
	local power = tonumber(SpawnTable.power) or 1200
	local loop = SpawnTable.loop

	self:T(freq)
	self:T(band)
	self:T(power)

	local radioPositionable = SpawnTable.group
	if(radioPositionable) then

		local pirateRadio = RADIO:New(radioPositionable)
		pirateRadio:NewGenericTransmission(song,freq,band,power,false)
		pirateRadio:Broadcast()
		self:T("[JTF-1] boobs")
	else
		MLRadio:NewGenericTransmission(song,freq,band,power,false)
		MLRadio:Broadcast()
		self:T("[JTF-1] tatas")
	end

end

-----------------
-- Get Property for SpawnType
-----------------

function MARKSPAWN:GetProperty(msType, property)
	_msg = string.format("%sGetProperty called for type: %s, property: %s", 
		self.traceTitle,
		tostring(msType),
		tostring(property)
	)
	self:T(_msg)

	for idx, spawnType in pairs(self.spawnTypes) do
		-- find the requested type
		if string.upper(msType) == string.upper(spawnType.msType) then
			-- get the requested property value
			local propertyVal = spawnType[property]
			-- if found return the value
			if propertyVal ~= nil then
				return propertyVal
			else
				_msg = string.format("%sError! Property %s not found for type %s",
					self.traceTitle,
					property,
					msType
				)
				self:E(_msg)
			end
		end
	end
	return nil
end

-----------------
-- Spawn Template Name String Comparison
-----------------

function MARKSPAWN:comparator(msType)
	for idx, val in pairs(self.spawnTypes) do
		if string.upper(msType) == string.upper(val.msType) then
			self:T("[JTF-1] Type: " .. val.msType)
			self:T("[JTF-1] Value: " .. val.category)
			self:T("[JTF-1] Role: " .. val.role)
			if val.spawn then
				return val.spawn, val.category, val.role
			else
				_msg = string.format("%sError! Skipping type for missing spawn template %s",
					self.traceTitle,
					val.template
				)
			end
		end
	end
	return nil
end

-----------------
-- Set ROE
-----------------

function MARKSPAWN:MLSetROE(ROEString, group)
	local text = string.upper(ROEString)
	if(text == "FREE") then 
		group:OptionROEWeaponFree()
	elseif (text == "RETURN") then
		group:OptionROEReturnFire()
	elseif (text == "HOLD") then
		group:OptionROEHoldFire()
	end
end

-----------------
-- Set ROT
-----------------

function MARKSPAWN:MLSetROT(ROTString, group)
	local text = string.upper(ROTString)
	if(text == "EVADE") then
		group:OptionROTEvadeFire()
	elseif (text == "PASSIVE") then
		group:OptionROTPassiveDefense()
	elseif (text == "NONE") then
		group:OptionROTNoReaction()
	end
end

-----------------
-- Set Alarm State
-----------------

function MARKSPAWN:MLSetAlarm(alarmString, group)
	local text = string.upper(alarmString)
	if(text == "GREEN") then 
		group:OptionAlarmStateGreen()
	elseif (text == "RED") then
		group:OptionAlarmStateRed()
	elseif (text == "AUTO") then
		group:OptionAlarmStateAuto()
	end
end

-----------------
-- Set Task
-----------------

function MARKSPAWN:MLSetTask(TaskString, group)
		local text = string.upper(TaskString)
		local taskTable = {}
	
		if(text == "CAP") then 
		local EngageTargets = { 
		id = 'EngageTargets', 
		params = { 
			maxDist = UTILS.NMToMeters(40), 
			targetTypes = {"Air"},
			priority = 0 
		} 
		}
		taskTable[1] = EngageTargets
	
	elseif (text == "REFUELING" or text == "TANKER") then
		local task = group:EnRouteTaskTanker()
		taskTable[1] = task
	
	elseif (text == "CAS") then
		local EngageTargets = { 
		id = 'EngageTargets', 
		params = { 
			maxDist = UTILS.NMToMeters(25), 
			targetTypes = {"Ground Units","Light armed ships","Helicopters"},
			priority = 0 
		} 
		}
	
	elseif (text == "SEAD") then
		local EngageTargets = { 
		id = 'EngageTargets', 
		params = {
			maxDist = UTILS.NMToMeters(25), 
			targetTypes = {"Air Defence"},
			priority = 0 
		} 
		}
		taskTable[1] = EngageTargets
	
	elseif (text == "TASMO") then
		local EngageTargets = { 
		id = 'EngageTargets', 
		params = { 
			maxDist = UTILS.NMToMeters(100), 
			targetTypes = {"Ships"},
			priority = 0 
		} 
		}
		taskTable[1] = EngageTargets
	
	elseif (text == "AWACS") then
		local task = group:EnRouteTaskAWACS()
		local EPLRS = { 
		id = 'EPLRS', 
		params = { 
			value = true,
		} 
		}
		group:SetCommand(EPLRS)
		taskTable[1] = task
	
	elseif (text == "AFAC") then
		local task = group:EnRouteTaskFAC(UTILS.NMToMeters(10), 0)
		taskTable[1] = task
	
	end
	
	return taskTable
end
  
-----------------
-- COALITION ENUMERATOR
-----------------
  
function MARKSPAWN:MLSideComparator(side, template)
	local coal
	local country = template:GetCountry()
	if(side == "BLUE") then
		coal = coalition.side.BLUE
		if(coal ~= template:GetCoalition()) then
			country = self.default.DEFAULT_BLUE_COUNTRY
		end
	elseif(side == "RED") then
		coal =  coalition.side.RED
		if(coal ~= template:GetCoalition()) then
			country = self.default.DEFAULT_RED_COUNTRY
		end
	elseif(side == "NEUTRAL") then
		coal =  coalition.side.NEUTRAL
		if(coal ~= template:GetCoalition()) then
			country = self.default.DEFAULT_NEUTRAL_COUNTRY
		end
	else
		coal = template:GetCoalition()
		country = template:GetCountry()
	end

	self:T(coal .. " " .. country)
	return coal, country
end

-----------------
-- Get Radio Preset
-----------------

function MARKSPAWN:MLRadioPreset(channel)
	return self.radioPresets[channel]
end

-----------------
-- CONVERT POS TO VEC2?
-----------------

function MARKSPAWN:MLConvertMarkPos(pos)
	local newPos = UTILS.DeepCopy(pos)
	local zVal = pos.x
	local xVal = pos.z
	newPos.z = zVal
	newPos.x = xVal
	_msg = self.traceTitle .. " newPos.z = " .. newPos.z .. " newPos.x = " .. newPos.x
	self:T(_msg)

	return newPos
end

-----------------
-- GET LIST OF WAYPOINT COORDINATES
-----------------

function MARKSPAWN:MLFindWaypoints(waypointNameList)
	self:T("[JTF-1] WAYPOINTS MODE TURN ON")
	local waypointNames={}
	local waypointCoords = {}
	--waypoints:gsub("%w*",function(name) table.insert(waypointNames,name) end)
	--for k, v in waypointNameList:gmatch("(%w*)") do
	--  table.insert(waypointNames,k)
	--end
	
	waypointNames = self:split(waypointNameList,",")
	local allMarks = world.getMarkPanels()
	for idx, name in pairs(waypointNames) do
		for idy, mark in pairs(allMarks) do
		self:T("[JTF-1] name: " .. name)
		self:T("[JTF-1] mark: " .. mark.text)
		if string.upper(name) == string.upper(mark.text) then
			waypointCoords[#waypointCoords + 1] = COORDINATE:NewFromVec3(mark.pos)
			break
		end
		end
	end
	return waypointCoords
end

-----------------
-- SPLIT STRING AT DELIMITER
-----------------

function MARKSPAWN:split(s, delimiter)
	local result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match);
	end
	return result;
end

-----------------
-- Display message with the mark's command and options
-----------------

function MARKSPAWN:MLListSpawnOptions(category, mark)
	local messageString = ""
	for idx, value in pairs(self.spawnTypes) do
		--list name, role, maybe default coalition
		if value.spawn then
			if(category:upper() == value.category:upper()) then
				local name = value.msType
				local role = value.role
				local defaultCoalition = GROUP:FindByName( value.spawn.SpawnTemplatePrefix ):GetCoalition()
				local coal
				if(defaultCoalition == 1) then 
					coal = "Red" 
				elseif defaultCoalition == 2 then 
					coal = "Blue" 
				else 
					coal = "Neutral"
				end
				local line = string.format("Type: %s, Role: %s, Coalition: %s\n", 
					name, 
					role, 
					coal
				)
				messageString = messageString .. line 
			end
		else
			_msg = string.format("%sError! Skipping OPTIONS for missing spawn template %s.",
				self.traceTitle,
				value.template
			)
			self:T(_msg)
		end

	end
	self:T("[JTF-1] OPTIONS: " .. messageString)
	local DCSUnit = mark.initiator
	if(DCSUnit) then
		--local group = unit:GetGroup()
		local unit = UNIT:Find(DCSUnit)
		local group = unit:GetGroup()
		MESSAGE:New(messageString,30):ToUnit(unit) -- ToGroup(group)
	else
		local coal = mark.coalition
		self:T(coal)
		MESSAGE:New(messageString,30):ToCoalition(coal)
	end
end

-----------------
-- GET REVERSE OF HEADING 
-----------------

--stolen from moose, cred to them
function MARKSPAWN:_Heading(course)
	local h
	if course<=180 then
		h=math.rad(course)
	else
		h=-math.rad(360-course)
	end
	return h 
end

-----------------
-- VALIDATE SKILL OPTION 
-----------------

function MARKSPAWN:MLSkillCheck(skill)
	if(skill == nil) then
		return nil
	end

	skill = skill:upper()
	if(skill == "AVERAGE") then
		return skill
	elseif(skill == "NORMAL") then
		return skill
	elseif(skill == "GOOD") then
		return skill
	elseif(skill == "HIGH") then
		return skill
	elseif(skill == "EXCELLENT") then
		return skill
	elseif(skill == "RANDOM") then
		return skill
	else
		return nil
	end

end

-----------------
-- TEMPLATES 
-----------------

function MARKSPAWN:AddTemplate(spawnType)

end

--- END MARKSPAWN  
--------------------------------[core\bfmacm.lua]-------------------------------- 
 
env.info( "[JTF-1] bfmacm" )
--
-- ZONES: if zones are MOOSE polygon zones, zone name in mission editor MUST be suffixed with ~ZONE_POLYGON
-- 

BFMACM = {
	ClassName = "BFMACM",
	version = "1.0",
	traceTitle = "[JTF-1] ",
	menuAdded = {},
	menuF10 = {},
	useSRS = true,
}

-- BFMACM.zoneBfmAcmName = "COYOTEABC" -- The BFM/ACM Zone
-- BFMACM.zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
-- 	"zone_box",
-- } 

BFMACM.adversary = {
	menu = { -- Adversary menu
		{template = "ADV_F4", menuText = "Adversary A-4"},
		{template = "ADV_MiG28", menuText = "Adversary MiG-28"},
		{template = "ADV_Su27", menuText = "Adversary MiG-23"},
		{template = "ADV_MiG23", menuText = "Adversary Su-27"},
		{template = "ADV_F16", menuText = "Adversary F-16"},
		{template = "ADV_F18", menuText = "Adversary F-18"},
	},
	range = {5, 10, 20}, -- ranges at which to spawn adversaries in nautical miles
	spawn = {}, -- container for aversary spawn objects
	defaultRadio = "377.8",
}

-- set frequency to use if messages are to be sent using SRS
BFMACM.rangeRadio = JTF1.rangeRadio or BFMACM.defaultRadio

-- Inherit from BASE
BFMACM = BASE:Inherit( BFMACM, BASE:New() )
-- Add eventhandler
BFMACM:HandleEvent(EVENTS.PlayerEnterAircraft)
BFMACM:HandleEvent(EVENTS.PlayerLeaveUnit)

local _msg
local useSRS

function BFMACM:Start() -- start BFMACM module
	useSRS = (JTF1.useSRS and BFMACM.useSRS) and MISSIONSRS.Radio.active -- default to not using SRS unless both the server AND the module request it and MISSIONSRS.Radio is true
	_msg = string.format("[JTF-1 BFMACM] useSRS: %s", tostring(useSRS))
	-- if useSRS then
	-- 	_msg = _msg .. "TRUE"
	-- else
	-- 	_msg = _msg .. "FALSE"
	-- end 
	self:T(_msg)

	-- Add main BFMACM zone
	if self.zoneBfmAcmName ~= nil then
		_zone = ZONE:FindByName(self.zoneBfmAcmName) or ZONE_POLYGON:FindByName(self.zoneBfmAcmName)
		if _zone == nil then
			_msg = string.format("[JTF-1 BFMACM] ERROR: BFM/ACM Zone: %s not found!", self.zoneBfmAcmName)
			self:E(_msg)
		else
			self.zoneBfmAcm = _zone
			_msg = string.format("[JTF-1 BFMACM] BFM/ACM Zone: %s added.", self.zoneBfmAcmName)
			self:T(_msg)
		end
	else
		-- no zone defined, whole map will be active
		_msg = "[JTF-1 BFMACM] No zone defined. Whole map is active."
		self:T(_msg)
		self.zoneBfmAcm = false

	end

	-- Add spawn exclusion zone(s)
	if self.zonesNoSpawnName then
		self.zonesNoSpawn = {}
		for i, zoneNoSpawnName in ipairs(self.zonesNoSpawnName) do
			_zone = (ZONE:FindByName(zoneNoSpawnName) and ZONE:FindByName(zoneNoSpawnName) or ZONE_POLYGON:FindByName(zoneNoSpawnName))
			if _zone == nil then
			_msg = "[JTF-1 BFMACM] ERROR: Exclusion zone: " .. tostring(zoneNoSpawnName) .. " not found!"
			self:E(_msg)
			else
				self.zonesNoSpawn[i] = _zone
			_msg = "[JTF-1 BFMACM] Exclusion zone: " .. tostring(zoneNoSpawnName) .. " added."
			self:T(_msg)
			end
		end
	else
		self:T("[JTF-1 BFMACM] No exclusion zones defined.")
	end

	-- Add spawn objects
	for i, adversaryMenu in ipairs(BFMACM.adversary.menu) do
		_adv = GROUP:FindByName(adversaryMenu.template)
		if _adv then
			self.adversary.spawn[adversaryMenu.template] = SPAWN:New(adversaryMenu.template)
		else
			_msg = "[JTF-1 BFMACM] ERROR: spawn template: " .. tostring(adversaryMenu.template) .. " not found!" .. tostring(zoneNoSpawnName) .. " not found!"
			self:E(_msg)
		end
	end

end

-- check player is present and unit is alive
function BFMACM:GetPlayerUnitAndName(unitname)
	if unitname ~= nil then
		local DCSunit = Unit.getByName(unitname)
		if DCSunit then
		local playername=DCSunit:getPlayerName()
		local unit = UNIT:Find(DCSunit)
		if DCSunit and unit and playername then
			return unit, playername
		end
		end
	end
	-- Return nil if we could not find a player.
	return nil,nil
end

-- Spawn adversaries
function BFMACM:SpawnAdv(adv,qty,group,rng,unit)
	local playerName = (unit:GetPlayerName() and unit:GetPlayerName() or "Unknown") 
	local range = rng * 1852
	local hdg = unit:GetHeading()
	local pos = unit:GetPointVec2()
	local spawnPt = pos:Translate(range, hdg, true)
	local spawnVec3 = spawnPt:GetVec3()
	local spawnAllowed, msgNoSpawn

	-- check player is in BFM ACM zone.
	if self.zoneBfmAcm then
		_msg = "[JTF-1 BFMACM] SpawnAdv(). Allowed Spawn Zone is defined."
		self:T(_msg)
		spawnAllowed = unit:IsInZone(self.zoneBfmAcm)
		msgNoSpawn = ", Cannot spawn adversary aircraft if you are outside the BFM/ACM zone!"
	else
		_msg = "[JTF-1 BFMACM] SpawnAdv(). No Allowed Spawn Zone defined."
		self:T(_msg)
		-- no allowed spawn zone defined. Whole map active.
		spawnAllowed = true
	end

	-- Check spawn location is not in an exclusion zone
	if spawnAllowed then
		if self.zonesNoSpawn then
		for i, zoneExclusion in ipairs(self.zonesNoSpawn) do
			spawnAllowed = not zoneExclusion:IsVec3InZone(spawnVec3)
		end
		msgNoSpawn = ", Cannot spawn adversary aircraft in an exclusion zone. Change course, or increase your range from the zone, and try again."
		end
	end

	-- Check spawn location is inside the BFM/ACM zone
	if spawnAllowed and self.zoneBfmAcm then
		spawnAllowed = self.zoneBfmAcm:IsVec3InZone(spawnVec3)
		msgNoSpawn = ", Cannot spawn adversary aircraft outside the BFM/ACM zone. Change course and try again."
	end

	-- Spawn the adversary, if not in an exclusion zone or outside the BFM/ACM zone.
	if spawnAllowed then
		self.adversary.spawn[adv]:InitGrouping(qty)
		:InitHeading(hdg + 180)
		:OnSpawnGroup(
		function ( SpawnGroup )
			local CheckAdversary = SCHEDULER:New( SpawnGroup, 
			function (CheckAdversary)
				if SpawnGroup and BFMACM.zoneBfmAcm then
					if SpawnGroup:IsNotInZone( BFMACM.zoneBfmAcm ) then
						local msg = "All players, BFM Adversary left BFM Zone and was removed!"
						if useSRS then -- if MISSIONSRS radio object has been created, send message via default broadcast.
							MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
						else -- otherwise, send in-game text message
							MESSAGE:New(msg):ToAll()
						end
						--MESSAGE:New("Adversary left BFM Zone and was removed!"):ToAll()
						SpawnGroup:Destroy()
						SpawnGroup = nil
					end
				end
			end,
			{}, 0, 5 )
		end
		)
		:SpawnFromVec3(spawnVec3)
		local msg = "All players, " .. playerName .. " has spawned BFM Adversary."
		if useSRS then -- if MISSIONSRS radio object has been created, send message via default broadcast.
			MISSIONSRS:SendRadio(msg,self.rangeRadio)
		else -- otherwise, send in-game text message
			MESSAGE:New(msg):ToAll()
		end
		--MESSAGE:New(playerName .. " has spawned Adversary."):ToGroup(group)
	else
		local msg = playerName .. msgNoSpawn
		if useSRS then -- if MISSIONSRS radio object has been created, send message via default broadcast.
			MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
		else -- otherwise, send in-game text message
			MESSAGE:New(msg):ToAll()
		end
		--MESSAGE:New(playerName .. msgNoSpawn):ToGroup(group)
	end
end

function BFMACM:AddMenu(unitname)
	self:T("[JTF-1 BFMACM] AddMenu called.")
  local unit, playername = self:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if self.menuAdded[uid] == nil then
        -- add GROUP menu if not already present
        if self.menuF10[gid] == nil then
			self:T("[JTF-1 BFMACM] Adding menu for group: " .. group:GetName())
			self.menuF10[gid] = MENU_GROUP:New(group, "AI BFM/ACM")
        end
        if self.menuF10[gid][uid] == nil then
          -- add playername submenu
          self:T("[JTF-1 BFMACM] Add submenu for player: " .. playername)
          self.menuF10[gid][uid] = MENU_GROUP:New(group, playername, BFMACM.menuF10[gid])
          -- add adversary submenus and range selectors
          self:T("[JTF-1 BFMACM] Add submenus and range selectors for player: " .. playername)
          for iMenu, adversary in ipairs(self.adversary.menu) do
            -- Add adversary type menu
            self.menuF10[gid][uid][iMenu] = MENU_GROUP:New(group, adversary.menuText, BFMACM.menuF10[gid][uid])
            -- Add single or pair selection for adversary type
            self.menuF10[gid][uid][iMenu].single = MENU_GROUP:New(group, "Single", BFMACM.menuF10[gid][uid][iMenu])
            self.menuF10[gid][uid][iMenu].pair = MENU_GROUP:New(group, "Pair", BFMACM.menuF10[gid][uid][iMenu])
            -- select range at which to spawn adversary
            for iCommand, range in ipairs(BFMACM.adversary.range) do
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].single, BFMACM.SpawnAdv, BFMACM, adversary.template, 1, group, range, unit)
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].pair, BFMACM.SpawnAdv, BFMACM, adversary.template, 2, group, range, unit)
            end
          end
        end
        BFMACM.menuAdded[uid] = true
      end
    else
		self:T(string.format("[JTF-1 BFMACM] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    self:T(string.format("[JTF-1 BFMACM] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end
  
-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function BFMACM:OnEventPlayerEnterAircraft(EventData)
	self:T("[JTF-1 BFMACM] PlayerEnterAircraft called.")
	local unitname = EventData.IniUnitName
	local unit, playername = BFMACM:GetPlayerUnitAndName(unitname)
	if unit and playername then
		self:T("[JTF-1 BFMACM] Player entered Aircraft: " .. playername)
		SCHEDULER:New(nil, BFMACM.AddMenu, {BFMACM, unitname},0.1)
	end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function BFMACM:OnEventPlayerLeaveUnit(EventData)
	local playername = EventData.IniPlayerName
	local unit = EventData.IniUnit
	local gid = EventData.IniGroup:GetID()
	local uid = EventData.IniUnit:GetID()
	self:T("[JTF-1 BFMACM] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
	if gid and uid then
		if self.menuF10[gid] then
			self:T("[JTF-1 BFMACM] Removing menu for unit UID:" .. uid)
			self.menuF10[gid][uid]:Remove()
			self.menuF10[gid][uid] = nil
			self.menuAdded[uid] = nil
		end
	end
end

-- pre-defined spawn templates to be used as an alternative to placing late activated templates in the miz
BFMACM.template = {

}
--BFMACM:Start()

--- END ACMBFM SECTION  
--------------------------------[core\Hercules_Cargo.lua]-------------------------------- 
 
env.info( "[JTF-1] Hercules_Cargo.lua" )
-- Hercules Cargo Drop Events by Anubis Yinepu

-- This script will only work for the Herculus mod by Anubis
-- Payloads carried by pylons 11, 12 and 13 need to be declared in the Herculus_Loadout.lua file
-- Except for Ammo pallets, this script will spawn whatever payload gets launched from pylons 11, 12 and 13
-- Pylons 11, 12 and 13 are moveable within the Herculus cargobay area
-- Ammo pallets can only be jettisoned from these pylons with no benefit to DCS world
-- To benefit DCS world, Ammo pallets need to be off/on loaded using DCS arming and refueling window
-- Cargo_Container_Enclosed = true: Cargo enclosed in container with parachute, need to be dropped from 100m (300ft) or more, except when parked on ground
-- Cargo_Container_Enclosed = false: Open cargo with no parachute, need to be dropped from 10m (30ft) or less

Hercules_Cargo = {}
Hercules_Cargo.Hercules_Cargo_Drop_Events = {}
local GT_DisplayName = ""
local GT_Name = ""
local Cargo_Drop_initiator = ""
local Cargo_Container_Enclosed = false
local SoldierGroup = false
local ParatrooperCount = 1
local ParatrooperGroupSpawnInit = false
local ParatrooperGroupSpawn = false

local Herc_j = 0
local Herc_Cargo = {}
Herc_Cargo.Cargo_Drop_Direction = 0
Herc_Cargo.Cargo_Contents = ""
Herc_Cargo.Cargo_Type_name = ""
Herc_Cargo.Cargo_over_water = false
Herc_Cargo.Container_Enclosed = false
Herc_Cargo.offload_cargo = false
Herc_Cargo.all_cargo_survive_to_the_ground = false
Herc_Cargo.all_cargo_gets_destroyed = false
Herc_Cargo.destroy_cargo_dropped_without_parachute = false
Herc_Cargo.scheduleFunctionID = 0

local CargoHeading = 0
local Cargo_Drop_Position = {}

local SoldierUnitID = 12000
local SoldierGroupID = 12000
local GroupSpacing = 0
--added by wrench
Hercules_Cargo.types = {
	["ATGM M1045 HMMWV TOW Air [7183lb]"] = {['name'] = "M1045 HMMWV TOW", ['container'] = true},
	["ATGM M1045 HMMWV TOW Skid [7073lb]"] = {['name'] = "M1045 HMMWV TOW", ['container'] = false},
	["APC M1043 HMMWV Armament Air [7023lb]"] = {['name'] = "M1043 HMMWV Armament", ['container'] = true},
	["APC M1043 HMMWV Armament Skid [6912lb]"] = {['name'] = "M1043 HMMWV Armament", ['container'] = false},
	["SAM Avenger M1097 Air [7200lb]"] = {['name'] = "M1097 Avenger", ['container'] = true},
	["SAM Avenger M1097 Skid [7090lb]"] = {['name'] = "M1097 Avenger", ['container'] = false},
	["APC Cobra Air [10912lb]"] = {['name'] = "Cobra", ['container'] = true},
	["APC Cobra Skid [10802lb]"] = {['name'] = "Cobra", ['container'] = false},
	["APC M113 Air [21624lb]"] = {['name'] = "M-113", ['container'] = true},
	["APC M113 Skid [21494lb]"] = {['name'] = "M-113", ['container'] = false},
	["Tanker M978 HEMTT [34000lb]"] = {['name'] = "M978 HEMTT Tanker", ['container'] = false},
	["HEMTT TFFT [34400lb]"] = {['name'] = "HEMTT TFFT", ['container'] = false},
	["SPG M1128 Stryker MGS [33036lb]"] = {['name'] = "M1128 Stryker MGS", ['container'] = false},
	["AAA Vulcan M163 Air [21666lb]"] = {['name'] = "Vulcan", ['container'] = true},
	["AAA Vulcan M163 Skid [21577lb]"] = {['name'] = "Vulcan", ['container'] = false},
	["APC M1126 Stryker ICV [29542lb]"] = {['name'] = "M1126 Stryker ICV", ['container'] = false},
	["ATGM M1134 Stryker [30337lb]"] = {['name'] = "M1134 Stryker ATGM", ['container'] = false},
	["APC LAV-25 Air [22520lb]"] = {['name'] = "LAV-25", ['container'] = true},
	["APC LAV-25 Skid [22514lb]"] = {['name'] = "LAV-25", ['container'] = false},
	["M1025 HMMWV Air [6160lb]"] = {['name'] = "Hummer", ['container'] = true},
	["M1025 HMMWV Skid [6050lb]"] = {['name'] = "Hummer", ['container'] = false},
	["IFV M2A2 Bradley [34720lb]"] = {['name'] = "M-2 Bradley", ['container'] = false},
	["IFV MCV-80 [34720lb]"] = {['name'] = "MCV-80", ['container'] = false},
	["IFV BMP-1 [23232lb]"] = {['name'] = "BMP-1", ['container'] = false},
	["IFV BMP-2 [25168lb]"] = {['name'] = "BMP-2", ['container'] = false},
	["IFV BMP-3 [32912lb]"] = {['name'] = "BMP-3", ['container'] = false},
	["ARV BRDM-2 Air [12320lb]"] = {['name'] = "BRDM-2", ['container'] = true},
	["ARV BRDM-2 Skid [12210lb]"] = {['name'] = "BRDM-2", ['container'] = false},
	["APC BTR-80 Air [23936lb]"] = {['name'] = "BTR-80", ['container'] = true},
	["APC BTR-80 Skid [23826lb]"] = {['name'] = "BTR-80", ['container'] = false},
	["APC BTR-82A Air [24998lb]"] = {['name'] = "BTR-82A", ['container'] = true},
	["APC BTR-82A Skid [24888lb]"] = {['name'] = "BTR-82A", ['container'] = false},
	["SAM ROLAND ADS [34720lb]"] = {['name'] = "Roland Radar", ['container'] = false},
	["SAM ROLAND LN [34720b]"] = {['name'] = "Roland ADS", ['container'] = false},
	["SAM SA-13 STRELA [21624lb]"] = {['name'] = "Strela-10M3", ['container'] = false},
	["AAA ZSU-23-4 Shilka [32912lb]"] = {['name'] = "ZSU-23-4 Shilka", ['container'] = false},
	["SAM SA-19 Tunguska 2S6 [34720lb]"] = {['name'] = "2S6 Tunguska", ['container'] = false},
	["Transport UAZ-469 Air [3747lb]"] = {['name'] = "UAZ-469", ['container'] = true},
	["Transport UAZ-469 Skid [3630lb]"] = {['name'] = "UAZ-469", ['container'] = false},
	["AAA GEPARD [34720lb]"] = {['name'] = "Gepard", ['container'] = false},
	["SAM CHAPARRAL Air [21624lb]"] = {['name'] = "M48 Chaparral", ['container'] = true},
	["SAM CHAPARRAL Skid [21516lb]"] = {['name'] = "M48 Chaparral", ['container'] = false},
	["SAM LINEBACKER [34720lb]"] = {['name'] = "M6 Linebacker", ['container'] = false},
	["Transport URAL-375 [14815lb]"] = {['name'] = "Ural-375", ['container'] = false},
	["Transport M818 [16000lb]"] = {['name'] = "M 818", ['container'] = false},
	["IFV MARDER [34720lb]"] = {['name'] = "Marder", ['container'] = false},
	["Transport Tigr Air [15900lb]"] = {['name'] = "Tigr_233036", ['container'] = true},
	["Transport Tigr Skid [15730lb]"] = {['name'] = "Tigr_233036", ['container'] = false},
	["IFV TPZ FUCH [33440lb]"] = {['name'] = "TPZ", ['container'] = false},
	["IFV BMD-1 Air [18040lb]"] = {['name'] = "BMD-1", ['container'] = true},
	["IFV BMD-1 Skid [17930lb]"] = {['name'] = "BMD-1", ['container'] = false},
	["IFV BTR-D Air [18040lb]"] = {['name'] = "BTR_D", ['container'] = true},
	["IFV BTR-D Skid [17930lb]"] = {['name'] = "BTR_D", ['container'] = false},
	["EWR SBORKA Air [21624lb]"] = {['name'] = "Dog Ear radar", ['container'] = true},
	["EWR SBORKA Skid [21624lb]"] = {['name'] = "Dog Ear radar", ['container'] = false},
	["ART 2S9 NONA Air [19140lb]"] = {['name'] = "SAU 2-C9", ['container'] = true},
	["ART 2S9 NONA Skid [19030lb]"] = {['name'] = "SAU 2-C9", ['container'] = false},
	["ART GVOZDIKA [34720lb]"] = {['name'] = "SAU Gvozdika", ['container'] = false},
	["APC MTLB Air [26400lb]"] = {['name'] = "MTLB", ['container'] = true},
	["APC MTLB Skid [26290lb]"] = {['name'] = "MTLB", ['container'] = false},
	--["Generic Crate [20000lb]"] = {['name'] =  "Hercules_Container_Parachute", ['container'] = true}
}
function Hercules_Cargo.Soldier_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, GroupSpacing)
	SoldierUnitID = SoldierUnitID + 30
	SoldierGroupID = SoldierGroupID + 1
	local Herc_Soldier_Spawn = 
	{
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["groupId"] = SoldierGroupID,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 0.5 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 0.5 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 1.0 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 1.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 1.5 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 1.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 2.0 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 2.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 2.5 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 2.5 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 3.0 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 3.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["type"] = "Soldier M249",
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 3.5 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 3.5 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["type"] = "Soldier M249",
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 4.0 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 4.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 4.5 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 4.5 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["type"] = "Paratrooper RPG-16",
				["transportable"] = 
				{
					["randomTransportable"] = true,
				}, -- end of ["transportable"]
				["unitId"] = SoldierUnitID + 1,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z + 5.0 + GroupSpacing,
				["x"] = Cargo_Drop_Position.x + 5.0 + GroupSpacing,
				["name"] = "Soldier Unit "..SoldierUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = false,
			}, -- end of [10]
		}, -- end of ["units"]
		["y"] = Cargo_Drop_Position.z,
		["x"] = Cargo_Drop_Position.x,
		["name"] = "Soldier_Group_"..SoldierGroupID,
		["start_time"] = 0,
	}
	coalition.addGroup(Cargo_Country, Group.Category.GROUND, Herc_Soldier_Spawn)
end

local CargoUnitID = 10000
local CargoGroupID = 10000
local CargoStaticGroupID = 11000

function Hercules_Cargo.Cargo_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country)
	CargoUnitID = CargoUnitID + 1
	CargoGroupID = CargoGroupID + 1
	local Herc_Cargo_Spawn = 
	{
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["groupId"] = CargoGroupID,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["type"] = Cargo_Type_name,
				["transportable"] = 
				{
					["randomTransportable"] = false,
				}, -- end of ["transportable"]
				["unitId"] = CargoUnitID,
				["skill"] = "Excellent",
				["y"] = Cargo_Drop_Position.z,
				["x"] = Cargo_Drop_Position.x,
				["name"] = "Cargo Unit "..CargoUnitID,
				["heading"] = CargoHeading,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = Cargo_Drop_Position.z,
		["x"] = Cargo_Drop_Position.x,
		["name"] = "Cargo Group "..CargoUnitID,
		["start_time"] = 0,
	}
	coalition.addGroup(Cargo_Country, Group.Category.GROUND, Herc_Cargo_Spawn)
end

function Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, dead, Cargo_Country)
	CargoStaticGroupID = CargoStaticGroupID + 1
	local Herc_CargoObject_Spawn = 
	{
		["type"] = Cargo_Type_name,
		["y"] = Cargo_Drop_Position.z,
		["x"] = Cargo_Drop_Position.x,
		["name"] = "Cargo Static Group "..CargoStaticGroupID,
		["heading"] = CargoHeading,
		["dead"] = dead,
	}
	coalition.addStaticObject(Cargo_Country, Herc_CargoObject_Spawn)
end

function Hercules_Cargo.Cargo_SpawnObjects(Cargo_Drop_Direction, Cargo_Content_position, Cargo_Type_name, Cargo_over_water, Container_Enclosed, ParatrooperGroupSpawn, offload_cargo, all_cargo_survive_to_the_ground, all_cargo_gets_destroyed, destroy_cargo_dropped_without_parachute, Cargo_Country)
	if offload_cargo == true then
		------------------------------------------------------------------------------
		if CargoHeading >= 3.14 then
			CargoHeading = 0
			Cargo_Drop_Position = {["x"] = Cargo_Content_position.x - (30.0 * math.cos(Cargo_Drop_Direction - 1.0)),
								   ["z"] = Cargo_Content_position.z - (30.0 * math.sin(Cargo_Drop_Direction - 1.0))}
		else
			if CargoHeading >= 1.57 then
				CargoHeading = 3.14
				Cargo_Drop_Position = {["x"] = Cargo_Content_position.x - (20.0 * math.cos(Cargo_Drop_Direction + 0.5)),
									   ["z"] = Cargo_Content_position.z - (20.0 * math.sin(Cargo_Drop_Direction + 0.5))}
			else
				if CargoHeading >= 0 then
					CargoHeading = 1.57
					Cargo_Drop_Position = {["x"] = Cargo_Content_position.x - (10.0 * math.cos(Cargo_Drop_Direction + 1.5)),
										   ["z"] = Cargo_Content_position.z - (10.0 * math.sin(Cargo_Drop_Direction + 1.5))}
				end
			end
		end
		------------------------------------------------------------------------------
		if ParatrooperGroupSpawn == true then
			Hercules_Cargo.Soldier_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, 0)
			Hercules_Cargo.Soldier_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, 5)
			Hercules_Cargo.Soldier_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, 10)
		else
			Hercules_Cargo.Cargo_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, 0)
		end
	else
		------------------------------------------------------------------------------
		CargoHeading = 0
		Cargo_Drop_Position = {["x"] = Cargo_Content_position.x - (20.0 * math.cos(Cargo_Drop_Direction)),
							   ["z"] = Cargo_Content_position.z - (20.0 * math.cos(Cargo_Drop_Direction))}
		------------------------------------------------------------------------------
		if all_cargo_gets_destroyed == true or Cargo_over_water == true then
			if Container_Enclosed == true then
				Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
				if ParatrooperGroupSpawn == false then
					Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, "Hercules_Container_Parachute_Static", CargoHeading, true, Cargo_Country)
				end
			else
				Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
			end
		else
			------------------------------------------------------------------------------
			if all_cargo_survive_to_the_ground == true then
				if ParatrooperGroupSpawn == true then
					Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
				else
					Hercules_Cargo.Cargo_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country)
				end
				if Container_Enclosed == true then
					if ParatrooperGroupSpawn == false then
						Hercules_Cargo.Cargo_SpawnStatic({["z"] = Cargo_Drop_Position.z + 10.0,["x"] = Cargo_Drop_Position.x + 10.0}, "Hercules_Container_Parachute_Static", CargoHeading, false, Cargo_Country)
					end
				end
			end
			------------------------------------------------------------------------------
			if destroy_cargo_dropped_without_parachute == true then
				if Container_Enclosed == true then
					if ParatrooperGroupSpawn == true then
						Hercules_Cargo.Soldier_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country, 0)
					else
						Hercules_Cargo.Cargo_SpawnGroup(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, Cargo_Country)
						Hercules_Cargo.Cargo_SpawnStatic({["z"] = Cargo_Drop_Position.z + 10.0,["x"] = Cargo_Drop_Position.x + 10.0}, "Hercules_Container_Parachute_Static", CargoHeading, false, Cargo_Country)
					end
				else
					Hercules_Cargo.Cargo_SpawnStatic(Cargo_Drop_Position, Cargo_Type_name, CargoHeading, true, Cargo_Country)
				end
			end
			------------------------------------------------------------------------------
		end
	end
end

function Hercules_Cargo.Calculate_Object_Height_AGL(object)
	return object:getPosition().p.y - land.getHeight({x = object:getPosition().p.x, y = object:getPosition().p.z})
end

function Hercules_Cargo.Check_SurfaceType(object)
   -- LAND,--1 SHALLOW_WATER,--2 WATER,--3 ROAD,--4 RUNWAY--5
	return land.getSurfaceType({x = object:getPosition().p.x, y = object:getPosition().p.z})
end

function Hercules_Cargo.Cargo_Track(Arg, time)
	local status, result = pcall(
		function()
		local next = next
		if next(Arg[1].Cargo_Contents) ~= nil then
			if Hercules_Cargo.Calculate_Object_Height_AGL(Arg[1].Cargo_Contents) < 5.0 then--pallet less than 5m above ground before spawning
				if Hercules_Cargo.Check_SurfaceType(Arg[1].Cargo_Contents) == 2 or Hercules_Cargo.Check_SurfaceType(Arg[1].Cargo_Contents) == 3 then
					Arg[1].Cargo_over_water = true--pallets gets destroyed in water
				end
				Arg[1].Cargo_Contents:destroy()--remove pallet+parachute before hitting ground and replace with Cargo_SpawnContents
				Hercules_Cargo.Cargo_SpawnObjects(Arg[1].Cargo_Drop_Direction, Object.getPoint(Arg[1].Cargo_Contents), Arg[1].Cargo_Type_name, Arg[1].Cargo_over_water, Arg[1].Container_Enclosed, Arg[1].ParatrooperGroupSpawn, Arg[1].offload_cargo, Arg[1].all_cargo_survive_to_the_ground, Arg[1].all_cargo_gets_destroyed, Arg[1].destroy_cargo_dropped_without_parachute, Arg[1].Cargo_Country)
				timer.removeFunction(Arg[1].scheduleFunctionID)
				Arg[1] = {}
			end
			return time + 0.1
		end
	end) -- pcall
	if not status then
		-- env.error(string.format("Cargo_Spawn: %s", result))
	else
		return result
	end
end

function Hercules_Cargo.Calculate_Cargo_Drop_initiator_NorthCorrection(point)	--correction needed for true north
	if not point.z then --Vec2; convert to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end

function Hercules_Cargo.Calculate_Cargo_Drop_initiator_Heading(Cargo_Drop_initiator)
	local Heading = math.atan2(Cargo_Drop_initiator:getPosition().x.z, Cargo_Drop_initiator:getPosition().x.x)
	Heading = Heading + Hercules_Cargo.Calculate_Cargo_Drop_initiator_NorthCorrection(Cargo_Drop_initiator:getPosition().p)
	if Heading < 0 then
		Heading = Heading + (2 * math.pi)-- put heading in range of 0 to 2*pi
	end
	return Heading + 0.06 -- rad
end

function Hercules_Cargo.Cargo_Initialize(initiator, Cargo_Contents, Cargo_Type_name, Container_Enclosed)
	local status, result = pcall(
		function()
		Cargo_Drop_initiator = Unit.getByName(initiator:getName())
		local next = next
		if next(Cargo_Drop_initiator) ~= nil then
			if ParatrooperGroupSpawnInit == true then
				if (ParatrooperCount == 1 or ParatrooperCount == 2 or ParatrooperCount == 3) then
					Herc_j = Herc_j + 1
					Herc_Cargo[Herc_j] = {}
					Herc_Cargo[Herc_j].Cargo_Drop_Direction = Hercules_Cargo.Calculate_Cargo_Drop_initiator_Heading(Cargo_Drop_initiator)
					Herc_Cargo[Herc_j].Cargo_Contents = Cargo_Contents
					Herc_Cargo[Herc_j].Cargo_Type_name = Cargo_Type_name
					Herc_Cargo[Herc_j].Container_Enclosed = Container_Enclosed
					Herc_Cargo[Herc_j].ParatrooperGroupSpawn = ParatrooperGroupSpawnInit
					Herc_Cargo[Herc_j].Cargo_Country = initiator:getCountry()
				------------------------------------------------------------------------------
					if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 5.0 then--aircraft on ground
						Herc_Cargo[Herc_j].offload_cargo = true
						ParatrooperCount = 0
						ParatrooperGroupSpawnInit = false
					else
				------------------------------------------------------------------------------
						if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 10.0 then--aircraft less than 10m above ground
							Herc_Cargo[Herc_j].all_cargo_survive_to_the_ground = true
						else
				------------------------------------------------------------------------------
							if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 152.4 then--aircraft more than 30ft but less than 500ft above ground
								Herc_Cargo[Herc_j].all_cargo_gets_destroyed = true
							else
				------------------------------------------------------------------------------
								Herc_Cargo[Herc_j].destroy_cargo_dropped_without_parachute = true--aircraft more than 152.4m (500ft)above ground
							end
						end
					end
				------------------------------------------------------------------------------
					Herc_Cargo[Herc_j].scheduleFunctionID = timer.scheduleFunction(Hercules_Cargo.Cargo_Track, {Herc_Cargo[Herc_j]}, timer.getTime() + 0.1)
					ParatrooperCount = ParatrooperCount + 1.0
				else
					if (ParatrooperCount == 30) then
						ParatrooperGroupSpawnInit = false
						ParatrooperCount = 1
					else
						ParatrooperCount = ParatrooperCount + 1.0
					end
				end
			else
				Herc_j = Herc_j + 1
				Herc_Cargo[Herc_j] = {}
				Herc_Cargo[Herc_j].Cargo_Drop_Direction = Hercules_Cargo.Calculate_Cargo_Drop_initiator_Heading(Cargo_Drop_initiator)
				Herc_Cargo[Herc_j].Cargo_Contents = Cargo_Contents
				Herc_Cargo[Herc_j].Cargo_Type_name = Cargo_Type_name
				Herc_Cargo[Herc_j].Container_Enclosed = Container_Enclosed
				Herc_Cargo[Herc_j].ParatrooperGroupSpawn = ParatrooperGroupSpawnInit
				Herc_Cargo[Herc_j].Cargo_Country = initiator:getCountry()
			------------------------------------------------------------------------------
				if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 5.0 then--aircraft on ground
					Herc_Cargo[Herc_j].offload_cargo = true
				else
			------------------------------------------------------------------------------
					if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 10.0 then--aircraft less than 10m above ground
						Herc_Cargo[Herc_j].all_cargo_survive_to_the_ground = true
					else
			------------------------------------------------------------------------------
						if Hercules_Cargo.Calculate_Object_Height_AGL(Cargo_Drop_initiator) < 100.0 then--aircraft more than 10m but less than 100m above ground
							Herc_Cargo[Herc_j].all_cargo_gets_destroyed = true
						else
			------------------------------------------------------------------------------
							Herc_Cargo[Herc_j].destroy_cargo_dropped_without_parachute = true--aircraft more than 100m above ground
						end
					end
				end
			------------------------------------------------------------------------------
				Herc_Cargo[Herc_j].scheduleFunctionID = timer.scheduleFunction(Hercules_Cargo.Cargo_Track, {Herc_Cargo[Herc_j]}, timer.getTime() + 0.1)
			end
		end
	end) -- pcall
	if not status then
		-- env.error(string.format("Cargo_Initialize: %s", result))
	else
		return result
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- EventHandlers
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function Hercules_Cargo.Hercules_Cargo_Drop_Events:onEvent(Cargo_Drop_Event)
	if Cargo_Drop_Event.id == world.event.S_EVENT_SHOT then
		GT_DisplayName = Weapon.getDesc(Cargo_Drop_Event.weapon).typeName:sub(15, -1)--Remove "weapons.bombs." from string
		 -- trigger.action.outTextForCoalition(coalition.side.BLUE, string.format("Cargo_Drop_Event: %s", Weapon.getDesc(Cargo_Drop_Event.weapon).typeName), 10)
		 -- trigger.action.outTextForCoalition(coalition.side.RED, string.format("Cargo_Drop_Event: %s", Weapon.getDesc(Cargo_Drop_Event.weapon).typeName), 10)
			 ---------------------------------------------------------------------------------------------------------------------------------
			if (GT_DisplayName == "Squad 30 x Soldier [7950lb]") then
				GT_Name = "Soldier M4 GRG"
				SoldierGroup = true
				ParatrooperGroupSpawnInit = true
				Hercules_Cargo.Cargo_Initialize(Cargo_Drop_Event.initiator, Cargo_Drop_Event.weapon, GT_Name, SoldierGroup)
			end
			 ---------------------------------------------------------------------------------------------------------------------------------
			if Hercules_Cargo.types[GT_DisplayName] then
				local GT_Name = Hercules_Cargo.types[GT_DisplayName]['name']
				local Cargo_Container_Enclosed = Hercules_Cargo.types[GT_DisplayName]['container']
				Hercules_Cargo.Cargo_Initialize(Cargo_Drop_Event.initiator, Cargo_Drop_Event.weapon, GT_Name, Cargo_Container_Enclosed)
			end
	end
end
world.addEventHandler(Hercules_Cargo.Hercules_Cargo_Drop_Events)

-- trigger.action.outTextForCoalition(coalition.side.BLUE, string.format("Cargo_Drop_Event.weapon: %s", Weapon.getDesc(Cargo_Drop_Event.weapon).typeName), 10)
-- trigger.action.outTextForCoalition(coalition.side.BLUE, tostring('Calculate_Object_Height_AGL: ' .. aaaaa), 10)
-- trigger.action.outTextForCoalition(coalition.side.BLUE, string.format("Speed: %.2f", Calculate_Object_Speed(Cargo_Drop_initiator)), 10)
-- trigger.action.outTextForCoalition(coalition.side.BLUE, string.format("Russian Interceptor Patrol scrambled from Nalchik"), 10)

-- function basicSerialize(var)
	-- if var == nil then
		-- return "\"\""
	-- else
		-- if ((type(var) == 'number') or
				-- (type(var) == 'boolean') or
				-- (type(var) == 'function') or
				-- (type(var) == 'table') or
				-- (type(var) == 'userdata') ) then
			-- return tostring(var)
		-- else
			-- if type(var) == 'string' then
				-- var = string.format('%q', var)
				-- return var
			-- end
		-- end
	-- end
-- end
	
-- function tableShow(tbl, loc, indent, tableshow_tbls) --based on serialize_slmod, this is a _G serialization
	-- tableshow_tbls = tableshow_tbls or {} --create table of tables
	-- loc = loc or ""
	-- indent = indent or ""
	-- if type(tbl) == 'table' then --function only works for tables!
		-- tableshow_tbls[tbl] = loc
		-- local tbl_str = {}
		-- tbl_str[#tbl_str + 1] = indent .. '{\n'
		-- for ind,val in pairs(tbl) do -- serialize its fields
			-- if type(ind) == "number" then
				-- tbl_str[#tbl_str + 1] = indent
				-- tbl_str[#tbl_str + 1] = loc .. '['
				-- tbl_str[#tbl_str + 1] = tostring(ind)
				-- tbl_str[#tbl_str + 1] = '] = '
			-- else
				-- tbl_str[#tbl_str + 1] = indent
				-- tbl_str[#tbl_str + 1] = loc .. '['
				-- tbl_str[#tbl_str + 1] = basicSerialize(ind)
				-- tbl_str[#tbl_str + 1] = '] = '
			-- end
			-- if ((type(val) == 'number') or (type(val) == 'boolean')) then
				-- tbl_str[#tbl_str + 1] = tostring(val)
				-- tbl_str[#tbl_str + 1] = ',\n'
			-- elseif type(val) == 'string' then
				-- tbl_str[#tbl_str + 1] = basicSerialize(val)
				-- tbl_str[#tbl_str + 1] = ',\n'
			-- elseif type(val) == 'nil' then -- won't ever happen, right?
				-- tbl_str[#tbl_str + 1] = 'nil,\n'
			-- elseif type(val) == 'table' then
				-- if tableshow_tbls[val] then
					-- tbl_str[#tbl_str + 1] = tostring(val) .. ' already defined: ' .. tableshow_tbls[val] .. ',\n'
				-- else
					-- tableshow_tbls[val] = loc ..	'[' .. basicSerialize(ind) .. ']'
					-- tbl_str[#tbl_str + 1] = tostring(val) .. ' '
					-- tbl_str[#tbl_str + 1] = tableShow(val,	loc .. '[' .. basicSerialize(ind).. ']', indent .. '		', tableshow_tbls)
					-- tbl_str[#tbl_str + 1] = ',\n'
				-- end
			-- elseif type(val) == 'function' then
				-- if debug and debug.getinfo then
					-- local fcnname = tostring(val)
					-- local info = debug.getinfo(val, "S")
					-- if info.what == "C" then
						-- tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', C function') .. ',\n'
					-- else
						-- if (string.sub(info.source, 1, 2) == [[./]]) then
							-- tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')' .. info.source) ..',\n'
						-- else
							-- tbl_str[#tbl_str + 1] = string.format('%q', fcnname .. ', defined in (' .. info.linedefined .. '-' .. info.lastlinedefined .. ')') ..',\n'
						-- end
					-- end
				-- else
					-- tbl_str[#tbl_str + 1] = 'a function,\n'
				-- end
			-- else
				-- tbl_str[#tbl_str + 1] = 'unable to serialize value type ' .. basicSerialize(type(val)) .. ' at index ' .. tostring(ind)
			-- end
		-- end
		-- tbl_str[#tbl_str + 1] = indent .. '}'
		-- return table.concat(tbl_str)
	-- end
-- end




-- function F10CargoDrop(GroupId, Unitname)
	-- local rootPath = missionCommands.addSubMenuForGroup(GroupId, "Cargo Drop")
	-- missionCommands.addCommandForGroup(GroupId, "Drop direction", rootPath, CruiseMissilesMessage, {GroupId, Unitname})
	-- missionCommands.addCommandForGroup(GroupId, "Drop distance", rootPath, ForwardConvoy, nil)
	-- local measurementsSetPath = missionCommands.addSubMenuForGroup(GroupId,"Set measurement units",rootPath)
	-- missionCommands.addCommandForGroup(GroupId, "Set to Imperial (feet, knts)",measurementsSetPath,setMeasurements,{GroupId, "imperial"})
	-- missionCommands.addCommandForGroup(GroupId, "Set to Metric (meters, km/h)",measurementsSetPath,setMeasurements,{GroupId, "metric"})
-- end

-- function Calculate_Object_Speed(object)
	-- return math.sqrt(object:getVelocity().x^2 + object:getVelocity().y^2 + object:getVelocity().z^2) * 3600 / 1852 -- knts
-- end

-- function vecDotProduct(vec1, vec2)
	-- return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
-- end

-- function Calculate_Aircraft_ForwardVelocity(Drop_initiator)
	-- return vecDotProduct(Drop_initiator:getPosition().x, Drop_initiator:getVelocity())
-- end

--- END HERCULES CARGO SUPPORT SECTION


  
--------------------------------[core\spawntemplates.lua]-------------------------------- 
 
env.info( "[JTF-1] spawntemplates" )
--------------------------------------------
--- Spawn Templates Defined in this file
--------------------------------------------
--
-- This file contains a library of templates to be used for spawn objects 
-- created for various modules and *MUST* be loaded prior to the 
-- calling module's Start() call (either in the module, or in the [module]_data.lua).
--

SPAWNTEMPLATES = {}
SPAWNTEMPLATES.traceTitle = "[JTF-1 SPAWNTEMPLATES] "
SPAWNTEMPLATES.version = "0.1"

SPAWNTEMPLATES.templates = {
	------------------------ BVR AIRCRAFT ------------------------
	["BVR_MIG23"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 84,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 5.5555555555556,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 531510.26758081,
					["x"] = 154464.47749365,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 577,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 84,
				["alt_type"] = "BARO",
				["skill"] = "Random",
				["speed"] = 5.5555555555556,
				["type"] = "MiG-23MLD",
				["unitId"] = 1566,
				["psi"] = 0,
				["y"] = 531510.26758081,
				["x"] = 154464.47749365,
				["name"] = "Aerial-1-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[2] = 
						{
							["CLSID"] = "{6980735A-44CC-4BB9-A1B5-591532F1DC69}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{B0DBC591-0F52-4F7D-AD7B-51E67725FB81}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{A5BAEAB7-6FAF-4236-AF72-0FD900F493F9}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{275A2855-4A79-4B2D-B082-91EA2ADF4691}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{CCF898C9-5BC7-49A4-9D1E-C3ED3D5166A1}",
						}, -- end of [6]
					}, -- end of ["pylons"]
					["fuel"] = "3800",
					["flare"] = 60,
					["chaff"] = 60,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Enfield11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "010",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 531510.26758081,
		["x"] = 154464.47749365,
		["name"] = "BVR_MIG23",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of ["BVR_MIG23"]
	["BVR_SU25"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAS",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 107,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 5.5555555555556,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 534989.23663351,
					["x"] = 154562.4766219,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 578,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 107,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["skill"] = "Random",
				["speed"] = 5.5555555555556,
				["type"] = "Su-25T",
				["unitId"] = 1567,
				["psi"] = 0,
				["y"] = 534989.23663351,
				["x"] = 154562.4766219,
				["name"] = "Aerial-2-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{682A481F-0CB5-4693-A382-D00DD4A156D7}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{637334E4-AB5A-47C0-83A6-51B7F1DF3CD5}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{D5435F26-F120-4FA3-9867-34ACE562EF1B}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{D5435F26-F120-4FA3-9867-34ACE562EF1B}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{E8D4652F-FD48-45B7-BA5B-2AE05BB5A9CF}",
						}, -- end of [5]
						[7] = 
						{
							["CLSID"] = "{E8D4652F-FD48-45B7-BA5B-2AE05BB5A9CF}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{D5435F26-F120-4FA3-9867-34ACE562EF1B}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{D5435F26-F120-4FA3-9867-34ACE562EF1B}",
						}, -- end of [9]
						[10] = 
						{
							["CLSID"] = "{637334E4-AB5A-47C0-83A6-51B7F1DF3CD5}",
						}, -- end of [10]
						[11] = 
						{
							["CLSID"] = "{682A481F-0CB5-4693-A382-D00DD4A156D7}",
						}, -- end of [11]
					}, -- end of ["pylons"]
					["fuel"] = "3790",
					["flare"] = 128,
					["chaff"] = 128,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 2,
					[2] = 1,
					["name"] = "Springfield11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "011",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 534989.23663351,
		["x"] = 154562.4766219,
		["name"] = "BVR_SU25",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 124,
	}, -- end of ["BVR_SU25"]
	["BVR_MIG29A"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 112,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 5.5555555555556,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 540071.18145709,
					["x"] = 154817.69397565,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 579,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 112,
				["alt_type"] = "BARO",
				["skill"] = "Random",
				["speed"] = 5.5555555555556,
				["type"] = "MiG-29A",
				["unitId"] = 1568,
				["psi"] = 0,
				["y"] = 540071.18145709,
				["x"] = 154817.69397565,
				["name"] = "Aerial-3-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{682A481F-0CB5-4693-A382-D00DD4A156D7}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{FBC29BFE-3D24-4C64-B81D-941239D12249}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{9B25D316-0434-4954-868F-D51DB1A38DF0}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{2BEC576B-CDF5-4B7F-961F-B0FA4312B841}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{9B25D316-0434-4954-868F-D51DB1A38DF0}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{FBC29BFE-3D24-4C64-B81D-941239D12249}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{682A481F-0CB5-4693-A382-D00DD4A156D7}",
						}, -- end of [7]
					}, -- end of ["pylons"]
					["fuel"] = "3376",
					["flare"] = 30,
					["chaff"] = 30,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040216030156,
				["callsign"] = 
				{
					[1] = 3,
					[2] = 1,
					["name"] = "Uzi11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "012",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 540071.18145709,
		["x"] = 154817.69397565,
		["name"] = "BVR_MIG29A",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 124,
	}, -- end of ["BVR_MIG29A"]
	["BVR_SU27"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 95,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 5.5555555555556,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 546218.38317547,
					["x"] = 154400.21235032,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 580,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 95,
				["alt_type"] = "BARO",
				["skill"] = "Random",
				["speed"] = 5.5555555555556,
				["type"] = "Su-27",
				["unitId"] = 1569,
				["psi"] = 0,
				["y"] = 546218.38317547,
				["x"] = 154400.21235032,
				["name"] = "Aerial-4-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{44EE8698-89F9-48EE-AF36-5FD31896A82F}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{FBC29BFE-3D24-4C64-B81D-941239D12249}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{E8069896-8435-4B90-95C0-01A03AE6E400}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{E8069896-8435-4B90-95C0-01A03AE6E400}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{E8069896-8435-4B90-95C0-01A03AE6E400}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{E8069896-8435-4B90-95C0-01A03AE6E400}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{B79C379A-9E87-4E50-A1EE-7F7E29C2E87A}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{FBC29BFE-3D24-4C64-B81D-941239D12249}",
						}, -- end of [9]
						[10] = 
						{
							["CLSID"] = "{44EE8698-89F9-48EE-AF36-5FD31896A82A}",
						}, -- end of [10]
					}, -- end of ["pylons"]
					["fuel"] = 5590.18,
					["flare"] = 96,
					["chaff"] = 96,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.615711114444,
				["callsign"] = 
				{
					[1] = 4,
					[2] = 1,
					["name"] = "Colt11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "013",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 546218.38317547,
		["x"] = 154400.21235032,
		["name"] = "BVR_SU27",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 127.5,
	}, -- end of ["BVR_SU27"]
	["BVR_F4"] = {
		["category"] = Group.Category.AIRPLANE,
		["dynSpawnTemplate"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 2000,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 256.94444444444,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["key"] = "CAP",
									["id"] = "EngageTargets",
									["number"] = 1,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Air",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 17,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 4,
												["name"] = 18,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 4,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 5,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "none;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "AAA",
													[14] = "SR SAM",
													[15] = "MR SAM",
													[16] = "LR SAM",
													[17] = "Aircraft Carriers",
													[18] = "Cruisers",
													[19] = "Destroyers",
													[20] = "Frigates",
													[21] = "Corvettes",
													[22] = "Light armed ships",
													[23] = "Unarmed ships",
													[24] = "Submarines",
													[25] = "Cruise missiles",
													[26] = "Antiship Missiles",
													[27] = "AA Missiles",
													[28] = "AG Missiles",
													[29] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 435467.56959117,
					["x"] = 30613.207113639,
					["speed_locked"] = true,
					["formation_template"] = "",
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 332,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 2000,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "iriaf-3-6564",
				["skill"] = "Random",
				["speed"] = 256.94444444444,
				["type"] = "F-4E-45MC",
				["unitId"] = 3236,
				["psi"] = 0,
				["onboard_num"] = "010",
				["y"] = 435467.56959117,
				["x"] = 30613.207113639,
				["name"] = "BVR_F4-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{F4_SARGENT_TANK_370_GAL}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{AIM-9M}",
						}, -- end of [2]
						[4] = 
						{
							["CLSID"] = "{AIM-9M}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{HB_F4E_AIM-7M}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{HB_F4E_AIM-7M}",
						}, -- end of [6]
						[8] = 
						{
							["CLSID"] = "{HB_F4E_AIM-7M}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{HB_F4E_AIM-7M}",
						}, -- end of [9]
						[10] = 
						{
							["CLSID"] = "{AIM-9M}",
						}, -- end of [10]
						[12] = 
						{
							["CLSID"] = "{AIM-9M}",
						}, -- end of [12]
						[13] = 
						{
							["CLSID"] = "{F4_SARGENT_TANK_370_GAL_R}",
						}, -- end of [13]
						[14] = 
						{
							["CLSID"] = "{HB_ALE_40_30_60}",
						}, -- end of [14]
					}, -- end of ["pylons"]
					["fuel"] = 5510.5,
					["flare"] = 30,
					["ammo_type"] = 1,
					["chaff"] = 120,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 0,
				["callsign"] = 100,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 435467.56959117,
		["x"] = 30613.207113639,
		["name"] = "BVR_F4",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["BVR_F4"]
	["BVR_F16"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 124.89419889801,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 220.97222222222,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["key"] = "CAP",
									["id"] = "EngageTargets",
									["number"] = 1,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Air",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 17,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 4,
												["name"] = 18,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 4,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 5,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "none;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "AAA",
													[14] = "SR SAM",
													[15] = "MR SAM",
													[16] = "LR SAM",
													[17] = "Aircraft Carriers",
													[18] = "Cruisers",
													[19] = "Destroyers",
													[20] = "Frigates",
													[21] = "Corvettes",
													[22] = "Light armed ships",
													[23] = "Unarmed ships",
													[24] = "Submarines",
													[25] = "Cruise missiles",
													[26] = "Antiship Missiles",
													[27] = "AA Missiles",
													[28] = "AG Missiles",
													[29] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 6,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 29,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 7,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 523278.34080823,
					["x"] = 154709.47531426,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 676,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 124.89419889801,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "18th agrs splinter",
				["skill"] = "Random",
				["speed"] = 220.97222222222,
				["AddPropAircraft"] = 
				{
				}, -- end of ["AddPropAircraft"]
				["type"] = "F-16C_50",
				["unitId"] = 1777,
				["psi"] = 0,
				["y"] = 523278.34080823,
				["x"] = 154709.47531426,
				["name"] = "BVR_F16-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "ALQ_184_Long",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [9]
					}, -- end of ["pylons"]
					["fuel"] = 3249,
					["flare"] = 60,
					["ammo_type"] = 1,
					["chaff"] = 60,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 6,
					[2] = 1,
					["name"] = "Ford11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "015",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 523278.34080823,
		["x"] = 154709.47531426,
		["name"] = "BVR_F16",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["BVR_F16"]
    ["BVR_F18"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAP",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 124.89419889801,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 179.86111111111,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["key"] = "CAP",
									["id"] = "EngageTargets",
									["number"] = 1,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Air",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 17,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 4,
												["name"] = 18,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 4,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 5,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "none;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "AAA",
													[14] = "SR SAM",
													[15] = "MR SAM",
													[16] = "LR SAM",
													[17] = "Aircraft Carriers",
													[18] = "Cruisers",
													[19] = "Destroyers",
													[20] = "Frigates",
													[21] = "Corvettes",
													[22] = "Light armed ships",
													[23] = "Unarmed ships",
													[24] = "Submarines",
													[25] = "Cruise missiles",
													[26] = "Antiship Missiles",
													[27] = "AA Missiles",
													[28] = "AG Missiles",
													[29] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 6,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 30,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["number"] = 7,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 527394.30419452,
					["x"] = 154758.47487839,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 677,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 124.89419889801,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "nawdc black",
				["skill"] = "Random",
				["speed"] = 179.86111111111,
				["AddPropAircraft"] = 
				{
				}, -- end of ["AddPropAircraft"]
				["type"] = "FA-18C_hornet",
				["unitId"] = 1778,
				["psi"] = 0,
				["dataCartridge"] = 
				{
					["GroupsPoints"] = 
					{
						["PB"] = 
						{
						}, -- end of ["PB"]
						["Sequence 2 Red"] = 
						{
						}, -- end of ["Sequence 2 Red"]
						["Sequence 3 Yellow"] = 
						{
						}, -- end of ["Sequence 3 Yellow"]
						["Sequence 1 Blue"] = 
						{
						}, -- end of ["Sequence 1 Blue"]
						["Start Location"] = 
						{
						}, -- end of ["Start Location"]
						["A/A Waypoint"] = 
						{
						}, -- end of ["A/A Waypoint"]
						["PP"] = 
						{
						}, -- end of ["PP"]
						["Initial Point"] = 
						{
						}, -- end of ["Initial Point"]
					}, -- end of ["GroupsPoints"]
					["Points"] = 
					{
					}, -- end of ["Points"]
				}, -- end of ["dataCartridge"]
				["y"] = 527394.30419452,
				["x"] = 154758.47487839,
				["name"] = "BVR_F18-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{LAU-115 - AIM-7M}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{FPU_8A_FUEL_TANK}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{8D399DDA-FF81-4F14-904D-099B34FE7918}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{A111396E-D3E8-4b9c-8AC9-2432489304D5}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{8D399DDA-FF81-4F14-904D-099B34FE7918}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{FPU_8A_FUEL_TANK}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{LAU-115 - AIM-7M}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}",
						}, -- end of [9]
					}, -- end of ["pylons"]
					["fuel"] = 4900,
					["flare"] = 60,
					["ammo_type"] = 1,
					["chaff"] = 60,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 7,
					[2] = 1,
					["name"] = "Chevy11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "016",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 527394.30419452,
		["x"] = 154758.47487839,
		["name"] = "BVR_F18_X",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	},	 -- end of ["BVR_F18"]
	------------------------ CAS AIRCRAFT ------------------------
	["CAS_MQ9"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAS",
		["uncontrolled"] = false,
		["taskSelected"] = true,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 2000,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 82.222222222222,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetUnlimitedFuel",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["key"] = "CAS",
									["id"] = "EngageTargets",
									["enabled"] = true,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Helicopters",
											[2] = "Ground Units",
											[3] = "Light armed ships",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 1,
												["name"] = 3,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["number"] = 5,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["variantIndex"] = 2,
												["name"] = 5,
												["formationIndex"] = 2,
												["value"] = 131074,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["number"] = 6,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 15,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["number"] = 7,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "none;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "AAA",
													[14] = "SR SAM",
													[15] = "MR SAM",
													[16] = "LR SAM",
													[17] = "Aircraft Carriers",
													[18] = "Cruisers",
													[19] = "Destroyers",
													[20] = "Frigates",
													[21] = "Corvettes",
													[22] = "Light armed ships",
													[23] = "Unarmed ships",
													[24] = "Submarines",
													[25] = "Cruise missiles",
													[26] = "Antiship Missiles",
													[27] = "AA Missiles",
													[28] = "AG Missiles",
													[29] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
								[8] = 
								{
									["number"] = 8,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [8]
								[9] = 
								{
									["number"] = 9,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [9]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 378428.12563875,
					["x"] = -11230.450562956,
					["speed_locked"] = true,
					["formation_template"] = "",
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 319,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 2000,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["skill"] = "High",
				["speed"] = 82.222222222222,
				["type"] = "MQ-9 Reaper",
				["unitId"] = 3086,
				["psi"] = 0,
				["onboard_num"] = "010",
				["y"] = 378428.12563875,
				["x"] = -11230.450562956,
				["name"] = "_MQ9",
				["payload"] = 
				{
					["pylons"] = 
					{
						[2] = 
						{
							["CLSID"] = "{DB769D48-67D7-42ED-A2BE-108D566C8B1E}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{DB769D48-67D7-42ED-A2BE-108D566C8B1E}",
						}, -- end of [3]
					}, -- end of ["pylons"]
					["fuel"] = 1300,
					["flare"] = 0,
					["chaff"] = 0,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = -1.8785757343974,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Enfield11",
					[3] = 1,
				}, -- end of ["callsign"]
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 378428.12563875,
		["x"] = -11230.450562956,
		["name"] = "_MQ9",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["BVR_MQ9"]
	["CAS_WINGLOON"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "CAS",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 2000,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 61.666666666667,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetUnlimitedFuel",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["key"] = "CAS",
									["id"] = "EngageTargets",
									["enabled"] = true,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Helicopters",
											[2] = "Ground Units",
											[3] = "Light armed ships",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 1,
												["name"] = 3,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["number"] = 5,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["variantIndex"] = 2,
												["name"] = 5,
												["formationIndex"] = 2,
												["value"] = 131074,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["number"] = 6,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 15,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["number"] = 7,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "none;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "AAA",
													[14] = "SR SAM",
													[15] = "MR SAM",
													[16] = "LR SAM",
													[17] = "Aircraft Carriers",
													[18] = "Cruisers",
													[19] = "Destroyers",
													[20] = "Frigates",
													[21] = "Corvettes",
													[22] = "Light armed ships",
													[23] = "Unarmed ships",
													[24] = "Submarines",
													[25] = "Cruise missiles",
													[26] = "Antiship Missiles",
													[27] = "AA Missiles",
													[28] = "AG Missiles",
													[29] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
								[8] = 
								{
									["number"] = 8,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [8]
								[9] = 
								{
									["number"] = 9,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 2,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [9]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 374191.87334164,
					["x"] = -10920.480882679,
					["speed_locked"] = true,
					["formation_template"] = "",
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 320,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 2000,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "plaaf",
				["skill"] = "High",
				["speed"] = 61.666666666667,
				["type"] = "WingLoong-I",
				["unitId"] = 3087,
				["psi"] = 0,
				["onboard_num"] = "010",
				["y"] = 374191.87334164,
				["x"] = -10920.480882679,
				["name"] = "wingloon",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "DIS_AKD-10",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "DIS_AKD-10",
						}, -- end of [2]
					}, -- end of ["pylons"]
					["fuel"] = 400,
					["flare"] = 0,
					["chaff"] = 0,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 0,
				["callsign"] = 100,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 374191.87334164,
		["x"] = -10920.480882679,
		["name"] = "wingloon",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["BVR_WINGLOON"]
    ------------------------ SEAD AIRCRAFT------------------------
	["SEAD_F16"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "SEAD",
		["uncontrolled"] = false,
		["taskSelected"] = true,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 124.89419889801,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 220.97222222222,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["key"] = "SEAD",
									["id"] = "EngageTargets",
									["enabled"] = true,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Air Defence",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 13,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["number"] = 5,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
													[1] = "Air Defence",
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "Air Defence;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "Aircraft Carriers",
													[14] = "Cruisers",
													[15] = "Destroyers",
													[16] = "Frigates",
													[17] = "Corvettes",
													[18] = "Light armed ships",
													[19] = "Unarmed ships",
													[20] = "Submarines",
													[21] = "Cruise missiles",
													[22] = "Antiship Missiles",
													[23] = "AA Missiles",
													[24] = "AG Missiles",
													[25] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["number"] = 6,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 31,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 7,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 523033.34298762,
					["x"] = 159609.43172652,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 678,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 124.89419889801,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "IAF 101st squadron",
				["skill"] = "Random",
				["speed"] = 220.97222222222,
				["AddPropAircraft"] = 
				{
				}, -- end of ["AddPropAircraft"]
				["type"] = "F-16C_50",
				["unitId"] = 1779,
				["psi"] = 0,
				["y"] = 523033.34298762,
				["x"] = 159609.43172652,
				["name"] = "SEAD_F16-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "ALQ_184_Long",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{F376DBEE-4CAE-41BA-ADD9-B2910AC95DEC}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [9]
						[10] = 
						{
							["CLSID"] = "{AN_ASQ_213}",
						}, -- end of [10]
						[11] = 
						{
							["CLSID"] = "{A111396E-D3E8-4b9c-8AC9-2432489304D5}",
						}, -- end of [11]
					}, -- end of ["pylons"]
					["fuel"] = 3249,
					["flare"] = 60,
					["ammo_type"] = 1,
					["chaff"] = 60,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 8,
					[2] = 1,
					["name"] = "Pontiac11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "017",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 523033.34298762,
		["x"] = 159609.43172652,
		["name"] = "SEAD_F16",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["SEAD_F16"]
	["SEAD_F18"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "SEAD",
		["uncontrolled"] = false,
		["taskSelected"] = true,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 151.17015748595,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 179.86111111111,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["key"] = "SEAD",
									["id"] = "EngageTargets",
									["number"] = 1,
									["auto"] = true,
									["params"] = 
									{
										["targetTypes"] = 
										{
											[1] = "Air Defence",
										}, -- end of ["targetTypes"]
										["priority"] = 0,
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 13,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 4,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 5,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["targetTypes"] = 
												{
													[1] = "Air Defence",
												}, -- end of ["targetTypes"]
												["name"] = 21,
												["value"] = "Air Defence;",
												["noTargetTypes"] = 
												{
													[1] = "Fighters",
													[2] = "Multirole fighters",
													[3] = "Bombers",
													[4] = "Helicopters",
													[5] = "UAVs",
													[6] = "Infantry",
													[7] = "Fortifications",
													[8] = "Tanks",
													[9] = "IFV",
													[10] = "APC",
													[11] = "Artillery",
													[12] = "Unarmed vehicles",
													[13] = "Aircraft Carriers",
													[14] = "Cruisers",
													[15] = "Destroyers",
													[16] = "Frigates",
													[17] = "Corvettes",
													[18] = "Light armed ships",
													[19] = "Unarmed ships",
													[20] = "Submarines",
													[21] = "Cruise missiles",
													[22] = "Antiship Missiles",
													[23] = "AA Missiles",
													[24] = "AG Missiles",
													[25] = "SA Missiles",
												}, -- end of ["noTargetTypes"]
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
								[6] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 6,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 32,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [6]
								[7] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 7,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [7]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 527051.30724566,
					["x"] = 159560.4321624,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 679,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 151.17015748595,
				["hardpoint_racks"] = true,
				["alt_type"] = "BARO",
				["livery_id"] = "nawdc black",
				["skill"] = "Random",
				["speed"] = 179.86111111111,
				["AddPropAircraft"] = 
				{
				}, -- end of ["AddPropAircraft"]
				["type"] = "FA-18C_hornet",
				["unitId"] = 1780,
				["psi"] = 0,
				["y"] = 527051.30724566,
				["x"] = 159560.4321624,
				["name"] = "SEAD_F18-1",
				["payload"] = 
				{
					["pylons"] = 
					{
						[1] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [1]
						[2] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [2]
						[3] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [3]
						[4] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [4]
						[5] = 
						{
							["CLSID"] = "{FPU_8A_FUEL_TANK}",
						}, -- end of [5]
						[6] = 
						{
							["CLSID"] = "{40EF17B7-F508-45de-8566-6FFECC0C1AB8}",
						}, -- end of [6]
						[7] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [7]
						[8] = 
						{
							["CLSID"] = "{B06DD79A-F21E-4EB9-BD9D-AB3844618C93}",
						}, -- end of [8]
						[9] = 
						{
							["CLSID"] = "{5CE2FF2A-645A-4197-B48D-8720AC69394F}",
						}, -- end of [9]
					}, -- end of ["pylons"]
					["fuel"] = 4900,
					["flare"] = 60,
					["ammo_type"] = 1,
					["chaff"] = 60,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 2.6040783413585,
				["callsign"] = 
				{
					[1] = 9,
					[2] = 1,
					["name"] = "Hornet11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "018",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 527051.30724566,
		["x"] = 159560.4321624,
		["name"] = "SEAD_F18",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 305,
	}, -- end of ["SEAD_F18"]
	--------------------SUPPORT AIRCRAFT---------------------
	["KC-135"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "Refueling",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 2000,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 220.97222222222,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetUnlimitedFuel",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = true,
									["id"] = "Tanker",
									["enabled"] = true,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "ActivateBeacon",
											["params"] = 
											{
												["type"] = 4,
												["AA"] = false,
												["callsign"] = "TKR",
												["system"] = 4,
												["channel"] = 1,
												["modeChannel"] = "X",
												["bearing"] = true,
												["frequency"] = 962000000,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
								[5] = 
								{
									["number"] = 5,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [5]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = -8563.6832781353,
					["x"] = -395281.46534495,
					["speed_locked"] = true,
					["formation_template"] = "",
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 1,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 2000,
				["alt_type"] = "BARO",
				["livery_id"] = "Standard USAF",
				["skill"] = "High",
				["speed"] = 220.97222222222,
				["AddPropAircraft"] = 
				{
					["VoiceCallsignLabel"] = "TO",
					["VoiceCallsignNumber"] = "11",
					["STN_L16"] = "07101",
				}, -- end of ["AddPropAircraft"]
				["type"] = "KC-135",
				["unitId"] = 1,
				["psi"] = 0,
				["onboard_num"] = "010",
				["y"] = -8563.6832781353,
				["x"] = -395281.46534495,
				["name"] = "KC-135-1",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = 90700,
					["flare"] = 0,
					["chaff"] = 0,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 0,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Texaco11",
					[3] = 1,
				}, -- end of ["callsign"]
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -8563.6832781353,
		["x"] = -395281.46534495,
		["name"] = "KC-135",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of [KC-135]
	["KC-135MPRS"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = true,
		["task"] = "Refueling",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 6096,
					["action"] = "Fly Over Point",
					["alt_type"] = "BARO",
					["speed"] = 164.44444444444,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "Tanker",
									["number"] = 1,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "ActivateBeacon",
											["params"] = 
											{
												["type"] = 4,
												["AA"] = false,
												["callsign"] = "RTB",
												["modeChannel"] = "Y",
												["channel"] = 60,
												["system"] = 5,
												["unitId"] = 20565,
												["bearing"] = true,
												["frequency"] = 1147000000,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 6,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = -87560.730212787,
					["x"] = -129296.58141675,
					["name"] = "",
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 1,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 6096,
				["alt_type"] = "BARO",
				["livery_id"] = "22nd ARW",
				["skill"] = "Excellent",
				["speed"] = 164.44444444444,
				["type"] = "KC135MPRS",
				["unitId"] = 1,
				["psi"] = 1.0660373467781,
				["y"] = -87560.730212787,
				["x"] = -129296.58141675,
				["name"] = "KC-135MPRS",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = 90700,
					["flare"] = 60,
					["chaff"] = 120,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = -1.0660373467782,
				["callsign"] = 
				{
					[1] = 3,
					[2] = 1,
					["name"] = "Shell11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "089",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -87560.730212787,
		["x"] = -129296.58141675,
		["name"] = "KC-135MPRS",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of [KC-135MPRS]
	["KC-130"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = true,
		["task"] = "Refueling",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 2438.4,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 172.5,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = true,
									["id"] = "Tanker",
									["enabled"] = true,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "ActivateBeacon",
											["params"] = 
											{
												["type"] = 4,
												["AA"] = false,
												["unitId"] = 16683,
												["modeChannel"] = "Y",
												["channel"] = 60,
												["system"] = 5,
												["callsign"] = "ARC",
												["bearing"] = true,
												["frequency"] = 1147000000,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = -11585.313345172,
					["x"] = -399323.02717468,
					["name"] = "",
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 2447,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 2438.4,
				["alt_type"] = "BARO",
				["livery_id"] = "default",
				["skill"] = "Excellent",
				["speed"] = 172.5,
				["type"] = "KC130",
				["unitId"] = 16683,
				["psi"] = 1.4236457627903,
				["y"] = -11585.313345172,
				["x"] = -399323.02717468,
				["name"] = "KC-130",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = 30000,
					["flare"] = 60,
					["chaff"] = 120,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = -1.4236457627903,
				["callsign"] = 
				{
					[1] = 2,
					[2] = 1,
					["name"] = "Arco11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "139",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -11585.313345172,
		["x"] = -399323.02717468,
		["name"] = "KC-130",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,		
	}, -- end of ["KC-130"]
	["AWACS-E3A"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = true,
		["task"] = "AWACS",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 6096,
					["action"] = "Fly Over Point",
					["alt_type"] = "BARO",
					["speed"] = 164.44444444444,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = true,
									["id"] = "AWACS",
									["enabled"] = true,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 46,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = -88627.624510964,
					["x"] = -129296.58141675,
					["name"] = "",
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 17446,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 6096,
				["alt_type"] = "BARO",
				["livery_id"] = "nato",
				["skill"] = "Excellent",
				["speed"] = 164.44444444444,
				["type"] = "E-3A",
				["unitId"] = 20566,
				["psi"] = 1.1124120783257,
				["y"] = -88627.624510964,
				["x"] = -129296.58141675,
				["name"] = "AWACS-E3A",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = 65000,
					["flare"] = 60,
					["chaff"] = 120,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = -1.1124120783257,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Overlord11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "090",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -88627.624510964,
		["x"] = -129296.58141675,
		["name"] = "AWACS-E3A",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of [AWACS-E3A]
  	["AWACS-E2D"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = true,
		["task"] = "AWACS",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 9144,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 133.61111111111,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "AWACS",
									["number"] = 1,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "EPLRS",
											["params"] = 
											{
												["value"] = true,
												["groupId"] = 38,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = -12187.736469214,
					["x"] = -399320.85899169,
					["name"] = "",
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 2452,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 9144,
				["alt_type"] = "BARO",
				["livery_id"] = "E-2D Demo",
				["skill"] = "High",
				["speed"] = 133.61111111111,
				["type"] = "E-2C",
				["unitId"] = 16697,
				["psi"] = 1.3887207292845,
				["y"] = -12187.736469214,
				["x"] = -399320.85899169,
				["name"] = "AWACS-E2D-1",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = "5624",
					["flare"] = 60,
					["chaff"] = 120,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = -1.3887207292845,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Overlord11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "143",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -12187.736469214,
		["x"] = -399320.85899169,
		["name"] = "AWACS-E2D",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,		
	}, -- end of ["AWACS-E2D"]
	["AWACS-A50"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "AWACS",
		["uncontrolled"] = false,
		["taskSelected"] = true,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 10972.8,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 220.97222222222,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = true,
									["id"] = "AWACS",
									["number"] = 1,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 3,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 1,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 4,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = false,
												["name"] = 19,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 315953.41096792,
					["x"] = 63905.857563882,
					["name"] = "",
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 588,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 10972.8,
				["alt_type"] = "BARO",
				["livery_id"] = "RF Air Force new",
				["skill"] = "High",
				["speed"] = 220.97222222222,
				["AddPropAircraft"] = 
				{
					["PropellorType"] = 0,
					["SoloFlight"] = false,
				}, -- end of ["AddPropAircraft"]
				["type"] = "A-50",
				["unitId"] = 1595,
				["psi"] = -1.7947587772958,
				["y"] = 315953.41096792,
				["x"] = 63905.857563882,
				["name"] = "RED_AWACS",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = "70000",
					["flare"] = 192,
					["chaff"] = 192,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 1.7947587772958,
				["callsign"] = 666,
				["onboard_num"] = "027",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 315953.41096792,
		["x"] = 63905.857563882,
		["name"] = "RED_AWACS",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of ["AWACS-RED"]
	["S3BTANKER"] = {
		["category"] = Group.Category.AIRPLANE,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["radioSet"] = false,
		["task"] = "Refueling",
		["uncontrolled"] = false,
		["route"] = 
		{
			["routeRelativeTOT"] = true,
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 1828.8,
					["action"] = "Turning Point",
					["alt_type"] = "BARO",
					["speed"] = 141.31944444444,
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = true,
									["id"] = "Tanker",
									["enabled"] = true,
									["params"] = 
									{
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = true,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "ActivateBeacon",
											["params"] = 
											{
												["type"] = 4,
												["AA"] = false,
												["callsign"] = "TKR",
												["system"] = 4,
												["channel"] = 1,
												["modeChannel"] = "X",
												["bearing"] = true,
												["frequency"] = 962000000,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "SetInvisible",
											["params"] = 
											{
												["value"] = true,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["type"] = "Turning Point",
					["ETA"] = 0,
					["ETA_locked"] = true,
					["y"] = 606748.96393416,
					["x"] = -358539.84033849,
					["formation_template"] = "",
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 1,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["alt"] = 1828.8,
				["alt_type"] = "BARO",
				["livery_id"] = "usaf standard",
				["skill"] = "High",
				["speed"] = 141.31944444444,
				["type"] = "S-3B Tanker",
				["unitId"] = 1,
				["psi"] = 0,
				["y"] = 606748.96393416,
				["x"] = -358539.84033849,
				["name"] = "Aerial-1-1",
				["payload"] = 
				{
					["pylons"] = 
					{
					}, -- end of ["pylons"]
					["fuel"] = "7813",
					["flare"] = 30,
					["chaff"] = 30,
					["gun"] = 100,
				}, -- end of ["payload"]
				["heading"] = 0,
				["callsign"] = 
				{
					[1] = 1,
					[2] = 1,
					["name"] = "Texaco11",
					[3] = 1,
				}, -- end of ["callsign"]
				["onboard_num"] = "010",
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 606748.96393416,
		["x"] = -358539.84033849,
		["name"] = "S3BTANKER",
		["communication"] = true,
		["start_time"] = 0,
		["modulation"] = 0,
		["frequency"] = 251,
	}, -- end of ["S3BTANKER"]
	------------------------ SAM ------------------------
	["SA2"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 30,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 570781.83160836,
					["x"] = 153693.01667557,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 573,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SNR_75V",
				["unitId"] = 1537,
				["y"] = 570781.83160836,
				["x"] = 153693.01667557,
				["name"] = "SA2-1",
				["heading"] = 0.0038885041518015,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1538,
				["y"] = 570734.73491097,
				["x"] = 153772.11573734,
				["name"] = "SA2-2",
				["heading"] = 5.4803338512622,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1539,
				["y"] = 570888.63214085,
				["x"] = 153693.23488244,
				["name"] = "SA2-3",
				["heading"] = 1.535889741755,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1540,
				["y"] = 570683.58738257,
				["x"] = 153691.1889813,
				["name"] = "SA2-4",
				["heading"] = 4.6774823953448,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1541,
				["y"] = 570734.96223331,
				["x"] = 153607.76167943,
				["name"] = "SA2-5",
				["heading"] = 3.8048177693476,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1542,
				["y"] = 570839.75783594,
				["x"] = 153605.2611336,
				["name"] = "SA2-6",
				["heading"] = 2.3561944901923,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S_75M_Volhov",
				["unitId"] = 1543,
				["y"] = 570836.12067836,
				["x"] = 153773.70699378,
				["name"] = "SA2-7",
				["heading"] = 0.92502450355699,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZIL-131 KUNG",
				["unitId"] = 1544,
				["y"] = 570826.46777346,
				["x"] = 153722.97334767,
				["name"] = "SA2-8",
				["heading"] = 4.1713369122664,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZIL-131 KUNG",
				["unitId"] = 1545,
				["y"] = 570829.72075048,
				["x"] = 153718.14362543,
				["name"] = "SA2-9",
				["heading"] = 4.1713369122664,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "p-19 s-125 sr",
				["unitId"] = 1546,
				["y"] = 570947.4874583,
				["x"] = 153631.87417734,
				["name"] = "SA2-10",
				["heading"] = 2.2165681500328,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320 APA-5D",
				["unitId"] = 1547,
				["y"] = 570946.21636909,
				["x"] = 153643.07562982,
				["name"] = "SA2-11",
				["heading"] = 0.68067840827779,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATMZ-5",
				["unitId"] = 1548,
				["y"] = 570610.66947625,
				["x"] = 153574.73104242,
				["name"] = "SA2-12",
				["heading"] = 0.87266462599716,
				["playerCanDrive"] = false,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATMZ-5",
				["unitId"] = 1549,
				["y"] = 570630.57256833,
				["x"] = 153555.65724584,
				["name"] = "SA2-13",
				["heading"] = 1.0297442586767,
				["playerCanDrive"] = false,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320T",
				["unitId"] = 1550,
				["y"] = 570696.9162086,
				["x"] = 153524.97331222,
				["name"] = "SA2-14",
				["heading"] = 5.4279739737024,
				["playerCanDrive"] = false,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320T",
				["unitId"] = 1551,
				["y"] = 570711.01423216,
				["x"] = 153541.55922228,
				["name"] = "SA2-15",
				["heading"] = 5.3407075111026,
				["playerCanDrive"] = false,
			}, -- end of [15]
		}, -- end of ["units"]
		["y"] = 570781.83160836,
		["x"] = 153693.01667557,
		["name"] = "SA2_X",
		["start_time"] = 0,
	}, -- end of ["SA2"]	
	["SA3"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 35,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 573114.92135768,
					["x"] = 153604.67378327,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 574,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "snr s-125 tr",
				["unitId"] = 1552,
				["y"] = 573114.92135768,
				["x"] = 153604.67378327,
				["name"] = "SA6-1-12",
				["heading"] = 6.2641478001644,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "5p73 s-125 ln",
				["unitId"] = 1553,
				["y"] = 573135.33272216,
				["x"] = 153550.27823879,
				["name"] = "SA6-1-13",
				["heading"] = 3.1590459461097,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "5p73 s-125 ln",
				["unitId"] = 1554,
				["y"] = 573099.80572107,
				["x"] = 153549.0222337,
				["name"] = "SA6-1-14",
				["heading"] = 3.1590459461097,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "5p73 s-125 ln",
				["unitId"] = 1555,
				["y"] = 573153.45508131,
				["x"] = 153578.26920935,
				["name"] = "SA6-1-15",
				["heading"] = 3.1590459461097,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "5p73 s-125 ln",
				["unitId"] = 1556,
				["y"] = 573078.81249316,
				["x"] = 153576.29548706,
				["name"] = "SA6-1-16",
				["heading"] = 3.1590459461097,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "p-19 s-125 sr",
				["unitId"] = 1557,
				["y"] = 573041.63524492,
				["x"] = 153638.42740326,
				["name"] = "SA6-1-17",
				["heading"] = 6.2641478001644,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZIL-131 KUNG",
				["unitId"] = 1558,
				["y"] = 573131.33903364,
				["x"] = 153604.47659312,
				["name"] = "SA6-1-18",
				["heading"] = 1.5707963267949,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 1559,
				["y"] = 573128.615675,
				["x"] = 153611.35397283,
				["name"] = "SA6-1-19",
				["heading"] = 3.1241393610699,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 1560,
				["y"] = 573139.09924472,
				["x"] = 153677.82188039,
				["name"] = "SA6-1-20",
				["heading"] = 1.6057029118348,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 1561,
				["y"] = 573139.14210189,
				["x"] = 153672.09668672,
				["name"] = "SA6-1-21",
				["heading"] = 1.6406094968747,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 1562,
				["y"] = 573139.44830985,
				["x"] = 153667.40149797,
				["name"] = "SA6-1-22",
				["heading"] = 1.5707963267949,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 1563,
				["y"] = 573048.41890609,
				["x"] = 153644.47684558,
				["name"] = "SA6-1-23",
				["heading"] = 1.6406094968747,
				["playerCanDrive"] = false,
			}, -- end of [12]
		}, -- end of ["units"]
		["y"] = 573114.92135768,
		["x"] = 153604.67378327,
		["name"] = "SA3_X",
		["start_time"] = 0,
	}, -- end of ["SA3"]
	["SA6"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 35,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 575462.13928984,
					["x"] = 153514.10246575,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 20,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 90,
												["name"] = 24,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 550,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Kub 1S91 str",
				["unitId"] = 1455,
				["y"] = 575462.13928984,
				["x"] = 153514.10246575,
				["name"] = "SA6-1-1",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Kub 2P25 ln",
				["unitId"] = 1456,
				["y"] = 575366.42777193,
				["x"] = 153530.31343414,
				["name"] = "SA6-1-2",
				["heading"] = 1.5707963267949,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Kub 2P25 ln",
				["unitId"] = 1457,
				["y"] = 575564.39203127,
				["x"] = 153518.09304432,
				["name"] = "SA6-1-3",
				["heading"] = 4.6949356878648,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Kub 2P25 ln",
				["unitId"] = 1458,
				["y"] = 575457.24346135,
				["x"] = 153619.92406734,
				["name"] = "SA6-1-4",
				["heading"] = 3.1764992386297,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Kub 2P25 ln",
				["unitId"] = 1459,
				["y"] = 575465.48565904,
				["x"] = 153414.93263457,
				["name"] = "SA6-1-5",
				["heading"] = 7.105427357601e-15,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-10",
				["unitId"] = 1460,
				["y"] = 575566.7083547,
				["x"] = 153384.46016622,
				["name"] = "SA6-1-6",
				["heading"] = 5.4628805587423,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-10",
				["unitId"] = 1461,
				["y"] = 575574.13989236,
				["x"] = 153393.66111761,
				["name"] = "SA6-1-7",
				["heading"] = 5.6374134839417,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 1462,
				["y"] = 575442.11965592,
				["x"] = 153488.49646889,
				["name"] = "SA6-1-8",
				["heading"] = 4.7298422729046,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320-31",
				["unitId"] = 1463,
				["y"] = 575482.15635911,
				["x"] = 153471.92997429,
				["name"] = "SA6-1-9",
				["heading"] = 3.1939525311496,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320-31",
				["unitId"] = 1464,
				["y"] = 575490.95802681,
				["x"] = 153471.92997429,
				["name"] = "SA6-1-10",
				["heading"] = 3.1764992386297,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-375 PBU",
				["unitId"] = 1465,
				["y"] = 575442.02541085,
				["x"] = 153492.06416023,
				["name"] = "SA6-1-11",
				["heading"] = 4.7298422729046,
				["playerCanDrive"] = false,
			}, -- end of [11]
		}, -- end of ["units"]
		["y"] = 575462.13928984,
		["x"] = 153514.10246575,
		["name"] = "SA6",
		["start_time"] = 0,
	}, -- end of ["SA6"]
    ["SA8"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 35,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 576326.90126669,
					["x"] = 153524.80926108,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 575,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 1564,
				["y"] = 576326.90126669,
				["x"] = 153524.80926108,
				["name"] = "SA8-1",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 576326.90126669,
		["x"] = 153524.80926108,
		["name"] = "SA8_X",
		["start_time"] = 0,
	},  -- end of ["SA8"]
    ["SA10"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 35,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 577222.62747304,
					["x"] = 153527.90695684,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 20,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 90,
												["name"] = 24,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
								[4] = 
								{
									["number"] = 4,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [4]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 549,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 40B6M tr",
				["unitId"] = 1425,
				["y"] = 577222.62747304,
				["x"] = 153527.90695684,
				["name"] = "SAM_Sa3Battery-1-1",
				["heading"] = 1.5707963267949,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 40B6MD sr",
				["unitId"] = 1426,
				["y"] = 577104.74560372,
				["x"] = 153512.34231908,
				["name"] = "SAM_Sa3Battery-1-2",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 54K6 cp",
				["unitId"] = 1427,
				["y"] = 576976.07279779,
				["x"] = 153504.32772185,
				["name"] = "SAM_Sa3Battery-1-3",
				["heading"] = 7.105427357601e-15,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 64H6E sr",
				["unitId"] = 1428,
				["y"] = 576976.07279779,
				["x"] = 153550.42298466,
				["name"] = "SAM_Sa3Battery-1-4",
				["heading"] = 7.105427357601e-15,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85C ln",
				["unitId"] = 1429,
				["y"] = 577224.00815973,
				["x"] = 153444.55697356,
				["name"] = "SAM_Sa3Battery-1-5",
				["heading"] = 7.105427357601e-15,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85D ln",
				["unitId"] = 1430,
				["y"] = 577206.52282554,
				["x"] = 153445.40831626,
				["name"] = "SAM_Sa3Battery-1-6",
				["heading"] = 0.17453292519941,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85D ln",
				["unitId"] = 1431,
				["y"] = 577240.85474953,
				["x"] = 153445.35934062,
				["name"] = "SAM_Sa3Battery-1-7",
				["heading"] = 6.1086523819802,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85C ln",
				["unitId"] = 1432,
				["y"] = 577223.04309933,
				["x"] = 153610.54736317,
				["name"] = "SAM_Sa3Battery-1-8",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85D ln",
				["unitId"] = 1433,
				["y"] = 577205.5118403,
				["x"] = 153609.84664181,
				["name"] = "SAM_Sa3Battery-1-9",
				["heading"] = 2.9670597283904,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "S-300PS 5P85D ln",
				["unitId"] = 1434,
				["y"] = 577240.62201673,
				["x"] = 153609.84664181,
				["name"] = "SAM_Sa3Battery-1-10",
				["heading"] = 3.3161255787892,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "generator_5i57",
				["unitId"] = 1435,
				["y"] = 577034.95033794,
				["x"] = 153536.99283452,
				["name"] = "SAM_Sa3Battery-1-11",
				["heading"] = 4.7123889803847,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "generator_5i57",
				["unitId"] = 1436,
				["y"] = 577035.10936011,
				["x"] = 153527.06935461,
				["name"] = "SAM_Sa3Battery-1-12",
				["heading"] = 4.7123889803847,
				["playerCanDrive"] = false,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-5",
				["unitId"] = 1437,
				["y"] = 577053.99278816,
				["x"] = 153587.73077582,
				["name"] = "SAM_Sa3Battery-1-13",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-5",
				["unitId"] = 1438,
				["y"] = 577043.36203865,
				["x"] = 153587.73077582,
				["name"] = "SAM_Sa3Battery-1-14",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 1439,
				["y"] = 577285.43890025,
				["x"] = 153506.95927751,
				["name"] = "SAM_Sa3Battery-1-15",
				["heading"] = 4.7123889803847,
				["playerCanDrive"] = false,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-60_Maz",
				["unitId"] = 1440,
				["y"] = 577071.27155213,
				["x"] = 153461.15560113,
				["name"] = "SAM_Sa3Battery-1-16",
				["heading"] = 0.78539816339741,
				["playerCanDrive"] = true,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-60_Maz",
				["unitId"] = 1441,
				["y"] = 577064.1594656,
				["x"] = 153468.26768765,
				["name"] = "SAM_Sa3Battery-1-17",
				["heading"] = 0.78539816339741,
				["playerCanDrive"] = true,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 1442,
				["y"] = 577285.1003477,
				["x"] = 153544.23418445,
				["name"] = "SAM_Sa3Battery-1-18",
				["heading"] = 4.7123889803847,
				["playerCanDrive"] = false,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Tor 9A331",
				["unitId"] = 1454,
				["y"] = 577150.52319232,
				["x"] = 153483.20163464,
				["name"] = "SAM_Sa10-1",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [19]
		}, -- end of ["units"]
		["y"] = 577222.62747304,
		["x"] = 153527.90695684,
		["name"] = "SA10_X",
		["start_time"] = 0,
	},  -- end of ["SA10"]
    ["SA11"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 34,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 578090.35719926,
					["x"] = 153490.60088682,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 572,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk SR 9S18M1",
				["unitId"] = 1525,
				["y"] = 578090.35719926,
				["x"] = 153490.60088682,
				["name"] = "SA11-1",
				["heading"] = 0,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk LN 9A310M1",
				["unitId"] = 1526,
				["y"] = 578191.23474919,
				["x"] = 153493.25724187,
				["name"] = "SA11-2",
				["heading"] = 4.7123889803847,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk LN 9A310M1",
				["unitId"] = 1527,
				["y"] = 577988.10445784,
				["x"] = 153486.61030825,
				["name"] = "SA11-3",
				["heading"] = 1.553343034275,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk LN 9A310M1",
				["unitId"] = 1528,
				["y"] = 578095.25302775,
				["x"] = 153384.77928523,
				["name"] = "SA11-4",
				["heading"] = 0.034906585039887,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk LN 9A310M1",
				["unitId"] = 1529,
				["y"] = 578087.01083006,
				["x"] = 153589.770718,
				["name"] = "SA11-5",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-10",
				["unitId"] = 1530,
				["y"] = 577985.78813441,
				["x"] = 153620.24318635,
				["name"] = "SA11-6",
				["heading"] = 2.3212879051525,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ATZ-10",
				["unitId"] = 1531,
				["y"] = 577978.35659675,
				["x"] = 153611.04223496,
				["name"] = "SA11-7",
				["heading"] = 2.4958208303519,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 1532,
				["y"] = 578111.78229705,
				["x"] = 153518.2375093,
				["name"] = "SA11-8",
				["heading"] = 1.5882496193148,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320-31",
				["unitId"] = 1533,
				["y"] = 578070.34013,
				["x"] = 153532.77337828,
				["name"] = "SA11-9",
				["heading"] = 0.05235987755983,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-4320-31",
				["unitId"] = 1534,
				["y"] = 578061.5384623,
				["x"] = 153532.77337828,
				["name"] = "SA11-10",
				["heading"] = 0.034906585039887,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Ural-375 PBU",
				["unitId"] = 1535,
				["y"] = 578111.78229705,
				["x"] = 153513.20410613,
				["name"] = "SA11-11",
				["heading"] = 1.5882496193148,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "SA-11 Buk CC 9S470M1",
				["unitId"] = 1536,
				["y"] = 578072.68953243,
				["x"] = 153476.6280431,
				["name"] = "SA11-12",
				["heading"] = 1.553343034275,
				["playerCanDrive"] = false,
			}, -- end of [12]
		}, -- end of ["units"]
		["y"] = 578090.35719926,
		["x"] = 153490.60088682,
		["name"] = "SA11_X",
		["start_time"] = 0,
	},  -- end of ["SA11"]
    ["SA15"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 578599.66302873,
						["x"] = 153482.38437486,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 578599.66302873,
						["x"] = 153482.38437486,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 34,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 578599.66302873,
					["x"] = 153482.38437486,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 576,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "High",
				["coldAtStart"] = false,
				["type"] = "Tor 9A331",
				["unitId"] = 1565,
				["y"] = 578599.66302873,
				["x"] = 153482.38437486,
				["name"] = "SA15-1",
				["heading"] = 4.7314728703886,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 578599.66302873,
		["x"] = 153482.38437486,
		["name"] = "SA15_X",
		["start_time"] = 0,
	},  -- end of ["SA15"]
    ["SA19"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299214.22371761,
					["x"] = 39623.843013552,
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 2,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
								[3] = 
								{
									["number"] = 3,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = true,
												["name"] = 20,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [3]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 682,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "2S6 Tunguska",
				["unitId"] = 1800,
				["y"] = 299214.22371761,
				["x"] = 39623.843013552,
				["name"] = "SA19-1",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299214.22371761,
		["x"] = 39623.843013552,
		["name"] = "SA19",
		["start_time"] = 0,
	},  -- end of ["SA19"]
	------------------------ AAA ------------------------
	["ZSU23_Shilka"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299328.09367735,
					["x"] = 39637.172381306,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 91,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "ZSU-23-4 Shilka",
				["unitId"] = 481,
				["y"] = 299328.09367735,
				["x"] = 39637.172381306,
				["name"] = "Unit #209",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299328.09367735,
		["x"] = 39637.172381306,
		["name"] = "AAA_Zsu23Shilka",
		["start_time"] = 0,
	},  -- end of ["ZSU23_Shilka"]
    ["ZU23_Emp"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299298.36197716,
					["x"] = 39637.779150698,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 89,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "ZU-23 Emplacement",
				["unitId"] = 479,
				["y"] = 299298.36197716,
				["x"] = 39637.779150698,
				["name"] = "Unit #207",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299298.36197716,
		["x"] = 39637.779150698,
		["name"] = "AAA_Zu23Emplacement",
		["start_time"] = 0,
	},  -- end of ["ZU23_Emp"]
    ["ZU23_Ural"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299282.72696715,
					["x"] = 39636.654073691,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 88,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 478,
				["y"] = 299282.72696715,
				["x"] = 39636.654073691,
				["name"] = "Unit #206",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299282.72696715,
		["x"] = 39636.654073691,
		["name"] = "AAA_Zu23Ural",
		["start_time"] = 0,
	}, -- end of ["ZU23_Ural"]
	["ZU23_Closed"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 299353.56779192,
						["x"] = 39637.047214632,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 299324.21254406,
						["x"] = 39636.129863136,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299311.94102036,
					["x"] = 39637.695245398,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 0,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 90,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "ZU-23 Emplacement Closed",
				["unitId"] = 480,
				["y"] = 299311.94102036,
				["x"] = 39637.695245398,
				["name"] = "Unit #208",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299311.94102036,
		["x"] = 39637.695245398,
		["name"] = "AAA_Zu23Closed",
		["start_time"] = 0,
	}, -- end of [ZU23_Closed]	
	----------------------- MANPADS -----------------------
	["SA18Manpads"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299292.29428324,
					["x"] = 39611.688066858,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 4,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 92,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "SA-18 Igla manpad",
				["unitId"] = 482,
				["y"] = 299292.29428324,
				["x"] = 39611.688066858,
				["name"] = "Unit #210",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299292.29428324,
		["x"] = 39611.688066858,
		["name"] = "SAM_Sa18Manpads",
		["start_time"] = 0,
	}, -- end of [SA18Manpads]
	["SA18SManpads"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 299317.36320321,
						["x"] = 39529.033326712,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 299320.60780347,
						["x"] = 39533.359460394,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 299308.07028743,
					["x"] = 39613.508375033,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 4,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 93,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "SA-18 Igla-S manpad",
				["unitId"] = 483,
				["y"] = 299308.07028743,
				["x"] = 39613.508375033,
				["name"] = "Unit #211",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 299308.07028743,
		["x"] = 39613.508375033,
		["name"] = "SAM_Sa18sManpads",
		["start_time"] = 0,
	}, -- end of [SA18SManpads]
	------------------------ CAMP ------------------------
	["CAMP_Heavy"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 30,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = -850039.55005353,
					["x"] = 507552.14703332,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 17483,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 20656,
				["y"] = -850039.55005353,
				["x"] = 507552.14703332,
				["name"] = "CAMP_Heavy",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = -850039.55005353,
		["x"] = 507552.14703332,
		["name"] = "CAMP_Heavy",
		["start_time"] = 0,
	}, -- end of ["CAMP_Heavy"]
	["CAMP_Tent_Group"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 21,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 289225.29837187,
					["x"] = 40597.069277546,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 73,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "tentepetite_vert",
				["unitId"] = 448,
				["y"] = 289225.29837187,
				["x"] = 40597.069277546,
				["name"] = "Unit #183",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "tente_verte",
				["unitId"] = 449,
				["y"] = 289203.1385953,
				["x"] = 40609.827936785,
				["name"] = "Unit #184",
				["heading"] = 0.069813170079773,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tente_verte",
				["unitId"] = 450,
				["y"] = 289247.45814844,
				["x"] = 40585.429798943,
				["name"] = "Unit #185",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tentepetite_vert",
				["unitId"] = 451,
				["y"] = 289211.86820425,
				["x"] = 40594.159407896,
				["name"] = "Unit #186",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tente_verte",
				["unitId"] = 452,
				["y"] = 289240.29539238,
				["x"] = 40610.051772912,
				["name"] = "Unit #187",
				["heading"] = 4.8869219055841,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Container_Vert",
				["unitId"] = 453,
				["y"] = 289199.7810534,
				["x"] = 40591.025702118,
				["name"] = "Unit #188",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Container_Vert",
				["unitId"] = 454,
				["y"] = 289230.44660279,
				["x"] = 40574.46182872,
				["name"] = "Unit #189",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tente_verte",
				["unitId"] = 455,
				["y"] = 289217.44400127,
				["x"] = 40579.772531204,
				["name"] = "Unit #190",
				["heading"] = 0.4014257279587,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tentepetite_vert",
				["unitId"] = 456,
				["y"] = 289217.01643517,
				["x"] = 40621.691251516,
				["name"] = "Unit #191",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Tente H_verte",
				["unitId"] = 461,
				["y"] = 289221.76804989,
				["x"] = 40560.906732556,
				["name"] = "Unit #196",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tentepetite_vert",
				["unitId"] = 462,
				["y"] = 289206.58029006,
				["x"] = 40572.63999098,
				["name"] = "Unit #197",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Tente H_verte",
				["unitId"] = 463,
				["y"] = 289247.52799094,
				["x"] = 40566.742969199,
				["name"] = "Unit #198",
				["heading"] = 5.9864793343406,
				["playerCanDrive"] = false,
			}, -- end of [12]
		}, -- end of ["units"]
		["y"] = 289225.29837187,
		["x"] = 40597.069277546,
		["name"] = "CAMP_Tent_Group",
		["start_time"] = 0,
	}, -- end of [CAMP_Tent_Group]
	["CAMP_Inf_02"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 20,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 288079.26256212,
					["x"] = 42645.403272296,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 4,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 1,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["enabled"] = true,
									["auto"] = false,
									["id"] = "WrappedAction",
									["number"] = 2,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 57,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Paratrooper AKS-74",
				["unitId"] = 367,
				["y"] = 288079.26256212,
				["x"] = 42645.403272296,
				["name"] = "Unit #104",
				["heading"] = 2.8448866807508,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 368,
				["y"] = 288069.14056436,
				["x"] = 42636.996867373,
				["name"] = "Unit #105",
				["heading"] = 5.0789081233035,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Paratrooper RPG-16",
				["unitId"] = 369,
				["y"] = 288078.76029292,
				["x"] = 42635.106753823,
				["name"] = "Unit #106",
				["heading"] = 3.6651914291881,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 370,
				["y"] = 288088.5545422,
				["x"] = 42637.618099792,
				["name"] = "Unit #107",
				["heading"] = 2.8448866807508,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 371,
				["y"] = 288088.05227301,
				["x"] = 42647.412349072,
				["name"] = "Unit #108",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Paratrooper RPG-16",
				["unitId"] = 445,
				["y"] = 288095.83744551,
				["x"] = 42639.124907373,
				["name"] = "Unit #180",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 446,
				["y"] = 288073.98873558,
				["x"] = 42653.941848591,
				["name"] = "Unit #181",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 447,
				["y"] = 288071.97965881,
				["x"] = 42644.398733909,
				["name"] = "Unit #182",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 457,
				["y"] = 288066.95696687,
				["x"] = 42649.421425847,
				["name"] = "Unit #192",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 458,
				["y"] = 288083.28071567,
				["x"] = 42654.946386979,
				["name"] = "Unit #193",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 459,
				["y"] = 288093.07496495,
				["x"] = 42644.901003102,
				["name"] = "Unit #194",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Infantry AK",
				["unitId"] = 460,
				["y"] = 288085.03865785,
				["x"] = 42629.581792691,
				["name"] = "Unit #195",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = false,
			}, -- end of [12]
		}, -- end of ["units"]
		["y"] = 288079.26256212,
		["x"] = 42645.403272296,
		["name"] = "CAMP_Inf_02",
		["start_time"] = 0,
		["hiddenOnPlanner"] = false,
	}, -- end of [CAMP_Inf_02]
    ----------------------- CONVOY ------------------------
	["CON_light"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 307002.29266054,
						["x"] = 36451.947799565,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 307002.29266054,
						["x"] = 36451.947799565,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 5,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 306991.33844617,
					["x"] = 36455.435715355,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "On Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 45,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 326,
				["y"] = 306991.33844617,
				["x"] = 36455.435715355,
				["name"] = "Unit #033",
				["heading"] = 2.8333339754249,
				["playerCanDrive"] = false,
				["wagons"] = 
				{
				}, -- end of ["wagons"]
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 327,
				["y"] = 306962.75232017,
				["x"] = 36464.537000937,
				["name"] = "Unit #034",
				["heading"] = 1.8790433242373,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 328,
				["y"] = 306934.16599896,
				["x"] = 36473.637673398,
				["name"] = "Unit #035",
				["heading"] = 1.8790149274913,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 329,
				["y"] = 306905.57963757,
				["x"] = 36482.738219676,
				["name"] = "Unit #036",
				["heading"] = 1.8790045696829,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 PBU",
				["unitId"] = 330,
				["y"] = 306876.99344612,
				["x"] = 36491.839299659,
				["name"] = "Unit #079",
				["heading"] = 1.8790140394514,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 331,
				["y"] = 306848.40800062,
				["x"] = 36500.942721509,
				["name"] = "Unit #080",
				["heading"] = 1.8790787459442,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 332,
				["y"] = 306819.82419292,
				["x"] = 36510.051281374,
				["name"] = "Unit #081",
				["heading"] = 1.8792307204181,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 333,
				["y"] = 306791.24378837,
				["x"] = 36519.170500361,
				["name"] = "Unit #083",
				["heading"] = 1.8795438987433,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 334,
				["y"] = 306762.66880464,
				["x"] = 36528.306677043,
				["name"] = "Unit #084",
				["heading"] = 1.8801155465484,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 335,
				["y"] = 306734.09679001,
				["x"] = 36537.452161264,
				["name"] = "Unit #085",
				["heading"] = 1.8805447152192,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 336,
				["y"] = 306705.52412294,
				["x"] = 36546.595611428,
				["name"] = "Unit #086",
				["heading"] = 1.8805410215421,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 337,
				["y"] = 306676.95006854,
				["x"] = 36555.734724067,
				["name"] = "Unit #087",
				["heading"] = 1.8803837453141,
				["playerCanDrive"] = false,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "SKP-11",
				["unitId"] = 342,
				["y"] = 306648.37513627,
				["x"] = 36564.871092641,
				["name"] = "Unit #088",
				["heading"] = 1.8802767356983,
				["playerCanDrive"] = false,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 343,
				["y"] = 306619.79957931,
				["x"] = 36574.005507597,
				["name"] = "Unit #089",
				["heading"] = 1.8802038056136,
				["playerCanDrive"] = false,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 344,
				["y"] = 306591.22351138,
				["x"] = 36583.138324052,
				["name"] = "Unit #090",
				["heading"] = 1.8801457366544,
				["playerCanDrive"] = false,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 345,
				["y"] = 306562.64680561,
				["x"] = 36592.269144119,
				["name"] = "Unit #091",
				["heading"] = 1.8800874621262,
				["playerCanDrive"] = false,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 346,
				["y"] = 306534.06930442,
				["x"] = 36601.39747612,
				["name"] = "Unit #092",
				["heading"] = 1.8799869866622,
				["playerCanDrive"] = false,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 347,
				["y"] = 306505.49163701,
				["x"] = 36610.525286639,
				["name"] = "Unit #093",
				["heading"] = 1.8799607746795,
				["playerCanDrive"] = false,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 348,
				["y"] = 306476.91389706,
				["x"] = 36619.652870086,
				["name"] = "Unit #094",
				["heading"] = 1.8799518773351,
				["playerCanDrive"] = false,
			}, -- end of [19]
		}, -- end of ["units"]
		["y"] = 306991.33844617,
		["x"] = 36455.435715355,
		["name"] = "CONVOY_light-1",
		["start_time"] = 0,
	},  -- end of ["CON_light"]
    ["CON_heavy"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 22,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 301676.00477616,
					["x"] = 38214.931330529,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 9.25,
					["action"] = "On Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 70,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZSU-23-4 Shilka",
				["unitId"] = 405,
				["y"] = 301676.00477616,
				["x"] = 38214.931330529,
				["name"] = "Unit #140",
				["heading"] = 2.8116029773454,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 406,
				["y"] = 301647.53942293,
				["x"] = 38224.39985035,
				["name"] = "Unit #141",
				["heading"] = 1.8782668196037,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 407,
				["y"] = 301619.07294999,
				["x"] = 38233.868742469,
				["name"] = "Unit #142",
				["heading"] = 1.8784381995326,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 408,
				["y"] = 301590.60647629,
				["x"] = 38243.337631008,
				["name"] = "Unit #143",
				["heading"] = 1.8785398765432,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 409,
				["y"] = 301562.13998517,
				["x"] = 38252.806469144,
				["name"] = "Unit #144",
				["heading"] = 1.8783470362892,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 410,
				["y"] = 301533.67338246,
				["x"] = 38262.27497114,
				["name"] = "Unit #145",
				["heading"] = 1.877645336169,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 411,
				["y"] = 301505.20653901,
				["x"] = 38271.74274927,
				["name"] = "Unit #146",
				["heading"] = 1.877473355351,
				["playerCanDrive"] = true,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 412,
				["y"] = 301476.73925518,
				["x"] = 38281.209202938,
				["name"] = "Unit #147",
				["heading"] = 1.8773984159304,
				["playerCanDrive"] = true,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 413,
				["y"] = 301448.27113757,
				["x"] = 38290.673148291,
				["name"] = "Unit #148",
				["heading"] = 1.8773291465698,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 414,
				["y"] = 301419.80110324,
				["x"] = 38300.131321826,
				["name"] = "Unit #149",
				["heading"] = 1.8772303862861,
				["playerCanDrive"] = true,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 415,
				["y"] = 301391.32811351,
				["x"] = 38309.580594062,
				["name"] = "Unit #150",
				["heading"] = 1.8769893046105,
				["playerCanDrive"] = true,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 416,
				["y"] = 301362.85730293,
				["x"] = 38319.036426189,
				["name"] = "Unit #151",
				["heading"] = 1.8757472778833,
				["playerCanDrive"] = true,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 417,
				["y"] = 301334.39176906,
				["x"] = 38328.508118369,
				["name"] = "Unit #152",
				["heading"] = 1.8730157673716,
				["playerCanDrive"] = true,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 418,
				["y"] = 301305.92821931,
				["x"] = 38337.98579116,
				["name"] = "Unit #153",
				["heading"] = 1.8708689503781,
				["playerCanDrive"] = true,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 419,
				["y"] = 301277.46511035,
				["x"] = 38347.464790578,
				["name"] = "Unit #154",
				["heading"] = 1.8679285264736,
				["playerCanDrive"] = true,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 420,
				["y"] = 301249.00182235,
				["x"] = 38356.943252237,
				["name"] = "Unit #155",
				["heading"] = 1.8637875013618,
				["playerCanDrive"] = true,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 421,
				["y"] = 301220.53792841,
				["x"] = 38366.419893654,
				["name"] = "Unit #156",
				["heading"] = 1.8575911919256,
				["playerCanDrive"] = true,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 422,
				["y"] = 301192.07330281,
				["x"] = 38375.894337225,
				["name"] = "Unit #157",
				["heading"] = 1.8495312285784,
				["playerCanDrive"] = true,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 423,
				["y"] = 301163.60811559,
				["x"] = 38385.367093434,
				["name"] = "Unit #158",
				["heading"] = 1.846427458863,
				["playerCanDrive"] = true,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 424,
				["y"] = 301135.14239031,
				["x"] = 38394.838232731,
				["name"] = "Unit #159",
				["heading"] = 1.8562698946798,
				["playerCanDrive"] = true,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 301676.00477616,
		["x"] = 38214.931330529,
		["name"] = "CONVOY_heavy-2",
		["start_time"] = 0,
	},  -- end of ["CON_heavy"]
	["CONVOY_base"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 307429.64127261,
						["x"] = 36315.691981635,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 307429.64127261,
						["x"] = 36315.691981635,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 5,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 307929.59357735,
					["x"] = 36284.831768249,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "On Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 72,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 444,
				["y"] = 307929.59357735,
				["x"] = 36284.831768249,
				["name"] = "Unit #179",
				["heading"] = -0.061648098349977,
				["playerCanDrive"] = false,
				["wagons"] = 
				{
				}, -- end of ["wagons"]
			}, -- end of [1]
		}, -- end of ["units"]
		["y"] = 307929.59357735,
		["x"] = 36284.831768249,
		["name"] = "CONVOY_base",
		["start_time"] = 0,
	}, -- end of [CONVOY_base]
	["CONVOY_light-1"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 307002.29266054,
						["x"] = 36451.947799565,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 307002.29266054,
						["x"] = 36451.947799565,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 52,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427622.79355021,
					["x"] = 13792.384414609,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 323,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3127,
				["y"] = 427622.79355021,
				["x"] = 13792.384414609,
				["name"] = "CONVOY_light-1-1",
				["heading"] = 1.8849555921539,
				["playerCanDrive"] = false,
				["wagons"] = 
				{
				}, -- end of ["wagons"]
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3128,
				["y"] = 427626.31175636,
				["x"] = 13800.112737528,
				["name"] = "CONVOY_light-1-2",
				["heading"] = 1.8790433242373,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3129,
				["y"] = 427629.89876323,
				["x"] = 13807.286751269,
				["name"] = "CONVOY_light-1-3",
				["heading"] = 1.8790149274913,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3130,
				["y"] = 427632.96159248,
				["x"] = 13815.434763184,
				["name"] = "CONVOY_light-1-4",
				["heading"] = 1.8790045696829,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 PBU",
				["unitId"] = 3131,
				["y"] = 427607.96625072,
				["x"] = 13796.5513766,
				["name"] = "CONVOY_light-1-5",
				["heading"] = 1.8790140394514,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3132,
				["y"] = 427612.49231782,
				["x"] = 13804.369128866,
				["name"] = "CONVOY_light-1-6",
				["heading"] = 1.8790787459442,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3133,
				["y"] = 427615.21163357,
				["x"] = 13812.799293817,
				["name"] = "CONVOY_light-1-7",
				["heading"] = 1.8792307204181,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3134,
				["y"] = 427617.34538382,
				["x"] = 13820.600818143,
				["name"] = "CONVOY_light-1-8",
				["heading"] = 1.8795438987433,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3135,
				["y"] = 427594.59377974,
				["x"] = 13800.871713379,
				["name"] = "CONVOY_light-1-9",
				["heading"] = 1.8801155465484,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3136,
				["y"] = 427598.40835041,
				["x"] = 13809.598668452,
				["name"] = "CONVOY_light-1-10",
				["heading"] = 1.8805447152192,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3137,
				["y"] = 427602.14241334,
				["x"] = 13817.600231864,
				["name"] = "CONVOY_light-1-11",
				["heading"] = 1.8805410215421,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3138,
				["y"] = 427604.40952297,
				["x"] = 13825.601795274,
				["name"] = "CONVOY_light-1-12",
				["heading"] = 1.8803837453141,
				["playerCanDrive"] = false,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "SKP-11",
				["unitId"] = 3139,
				["y"] = 427582.07182511,
				["x"] = 13804.397652236,
				["name"] = "CONVOY_light-1-13",
				["heading"] = 1.8802767356983,
				["playerCanDrive"] = false,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3140,
				["y"] = 427585.67252865,
				["x"] = 13812.06581717,
				["name"] = "CONVOY_light-1-14",
				["heading"] = 1.8802038056136,
				["playerCanDrive"] = false,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 3141,
				["y"] = 427588.33971645,
				["x"] = 13821.134255703,
				["name"] = "CONVOY_light-1-15",
				["heading"] = 1.8801457366544,
				["playerCanDrive"] = false,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 3142,
				["y"] = 427592.07377938,
				["x"] = 13829.335858199,
				["name"] = "CONVOY_light-1-16",
				["heading"] = 1.8800874621262,
				["playerCanDrive"] = false,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3143,
				["y"] = 427569.40268305,
				["x"] = 13808.198394856,
				["name"] = "CONVOY_light-1-17",
				["heading"] = 1.8799869866622,
				["playerCanDrive"] = false,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3186,
				["y"] = 427578.81880602,
				["x"] = 13833.309137985,
				["name"] = "CONVOY_light-1-20",
				["heading"] = 1.8799607746795,
				["playerCanDrive"] = false,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "KAMAZ Truck",
				["unitId"] = 3144,
				["y"] = 427572.53662872,
				["x"] = 13816.666716131,
				["name"] = "CONVOY_light-1-18",
				["heading"] = 1.8799607746795,
				["playerCanDrive"] = false,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3145,
				["y"] = 427575.00377743,
				["x"] = 13825.201717104,
				["name"] = "CONVOY_light-1-19",
				["heading"] = 1.8799518773351,
				["playerCanDrive"] = false,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 427622.79355021,
		["x"] = 13792.384414609,
		["name"] = "CONVOY_light-1",
		["start_time"] = 0,
	}, -- end of ["CONVOY_light-1"]
	["CONVOY_light-2"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 306224.70862636,
						["x"] = 36700.197414639,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 306224.70862636,
						["x"] = 36700.197414639,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427651.63035237,
					["x"] = 13850.757198918,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 321,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3088,
				["y"] = 427651.63035237,
				["x"] = 13850.757198918,
				["name"] = "CONVOY_light-2-1",
				["heading"] = 1.8849555921539,
				["playerCanDrive"] = false,
				["wagons"] = 
				{
				}, -- end of ["wagons"]
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3089,
				["y"] = 427653.52285025,
				["x"] = 13855.921158178,
				["name"] = "CONVOY_light-2-2",
				["heading"] = 1.879900916109,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3090,
				["y"] = 427656.79369732,
				["x"] = 13862.099424868,
				["name"] = "CONVOY_light-2-3",
				["heading"] = 1.8799008592043,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3091,
				["y"] = 427658.61083458,
				["x"] = 13868.277691558,
				["name"] = "CONVOY_light-2-4",
				["heading"] = 1.879900859882,
				["playerCanDrive"] = false,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 PBU",
				["unitId"] = 3092,
				["y"] = 427638.25889725,
				["x"] = 13855.073160789,
				["name"] = "CONVOY_light-2-5",
				["heading"] = 1.8799008723394,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3093,
				["y"] = 427641.07041672,
				["x"] = 13860.432449647,
				["name"] = "CONVOY_light-2-6",
				["heading"] = 1.8799008962587,
				["playerCanDrive"] = false,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3094,
				["y"] = 427643.32549924,
				["x"] = 13866.719346379,
				["name"] = "CONVOY_light-2-7",
				["heading"] = 1.8799009318986,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3095,
				["y"] = 427645.71725343,
				["x"] = 13873.142914779,
				["name"] = "CONVOY_light-2-8",
				["heading"] = 1.8799009689035,
				["playerCanDrive"] = false,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3096,
				["y"] = 427626.92489907,
				["x"] = 13859.065732967,
				["name"] = "CONVOY_light-2-9",
				["heading"] = 1.8799009988225,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3097,
				["y"] = 427629.24831743,
				["x"] = 13864.737607192,
				["name"] = "CONVOY_light-2-10",
				["heading"] = 1.8799010251592,
				["playerCanDrive"] = false,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3098,
				["y"] = 427631.77674329,
				["x"] = 13871.092839757,
				["name"] = "CONVOY_light-2-11",
				["heading"] = 1.8799010371935,
				["playerCanDrive"] = false,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3099,
				["y"] = 427634.51017665,
				["x"] = 13877.516408157,
				["name"] = "CONVOY_light-2-12",
				["heading"] = 1.879901035186,
				["playerCanDrive"] = false,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZIL-131 KUNG",
				["unitId"] = 3100,
				["y"] = 427616.26450896,
				["x"] = 13862.482524669,
				["name"] = "CONVOY_light-2-13",
				["heading"] = 1.8799010189057,
				["playerCanDrive"] = false,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3101,
				["y"] = 427619.06627815,
				["x"] = 13868.154398894,
				["name"] = "CONVOY_light-2-14",
				["heading"] = 1.8799008997323,
				["playerCanDrive"] = false,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 3102,
				["y"] = 427621.86804735,
				["x"] = 13874.714638961,
				["name"] = "CONVOY_light-2-15",
				["heading"] = 1.879899520508,
				["playerCanDrive"] = false,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZiL-131 APA-80",
				["unitId"] = 3103,
				["y"] = 427624.87482405,
				["x"] = 13881.274879029,
				["name"] = "CONVOY_light-2-16",
				["heading"] = 1.8798949531691,
				["playerCanDrive"] = false,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 3104,
				["y"] = 427605.33077551,
				["x"] = 13866.172659707,
				["name"] = "CONVOY_light-2-17",
				["heading"] = 1.8798871541494,
				["playerCanDrive"] = false,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 3187,
				["y"] = 427613.15856542,
				["x"] = 13884.409797101,
				["name"] = "CONVOY_light-2-20",
				["heading"] = 1.8798761276137,
				["playerCanDrive"] = false,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 3105,
				["y"] = 427610.9343139,
				["x"] = 13877.994758995,
				["name"] = "CONVOY_light-2-18",
				["heading"] = 1.8798761276137,
				["playerCanDrive"] = false,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3106,
				["y"] = 427608.20088054,
				["x"] = 13871.9812056,
				["name"] = "CONVOY_light-2-19",
				["heading"] = 1.8798618795929,
				["playerCanDrive"] = false,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 427651.63035237,
		["x"] = 13850.757198918,
		["name"] = "CONVOY_light-2",
		["start_time"] = 0,
	}, -- end of ["CONVOY_light-2"]
	["CONVOY_heavy-1"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 305424.62758347,
						["x"] = 36955.598089493,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 305424.62758347,
						["x"] = 36955.598089493,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 52,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427585.19682356,
					["x"] = 13671.643558776,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 9.25,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 322,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3107,
				["y"] = 427585.19682356,
				["x"] = 13671.643558776,
				["name"] = "CONVOY_heavy-1-1",
				["heading"] = 1.850049007114,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3108,
				["y"] = 427543.20068003,
				["x"] = 13707.91421832,
				["name"] = "CONVOY_heavy-1-2",
				["heading"] = 1.8791409262917,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3109,
				["y"] = 427587.45327674,
				["x"] = 13677.959587648,
				["name"] = "CONVOY_heavy-1-3",
				["heading"] = 1.8791601648452,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3110,
				["y"] = 427590.43800042,
				["x"] = 13685.028670051,
				["name"] = "CONVOY_heavy-1-4",
				["heading"] = 1.8792199564999,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3111,
				["y"] = 427593.89399626,
				["x"] = 13691.312298852,
				["name"] = "CONVOY_heavy-1-5",
				["heading"] = 1.8792993044879,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3112,
				["y"] = 427571.27293257,
				["x"] = 13675.760317568,
				["name"] = "CONVOY_heavy-1-6",
				["heading"] = 1.8793461925752,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3113,
				["y"] = 427573.94347482,
				["x"] = 13681.88685565,
				["name"] = "CONVOY_heavy-1-7",
				["heading"] = 1.8793518558872,
				["playerCanDrive"] = true,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3114,
				["y"] = 427576.62903289,
				["x"] = 13689.139390002,
				["name"] = "CONVOY_heavy-1-8",
				["heading"] = 1.8792989748675,
				["playerCanDrive"] = true,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3115,
				["y"] = 427579.65132233,
				["x"] = 13695.733476045,
				["name"] = "CONVOY_heavy-1-9",
				["heading"] = 1.8791699310651,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BMP-2",
				["unitId"] = 3116,
				["y"] = 427558.77004986,
				["x"] = 13680.347275277,
				["name"] = "CONVOY_heavy-1-10",
				["heading"] = 1.8790240909102,
				["playerCanDrive"] = true,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3117,
				["y"] = 427561.24283212,
				["x"] = 13686.39185415,
				["name"] = "CONVOY_heavy-1-11",
				["heading"] = 1.878900414256,
				["playerCanDrive"] = true,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BTR_D",
				["unitId"] = 3118,
				["y"] = 427564.44829062,
				["x"] = 13693.16910925,
				["name"] = "CONVOY_heavy-1-12",
				["heading"] = 1.8788157653291,
				["playerCanDrive"] = true,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "BTR_D",
				["unitId"] = 3119,
				["y"] = 427567.28741099,
				["x"] = 13699.854779822,
				["name"] = "CONVOY_heavy-1-13",
				["heading"] = 1.8787606099854,
				["playerCanDrive"] = true,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR_D",
				["unitId"] = 3120,
				["y"] = 427546.77247664,
				["x"] = 13684.926501696,
				["name"] = "CONVOY_heavy-1-14",
				["heading"] = 1.8787212155447,
				["playerCanDrive"] = true,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3121,
				["y"] = 427549.52001249,
				["x"] = 13690.971080569,
				["name"] = "CONVOY_heavy-1-15",
				["heading"] = 1.878691365128,
				["playerCanDrive"] = true,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3122,
				["y"] = 427552.26754834,
				["x"] = 13697.381997556,
				["name"] = "CONVOY_heavy-1-16",
				["heading"] = 1.8786679717346,
				["playerCanDrive"] = true,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3123,
				["y"] = 427555.28983778,
				["x"] = 13703.792914542,
				["name"] = "CONVOY_heavy-1-17",
				["heading"] = 1.8786490585146,
				["playerCanDrive"] = true,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3124,
				["y"] = 427534.13381172,
				["x"] = 13689.139390002,
				["name"] = "CONVOY_heavy-1-18",
				["heading"] = 1.8786338426242,
				["playerCanDrive"] = false,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375",
				["unitId"] = 3125,
				["y"] = 427537.15610116,
				["x"] = 13695.550306988,
				["name"] = "CONVOY_heavy-1-19",
				["heading"] = 1.8786213481253,
				["playerCanDrive"] = false,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3126,
				["y"] = 427540.45314418,
				["x"] = 13701.503301333,
				["name"] = "CONVOY_heavy-1-20",
				["heading"] = 1.878611069685,
				["playerCanDrive"] = true,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 427585.19682356,
		["x"] = 13671.643558776,
		["name"] = "CONVOY_heavy-1",
		["start_time"] = 0,
	}, -- end of ["CONVOY_heavy-1"]
	["CONVOY_heavy-2"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 52,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427552.42580137,
					["x"] = 13613.164301968,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 9.25,
					["action"] = "Custom",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 324,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ZSU-23-4 Shilka",
				["unitId"] = 3146,
				["y"] = 427552.42580137,
				["x"] = 13613.164301968,
				["name"] = "CONVOY_heavy-2-1",
				["heading"] = 1.9024088846738,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3147,
				["y"] = 427555.12715032,
				["x"] = 13619.130326314,
				["name"] = "CONVOY_heavy-2-2",
				["heading"] = 1.8782668196037,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3148,
				["y"] = 427557.3968117,
				["x"] = 13624.96659842,
				["name"] = "CONVOY_heavy-2-3",
				["heading"] = 1.8784381995326,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3149,
				["y"] = 427559.01799839,
				["x"] = 13630.802870525,
				["name"] = "CONVOY_heavy-2-4",
				["heading"] = 1.8785398765432,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3150,
				["y"] = 427541.75236008,
				["x"] = 13616.69854627,
				["name"] = "CONVOY_heavy-2-5",
				["heading"] = 1.8783470362892,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3151,
				["y"] = 427543.53566545,
				["x"] = 13622.77799638,
				["name"] = "CONVOY_heavy-2-6",
				["heading"] = 1.877645336169,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3152,
				["y"] = 427546.53486084,
				["x"] = 13628.371090481,
				["name"] = "CONVOY_heavy-2-7",
				["heading"] = 1.877473355351,
				["playerCanDrive"] = true,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3153,
				["y"] = 427548.23710687,
				["x"] = 13633.964184582,
				["name"] = "CONVOY_heavy-2-8",
				["heading"] = 1.8773984159304,
				["playerCanDrive"] = true,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3154,
				["y"] = 427530.16087521,
				["x"] = 13620.265157001,
				["name"] = "CONVOY_heavy-2-9",
				["heading"] = 1.8773291465698,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3155,
				["y"] = 427532.10629924,
				["x"] = 13626.425666446,
				["name"] = "CONVOY_heavy-2-10",
				["heading"] = 1.8772303862861,
				["playerCanDrive"] = true,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3156,
				["y"] = 427534.94337596,
				["x"] = 13632.261938552,
				["name"] = "CONVOY_heavy-2-11",
				["heading"] = 1.8769893046105,
				["playerCanDrive"] = true,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3157,
				["y"] = 427537.05091866,
				["x"] = 13638.665626001,
				["name"] = "CONVOY_heavy-2-12",
				["heading"] = 1.8757472778833,
				["playerCanDrive"] = true,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3158,
				["y"] = 427518.974687,
				["x"] = 13624.074945737,
				["name"] = "CONVOY_heavy-2-13",
				["heading"] = 1.8730157673716,
				["playerCanDrive"] = true,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3159,
				["y"] = 427520.8390517,
				["x"] = 13629.749099173,
				["name"] = "CONVOY_heavy-2-14",
				["heading"] = 1.8708689503781,
				["playerCanDrive"] = true,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3160,
				["y"] = 427523.51400975,
				["x"] = 13635.747489948,
				["name"] = "CONVOY_heavy-2-15",
				["heading"] = 1.8679285264736,
				["playerCanDrive"] = true,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3161,
				["y"] = 427526.59426448,
				["x"] = 13642.394355401,
				["name"] = "CONVOY_heavy-2-16",
				["heading"] = 1.8637875013618,
				["playerCanDrive"] = true,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3162,
				["y"] = 427507.27020542,
				["x"] = 13627.798973696,
				["name"] = "CONVOY_heavy-2-17",
				["heading"] = 1.8575911919256,
				["playerCanDrive"] = true,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3163,
				["y"] = 427510.7226846,
				["x"] = 13633.948702249,
				["name"] = "CONVOY_heavy-2-18",
				["heading"] = 1.8495312285784,
				["playerCanDrive"] = true,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3164,
				["y"] = 427513.41993397,
				["x"] = 13640.314210752,
				["name"] = "CONVOY_heavy-2-19",
				["heading"] = 1.846427458863,
				["playerCanDrive"] = true,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3165,
				["y"] = 427516.54874323,
				["x"] = 13646.248159355,
				["name"] = "CONVOY_heavy-2-20",
				["heading"] = 1.8562698946798,
				["playerCanDrive"] = true,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 427552.42580137,
		["x"] = 13613.164301968,
		["name"] = "CONVOY_heavy-2",
		["start_time"] = 0,
	}, -- end of ["CONVOY_heavy-2"]
	["CONVOY_heavy-3"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["lateActivation"] = true,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["task"] = "Ground Nothing",
		["taskSelected"] = true,
		["route"] = 
		{
			["spans"] = 
			{
				[1] = 
				{
					[1] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [1]
					[2] = 
					{
						["y"] = 304414.77669086,
						["x"] = 37276.865434798,
					}, -- end of [2]
				}, -- end of [1]
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427529.34149148,
					["x"] = 13561.906228033,
					["name"] = "",
					["ETA_locked"] = true,
					["speed"] = 9.25,
					["action"] = "Custom",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
								[1] = 
								{
									["number"] = 1,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 0,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [1]
								[2] = 
								{
									["number"] = 2,
									["auto"] = false,
									["id"] = "WrappedAction",
									["enabled"] = true,
									["params"] = 
									{
										["action"] = 
										{
											["id"] = "Option",
											["params"] = 
											{
												["value"] = 0,
												["name"] = 9,
											}, -- end of ["params"]
										}, -- end of ["action"]
									}, -- end of ["params"]
								}, -- end of [2]
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
			["routeRelativeTOT"] = true,
		}, -- end of ["route"]
		["groupId"] = 325,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Tigr_233036",
				["unitId"] = 3166,
				["y"] = 427529.34149148,
				["x"] = 13561.906228033,
				["name"] = "CONVOY_heavy-3-1",
				["heading"] = 1.8675022996339,
				["playerCanDrive"] = false,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "UAZ-469",
				["unitId"] = 3167,
				["y"] = 427534.06119693,
				["x"] = 13566.728535773,
				["name"] = "CONVOY_heavy-3-2",
				["heading"] = 1.8782668196037,
				["playerCanDrive"] = false,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "ATZ-5",
				["unitId"] = 3168,
				["y"] = 427539.39651613,
				["x"] = 13579.348617732,
				["name"] = "CONVOY_heavy-3-3",
				["heading"] = 1.8784381995326,
				["playerCanDrive"] = false,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3169,
				["y"] = 427536.11324277,
				["x"] = 13573.397684776,
				["name"] = "CONVOY_heavy-3-4",
				["heading"] = 1.8785398765432,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "ATZ-5",
				["unitId"] = 3170,
				["y"] = 427520.31248975,
				["x"] = 13565.292103681,
				["name"] = "CONVOY_heavy-3-5",
				["heading"] = 1.8783470362892,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3171,
				["y"] = 427522.67234248,
				["x"] = 13570.832627467,
				["name"] = "CONVOY_heavy-3-6",
				["heading"] = 1.877645336169,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3172,
				["y"] = 427525.54520666,
				["x"] = 13577.296571885,
				["name"] = "CONVOY_heavy-3-7",
				["heading"] = 1.877473355351,
				["playerCanDrive"] = true,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3173,
				["y"] = 427528.31546855,
				["x"] = 13583.760516302,
				["name"] = "CONVOY_heavy-3-8",
				["heading"] = 1.8773984159304,
				["playerCanDrive"] = true,
			}, -- end of [8]
			[9] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3174,
				["y"] = 427508.9236353,
				["x"] = 13568.985786205,
				["name"] = "CONVOY_heavy-3-9",
				["heading"] = 1.8773291465698,
				["playerCanDrive"] = false,
			}, -- end of [9]
			[10] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3175,
				["y"] = 427511.18088573,
				["x"] = 13574.731514576,
				["name"] = "CONVOY_heavy-3-10",
				["heading"] = 1.8772303862861,
				["playerCanDrive"] = true,
			}, -- end of [10]
			[11] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3176,
				["y"] = 427514.05374992,
				["x"] = 13581.605868163,
				["name"] = "CONVOY_heavy-3-11",
				["heading"] = 1.8769893046105,
				["playerCanDrive"] = true,
			}, -- end of [11]
			[12] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3177,
				["y"] = 427517.13181869,
				["x"] = 13587.967210288,
				["name"] = "CONVOY_heavy-3-12",
				["heading"] = 1.8757472778833,
				["playerCanDrive"] = true,
			}, -- end of [12]
			[13] = 
			{
				["skill"] = "Average",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3178,
				["y"] = 427496.30355334,
				["x"] = 13573.60288936,
				["name"] = "CONVOY_heavy-3-13",
				["heading"] = 1.8730157673716,
				["playerCanDrive"] = true,
			}, -- end of [13]
			[14] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3179,
				["y"] = 427498.35559919,
				["x"] = 13579.348617732,
				["name"] = "CONVOY_heavy-3-14",
				["heading"] = 1.8708689503781,
				["playerCanDrive"] = true,
			}, -- end of [14]
			[15] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3180,
				["y"] = 427501.43366796,
				["x"] = 13585.299550688,
				["name"] = "CONVOY_heavy-3-15",
				["heading"] = 1.8679285264736,
				["playerCanDrive"] = true,
			}, -- end of [15]
			[16] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3181,
				["y"] = 427505.02474819,
				["x"] = 13592.276506567,
				["name"] = "CONVOY_heavy-3-16",
				["heading"] = 1.8637875013618,
				["playerCanDrive"] = true,
			}, -- end of [16]
			[17] = 
			{
				["skill"] = "Excellent",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3182,
				["y"] = 427485.63291494,
				["x"] = 13577.0913673,
				["name"] = "CONVOY_heavy-3-17",
				["heading"] = 1.8575911919256,
				["playerCanDrive"] = true,
			}, -- end of [17]
			[18] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3183,
				["y"] = 427488.813586,
				["x"] = 13582.939697964,
				["name"] = "CONVOY_heavy-3-18",
				["heading"] = 1.8495312285784,
				["playerCanDrive"] = true,
			}, -- end of [18]
			[19] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-90",
				["unitId"] = 3184,
				["y"] = 427491.07083643,
				["x"] = 13589.608846966,
				["name"] = "CONVOY_heavy-3-19",
				["heading"] = 1.846427458863,
				["playerCanDrive"] = true,
			}, -- end of [19]
			[20] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Osa 9A33 ln",
				["unitId"] = 3185,
				["y"] = 427494.66191667,
				["x"] = 13596.483200553,
				["name"] = "CONVOY_heavy-3-20",
				["heading"] = 1.8562698946798,
				["playerCanDrive"] = true,
			}, -- end of [20]
		}, -- end of ["units"]
		["y"] = 427529.34149148,
		["x"] = 13561.906228033,
		["name"] = "CONVOY_heavy-3",
		["start_time"] = 0,
	}, -- end of ["CONVOY_heavy-3"]
	------------------------ ARMOUR ------------------------
	["ARMOUR_Heavy_01"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427361.00279172,
					["x"] = 13655.375481588,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 328,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3204,
				["y"] = 427361.00279172,
				["x"] = 13655.375481588,
				["name"] = "ARMOUR_Heavy_01-1",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3205,
				["y"] = 427374.10326346,
				["x"] = 13672.296924251,
				["name"] = "ARMOUR_Heavy_01-2",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-55",
				["unitId"] = 3206,
				["y"] = 427350.44963393,
				["x"] = 13641.183303871,
				["name"] = "ARMOUR_Heavy_01-3",
				["heading"] = 5.6723200689816,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3207,
				["y"] = 427375.16857515,
				["x"] = 13643.556231586,
				["name"] = "ARMOUR_Heavy_01-4",
				["heading"] = 3.3161255787892,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tt_KORD",
				["unitId"] = 3208,
				["y"] = 427366.1364002,
				["x"] = 13635.675859695,
				["name"] = "ARMOUR_Heavy_01-5",
				["heading"] = 2.3038346126325,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3209,
				["y"] = 427354.87215213,
				["x"] = 13676.544862285,
				["name"] = "ARMOUR_Heavy_01-6",
				["heading"] = 2.8448866807508,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 3210,
				["y"] = 427340.72621724,
				["x"] = 13668.783119687,
				["name"] = "ARMOUR_Heavy_01-7",
				["heading"] = 1.5707963267949,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "HL_DSHK",
				["unitId"] = 3211,
				["y"] = 427343.00011621,
				["x"] = 13655.730186682,
				["name"] = "ARMOUR_Heavy_01-8",
				["heading"] = 1.7627825445143,
				["playerCanDrive"] = true,
			}, -- end of [8]
		}, -- end of ["units"]
		["y"] = 427361.00279172,
		["x"] = 13655.375481588,
		["name"] = "ARMOUR_Heavy_01",
		["start_time"] = 0,
	}, -- end of ["ARMOUR_Heavy_01"]
	["ARMOUR_Heavy_02"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427408.8264185,
					["x"] = 13776.126967418,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 329,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BRDM-2",
				["unitId"] = 3212,
				["y"] = 427408.8264185,
				["x"] = 13776.126967418,
				["name"] = "ARMOUR_Heavy_02-1",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BRDM-2",
				["unitId"] = 3213,
				["y"] = 427423.59508475,
				["x"] = 13759.512217893,
				["name"] = "ARMOUR_Heavy_02-2",
				["heading"] = 2.460914245312,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-375 ZU-23",
				["unitId"] = 3214,
				["y"] = 427394.00817584,
				["x"] = 13756.64621542,
				["name"] = "ARMOUR_Heavy_02-3",
				["heading"] = 3.5604716740684,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "HL_KORD",
				["unitId"] = 3215,
				["y"] = 427405.13425194,
				["x"] = 13797.356925145,
				["name"] = "ARMOUR_Heavy_02-4",
				["heading"] = 6.2308254296198,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "HL_DSHK",
				["unitId"] = 3216,
				["y"] = 427409.0083695,
				["x"] = 13762.298691693,
				["name"] = "ARMOUR_Heavy_02-5",
				["heading"] = 0.78539816339745,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "SAU Gvozdika",
				["unitId"] = 3217,
				["y"] = 427387.36143465,
				["x"] = 13778.253415243,
				["name"] = "ARMOUR_Heavy_02-6",
				["heading"] = 4.2411500823462,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "ATMZ-5",
				["unitId"] = 3218,
				["y"] = 427438.02248791,
				["x"] = 13774.677151143,
				["name"] = "ARMOUR_Heavy_02-7",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "ATMZ-5",
				["unitId"] = 3219,
				["y"] = 427428.71757453,
				["x"] = 13775.224498989,
				["name"] = "ARMOUR_Heavy_02-8",
				["heading"] = 3.0194196059502,
				["playerCanDrive"] = false,
			}, -- end of [8]
		}, -- end of ["units"]
		["y"] = 427408.8264185,
		["x"] = 13776.126967418,
		["name"] = "ARMOUR_Heavy_02",
		["start_time"] = 0,
	}, -- end of ["ARMOUR_Heavy_02"]
	["ARMOUR_Heavy_03"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427443.12239686,
					["x"] = 13868.726108977,
					["ETA_locked"] = true,
					["speed"] = 5.5555555555556,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 330,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3220,
				["y"] = 427443.12239686,
				["x"] = 13868.726108977,
				["name"] = "ARMOUR_Heavy_03-1",
				["heading"] = 0,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BMP-3",
				["unitId"] = 3221,
				["y"] = 427426.48202961,
				["x"] = 13874.447449118,
				["name"] = "ARMOUR_Heavy_03-2",
				["heading"] = 5.1836278784232,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "tt_DSHK",
				["unitId"] = 3222,
				["y"] = 427434.7049642,
				["x"] = 13859.505775276,
				["name"] = "ARMOUR_Heavy_03-3",
				["heading"] = 5.6723200689816,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3223,
				["y"] = 427461.10612843,
				["x"] = 13850.017846548,
				["name"] = "ARMOUR_Heavy_03-4",
				["heading"] = 2.4434609527921,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-55",
				["unitId"] = 3224,
				["y"] = 427442.93347736,
				["x"] = 13848.021893743,
				["name"] = "ARMOUR_Heavy_03-5",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = true,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3225,
				["y"] = 427429.79125938,
				["x"] = 13883.873739997,
				["name"] = "ARMOUR_Heavy_03-6",
				["heading"] = 4.9741883681838,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-4320T",
				["unitId"] = 3226,
				["y"] = 427419.39591553,
				["x"] = 13854.483185225,
				["name"] = "ARMOUR_Heavy_03-7",
				["heading"] = 3.1415926535898,
				["playerCanDrive"] = false,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Ural-4320T",
				["unitId"] = 3227,
				["y"] = 427459.51509729,
				["x"] = 13869.527886334,
				["name"] = "ARMOUR_Heavy_03-8",
				["heading"] = 2.3561944901923,
				["playerCanDrive"] = false,
			}, -- end of [8]
		}, -- end of ["units"]
		["y"] = 427443.12239686,
		["x"] = 13868.726108977,
		["name"] = "ARMOUR_Heavy_03",
		["start_time"] = 0,
	}, -- end of ["ARMOUR_Heavy_03"]
	["ARMOUR_Heavy_04"] = {
		["category"] = Group.Category.GROUND,
		["visible"] = false,
		["tasks"] = 
		{
		}, -- end of ["tasks"]
		["uncontrollable"] = false,
		["route"] = 
		{
			["spans"] = 
			{
			}, -- end of ["spans"]
			["points"] = 
			{
				[1] = 
				{
					["alt"] = 51,
					["type"] = "Turning Point",
					["ETA"] = 0,
					["alt_type"] = "BARO",
					["formation_template"] = "",
					["y"] = 427472.82671015,
					["x"] = 13929.914313022,
					["ETA_locked"] = true,
					["speed"] = 4,
					["action"] = "Off Road",
					["task"] = 
					{
						["id"] = "ComboTask",
						["params"] = 
						{
							["tasks"] = 
							{
							}, -- end of ["tasks"]
						}, -- end of ["params"]
					}, -- end of ["task"]
					["speed_locked"] = true,
				}, -- end of [1]
			}, -- end of ["points"]
		}, -- end of ["route"]
		["groupId"] = 331,
		["hidden"] = false,
		["units"] = 
		{
			[1] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3228,
				["y"] = 427472.82671015,
				["x"] = 13929.914313022,
				["name"] = "ARMOUR_Heavy_04-1",
				["heading"] = 0.66322511575785,
				["playerCanDrive"] = true,
			}, -- end of [1]
			[2] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "BTR-80",
				["unitId"] = 3229,
				["y"] = 427485.92718189,
				["x"] = 13946.835755685,
				["name"] = "ARMOUR_Heavy_04-2",
				["heading"] = 0.97738438111682,
				["playerCanDrive"] = true,
			}, -- end of [2]
			[3] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-55",
				["unitId"] = 3230,
				["y"] = 427486.23645544,
				["x"] = 13909.617784168,
				["name"] = "ARMOUR_Heavy_04-3",
				["heading"] = 2.3212879051525,
				["playerCanDrive"] = true,
			}, -- end of [3]
			[4] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3231,
				["y"] = 427492.18328451,
				["x"] = 13917.321736417,
				["name"] = "ARMOUR_Heavy_04-4",
				["heading"] = 1.6231562043547,
				["playerCanDrive"] = true,
			}, -- end of [4]
			[5] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "Paratrooper RPG-16",
				["unitId"] = 3232,
				["y"] = 427489.95224552,
				["x"] = 13930.782546537,
				["name"] = "ARMOUR_Heavy_04-5",
				["heading"] = 0,
				["playerCanDrive"] = false,
			}, -- end of [5]
			[6] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "T-72B",
				["unitId"] = 3233,
				["y"] = 427470.26104556,
				["x"] = 13942.243860705,
				["name"] = "ARMOUR_Heavy_04-6",
				["heading"] = 4.9043751981041,
				["playerCanDrive"] = true,
			}, -- end of [6]
			[7] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "HL_DSHK",
				["unitId"] = 3234,
				["y"] = 427459.67336677,
				["x"] = 13917.222490468,
				["name"] = "ARMOUR_Heavy_04-7",
				["heading"] = 4.1189770347066,
				["playerCanDrive"] = true,
			}, -- end of [7]
			[8] = 
			{
				["skill"] = "Random",
				["coldAtStart"] = false,
				["type"] = "GAZ-66",
				["unitId"] = 3235,
				["y"] = 427480.77247503,
				["x"] = 13925.633609156,
				["name"] = "ARMOUR_Heavy_04-8",
				["heading"] = 0.62831853071796,
				["playerCanDrive"] = false,
			}, -- end of [8]
		}, -- end of ["units"]
		["y"] = 427472.82671015,
		["x"] = 13929.914313022,
		["name"] = "ARMOUR_Heavy_04",
		["start_time"] = 0,
	}, -- end of ["ARMOUR_Heavy_04"]
    ------------------------ ARTILLERY ------------------------
	------------------------ INFANTRY ------------------------
	------------------------ SHIP ------------------------

}  
  
--------------------------------[disableai.lua]-------------------------------- 
 
env.info( "[JTF-1] disableai.lua" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Disable AI for ground targets
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DISABLEAI = {}
DISABLEAI.traceTitle = "[JTF-1 DISABLEAI] "
DISABLEAI.setGroupGroundActive = SET_GROUP:New()
  :FilterActive()
  :FilterCategoryGround()
  :FilterOnce()
--local setGroupGroundActive = SET_GROUP:New():FilterActive():FilterCategoryGround():FilterOnce()

-- table of Prefixes for groups for which AI should NOT be disabled
DISABLEAI.excludeAI = {"BLUFOR", "FAC", "JTAC", "66%-"}
--local excludeAI = "BLUFOR"

_msg = string.format("%sStart Disable AI.", DISABLEAI.traceTitle)
BASE:T({_msg, Exclude_List = DISABLEAI.excludeAI})


DISABLEAI.setGroupGroundActive:ForEachGroup(
  function(activeGroup)

    -- name of the group we're checking
    local activeGroupName = activeGroup:GetName()
    -- list of group name prefixes to exclude
    local excludeAI = DISABLEAI.excludeAI
    -- flag to trigger disabling AI
    local disableGroup = true

    -- check if group name prefix is in exclusion list
    for _, stringExclude in pairs(excludeAI) do
      if string.find(activeGroupName, stringExclude) ~= nil then
        disableGroup = false
        _msg = string.format("%sSkip group: %s", DISABLEAI.traceTitle, activeGroupName)
        break
      end
    end

    -- Disable AI if group was not in exclusion list
    if disableGroup == true then
      activeGroup:SetAIOnOff(false)
      _msg = string.format("%sDisable group: %s", DISABLEAI.traceTitle, activeGroupName)
    end

    BASE:T(_msg)

  end
)

-- remove set object
DISABLEAI.setGroupGroundActive = nil

---  END DISABLE AI  
--------------------------------[movingtargets.lua]-------------------------------- 
 
env.info( "[JTF-1] movingtargets" )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MOVING TARGETS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- R62 T6208 MOVING TARGETS

local function rangeMovingTarget(targetId)
    local spawnMovingTarget = SPAWN:New( targetId )
    spawnMovingTarget:Spawn()
  end

  local MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
  local MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-1")
  local MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-2")
  local MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-3")

  -- END R62 T6208

--- END MOVING TARGETS   
--------------------------------[ecs.lua]-------------------------------- 
 
env.info( "[JTF-1] ecs" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ELECTRONIC COMBAT SIMULATOR RANGE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- IADS
-- REQUIRES MIST

local ECS = {}
ECS.ActiveSite = {}
ECS.rIADS = nil

ECS.menuEscTop = MENU_COALITION:New(coalition.side.BLUE, "EC South")

-- SAM spawn emplates
ECS.templates = {
  {templateName = "ECS_SA11", threatName = "SA-11"},
  {templateName = "ECS_SA10", threatName = "SA-10"},
  {templateName = "ECS_SA2",  threatName = "SA-2"},
  {templateName = "ECS_SA3",  threatName = "SA-3"},
  {templateName = "ECS_SA6",  threatName = "SA-6"},
  {templateName = "ECS_SA8",  threatName = "SA-8"},
  {templateName = "ECS_SA15", threatName = "SA-15"},
}
-- Zone in which threat will be spawned
ECS.zoneEcs7769 = ZONE:FindByName("ECS_ZONE_7769")


function activateEcsThreat(samTemplate, samZone, activeThreat, isReset)

  -- remove threat selection menu options
  if not isReset then
    ECS.menuEscTop:RemoveSubMenus()
  end
  
  -- spawn threat in ECS zone
  local ecsSpawn = SPAWN:New(samTemplate)
  ecsSpawn:OnSpawnGroup(
      function (spawnGroup)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Deactivate 77-69", ECS.menuEscTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, false)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Reset 77-69", ECS.menuEscTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, true, samZone)
        local msg = "All players, EC South is active with " .. activeThreat
        if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
          MISSIONSRS:SendRadio(msg)
        else -- otherwise, send in-game text message
          MESSAGE:New(msg):ToAll()
        end
        --MESSAGE:New("EC South is active with " .. activeThreat):ToAll()
        ECS.rIADS = SkynetIADS:create("ECSOUTH")
        ECS.rIADS:setUpdateInterval(5)
        --ECS.rIADS:addEarlyWarningRadar("GCI2")
        ECS.rIADS:addSAMSite(spawnGroup.GroupName)
        ECS.rIADS:getSAMSiteByGroupName(spawnGroup.GroupName):setGoLiveRangeInPercent(80)
        ECS.rIADS:activate()        
      end
      , ECS.menuEscTop, ecsSpawn, activeThreat, samZone --, rangePrefix
    )
    :SpawnInZone(samZone, true)
end

function resetEcsThreat(spawnGroup, ecsSpawn, activeThreat, refreshEcs, samZone)

  ECS.menuEscTop:RemoveSubMenus()
  
  if ECS.rIADS ~= nil then
    ECS.rIADS:deactivate()
    ECS.rIADS = nil
  end

  if spawnGroup:IsAlive() then
    spawnGroup:Destroy()
  end

  if refreshEcs then
    ecsSpawn:SpawnInZone(samZone, true)
  else
    addEcsThreatMenu()
    local msg = "All players, EC South "  .. activeThreat .." has been deactivated."
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New("EC South "  .. activeThreat .." has been deactived."):ToAll()
  end    

end

function addEcsThreatMenu()

  for i, template in ipairs(ECS.templates) do
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. template.threatName, ECS.menuEscTop, activateEcsThreat, template.templateName, ECS.zoneEcs7769, template.threatName)
  end

end

addEcsThreatMenu()

--- END ELECTRONIC COMBAT SIMULATOR RANGE  
--------------------------------[bvrgci.lua]-------------------------------- 
 
env.info( "[JTF-1] bvrgci" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN BVRGCI SECTION.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Each Menu level has an associated function which;
-- 1) adds the menu item for the level
-- 2) calls the function for the next level
--
-- Functions fit into the following menu map;
--
-- AI BVRGCI (menu root)
--   |_Group Size (menu level 1)
--     |_Altitude (menu level 2)
--       |_Formation (menu level 3)
--         |_Spacing (menu level 4)
--           |_Aircraft Type (command level 4) 
--   |_Remove Adversaries (command level 2)

--- BVRGCI default settings and values.
-- @type BVRGCI
-- @field #table Menu root BVRGCI F10 menu
-- @field #table SubMenu BVRGCI submenus
-- @field #number headingDefault Default heading for adversary spawns
-- @field #boolean Destroy When set to true, spawned adversary groups will be removed
BVRGCI = {
    Menu            = {},
    SubMenu         = {},
    Spawn           = {},
    headingDefault  = 150,
    Destroy         = false,
    defaultRadio = "377.8",
  }
   
BVRGCI.rangeRadio = JTF1.rangeRadio or BVRGCI.defaultRadio

  --- ME Zone object for BVRGCI area boundary
  -- @field #string ZoneBvr 
  BVRGCI.ZoneBvr = ZONE:FindByName("ZONE_BVR")
  --- ME Zone object for adversary spawn point
  -- @field #string ZoneBvrSpawn 
  BVRGCI.ZoneBvrSpawn = ZONE:FindByName("ZONE_BVR_SPAWN")
  --- ME Zone object for adversary spawn waypoint 1
  -- @field #string ZoneBvrWp1 
  BVRGCI.ZoneBvrWp1 = ZONE:FindByName("ZONE_BVR_WP1")
  
  --- Sizes of adversary groups
  -- @type BVRGCI.Size
  -- @field #number Pair Section size group.
  -- @field #number Four Flight size group.
  BVRGCI.Size = {
    Pair = 2,
    Four = 4,
  }
  
  --- Levels at which adversary groups may be spawned
  -- @type BVRGCI.Altitude Altitude name, Altitude in metres for adversary spawns.
  -- @field #number High Altitude, in metres, for High Level spawn.
  -- @field #number Medium Altitude, in metres, for Medium Level spawns.
  -- @field #number Low Altitude, in metres, for Low Level spawns.
  BVRGCI.Altitude = {
    High    = 9144, -- 30,000ft
    Medium  = 6096, -- 20,000ft
    Low     = 3048, -- 10,000ft
  }
      
  --- Adversary types
  -- @type BVRGCI.Adversary 
  -- @list <#string> Display name for adversary type.
  -- @list <#string> Name of spawn template for adversary type.
  BVRGCI.Adversary = { 
    {"F-4", "BVR_F4"},
    {"F-14A", "BVR_F14A" },
    {"MiG-21", "BVR_MIG21"},
    {"MiG-23", "BVR_MIG23"},
    {"MiG-29A", "BVR_MIG29A"},
    {"Su-25", "BVR_SU25"},
    {"Su-34", "BVR_SU34"},
  }
  
  -- @field #table BVRGCI.BvrSpawnVec3 Vec3 coordinates for spawnpoint.
  BVRGCI.BvrSpawnVec3 = COORDINATE:NewFromVec3(BVRGCI.ZoneBvrSpawn:GetPointVec3())
  -- @field #table BvrWp1Vec3 Vec3 coordintates for wp1.
  BVRGCI.BvrWp1Vec3 = COORDINATE:NewFromVec3(BVRGCI.ZoneBvrWp1:GetPointVec3())
  -- @field #number Heading Heading from spawn point to wp1.
  BVRGCI.Heading = COORDINATE:GetAngleDegrees(BVRGCI.BvrSpawnVec3:GetDirectionVec3(BVRGCI.BvrWp1Vec3))
  
  --- Spawn adversary aircraft with menu tree selected parameters.
  -- @param #string typeName Aircraft type name
  -- @param #string typeSpawnTemplate Airctraft type spawn template
  -- @param #number Qty Quantity to spawn
  -- @param #number Altitude Alititude at which to spawn adversary group
  -- @param #number Formation ID for Formation, and spacing, in which to spawn adversary group
  function BVRGCI.SpawnType(typeName, typeSpawnTemplate, Qty, Altitude, Formation) 
    local spawnHeading = BVRGCI.Heading
    local spawnVec3 = BVRGCI.BvrSpawnVec3
    spawnVec3.y = Altitude
    local spawnAdversary = SPAWN:New(typeSpawnTemplate)
    spawnAdversary:InitGrouping(Qty) 
    spawnAdversary:InitHeading(spawnHeading)
    spawnAdversary:OnSpawnGroup(
        function ( SpawnGroup, Formation, typeName )
          -- reset despawn flag
          BVRGCI.Destroy = false
          -- set formation for spawned AC
          SpawnGroup:SetOption(AI.Option.Air.id.FORMATION, Formation)
          -- add scheduled funtion, 5 sec interval
          local CheckAdversary = SCHEDULER:New( SpawnGroup, 
            function (CheckAdversary)
              if SpawnGroup then
                -- remove adversary group if it has left the BVR/GCI zone, or the remove all adversaries menu option has been selected
                if (SpawnGroup:IsNotInZone(BVRGCI.ZoneBvr) or (BVRGCI.Destroy)) then 
                  local groupName = SpawnGroup.GroupName
                  local msgDestroy = "All players, BVR adversary group " .. groupName .. " removed."
                  local msgLeftZone = "All players, BVR adversary group " .. groupName .. " left zone and was removed."
                  SpawnGroup:Destroy()
                  SpawnGroup = nil
                  local msg = (BVRGCI.Destroy and msgDestroy or msgLeftZone)
                  if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
                    MISSIONSRS:SendRadio(msg, BVRGCI.rangeRadio)
                  else -- otherwise, send in-game text message
                    MESSAGE:New(msg):ToAll()
                  end
                  --MESSAGE:New(BVRGCI.Destroy and msgDestroy or msgLeftZone):ToAll()
                end
              end
            end,
          {}, 0, 5 )
        end,
        Formation, typeName
      )
    spawnAdversary:SpawnFromVec3(spawnVec3)
    local msg = "All players, BVR Adversary group spawned."
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg, BVRGCI.rangeRadio)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New(_msg):ToAll()
  end
  
  --- Remove all spawned BVRGCI adversaries
  function BVRGCI.RemoveAdversaries()
    BVRGCI.Destroy = true
  end
  
  --- Add BVR/GCI MENU Adversary Type.
  -- @param #table ParentMenu Parent menu with which each command should be associated.
  function BVRGCI.BuildMenuType(ParentMenu)
    for i, v in ipairs(BVRGCI.Adversary) do
      local typeName = v[1]
      local typeSpawnTemplate = v[2]
      -- add Type spawn commands if spawn template exists, else send message that it doesn't
      if GROUP:FindByName(typeSpawnTemplate) ~= nil then
          MENU_COALITION_COMMAND:New(coalition.side.BLUE, typeName, ParentMenu, BVRGCI.SpawnType, typeName, typeSpawnTemplate, BVRGCI.Spawn.Qty, BVRGCI.Spawn.Level, ENUMS.Formation.FixedWing[BVRGCI.Spawn.Formation][BVRGCI.Spawn.Spacing])
      else
        _msg = "Spawn template " .. typeName .. " was not found and could not be added to menu."
        MESSAGE:New(_msg):ToAll()
      end
    end
  end
  
  --- Add BVR/GCI MENU Formation Spacing.
  -- @param #string Spacing Spacing to apply to adversary group formation.
  -- @param #string MenuText Text to display for menu option.
  -- @param #object ParentMenu Parent menu with which this menu should be associated.
  function BVRGCI.BuildMenuSpacing(Spacing, ParentMenu)
    local MenuName = Spacing
    local MenuText = Spacing
    BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
    BVRGCI.Spawn.Spacing = Spacing
    -- Build Type menus
    BVRGCI.BuildMenuType(BVRGCI.SubMenu[MenuName])
  end
  
  --- Add BVR/GCI MENU Formation.
  -- @param #string Formation Name of formation in which adversary group should fly.
  -- @param #string MenuText Text to display for menu option.
  -- @param #object ParentMenu Parent menu with which this menus should be associated.
  function BVRGCI.BuildMenuFormation(Formation, MenuText, ParentMenu)
    local MenuName = Formation
    BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
    BVRGCI.Spawn.Formation = Formation
    -- Build formation spacing menus
    BVRGCI.BuildMenuSpacing("Open", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuSpacing("Close", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuSpacing("Group", BVRGCI.SubMenu[MenuName])
  end
  
  --- Add BVR/GCI MENU Level.
  -- @param #number Altitude Altitude, in metres, at which to adversary group should spawn
  -- @param #string MenuName Text for this item's menu name
  -- 
  function BVRGCI.BuildMenuLevel(Altitude, MenuName, MenuText, ParentMenu)
    BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
    BVRGCI.Spawn.Level = Altitude
    --Build Formation menus
    BVRGCI.BuildMenuFormation("LineAbreast", "Line Abreast", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("Trail", "Trail", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("Wedge", "Wedge", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("EchelonRight", "Echelon Right", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("EchelonLeft", "Echelon Left", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("FingerFour", "Finger Four", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("Spread", "Spread", BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuFormation("BomberElement", "Diamond", BVRGCI.SubMenu[MenuName])
  end
  
  --- Add BVR/GCI MENU Group Size.
  -- @param #number Qty Quantity of aircraft in enemy flight.
  -- @param #string MenuName Text for this item's menu name
  -- @param #object ParentMenu to which this menu item belongs 
  function BVRGCI.BuildMenuQty(Qty, MenuName, ParentMenu)
    MenuText = MenuName
    BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
    BVRGCI.Spawn.Qty = Qty
    -- Build Level menus
    BVRGCI.BuildMenuLevel(BVRGCI.Altitude.High, "High", "High Level",  BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuLevel(BVRGCI.Altitude.Medium, "Medium", "Medium Level",  BVRGCI.SubMenu[MenuName])
    BVRGCI.BuildMenuLevel(BVRGCI.Altitude.Low, "Low", "Low Level",  BVRGCI.SubMenu[MenuName])
  end

  
  
  --- Add BVRGCI MENU Root.
  function BVRGCI.BuildMenuRoot()
    BVRGCI.Menu = MENU_COALITION:New(coalition.side.BLUE, "AI BVR/GCI")
      -- Build group size menus
      BVRGCI.BuildMenuQty(2, "Pair", BVRGCI.Menu)
      BVRGCI.BuildMenuQty(4, "Four", BVRGCI.Menu)
      -- level 2 command
      BVRGCI.MenuRemoveAdversaries = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Remove BVR Adversaries", BVRGCI.Menu, BVRGCI.RemoveAdversaries)
  end
  
  BVRGCI.BuildMenuRoot()
  
--- END BVRGCI SECTION  
--------------------------------[missionsrs_data.lua]-------------------------------- 
 
env.info( "[JTF-1] missionsrs_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MISSION TIMER SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missionsrs.lua
--
-- These values are specific to the miz and will override the default values in MISSIONSRS.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not MISSIONSRS then 
	_msg = "[JTF-1 MISSIONSRS] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	MISSIONSRS = {}
end

-- table of values for missionsrs to use this miz. Overrides default values.
-- MISSIONSRS.srsPath = "C:/Program Files/DCS-SimpleRadio-Standalone" -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
-- MISSIONSRS.srsPort = 5002                                          -- default SRS port to use if settings file is not available
-- MISSIONSRS.msg = "No Message Defined!"                             -- default message if text is nil
MISSIONSRS.freqs = "243,251,327,377.8,30"                          -- transmit on guard, CTAF, NTTR TWR, NTTR BLACKJACK and 30FM as default frequencies
-- MISSIONSRS.modulations = "AM,AM,AM,AM,FM"                          -- default modulation (count *must* match qty of freqs)
-- MISSIONSRS.vol = "1.0"                                             -- default to full volume
-- MISSIONSRS.name = "Server"                                         -- default to server as sender
-- MISSIONSRS.coalition = 0                                           -- default to spectators
-- MISSIONSRS.vec3 = nil                                              -- point from which transmission originates
-- MISSIONSRS.speed = 2                                               -- speed at which message should be played
-- MISSIONSRS.gender = "female"                                       -- default gender of sender
-- MISSIONSRS.culture = "en-US"                                       -- default culture of sender
-- MISSIONSRS.voice = ""                                              -- default voice to use

if MISSIONSRS.Start then
	MISSIONSRS:Start()
end  
--------------------------------[adminmenu_data.lua]-------------------------------- 
 
env.info( "[JTF-1] adminmenu_data" )

--- MISSION ADMIN MENU SETTINGS FOR MIZ
--
-- This file MUST be loaded AFTER adminmenu.lua
--
-- These values are specific to the miz and will override the default values in ADMIN
--

-- Error prevention. Create empty container if module core lua not loaded.
if not ADMIN then 
	ADMIN = {}
	ADMIN.traceTitle = "[JTF-1 ADMIN] "
	_msg = ADMIN.traceTitle .. "CORE FILE NOT LOADED!"
	BASE:E(_msg)
end

-- table of values to override default ADMIN values for this miz
ADMIN.menuAllSlots = false
ADMIN.jtfmenu = false

-- start the mission timer
if ADMIN.Start then
	_msg = ADMIN.traceTitle .. "Call Start()"
	BASE:T(_msg)
	ADMIN:Start()  
end
  
--------------------------------[missiontimer_data.lua]-------------------------------- 
 
env.info( "[JTF-1] missiontimer_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MISSION TIMER SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missiontimer.lua
--
-- These values are specific to the miz and will override the default values in missiontimer.lua
--

-- Error prevention. Create empty container if module core lua not loaded.
if not MISSIONTIMER then 
	_msg = "[JTF-1 MISSIONTIMER] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	MISSIONTIMER = {}
end

-- table of values for timer shedule in this miz
MISSIONTIMER.durationHrs = 11 -- Mission run time in HOURS. Default 24
--MISSIONTIMER.msgSchedule = {60, 30, 10, 5} -- Schedule for mission restart warning messages prior to the mission restart. Time in minutes. Default {60, 30, 10, 5}
--MISSIONTIMER.restartDelay =  4 -- time in minutes to delay restart if active clients are present. Dewfault 10.
--MISSIONTIMER.useSRS = true -- set to false to disable use of SRS for this module in this miz

-- start the mission timer
if MISSIONTIMER.Start then
	MISSIONTIMER:Start()  
end
  
--------------------------------[supportaircraft_data.lua]-------------------------------- 
 
env.info( "[JTF-1] supportaircraft_data" )
--------------------------------------------
--- Support Aircraft Defined in this file
--------------------------------------------
--
-- **NOTE**: SUPPORTAIRCRAFT.LUA MUST BE LOADED BEFORE THIS FILE IS LOADED!
--
-- This file contains the config data specific to the miz in which it will be used.
-- All functions and key values are in SUPPORTAIRCRAFT.LUA, which should be loaded first
--
-- Load order in miz MUST be;
--     1. supportaircraft.lua
--     2. supportaircraft_data.lua
--

-- Error prevention. Create empty container if SUPPORTAIRCRAFT.LUA is not loaded or has failed.
if not SUPPORTAC then 
  _msg = "[JTF-1 SUPPORTAC] CORE FILE NOT LOADED!"
  BASE:E(_msg)
  SUPPORTAC = {}
end

SUPPORTAC.useSRS = true

-- Support aircraft missions. Each mission block defines a support aircraft mission. Each block is processed
-- and an aircraft will be spawned for the mission. When the mission is cancelled, eg after RTB or if it is destroyed,
-- a new aircraft will be spawned and a fresh AUFTRAG created.
SUPPORTAC.mission = {
    -- {
    --   name = "ARWK", -- text name for this support mission. Combined with this block's index and the mission type to define the group name on F10 map
    --   category = SUPPORTAC.category.tanker, -- support mission category. Used to determine the auftrag type. Options are listed in SUPPORTAC.category
    --   type = SUPPORTAC.type.tankerBoom, -- type defines the spawn template that will be used
    --   zone = "ARWK", -- ME zone that defines the start waypoint for the spawned aircraft
    --   callsign = CALLSIGN.Tanker.Arco, -- callsign under which the aircraft will operate
    --   callsignNumber = 1, -- primary callsign number that will be used for the aircraft
    --   tacan = 35, -- TACAN channel the ac will use
    --   tacanid = "ARC", -- TACAN ID the ac will use. Also used for the morse ID
    --   radio = 276.5, -- freq the ac will use when on mission
    --   flightLevel = 160, -- flight level at which to spwqan aircraft and at which track will be flown
    --   speed = 315, -- IAS when on mission
    --   heading = 94, -- mission outbound leg in degrees
    --   leg = 40, -- mission leg length in NM
    --   fuelLowThreshold = 30, -- lowest fuel threshold at which RTB is triggered
    --   activateDelay = 5, -- delay, after this aircraft has been despawned, before new aircraft is spawned
    --   despawnDelay = 10, -- delay before this aircraft is despawned
    -- },
    {
    name = "AR641A", -- text name for this support mission. Combined with this block's index and the mission type to define the group name on F10 map
    category = SUPPORTAC.category.tanker, -- support mission category. Used to determine the auftrag type. Options are listed in SUPPORTAC.categories
    type =  SUPPORTAC.type.tankerBoom, --"KC-135-TEX1", --SUPPORTAC.type.tankerBoom, -- type defines the spawn template that will be used
    zone = "AR641A", -- ME zone that defines the start waypoint for the spawned aircraft
    callsign = CALLSIGN.Tanker.Texaco, -- callsign under which the aircraft will operate
    callsignNumber = 1, -- primary callsign number that will be used for the aircraft
    tacan = 31, -- TACAN channel the ac will use
    tacanid = "TEX", -- TACAN ID the ac will use. Also used for the morse ID
    radio = 295.4, -- freq the ac will use when on mission
    flightLevel = 240,
    speed = 315, -- IAS when on mission
    heading = 71, -- mission outbound leg in degrees
    leg = 30, -- mission leg length in NM
    livery = "Metrea KC-135 N569MA",
  },
  {
    name = "AR641A",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,--"KC-135MPRS-SHL1", --
    zone = "AR641A",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 1,
    tacan = 35,
    tacanid = "SHL",
    radio = 276.1,
    flightLevel = 200,
    speed = 315,
    heading = 71,
    leg = 30,
  },
  {
    name = "AR635",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerBoom,--"KC-135-TEX2", --
    zone = "AR635",
    callsign = CALLSIGN.Tanker.Texaco,
    callsignNumber = 2,
    tacan = 52,
    tacanid = "TEX",
    radio = 352.6,
    flightLevel = 240,
    speed = 315,
    heading = 92,
    leg = 50,
    livery = "Metrea KC-135",
  },
  {
    name = "AR635",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,--"KC-135MPRS-SHL2", -- 
    zone = "AR635",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 2,
    tacan = 34,
    tacanid = "SHL",
    radio = 317.775,
    flightLevel = 200,
    speed = 315,
    heading = 92,
    leg = 50,
  },
  {
    name = "AR230V",
    category = SUPPORTAC.category.tanker,
    type =  SUPPORTAC.type.tankerBoom,--"KC-135-ARC1", --
    zone = "AR230V",
    callsign = CALLSIGN.Tanker.Arco,
    callsignNumber = 1,
    tacan = 30,
    tacanid = "ARC",
    radio = 343.6,
    flightLevel = 150,
    speed = 215,
    heading = 41,
    leg = 30,
    livery = "Metrea KC-135",
  },
  {
    name = "AR230V",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbeC130,--"KC-130-ARC3", --
    zone = "AR230V",
    callsign = CALLSIGN.Tanker.Arco,
    callsignNumber = 3,
    tacan = 29,
    tacanid = "ARC",
    radio = 323.2,
    flightLevel = 100,
    speed = 315,
    heading = 41,
    leg = 30,
  },
  {
    name = "ARLNS",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerBoom,--"KC-135-TEX3", --
    zone = "ARLNS",
    callsign = CALLSIGN.Tanker.Texaco,
    callsignNumber = 3,
    tacan = 51,
    tacanid = "TEX",
    radio = 324.05,
    flightLevel = 240,
    speed = 315,
    heading = 331,
    leg = 20,
    livery = "Metrea KC-135 N571MA"
  },
  {
    name = "ARLNS",
    category = SUPPORTAC.category.tanker,
    type = SUPPORTAC.type.tankerProbe,--"KC-135MPRS-SHL3", --
    zone = "ARLNS",
    callsign = CALLSIGN.Tanker.Shell,
    callsignNumber = 3,
    tacan = 33,
    tacanid = "SHL",
    radio = 319.8,
    flightLevel = 200,
    speed = 315,
    heading = 331,
    leg = 20,
  },
  {
    name = "AWACSEAST",
    category = SUPPORTAC.category.awacs,
    type = SUPPORTAC.type.awacsE3a,--"AWACS-E3A-DR1", --
    zone = "AWACS-EAST",
    callsign = CALLSIGN.AWACS.Darkstar,
    callsignNumber = 1,
    tacan = nil,
    tacanid = nil,
    radio = 282.025,
    flightLevel = 300,
    speed = 400,
    heading = 210,
    leg = 43,
    activateDelay = 5,
    despawnDelay = 10,
    fuelLowThreshold = 15,
  },
}

-- call the function that initialises the SUPPORTAC module
if SUPPORTAC.Start ~= nil then
  _msg = "[JTF-1 SUPPORTAC] SUPPORTAIRCRAFT_DATA - call SUPPORTAC:Start()."
  BASE:I(_msg)
  SUPPORTAC:Start()
end


  
--------------------------------[staticranges_data.lua]-------------------------------- 
 
env.info( "[JTF-1] staticranges_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- STATIC RANGES SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER staticranges.lua
--
-- These values are specific to the miz and will override the default values in STATICRANGES.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not STATICRANGES then 
	_msg = "[JTF-1 STATICRANGES] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	STATICRANGES = {}
end

-- These values will overrides the default values in staticranges.lua
STATICRANGES.strafeMaxAlt             = 1530 -- [5000ft] in metres. Height of strafe box.
STATICRANGES.strafeBoxLength          = 3000 -- [10000ft] in metres. Length of strafe box.
STATICRANGES.strafeBoxWidth           = 300 -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
STATICRANGES.strafeFoullineDistance   = 610 -- [2000ft] in metres. Min distance for from target for rounds to be counted.
STATICRANGES.strafeGoodPass           = 20 -- Min hits for a good pass.

-- Range targets table
STATICRANGES.Ranges = {
    -- { -- SAMPLE RANGE DATA
    --   rangeId               = "R63", -- unique ID for the range
    --   rangeName             = "Range 63", -- text used for messages
    --   rangeZone             = "R63", -- zone object in which range objects are placed
    --   rangeControlFrequency = 361.6, -- TAC radio frequency for the range
    --   groups = { -- group objects used as bombing targets
    --     "63-01", "63-02", "63-03", "63-05", 
    --     "63-10", "63-12", "63-15", "R-63B Class A Range-01", 
    --     "R-63B Class A Range-02",    
    --   },
    --   units = { -- unit objects used as bombing targets
    --     "R63BWC", "R63BEC",
    --   },
    --   strafepits = { -- unit objects used as strafepits 
    --     { --West strafepit -- use sub groups for multiple strafepits
    --       "R63B Strafe Lane L2", 
    --       "R63B Strafe Lane L1", 
    --       "R63B Strafe Lane L3",
    --     },
    --     { --East strafepit 
    --       "R63B Strafe Lane R2", 
    --       "R63B Strafe Lane R1", 
    --       "R63B Strafe Lane R3",
    --     },
    --   },
    -- },
    { --R61
      rangeId               = "R61",
      rangeName             = "Range 61",
      rangeZone             = "R61",
      rangeControlFrequency = 341.925,
      groups = {
        "61-01", "61-03",
      },
      units = {
        "61-01 Aircraft #001", "61-01 Aircraft #002", 
      },
      strafepits = {
      },
    },--R61 END
    { --R62
      rangeId               = "R62",
      rangeName             = "Range 62",
      rangeZone             = "R62",
      rangeControlFrequency = 234.250,
      groups = {
        "62-01", "62-02", "62-04",
        "62-03", "62-08", "62-09", "62-11", 
        "62-12", "62-13", "62-14", "62-21", 
        "62-21-01", "62-22", "62-31", "62-32",
        "62-41", "62-42", "62-43", "62-44", 
        "62-45", "62-51", "62-52", "62-53", 
        "62-54", "62-55", "62-56", "62-61", 
        "62-62", "62-63", "62-71", "62-72", 
        "62-73", "62-74", "62-75", "62-76", 
        "62-77", "62-78", "62-79", "62-81", 
        "62-83", "62-91", "62-92", "62-93",
      },
      units = {
        "62-32-01", "62-32-02", "62-32-03", "62-99",  
      },
      strafepits = {
      },
    },--R62 END
    { --R63
      rangeId               = "R63",
      rangeName             = "Range 63",
      rangeZone             = "R63",
      rangeControlFrequency = 361.6,
      groups = {
        "63-01", "63-02", "63-03", "63-05", 
        "63-10", "63-12", "63-15", "R-63B Class A Range-01", 
        "R-63B Class A Range-02",    
      },
      units = {
        "R63BWC", "R63BEC",
      },
      strafepits = {
        { --West strafepit
          "R63B Strafe Lane L2", 
          "R63B Strafe Lane L1", 
          "R63B Strafe Lane L3",
        },
        { --East strafepit 
          "R63B Strafe Lane R2", 
          "R63B Strafe Lane R1", 
          "R63B Strafe Lane R3",
        },
      },
    },--R63 END
    { --R64
      rangeId               = "R64",
      rangeName             = "Range 64",
      rangeZone             = "R64",
      rangeControlFrequency = 288.8,
      groups = {
        "64-10", "64-11", "64-13", "64-14", 
        "64-17", "64-19", "64-15", "64-05", 
        "64-08", "64-09",
      },
      units = {
        "64-12-05", "R64CWC", "R64CEC", "R-64C Class A Range-01", 
        "R-64C Class A Range-02", 
      },
      strafepits = {
        {-- West strafepit
          "R64C Strafe Lane L2", 
          "R64C Strafe Lane L1", 
          "R64C Strafe Lane L3",
        },
        {-- East strafepit
          "R64C Strafe Lane R2", 
          "R64C Strafe Lane R1", 
          "R64C Strafe Lane R3",
        },
      },
    },--R64 END
    { --R65
      rangeId               = "R65",
      rangeName             = "Range 65",
      rangeZone             = "R65",
      rangeControlFrequency = 225.450,
      groups = {
        "65-01", "65-02", "65-03", "65-04", 
        "65-05", "65-06", "65-07", "65-08", 
        "65-11",
      },
      units = {
      },
      strafepits = {
      },
    },--R65 END
}
  
-- Start the STATICRANGES module
if STATICRANGES.Start then
	STATICRANGES:Start()
end  
--------------------------------[activeranges_data.lua]-------------------------------- 
 
env.info( "[JTF-1] activeranges_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ACTIVE RANGES SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER activeranges.lua
--
-- These values are specific to the miz and will override the default values in ACTIVERANGES.default
--

-- Error prevention. Create empty container if module core lua not loaded.
if not ACTIVERANGES then 
	_msg = "[JTF-1 ACTIVERANGES] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	ACTIVERANGES = {}
end


--ACTIVERANGES.spawnatstart = false -- if false, do not spawn targets at mission start
ACTIVERANGES.activeatstart = false -- if true, set AI on for targets spawned at mission start
ACTIVERANGES.useSRS = true -- set to false to disable use of SRS for this module in this miz
--ACTIVERANGES.rangeRadio = "377.8" -- radio frequency over which to broadcast Active Range messages


-- start the mission timer
if ACTIVERANGES.Start then
	ACTIVERANGES:Start()
end  
--------------------------------[markspawn_data.lua]-------------------------------- 
 
env.info( "[JTF-1] markspawn_data" )
--------------------------------------------
--- Mark Spawn Mission Data Defined in this file
--------------------------------------------
--
-- **NOTE**: MARKSPAWN.LUA MUST BE LOADED BEFORE THIS FILE IS LOADED!
--
-- This file contains the config data specific to the miz in which it will be used.
-- All functions and key values are in MARKSPAWN.LUA, which should be loaded first
--
-- Load order in miz MUST be;
--     1. markspawn.lua
--     2. markspawn_data.lua
--

-- Error prevention. Create empty container if SUPPORTAIRCRAFT.LUA is not loaded or has failed.
if not MARKSPAWN then 
	MARKSPAWN = {}
	SUPPORTAC.traceTitle = "[JTF-1 MARKSPAWN] "
	_msg = MARKSPAWN.traceTitle .. "CORE FILE NOT LOADED!"
	BASE:E(_msg)
end

-- UNCOMMENT TO OVERRIDE MARKSPAWN DEFAULT VALUES BELOW

-- MARKSPAWN.DEFAULT_BLUE_COUNTRY = 2 -- USA
-- MARKSPAWN.DEFAULT_RED_COUNTRY = 0 -- RUSSIA
-- MARKSPAWN.MLDefaultAirAlt = 200 -- altitude Flight Level
-- MARKSPAWN.MLDefaultHdg = 000
-- MARKSPAWN.MLDefaultSkill = "AVERAGE"
-- MARKSPAWN.MLDefaultDistance = 0
-- MARKSPAWN.MLDefaultGroundDistance = 0
-- MARKSPAWN.MLDefaultROE = "FREE"
-- MARKSPAWN.MLDefaultROT = "EVADE"
-- MARKSPAWN.MLDefaultFreq = 251
-- MARKSPAWN.MLDefaultNum = 1
-- MARKSPAWN.MLDefaultAirSpeed = 425
-- MARKSPAWN.MLDefaultGroundSpeed = 21
-- MARKSPAWN.MLDefaultAlert = "RED"
-- MARKSPAWN.MLDefaultGroundTask = "NOTHING"




-- call the function that initialises the SUPPORTAC module
if MARKSPAWN.Start ~= nil then
    _msg = MARKSPAWN.traceTitle .. "MARKSPAWN_DATA - call MARKSPAWN:Start()."
    BASE:I(_msg)
    MARKSPAWN:Start()
  end
  
  
--------------------------------[missiletrainer_data.lua]-------------------------------- 
 
env.info( "[JTF-1] missiletrainer_data" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- MISSILE TRAINER SETTINGS FOR MIZ
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missiletrainer.lua
--
-- These values are specific to the miz and will override the default values in missiletrainer.lua
--

-- Error prevention. Create empty container if module core lua not loaded.
if not MTRAINER then 
	_msg = "[JTF-1 MTRAINER] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	MTRAINER = {}
end

-- these values will override those set in the core file
MTRAINER.safeZone = nil -- safezone to use, otherwise nil for entire map
MTRAINER.launchZone = nil -- launchzone to use, otherwise nil for entire map
MTRAINER.DefaultLaunchAlerts = false -- if true, disable launch alerts
MTRAINER.DefaultMissileDestruction = false -- 
MTRAINER.DefaultLaunchMarks = false -- if true, enable map marks for launched missiles
MTRAINER.ExplosionDistance = 300 -- distance from player at which to destroy incoming missiles
MTRAINER.useSRS = true -- module should use SRS for radio messages

-- Start the MTRAINER module
if MTRAINER.Start then
  MTRAINER:Start()
end


  
--------------------------------[bfmacm_data.lua]-------------------------------- 
 
env.info( "[JTF-1] bfmacm_data" )
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- ACM/BFM
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- This file MUST be loaded AFTER missiletrainer.lua
--
-- These values are specific to the miz and will override the default values in missiletrainer.lua
--

-- Error prevention. Create empty container if module core lua not loaded.
if not BFMACM then 
	_msg = "[JTF-1 BFMACM] CORE FILE NOT LOADED!"
	BASE:E(_msg)
	BFMACM = {}
end

BFMACM.zoneBfmAcmName = "COYOTEABC" -- The BFM/ACM Zone
BFMACM.zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
	"zone_box",
} 

BFMACM.adversary = {
	menu = { -- Adversary menu
		{template = "ADV_F4", menuText = "Adversary A-4"},
		{template = "ADV_MiG28", menuText = "Adversary MiG-28"},
		{template = "ADV_Su27", menuText = "Adversary MiG-23"},
		{template = "ADV_MiG23", menuText = "Adversary Su-27"},
		{template = "ADV_F16", menuText = "Adversary F-16"},
		{template = "ADV_F18", menuText = "Adversary F-18"},
	},
	range = {5, 10, 20}, -- ranges at which to spawn adversaries in nautical miles
	spawn = {}, -- container for aversary spawn objects
	defaultRadio = "377.8",
}


if BFMACM.Start then
	BFMACM:Start()
end  
--------------------------------[core\mission_end.lua]-------------------------------- 
 
env.info( "*** [JTF-1] MISSION SCRIPTS END ***" )
