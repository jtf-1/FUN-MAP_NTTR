-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ADMIN MENU SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ADMIN = EVENTHANDLER:New()
ADMIN:HandleEvent(EVENTS.PlayerEnterAircraft)

ADMIN.adminUnitName = "XX_" -- String to locate within unit name for admin slots
ADMIN.missionRestart = 9999 -- Flag value to restart current mission
ADMIN.missionRestartMsg = "ADMIN9999" -- Message to trigger mission restart via jtf1-hooks

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
  local unitName = EventData.IniUnitName
  local unit, playername = ADMIN:GetPlayerUnitAndName(unitName)
  if unit and playername then
    local adminCheck = (string.find(unitName, ADMIN.adminUnitName) and "true" or "false")
    if string.find(unitName, ADMIN.adminUnitName) then
      SCHEDULER:New(nil, ADMIN.BuildAdminMenu, {self, unit, playername}, 0.5)
    end
  end
end

--- Set mission flag to load a new mission.
--- If mapFlagValue is current mission, restart the mission via jtf1-hooks
--- 9999 = Current Mission
--- 1 = NTTR Day.
--- 2 = NTTR Day IFR.
--- 3 = NTTR Night.
--- 4 = NTTR Night No Moon.
-- @param #string playerName Name of client calling restart command.
-- @param #number mapFlagValue Mission number to which flag should be set.
function ADMIN:LoadMission(playerName, mapFlagValue)
  if playerName then
    env.info("[JTF-1] ADMIN Restart player name: " .. playerName)
  end
  if mapFlagValue == ADMIN.missionRestart then
    MESSAGE:New(ADMIN.missionRestartMsg):ToAll()
  else
    trigger.action.setUserFlag(ADMIN.flagLoadMission, mapFlagValue)
  end
end

--- Add admin menu and commands if client is in an ADMIN spawn
-- @param #object unit Unit of player.
-- @param #string playername Name of player
function ADMIN:BuildAdminMenu(unit,playername)
  local adminGroup = unit:GetGroup()
  local adminGroupName = adminGroup:GetName()
  local adminMenu = MENU_GROUP:New(adminGroup, "Admin")
  MENU_GROUP_COMMAND:New(adminGroup, "Restart current mission", adminMenu, ADMIN.LoadMission, self, playername, 9999 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR", adminMenu, ADMIN.LoadMission, self, playername, 1 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load DAY NTTR - IFR", adminMenu, ADMIN.LoadMission, self, playername, 2 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR", adminMenu, ADMIN.LoadMission, self, playername, 3 )
  MENU_GROUP_COMMAND:New(adminGroup, "Load NIGHT NTTR - No Moon", adminMenu, ADMIN.LoadMission, self, playername, 4 )
end

--- END ADMIN MENU SECTION