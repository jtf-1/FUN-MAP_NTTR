env.info( '*** JTF-1 NTTR Fun Map MOOSE script ***' )
env.info( '*** JTF-1 MOOSE MISSION SCRIPT START ***' )


JtfAdmin = true --activate admin menu option in admin slots

_SETTINGS:SetPlayerMenuOff()

-- BEGIN FUNCTIONS SECTION

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

-- END FUNCTIONS SECTION


-- BEGIN SUPPORT AIRCRAFT SECTION

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

local strafeMaxAlt = 1530 -- [5000ft] in metres. Height of strafe box.
local strafeBoxLength = 3000 -- [10000ft] in metres. Length of strafe box.
local strafeBoxWidth = 300 -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
local strafeGoodPass = 20 -- Min hits for a good pass.

-- Range tactical frequencies
local RadioRangeControl = {
  {R61 = 341.925},
  {R62 = 234.250},
  {R63 = 361.600},
  {R64 = 341.925},
  {R65 = 225.450},
  {R74 = 228.000},
  {ECS = 293.500},
  }
  
-- RANGE R61

Range_R61 = RANGE:New("Range 61")
Range_R61:SetRangeZone(ZONE_POLYGON:FindByName("R61"))
Range_R61:SetSoundfilesPath("Range Soundfiles/")
Range_R61:SetRangeControl(RadioRangeControl.R61)

-- R61B
Range_R61:AddBombingTargetGroup(GROUP:FindByName("61-01"))
Range_R61:AddBombingTargetGroup(GROUP:FindByName("61-03"))

local bombtarget_R61B = {
  "61-01 Aircraft #001", 
  "61-01 Aircraft #002", 
}
Range_R61:AddBombingTargets( bombtarget_R61B )

Range_R61:Start()

-- END R61

-- R62
Range_R62 = RANGE:New("Range 62")
Range_R62:DebugOFF()
Range_R62:SetRangeZone(ZONE_POLYGON:FindByName("R62"))
Range_R62:SetSoundfilesPath("Range Soundfiles/")
Range_R62:SetRangeControl(RadioRangeControl.R62)

-- R62A
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-01"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-02"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-04"))

-- R62B
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-03"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-08"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-09"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-11"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-12"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-13"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-14"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-21"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-21-01"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-22"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-31"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-32"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-41"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-42"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-43"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-44"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-45"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-51"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-52"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-53"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-54"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-55"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-56"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-61"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-62"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-63"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-71"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-72"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-73"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-74"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-75"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-76"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-77"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-78"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-79"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-81"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-83"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-91"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-92"))
Range_R62:AddBombingTargetGroup(GROUP:FindByName("62-93"))

local bombtarget_R62 = {
  "62-32-01", 
  "62-32-02", 
  "62-32-03",
  "62-99",  
}
Range_R62:AddBombingTargets( bombtarget_R62 )

Range_R62:Start()

-- T6208 moving strafe targets
MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, function() trigger.action.setUserFlag(62081, 1) end) 
MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, function() trigger.action.setUserFlag(62082, 1) end) 
MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, function() trigger.action.setUserFlag(62083, 1) end) 

-- END R62

-- R63
Range_R63 = RANGE:New("Range 63")
Range_R63:SetRangeZone(ZONE_POLYGON:FindByName("R63"))
Range_R63:SetSoundfilesPath("Range Soundfiles/")
Range_R63:SetRangeControl(RadioRangeControl.R63B)
Range_R63:SetMaxStrafeAlt(strafeMaxAlt)

--R63B
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-01"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-02"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-03"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-05"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-10"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-12"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("63-15"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("R-63B Class A Range-01"))
Range_R63:AddBombingTargetGroup(GROUP:FindByName("R-63B Class A Range-02"))

local FoulDist_R63B_Strafe = Range_R63:GetFoullineDistance("R63B Strafe Lane L1", "R63B Foul Line Left")

local Strafe_R63B_West = {
  "R63B Strafe Lane L2",
  "R63B Strafe Lane L1",
  "R63B Strafe Lane L3",
}
Range_R63:AddStrafePit(Strafe_R63B_West, strafeBoxLength, strafeBoxWidth, nil, true, strafeGoodPass, FoulDist_R63B_Strafe)

local Strafe_R63B_East = {
  "R63B Strafe Lane R2",
  "R63B Strafe Lane R1",
  "R63B Strafe Lane R3",
}
Range_R63:AddStrafePit(Strafe_R63B_East, strafeBoxLength, strafeBoxWidth, nil, true, strafeGoodPass, FoulDist_R63B_Strafe)

