------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN ACM/BFM SECTION
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


local BFMACM = {}
BFMACM.Menu = {}
BFMACM.SetClient = SET_CLIENT:New():FilterStart()

-- BFM/ACM Zones
BFMACM.BoxZone  = ZONE_POLYGON:New( "Polygon_Box", GROUP:FindByName("zone_box") )
BFMACM.ZoneMenu = ZONE_POLYGON:New( "Polygon_BFM_ACM", GROUP:FindByName("COYOTEABC") )
BFMACM.ExitZone = ZONE:FindByName("Zone_BfmAcmExit")
BFMACM.Zone     = ZONE:FindByName("Zone_BfmAcmFox")

-- Spawn Objects
AdvF4 = SPAWN:New( "ADV_F4" )   
Adv28 = SPAWN:New( "ADV_MiG28" )  
Adv27 = SPAWN:New( "ADV_Su27" )
Adv23 = SPAWN:New( "ADV_MiG23" )
Adv16 = SPAWN:New( "ADV_F16" )
Adv18 = SPAWN:New( "ADV_F18" )

function BFMACM.BfmSpawnAdv(adv,qty,group,rng,unit)

  playerName = (unit:GetPlayerName() and unit:GetPlayerName() or "Unknown") 
  range = rng * 1852
  hdg = unit:GetHeading()
  pos = unit:GetPointVec2()
  spawnPt = pos:Translate(range, hdg, true)
  spawnVec3 = spawnPt:GetVec3()
  if BFMACM.BoxZone:IsVec3InZone(spawnVec3) then
    MESSAGE:New(playerName .. " - Cannot spawn adversary aircraft in The Box.\nChange course or increase your range from The Box, and try again."):ToGroup(group)
  else
    adv:InitGrouping(qty)
      :InitHeading(hdg + 180)
      :OnSpawnGroup(
        function ( SpawnGroup )
          local CheckAdversary = SCHEDULER:New( SpawnGroup, 
          function (CheckAdversary)
            if SpawnGroup then
              if SpawnGroup:IsNotInZone( BFMACM.ZoneMenu ) then
                MESSAGE:New("Adversary left BFM Zone and was removed!"):ToAll()
                SpawnGroup:Destroy()
                SpawnGroup = nil
              end
            end
          end,
          {}, 0, 5 )
        end
      )
      :SpawnFromVec3(spawnVec3)
    MESSAGE:New(playerName .. " has spawned Adversary."):ToGroup(group)
  end

end

function BFMACM.BfmBuildMenuCommands (AdvMenu, MenuGroup, MenuName, BfmMenu, AdvType, AdvQty, unit)

  BFMACM[AdvMenu] = MENU_GROUP:New( MenuGroup, MenuName, BfmMenu)
    BFMACM[AdvMenu .. "_rng5"] = MENU_GROUP_COMMAND:New( MenuGroup, "5 nmi", BFMACM[AdvMenu], BFMACM.BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 5, unit)
    BFMACM[AdvMenu .. "_rng10"] = MENU_GROUP_COMMAND:New( MenuGroup, "10 nmi", BFMACM[AdvMenu], BFMACM.BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 10, unit)
    BFMACM[AdvMenu .. "_rng20"] = MENU_GROUP_COMMAND:New( MenuGroup, "20 nmi", BFMACM[AdvMenu], BFMACM.BfmSpawnAdv, AdvType, AdvQty, MenuGroup, 20, unit)

end

function BfmBuildMenus(AdvQty, MenuGroup, MenuName, SpawnBfmGroup, unit)

  local AdvSuffix = "_" .. tostring(AdvQty)
  BfmMenu = MENU_GROUP:New(MenuGroup, MenuName, SpawnBfmGroup)
    BFMACM.BfmBuildMenuCommands("SpawnBfmA4menu" .. AdvSuffix, MenuGroup, "Adversary A-4", BfmMenu, AdvF4, AdvQty, unit)
    BFMACM.BfmBuildMenuCommands("SpawnBfm28menu" .. AdvSuffix, MenuGroup, "Adversary MiG-28", BfmMenu, Adv28, AdvQty, unit)
    BFMACM.BfmBuildMenuCommands("SpawnBfm23menu" .. AdvSuffix, MenuGroup, "Adversary MiG-23", BfmMenu, Adv23, AdvQty, unit)
    BFMACM.BfmBuildMenuCommands("SpawnBfm27menu" .. AdvSuffix, MenuGroup, "Adversary Su-27", BfmMenu, Adv27, AdvQty, unit)
    BFMACM.BfmBuildMenuCommands("SpawnBfm16menu" .. AdvSuffix, MenuGroup, "Adversary F-16", BfmMenu, Adv16, AdvQty, unit)
    BFMACM.BfmBuildMenuCommands("SpawnBfm18menu" .. AdvSuffix, MenuGroup, "Adversary F-18", BfmMenu, Adv18, AdvQty, unit)   
      
end
-- CLIENTS
-- BLUFOR = SET_GROUP:New():FilterCoalitions( "blue" ):FilterStart()

-- SPAWN AIR MENU

function BFMACM.BfmAddMenu()

  local devMenuBfm = false -- if true, BFM menu available outside BFM zone

  BFMACM.SetClient:ForEachClient(
    function(client)
     if (client ~= nil) and (client:IsAlive()) then 
        local group = client:GetGroup()
        local groupName = group:GetName()
        local unit = client:GetClientGroupUnit()
        local playerName = client:GetPlayer()
        
        if (unit:IsInZone(BFMACM.ZoneMenu) or devMenuBfm) then
          if BFMACM["SpawnBfm" .. groupName] == nil then
            MenuGroup = group
            BFMACM["SpawnBfm" .. groupName] = MENU_GROUP:New( MenuGroup, "AI BFM/ACM" )
              BfmBuildMenus(1, MenuGroup, "Single", BFMACM["SpawnBfm" .. groupName], unit)
              BfmBuildMenus(2, MenuGroup, "Pair", BFMACM["SpawnBfm" .. groupName], unit)
            MESSAGE:New(playerName .. " has entered the BFM/ACM zone.\nUse F10 menu to spawn adversaries.\nMissile Trainer can also be activated from F10 menu."):ToGroup(group)
            --env.info("[JTF-1] BFM/ACM entry Player name: " ..client:GetPlayerName())
            --env.info("[JTF-1] BFM/ACM entry Group Name: " ..group:GetName())
          end
        elseif BFMACM["SpawnBfm" .. groupName] ~= nil then
          if unit:IsNotInZone(BFMACM.ZoneMenu) then
            BFMACM["SpawnBfm" .. groupName]:Remove()
            BFMACM["SpawnBfm" .. groupName] = nil
            MESSAGE:New(playerName .. " has left the ACM/BFM zone."):ToGroup(group)
            --env.info("[JTF-1] BFM/ACM exit Group Name: " ..group:GetName())
          end
        end
      end
    end
  )
  timer.scheduleFunction(BFMACM.BfmAddMenu,nil,timer.getTime() + 5)

end

BFMACM.BfmAddMenu()

--- END ACMBFM SECTION