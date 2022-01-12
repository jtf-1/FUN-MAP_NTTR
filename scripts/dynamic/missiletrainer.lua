-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSILE TRAINER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create event handler
mTrainer = EVENTHANDLER:New()
mTrainer:HandleEvent(EVENTS.Birth)   --EVENTS.Birth or EVENTS.BirthPlayerEnterAircraft

-- Create mTrainer container and defaults
mTrainer.menuadded = {}
mTrainer.MenuF10   = {}
mTrainer.safeZone = nil --safezone to use, otherwise nil --"ZONE_FOX"
mTrainer.launchZone = nil --launchzone to use, otherwise nil --"ZONE_FOX"

function mTrainer:GetPlayerUnitAndName(unitname)
  if unitname ~= nil then
    -- Get DCS unit from its name.
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

mTrainer.fox = FOX:New() -- add new FOX class to the Missile Trainer

--- FOX Default Settings
-- launcher alerts OFF
mTrainer.fox:SetDefaultLaunchAlerts(false)
-- missile destruction off
mTrainer.fox:SetDefaultMissileDestruction(false)
-- launch map marks OFF
mTrainer.fox:SetDefaultLaunchMarks(false)
-- distance from uit at which to destroy incoming missiles
mTrainer.fox:SetExplosionDistance(300)
-- set debug on if true
mTrainer.fox:SetDebugOnOff()
-- remove default F10 menu as a custom menu will be used
mTrainer.fox:SetDisableF10Menu()
-- zone in which players will be protected
if mTrainer.safeZone then
  mTrainer.fox:AddSafeZone(ZONE:New(mTrainer.safeZone))
end
-- zone in which launches will be tracked
if mTrainer.launchZone then
  mTrainer.fox:AddLaunchZone(ZONE:New(mTrainer.launchZone))
end

-- start the missile trainer
mTrainer.fox:Start()

--- Toggle Launch Alerts and Destroy Missiles on/off
-- @param #mTrainer self
-- @param #string unitname name of client unit
function mTrainer:TogglemTrainer(unitname)
  self.fox:_ToggleLaunchAlert(unitname)
  self.fox:_ToggleDestroyMissiles(unitname)
end

--- Add Missile Trainer F10 root menu.
-- @param #mTrainer self
-- @param #wrapper.Unit unit Unit object occupied by client
-- @param #string unitname Name of unit occupied by client
function mTrainer:AddMenu(unitname, state)
  self:F(unitname)
  local unit, playername = self:GetPlayerUnitAndName(unitname)
  -- check for player unit.
  if unit and playername then
    -- get group and groupo ID.
    local group = unit:GetGroup()
    local gid = group:GetID()
    if group and gid then
      if not self.menuadded[gid] then
        -- enable switch so that we don't do this twice
        self.menuadded[gid] = true
        local rootPath=nil
        if FOX.MenuF10[gid] == nil then
          FOX.MenuF10[gid] = missionCommands.addSubMenuForGroup(gid, "Missile Trainer")
        end
        rootPath = FOX.MenuF10[gid]
        missionCommands.addCommandForGroup(gid, "Missile Trainer On/Off", rootPath, self.TogglemTrainer, self, unitname) -- F1
        missionCommands.addCommandForGroup(gid, "My Status", rootPath, self.fox._MyStatus,  self.fox, unitname) -- F2
      end
    else
      self:E(self.lid..string.format("ERROR: Could not find group or group ID in AddMenu() function. Unit name: %s.", unitname))
    end
  else
    self:E(self.lid..string.format("ERROR: Player unit does not exist in AddMenu() function. Unit name: %s.", unitname))
  end
end

function mTrainer:OnEventBirth(EventData) -- OnEventBirth or OnEventPlayerEnterAircraft
  self:F({eventbirth = EventData})
  local unitname = EventData.IniUnitName
  local unit, playername = mTrainer:GetPlayerUnitAndName(unitname)
  if unit and playername then
    SCHEDULER:New(nil, mTrainer.AddMenu, {mTrainer, unitname, true},0.1)
  end
end

--- END MISSILE TRAINER