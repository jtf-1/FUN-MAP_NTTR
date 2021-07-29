env.info( '*** JTF-1 NTTR Fun Map MOOSE script ***' )
env.info( '*** JTF-1 MOOSE MISSION SCRIPT START ***' )


JtfAdmin = true --activate admin menu option in admin slots
BASE:TraceOnOff(false) --debug on/off

_SETTINGS:SetPlayerMenuOff()

-- BEGIN SUPPORT AIRCRAFT SECTION

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone

  --local SupportSpawn = _args[1]
  local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )
  SupportSpawnObject:InitLimit( 1, 50 )
    :OnSpawnGroup(
      function ( SpawnGroup )
        SpawnGroup:CommandSetCallsign(SupportSpawn.callsignName, SupportSpawn.callsignNumber)
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
 
end -- function

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

-- spawn support aircraft ---
for i, v in ipairs( TableSpawnSupport ) do
  SpawnSupport ( v )
end

-- END SUPPORT AIRCRAFT SECTION

-- BEGIN STATIC RANGE SECTION

function AddRanges(TableRangeStatic)
  for rangeIndex, rangeData in ipairs(TableRangeStatic) do
  
    local rangeId = rangeData.rangeId
    
    _G["Range_" .. rangeId] = RANGE:New(rangeData.rangeName)
    _G["Range_" .. rangeId]:SetRangeZone(ZONE_POLYGON:FindByName(rangeData.rangeZone))
    _G["Range_" .. rangeId]:SetSoundfilesPath(rangeSoundFilesPath)
    --_G["Range_" .. rangeId]:SetRangeControl(rangeData.rangeControlFrequency)
 
    if rangeData.groups ~= nil then -- add groups of targets
      for tgtIndex, tgtName in ipairs(rangeData.groups) do
        _G["Range_" .. rangeId]:AddBombingTargetGroup(GROUP:FindByName(tgtName))
      end
    end
    
    if rangeData.units ~= nil then -- add individual targets
      for tgtIndex, tgtName in ipairs(rangeData.units) do
        _G["Range_" .. rangeId]:AddBombingTargets( tgtName )
      end
    end
    
    if rangeData.strafepits ~= nil then -- add strafe targets
      for strafepitIndex, strafepit in ipairs(rangeData.strafepits) do
        _G["Range_" .. rangeId]:AddStrafePit(strafepit, strafeBoxLength, strafeBoxWidth, nil, true, strafeGoodPass, strafeFoullineDistance)
      end  
    end
    
    _G["Range_" .. rangeId]:DebugOFF()  
    _G["Range_" .. rangeId]:Start()
  end
end

-- Range Strafe target default parameters
local strafeMaxAlt = 1530 -- [5000ft] in metres. Height of strafe box.
local strafeBoxLength = 3000 -- [10000ft] in metres. Length of strafe box.
local strafeBoxWidth = 300 -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
local strafeFoullineDistance = 610 -- [2000ft] in metres. Min distance for from target for rounds to be counted.
local strafeGoodPass = 20 -- Min hits for a good pass.
local rangeSoundFilesPath = "Range Soundfiles/" -- Range sound files path in miz

-- Range targets table
local TableRangeStatic = {
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
  },--R61 END
  { --R62A
    rangeId = "R62A",
    rangeName = "Range 62A",
    rangeZone = "R62A",
    rangeControlFrequency = 234.250,
    groups = {
      "62-01", "62-02", "62-04",
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
  },--R65 END
}


-- Create ranges
AddRanges(TableRangeStatic)

-- R62 T6208 moving strafe targets
MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, function() trigger.action.setUserFlag(62081, 1) end) 
MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, function() trigger.action.setUserFlag(62082, 1) end) 
MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, function() trigger.action.setUserFlag(62083, 1) end) 

-- END R62 T6208
-- END STATIC RANGE SECTION

-- BEGIN DYNAMIC RANGES

MenuActiveRangesTop = MENU_COALITION:New(coalition.side.BLUE, "ACTIVE RANGES")

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

--- END DYNAMIC RANGES

-- BEGIN ELECTRONIC COMBAT SIMULATOR RANGE

menuEcsTop = MENU_COALITION:New(coalition.side.BLUE, "EC SOUTH")

