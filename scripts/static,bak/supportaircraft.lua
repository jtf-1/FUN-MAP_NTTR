-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN SUPPORT AIRCRAFT SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Support Aircraft

-- Spawn support aircraft (tankers, awacs) at zone markers placed in the mission editor.

-- In the mission editor, place a zone where you want the support aircraft to spawn.
-- Under SUPPORTAC.missions, add a config block for the aircraft you intend to spawn.
-- See the comments in the example block for explanations of each config option.

SUPPORTAC = {}

SUPPORTAC.defaults = {
  radio = 251, -- default radio freq the ac will use when not on mission
  activateDelay = 10, -- delay, in seconds, after the previous ac has despawned before the new ac will be activated 
  despawnDelay = 120, -- delay, in seconds, before the old ac will be despawned
  tankerLeg = 50, -- default tanker racetrack leg length
  awacsLeg = 70, -- default awacs racetrack leg length
  fuelLowThreshold = 0, -- default fuel low level to trigger RTB
}

SUPPORTAC.categories = {
  tanker = 1,
  awacs = 2,
}

SUPPORTAC.type = {
  tankerBoom = "KC-135", -- template to be used for trype = "tankerBoom"
  tankerProbe = "KC-135MPRS", -- template to be used for type = "tankerProbe"
  tankerProbeC130 = "KC-130", -- template for type = "tankerProbeC130"
  tankerProbeC130J = "KC-130J", -- template for type = "tankerProbeC130J"
  awacsE3a = "AWACS-E3A", -- template to be used for type = "awacsE3a"
}

-- inherit everything from BASE class
SUPPORTAC = BASE:Inherit(SUPPORTAC, BASE:New()) -- #SUPPORTAC

