local M1 = missionCommands.addSubMenu("Target 62-08", nil)
local M3 = missionCommands.addSubMenu("Target 77-69", nil)

missionCommands.addCommand("TGT 6208: Activate  4x4 (46 mph)", M1,function() trigger.action.setUserFlag(62081, 1) end, nil)
missionCommands.addCommand("TGT 6208: Activate  Truck (23 mph)", M1,function() trigger.action.setUserFlag(62082, 1) end, nil)
missionCommands.addCommand("TGT 6208: Activate  T-55 (11 mph)", M1,function() trigger.action.setUserFlag(62083, 1) end, nil)


missionCommands.addCommand("Activate SA-2", M3,function() trigger.action.setUserFlag(77691, 1) end, nil)
missionCommands.addCommand("Activate SA-3", M3,function() trigger.action.setUserFlag(77692, 1) end, nil)
missionCommands.addCommand("Activate SA-8", M3,function() trigger.action.setUserFlag(77693, 1) end, nil)
missionCommands.addCommand("Activate SA-15", M3,function() trigger.action.setUserFlag(77694, 1) end, nil)
missionCommands.addCommand("Disable All", M3,function() trigger.action.setUserFlag(7769, 1) end, nil)


T77691Group = GROUP:FindByName( "T7769-1#001" )
T77691Group:Destroy()

T77692Group = GROUP:FindByName( "T7769-2#001" )
T77692Group:Destroy()

T77693Group = GROUP:FindByName( "T7769-3#001" )
T77693Group:Destroy()

T77694Group = GROUP:FindByName( "T7769-4#001" )
T77694Group:Destroy()




GroupPolygonT7769 = GROUP:FindByName( "T7769boundary" )  
T7769Zone=ZONE_POLYGON:New("T7769", GroupPolygonT7769)

ZoneTable = { T7769Zone }
Spawn_776901_Source = SPAWN:New( "T7769-1" ):InitRandomizeZones( ZoneTable )
Spawn_776901 = Spawn_776901_Source:Spawn()