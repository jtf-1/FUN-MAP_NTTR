env.info( '[JTF-1] *** MISSION FILE BUILD DATE: 2022-12-05T11:36:31.29Z ***') 
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
    rangeRadio = "377.8", -- default frequency for range radio comms
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

  function DEV_MENU:testLua() --check encoding
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

-- remove set object
setGroupGroundActive = nil

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
-- Use MISSIONSRS:SendRadio() to transmit on SRS
--
-- msgText        - [required] STRING. Text of message. Can be plain text or a MOOSE SOUNDTEXT obkect
-- msfFreqs       - [optional] STRING. frequency, or table of frequencies (without any spaces). Default freqs AND modulations will be applied if this is not specified.
-- msgModulations - [optional] STRING. modulation, or table of modulations (without any spaces) if multiple freqs passed. Ignored if msgFreqs is not defined. Default modulations will be applied if this is not specified
--


MISSIONSRS = {
  fileName = "ServerLocalSettings.lua",                           -- name of file containing local server settings
  LocalServerConfigPath = nil,                                    -- path to server srs settings. nil if file is in root of server's savedgames profile.
  LocalServerConfigFile = "LocalServerSettings.txt",              -- srs server settings file name
  defaultSrsPath = "C:/Program Files/DCS-SimpleRadio-Standalone", -- default path to SRS install directory if setting file is not avaialable "C:/Program Files/DCS-SimpleRadio-Standalone"
  defaultSrsPort = 5002,                                          -- default SRS port to use if settings file is not available
  defaultText = "No Message Defined!",                            -- default message if text is nil
  defaultFreqs = "243,251,327,377.8,30",                          -- transmit on guard, CTAF, NTTR TWR, NTTR BLACKJACK and 30FM as default frequencies
  defaultModulations = "AM,AM,AM,AM,FM",                          -- default modulation (count *must* match qty of freqs)
  defaultVol = "1.0",                                             -- default to full volume
  defaultName = "Server",                                         -- default to server as sender
  defaultCoalition = 0,                                           -- default to spectators
  defaultVec3 = nil,                                              -- point from which transmission originates
  defaultSpeed = 2,                                               -- speed at which message should be played
  defaultGender = "female",                                       -- default gender of sender
  defaultCulture = "en-US",                                       -- default culture of sender
  defaultVoice = "",                                              -- default voice to use
}

function MISSIONSRS:LoadSettings()
  local loadFile  = self.LocalServerConfigFile
  if UTILS.CheckFileExists(self.LocalServerConfigPath, self.LocalServerConfigFile) then
    local loadFile, serverSettings = UTILS.LoadFromFile(self.LocalServerConfigPath, self.LocalServerConfigFile)
    BASE:T({"[MISSIONSRS] Load Server Settings",{serverSettings}})
    if not loadFile then
      BASE:E(string.format("[MISSIONSRS] ERROR: Could not load %s", loadFile))
    else
      self.SRS_DIRECTORY = serverSettings[1] or self.defaultSrsPath
      self.SRS_PORT = serverSettings[2] or self.defaultSrsPort
      self:AddRadio()
      BASE:T({"[MISSIONSRS]",{self}})
    end
  else
    BASE:E(string.format("[MISSIONSRS] ERROR: Could not find %s", loadFile))
  end
end

function MISSIONSRS:AddRadio()
  self.Radio = MSRS:New(self.SRS_DIRECTORY, self.defaultFreqs, self.defaultModulations)
  self.Radio:SetPort(self.SRS_PORT)
  self.Radio:SetGender(self.defaultGender)
  self.Radio:SetCulture(self.defaultCulture)
  self.Radio.name = self.defaultName
end

function MISSIONSRS:SendRadio(msgText, msgFreqs, msgModulations)

  BASE:T({"[MISSIONSRS] SendRadio", {msgText}, {msgFreqs}, {msgModulations}})
  if msgFreqs then
    BASE:T("[MISSIONSRS] tx with freqs change.")
    if msgModulations then
      BASE:T("[MISSIONSRS] tx with mods change.")
    end
  end
  if msgText == (nil or "") then 
    msgText = self.defaultText
  end
  local text = msgText
  local tempFreqs = (msgFreqs or self.defaultFreqs)
  local tempModulations = (msgModulations or self.defaultModulations)
  if not msgText.ClassName then
    BASE:T("[MISSIONSRS] msgText NOT SoundText object.")
    text = SOUNDTEXT:New(msgText) -- convert msgText to SOundText object
  end
  self.Radio:SetFrequencies(tempFreqs)
  self.Radio:SetModulations(tempModulations)
  self.Radio:PlaySoundText(text)
  self.Radio:SetFrequencies(self.defaultFreqs) -- reset freqs to default
  self.Radio:SetModulations(self.defaultModulations) -- rest modulation to default

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
  {menuText = "Load DAY NTTR - NO GPS (1980)", missionFlagValue = 5},
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
      MENU_GROUP_COMMAND:New( adminGroup, "SRS Broadcast test", testMenu, MISSIONSRS.SendRadio, "All players, test broadcast over default radio.")
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

MISSIONTIMER = {
  durationHrs = 11, -- Mission run time in HOURS
  msgSchedule = {60, 30, 10, 5}, -- Schedule for mission restart warning messages. Time in minutes.
  msgWarning = {}, -- schedule container
  missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ), -- Message to trigger mission restart via jtf1-hooks
  restartDelay =  4, -- time in minutes to delay restart if active clients are present.
}

MISSIONTIMER.durationSecs = MISSIONTIMER.durationHrs * 3600 -- Mission run time in seconds

BASE:T({"[MISSIONTIMER]",{MISSIONTIMER}})

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MISSIONTIMER:AddSchedules()
  if self.msgSchedule ~= nil then
    for i, msgTime in ipairs(self.msgSchedule) do
      self.msgWarning[i] = SCHEDULER:New( nil, 
        function()
          BASE:T("[MISSIONTIMER] TIMER WARNING CALLED at " .. tostring(msgTime) .. " minutes remaining.")
          local msg = "All players, mission is scheduled to restart in  " .. msgTime .. " minutes!"
          if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
            MISSIONSRS:SendRadio(msg)
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
  if not self.clientList then
    self.clientList = SET_CLIENT:New()
    self.clientList:FilterActive()
    self.clientList:FilterStart()
  end
  if self.clientList:CountAlive() > 0 then
    local delayTime = self.restartDelay
    local msg  = "All players, mission will restart when no active clients are present. Next check will be in " .. tostring(delayTime) .." minutes." 
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg)
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
    MESSAGE:New(self.missionRestart):ToAll()
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
    menu = {},
    rangeRadio = "377.8",
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
        local msg = "All players, Target " .. rangePrefix .. " has been deactivated."
        if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
          MISSIONSRS:SendRadio(msg, ACTIVERANGES.rangeRadio)
        else -- otherwise, send in-game text message
          MESSAGE:New(msg):ToAll()
        end
        --MESSAGE:New("Target " .. rangePrefix .. " has been deactivated."):ToAll()
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
      MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, false)
      if GROUP:FindByName(samTemplate) ~= nil then
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " NO SAM" , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, true)
      else
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText , ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, ACTIVERANGES.menu["rangeMenu_" .. rangePrefix], withSam, true)
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
    spawn = {}, -- container for aversary spawn objects
    defaultRadio = "377.8",
  },
}

BFMACM.rangeRadio = (JTF1.rangeRadio and JTF1.rangeRadio or BFMACM.defaultRadio)

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
  local msgNoSpawn = ", Cannot spawn adversary aircraft if you are outside the BFM/ACM zone!"

  -- Check spawn location is not in an exclusion zone
  if spawnAllowed then
    if BFMACM.zonesNoSpawn then
      for i, zoneExclusion in ipairs(BFMACM.zonesNoSpawn) do
        spawnAllowed = not zoneExclusion:IsVec3InZone(spawnVec3)
      end
      msgNoSpawn = ", Cannot spawn adversary aircraft in an exclusion zone. Change course, or increase your range from the zone, and try again."
    end
  end

  -- Check spawn location is inside the BFM/ACM zone
  if spawnAllowed then
    spawnAllowed = BFMACM.zoneBfmAcm:IsVec3InZone(spawnVec3)
    msgNoSpawn = ", Cannot spawn adversary aircraft outside the BFM/ACM zone. Change course and try again."
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
              local msg = "All players, BFM Adversary left BFM Zone and was removed!"
              if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
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
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New(playerName .. " has spawned Adversary."):ToGroup(group)
  else
    local msg = playerName .. msgNoSpawn
    if MISSIONSRS.Radio then -- if MISSIONSRS radio object has been created, send message via default broadcast.
      MISSIONSRS:SendRadio(msg,BFMACM.rangeRadio)
    else -- otherwise, send in-game text message
      MESSAGE:New(msg):ToAll()
    end
    --MESSAGE:New(playerName .. msgNoSpawn):ToGroup(group)
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
    defaultRadio = "377.8",
  }
   
BVRGCI.rangeRadio = (JTF1.rangeRadio and JTF1.rangeRadio or BVRGCI.defaultRadio)

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
 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MARK SPAWN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Sourced from Virtual 57th. Minor refactoring of original script
--

BASE:T("[MARK_SPAWN] VERSION 0.12")

MARKSPAWN = {

  -- DEFAULT VALUES
  DEFAULT_BLUE_COUNTRY = 2, -- USA
  DEFAULT_RED_COUNTRY = 0, -- RUSSIA
  radioPresets = {},
  MLSpawnedGroups = {},
  MLDefaultAirAlt = 280, -- altitude in metres
  MLDefaultHdg = 000,
  MLDefaultSkill = "AVERAGE",
  MLDefaultDistance = 0,
  MLDefaultROE = "FREE",
  MLDefaultROT = "EVADE",
  MLDefaultFreq = 251,
  MLDefaultNum = 1,
  MLDefaultAirSpeed = 425,
  MLTgtArray = {},
    
  -- SPAWNABLE GROUP TYPES
  spawnTypes = { -- types available for spawning
    { spawn = "BVR_MIG23",  txt = "MIG23" ,   category = "air",     type = "CAP" },
    { spawn = "BVR_SU25",   txt = "SU25" ,    category = "air",     type = "CAP" },
    { spawn = "BVR_MIG29A", txt = "MIG29" ,   category = "air",     type = "CAP" },
    { spawn = "BVR_SU27",   txt = "SU27" ,    category = "air",     type = "CAP" },
    { spawn = "BVR_F4",     txt = "F4" ,      category = "air",     type = "CAP" },
    { spawn = "SA6",    txt = "SA6BTY" ,  category = "ground",  type = "SAM" },
    { spawn = "SA8",    txt = "SA8BTY" ,  category = "ground",  type = "SAM" },
    { spawn = "SA10",   txt = "SA10BTY" , category = "ground",  type = "SAM" },
    { spawn = "SA11",   txt = "SA11BTY" , category = "ground",  type = "SAM" },
    { spawn = "SA15",   txt = "SA15BTY" , category = "ground",  type = "SAM" },
  },
}

