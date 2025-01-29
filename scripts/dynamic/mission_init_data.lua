env.info( "[JTF-1] mission_init_data.lua" )

--- MISSION  SETTINGS FOR MIZ
--
-- This file MUST be loaded AFTER mission_init.lua
--
-- These values are specific to the miz and will override the default values in 
--

-- Error prevention. Create empty container if module core lua not loaded.
if not MISSIONINIT then 
	MISSIONINIT = {}
	MISSIONINIT.traceTitle = "[JTF-1 MISSIONINIT] "
	_msg = MISSIONINIT.traceTitle .. "CORE FILE NOT LOADED!"
	BASE:E(_msg)
end

-- table of values to override default  values for this miz
MISSIONINIT.menuAllSlots = false
MISSIONINIT.jtfmenu = false

-- start the mission timer
if MISSIONINIT.Start then
	_msg = MISSIONINIT.traceTitle .. "Call Start()"
	BASE:T(_msg)
	MISSIONINIT:Start()  
end
