env.info( '*** JTF-1 NTTR Fun Map MOOSE script ***' )
env.info( '*** JTF-1 MOOSE MISSION SCRIPT START ***' )

_SETTINGS:SetPlayerMenuOff()

-- BEGIN FUNCTIONS SECTION

function SpawnSupport (SupportSpawn) -- spawnobject, spawnzone

  --local SupportSpawn = _args[1]
  local SupportSpawnObject = SPAWN:New( SupportSpawn.spawnobject )

  SupportSpawnObject:InitLimit( 1, 50 )
    :OnSpawnGroup(
      function ( SpawnGroup )
        local SpawnIndex = SupportSpawnObject:GetSpawnIndexFromGroup( SpawnGroup )
        local CheckTanker = SCHEDULER:New( nil, 
        function()
          if SpawnGroup:IsNotInZone( SupportSpawn.spawnzone ) then
            SupportSpawnObject:ReSpawn( SpawnIndex )
          end
        end,
        {}, 0, 60 )
      end
    )
    :InitRepeatOnEngineShutDown()
    :Spawn()


end -- function

-- END FUNCTIONS SECTION

-- BEGIN SUPPORT AIRCRAFT SECTION

----------------------------------------------------
--- define table of respawning support aircraft ---
----------------------------------------------------

TableSpawnSupport = { -- {spawnobjectname, spawnzone}
	{spawnobject = "AR230V_KC-130_01", spawnzone = ZONE:FindByName("AR230V")},
	{spawnobject = "AR231V_KC-130_01", spawnzone = ZONE:FindByName("AR231V")},
	{spawnobject = "AR635_KC-135_01", spawnzone = ZONE:FindByName("AR635")},
	{spawnobject = "AR641A_KC135_01", spawnzone = ZONE:FindByName("AR641A")},
	{spawnobject = "AR635_KC-135MPRS_01", spawnzone = ZONE:FindByName("AR635")},
	{spawnobject = "AR641A_KC135MPRS_01", spawnzone = ZONE:FindByName("AR641A")},
	{spawnobject = "AWACS_DARKSTAR", spawnzone = ZONE:FindByName("AWACS")},
}

------------------------------
--- spawn support aircraft ---
------------------------------

for i, v in ipairs( TableSpawnSupport ) do
	SpawnSupport ( v )
	
end

-- END SUPPORT AIRCRAFT SECTION


-- BEGIN RANGE SECTION

-- RANGE R61B

Range_R61B = RANGE:New("Range 61B")

Range_R61B:SetRangeZone(ZONE_POLYGON:FindByName("R61B"))

Range_R61B:AddBombingTargetGroup(GROUP:FindByName("61-01"))
Range_R61B:AddBombingTargetGroup(GROUP:FindByName("61-03"))

local bombtarget_R61B = {
	"61-01 Aircraft #001", 
	"61-01 Aircraft #002", 
}
Range_R61B:AddBombingTargets( bombtarget_R61B )

Range_R61B:SetSoundfilesPath("Range Soundfiles/")
Range_R61B:SetRangeControl(341.925)

Range_R61B:Start()

-- END RANGE 61B

-- RANGE R62A

Range_R62A = RANGE:New("Range 62A")

Range_R62A:SetRangeZone(ZONE_POLYGON:FindByName("R62A"))

Range_R62A:AddBombingTargetGroup(GROUP:FindByName("62-01"))
Range_R62A:AddBombingTargetGroup(GROUP:FindByName("62-02"))
Range_R62A:AddBombingTargetGroup(GROUP:FindByName("62-04"))

Range_R62A:SetSoundfilesPath("Range Soundfiles/")
Range_R62A:SetRangeControl(234.250)

Range_R62A:Start()

-- END RANGE R62A

-- RANGE R62B

Range_R62B = RANGE:New("Range 62B")

