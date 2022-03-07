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

  local DEV_MENU = {
    traceOn = true, -- default tracestate false == trace off, true == trace on.
  }

  DEV_MENU.missionRestartMsg = (JTF1.missionRestartMsg and JTF1.missionRestartMsg or "ADMIN9999") -- Message to trigger mission restart via jtf1-hooks
  
  function DEV_MENU:toggleTrace(traceOn)
    if traceOn then
      BASE:TraceOff()
    else
      BASE:TraceOn()
    end
    self.traceOn = not traceOn
  end

  function DEV_MENU:testLua(IncludeFile)
    local base = _G
    local __filepath = 'E:/GitHub/FUN-MAP_NTTR/scripts/dynamic/'
		local f = assert( base.loadfile( __filepath .. IncludeFile ) )
    if f == nil then
      error ("[JTF-1] Loader: could not load mission file " .. IncludeFile )
    else
      env.info( "[JTF-1] Loader: " .. IncludeFile .. " dynamically loaded." )
			return f()
    end
  end

  function DEV_MENU:restartMission()
    MESSAGE:New(DEV_MENU.missionRestartMsg):ToAll()
  end

  -- Add Dev submenu to F10 Other
  DEV_MENU.topmenu = MENU_MISSION:New("DEVMENU")
  MENU_MISSION_COMMAND:New("Toggle TRACE.", DEV_MENU.topmenu, DEV_MENU.toggleTrace, DEV_MENU, DEV_MENU.traceOn)
  MENU_MISSION_COMMAND:New("Load Test LUA.", DEV_MENU.topmenu, DEV_MENU.testLua, "test.lua")
  MENU_MISSION_COMMAND:New("Restart Mission", DEV_MENU.topmenu, DEV_MENU.restartMission)

  -- trace all events
  BASE:TraceAll(true)

  if DEV_MENU.traceOn then 
    DEV_MENU:toggleTrace(false) 
  end

else
  env.info('[JTF-1] *** JTF-1 - DEV flag is OFF. ***')
end

--- END DEVCHECK