--MARKSPAWN.markEvent = EVENTHANDLER:New()
--MARKSPAWN.markEvent:HandleEvent(EVENTS.MarkChange)

local DEFAULT_BLUE_COUNTRY = 2 --The USA
local DEFAULT_RED_COUNTRY = 0 -- RUSSIA
  
local spawnerOptions = {

  { spawn = SPAWN:New(  "BVR_MIG23"  ), txt = "MIG23" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_SU25"  ), txt = "SU25" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_MIG29A"  ), txt = "MIG29" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_SU27"  ), txt = "SU27" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_F4"  ), txt = "F4" , category = "air", type = "CAP" },

  { spawn = SPAWN:New(  "SA6"  ), txt = "SA6" , category = "ground", type = "SAM" },
  { spawn = SPAWN:New(  "SA8"  ), txt = "SA8" , category = "ground", type = "SAM" },
  { spawn = SPAWN:New(  "SA10"  ), txt = "SA10" , category = "ground", type = "SAM" },
  { spawn = SPAWN:New(  "SA11"  ), txt = "SA11" , category = "ground", type = "SAM" },
  { spawn = SPAWN:New(  "SA15"  ), txt = "SA15" , category = "ground", type = "SAM" },
}

local radioPresets = {}

local MLSpawnedGroups = {}

local MLAirSpawn
local MLGroundSpawn
local MLNavalSpawn
local MLSetROE
local MLSetTask
local MLSetAlarm
local MLSideComparator
local MLConvertMarkPos
local parseMark
local MLRadioPreset
local MLFindWaypoints
local MLListSpawnOptions
local MLDeleteGroup
local MLWxReport
local MLSkillCheck
local split
local comparator
local deleteDeterminator
local magVarDeterminator
local MLSetROT
local MLRemoveMark
--local MLRadioSpawn
local MLSongParser
--local MLRadioStatic = STATIC:FindByName("PIRATERADIO","CUCKS")
--local MLRadio = RADIO:New(MLRadioStatic)
local _Heading
local MLTgtArray = {}
local MLCreateTGT
local MLPopulateTGT
local MLReturnTGT
local MLTgtArrayAdd
local MLTgtArrayRemove
local MLDefaultAirAlt = 280 -- altitude in metres
local MLDefaultHdg = 000
local MLDefaultSkill = "AVERAGE"
local MLDefaultDistance = 0
local MLDefaultROE = "FREE"
local MLDefaultROT = "EVADE"
local MLDefaultFreq = 251
local MLDefaultNum = 1
local MLDefaultAirSpeed = 425
local MLDefaultAlert = "RED"

-----------------
-- MARK POINT EVENT HANDLER
-----------------

local markEvent = EVENTHANDLER:New()
markEvent:HandleEvent(EVENTS.MarkChange)

-- IF MARK IS A "CMD", SEND MARK DATA TO PARSER
function markEvent:OnEventMarkChange( EventData )
  BASE:T("[MARK_SPAWN] MARK CHANGE EVENT")
  local text = EventData.text
  local x, _ = string.find(text, "CMD")
  if(x ~= nil) then
    parseMark(EventData)
    MLRemoveMark(EventData.idx)
  else
    return
  end
end

 scheduler, schedulerID = SCHEDULER:New( nil,
   function(foo)
    BASE:T("[MARK_SPAWN] scheduler:" .. UTILS.OneLineSerialize(markEvent))
   end,
 {}, 300, 300)

-----------------
-- CMD PARSER
-----------------