Range_R62B:SetRangeZone(ZONE_POLYGON:FindByName("R62B"))

Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-03"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-08"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-09"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-11"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-12"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-13"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-14"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-21"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-21-01"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-22"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-31"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-32"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-41"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-42"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-43"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-44"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-45"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-51"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-52"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-53"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-54"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-55"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-56"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-61"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-62"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-63"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-71"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-72"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-73"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-74"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-75"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-76"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-77"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-78"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-79"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-81"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-83"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-91"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-92"))
Range_R62B:AddBombingTargetGroup(GROUP:FindByName("62-93"))

local bombtarget_R62B = {
	"62-32-01", 
	"62-32-02", 
	"62-32-03", 
}
Range_R62B:AddBombingTargets( bombtarget_R62B )

Range_R62B:SetSoundfilesPath("Range Soundfiles/")
Range_R62B:SetRangeControl(234.250)

Range_R62B:Start()

-- T6208 moving strafe targets
MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, function() trigger.action.setUserFlag(62081, 1) end) 
MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, function() trigger.action.setUserFlag(62082, 1) end) 
MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, function() trigger.action.setUserFlag(62083, 1) end) 

-- END RANGE R62B

-- RANGE R63B (CLASS A)

Range_R63B = RANGE:New("Range 63B")

Range_R63B:SetRangeZone(ZONE_POLYGON:FindByName("R63B"))

Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-01"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-02"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-03"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-05"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-10"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-12"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("63-15"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("R-63B Class A Range-01"))
Range_R63B:AddBombingTargetGroup(GROUP:FindByName("R-63B Class A Range-02"))

local FoulDist_R63B_Strafe = Range_R63B:GetFoullineDistance("R63B Strafe Lane L1", "R63B Foul Line Left")

local Strafe_R63B_West = {
	"R63B Strafe Lane L1",
	"R63B Strafe Lane L2",
	"R63B Strafe Lane L3",
}
Range_R63B:AddStrafePit(Strafe_R63B_West, 3000, 300, nil, true, 20, FoulDist_R63B_Strafe)

local Strafe_R63B_East = {
	"R63B Strafe Lane R1",
	"R63B Strafe Lane R2",
	"R63B Strafe Lane R3",
}
Range_R63B:AddStrafePit(Strafe_R63B_East, 3000, 300, nil, true, 20, FoulDist_R63B_Strafe)

local bombtarget_R63B = {
	"R63BWC",
	"R63BEC",	
}
Range_R63B:AddBombingTargets( bombtarget_R63B )


Range_R63B:SetSoundfilesPath("Range Soundfiles/")
Range_R63B:SetRangeControl(234.250)

Range_R63B:Start()

-- END RANGE R63B


-- RANGE R64A

Range_R64A= RANGE:New("Range R64A")

Range_R64A:SetRangeZone(ZONE_POLYGON:FindByName("R64A"))

Range_R64A:AddBombingTargetGroup(GROUP:FindByName("64-10"))
Range_R64A:AddBombingTargetGroup(GROUP:FindByName("64-11"))

local bombtarget_R64A = {
	"64-12-05", 
}
Range_R64A:AddBombingTargets( bombtarget_R64A )

Range_R64A:SetSoundfilesPath("Range Soundfiles/")
Range_R64A:SetRangeControl(341.925)

Range_R64A:Start()

-- END RANGE 64A

-- RANGE R64B

Range_R64B= RANGE:New("Range R64B")

Range_R64B:SetRangeZone(ZONE_POLYGON:FindByName("R64B"))

Range_R64B:AddBombingTargetGroup(GROUP:FindByName("64-13"))
Range_R64B:AddBombingTargetGroup(GROUP:FindByName("64-14"))
Range_R64B:AddBombingTargetGroup(GROUP:FindByName("64-17"))
Range_R64B:AddBombingTargetGroup(GROUP:FindByName("64-19"))
Range_R64B:AddBombingTargetGroup(GROUP:FindByName("64-15"))

Range_R64B:SetSoundfilesPath("Range Soundfiles/")
Range_R64B:SetRangeControl(341.925)

Range_R64B:Start()

-- END RANGE 64B


-- Range R64C

Range_R64C = RANGE:New("Range 64C")

Range_R64C:SetRangeZone(ZONE_POLYGON:FindByName("R64C"))

Range_R64C:AddBombingTargetGroup(GROUP:FindByName("64-05"))
Range_R64C:AddBombingTargetGroup(GROUP:FindByName("64-08"))
Range_R64C:AddBombingTargetGroup(GROUP:FindByName("64-09"))

local FoulDist_R64C_Strafe = Range_R64C:GetFoullineDistance("R64C Strafe Lane L1", "R64C Strafe Foul Line L1")

local Strafe_R64C_West = {
	"R64C Strafe Lane L1",
	"R64C Strafe Lane L2",
	"R64C Strafe Lane L3",
}
Range_R64C:AddStrafePit(Strafe_R64C_West, 3000, 300, nil, true, 20, FoulDist_R64C_Strafe)

local Strafe_R64C_East = {
	"R64C Strafe Lane R1",
	"R64C Strafe Lane R2",
	"R64C Strafe Lane R3",
}
Range_R64C:AddStrafePit(Strafe_R64C_East, 3000, 300, nil, true, 20, FoulDist_R64C_Strafe)

local bombtarget_R64C = {
	"R64CWC", 
	"R64CEC", 
	"R-64C Class A Range-01", 
	"R-64C Class A Range-02", 
	}
Range_R64C:AddBombingTargets( bombtarget_R64C )

Range_R64C:SetSoundfilesPath("Range Soundfiles/")
Range_R64C:SetRangeControl(288.800)

Range_R64C:Start()

-- END Range R64C

-- RANGE R65C

Range_R65C = RANGE:New("Range R65C")

Range_R65C:SetRangeZone(ZONE_POLYGON:FindByName("R65C"))

Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-01"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-02"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-03"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-04"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-05"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-06"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-07"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-08"))
Range_R65C:AddBombingTargetGroup(GROUP:FindByName("65-11"))

Range_R65C:SetSoundfilesPath("Range Soundfiles/")
Range_R65C:SetRangeControl(225.45)

Range_R65C:Start()

-- END RANGE R65C

-- RANGE R65D

Range_R65D = RANGE:New("Range R65D")

Range_R65D:SetRangeZone(ZONE_POLYGON:FindByName("R65D"))

Range_R65D:AddBombingTargetGroup(GROUP:FindByName("65-10"))

Range_R65D:SetSoundfilesPath("Range Soundfiles/")
Range_R65D:SetRangeControl(225.45)

Range_R65D:Start()

-- END RANGE R65D

-- END RANGE SECTION

-- BEGIN ACM/BFM SECTION

-- BFM/ACM Zones
BoxZone = ZONE_POLYGON:New( "Polygon_Box", GROUP:FindByName("zone_box") )
BfmAcmZone = ZONE_POLYGON:New( "Polygon_BFM_ACM", GROUP:FindByName("COYOTEABC") )
BfmAcmZoneFox = ZONE:FindByName("BfmAcmZoneProtected")

-- MISSILE TRAINER

-- Create a new missile trainer object.
fox=FOX:New()

-- Add training zones.
fox:AddSafeZone(BfmAcmZoneFox)
fox:AddLaunchZone(BfmAcmZoneFox)
fox:SetDisableF10Menu()

-- Start missile trainer.
fox:Start()

-- Spawn Objects
AdvA4 = SPAWN:New( "ADV_A4" )		
Adv28 = SPAWN:New( "ADV_MiG28" )	
Adv27 = SPAWN:New( "ADV_Su27" )
Adv23 = SPAWN:New( "ADV_MiG23" )
Adv16 = SPAWN:New( "ADV_F16" )
Adv18 = SPAWN:New( "ADV_F18" )

-- will need to pass function caller (from menu) to each of these spawn functions.  
-- Then calculate spawn position/velocity relative to caller
function SpawnAdv(adv,qty,group,rng)
	range = rng * 1852
	hdg = group:GetHeading()
	pos = group:GetPointVec2()
	spawnPt = pos:Translate(range, hdg, true)
	spawnVec3 = spawnPt:GetVec3()
	if BoxZone:IsVec3InZone(spawnVec3) then
		MESSAGE:New("Cannot spawn adversary in The Box.\nChange course or increase your range from The Box, and try again."):ToGroup(group)
	else
		adv:InitGrouping(qty):InitHeading(hdg + 180):SpawnFromVec3(spawnVec3)
		MESSAGE:New("Adversary spawned."):ToGroup(group)
	end
end

function BuildMenuCommands (AdvMenu, MenuGroup, MenuName, BfmMenu, AdvType, AdvQty)

	_G[AdvMenu] = MENU_GROUP:New( MenuGroup, MenuName, _G[BfmMenu])
		_G[AdvMenu .. "_rng5"] = MENU_GROUP_COMMAND:New( MenuGroup, "5 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 5)
		_G[AdvMenu .. "_rng10"] = MENU_GROUP_COMMAND:New( MenuGroup, "10 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 10)
		_G[AdvMenu .. "_rng20"] = MENU_GROUP_COMMAND:New( MenuGroup, "20 nmi", _G[AdvMenu], SpawnAdv, AdvType, AdvQty, MenuGroup, 20)

end

function BuildMenus(AdvQty, MenuGroup, MenuName, SpawnBfm)

	local AdvSuffix = "_" .. tostring(AdvQty)
	local BfmMenu = "SpawnBfm" .. AdvSuffix

	_G[BfmMenu] = MENU_GROUP:New( MenuGroup, MenuName, SpawnBfm)
	
		BuildMenuCommands("SpawnBfmA4menu" .. AdvSuffix, MenuGroup, "Adversary A-4", BfmMenu, AdvA4, AdvQty)
		BuildMenuCommands("SpawnBfm28menu" .. AdvSuffix, MenuGroup, "Adversary MiG-28", BfmMenu, Adv28, AdvQty)
		BuildMenuCommands("SpawnBfm23menu" .. AdvSuffix, MenuGroup, "Adversary MiG-23", BfmMenu, Adv23, AdvQty)
		BuildMenuCommands("SpawnBfm27menu" .. AdvSuffix, MenuGroup, "Adversary Su-27", BfmMenu, Adv27, AdvQty)
		BuildMenuCommands("SpawnBfm16menu" .. AdvSuffix, MenuGroup, "Adversary F-16", BfmMenu, Adv16, AdvQty)
		BuildMenuCommands("SpawnBfm18menu" .. AdvSuffix, MenuGroup, "Adversary F-18", BfmMenu, Adv18, AdvQty)		
			
end
-- CLIENTS
BLUFOR = SET_GROUP:New():FilterCoalitions( "blue" ):FilterStart()

-- SPAWN AIR MENU
local SetClient = SET_CLIENT:New():FilterCoalitions("blue"):FilterStart()

local function MENU()
	SetClient:ForEachClient(function(client)
		if (client ~= nil) and (client:IsAlive()) then 
 
			local group = client:GetGroup()
			local groupName = group:GetName()
			if (group:IsCompletelyInZone(BfmAcmZone)) then
				if SpawnBfm == nil then
					MenuGroup = group
					MenuGroupName = MenuGroup:GetName()

					SpawnBfm = MENU_GROUP:New( MenuGroup, "AI BFM/ACM" )
						
						BuildMenus(1, MenuGroup, "Single", SpawnBfm)
						BuildMenus(2, MenuGroup, "Pair", SpawnBfm)



					MESSAGE:New("You have entered the BFM/ACM zone.\nUse F10 menu to spawn adversaries."):ToGroup(group)
					env.info("BFM/ACM entry Player name: " ..client:GetPlayerName())
					env.info("BFM/ACM entry Group Name: " ..group:GetName())
				end
				--SetClient:Remove(client:GetName(), true)
			elseif SpawnBfm ~= nil then
				SpawnBfm:Remove()
				SpawnBfm = nil
				MESSAGE:New("You have left the ACM/BFM zone."):ToGroup(group)
				env.info("BFM/ACM exit Group Name: " ..group:GetName())
			end
		end
	end)
timer.scheduleFunction(MENU,nil,timer.getTime() + 5)
end

MENU()

-- END ACM/BFM SECTION



env.info( '*** JTF-1 MOOSE MISSION SCRIPT END ***' )