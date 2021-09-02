env.info( '*** JTF-1 NTTR Fun Map MOOSE script ***' )
env.info( '*** JTF-1 MOOSE MISSION SCRIPT START ***' )

--- check mission admin flag state
-- if flag is true, mission will use assert(loadfile) to load mission lua file
devState = trigger.misc.getUserFlag(8888)
if devState then
  env.warning('*** JTF-1 - DEV flag is ON! ***')
else
  env.info('*** JTF-1 - DEV flag is OFF. ***')
end

--- activate admin menu option in admin slots if true
local JtfAdmin = true 

--- remove default MOOSE player menu
_SETTINGS:SetPlayerMenuOff()

--- Name of client unit used for admin control
local adminUnitName = "XX_ADMIN"

--- Dynamic list of all clients
local SetClient = SET_CLIENT:New():FilterStart()

--- debug on/off
BASE:TraceOnOff(false) 
if BASE:IsTrace() then
  BASE:TraceLevel(1)
  --BASE:TraceAll(true)
  BASE:TraceClass("setGroupGroundActive")
end

--- Disable AI for ground targets and FAC
local setGroupGroundActive = SET_GROUP:New():FilterActive():FilterCategoryGround():FilterOnce()
  setGroupGroundActive:ForEachGroup(
    function(activeGroup)
      activeGroup:SetAIOff()
    end
  )

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSION EVENT HANDLERS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local MissionEventHandler = EVENTHANDLER:New() -- new eventhandler object
MissionEventHandler:HandleEvent(EVENTS.Birth) -- subscribe to BIRTH event

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned.
-- @param #string unitName Name of the player unit.
-- @return #Wrapper.Unit unit object occupied by player.
-- @return #string Name of the player.
-- @return nil If player does not exist.
function GetPlayerUnitAndName(unitName)
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

--- OnBirth event handler for all spawned units.
-- @param #MissionEventHandler self.
-- @param Core.Event#EVENTDATA EventData Data for unit birth event.
function MissionEventHandler:OnEventBirth(EventData)
  local unitName = EventData.IniUnitName
  local unit, playername = GetPlayerUnitAndName(unitName)
  if unit and playername then -- unit is occupied by a client
    --- add missile trainer menu
    SCHEDULER:New(nil, MissileTrainer.AddMenu, {MissileTrainer,unit,unitName}, 0.1) -- delay MissileTrainer.AddMenu() call to ensure client has properly entered unit
    --- if player is in an admin slot, add mission restart menu 
    if unitName == adminUnitName then 
      SCHEDULER:New(nil, BuildAdminMenu, {unit}, 0.1) -- delay BuildAdminMenu() call to ensure client has properly entered unit
      --BuildAdminMenu(unit)
    end
  end
end