function parseMark (mark)

  BASE:T("[MARK_SPAWN] mark: " .. UTILS.OneLineSerialize(mark))

  local cmdOption = false
  local text = mark.text
  local pos = mark.pos
  
  -----------------
  -- CMD AIR GROUP
  -----------------

  --check if there is an air spawn command, if so run through the spawn logic
  local i, _, spawnValue = string.find(text, "ASPAWN: (%w+)")
  if(i ~= nil) then
    cmdOption = true
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("air", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, altitude = string.find(text, "ALT: (%d+)")
      local _, _, task = string.find(text,"TASK: (%w+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WPS = string.find(text, "WPS: {(.*)}")
      local _, _, freq = string.find(text, "FREQ: (%d[%d.]+)")
      local _, _, num = string.find(text, "NUM: (%d+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")
      local _, _, base = string.find(text, "BASE: (%w+)")
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, ROT = string.find(text, "ROT: (%w+)")

      local spawnTable = {
        type = spawnValue,
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

        BASE:T("[MARK_SPAWN] spawnTable: " .. UTILS.OneLineSerialize(spawnTable))
      MLAirSpawn(spawnTable)
    end
  end
  
  -----------------
  -- CMD GROUND GROUP
  -----------------

  local j, _, spawnValue = string.find(text, "GSPAWN: (%w+)")
  if(j ~= nil) then
    cmdOption = true
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("ground", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WP = string.find(text, "WPS: {(.*)}")
      local _, _, alert = string.find(text, "ALERT: (%w+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")  
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, tgtName = string.find(text, "TGT: (%w+)")

      local spawnTable = {
        type = spawnValue,
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

        BASE:T("[SPAWN_MARK] GSPAWN: " .. UTILS.OneLineSerialize(spawnTable))
      MLGroundSpawn(spawnTable)
    end
  end
    
  -----------------
  -- CMD RADIO
  -----------------

  local k, _, spawnValue = string.find(text, "RADIO: (%w+)")
  if(k ~= nil) then
    cmdOption = true
    BASE:T("[MARK_SPAWN] SpawnValue: " .. spawnValue)
    BASE:T("[MARK_SPAWN] Other Text: " .. k)
    local _, _, freq = string.find(text, "FREQ: (%d+)")
    local _, _, band = string.find(text,"BAND: (%w+)")
    local _, _, power = string.find(text,"PWR: (%d+)")
    
    local spawnTable = {
      song = spawnValue,
      freq = freq,
      band = band, 
      power = power, 
    }

    BASE:T("[MARK_SPAWN] RADIO: " .. UTILS.OneLineSerialize(spawnTable))
    --MLRadioSpawn(spawnTable)
  end
  
  -----------------
  -- CMD NAVY GROUP
  -----------------

  --spawn a naval group
  local l, _, spawnValue = string.find(text, "NSPAWN: (%w+)")
  if(l ~= nil) then
    cmdOption = true
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("naval", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WP = string.find(text, "WPS: {(.*)}")
      local _, _, alert = string.find(text, "ALERT: (%w+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")  
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, tgtName = string.find(text, "TGT: (%w+)")
      
      local spawnTable = {
        type = spawnValue,
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

      BASE:T("[MARK_SPAWN] NSPAWN: " .. UTILS.OneLineSerialize(spawnTable))
      MLNavalSpawn(spawnTable)
    end
  end
  
  -----------------
  -- CMD DELETE GROUP
  -----------------

  --Delete one or more groups
  local l, _, deleteCMD = string.find(text, "DELETE: (%w+)")
  if(l ~= nil) then
    cmdOption = true
    local _, _, category = string.find(text, "CAT (%w+)")
    local _, _, side = string.find(text,"SIDE (%w+)")
    local _, _, radius = string.find(text,"RAD (%d+)")
    local _, _, template = string.find(text,"TYPE (%w+)")
    local _, _, groupName = string.find(text, "GROUP (.+)")
      
      local spawnTable = {
          cmd = deleteCMD,
          category = category,
          side = side,
          radius = radius,
          template = template,
          groupName = groupName,
        }
    MLDeleteGroup(spawnTable, mark)
  end

  -----------------
  -- CMD WX REPORT
  -----------------

  local m, _, repoString = string.find(text, "WXREPORT: (.*)")
  if(m ~= nil) then
    cmdOption = true
    MLWxReport(repoString, mark)
  end

  if not cmdOption then
    BASE:E("[MARK_SPAWN] ERROR! CMD not found.")
  end

end
  
-----------------
-- SPAWN AIR GROUP(S)
-----------------

function MLAirSpawn(SpawnTable)
  local type = SpawnTable.type
  local heading = tonumber(SpawnTable.heading) or MLDefaultHdg
  local altitude = tonumber(SpawnTable.altitude) or MLDefaultAirAlt
  altitude = UTILS.FeetToMeters(altitude * 100)
  local task = SpawnTable.task or "NOTHING"
  local skill = MLSkillCheck(SpawnTable.skill) or MLDefaultSkill
  local distance = tonumber(SpawnTable.distance) or MLDefaultDistance
  local ROE = SpawnTable.roe or MLDefaultROE
  local ROT = SpawnTable.rot or MLDefaultROT
  local freq = tonumber(SpawnTable.freq) or MLDefaultFreq
  local num = tonumber(SpawnTable.num) or MLDefaultNum
  local speed = tonumber(SpawnTable.speed) or MLDefaultAirSpeed
  local form = SpawnTable.formation or nil
  local base = SpawnTable.base or nil
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos):SetAltitude(altitude,true)
  local spawner = comparator(type)

  if(spawner == nil) then
    return
  end

  local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
  local waypointNameString = SpawnTable.WP or nil
  
  -- switch country/coalition if desired
  local coal, country
  if(SpawnTable.side) then
    coal, country = MLSideComparator(SpawnTable.side, template)
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end
  local group
  
  -- spawn the group
  if(base) then
    local airbase
    if(base == "NEAREST") then 
      BASE:T("[MARK_SPAWN] learn 2 spell, scrub")
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
    BASE:T("[MARK_SPAWN] ASPAWN: " .. coal .. " " .. country)
    group = spawner:InitGrouping(num):InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
    _groupName = group.GroupName
    BASE:T("[MARK_SPAWN] ASPAWN: " .. _groupName)
  end
  
  MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "air", side = coal}
  -- set ROE
  MLSetROE(ROE,group)
  -- set ROT
  MLSetROT(ROT,group)
  --if no distance, then we orbit
  if(waypointNameString) then
    local waypointCoords = MLFindWaypoints(waypointNameString)
    if(#waypointCoords > 0) then
      BASE:T('[MARK_SPAWN] MORE WAYPOINTS')
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
    BASE:T("[MARK_SPAWN] We Fucked Up")
  end
  local taskTable = {}
  if(task ~= "NOTHING") then
    taskTable = MLSetTask(task,group)
    group:PushTask ( group:TaskCombo( MLSetTask(task,group) ) , 3 )
  end
  --set group frequency
  if(freq) then
    if(freq <= 20) then
      freq = MLRadioPreset(freq)
    end
    BASE:T("[MARK_SPAWN] freq:".. freq)
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

function MLGroundSpawn(SpawnTable)
  local type = SpawnTable.type
  local heading = tonumber(SpawnTable.heading) or 000
  local task = SpawnTable.task or "NOTHING"
  local skill = MLSkillCheck(SpawnTable.skill) or "AVERAGE"
  local distance = tonumber(SpawnTable.distance) or 0
  local ROE = SpawnTable.roe or "FREE"
  local freq = tonumber(SpawnTable.freq) or 251
  local speed = tonumber(SpawnTable.speed) or 21
  local form = SpawnTable.formation or nil
  local alert = SpawnTable.alert or MLDefaultAlert
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  --local tgt = nil
  local spawner = comparator(type)
  --local tgt = MLCreateTGT(SpawnTable.tgt,SpawnTable.pos)or nil

  if(spawner == nil) then
    BASE:E("[MARK_SPAWN] ERROR! spawner not found in spawnOptions.")
    return
  end

  local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
  local waypointNameString = SpawnTable.WP or nil
  
  --local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  local coal, country

  if(SpawnTable.side) then
    coal, country = MLSideComparator(SpawnTable.side, template)
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end

  
  local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):SpawnFromVec3(spawnCoord:GetVec3())

  local _group = group.GroupName
  BASE:T("[MARK_SPAWN] GSPAWN: " .. _group)
  
  MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "ground", side = coal}
  
  MLSetROE(ROE,group)
  MLSetAlarm(alert,group)
  -- add waypoints
  --if no distance, then we orbit
  if(waypointNameString) then
    local waypointCoords = MLFindWaypoints(waypointNameString)
    BASE:T('MORE WAYPOINTS')
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

function MLNavalSpawn(SpawnTable)
  local type = SpawnTable.type
  local heading = tonumber(SpawnTable.heading) or 000
  local task = SpawnTable.task or "NOTHING"
  local skill = MLSkillCheck(SpawnTable.skill) or "AVERAGE"
  local distance = tonumber(SpawnTable.distance) or 0
  local ROE = SpawnTable.roe or "FREE"
  local freq = tonumber(SpawnTable.freq) or 251
  local speed = tonumber(SpawnTable.speed) or 30
  local form = SpawnTable.formation or nil
  local alert = SpawnTable.alert or "AUTO"
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  local spawner = comparator(type)
  local tgt = nil
  --local tgt = MLCreateTGT(SpawnTable.tgt,SpawnTable.pos) or nil
  if(spawner == nil) then
    return
  end
  local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
  local waypointNameString = SpawnTable.WP or nil
  
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  local coal, country
  if(SpawnTable.side) then
    coal, country = MLSideComparator(SpawnTable.side, template)
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end

  local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
  MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "naval", side = coal}

  MLSetROE(ROE,group)
  --MLSetAlarm(alert,group)
  -- LETS DO WAYPOINTS YE JAMMY FOOKERS!
  --if no distance, then we orbit
  if(waypointNameString) then
    local waypointCoords = MLFindWaypoints(waypointNameString)
    BASE:T('MORE WAYPOINTS')
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

function MLDeleteGroup(spawnTable,mark)

  local deleteCMD = spawnTable.cmd:upper()
  
  BASE:T("[MARK_SPAWN] DELETE:" .. deleteCMD)

  
  local coal = spawnTable.side or "RED"
  local type = spawnTable.category or "ALL"

  type = type:upper()

  local radius =  spawnTable.radius or 5
  radius = UTILS.NMToMeters(radius)

  local template = spawnTable.template or nil

  if template then
    template = template:upper()
  end
  
  if(coal:upper() == "RED") then 
    coal = 1 else coal = 2 
  end
  
  BASE:T("[MARK_SPAWN] DELETE OPTIONS CMD: " .. deleteCMD .. " SIDE: " .. coal .. " Type: " .. type .. " Radius: " .. radius)
  
  if(deleteCMD == "GROUP") then
    BASE:T("[MARK_SPAWN] DELETE GROUP")
    local groupName = spawnTable.groupName --string.find(deleteCMD, "NAME: (%w+)")
    BASE:T("[MARK_SPAWN] groupName: " .. groupName)
    local victim = GROUP:FindByName(groupName) or nil
    if victim then
      victim:Destroy(false)
    else
      BASE:T("[MARK_SPAWN] Delete groupName not found!")
    end
  
  elseif(deleteCMD == "AREA") then
    BASE:T("[MARK_SPAWN] Doing Radius Stuff")
    local deleteZone = ZONE_RADIUS:New("DeleteZone",COORDINATE:NewFromVec3(mark.pos):GetVec2(),radius)
    BASE:T("[MARK_SPAWN] Marker Pos: " .. UTILS.OneLineSerialize(mark.pos) .. " Zone Pos: " .. UTILS.OneLineSerialize(deleteZone:GetVec2()) .. "Radius: " .. deleteZone:GetRadius())
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() then 
        local groupPos = entry.group:GetVec2()
        local zoneVec2 = deleteZone:GetVec2()
        local isThere = ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5 <= tonumber(deleteZone:GetRadius())
        BASE:T("[MARK_SPAWN] BREASTS: " .. ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5)
        if(isThere) then
          BASE:T("[MARK_SPAWN] Group in zone")
          if(type and (entry.category:upper() == type:upper() or type:upper() == "ALL")) then
          BASE:T("[MARK_SPAWN] Type correct")
          BASE:T("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. entry.side)
            if(coal and (entry.side == coal)) then
              BASE:T("[MARK_SPAWN] Side correct")
              local victim = entry.group
              victim:Destroy(false)
              MLSpawnedGroups[idx] = nil
            end
          end
        else
          BASE:T("[MARK_SPAWN] Group out of Zone")
        end
      else
        BASE:T("[MARK_SPAWN] Group omae wa mo shindeiru")
        MLSpawnedGroups[idx] = nil
      end
    end
  elseif(deleteCMD == "NEAREST") then
    BASE:T("[MARK_SPAWN] Close Stuff")
  local minDistance = -1
  local closest = 1
  local markPos = COORDINATE:NewFromVec3(mark.pos):GetVec2()
  if(MLSpawnedGroups[1].group:IsAlive()) then
    local groupPos = MLSpawnedGroups[1].group:GetVec2()
  minDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5
  for idx, entry in pairs (MLSpawnedGroups) do
        if entry.group:IsAlive() then 
          local groupPos = entry.group:GetVec2()
          local currentDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5
          if(currentDistance < minDistance) then
      minDistance = currentDistance
      closest = idx
    end
        else
          BASE:T("[MARK_SPAWN] Group omae wa mo shindeiru")
          MLSpawnedGroups[idx] = nil
        end
      end
  local closestEntry = MLSpawnedGroups[closest]
  if(type and (closestEntry.category:upper() == type:upper() or type:upper() == "ALL")) then
    BASE:T("[MARK_SPAWN] Type correct")
    BASE:T("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. closestEntry.side)
    if(coal and (closestEntry.side == coal)) then
      BASE:T("[MARK_SPAWN] Side correct")
    local victim = closestEntry.group
    victim:Destroy(false)
    MLSpawnedGroups[closest] = nil
      end
  end
  end
  elseif(deleteCMD == "KIND") then
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() and template then 
    if(entry.template == template) then
      if(type and (entry.category:upper() == type:upper() or type:upper() == "ALL")) then
        BASE:T("[MARK_SPAWN] Type correct")
        BASE:T("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. entry.side)
        if(coal and (entry.side == coal)) then
          BASE:T("[MARK_SPAWN] Side correct")
        local victim = entry.group
        victim:Destroy(false)
        MLSpawnedGroups[idx] = nil
          end
    end
        end
      else
        BASE:T("[MARK_SPAWN] Group omae wa mo shindeiru")
        MLSpawnedGroups[idx] = nil
  end
    end
  elseif(deleteCMD == "ALL") then
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() then
        BASE:T("[MARK_SPAWN] Side correct")
        local victim = entry.group
        victim:Destroy(false)
        MLSpawnedGroups[idx] = nil
      else
        MLSpawnedGroups[idx] = nil
      end
    end
  end
end

-----------------
-- WX REPORT
-----------------

function MLWxReport (repoString, mark)
  local qfe = false
  local metric = false
  local options = split(repoString, ",")
  BASE:T(UTILS.OneLineSerialize(options))
  for idx, option in pairs (options) do
    option = option:gsub("%s+", "")
    BASE:T(option)
    if(option:upper() == "METRIC") then
      metric = true
    elseif(option:upper() == "QFE") then
      qfe = true
    end
  end
  
  local wxPos = COORDINATE:NewFromVec3(MLConvertMarkPos(mark.pos))
  local heading, windSpeedMPS = wxPos:GetWind(wxPos:GetLandHeight())
  heading = _Heading(heading + 180)
  local windSpeedKnots = UTILS.MpsToKnots(windSpeedMPS)
  local temperature = wxPos:GetTemperature()
  
  local pressure_hPa,pressure_inHg
  if(qfe) then
    pressure_hPa = wxPos:GetPressure(wxPos:GetLandHeight())
  else
    pressure_hPa = wxPos:GetPressure(0)
  end
  pressure_inHg = pressure_hPa * 0.0295299830714
  BASE:T("[MARK_SPAWN] " .. pressure_hPa .. ", " .. pressure_inHg)
  
  local coal
  if(mark.initiator) then
    coal = UNIT:Find(mark.initiator):GetGroup():GetCoalition()
  else
    coal = mark.coalition
  end

  local msg = ""
  if(metric) then
    msg = msg .. string.format("Wind is from %3d Degrees at %3d Mps\n",windSpeedMPS,heading)
    if(qfe) then
      msg = msg .. string.format("QFE is %4.2f hPa\n", pressure_hPa)
    else
      msg = msg .. string.format("QNH is %4.2f hPa\n", pressure_hPa)
    end
  else
    msg = msg .. string.format("Wind is from %3d Degrees at %3d Knots\n",windSpeedKnots,heading)
    if(qfe) then
      msg = msg .. string.format("QFE is %4.2f inHg\n", pressure_inHg)
    else
      msg = msg .. string.format("QNH is %4.2f inHg\n", pressure_inHg)
    end
  end
  msg = msg .. string.format("Temperature is %3d Degrees C", temperature)
  wxPos:MarkToCoalition(msg,coal,false,nil)
end

-----------------
-- REMOVE CMD MARK POINT
-----------------

function MLRemoveMark (markId)
  local allMarks = world.getMarkPanels()
  for idx, mark in pairs(allMarks) do
    if markId == mark.idx then
      trigger.action.removeMark(markId)
      allMarks[idx] = nil
      return
    end
  end
end

-- function MLRadioSpawn(SpawnTable)
--   local song = SpawnTable.song
--   local freq = tonumber(SpawnTable.freq) or 251

--   local band = SpawnTable.band or "AM"
--   if(band == "FM") then
--     band = 1
--   else
--     band = 0
--   end
--   local power = tonumber(SpawnTable.power) or 1200
--   local loop = SpawnTable.loop

--   BASE:T(freq)
--   BASE:T(band)
--   BASE:T(power)

--   local radioPositionable = SpawnTable.group
--   if(radioPositionable) then

--     local pirateRadio = RADIO:New(radioPositionable)
--     pirateRadio:NewGenericTransmission(song,freq,band,power,false)
--     pirateRadio:Broadcast()
--     BASE:T("[MARK_SPAWN] boobs")
--   else
--     MLRadio:NewGenericTransmission(song,freq,band,power,false)
--     MLRadio:Broadcast()
--     BASE:T("[MARK_SPAWN] tatas")
--   end
  

-- end
  
function comparator (type)
  for idx, val in pairs(spawnerOptions) do
    if string.upper(type) == string.upper(val.txt) then
      BASE:T("[MARK_SPAWN] Type: " .. val.type)
      BASE:T("[MARK_SPAWN] Value: " .. val.txt)
      return val.spawn
    end
  end
  return nil
end

function MLSetROE(ROEString, group)
  local text = string.upper(ROEString)
  if(text == "FREE") then 
    group:OptionROEWeaponFree()
  elseif (text == "RETURN") then
    group:OptionROEReturnFire()
  elseif (text == "HOLD") then
    group:OptionROEHoldFire()
  end
end
  
function MLSetROT(ROTString, group)
  local text = string.upper(ROTString)
  if(text == "EVADE") then
    group:OptionROTEvadeFire()
  elseif (text == "PASSIVE") then
    group:OptionROTPassiveDefense()
  elseif (text == "NONE") then
    group:OptionROTNoReaction()
  end
end
  
function MLSetAlarm(alarmString, group)
  local text = string.upper(alarmString)
  if(text == "GREEN") then 
    group:OptionAlarmStateGreen()
  elseif (text == "RED") then
    group:OptionAlarmStateRed()
  elseif (text == "AUTO") then
    group:OptionAlarmStateAuto()
  end
end

function MLSetTask(TaskString, group)
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
  
  
function MLSideComparator (side, template)
  local coal
  local country = template:GetCountry()
  if(side == "BLUE") then
    coal = coalition.side.BLUE
    if(coal ~= template:GetCoalition()) then
      country = DEFAULT_BLUE_COUNTRY
    end
  elseif(side == "RED") then
    coal =  coalition.side.RED
    if(coal ~= template:GetCoalition()) then
      country = DEFAULT_RED_COUNTRY
    end
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end
  
  BASE:T(coal .. " " .. country)
  return coal, country
end
  
function MLRadioPreset (channel)
  return radioPresets[channel]
end
  
function MLConvertMarkPos (pos)
  local newPos = UTILS.DeepCopy(pos)
  local zVal = pos.x
  local xVal = pos.z
  newPos.z = zVal
  newPos.x = xVal
  return newPos
end
  
function MLFindWaypoints(waypointNameList)
  BASE:T("[MARK_SPAWN] WAYPOINTS MODE TURN ON")
  local waypointNames={}
  local waypointCoords = {}
  --waypoints:gsub("%w*",function(name) table.insert(waypointNames,name) end)
  --for k, v in waypointNameList:gmatch("(%w*)") do
  --  table.insert(waypointNames,k)
  --end
  
  waypointNames = split(waypointNameList,",")
  local allMarks = world.getMarkPanels()
  for idx, name in pairs(waypointNames) do
    for idy, mark in pairs(allMarks) do
      BASE:T("[MARK_SPAWN] name: " .. name)
      BASE:T("[MARK_SPAWN] mark: " .. mark.text)
      if string.upper(name) == string.upper(mark.text) then
        waypointCoords[#waypointCoords + 1] = COORDINATE:NewFromVec3(mark.pos)
        break
      end
    end
  end
  return waypointCoords
end
  
function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end
  
function MLListSpawnOptions(category, mark)
  local messageString = ""
  for idx, value in pairs(spawnerOptions) do
    --list name, role, maybe default coalition
    if(category:upper() == value.category:upper()) then
      local name = value.txt
      local role = value.type
      local defaultCoalition = GROUP:FindByName( value.spawn.SpawnTemplatePrefix ):GetCoalition()
      local coal
      if(defaultCoalition == 1) then coal = "Red" elseif defaultCoalition == 2 then coal = "Blue" else coal = "How the fuck did you make a neutral?" end
      local line = "Type: " .. name .. ", Role: " .. role .. ", Coalition: " .. coal .. "\n"
      messageString = messageString .. line 
    end
  end
  BASE:T("[MARK_SPAWN] OPTIONS: " .. messageString)
  local DCSUnit = mark.initiator
  if(DCSUnit) then
    --local group = unit:GetGroup()
    local unit = UNIT:Find(DCSUnit)
    local group = unit:GetGroup()
    MESSAGE:New(messageString,30):ToGroup(group)
  else
    local coal = mark.coalition
    BASE:T(coal)
    MESSAGE:New(messageString,30):ToCoalition(coal)
  end
end

--stolen from moose, cred to them
function _Heading(course)
  local h
  if course<=180 then
    h=math.rad(course)
  else
    h=-math.rad(360-course)
  end
  return h 
end
  
function MLSkillCheck(skill)
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
  
--[[ 

function deleteDeterminator(stringCompare, considerCoal, entry)
  if(stringCompare) then
    if(considerCoal) then
      if(considerCoal == entry.group:GetCoalition()) then
        --BASE:T("[MARK_SPAWN] string/coal compare pass")
        return true
      else
        --BASE:T("[MARK_SPAWN] Coal compare fail")
        return false
      end
    else
      --BASE:T("[MARK_SPAWN] String Compare, no coalition")
      return true
    end
  else
    -- BASE:T("[MARK_SPAWN] String Compare Fail")
    return false  
  end
end
  
function magVarDeterminator()
  local magVar = 0
  local theater = env.mission.theatre
  if(theater == "Caucasus") then
    --is Georgia
    magVar = -6
  elseif(theater == "Nevada") then
    --is Nevada
    magVar = -12
  elseif(theater == "Normandy") then
    --is Normandy
    magVar = 2
  elseif(theater == "PersianGulf") then
    --is Persian Gulf
    magVar = -2
  else
    magVar = 0
  end
  return magVar
end
  
function MLCreateTGT(tgtName,pos,radius)
  local tgt = {}
  tgt.name = tgtName
  tgt.pos = pos
  tgt.radius = radius or 100
  tgt.zone = ZONE_RADIUS:New( tgtName .. "Zone", COORDINATE:NewFromVec3(SpawnTable.pos):GetVec2(), tgt.radius )
  tgt.units = MLPopulateTGT(tgt)
  MLTgtArrayAdd(tgt)
end
  
function MLPopulateTGT(tgt)
  local zone = tgt.zone
  local curratedUnits
  zone:scan(1)
  local units = zone:GetScannedUnits()
  BASE:T(UTILS.OneLineSerialize(units))
  for idx, unit in pairs(units) do
    local unitCategory = unit:GetDCSObject():GetCategory()
    if(unitCategory == "UNIT") then
      local unitSensors = unit:GetDCSObject():getSensors()
      local hasRadar = false
      for idx, sensor in pairs(unitSensors) do
        if(sensor.type == 1) then
          hasRadar = true
        end
      end
      if(hasRadar and unit:IsAlive()) then
        curratedUnits:insert({unit = unit, radarUnit = true})
      end
    elseif(unitCategory == "FORTIFICATION" and unit:IsAlive()) then
      curratedUnits:insert({unit = unit, structure = true})
    end
  end
    
  return curratedUnits
end
  
function MLReturnTGT(tgt)
  
end
  
function MLTgtArrayAdd(tgt)
  MLTgtArray:insert(tgt)
  if(#MLTgtArray > 5) then
    table.remove(MLTgtArray, 1)
  end
end
  
function MLTgtArrayRemove(tgt)

end

s = "MLCMD SPAWN: MIG27, ALT: 180, HDG: 180, TASK: CAP, SKILL: GOOD"
_, _, value, value2 , value3 = string.find(s, "SPAWN:%s(%w*)")
print(value, value2, value3)
_, _, value = string.find(s, "HDG: (%d+)")
print(value)

--  ]]

--- END MARK SPAWN
 
env.info( '[JTF-1] *** JTF-1 MOOSE MISSION SCRIPT END ***' )
 