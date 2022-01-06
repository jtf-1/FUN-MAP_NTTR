-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Check for Static or Dynamic mission file loading flag
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 then
  env.warning('*** JTF-1 - DEV flag is ON! ***')
  MESSAGE:New("Dev Mode is ON!"):ToAll()

  local function restartDev()
    trigger.action.setUserFlag(flagLoadMission, flagDevMissionValue)
  end

  -- add command to OTHER menu root to retart dev mission
  MENU_MISSION_COMMAND:New("Reload DEV Mission",nil,restartDev)
  
else
  env.info('*** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK