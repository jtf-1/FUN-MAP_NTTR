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