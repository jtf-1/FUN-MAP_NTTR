-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN JTF-1 HOOKS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

net.log("[JTF-1] Hooks v0.1")

local jtf1hooks = {}
jtf1hooks.currentMission = ""
jtf1hooks.missionRestart = "ADMIN9999" -- Message string to monitor for triggering a mission restart

function jtf1hooks.onMissionLoadEnd()

    jtf1hooks.currentMission = DCS.getMissionFilename()
    net.log("[JTF-1] Mission filename = " .. tostring(jtf1hooks.currentMission))

end

function jtf1hooks.onTriggerMessage(message)
    if message == jtf1hooks.missionRestart then
        net.log("[JTF-1] Restart Current Mission")
        net.load_mission(jtf1hooks.currentMission)
    end
end

DCS.setUserCallbacks(jtf1hooks)
net.log("[JTF-1] Hooks active.")