-- function to create new support mission and flightGroup
function SUPPORTAC:NewMission(mission, initDelay)
  _msg = string.format("[SUPPORTAC] Create new mission for %s", mission.name)
  SUPPORTAC:T(_msg)
  local newMission = {}

  -- find mission ZONE
  local missionZone = ZONE:FindByName(mission.zone)
  local missionCoordinate = missionZone:GetCoordinate()
  local missionAltitude = mission.flightLevel * 100
  local missionSpeed = mission.speed
  local missionHeading = mission.heading
  local missionLeg = mission.leg

  -- create new mission
  if mission.category == SUPPORTAC.categories.tanker then
    newMission = AUFTRAG:NewTANKER(
      missionCoordinate, 
      missionAltitude, 
      missionSpeed, 
      missionHeading, 
      missionLeg
      )
    _msg = string.format("[SUPPORTAC] New mission created: %s", newMission:GetName())
    newMission:T(_msg)
  elseif mission.category == SUPPORTAC.categories.awacs then
    newMission = AUFTRAG:NewAWACS(
      missionCoordinate,
      missionAltitude,
      missionSpeed,
      missionHeading,
      missionLeg
    )
    _msg = string.format("[SUPPORTAC] New mission created: %s", newMission:GetName())
    newMission:T(_msg)
  else
    _msg = "[SUPPORTAC] Mission category not defined!"
    SUPPORTAC:E(_msg)
  end

  if mission.tacan ~= nil then
    newMission:SetTACAN(mission.tacan, mission.tacanid)
  end
  newMission:SetRadio(mission.radio)

  local despawnDelay = SUPPORTAC.defaults.despawnDelay
  local activateDelay = SUPPORTAC.defaults.activateDelay + despawnDelay

  if initDelay then
    activateDelay = initDelay
  end

  -- create new flightgroup template
  -- spawn location
  local spawnAltitude = UTILS.FeetToMeters(mission.flightLevel * 100)
  local spawnZone = ZONE:FindByName(mission.zone)
  local spawnZoneCoordinate = spawnZone:GetCoordinate()
  local spawnVec3 = spawnZoneCoordinate:GetVec3()
  spawnVec3.y = spawnAltitude
  
  -- spawn new group
  local spawnGroup = mission.missionSpawn:SpawnFromVec3(spawnVec3)
  _msg = string.format("[SUPPORTAC] New group spawned: %s", spawnGroup:GetName())
  spawnGroup:T(_msg)

  -- create new flightGroup
  local flightGroup = FLIGHTGROUP:New(spawnGroup)
    :SetDefaultCallsign(mission.callsign, mission.callsignNumber)
    :SetDefaultRadio(SUPPORTAC.defaults.radio)
    :SetDefaultAltitude(mission.flightLevel * 100)
    :SetDefaultSpeed(mission.speed) -- mission.speed + (mission.flightLevel / 2)
    :Activate(activateDelay)

  -- function call after flightGroup is spawned
  -- assign mission to new ac
  function flightGroup:OnAfterSpawned()
    _msg = string.format("[SUPPORTAC] Flightgroup %s activated.", self:GetName())
    self:T(_msg)
    -- assign mission to flightGroup
    self:AddMission(newMission)
  end

  -- function called after flightGroup starts mission
  -- set RTB criteria
  function flightGroup:OnAfterMissionStart()
    self:SetFuelLowRTB()
    self:SetFuelLowRefuel(false)
    if mission.fuelLowThreshold > 0 then
      self:SetFuelLowThreshold(mission.fuelLowThreshold) -- tune fuel RTB trigger for each support mission
    end
  end

  -- function called after a flightGroup RTBs
  -- spawn a replacement for the current aircraft when it RTBs
  function flightGroup:OnAfterRTB(From, Event, To, airbase)
    local _msg = string.format("[SUPPORTAC] Group %s is RTB to %s",  self:GetName(), airbase:GetName())
    self:T(_msg)
    -- set flightgroup RTB flag
    self.isRTB = true
    -- send RTB advisory message
    local msgText = string.format("All players, %s is RTB. A new aircraft will be on station shortly.", self.group:GetCustomCallSign(true))
    local msgFreq = self:GetRadio()
    SUPPORTAC:SendMessage(msgText, msgFreq) --SUPPORTAC:SendMessage(msgText, msgFreq)
    -- turn off the flightgroup's TACAN
    self:TurnOffTACAN()
    -- cancel the flightgroup's auftrag then despawn it 
    local currentMission = self:GetMissionCurrent()
    currentMission:Cancel()
    self:Despawn(despawnDelay, true)
    -- create a new mission to replace the departing support aircraft 
    SUPPORTAC:NewMission(mission)
  end

  -- function called if the mission has failed
  -- trap mission fails (eg someone kills a tanker) as they might not trigger a replacement aircraft
  function newMission:OnAfterFailed(From, Event, To)
    local _msg = string.format("[SUPPORTAC] Mission failed with event: %s", Event)
    -- if the mission fails before the flightGroup RTBs create a new support mission
    if not flightGroup.isRTB then
      SUPPORTAC:NewMission(mission)
    end
  end

end

function SUPPORTAC:SendMessage(msgText, msgFreq)
  _msg = string.format("[SUPPORTAC] SendMessage: %s", msgText)
  self:T(_msg)

  if MISSIONSRS.Radio then
    MISSIONSRS:SendRadio(msgText, msgFreq)
  else
    MESSAGE:New(msgText):ToAll()
  end

end  

-- step through SUPPORTAC.aircraft
for index, mission in ipairs(SUPPORTAC.missions) do

  if BASE:IsTrace() or SUPPORTAC:IsTrace() then
      if ZONE:FindByName(mission.zone) then
      -- draw mission zone on map
      ZONE:FindByName(mission.zone):DrawZone()
    else
      _msg = string.format("[SUPPORTAC] DrawZone - Zone %s not found!", mission.zone)
      SUPPORTAC:E(_msg)
    end
  end

  -- set spawn prefix unique to support mission
  local missionSpawnAlias = string.format("M%02d_%s_%s", index, mission.name, mission.type)
  local missionSpawnTemplate = mission.type
  -- create mission spawn template
  mission.missionSpawn = SPAWN:NewWithAlias(missionSpawnTemplate, missionSpawnAlias)
    :InitLateActivated()
    :InitHeading(mission.heading)
  -- create new mission
  SUPPORTAC:NewMission(mission, 0) -- create new mission with specified delay to flightgroup activation

end

-- END SUPPORT AIRCRAFT SECTION