-- SAM spawn emplates
templateEcs_Sa10 = "ECS_SA10"
templateEcs_Sa2 = "ECS_SA2"
templateEcs_Sa3 = "ECS_SA3"
templateEcs_Sa6 = "ECS_SA6"
templateEcs_Sa8 = "ECS_SA8"
templateEcs_Sa15 = "ECS_SA15"
-- Zone in which threat will be spawned
zoneEcs7769 = ZONE:FindByName("ECS_ZONE_7769")

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
      end, menuEcsTop, rangePrefix, ecsSpawn, activeThreat, samZone
    )
    :SpawnInZone(samZone, true)

end

function resetEcsThreat(spawnGroup, ecsSpawn, activeThreat, refreshEcs, samZone)

  commandDeactivateEcs_7769:Remove() -- remove ECS active menus
  commandRefreshEcs_7769:Remove()

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


--- BEGIN MISSILE TRAINER

-- Create a new missile trainer object.
fox=FOX:New()

-- Add training zones.
fox:AddSafeZone(ZONE:FindByName("Zone_BfmAcmFox"))
fox:AddLaunchZone(ZONE:FindByName("Zone_BfmAcmFox"))

fox:AddSafeZone(ZONE:FindByName("ZONE_4807_MT"))
fox:AddLaunchZone(ZONE:FindByName("ZONE_4807_MT"))

fox:AddSafeZone(ZONE:FindByName("ZONE_ECS_MT"))
fox:AddLaunchZone(ZONE:FindByName("ZONE_ECS_MT"))

-- FOX settings
fox:SetExplosionDistance(300)
fox:SetDisableF10Menu()
fox:SetDebugOnOff()

-- Start missile trainer.
fox:Start()

--- END MISSILE TRAINER


-- BEGIN ACM/BFM SECTION

--local SpawnBfm.groupName = nil

-- BFM/ACM Zones
BoxZone = ZONE_POLYGON:New( "Polygon_Box", GROUP:FindByName("zone_box") )
BfmAcmZoneMenu = ZONE_POLYGON:New( "Polygon_BFM_ACM", GROUP:FindByName("COYOTEABC") )
BfmAcmExitZone = ZONE:FindByName("Zone_BfmAcmExit")
BfmAcmZone = ZONE:FindByName("Zone_BfmAcmFox")

-- Spawn Objects
AdvA4 = SPAWN:New( "ADV_A4" )   
Adv28 = SPAWN:New( "ADV_MiG28" )  
Adv27 = SPAWN:New( "ADV_Su27" )
Adv23 = SPAWN:New( "ADV_MiG23" )
Adv16 = SPAWN:New( "ADV_F16" )
Adv18 = SPAWN:New( "ADV_F18" )