local bombtarget_R63B = {
  "R63BWC",
  "R63BEC", 
}
Range_R63:AddBombingTargets( bombtarget_R63B )

Range_R63:Start()

-- ENDR63


-- R64
Range_R64= RANGE:New("Range R64")
Range_R64:SetRangeZone(ZONE_POLYGON:FindByName("R64"))
Range_R64:SetSoundfilesPath("Range Soundfiles/")
Range_R64:SetRangeControl(RadioRangeControl.R64C)
Range_R64:SetMaxStrafeAlt(strafeMaxAlt)

-- R64A
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-10"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-11"))

local bombtarget_R64A = {
  "64-12-05", 
}
Range_R64:AddBombingTargets( bombtarget_R64A )

-- R64B
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-13"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-14"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-17"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-19"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-15"))

-- R64C
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-05"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-08"))
Range_R64:AddBombingTargetGroup(GROUP:FindByName("64-09"))

local bombtarget_R64C = {
  "R64CWC", 
  "R64CEC", 
  "R-64C Class A Range-01", 
  "R-64C Class A Range-02", 
}
Range_R64:AddBombingTargets( bombtarget_R64C )

-- Strafe Pits
local FoulDist_R64C_Strafe = Range_R64:GetFoullineDistance("R64C Strafe Lane L1", "R64C Strafe Foul Line L1")

local Strafe_R64C_West = {
  "R64C Strafe Lane L2",
  "R64C Strafe Lane L1",
  "R64C Strafe Lane L3",
}
Range_R64:AddStrafePit(Strafe_R64C_West, strafeBoxLength, strafeBoxWidth, nil, true, strafeGoodPass, FoulDist_R64C_Strafe)

local Strafe_R64C_East = {
  "R64C Strafe Lane R2",
  "R64C Strafe Lane R1",
  "R64C Strafe Lane R3",
}
Range_R64:AddStrafePit(Strafe_R64C_East, strafeBoxLength, strafeBoxWidth, nil, true, strafeGoodPass, FoulDist_R64C_Strafe)

Range_R64:Start()

-- END R64

-- R65
Range_R65 = RANGE:New("Range R65")
Range_R65:SetRangeZone(ZONE_POLYGON:FindByName("R65"))
Range_R65:SetSoundfilesPath("Range Soundfiles/")
Range_R65:SetRangeControl(RadioRangeControl.R65)

--R65C
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-01"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-02"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-03"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-04"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-05"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-06"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-07"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-08"))
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-11"))

--R65D
Range_R65:AddBombingTargetGroup(GROUP:FindByName("65-10"))

Range_R65:Start()

-- END R65

-- RANGE DEBUG
Range_R61:DebugOFF()
Range_R62:DebugOFF()
Range_R63:DebugOFF()
Range_R64:DebugOFF()
Range_R65:DebugOFF()

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
BLUFOR = SET_GROUP:New():FilterCoalitions( "blue" ):FilterStart()

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
          env.info("BFM/ACM entry Player name: " ..client:GetPlayerName())
          env.info("BFM/ACM entry Group Name: " ..group:GetName())
        end
      elseif _G["SpawnBfm" .. groupName] ~= nil then
        if group:IsNotInZone(BfmAcmZoneMenu) then
          _G["SpawnBfm" .. groupName]:Remove()
          _G["SpawnBfm" .. groupName] = nil
          MESSAGE:New("You are outside the ACM/BFM zone."):ToGroup(group)
          env.info("BFM/ACM exit Group Name: " ..group:GetName())
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
  trigger.action.setUserFlag(mapFlag, true) -- 999 = NTTR Day, 997 = NTTR Day Weather, 998 = NTTR Night, 996 = NTTR Night Weather, 995 = NTTR Night No Moon

end

local function BuildAdminMenu(adminState)

  SetAdminClient:ForEachClient(function(client)
    if (client ~= nil) and (client:IsAlive()) then
      adminGroup = client:GetGroup()
      adminGroupName = adminGroup:GetName()
      if string.find(adminGroupName, "XX_ADMIN") then
        adminMenu = MENU_GROUP:New(adminGroup, "ADMIN")
        MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR", adminMenu, adminRestartMission, client:GetPlayerName(), 999 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR - Weather", adminMenu, adminRestartMission, client:GetPlayerName(), 997 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR", adminMenu, adminRestartMission, client:GetPlayerName(), 998 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - Weather", adminMenu, adminRestartMission, client:GetPlayerName(), 996 )
        MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - No Moon", adminMenu, adminRestartMission, client:GetPlayerName(), 995 )
        env.info("ADMIN Player name: " ..client:GetPlayerName())
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
