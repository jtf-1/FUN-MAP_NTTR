
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MARK SPAWN
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Sourced from Virtual 57th. Minor refactoring of original script
--

local DEFAULT_BLUE_COUNTRY = 2 --The USA
local DEFAULT_RED_COUNTRY = 0 -- RUSSIA
  
local spawnerOptions = {

  --{ spawn = SPAWN:New(  "MIG29A"  ), txt = "MiG29" , category = "air", type = "CAP" },


  { spawn = SPAWN:New(  "BVR_MIG23"  ), txt = "MIG23" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_SU25"  ), txt = "SU25" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_MIG29A"  ), txt = "MIG29" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_SU27"  ), txt = "SU27" , category = "air", type = "CAP" },
  { spawn = SPAWN:New(  "BVR_F4"  ), txt = "F4" , category = "air", type = "CAP" },

  --{ spawn = SPAWN:New(  "ECS_SA6"  ), txt = "SA6BTY" , category = "ground", type = "SAM" },
  --{ spawn = SPAWN:New(  "ECS_SA10"  ), txt = "SA10BTY" , category = "ground", type = "SAM" },
  --{ spawn = SPAWN:New(  "ECS_SA11"  ), txt = "SA11BTY" , category = "ground", type = "SAM" },

  --{ spawn = SPAWN:New(  "RED TASMO 8"  ), txt = "AJS37TASMO" , category = "air", type = "Anti-Ship" },
  --{ spawn = SPAWN:New(  "RED CAS 1"  ), txt = "H6" , category = "air", type = "NOTHING" },
  --{ spawn = SPAWN:New(  "RED CAS 5"  ), txt = "SU17CAS" , category = "air", type = "CAS" },
  --{ spawn = SPAWN:New(  "RED SEAD 1"  ), txt = "SU25SEAD" , category = "air", type = "SEAD" },
  --{ spawn = SPAWN:New(  "RED AWACS"  ), txt = "A50", category = "air", type = "AWACS" },
  --{ spawn = SPAWN:New(  "RED CIV 1"  ), txt = "AN26", category = "air", type = "Civilian" },
  --{ spawn = SPAWN:New(  "USAF Tanker 1"  ), txt = "KC135", category = "air", type = "Tanker" },
  --{ spawn = SPAWN:New(  "Silkworm Battery"  ), txt = "HY2BTY", category = "ground", type = "ASCM" },
  --{ spawn = SPAWN:New(  "ZSU23"  ), txt = "ZSU234", category = "ground", type = "SPAAG" },
  --{ spawn = SPAWN:New(  "ZU23"  ), txt = "ZU23", category = "ground", type = "AAA" },
  --{ spawn = SPAWN:New(  "Artillery Battery"  ), txt = "ARTYBTY" , category = "ground", type = "ARTY" },
  --{ spawn = SPAWN:New(  "Truck Park"  ), txt = "TRUCKS" , category = "ground", type = "transport" },
  --{ spawn = SPAWN:New(  "Compound 1"  ), txt = "OUTPOST" , category = "ground", type = "structures" },
  --{ spawn = SPAWN:New(  "T-55 PLT"  ), txt = "T55PLT", category = "ground", type = "ARMOR" },
  --{ spawn = SPAWN:New(  "JTAC"  ), txt = "HUMVEE", category = "ground", type = "JTAC" },
  --{ spawn = SPAWN:New(  "Slava"  ), txt = "Slava", category = "naval", type = "bote" },
}

local radioPresets = {}

local MLSpawnedGroups = {}

local MLAirSpawn
local MLGroundSpawn
local MLNavalSpawn
local MLSetROE
local MLSetTask
local MLSetAlarm
local MLSideComparator
local MLUnfuckMarkPos
local parseMark
local MLRadioPreset
local MLFindWaypoints
local MLListSpawnOptions
local MLDeleteGroup
local MLWxReport
local MLSkillCheck
local split
local comparator
local deleteDeterminator
local magVarDeterminator
local MLSetROT
local MLRemoveMark
local MLRadioSpawn
local MLSongParser
--local MLRadioStatic = STATIC:FindByName("PIRATERADIO","CUCKS")
--local MLRadio = RADIO:New(MLRadioStatic)
local _Heading
local MLTgtArray = {}
local MLCreateTGT
local MLPopulateTGT
local MLReturnTGT
local MLTgtArrayAdd
local MLTgtArrayRemove
local MLDefaultAirAlt = 280 -- altitude in metres
local MLDefaultHdg = 000
local MLDefaultSkill = "AVERAGE"
local MLDefaultDistance = 0
local MLDefaultROE = "FREE"
local MLDefaultROT = "EVADE"
local MLDefaultFreq = 251
local MLDefaultNum = 1
local MLDefaultAirSpeed = 425