function SpawnAdv(adv,qty,group,rng)

  range = rng * 1852
  hdg = group:GetHeading()
  pos = group:GetPointVec2()
  spawnPt = pos:Translate(range, hdg, true)
  spawnVec3 = spawnPt:GetVec3()
  if BoxZone:IsVec3InZone(spawnVec3) then
    MESSAGE:New("Cannot spawn adversary aircraft in The Box.\nChange course or increase your range from The Box, and try again."):ToGroup(group)
  else
    adv:InitGrouping(qty)
      :InitHeading(hdg + 180)
      :OnSpawnGroup(
        function ( SpawnGroup )
          local CheckAdversary = SCHEDULER:New( SpawnGroup, 
          function (CheckAdversary)
            if SpawnGroup then
              if SpawnGroup:IsNotInZone( BfmAcmZoneMenu ) then
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
    MESSAGE:New("Adversary spawned."):ToGroup(group)
  end

end

function BuildMenuCommands (AdvMenu, MenuGroup, MenuName, BfmMenu, AdvType, AdvQty)

  _G[AdvMenu] = MENU_GROUP:New( MenuGroup, MenuName, BfmMenu)
    _G[AdvMenu .. "_rng5"] = MENU_GROUP_COMMAND:New( MenuGroup, "5 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 5)
    _G[AdvMenu .. "_rng10"] = MENU_GROUP_COMMAND:New( MenuGroup, "10 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 10)
    _G[AdvMenu .. "_rng20"] = MENU_GROUP_COMMAND:New( MenuGroup, "20 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 20)

end

function BuildMenus(AdvQty, MenuGroup, MenuName, SpawnBfmGroup)

  local AdvSuffix = "_" .. tostring(AdvQty)
  BfmMenu = MENU_GROUP:New(MenuGroup, MenuName, SpawnBfmGroup)
    BuildMenuCommands("SpawnBfmA4menu" .. AdvSuffix, MenuGroup, "Adversary A-4", BfmMenu, AdvA4, AdvQty)
    BuildMenuCommands("SpawnBfm28menu" .. AdvSuffix, MenuGroup, "Adversary MiG-28", BfmMenu, Adv28, AdvQty)
    BuildMenuCommands("SpawnBfm23menu" .. AdvSuffix, MenuGroup, "Adversary MiG-23", BfmMenu, Adv23, AdvQty)
    BuildMenuCommands("SpawnBfm27menu" .. AdvSuffix, MenuGroup, "Adversary Su-27", BfmMenu, Adv27, AdvQty)
    BuildMenuCommands("SpawnBfm16menu" .. AdvSuffix, MenuGroup, "Adversary F-16", BfmMenu, Adv16, AdvQty)
    BuildMenuCommands("SpawnBfm18menu" .. AdvSuffix, MenuGroup, "Adversary F-18", BfmMenu, Adv18, AdvQty)   
      
end
-- CLIENTS
-- BLUFOR = SET_GROUP:New():FilterCoalitions( "blue" ):FilterStart()

-- SPAWN AIR MENU
local SetClient = SET_CLIENT:New():FilterCoalitions("blue"):FilterStart() -- create a list of all clients

local function MENU()

  local devMenuBfm = false -- if true, BFM menu available outside BFM zone

  SetClient:ForEachClient(function(client)
   if (client ~= nil) and (client:IsAlive()) then 
      local group = client:GetGroup()
      local groupName = group:GetName()
      if (group:IsPartlyOrCompletelyInZone(BfmAcmZoneMenu) or devMenuBfm) then
        if _G["SpawnBfm" .. groupName] == nil then
          MenuGroup = group
          _G["SpawnBfm" .. groupName] = MENU_GROUP:New( MenuGroup, "AI BFM/ACM" )
            BuildMenus(1, MenuGroup, "Single", _G["SpawnBfm" .. groupName])
            BuildMenus(2, MenuGroup, "Pair", _G["SpawnBfm" .. groupName])
          MESSAGE:New("You have entered the BFM/ACM zone.\nUse F10 menu to spawn adversaries."):ToGroup(group)
          --env.info("BFM/ACM entry Player name: " ..client:GetPlayerName())
          --env.info("BFM/ACM entry Group Name: " ..group:GetName())
        end
      elseif _G["SpawnBfm" .. groupName] ~= nil then
        if group:IsNotInZone(BfmAcmZoneMenu) then
          _G["SpawnBfm" .. groupName]:Remove()
          _G["SpawnBfm" .. groupName] = nil
          MESSAGE:New("You are outside the ACM/BFM zone."):ToGroup(group)
          --env.info("BFM/ACM exit Group Name: " ..group:GetName())
        end
      end
    end
  end)
  timer.scheduleFunction(MENU,nil,timer.getTime() + 5)

end

MENU()

-- END ACM/BFM SECTION


-- ADMIN SECTION

SetAdminClient = SET_CLIENT:New():FilterStart()

local function adminRestartMission(adminClientName, mapFlag)

  if adminClientName then
    env.info("ADMIN Restart player name: " ..adminClientName)
  end
  trigger.action.setUserFlag(mapFlag, true) -- 999 = NTTR Day, 997 = NTTR Day IFR, 998 = NTTR Night, 996 = NTTR Night Weather, 995 = NTTR Night No Moon

end

local function BuildAdminMenu(adminState)

  SetAdminClient:ForEachClient(function(client)
    if (client ~= nil) and (client:IsAlive()) then
      adminGroup = client:GetGroup()
      adminGroupName = adminGroup:GetName()
      if string.find(adminGroupName, "XX_ADMIN") then
        adminMenu = MENU_GROUP:New(adminGroup, "ADMIN")
        MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR", adminMenu, adminRestartMission, client:GetPlayerName(), 999 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR - IFR", adminMenu, adminRestartMission, client:GetPlayerName(), 997 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR", adminMenu, adminRestartMission, client:GetPlayerName(), 998 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - Weather", adminMenu, adminRestartMission, client:GetPlayerName(), 996 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - No Moon", adminMenu, adminRestartMission, client:GetPlayerName(), 995 )
        --env.info("ADMIN Player name: " ..client:GetPlayerName())
      end
    SetAdminClient:Remove(client:GetName(), true)
    end
  end)
  timer.scheduleFunction(BuildAdminMenu, nil, timer.getTime() + 10)

end

if JtfAdmin then
  env.info("ADMIN enabled")
  BuildAdminMenu(true)
end

--END ADMIN SECTION

env.info( '*** JTF-1 MOOSE MISSION SCRIPT END ***' )
