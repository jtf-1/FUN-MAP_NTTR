env.info( '[JTF-1] *** MISSION FILE BUILD DATE: 2022-04-06T19:13:07.36Z ***') 
env.info( '[JTF-1] *** JTF-1 STATIC MISSION SCRIPT START ***' )

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
}
--- END INIT
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Check for Static or Dynamic mission file loading flag
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 then
  env.warning('[JTF-1] *** JTF-1 - DEV flag is ON! ***')
  MESSAGE:New("Dev Mode is ON!"):ToAll()
  DEV_MENU = {
    traceOn = true, -- default tracestate false == trace off, true == trace on.
    flagLoadMission = (JTF1.flagLoadMission and JTF1.flagLoadMission or 9999), -- flag for load misison trigger
    missionRestartMsg = (JTF1.missionRestartMsg and JTF1.missionRestartMsg or "ADMIN9999"), -- Message to trigger mission restart via jtf1-hooks
  }
  
  function DEV_MENU:toggleTrace(traceOn)
    if traceOn then
      BASE:TraceOff()
    else
      BASE:TraceOn()
    end
    self.traceOn = not traceOn
  end

  function DEV_MENU:testLua()
    local base = _G
    local f = assert( base.loadfile( 'E:/GitHub/FUN-MAP_NTTR/scripts/dynamic/test.lua' ) )
    if f == nil then
                        error ("Mission Loader: could not load test.lua." )
                else
                        env.info( "[JTF-1] Mission Loader: test.lua dynamically loaded." )
                        --return f()
                end
  end

  function DEV_MENU:restartMission()
    trigger.action.setUserFlag(ADMIN.flagLoadMission, 99)
  end

  -- Add Dev submenu to F10 Other
  DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
  MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, DEV_MENU.toggleTrace, DEV_MENU, DEV_MENU.traceOn)
  MENU_MISSION_COMMAND:New("Reload Test LUA.", DEV_MENU.topmenu, DEV_MENU.testLua)
  MENU_MISSION_COMMAND:New("Restart Mission", DEV_MENU.topmenu, DEV_MENU.restartMission)

  -- trace all events
  BASE:TraceAll(true)

  if DEV_MENU.traceOn then
    BASE:TraceOn()
  end  