-- MARK POINT EVENT HANDLER
local markEvent = EVENTHANDLER:New():HandleEvent(EVENTS.MarkChange)

-- IF MARK IS A "CMD", SEND MARK DATA TO PARSER
function markEvent:OnEventMarkChange( EventData )
  env.info("[MARK_SPAWN] sanity check")
  local text = EventData.text
  local x, _ = string.find(text, "CMD")
  if(x ~= nil) then
    parseMark(EventData)
    MLRemoveMark(EventData.idx)
  else
    return
  end
end

scheduler, schedulerID = SCHEDULER:New( nil,
  function(foo)
    env.info(UTILS.OneLineSerialize(markEvent))
  end,
{}, 300, 300)

--- MARK PARSER
function parseMark (mark)
  local text = mark.text
  --local pos = MLUnfuckMarkPos(mark.pos)
  local pos = mark.pos
  env.info(UTILS.OneLineSerialize(mark))

  -----------------
  -- AIR SPAWN
  -----------------
  --check if there is an air spawn command, if so run through the spawn logic
  local i, _, spawnValue = string.find(text, "ASPAWN: (%w+)")
  if(i ~= nil) then
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("air", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, altitude = string.find(text, "ALT: (%d+)")
      local _, _, task = string.find(text,"TASK: (%w+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WPS = string.find(text, "WPS: {(.*)}")
      local _, _, freq = string.find(text, "FREQ: (%d[%d.]+)")
      local _, _, num = string.find(text, "NUM: (%d+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")
      local _, _, base = string.find(text, "BASE: (%w+)")
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, ROT = string.find(text, "ROT: (%w+)")

      local spawnTable = {
        type = spawnValue,
          heading = heading,
          altitude = altitude,
          task = task, 
          skill = skill, 
          distance = distance, 
          roe = ROE, 
          WP = WPS, 
          pos = pos, 
          freq = freq, 
          num = num, 
          speed = speed,
          side = side, 
          formation = formation,
          base = base,
          groupName = groupName,
          rot = ROT,
        }

      env.info(UTILS.OneLineSerialize(spawnTable))
      MLAirSpawn(spawnTable)
    end    
  end
  
  -----------------
  -- GROUND SPAWN
  -----------------
  local j, _, spawnValue = string.find(text, "GSPAWN: (%w+)")
  if(j ~= nil) then
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("ground", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WP = string.find(text, "WPS: {(.*)}")
      local _, _, alert = string.find(text, "ALERT: (%w+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")  
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, tgtName = string.find(text, "TGT: (%w+)")

      local spawnTable = {
        type = spawnValue,
          heading = heading,
          skill = skill, 
          distance = distance, 
          roe = ROE, 
          WP = WP, 
          pos = pos,
          speed = speed,
          coalition = side,
          formation = formation,
          alert = alert,
          side = side,
          groupName = groupName,
          tgt = tgtName
        }

      env.info(UTILS.OneLineSerialize(spawnTable))
      MLGroundSpawn(spawnTable)
    end
  end
    
  local k, _, spawnValue = string.find(text, "RADIO: (%w+)")

  if(k ~= nil) then
    env.info("[MARK_SPAWN] SpawnValue: " .. spawnValue)
    env.info("[MARK_SPAWN] Other Text: " .. k)
    local _, _, freq = string.find(text, "FREQ: (%d+)")
    local _, _, band = string.find(text,"BAND: (%w+)")
    local _, _, power = string.find(text,"PWR: (%d+)")
    
    local spawnTable = {
      song = spawnValue,
      freq = freq,
      band = band, 
      power = power, 
    }

    env.info("[MARK_SPAWN] CANADIANS")
    env.info(UTILS.OneLineSerialize(spawnTable))
    --MLRadioSpawn(spawnTable)
  else
    env.info("[MARK_SPAWN] UDACHI, SPAYOO")
  end
  
  -----------------
  -- NAVY SPAWN
  -----------------
  --spawn a naval group
  local l, _, spawnValue = string.find(text, "NSPAWN: (%w+)")
  if(l ~= nil) then
    if(spawnValue:upper() == "OPTIONS") then
      MLListSpawnOptions("naval", mark)
    else
      local _, _, heading = string.find(text, "HDG: (%d+)")
      local _, _, skill = string.find(text,"SKILL: (%w+)")
      local _, _, distance = string.find(text,"DIST: (%d+)")
      local _, _, ROE = string.find(text, "ROE: (%w+)")
      local _, _, WP = string.find(text, "WPS: {(.*)}")
      local _, _, alert = string.find(text, "ALERT: (%w+)")
      local _, _, speed = string.find(text, "SPD: (%d+)")
      local _, _, side = string.find(text, "SIDE: (%w+)")
      local _, _, formation = string.find(text, "FORM: (%w+)")  
      local _, _, groupName = string.find(text, "NAME: (%w+)")
      local _, _, tgtName = string.find(text, "TGT: (%w+)")
      
      local spawnTable = {
        type = spawnValue,
          heading = heading,
          skill = skill, 
          distance = distance, 
          roe = ROE, 
          WP = WP, 
          pos = pos,
          speed = speed,
          coalition = side,
          formation = formation,
          alert = alert,
          side = side,
          groupName = groupName,
          tgt = tgtName
        }

      env.info(UTILS.OneLineSerialize(spawnTable))
      MLNavalSpawn(spawnTable)
    end
  end
  
  -----------------
  -- DELETE GROUP(S)
  -----------------
  --Delete one or more groups
  local l, _, deleteCMD = string.find(text, "DELETE: (%w+)")
  if(l ~= nil) then
    local _, _, category = string.find(text, "CAT: (%w+)")
    local _, _, side = string.find(text,"SIDE: (%w+)")
    local _, _, radius = string.find(text,"RAD: (%d+)")
    local _, _, template = string.find(text,"TYPE: (%w+)")
    local _, _, groupName = string.find(text, "NAME: (.+)")
      
      local spawnTable = {
          cmd = deleteCMD,
          category = category,
          side = side,
          radius = radius,
          template = template,
          groupName = groupName,
        }
    MLDeleteGroup(spawnTable, mark)
  end
  --spawn a naval group
  local m, _, repoString = string.find(text, "WXREPORT: (.*)")
  if(m ~= nil) then
    MLWxReport(repoString, mark)
  end

end
  
function MLAirSpawn(SpawnTable)
  local type = SpawnTable.type
  local heading = tonumber(SpawnTable.heading) or MLDefaultHdg
  local altitude = tonumber(SpawnTable.altitude) or MLDefaultAirAlt
  altitude = UTILS.FeetToMeters(altitude * 100)
  local task = SpawnTable.task or "NOTHING"
  local skill = MLSkillCheck(SpawnTable.skill) or MLDefaultSkill
  local distance = tonumber(SpawnTable.distance) or MLDefaultDistance
  local ROE = SpawnTable.roe or MLDefaultROE
  local ROT = SpawnTable.rot or MLDefaultROT
  local freq = tonumber(SpawnTable.freq) or MLDefaultFreq
  local num = tonumber(SpawnTable.num) or MLDefaultNum
  local speed = tonumber(SpawnTable.speed) or MLDefaultAirSpeed
  local form = SpawnTable.formation or nil
  local base = SpawnTable.base or nil
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos):SetAltitude(altitude,true)
  local spawner = comparator(type)
  if(spawner == nil) then
    return
  end
  local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
  local waypointNameString = SpawnTable.WP or nil
  
  --switch country/coalition if desired
  local coal, country
  if(SpawnTable.side) then
    coal, country = MLSideComparator(SpawnTable.side, template)
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end
  local group
  
  --spawn the group
  if(base) then
    local airbase
    if(base == "NEAREST") then 
      env.info("[MARK_SPAWN] learn 2 spell, scrub")
      local theater = env.mission.theatre
      local distance = 0
    else
      airbase = AIRBASE:FindByName(base)
      if(airbase == nil) then 
        airbase = AIRBASE:GetAllAirbases()[1]
      end
    end
    group = spawner:InitGrouping(num):InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnAtAirbase(airbase,SPAWN.Takeoff.Cold,nil)
  else
    env.info(coal .. " " .. country)
    group = spawner:InitGrouping(num):InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
  end
  
  MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "air", side = coal}
  --set ROE
  MLSetROE(ROE,group)
  MLSetROE(ROT,group)
  -- LETS DO WAYPOINTS YE JAMMY FOOKERS!
  --if no distance, then we orbit
  if(waypointNameString) then
    local waypointCoords = MLFindWaypoints(waypointNameString)
    if(#waypointCoords > 0) then
      env.info('MORE WAYPOINTS')
      local route = {}
      route[#route + 1] = spawnCoord:WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
      for idx, waypoint in pairs(waypointCoords) do
        route[#route + 1] = waypoint:SetAltitude(altitude,true):WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
      end
      group:Route(route)
    else
      local orbitEndPoint = spawnCoord:Translate(UTILS.NMToMeters(15),heading)
      local orbit = { 
        id = 'Orbit', 
        params = { 
          pattern = AI.Task.OrbitPattern.RACE_TRACK,
          point = spawnCoord:GetVec2(),
          point2 = orbitEndPoint:GetVec2(),
          speed = UTILS.KnotsToMps(speed),
          altitude = altitude
        } 
      }

      group:SetTask( orbit, 2 )
    end
  elseif(distance == 0) then
    local orbitEndPoint = spawnCoord:Translate(UTILS.NMToMeters(15),heading)
    local orbit = { 
      id = 'Orbit', 
      params = { 
        pattern = AI.Task.OrbitPattern.RACE_TRACK,
        point = spawnCoord:GetVec2(),
        point2 = orbitEndPoint:GetVec2(),
        speed = UTILS.KnotsToMps(speed),
        altitude = altitude
      } 
    }

    group:SetTask( orbit, 2 )
  --if distance, we create a waypoint way the fuck out in the boonies
  elseif(distance > 0) then
    local WP1 = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
    :WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
    local WP2 = spawnCoord:Translate(UTILS.NMToMeters(distance),heading * 2)
    :WaypointAir(POINT_VEC3.RoutePointAltType.BARO,POINT_VEC3.RoutePointType.TurningPoint,POINT_VEC3.RoutePointAction.TurningPoint,UTILS.KnotsToKmph(speed),true)
    
    local route = {WP1, WP2}
    group:Route(route)
  else
    env.info("[MARK_SPAWN] We Fucked Up")
  end
  local taskTable = {}
  if(task ~= "NOTHING") then
    taskTable = MLSetTask(task,group)
    group:PushTask ( group:TaskCombo( MLSetTask(task,group) ) , 3 )
  end
  --set group frequency
  if(freq) then
    if(freq <= 20) then
      freq = MLRadioPreset(freq)
    end
    env.info(freq)
    freq = freq * 1000000
    local SetFrequency = { 
      id = 'SetFrequency', 
      params = { 
        frequency = freq, 
        modulation = 0, 
      }
    }
    group:SetCommand(SetFrequency)
  end

 end
  
  function MLGroundSpawn(SpawnTable)
    local type = SpawnTable.type
    local heading = tonumber(SpawnTable.heading) or 000
    local task = SpawnTable.task or "NOTHING"
    local skill = MLSkillCheck(SpawnTable.skill) or "AVERAGE"
    local distance = tonumber(SpawnTable.distance) or 0
    local ROE = SpawnTable.roe or "FREE"
    local freq = tonumber(SpawnTable.freq) or 251
    local speed = tonumber(SpawnTable.speed) or 21
    local form = SpawnTable.formation or nil
    local alert = SpawnTable.alert or "AUTO"
    local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
    local spawner = comparator(type)
    local tgt = nil
    --local tgt = MLCreateTGT(SpawnTable.tgt,SpawnTable.pos)or nil
    if(spawner == nil) then
      return
    end
    local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
    local waypointNameString = SpawnTable.WP or nil
    
    local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
    local coal, country
    if(SpawnTable.side) then
      coal, country = MLSideComparator(SpawnTable.side, template)
    else
      coal = template:GetCoalition()
      country = template:GetCountry()
    end
    

    
    local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
    MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "ground", side = coal}
    MLSetROE(ROE,group)
    MLSetAlarm(alert,group)
    -- LETS DO WAYPOINTS YE JAMMY FOOKERS!
    --if no distance, then we orbit
    if(waypointNameString) then
      local waypointCoords = MLFindWaypoints(waypointNameString)
      env.info('MORE WAYPOINTS')
      local route = {}
      for idx, waypoint in pairs(waypointCoords) do
        route[#route + 1] = waypoint:WaypointGround(UTILS.KnotsToKmph(speed),form)
      end
      group:Route(route)
    elseif(distance > 0) then
      local WP = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
      group:RouteGroundTo(WP, speed, form, 1)
    end
  end
  
function MLNavalSpawn(SpawnTable)
  local type = SpawnTable.type
  local heading = tonumber(SpawnTable.heading) or 000
  local task = SpawnTable.task or "NOTHING"
  local skill = MLSkillCheck(SpawnTable.skill) or "AVERAGE"
  local distance = tonumber(SpawnTable.distance) or 0
  local ROE = SpawnTable.roe or "FREE"
  local freq = tonumber(SpawnTable.freq) or 251
  local speed = tonumber(SpawnTable.speed) or 30
  local form = SpawnTable.formation or nil
  local alert = SpawnTable.alert or "AUTO"
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  local spawner = comparator(type)
  local tgt = nil
  --local tgt = MLCreateTGT(SpawnTable.tgt,SpawnTable.pos) or nil
  if(spawner == nil) then
    return
  end
  local template = GROUP:FindByName( spawner.SpawnTemplatePrefix )
  local waypointNameString = SpawnTable.WP or nil
  
  local spawnCoord = COORDINATE:NewFromVec3(SpawnTable.pos)
  local coal, country
  if(SpawnTable.side) then
    coal, country = MLSideComparator(SpawnTable.side, template)
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end

  local group = spawner:InitSkill(skill):InitCoalition(coal):InitCountry(country):InitHeading(heading):SpawnFromVec3(spawnCoord:GetVec3())
  MLSpawnedGroups[#MLSpawnedGroups + 1] = {group = group, category = "naval", side = coal}

  MLSetROE(ROE,group)
  --MLSetAlarm(alert,group)
  -- LETS DO WAYPOINTS YE JAMMY FOOKERS!
  --if no distance, then we orbit
  if(waypointNameString) then
    local waypointCoords = MLFindWaypoints(waypointNameString)
    env.info('MORE WAYPOINTS')
    local route = {}
    for idx, waypoint in pairs(waypointCoords) do
      route[#route + 1] = waypoint:WaypointGround(UTILS.KnotsToKmph(speed),nil)
    end
    group:Route(route)
  elseif(distance >= 0) then
    local WP = spawnCoord:Translate(UTILS.NMToMeters(distance),heading)
    group:RouteGroundTo(WP, speed, nil, 1)
  end
end
  
function MLRadioSpawn(SpawnTable)
  local song = SpawnTable.song
  local freq = tonumber(SpawnTable.freq) or 251

  local band = SpawnTable.band or "AM"
  if(band == "FM") then
    band = 1
  else
    band = 0
  end
  local power = tonumber(SpawnTable.power) or 1200
  local loop = SpawnTable.loop

  env.info(freq)
  env.info(band)
  env.info(power)

  local radioPositionable = SpawnTable.group
  if(radioPositionable) then

    local pirateRadio = RADIO:New(radioPositionable)
    pirateRadio:NewGenericTransmission(song,freq,band,power,false)
    pirateRadio:Broadcast()
    env.info("[MARK_SPAWN] boobs")
  else
    MLRadio:NewGenericTransmission(song,freq,band,power,false)
    MLRadio:Broadcast()
    env.info("[MARK_SPAWN] tatas")
  end
  

end
  
function comparator (type)
  for idx, val in pairs(spawnerOptions) do
    if string.upper(type) == string.upper(val.txt) then
      env.info("[MARK_SPAWN] Type: " .. type)
      env.info("[MARK_SPAWN] Value: " .. val.txt)
      return val.spawn
    end
  end
  return nil
end

function MLSetROE(ROEString, group)
  local text = string.upper(ROEString)
  if(text == "FREE") then 
    group:OptionROEWeaponFree()
  elseif (text == "RETURN") then
    group:OptionROEReturnFire()
  elseif (text == "HOLD") then
    group:OptionROEHoldFire()
  end
end
  
function MLSetROT(ROTString, group)
  local text = string.upper(ROTString)
  if(text == "EVADE") then
    group:OptionROTEvadeFire()
  elseif (text == "PASSIVE") then
    group:OptionROTPassiveDefense()
  elseif (text == "NONE") then
    group:OptionROTNoReaction()
  end
end
  
function MLSetAlarm(alarmString, group)
  local text = string.upper(alarmString)
  if(text == "GREEN") then 
    group:OptionAlarmStateGreen()
  elseif (text == "RED") then
    group:OptionAlarmStateRed()
  elseif (text == "AUTO") then
    group:OptionAlarmStateAuto()
  end
end

function MLSetTask(TaskString, group)
    local text = string.upper(TaskString)
    local taskTable = {}
  if(text == "CAP") then 
    local EngageTargets = { 
      id = 'EngageTargets', 
      params = { 
        maxDist = UTILS.NMToMeters(40), 
        targetTypes = {"Air"},
        priority = 0 
      } 
    }
    taskTable[1] = EngageTargets
  elseif (text == "REFUELING" or text == "TANKER") then
    local task = group:EnRouteTaskTanker()
    taskTable[1] = task
  elseif (text == "CAS") then
    local EngageTargets = { 
      id = 'EngageTargets', 
      params = { 
        maxDist = UTILS.NMToMeters(25), 
        targetTypes = {"Ground Units","Light armed ships","Helicopters"},
        priority = 0 
      } 
    }
  elseif (text == "SEAD") then
    local EngageTargets = { 
      id = 'EngageTargets', 
      params = {
        maxDist = UTILS.NMToMeters(25), 
        targetTypes = {"Air Defence"},
        priority = 0 
      } 
    }
    taskTable[1] = EngageTargets
  elseif (text == "TASMO") then
    local EngageTargets = { 
      id = 'EngageTargets', 
      params = { 
        maxDist = UTILS.NMToMeters(100), 
        targetTypes = {"Ships"},
        priority = 0 
      } 
    }
    taskTable[1] = EngageTargets
  elseif (text == "AWACS") then
    local task = group:EnRouteTaskAWACS()
    local EPLRS = { 
      id = 'EPLRS', 
      params = { 
        value = true,
      } 
    }
    group:SetCommand(EPLRS)
    taskTable[1] = task
  elseif (text == "AFAC") then
    local task = group:EnRouteTaskFAC(UTILS.NMToMeters(10), 0)
    taskTable[1] = task
  
  end
  
  return taskTable
end
  
  
function MLSideComparator (side, template)
  local coal
  local country = template:GetCountry()
  if(side == "BLUE") then
    coal = coalition.side.BLUE
    if(coal ~= template:GetCoalition()) then
      country = DEFAULT_BLUE_COUNTRY
    end
  elseif(side == "RED") then
    coal =  coalition.side.RED
    if(coal ~= template:GetCoalition()) then
      country = DEFAULT_RED_COUNTRY
    end
  else
    coal = template:GetCoalition()
    country = template:GetCountry()
  end
  
  env.info(coal .. " " .. country)
  return coal, country
end
  
function MLRadioPreset (channel)
  return radioPresets[channel]
end
  
function MLUnfuckMarkPos (pos)
  local newPos = UTILS.DeepCopy(pos)
  local zVal = pos.x
  local xVal = pos.z
  newPos.z = zVal
  newPos.x = xVal
  return newPos
end
  
function MLFindWaypoints(waypointNameList)
  env.info("[MARK_SPAWN] WAYPOINTS MODE TURN ON")
  local waypointNames={}
  local waypointCoords = {}
  --waypoints:gsub("%w*",function(name) table.insert(waypointNames,name) end)
  --for k, v in waypointNameList:gmatch("(%w*)") do
  --  table.insert(waypointNames,k)
  --end
  
  waypointNames = split(waypointNameList,",")
  local allMarks = world.getMarkPanels()
  for idx, name in pairs(waypointNames) do
    for idy, mark in pairs(allMarks) do
      env.info("[MARK_SPAWN] name: " .. name)
      env.info("[MARK_SPAWN] mark: " .. mark.text)
      if string.upper(name) == string.upper(mark.text) then
        waypointCoords[#waypointCoords + 1] = COORDINATE:NewFromVec3(mark.pos)
        break
      end
    end
  end
  return waypointCoords
end
  
function split(s, delimiter)
  local result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end
  
function MLListSpawnOptions(category, mark)
  local messageString = ""
  for idx, value in pairs(spawnerOptions) do
    --list name, role, maybe default coalition
    if(category:upper() == value.category:upper()) then
      local name = value.txt
      local role = value.type
      local defaultCoalition = GROUP:FindByName( value.spawner.SpawnTemplatePrefix ):GetCoalition()
      local coal
      if(defaultCoalition == 1) then coal = "Red" elseif defaultCoalition == 2 then coal = "Blue" else coal = "How the fuck did you make a neutral?" end
      local line = "Name: " .. name .. ", Role: " .. role .. ", Coalition: " .. coal .. "\n"
      messageString = messageString .. line 
    end
  end
  env.info(messageString)
  local DCSUnit = mark.initiator
  if(DCSUnit) then
    --local group = unit:GetGroup()
    local unit = UNIT:Find(DCSUnit)
    local group = unit:GetGroup()
    MESSAGE:New(messageString,30):ToGroup(group)
  else
    local coal = mark.coalition
    env.info(coal)
    MESSAGE:New(messageString,30):ToCoalition(coal)
  end
end
  
function MLDeleteGroup(spawnTable,mark)
  local deleteCMD = spawnTable.cmd:upper()
  env.info("[MARK_SPAWN]" .. deleteCMD)
  local coal = spawnTable.side or "RED"

  local type = spawnTable.category or "ALL"
  type = type:upper()

  local radius =  spawnTable.radius or 5
  radius = UTILS.NMToMeters(radius)
  local template = spawnTable.template or nil

  if template then
    template = template:upper()
  end
  if(coal:upper() == "RED") then coal = 1 else coal = 2 end
  env.info("[MARK_SPAWN] TITS! CMD: " .. deleteCMD .. " SIDE: " .. coal .. " Type: " .. type .. " Radius: " .. radius)


  
  if(deleteCMD == "NAME") then
    env.info("[MARK_SPAWN] DELETE GROUP")
    local groupName = spawnTable.groupName --string.find(deleteCMD, "NAME: (%w+)")
    env.info("[MARK_SPAWN] groupName: " .. groupName)
    local victim = GROUP:FindByName(groupName) or nil
    if victim then
      victim:Destroy(false)
    else
      env.info("[MARK_SPAWN] Delete groupName not found!")
    end
  
  elseif(deleteCMD == "AREA") then
    env.info("[MARK_SPAWN] Doing Radius Stuff")
    local deleteZone = ZONE_RADIUS:New("DeleteZone",COORDINATE:NewFromVec3(mark.pos):GetVec2(),radius)
    env.info("[MARK_SPAWN] Marker Pos: " .. UTILS.OneLineSerialize(mark.pos) .. " Zone Pos: " .. UTILS.OneLineSerialize(deleteZone:GetVec2()) .. "Radius: " .. deleteZone:GetRadius())
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() then 
        local groupPos = entry.group:GetVec2()
        local zoneVec2 = deleteZone:GetVec2()
        local isThere = ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5 <= tonumber(deleteZone:GetRadius())
        env.info("[MARK_SPAWN] BREASTS: " .. ((groupPos.x - zoneVec2.x )^2 + ( groupPos.y - zoneVec2.y ) ^2 ) ^ 0.5)
        if(isThere) then
          env.info("[MARK_SPAWN] Group in zone")
          if(type and (entry.category:upper() == type:upper() or type:upper() == "ALL")) then
          env.info("[MARK_SPAWN] Type correct")
          env.info("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. entry.side)
            if(coal and (entry.side == coal)) then
              env.info("[MARK_SPAWN] Side correct")
              local victim = entry.group
              victim:Destroy(false)
              MLSpawnedGroups[idx] = nil
            end
          end
        else
          env.info("[MARK_SPAWN] Group out of Zone")
        end
      else
        env.info("[MARK_SPAWN] Group omae wa mo shindeiru")
        MLSpawnedGroups[idx] = nil
      end
    end
  elseif(deleteCMD == "NEAREST") then
    env.info("[MARK_SPAWN] Close Stuff")
  local minDistance = -1
  local closest = 1
  local markPos = COORDINATE:NewFromVec3(mark.pos):GetVec2()
  if(MLSpawnedGroups[1].group:IsAlive()) then
    local groupPos = MLSpawnedGroups[1].group:GetVec2()
  minDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5
  for idx, entry in pairs (MLSpawnedGroups) do
        if entry.group:IsAlive() then 
          local groupPos = entry.group:GetVec2()
          local currentDistance = ((groupPos.x - markPos.x )^2 + ( groupPos.y - markPos.y ) ^2 ) ^ 0.5
          if(currentDistance < minDistance) then
      minDistance = currentDistance
      closest = idx
    end
        else
          env.info("[MARK_SPAWN] Group omae wa mo shindeiru")
          MLSpawnedGroups[idx] = nil
        end
      end
  local closestEntry = MLSpawnedGroups[closest]
  if(type and (closestEntry.category:upper() == type:upper() or type:upper() == "ALL")) then
    env.info("[MARK_SPAWN] Type correct")
    env.info("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. closestEntry.side)
    if(coal and (closestEntry.side == coal)) then
      env.info("[MARK_SPAWN] Side correct")
    local victim = closestEntry.group
    victim:Destroy(false)
    MLSpawnedGroups[closest] = nil
      end
  end
  end
  elseif(deleteCMD == "KIND") then
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() and template then 
    if(entry.template == template) then
      if(type and (entry.category:upper() == type:upper() or type:upper() == "ALL")) then
        env.info("[MARK_SPAWN] Type correct")
        env.info("[MARK_SPAWN] Function Side: " .. coal .. "Group Side: " .. entry.side)
        if(coal and (entry.side == coal)) then
          env.info("[MARK_SPAWN] Side correct")
        local victim = entry.group
        victim:Destroy(false)
        MLSpawnedGroups[idx] = nil
          end
    end
        end
      else
        env.info("[MARK_SPAWN] Group omae wa mo shindeiru")
        MLSpawnedGroups[idx] = nil
  end
    end
  elseif(deleteCMD == "ALL") then
    for idx, entry in pairs (MLSpawnedGroups) do
      if entry.group:IsAlive() then
        env.info("[MARK_SPAWN] Side correct")
        local victim = entry.group
        victim:Destroy(false)
        MLSpawnedGroups[idx] = nil
      else
        MLSpawnedGroups[idx] = nil
      end
    end
  end
end
  
function MLWxReport (repoString, mark)
  local qfe = false
  local metric = false
  local options = split(repoString, ",")
  env.info(UTILS.OneLineSerialize(options))
  for idx, option in pairs (options) do
    option = option:gsub("%s+", "")
    env.info(option)
    if(option:upper() == "METRIC") then
      metric = true
    elseif(option:upper() == "QFE") then
      qfe = true
    end
  end
  
  local wxPos = COORDINATE:NewFromVec3(MLUnfuckMarkPos(mark.pos))
  local heading, windSpeedMPS = wxPos:GetWind(wxPos:GetLandHeight())
  heading = _Heading(heading + 180)
  local windSpeedKnots = UTILS.MpsToKnots(windSpeedMPS)
  local temperature = wxPos:GetTemperature()
  
  local pressure_hPa,pressure_inHg
  if(qfe) then
    pressure_hPa = wxPos:GetPressure(wxPos:GetLandHeight())
  else
    pressure_hPa = wxPos:GetPressure(0)
  end
  pressure_inHg = pressure_hPa * 0.0295299830714
  env.info(pressure_hPa .. ", " .. pressure_inHg)
  
  local coal
  if(mark.initiator) then
    coal = UNIT:Find(mark.initiator):GetGroup():GetCoalition()
  else
    coal = mark.coalition
  end

  local msg = ""
  if(metric) then
    msg = msg .. string.format("Wind is from %3d Degrees at %3d Mps\n",windSpeedMPS,heading)
    if(qfe) then
      msg = msg .. string.format("QFE is %4.2f hPa\n", pressure_hPa)
    else
      msg = msg .. string.format("QNH is %4.2f hPa\n", pressure_hPa)
    end
  else
    msg = msg .. string.format("Wind is from %3d Degrees at %3d Knots\n",windSpeedKnots,heading)
    if(qfe) then
      msg = msg .. string.format("QFE is %4.2f inHg\n", pressure_inHg)
    else
      msg = msg .. string.format("QNH is %4.2f inHg\n", pressure_inHg)
    end
  end
  msg = msg .. string.format("Temperature is %3d Degrees C", temperature)
  wxPos:MarkToCoalition(msg,coal,false,nil)
end
  
      
function deleteDeterminator(stringCompare, considerCoal, entry)
  if(stringCompare) then
    if(considerCoal) then
      if(considerCoal == entry.group:GetCoalition()) then
        --env.info("[MARK_SPAWN] string/coal compare pass")
        return true
      else
        --env.info("[MARK_SPAWN] Coal compare fail")
        return false
      end
    else
      --env.info("[MARK_SPAWN] String Compare, no coalition")
      return true
    end
  else
    -- env.info("[MARK_SPAWN] String Compare Fail")
    return false  
  end
end
  
function magVarDeterminator()
  local magVar = 0
  local theater = env.mission.theatre
  if(theater == "Caucasus") then
    --is Georgia
    magVar = -6
  elseif(theater == "Nevada") then
    --is Nevada
    magVar = -12
  elseif(theater == "Normandy") then
    --is Normandy
    magVar = 2
  elseif(theater == "PersianGulf") then
    --is Persian Gulf
    magVar = -2
  else
    magVar = 0
  end
  return magVar
end
  
--stolen from moose, cred to them
function _Heading(course)
  local h
  if course<=180 then
    h=math.rad(course)
  else
    h=-math.rad(360-course)
  end
  return h 
end
  
function MLSkillCheck(skill)
  if(skill == nil) then
    return nil
  end

  skill = skill:upper()
  if(skill == "AVERAGE") then
    return skill
  elseif(skill == "NORMAL") then
    return skill
  elseif(skill == "GOOD") then
    return skill
  elseif(skill == "HIGH") then
    return skill
  elseif(skill == "EXCELLENT") then
    return skill
  elseif(skill == "RANDOM") then
    return skill
  else
    return nil
  end

end
  
function MLRemoveMark (markId)
  local allMarks = world.getMarkPanels()
  for idx, mark in pairs(allMarks) do
    if markId == mark.idx then
      trigger.action.removeMark(markId)
      allMarks[idx] = nil
      return
    end
  end
end
  
function MLCreateTGT(tgtName,pos,radius)
  local tgt = {}
  tgt.name = tgtName
  tgt.pos = pos
  tgt.radius = radius or 100
  tgt.zone = ZONE_RADIUS:New( tgtName .. "Zone", COORDINATE:NewFromVec3(SpawnTable.pos):GetVec2(), tgt.radius )
  tgt.units = MLPopulateTGT(tgt)
  MLTgtArrayAdd(tgt)
end
  
function MLPopulateTGT(tgt)
  local zone = tgt.zone
  local curratedUnits
  zone:scan(1)
  local units = zone:GetScannedUnits()
  env.info(UTILS.OneLineSerialize(units))
  for idx, unit in pairs(units) do
    local unitCategory = unit:GetDCSObject():GetCategory()
    if(unitCategory == "UNIT") then
      local unitSensors = unit:GetDCSObject():getSensors()
      local hasRadar = false
      for idx, sensor in pairs(unitSensors) do
        if(sensor.type == 1) then
          hasRadar = true
        end
      end
      if(hasRadar and unit:IsAlive()) then
        curratedUnits:insert({unit = unit, radarUnit = true})
      end
    elseif(unitCategory == "FORTIFICATION" and unit:IsAlive()) then
      curratedUnits:insert({unit = unit, structure = true})
    end
  end
    
  return curratedUnits
end
  
function MLReturnTGT(tgt)
  
end
  
function MLTgtArrayAdd(tgt)
  MLTgtArray:insert(tgt)
  if(#MLTgtArray > 5) then
    table.remove(MLTgtArray, 1)
  end
end
  
function MLTgtArrayRemove(tgt)
end

--[[
s = "MLCMD SPAWN: MIG27, ALT: 180, HDG: 180, TASK: CAP, SKILL: GOOD"
_, _, value, value2 , value3 = string.find(s, "SPAWN:%s(%w*)")
print(value, value2, value3)
_, _, value = string.find(s, "HDG: (%d+)")
print(value)
  ]]

--- END MARK SPAWN