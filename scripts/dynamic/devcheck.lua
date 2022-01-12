-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Check for Static or Dynamic mission file loading flag
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- mission flag for setting dev mode
local devFlag = 8888

-- If missionflag is true, mission file will load from filesystem with an assert
local devState = trigger.misc.getUserFlag(devFlag)

if devState == 1 then
  DEV_MENU = {}
  --turn on tracing
  BASE:TraceOn()
  env.warning('*** JTF-1 - DEV flag is ON! ***')
  MESSAGE:New("Dev Mode is ON!"):ToAll()

  local function devRestart()
    trigger.action.setUserFlag(flagLoadMission, flagDevMissionValue)
  end

  local function devTraceOnOff(tracestate)
    DEV_MENU.traceOnOff:Remove()
    if tracestate then
      BASE:TraceOn()
    else
      BASE:TraceOff()
    end
    tracestate = not tracestate
    DEV_MENU.traceOnOff = MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, devTraceOnOff, tracestate)
  end

  -- Add Dev submenu to F10 Other
  DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
  -- add command to OTHER menu root to retart dev mission
  DEV_MENU.reload = MENU_MISSION_COMMAND:New("Reload DEV Mission", DEV_MENU.topmenu, devRestart)
  DEV_MENU.traceOnOff = MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, devTraceOnOff, false)

  -- turn on tracing for debug
  BASE:TraceAll(true)
else
  env.info('*** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK