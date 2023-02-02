-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN SUPPORT AIRCRAFT SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- define table of respawning support aircraft ---
local TableSpawnSupport = { -- {spawnobjectname, spawnzone, callsignName, callsignNumber}
  {
    spawnobject     = "AR230V_KC-135_01", 
    spawnzone       = "AR230V", 
    callsignName    = 2, 
    callsignNumber  = 1
  },
  {
    spawnobject     = "AR230V_KC-130J_01", 
    spawnzone       = "AR230V", 
    callsignName    = 2, 
    callsignNumber  = 3
  },
  {
    spawnobject     = "AR635_KC-135_01", 
    spawnzone       = "AR635", 
    callsignName    = 1,
    callsignNumber  = 2
  },
 {
   spawnobject     = "XX_AR625_KC-135_01", -- remove XX_ to reactivate
   spawnzone       = "AR625", 
   callsignName    = 1,
   callsignNumber  = 3
 },
  {
    spawnobject     = "AR641A_KC-135_01", 
    spawnzone       = "AR641A", 
    callsignName    = 1,
    callsignNumber  = 1
  },
  {
    spawnobject     = "AR635_KC-135MPRS_01", 
    spawnzone       = "AR635", 
    callsignName    = 3,
    callsignNumber  = 2
  },
 {
   spawnobject     = "XX_AR625_KC-135MPRS_01", -- remove XX_ to reactivate
   spawnzone       = "AR625", 
   callsignName    = 3,
   callsignNumber  = 3
 },
  {
    spawnobject     = "AR641A_KC-135MPRS_01", 
    spawnzone       = "AR641A", 
    callsignName    = 3,
    callsignNumber  = 1
  },
  {
    spawnobject    = "ARLNS_KC-135MPRS_01", 
    spawnzone       = "ARLNS", 
    callsignName    = 3,
    callSignNumber  = 3
  },
  {
    spawnobject    = "ARLNS_KC-135_01", 
    spawnzone       = "ARLNS", 
    callsignName    = 1,
    callSignNumber  = 3
  },
  {
    spawnobject     = "AWACS_DARKSTAR", 
    spawnzone       = "AWACS", 
    callsignName    = 5, 
    callsignNumber  = 1
  },
}

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone, callsignName, callsignNumber
  if GROUP:FindByName(SupportSpawn.spawnobject) then
    local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )
    SupportSpawnObject:InitLimit( 1, 0 )
      :OnSpawnGroup(
        function ( SpawnGroup )
          --SpawnGroup:CommandSetCallsign(SupportSpawn.callsignName, SupportSpawn.callsignNumber)
          local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
          local CheckTanker = SCHEDULER:New( nil, 
            function ()
              if SpawnGroup then
                if SpawnGroup:IsNotInZone( ZONE:FindByName(SupportSpawn.spawnzone) ) then
                  SupportSpawnObject:ReSpawn( SpawnIndex )
                  BASE:T("[JTF-1][SUPPORTSPAWN] Spawned aircraft: " .. SpawnGroup:GetName() .. " is not in zone.")
                end
              end
            end,
            {}, 0, 60 
          )
        end
      )
      :InitKeepUnitNames(true)
      :InitRepeatOnLanding()
      :Spawn()
    BASE:T("[JTF-1][SUPPORTSPAWN] Spawned " .. SupportSpawn.spawnobject)
  else
    BASE:E("[JTF-1] Function SpawnSupport: spawn template not found in mission: " .. tostring(SupportSpawn.spawnobject))
  end
end

-- spawn support aircraft ---
for i, v in ipairs( TableSpawnSupport ) do
  SpawnSupport ( v )
end

--- END SUPPORT AIRCRAFT SECTION