--END MISSION EVENT HANDLERS

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN SUPPORT AIRCRAFT SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- define table of respawning support aircraft ---
TableSpawnSupport = { -- {spawnobjectname, spawnzone, callsignName, callsignNumber}
  {spawnobject = "AR230V_KC-135_01", spawnzone = ZONE:New("AR230V"), callsignName = 2, callsignNumber = 1},
  {spawnobject = "AR230V_KC-130_01", spawnzone = ZONE:New("AR230V"), callsignName = 2, callsignNumber = 3},
  {spawnobject = "AR231V_KC-135_01", spawnzone = ZONE:New("AR231V"), callsignName = 2, callSignNumber = 2},
  {spawnobject = "AR635_KC-135_01", spawnzone = ZONE:New("AR635"), callsignName = 1, callsignNumber = 2},
  {spawnobject = "AR625_KC-135_01", spawnzone = ZONE:New("AR625"), callsignName = 1, callsignNumber = 3},
  {spawnobject = "AR641A_KC-135_01", spawnzone = ZONE:New("AR641A"), callsignName = 1, callsignNumber = 1},
  {spawnobject = "AR635_KC-135MPRS_01", spawnzone = ZONE:New("AR635"), callsignName = 3, callsignNumber = 2},
  {spawnobject = "AR625_KC-135MPRS_01", spawnzone = ZONE:New("AR625"), callsignName = 3, callsignNumber = 3},
  {spawnobject = "AR641A_KC-135MPRS_01", spawnzone = ZONE:New("AR641A"), callsignName = 3, callsignNumber = 1},
  {spawnobject = "AWACS_DARKSTAR", spawnzone = ZONE:New("AWACS"), callsignName = 5, callsignNumber = 1},
}

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone

  --local SupportSpawn = _args[1]
  local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )
  SupportSpawnObject:InitLimit( 1, 50 )
    :OnSpawnGroup(
      function ( SpawnGroup )
        --SpawnGroup:CommandSetCallsign(SupportSpawn.callsignName, SupportSpawn.callsignNumber)
        local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
        local CheckTanker = SCHEDULER:New( nil, 
        function ()
          if SpawnGroup then
            if SpawnGroup:IsNotInZone( SupportSpawn.spawnzone ) then
              SupportSpawnObject:ReSpawn( SpawnIndex )
            end
          end
        end,
        {}, 0, 60 )
      end
    )
    :InitRepeatOnLanding()
    :Spawn()
 
end

-- spawn support aircraft ---
for i, v in ipairs( TableSpawnSupport ) do
  SpawnSupport ( v )
end

--- END SUPPORT AIRCRAFT SECTION

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN RANGE SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- R62 T6208 MOVING TARGETS

MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, function() trigger.action.setUserFlag(62081, 1) end) 
MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, function() trigger.action.setUserFlag(62082, 1) end) 
MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, function() trigger.action.setUserFlag(62083, 1) end) 

-- END R62 T6208

-- STATIC RANGES

-- @field #STATICRANGES
local RANGESNTTR = {}

RANGESNTTR.Defaults = {
  strafeMaxAlt             = 1530, -- [5000ft] in metres. Height of strafe box.
  strafeBoxLength          = 3000, -- [10000ft] in metres. Length of strafe box.
  strafeBoxWidth           = 300, -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
  strafeFoullineDistance   = 610, -- [2000ft] in metres. Min distance for from target for rounds to be counted.
  strafeGoodPass           = 20, -- Min hits for a good pass.
  rangeSoundFilesPath      = "Range Soundfiles/" -- Range sound files path in miz
}