else
  env.info('[JTF-1] *** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Disable AI for ground targets and FAC
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local setGroupGroundActive = SET_GROUP:New():FilterActive():FilterCategoryGround():FilterOnce()

-- Prefix for groups for which AI should NOT be disabled
local excludeAI = "BLUFOR"

setGroupGroundActive:ForEachGroup(
  function(activeGroup)
    if not string.find(activeGroup:GetName(), excludeAI) then
      activeGroup:SetAIOff()
    end      
  end
)

---  END DISABLE AI
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Default SRS Text-to-Speech
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Send messages through SRS using STTS
-- Script will try to load the file specified with LocalServerConfigFile [name of settings file] 
-- and LocalServerConfigPath [path to file]. This file should define the path to the SRS installation 
-- directory and the port used by the DCS server instance running the mission. 
--
-- If the settings file is not found, the defaults for srs_path and srs_port will be used.
--
-- Message text will be formatted as a SOUNDTEXT object.
-- 


MISSIONSRS = {
  fileName = "ServerLocalSettings.lua", -- name of file containing local server settings
  LocalServerConfigPath = nil, --"C:/Users/rober/Saved Games/DCS.openbeta_server/Scripts", -- path to server srs settings
  LocalServerConfigFile = "LocalServerSettings.txt", -- srs server settings file name
  defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  defaultSrsPort = 5002, -- default SRS port to use if settings file is not available
  defaultText = "No Message Defined!",
  defaultFreqs = "243,251,327,377.8", -- transmit on guard, CTAF, NTTR TWR and NTTR BLACKJACK as default frequencies
  defaultModulation = "AM,AM,AM,AM", -- default modulation (count *must* match qty of freqs)
  defaultVol = "1.0", -- default to full volume
  defaultName = "Server", -- default to server as sender
  defaultCoalition = 0, -- default to spectators
  defaultVec3 = nil, -- point from which transmission originates
  defaultSpeed = 2, -- speed at which message should be played
  defaultGender = "female", -- default gender of sender
  defaultCulture = "en-US", -- default culture of sender
  defaultVoice = "", -- default voice to use
}

function MISSIONSRS:LoadSettings()
  local loadFile  = MISSIONSRS.LocalServerConfigFile
  if UTILS.CheckFileExists(MISSIONSRS.LocalServerConfigPath, MISSIONSRS.LocalServerConfigFile) then
    local loadFile, serverSettings = UTILS.LoadFromFile(MISSIONSRS.LocalServerConfigPath, MISSIONSRS.LocalServerConfigFile)
    BASE:T({"[MISSIONSRS] Load Server Settings",{serverSettings}})
    if not loadFile then
      BASE:E(string.format("[MISSIONSRS] ERROR: Could not load %s", loadFile))
    else
      MISSIONSRS.SRS_DIRECTORY = serverSettings[1] or MISSIONSRS.defaultSrsPath
      MISSIONSRS.SRS_PORT = serverSettings[2] or MISSIONSRS.defaultSrsPort
      MISSIONSRS:AddRadio()
      BASE:T({"[MISSIONSRS]",{MISSIONSRS}})
    end
  else
    BASE:E(string.format("[MISSIONSRS] ERROR: Could not find %s", loadFile))
  end
end

function MISSIONSRS:AddRadio()
  MISSIONSRS.Radio = MSRS:New(MISSIONSRS.SRS_DIRECTORY, MISSIONSRS.defaultFreqs, MISSIONSRS.defaultModulation)
  MISSIONSRS.Radio:SetPort(MISSIONSRS.SRS_PORT)
  MISSIONSRS.Radio:SetGender(MISSIONSRS.defaultGender)
  MISSIONSRS.Radio:SetCulture(MISSIONSRS.defaultCulture)
  MISSIONSRS.Radio.name = MISSIONSRS.defaultName
end

function MISSIONSRS.SendRadio(msgText)
  BASE:T({"[MISSIONSRS] SendRadio", msgText})
  local text = SOUNDTEXT:New(msgText)
  MISSIONSRS.Radio:PlaySoundText(text)
end


MISSIONSRS:LoadSettings()

 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ADMIN MENU SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
-- to TRUE.
--
-- 

ADMIN = EVENTHANDLER:New()
ADMIN:HandleEvent(EVENTS.PlayerEnterAircraft)

ADMIN.adminUnitName = "XX_" -- String to locate within unit name for admin slots
ADMIN.missionRestart = (JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999") -- Message to trigger mission restart via jtf1-hooks
ADMIN.flagLoadMission = 9999
ADMIN.menuAllSlots = false -- Set to true for admin menu to appear for all players

ADMIN.missionList = { -- List of missions for load mission menu commands
  {menuText = "Restart current mission", missionFlagValue = 0},
  {menuText = "Load DAY NTTR", missionFlagValue = 1},
  {menuText = "Load DAY NTTR - IFR", missionFlagValue = 2},
  {menuText = "Load NIGHT NTTR", missionFlagValue = 3},
  {menuText = "Load NIGHT NTTR - No Moon", missionFlagValue = 4},
}

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

function ADMIN:OnEventPlayerEnterAircraft(EventData)
  if not ADMIN.menuAllSlots then
    local unitName = EventData.IniUnitName
    local unit, playername = ADMIN:GetPlayerUnitAndName(unitName)
    if unit and playername then
      local adminCheck = (string.find(unitName, ADMIN.adminUnitName) and "true" or "false")
      if string.find(unitName, ADMIN.adminUnitName) then
        SCHEDULER:New(nil, ADMIN.BuildAdminMenu, {self, unit, playername}, 0.5)
      end
    end
  end
end

--- Set mission flag to load a new mission.
--- If mapFlagValue is current mission, restart the mission via jtf1-hooks
-- @param #string playerName Name of client calling restart command.
-- @param #number mapFlagValue Mission number to which flag should be set.
function ADMIN:LoadMission(playerName, mapFlagValue)
  if playerName then
    env.info("[JTF-1] ADMIN Restart player name: " .. playerName)
  end
  if mapFlagValue == 0 then -- use jtf1-hooks to restart current mission
    MESSAGE:New(ADMIN.missionRestart):ToAll()
  else
    trigger.action.setUserFlag(ADMIN.flagLoadMission, mapFlagValue)
  end
end

--- Add admin menu and commands if client is in an ADMIN spawn
-- @param #object unit Unit of player.
-- @param #string playername Name of player
function ADMIN:BuildAdminMenu(unit,playername)
  if not (unit or playername) then
    -- create menu at Mission level
    local adminMenu = MENU_MISSION:New("Admin")
    for i, menuCommand in ipairs(ADMIN.missionList) do
      MENU_MISSION_COMMAND:New( menuCommand.menuText, adminMenu, ADMIN.LoadMission, self, playername, menuCommand.missionFlagValue )
    end
  else
    -- Create menu for admin slot
    local adminGroup = unit:GetGroup()
    local adminMenu = MENU_GROUP:New(adminGroup, "Admin")
    local testMenu = MENU_GROUP:New(adminGroup, "Test", adminMenu)
    for i, menuCommand in ipairs(ADMIN.missionList) do
      MENU_GROUP_COMMAND:New( adminGroup, menuCommand.menuText, adminMenu, ADMIN.LoadMission, self, playername, menuCommand.missionFlagValue )
      MENU_GROUP_COMMAND:New( adminGroup, "SRS Broadcast test", testMenu, MISSIONSRS.SendRadio, "99 all players, test broadcast over default radio.")
    end
  end
end

if ADMIN.menuAllSlots then
  ADMIN:BuildAdminMenu()
end

--- END ADMIN MENU SECTION
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSION TIMER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Mission Timer
--
-- Add schedules to display messages at set intervals prior to restarting the base mission.
-- ME switched triggers should be set to a FLAG EQUALS condition for the flag flagLoadMission
-- value (defined in script header). Sending missionRestart text will trigger restarting the
-- current mission via jtf1-hooks.lua.
--

MISSIONTIMER = {}

MISSIONTIMER.durationHrs = 11 -- Mission run time in HOURS
MISSIONTIMER.msgSchedule = {60, 30, 10, 5} -- Schedule for mission restart warning messages. Time in minutes.
MISSIONTIMER.durationSecs = MISSIONTIMER.durationHrs * 3600 -- Mission run time in seconds
MISSIONTIMER.msgWarning = {} -- schedule container
MISSIONTIMER.missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ) -- Message to trigger mission restart via jtf1-hooks
MISSIONTIMER.restartDelay = 4 -- time in minutes to delay restart if active clients are present.

BASE:T({"[MISSIONTIMER]",{MISSIONTIMER}})

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MISSIONTIMER:AddSchedules()
  if MISSIONTIMER.msgSchedule ~= nil then
    for i, msgTime in ipairs(self.msgSchedule) do
      self.msgWarning[i] = SCHEDULER:New( nil, 
        function()
          BASE:T("[MISSIONTIMER] TIMER WARNING CALLED at " .. tostring(msgTime) .. " minutes remaining.")
          local msg = "99 all players, mission will restart in  " .. msgTime .. " minutes!"
          if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
            MISSIONSRS.SendRadio(msg)
          else -- otherwise, send in-game text message
            MESSAGE:New(msg):ToAll()
          end
        end,
      {msgTime}, self.durationSecs - (msgTime * 60))
    end
  end
  self.msgWarning["restart"] = SCHEDULER:New( nil,
    function()
      MISSIONTIMER:Restart()
    end,
    { }, self.durationSecs)
end

function MISSIONTIMER:Restart()
  local clientList = SET_CLIENT:New()
  clientList:FilterActive()
  clientList:FilterStart()
  if clientList:CountAlive() > 0 then
    local delayTime = self.restartDelay
    local msg  = "99 all players, mission will restart when no active clients are present. Next check will be in " .. tostring(delayTime) .." minutes." 
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS.SendRadio(msg)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    self.msgWarning["restart"] = SCHEDULER:New( nil,
      function()
        MISSIONTIMER:Restart()
      end,
      { }, (self.restartDelay * 60))
  else
    BASE:T("[MISSIONTIMER] RESTART MISSION")
    MESSAGE:New(MISSIONTIMER.missionRestart):ToAll()
  end
end

MISSIONTIMER:AddSchedules()

--- END MISSION TIMER
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSILE TRAINER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

MTRAINER = {
  menuadded = {},
  MenuF10   = {},
  safeZone = nil, -- safezone to use, otherwise nil --"ZONE_FOX"
  launchZone = nil, -- launchzone to use, otherwise nil --"ZONE_FOX"
  DefaultLaunchAlerts = false,
  DefaultMissileDestruction = false,
  DefaultLaunchMarks = false,
  ExplosionDistance = 300,
}
-- Create MTRAINER container and defaults

-- add event handler
MTRAINER.eventHandler = EVENTHANDLER:New()
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
MTRAINER.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

-- check player is present and unit is alive
function MTRAINER:GetPlayerUnitAndName(unitname)
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

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #string unitname name of client unit
function MTRAINER:ToggleTrainer(unitname)
  self.fox:_ToggleLaunchAlert(unitname)
  self.fox:_ToggleDestroyMissiles(unitname)
end

--- Add Missile Trainer for GROUP|UNIT in F10 root menu.
-- @param #string unitname Name of unit occupied by client
function MTRAINER:AddMenu(unitname)
  local unit, playername = self:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if MTRAINER.menuadded[uid] == nil then
        -- add GROUP menu if not already present
        if MTRAINER.MenuF10[gid] == nil then
          BASE:T("[MTRAINER] Adding menu for group: " .. group:GetName())
          MTRAINER.MenuF10[gid] = MENU_GROUP:New(group, "Missile Trainer")
        end
        if MTRAINER.MenuF10[gid][uid] == nil then
          BASE:T("[MTRAINER] Add submenu for player: " .. playername)
          MTRAINER.MenuF10[gid][uid] = MENU_GROUP:New(group, playername, MTRAINER.MenuF10[gid])
          BASE:T("[MTRAINER] Add commands for player: " .. playername)
          MENU_GROUP_COMMAND:New(group, "Missile Trainer On/Off", MTRAINER.MenuF10[gid][uid], MTRAINER.ToggleTrainer, MTRAINER, unitname)
          MENU_GROUP_COMMAND:New(group, "My Status", MTRAINER.MenuF10[gid][uid], MTRAINER.fox._MyStatus, MTRAINER.fox, unitname)
        end
        MTRAINER.menuadded[uid] = true
      end
    else
      BASE:T(string.format("[MTRAINER] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    BASE:T(string.format("[MTRAINER] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end

-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerEnterAircraft(EventData) 
  local unitname = EventData.IniUnitName
  local unit, playername = MTRAINER:GetPlayerUnitAndName(unitname)
  if unit and playername then
    SCHEDULER:New(nil, MTRAINER.AddMenu, {MTRAINER, unitname, true},0.1)
  end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function MTRAINER.eventHandler:OnEventPlayerLeaveUnit(EventData)
  local playername = EventData.IniPlayerName
  local unit = EventData.IniUnit
  local gid = EventData.IniGroup:GetID()
  local uid = EventData.IniUnit:GetID()
  BASE:T("[MTRAINER] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
  if gid and uid then
    if MTRAINER.MenuF10[gid] then
      BASE:T("[MTRAINER] Removing menu for unit UID:" .. uid)
      MTRAINER.MenuF10[gid][uid]:Remove()
      MTRAINER.MenuF10[gid][uid] = nil
      MTRAINER.menuadded[uid] = nil
    end
  end
end

--- END MISSILE TRAINER
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN SUPPORT AIRCRAFT SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- define table of respawning support aircraft ---
local TableSpawnSupport = { -- {spawnobjectname, spawnzone, callsignName, callsignNumber}
  {
    spawnobject     = "AR230V_KC-135_01", 
    spawnzone       = "AR230V", 
    callsignName    = 2, 
    callsignNumber  = 1
  },
  {
    spawnobject     = "AR230V_KC-130J_01", 
    spawnzone       = "AR230V", 
    callsignName    = 2, 
    callsignNumber  = 3
  },
  {
    spawnobject     = "AR635_KC-135_01", 
    spawnzone       = "AR635", 
    callsignName    = 1,
    callsignNumber  = 2
  },
 {
   spawnobject     = "XX_AR625_KC-135_01", -- remove XX_ to reactivate
   spawnzone       = "AR625", 
   callsignName    = 1,
   callsignNumber  = 3
 },
  {
    spawnobject     = "AR641A_KC-135_01", 
    spawnzone       = "AR641A", 
    callsignName    = 1,
    callsignNumber  = 1
  },
  {
    spawnobject     = "AR635_KC-135MPRS_01", 
    spawnzone       = "AR635", 
    callsignName    = 3,
    callsignNumber  = 2
  },
 {
   spawnobject     = "XX_AR625_KC-135MPRS_01", -- remove XX_ to reactivate
   spawnzone       = "AR625", 
   callsignName    = 3,
   callsignNumber  = 3
 },
  {
    spawnobject     = "AR641A_KC-135MPRS_01", 
    spawnzone       = "AR641A", 
    callsignName    = 3,
    callsignNumber  = 1
  },
  {
    spawnobject    = "ARLNS_KC-135MPRS_01", 
    spawnzone       = "ARLNS", 
    callsignName    = 3,
    callSignNumber  = 3
  },
  {
    spawnobject    = "ARLNS_KC-135_01", 
    spawnzone       = "ARLNS", 
    callsignName    = 1,
    callSignNumber  = 3
  },
  {
    spawnobject     = "AWACS_DARKSTAR", 
    spawnzone       = "AWACS", 
    callsignName    = 5, 
    callsignNumber  = 1
  },
}

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone, callsignName, callsignNumber
  if GROUP:FindByName(SupportSpawn.spawnobject) then
    local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )
    SupportSpawnObject:InitLimit( 1, 0 )
      :OnSpawnGroup(
        function ( SpawnGroup )
          --SpawnGroup:CommandSetCallsign(SupportSpawn.callsignName, SupportSpawn.callsignNumber)
          local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
          local CheckTanker = SCHEDULER:New( nil, 
            function ()
              if SpawnGroup then
                if SpawnGroup:IsNotInZone( ZONE:FindByName(SupportSpawn.spawnzone) ) then
                  SupportSpawnObject:ReSpawn( SpawnIndex )
                  BASE:T("[JTF-1][SUPPORTSPAWN] Spawned aircraft: " .. SpawnGroup:GetName() .. " is not in zone.")
                end
              end
            end,
            {}, 0, 60 
          )
        end
      )
      :InitRepeatOnLanding()
      :Spawn()
    BASE:T("[JTF-1][SUPPORTSPAWN] Spawned " .. SupportSpawn.spawnobject)
  else
    BASE:E("[JTF-1] Function SpawnSupport: spawn template not found in mission: " .. tostring(SupportSpawn.spawnobject))
  end
end

-- spawn support aircraft ---
for i, v in ipairs( TableSpawnSupport ) do
  SpawnSupport ( v )
end

--- END SUPPORT AIRCRAFT SECTION
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN STATIC RANGE SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- @field #STATICRANGES
local STATICRANGES = {}

STATICRANGES.Defaults = {
  strafeMaxAlt             = 1530, -- [5000ft] in metres. Height of strafe box.
  strafeBoxLength          = 3000, -- [10000ft] in metres. Length of strafe box.
  strafeBoxWidth           = 300, -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
  strafeFoullineDistance   = 610, -- [2000ft] in metres. Min distance for from target for rounds to be counted.
  strafeGoodPass           = 20, -- Min hits for a good pass.
  rangeSoundFilesPath      = "Range Soundfiles/" -- Range sound files path in miz
}

-- Range targets table
STATICRANGES.Ranges = {
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
  -- { --R62B
  --   rangeId               = "R62B",
  --   rangeName             = "Range 62B",
  --   rangeZone             = "R62B",
  --   rangeControlFrequency = 234.250,
  --   groups = {
  --     "62-03", "62-08", "62-09", "62-11", 
  --     "62-12", "62-13", "62-14", "62-21", 
  --     "62-21-01", "62-22", "62-31", "62-32",
  --     "62-41", "62-42", "62-43", "62-44", 
  --     "62-45", "62-51", "62-52", "62-53", 
  --     "62-54", "62-55", "62-56", "62-61", 
  --     "62-62", "62-63", "62-71", "62-72", 
  --     "62-73", "62-74", "62-75", "62-76", 
  --     "62-77", "62-78", "62-79", "62-81", 
  --     "62-83", "62-91", "62-92", "62-93",
  --   },
  --   units = {
  --     "62-32-01", "62-32-02", "62-32-03", "62-99",  
  --   },
  --   strafepits = {
  --   },
  -- },--R62B END
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
    rangeControlFrequency = 341.925,
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


function STATICRANGES:AddStaticRanges(TableRanges)

  for rangeIndex, rangeData in ipairs(TableRanges) do
  
    local rangeObject = "Range_" .. rangeData.rangeId
    
    self[rangeObject] = RANGE:New(rangeData.rangeName)
      self[rangeObject]:DebugOFF()  
      self[rangeObject]:SetRangeZone(ZONE_POLYGON:FindByName(rangeData.rangeZone))
      self[rangeObject]:SetMaxStrafeAlt(self.Defaults.strafeMaxAlt)
      self[rangeObject]:SetDefaultPlayerSmokeBomb(false)
 
    if rangeData.groups ~= nil then -- add groups of targets
      for tgtIndex, tgtName in ipairs(rangeData.groups) do
        self[rangeObject]:AddBombingTargetGroup(GROUP:FindByName(tgtName))
      end
    end
    
    if rangeData.units ~= nil then -- add individual targets
      for tgtIndex, tgtName in ipairs(rangeData.units) do
        self[rangeObject]:AddBombingTargets( tgtName )
      end
    end
    
    if rangeData.strafepits ~= nil then -- add strafe targets
      for strafepitIndex, strafepit in ipairs(rangeData.strafepits) do
        self[rangeObject]:AddStrafePit(strafepit, self.Defaults.strafeBoxLength, self.Defaults.strafeBoxWidth, nil, true, self.Defaults.strafeGoodPass, self.Defaults.strafeFoullineDistance)
      end  
    end
    
    if rangeData.rangeControlFrequency ~= nil then
      
    end

    self[rangeObject]:Start()
  end

end

-- Create ranges
STATICRANGES:AddStaticRanges(STATICRANGES.Ranges)

--- END STATIC RANGES
 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN DYNAMIC RANGE SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local ACTIVERANGES = {
    menu = {}
  }
  
  
  ACTIVERANGES.menu.menuTop = MENU_COALITION:New(coalition.side.BLUE, "Active Ranges")
  
  --- Deactivate or refresh target group and associated SAM
  -- @function resetRangeTarget
  -- @param #table rangeGroup Target GROUP object.
  -- @param #string rangePrefix Range nname prefix.
  -- @param #table rangeMenu Parent menu to which submenus should be added.
  -- @param #bool withSam Find and destroy associated SAM group.
  -- @param #bool refreshRange True if target is to be refreshed. False if it is to be deactivated. 
  function resetRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)
  
    if rangeGroup:IsActive() then
      rangeGroup:Destroy(false)
      if withSam then
        withSam:Destroy(false)
      end
      if refreshRange == false then
        rangeMenu:Remove()
        local reactivateRangeGroup = initActiveRange(GROUP:FindByName("ACTIVE_" .. rangePrefix), false )
        reactivateRangeGroup:OptionROE(ENUMS.ROE.WeaponHold)
        reactivateRangeGroup:OptionROTEvadeFire()
        reactivateRangeGroup:OptionAlarmStateGreen()
        MESSAGE:New("Target " .. rangePrefix .. " has been deactivated."):ToAll()
      else
        local refreshRangeGroup = initActiveRange(GROUP:FindByName("ACTIVE_" .. rangePrefix), true)
        activateRangeTarget(refreshRangeGroup, rangePrefix, rangeMenu, withSam, true)      
      end
    end
    
  end
  
  --- Activate selected range target.
  -- @function activateRangeTarget
  -- @param #table rangeGroup Target GROUP object.
  -- @param #string rangePrefix Range name prefix.
  -- @param #table rangeMenu Menu that should be removed and/or to which sub-menus should be added
  -- @param #boolean withSam Spawn and activate associated SAM target
  -- @param #boolean refreshRange True if target is to being refreshed. False if it is being deactivated.
  function activateRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)
  
    if refreshRange == nil then
      rangeMenu:Remove()
      ACTIVERANGES.menu["rangeMenu_" .. rangePrefix] = MENU_COALITION:New(coalition.side.BLUE, "Reset " .. rangePrefix, ACTIVERANGES.menu.menuTop)
    end
    
    rangeGroup:OptionROE(ENUMS.ROE.WeaponFree)
    rangeGroup:OptionROTEvadeFire()
    rangeGroup:OptionAlarmStateRed()
    rangeGroup:SetAIOnOff(true)
    
    local deactivateText = "Deactivate " .. rangePrefix
    local refreshText = "Refresh " .. rangePrefix
    local samTemplate = "SAM_" .. rangePrefix
  
    if withSam then
      local activateSam = SPAWN:New(samTemplate)
      activateSam:OnSpawnGroup(
        function (spawnGroup)
          MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], spawnGroup, false)
          MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " with SAM" , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], spawnGroup, true)
          MESSAGE:New("Target " .. rangePrefix .. " is active, with SAM."):ToAll()
          spawnGroup:OptionROE(ENUMS.ROE.WeaponFree)
          spawnGroup:OptionROTEvadeFire()
          spawnGroup:OptionAlarmStateRed()
        end
        , rangeGroup, rangePrefix, rangeMenu, withSam, deactivateText, refreshText
      )
      :Spawn()
    else
      MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, false)
      if GROUP:FindByName(samTemplate) ~= nil then
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " NO SAM" , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, true)
      else
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, true)
      end
      MESSAGE:New("Target " .. rangePrefix .. " is active."):ToAll()
    end
    
  end
  
  --- Add menus for range target.
  -- @function addActiveRangeMenu
  -- @param #table rangeGroup Target group object
  -- @param #string rangePrefix Range prefix
  function addActiveRangeMenu(rangeGroup, rangePrefix)
  
    local rangeIdent = string.sub(rangePrefix, 1, 2)
    
    if ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent] == nil then
      ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent] = MENU_COALITION:New(coalition.side.BLUE, "R" .. rangeIdent, ACTIVERANGES.menu.menuTop)
    end
    
    ACTIVERANGES.menu["rangeMenu_" .. rangePrefix] = MENU_COALITION:New(coalition.side.BLUE, rangePrefix, ACTIVERANGES.menu["rangeMenuSub_" .. rangeIdent])
    
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], activateRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], false )
   
    local samTemplate = "SAM_" .. rangePrefix
    
    if GROUP:FindByName(samTemplate) ~= nil then
      MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix .. " with SAM" , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], activateRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], true )
    end
   
    return ACTIVERANGES.menu["rangeMenu_" .. rangePrefix]
    
  end
  
  --- Spawn ACTIVE range groups.
  -- @function initActiveRange
  -- @param #table rangeTemplateGroup Target spawn template GROUP object
  -- @param #string refreshRange If false, turn off target AI and add menu option to activate the target
  function initActiveRange(rangeTemplateGroup, refreshRange)
  
    local rangeTemplate = rangeTemplateGroup.GroupName
  
    local activeRange = SPAWN:New(rangeTemplate)
  
    if refreshRange == false then -- turn off AI if initial
      activeRange:InitAIOnOff(false)
    end
    
    activeRange:OnSpawnGroup(
      function (spawnGroup)
        local rangeName = spawnGroup.GroupName
        local rangePrefix = string.sub(rangeName, 8, 12) 
        if refreshRange == false then
          addActiveRangeMenu(spawnGroup, rangePrefix)
        end
      end
      , refreshRange 
    )
  
      activeRange:Spawn()
      
      local rangeGroup = activeRange:GetLastAliveGroup()
      rangeGroup:OptionROE(ENUMS.ROE.WeaponHold)
      rangeGroup:OptionROTEvadeFire()
      rangeGroup:OptionAlarmStateGreen()
      rangeGroup:SetAIOnOff(false)
  
      return rangeGroup
  
    
  end
  
  local SetInitActiveRangeGroups = SET_GROUP:New():FilterPrefixes("ACTIVE_"):FilterOnce() -- create list of group objects with prefix "ACTIVE_"
  SetInitActiveRangeGroups:ForEachGroup(initActiveRange, false)
  
