-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MISSION TIMER
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Mission Timer
--
-- Add schedules to display messages at set intervals prior to restarting the base mission.
-- ME switched triggers should be set to a FLAG EQUALS condition for the flag flagLoadMission
-- value (defined in script header). The flag value 1 should trigger a LOAD MISSION for the
-- base (default) map.
--
-- Uses jtf1-hooks.lua to restart curent mission at end of mission runtime.
--
--

local MissionTimer = {}
MissionTimer.durationHrs = 11 -- Mission run time in HOURS
MissionTimer.msgSchedule = {60, 30, 10, 5} -- Schedule for mission restart warning messages. Time in minutes.
MissionTimer.durationSecs = MissionTimer.durationHrs * 3600 -- Mission run time in seconds
MissionTimer.msgWarning = {} -- schedule container
MissionTimer.missionRestart = ( JTF1.missionRestart and JTF1.missionRestart or "ADMIN9999" ) -- Message to trigger mission restart via jtf1-hooks

--- add scheduled messages for mission restart warnings and restart at end of mission duration
function MissionTimer:AddSchedules()

  if MissionTimer.msgSchedule ~= nil then
    for i, msgTime in ipairs(self.msgSchedule) do
      self.msgWarning[i] = SCHEDULER:New( nil, 
        function()
          MESSAGE:New("Mission will restart in " .. msgTime .. " minutes!"):ToAll()
        end,
      {msgTime}, self.durationSecs - (msgTime * 60))
    end
  end

  self.msgWarning["restart"] = SCHEDULER:New( nil,
    function()
      env.info("[JTF-1] MISSION RESTART CALLED")
      MESSAGE:New(MissionTimer.missionRestart):ToAll()
    end,
    { }, self.durationSecs)

  end

MissionTimer:AddSchedules()

--- END MISSION TIMER