-- Range targets table
RANGESNTTR.RangeStatic = {
  { --R61
    rangeId = "R61",
    rangeName = "Range 61",
    rangeZone = "R61",
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
  { --R62A
    rangeId = "R62A",
    rangeName = "Range 62A",
    rangeZone = "R62A",
    rangeControlFrequency = 234.250,
    groups = {
      "62-01", "62-02", "62-04",
    },
    units = {
    },
    strafepits = {
    },
  },--R62A END
  { --R62B
    rangeId = "R62B",
    rangeName = "Range 62B",
    rangeZone = "R62B",
    rangeControlFrequency = 234.250,
    groups = {
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
  },--R62B END
  { --R63
    rangeId = "R63",
    rangeName = "Range 63",
    rangeZone = "R63",
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
    rangeId = "R64",
    rangeName = "Range 64",
    rangeZone = "R64",
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
    rangeId = "R65",
    rangeName = "Range 65",
    rangeZone = "R65",
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


function RANGESNTTR:AddStaticRanges(TableRangeStatic)

  for rangeIndex, rangeData in ipairs(TableRangeStatic) do
  
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
    
    self[rangeObject]:Start()
  end

end

-- Create ranges
RANGESNTTR:AddStaticRanges(RANGESNTTR.RangeStatic)


-- ACTIVE RANGES

MenuActiveRangesTop = MENU_COALITION:New(coalition.side.BLUE, "Active Ranges")

function resetRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)

  if rangeGroup:IsActive() then
    rangeGroup:Destroy(false)
    if withSam then
      withSam:Destroy(false)
    end
    if not refreshRange then
      rangeMenu:Remove()
      initActiveRange(GROUP:FindByName("ACTIVE_" .. rangePrefix))
      MESSAGE:New("Target " .. rangePrefix .. " has been deactivated."):ToAll()
    else
      refreshRangeGroup = initActiveRange(GROUP:FindByName("ACTIVE_" .. rangePrefix), refreshRange)
      activateRangeTarget(refreshRangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)      
    end
  end
  
end

function activateRangeTarget(rangeGroup, rangePrefix, rangeMenu, withSam, refreshRange)

  if refreshRange == nil then
    rangeMenu:Remove()
    _G["rangeMenu_" .. rangePrefix] = MENU_COALITION:New(coalition.side.BLUE, "Reset " .. rangePrefix, MenuActiveRangesTop)
  end
  rangeGroup:SetAIOn()
  rangeGroup:OptionROE(ENUMS.ROE.WeaponFree)
  rangeGroup:OptionROTEvadeFire()
  rangeGroup:OptionAlarmStateRed()
  local deactivateText = "Deactivate " .. rangePrefix
  local refreshText = "Refresh " .. rangePrefix
  if withSam then
    local samTemplate = "SAM_" .. rangePrefix
    local activateSam = SPAWN:New(samTemplate)
     activateSam:OnSpawnGroup(
      function (spawnGroup)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , _G["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], spawnGroup, false)
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " with SAM" , _G["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], spawnGroup, true)
        MESSAGE:New("Target " .. rangePrefix .. " is active, with SAM."):ToAll()
      end, rangeGroup, rangePrefix, rangeMenu, withSam, deactivateText, refreshText
    )
    :Spawn()
  else
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, deactivateText , _G["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], withSam, false)
    MENU_COALITION_COMMAND:New(coalition.side.BLUE, refreshText .. " NO SAM" , _G["rangeMenu_" .. rangePrefix], resetRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], withSam, true)
    MESSAGE:New("Target " .. rangePrefix .. " is active."):ToAll()
  end
  
end

function addActiveRangeMenu(rangeGroup, rangePrefix)

  local rangeIdent = string.sub(rangePrefix, 1, 2)
  if _G["rangeMenuSub_" .. rangeIdent] == nil then
    _G["rangeMenuSub_" .. rangeIdent] = MENU_COALITION:New(coalition.side.BLUE, "R" .. rangeIdent, MenuActiveRangesTop)
  end
  _G["rangeMenu_" .. rangePrefix] = MENU_COALITION:New(coalition.side.BLUE, rangePrefix, _G["rangeMenuSub_" .. rangeIdent])
  MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix .. " NO SAM", _G["rangeMenu_" .. rangePrefix], activateRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], false )
  MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate " .. rangePrefix .. " with SAM" , _G["rangeMenu_" .. rangePrefix], activateRangeTarget, rangeGroup, rangePrefix, _G["rangeMenu_" .. rangePrefix], true )
  return _G["rangeMenu_" .. rangePrefix]
  
end

function initActiveRange(rangeTemplateGroup, refreshRange) -- initial menu build for active ranges

  rangeTemplate = rangeTemplateGroup.GroupName
  local activeRange = SPAWN:New(rangeTemplate)
    activeRange:OnSpawnGroup(
    function (spawnGroup)
      local rangeName = spawnGroup.GroupName
      local rangePrefix = string.sub(rangeName, 8, 12) 
      if refreshRange == nil then
        addActiveRangeMenu(spawnGroup, rangePrefix)
      end
    end, refreshRange 
  )
  :Spawn()
  return activeRange:GetLastAliveGroup()
  
end

local SetInitActiveRangeGroups = SET_GROUP:New():FilterPrefixes("ACTIVE_"):FilterOnce() -- create list of group objects with prefix "ACTIVE_"
SetInitActiveRangeGroups:ForEachGroup(initActiveRange)

--- END RANGES

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSILE TRAINER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create a new missile trainer object.
MissileTrainer = {
  menuadded = {},
  MenuF10 = {},
}

MissileTrainer.fox = FOX:New() -- add new FOX class to the Missile Trainer

--- FOX Default Settings
MissileTrainer.fox:SetDefaultLaunchAlerts(false) -- launcher alerts OFF
  :SetDefaultLaunchMarks(false) -- launch marks OFF
  :SetDefaultMissileDestruction(false) -- missile destruction off
  :SetExplosionDistance(300) -- distance from uit at which to destroy incoming missiles
  :SetDebugOnOff() -- set debug on if true
  :SetDisableF10Menu() -- remove default F10 menu as a custom menu will be used
  :Start() -- start the missile trainer

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #MissileTrainer self
-- @param #string unitName name of client unit
function MissileTrainer:ToggleMissileTrainer(unitName)
  self.fox:_ToggleLaunchAlert(unitName)
  self.fox:_ToggleDestroyMissiles(unitName)
end

--- Add Missile Trainer F10 root menu
-- @param #MissileTrainer self
-- @param #wrapper.Unit unit Unit object occupied by client
-- @param #string unitName Name of unit occupied by client
function MissileTrainer:AddMenu(unit, unitName)
  local group = unit:GetGroup()
  local gid = group:GetID()

  self.MenuF10[gid] = missionCommands.addSubMenuForGroup(gid, "Missile Trainer")
  rootPath = self.MenuF10[gid]
  missionCommands.addCommandForGroup(gid, "Missile Trainer On/Off", rootPath, self.ToggleMissileTrainer, MissileTrainer, unitName)
end

--- END MISSILE TRAINER

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ELECTRONIC COMBAT SIMULATOR RANGE
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

menuEcsTop = MENU_COALITION:New(coalition.side.BLUE, "EC South")

-- SAM spawn emplates
templateEcs_Sa10 = "ECS_SA10"
templateEcs_Sa2 = "ECS_SA2"
templateEcs_Sa3 = "ECS_SA3"
templateEcs_Sa6 = "ECS_SA6"
templateEcs_Sa8 = "ECS_SA8"
templateEcs_Sa15 = "ECS_SA15"
-- Zone in which threat will be spawned
zoneEcs7769 = ZONE:FindByName("ECS_ZONE_7769")

ECS = {}
ECS.ActiveSite = {}
ECS.rIADS = nil


function activateEcsThreat(samTemplate, samZone, activeThreat, isReset)

  -- remove threat selection menu options
  if not isReset then
    commandActivateSa10:Remove()
    commandActivateSa2:Remove()
    commandActivateSa3:Remove()
    commandActivateSa6:Remove()
    commandActivateSa8:Remove()
    commandActivateSa15:Remove()
  end
  
  -- spawn threat in ECS zone
  local ecsSpawn = SPAWN:New(samTemplate)
  ecsSpawn:OnSpawnGroup(
      function (spawnGroup)
        commandDeactivateEcs_7769 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Deactivate 77-69", menuEcsTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, false)
        commandRefreshEcs_7769 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Reset 77-69", menuEcsTop, resetEcsThreat, spawnGroup, ecsSpawn, activeThreat, true, samZone)
        MESSAGE:New("EC South is active with " .. activeThreat):ToAll()
        ECS.rIADS = SkynetIADS:create("ECSOUTH")
        ECS.rIADS:setUpdateInterval(5)
        ECS.rIADS:addEarlyWarningRadar("GCI2")
        ECS.rIADS:addSAMSite(spawnGroup.GroupName)
        ECS.rIADS:getSAMSiteByGroupName(spawnGroup.GroupName):setGoLiveRangeInPercent(80)
        ECS.rIADS:activate()        
      end
      , menuEcsTop, rangePrefix, ecsSpawn, activeThreat, samZone
    )
    :SpawnInZone(samZone, true)
end

function resetEcsThreat(spawnGroup, ecsSpawn, activeThreat, refreshEcs, samZone)

  commandDeactivateEcs_7769:Remove() -- remove ECS active menus
  commandRefreshEcs_7769:Remove()
  
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

  -- [threat template], [threat zone], [active threat]
  commandActivateSa10 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-10", menuEcsTop ,activateEcsThreat, templateEcs_Sa10, zoneEcs7769, "SA-10")
  commandActivateSa2 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-2", menuEcsTop ,activateEcsThreat, templateEcs_Sa2, zoneEcs7769, "SA-2")
  commandActivateSa3 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-3", menuEcsTop ,activateEcsThreat, templateEcs_Sa3, zoneEcs7769, "SA-3")
  commandActivateSa6 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-6", menuEcsTop ,activateEcsThreat, templateEcs_Sa6, zoneEcs7769, "SA-6")
  commandActivateSa8 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-8", menuEcsTop ,activateEcsThreat, templateEcs_Sa8, zoneEcs7769, "SA-8")
  commandActivateSa15 = MENU_COALITION_COMMAND:New(coalition.side.BLUE, "Activate SA-15", menuEcsTop ,activateEcsThreat, templateEcs_Sa15, zoneEcs7769, "SA-15")

end

addEcsThreatMenu()

-- END ELECTRONIC COMBAT SIMULATOR RANGE


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ACM/BFM SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

BfmAcm = {}
BfmAcm.Menu = {}

--local SpawnBfm.groupName = nil

-- BFM/ACM Zones
BfmAcm.BoxZone = ZONE_POLYGON:New( "Polygon_Box", GROUP:FindByName("zone_box") )
BfmAcm.ZoneMenu = ZONE_POLYGON:New( "Polygon_BFM_ACM", GROUP:FindByName("COYOTEABC") )
BfmAcm.ExitZone = ZONE:FindByName("Zone_BfmAcmExit")
BfmAcm.Zone = ZONE:FindByName("Zone_BfmAcmFox")

-- Spawn Objects
AdvF4 = SPAWN:New( "ADV_F4" )   
Adv28 = SPAWN:New( "ADV_MiG28" )  
Adv27 = SPAWN:New( "ADV_Su27" )
Adv23 = SPAWN:New( "ADV_MiG23" )
Adv16 = SPAWN:New( "ADV_F16" )
Adv18 = SPAWN:New( "ADV_F18" )

function BfmSpawnAdv(adv,qty,group,rng,unit)

  playerName = (unit:GetPlayerName() and unit:GetPlayerName() or "Unknown") 
  range = rng * 1852
  hdg = unit:GetHeading()
  pos = unit:GetPointVec2()
  spawnPt = pos:Translate(range, hdg, true)
  spawnVec3 = spawnPt:GetVec3()
  if BfmAcm.BoxZone:IsVec3InZone(spawnVec3) then
    MESSAGE:New(playerName .. " - Cannot spawn adversary aircraft in The Box.\nChange course or increase your range from The Box, and try again."):ToGroup(group)
  else
    adv:InitGrouping(qty)
      :InitHeading(hdg + 180)
      :OnSpawnGroup(
        function ( SpawnGroup )
          local CheckAdversary = SCHEDULER:New( SpawnGroup, 
          function (CheckAdversary)
            if SpawnGroup then
              if SpawnGroup:IsNotInZone( BfmAcm.ZoneMenu ) then
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
  end

end

function BfmBuildMenuCommands (AdvMenu, MenuGroup, MenuName, BfmMenu, AdvType, AdvQty, unit)

  _G[AdvMenu] = MENU_GROUP:New( MenuGroup, MenuName, BfmMenu)
    _G[AdvMenu .. "_rng5"] = MENU_GROUP_COMMAND:New( MenuGroup, "5 nmi", _G[AdvMenu], BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 5, unit)
    _G[AdvMenu .. "_rng10"] = MENU_GROUP_COMMAND:New( MenuGroup, "10 nmi", _G[AdvMenu], BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 10, unit)
    _G[AdvMenu .. "_rng20"] = MENU_GROUP_COMMAND:New( MenuGroup, "20 nmi", _G[AdvMenu], BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 20, unit)

end

function BfmBuildMenus(AdvQty, MenuGroup, MenuName, SpawnBfmGroup, unit)

  local AdvSuffix = "_" .. tostring(AdvQty)
  BfmMenu = MENU_GROUP:New(MenuGroup, MenuName, SpawnBfmGroup)
    BfmBuildMenuCommands("SpawnBfmA4menu" .. AdvSuffix, MenuGroup, "Adversary A-4", BfmMenu, AdvF4, AdvQty, unit)
    BfmBuildMenuCommands("SpawnBfm28menu" .. AdvSuffix, MenuGroup, "Adversary MiG-28", BfmMenu, Adv28, AdvQty, unit)
    BfmBuildMenuCommands("SpawnBfm23menu" .. AdvSuffix, MenuGroup, "Adversary MiG-23", BfmMenu, Adv23, AdvQty, unit)
    BfmBuildMenuCommands("SpawnBfm27menu" .. AdvSuffix, MenuGroup, "Adversary Su-27", BfmMenu, Adv27, AdvQty, unit)
    BfmBuildMenuCommands("SpawnBfm16menu" .. AdvSuffix, MenuGroup, "Adversary F-16", BfmMenu, Adv16, AdvQty, unit)
    BfmBuildMenuCommands("SpawnBfm18menu" .. AdvSuffix, MenuGroup, "Adversary F-18", BfmMenu, Adv18, AdvQty, unit)   
      
end
-- CLIENTS
-- BLUFOR = SET_GROUP:New():FilterCoalitions( "blue" ):FilterStart()

-- SPAWN AIR MENU

local function BfmAddMenu()

  local devMenuBfm = false -- if true, BFM menu available outside BFM zone

  SetClient:ForEachClient(
    function(client)
     if (client ~= nil) and (client:IsAlive()) then 
        local group = client:GetGroup()
        local groupName = group:GetName()
        local unit = client:GetClientGroupUnit()
        local playerName = client:GetPlayer()
        
        if (unit:IsInZone(BfmAcm.ZoneMenu) or devMenuBfm) then
          if _G["SpawnBfm" .. groupName] == nil then
            MenuGroup = group
            _G["SpawnBfm" .. groupName] = MENU_GROUP:New( MenuGroup, "AI BFM/ACM" )
              BfmBuildMenus(1, MenuGroup, "Single", _G["SpawnBfm" .. groupName], unit)
              BfmBuildMenus(2, MenuGroup, "Pair", _G["SpawnBfm" .. groupName], unit)
            MESSAGE:New(playerName .. " has entered the BFM/ACM zone.\nUse F10 menu to spawn adversaries."):ToGroup(group)
            --env.info("BFM/ACM entry Player name: " ..client:GetPlayerName())
            --env.info("BFM/ACM entry Group Name: " ..group:GetName())
          end
        elseif _G["SpawnBfm" .. groupName] ~= nil then
          if unit:IsNotInZone(BfmAcm.ZoneMenu) then
            _G["SpawnBfm" .. groupName]:Remove()
            _G["SpawnBfm" .. groupName] = nil
            MESSAGE:New(playerName .. " has left the ACM/BFM zone."):ToGroup(group)
            --env.info("BFM/ACM exit Group Name: " ..group:GetName())
          end
        end
      end
    end
  )
  timer.scheduleFunction(BfmAddMenu,nil,timer.getTime() + 5)

end

BfmAddMenu()

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
-- @field #string ZoneBvr ME Zone object for BVRGCI area boundary
-- @field #string ZoneBvrSpawn ME Zone object for adversary spawn point
-- @field #string ZoneBvrWp1 ME Zone object for adversary spawn waypoint 1
-- @field #number headingDefault Default heading for adversary spawns
-- @field #boolean Destroy When set to true, spawned adversary groups will be removed
BVRGCI = {
  Menu            = {},
  SubMenu         = {},
  ZoneBvr         = ZONE:FindByName("ZONE_BVR"),
  ZoneBvrSpawn    = ZONE:FindByName("ZONE_BVR_SPAWN"),
  ZoneBvrWp1      = ZONE:FindByName("ZONE_BVR_WP1"),
  headingDefault  = 150,
  Destroy         = false,
 }

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
  High = 9144, -- 30,000ft
  Medium = 6096, -- 20,000ft
  Low = 3048, -- 10,000ft
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
-- @param #string typeName Aircraft type name.
-- @param #string typeSpawnTemplate Airctraft type spawn template.
-- @param #number Qty Quantity to spawn.
-- @param #number Altitude Alititude at which to spawn adversary group.
-- @param #number Formation ID for Formation, and spacing, in which to spawn adversary group.
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
        MENU_COALITION_COMMAND:New(coalition.side.BLUE, typeName, ParentMenu, BVRGCI.SpawnType, typeName, typeSpawnTemplate, BVRGCI.SubMenu.Qty, BVRGCI.SubMenu.Level, ENUMS.Formation.FixedWing[BVRGCI.SubMenu.Formation][BVRGCI.SubMenu.Spacing])
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
  BVRGCI.SubMenu.Spacing = Spacing
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
  BVRGCI.SubMenu.Formation = Formation
  -- Build formation spacing menus
  BVRGCI.BuildMenuSpacing("Open", BVRGCI.SubMenu[MenuName])
  BVRGCI.BuildMenuSpacing("Close", BVRGCI.SubMenu[MenuName])
  BVRGCI.BuildMenuSpacing("Group", BVRGCI.SubMenu[MenuName])
end

--- Add BVR/GCI MENU Level.
-- @param #number Altitude Altitude, in metres, at which to adversary group should spawn
-- @param #string MenuName
function BVRGCI.BuildMenuLevel(Altitude, MenuName, MenuText, ParentMenu)
  BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
  BVRGCI.SubMenu.Level = Altitude
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
function BVRGCI.BuildMenuQty(Qty, MenuName, ParentMenu)
  MenuText = MenuName
  BVRGCI.SubMenu[MenuName] = MENU_COALITION:New(coalition.side.BLUE, MenuText, ParentMenu)
  BVRGCI.SubMenu.Qty = Qty
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
--- BEGIN ADMIN MENU SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set mission flag to load a new mission.
--- 1 = NTTR Day.
--- 2 = NTTR Day IFR.
--- 3 = NTTR Night.
--- 4 = NTTR Night Weather.
--- 5 = NTTR Night No Moon.
-- @param #string playerName Name of client calling restart command
-- @param #number mapFlagValue Mission flag to set to true
function LoadMission(playerName, mapFlagValue)

  if adminClientName then
    env.info("ADMIN Restart player name: " .. playerName)
  end
  trigger.action.setUserFlag(9999, mapFlagValue) 

end

--- Add admin menu and commands if client is in an ADMIN spawn
-- @param #object unit Wrapper.Unit#UNIT Unit of player.
function BuildAdminMenu(unit)
  local adminGroup = unit:GetGroup()
  local adminGroupName = adminGroup:GetName()
  local adminMenu = MENU_GROUP:New(adminGroup, "Admin")
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR", adminMenu, LoadMission, unit:GetPlayerName(), 1 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR - IFR", adminMenu, LoadMission, unit:GetPlayerName(), 2 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR", adminMenu, LoadMission, unit:GetPlayerName(), 3 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - Weather", adminMenu, LoadMission, unit:GetPlayerName(), 4 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - No Moon", adminMenu, LoadMission, unit:GetPlayerName(), 5 )
end

--- END ADMIN MENU SECTION


env.info( '*** JTF-1 MOOSE MISSION SCRIPT END ***' )