--- END ACTIVE RANGES
 
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
        MESSAGE:New("EC South is active with " .. activeThreat):ToAll()
        ECS.rIADS = SkynetIADS:create("ECSOUTH")
        ECS.rIADS:setUpdateInterval(5)
        ECS.rIADS:addEarlyWarningRadar("GCI2")
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
    MESSAGE:New("EC South "  .. activeThreat .." has been deactived."):ToAll()
  end    

end

function addEcsThreatMenu()

  for i, template in ipairs(ECS.templates) do
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. template.threatName, ECS.menuEscTop, activateEcsThreat, template.templateName, ECS.zoneEcs7769, template.threatName)
  end

end

addEcsThreatMenu()

--- END ELECTRONIC COMBAT SIMULATOR RANGE
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ACM/BFM SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- AI ACM/BFM
--
-- ZONES: if zones are MOOSE polygon zones, zone name in mission editor MUST be suffixed with ~ZONE_POLYGON
-- 

BFMACM = {
  menuAdded = {},
  menuF10 = {},
  zoneBfmAcmName = "COYOTEABC", -- The BFM/ACM Zone
  zonesNoSpawnName = { -- zones inside BFM/ACM zone within which adversaries may NOT be spawned.
      "zone_box",
  },
  adversary = {
    menu = { -- Adversary menu
      {template = "ADV_F4", menuText = "Adversary A-4"},
      {template = "ADV_MiG28", menuText = "Adversary MiG-28"},
      {template = "ADV_Su27", menuText = "Adversary MiG-23"},
      {template = "ADV_MiG23", menuText = "Adversary Su-27"},
      {template = "ADV_F16", menuText = "Adversary F-16"},
      {template = "ADV_F18", menuText = "Adversary F-18"},
    },
    range = {5, 10, 20}, -- ranges at which to spawn adversaries in nautical miles
    spawn = {} -- container for aversary spawn objects
  },
}

-- add event handler
BFMACM.eventHandler = EVENTHANDLER:New()
BFMACM.eventHandler:HandleEvent(EVENTS.PlayerEnterAircraft)
BFMACM.eventHandler:HandleEvent(EVENTS.PlayerLeaveUnit)

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

-- Add main BFMACM zone
 _zone = ( ZONE:FindByName(BFMACM.zoneBfmAcmName) and ZONE:FindByName(BFMACM.zoneBfmAcmName) or ZONE_POLYGON:FindByName(BFMACM.zoneBfmAcmName))
if _zone == nil then
  _msg = "[BFMACM] ERROR: BFM/ACM Zone: " .. tostring(BFMACM.zoneBfmAcmName) .. " not found!"
  BASE:E(_msg)
else
  BFMACM.zoneBfmAcm = _zone
  _msg = "[BFMACM] BFM/ACM Zone: " .. tostring(BFMACM.zoneBfmAcmName) .. " added."
  BASE:T(_msg)
end

-- Add spawn exclusion zone(s)
if BFMACM.zonesNoSpawnName then
  BFMACM.zonesNoSpawn = {}
  for i, zoneNoSpawnName in ipairs(BFMACM.zonesNoSpawnName) do
    _zone = (ZONE:FindByName(zoneNoSpawnName) and ZONE:FindByName(zoneNoSpawnName) or ZONE_POLYGON:FindByName(zoneNoSpawnName))
    if _zone == nil then
      _msg = "[BFMACM] ERROR: Exclusion zone: " .. tostring(zoneNoSpawnName) .. " not found!"
      BASE:E(_msg)
    else
      BFMACM.zonesNoSpawn[i] = _zone
      _msg = "[BFMACM] Exclusion zone: " .. tostring(zoneNoSpawnName) .. " added."
      BASE:T(_msg)
    end
  end
else
  BASE:T("[BFMACM] No exclusion zones defined")
end

-- Add spawn objects
for i, adversaryMenu in ipairs(BFMACM.adversary.menu) do
  _adv = GROUP:FindByName(adversaryMenu.template)
  if _adv then
    BFMACM.adversary.spawn[adversaryMenu.template] = SPAWN:New(adversaryMenu.template)
  else
    _msg = "[BFMACM] ERROR: spawn template: " .. tostring(adversaryMenu.template) .. " not found!" .. tostring(zoneNoSpawnName) .. " not found!"
    BASE:E(_msg)
  end
end

-- Spawn adversaries
function BFMACM.SpawnAdv(adv,qty,group,rng,unit)
  local playerName = (unit:GetPlayerName() and unit:GetPlayerName() or "Unknown") 
  local range = rng * 1852
  local hdg = unit:GetHeading()
  local pos = unit:GetPointVec2()
  local spawnPt = pos:Translate(range, hdg, true)
  local spawnVec3 = spawnPt:GetVec3()

  -- check player is in BFM ACM zone.
  local spawnAllowed = unit:IsInZone(BFMACM.zoneBfmAcm)
  local msgNoSpawn = " - Cannot spawn adversary aircraft if you are outside the BFM/ACM zone!"

  -- Check spawn location is not in an exclusion zone
  if spawnAllowed then
    if BFMACM.zonesNoSpawn then
      for i, zoneExclusion in ipairs(BFMACM.zonesNoSpawn) do
        spawnAllowed = not zoneExclusion:IsVec3InZone(spawnVec3)
      end
      msgNoSpawn = " - Cannot spawn adversary aircraft in an exclusion zone. Change course, or increase your range from the zone, and try again."
    end
  end

  -- Check spawn location is inside the BFM/ACM zone
  if spawnAllowed then
    spawnAllowed = BFMACM.zoneBfmAcm:IsVec3InZone(spawnVec3)
    msgNoSpawn = " - Cannot spawn adversary aircraft outside the BFM/ACM zone. Change course and try again."
  end

  -- Spawn the adversary, if not in an exclusion zone or outside the BFM/ACM zone.
  if spawnAllowed then
    BFMACM.adversary.spawn[adv]:InitGrouping(qty)
    :InitHeading(hdg + 180)
    :OnSpawnGroup(
      function ( SpawnGroup )
        local CheckAdversary = SCHEDULER:New( SpawnGroup, 
        function (CheckAdversary)
          if SpawnGroup then
            if SpawnGroup:IsNotInZone( BFMACM.zoneBfmAcm ) then
              MESSAGE:New("Adversary left BFM Zone and was removed!"):ToAll()
              SpawnGroup:Destroy()
              SpawnGroup = nil
            end
          end
        end,
        {}, 0, 5 )
      end
    )
    :SpawnFromVec3(spawnVec3)
    MESSAGE:New(playerName .. " has spawned Adversary."):ToGroup(group)
  else
    MESSAGE:New(playerName .. msgNoSpawn):ToGroup(group)
  end
end
  
function BFMACM:AddMenu(unitname)
  BASE:T("[BFMACM] AddMenu called.")
  local unit, playername = BFMACM:GetPlayerUnitAndName(unitname)
  if unit and playername then
    local group = unit:GetGroup()
    local gid = group:GetID()
    local uid = unit:GetID()
    if group and gid then
      -- only add menu once!
      if BFMACM.menuAdded[uid] == nil then
        -- add GROUP menu if not already present
        if BFMACM.menuF10[gid] == nil then
          BASE:T("[BFMACM] Adding menu for group: " .. group:GetName())
          BFMACM.menuF10[gid] = MENU_GROUP:New(group, "AI BFM/ACM")
        end
        if BFMACM.menuF10[gid][uid] == nil then
          -- add playername submenu
          BASE:T("[BFMACM] Add submenu for player: " .. playername)
          BFMACM.menuF10[gid][uid] = MENU_GROUP:New(group, playername, BFMACM.menuF10[gid])
          -- add adversary submenus and range selectors
          BASE:T("[BFMACM] Add submenus and range selectors for player: " .. playername)
          for iMenu, adversary in ipairs(BFMACM.adversary.menu) do
            -- Add adversary type menu
            BFMACM.menuF10[gid][uid][iMenu] = MENU_GROUP:New(group, adversary.menuText, BFMACM.menuF10[gid][uid])
            -- Add single or pair selection for adversary type
            BFMACM.menuF10[gid][uid][iMenu].single = MENU_GROUP:New(group, "Single", BFMACM.menuF10[gid][uid][iMenu])
            BFMACM.menuF10[gid][uid][iMenu].pair = MENU_GROUP:New(group, "Pair", BFMACM.menuF10[gid][uid][iMenu])
            -- select range at which to spawn adversary
            for iCommand, range in ipairs(BFMACM.adversary.range) do
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].single, BFMACM.SpawnAdv, adversary.template, 1, group, range, unit)
                MENU_GROUP_COMMAND:New(group, tostring(range) .. " nm", BFMACM.menuF10[gid][uid][iMenu].pair, BFMACM.SpawnAdv, adversary.template, 2, group, range, unit)
            end
          end
        end
        BFMACM.menuAdded[uid] = true
      end
    else
      BASE:T(string.format("[BFMACM] ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    BASE:T(string.format("[BFMACM] ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end
  
-- handler for PlayEnterAircraft event.
-- call function to add GROUP:UNIT menu.
function BFMACM.eventHandler:OnEventPlayerEnterAircraft(EventData)
  BASE:T("[BFMACM] PlayerEnterAircraft called.")
  local unitname = EventData.IniUnitName
  local unit, playername = BFMACM:GetPlayerUnitAndName(unitname)
  if unit and playername then
    BASE:T("[BFMACM] Player entered Aircraft: " .. playername)
    SCHEDULER:New(nil, BFMACM.AddMenu, {BFMACM, unitname},0.1)
  end
end

-- handler for PlayerLeaveUnit event.
-- remove GROUP:UNIT menu.
function BFMACM.eventHandler:OnEventPlayerLeaveUnit(EventData)
  local playername = EventData.IniPlayerName
  local unit = EventData.IniUnit
  local gid = EventData.IniGroup:GetID()
  local uid = EventData.IniUnit:GetID()
  BASE:T("[BFMACM] " .. playername .. " left unit:" .. unit:GetName() .. " UID: " .. uid)
  if gid and uid then
    if BFMACM.menuF10[gid] then
      BASE:T("[BFMACM] Removing menu for unit UID:" .. uid)
      BFMACM.menuF10[gid][uid]:Remove()
      BFMACM.menuF10[gid][uid] = nil
      BFMACM.menuAdded[uid] = nil
    end
  end
end

--- END ACMBFM SECTION
 
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
local BVRGCI = {
    Menu            = {},
    SubMenu         = {},
    Spawn           = {},
    headingDefault  = 150,
    Destroy         = false,
  }
   
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
                  local msgDestroy = "BVR adversary group " .. groupName .. " removed."
                  local msgLeftZone = "BVR adversary group " .. groupName .. " left zone and was removed."
                  SpawnGroup:Destroy()
                  SpawnGroup = nil
                  MESSAGE:New(BVRGCI.Destroy and msgDestroy or msgLeftZone):ToAll()
                end
              end
            end,
          {}, 0, 5 )
        end,
        Formation, typeName
      )
    spawnAdversary:SpawnFromVec3(spawnVec3)
    local _msg = "BVR Adversary group spawned."
    MESSAGE:New(_msg):ToAll()
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
 
env.info( '[JTF-1] *** JTF-1 MOOSE MISSION SCRIPT END ***' )
 
