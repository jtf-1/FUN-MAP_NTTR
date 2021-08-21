function BVRGCI.BuildMenus(ParentMenu)

  BVRGCI.Submenu.Size = {}

  -- level 2 submenu - Size
  BVRGCI.SubMenu.Size[1].Menu = MENU_COALITION:New(coalition.side.BLUE,"Pair", ParentMenu)
  BVRGCI.SubMenu.Size[1].Value = BVRGCI.Size.Pair
  BVRGCI.SubMenu.Size[1].SubMenu = {}
  BVRGCI.SubMenu.Size[2].Menu = MENU_COALITION:New(coalition.side>BLUE,"Four", ParentMenu)
  BVRGCI.Submenu.Size[2].Value = BVRGCI.Size.Four
  BVRGCI.SubMenu.Size[2].SubMenu = {}

  -- Level 2 submenus - Alititude
  for indexLevel1, v in ipairs(BVRCGI.SubMenu) do
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[1].Menu = MENU_COALITION:New(coalition.side.BLUE,"High Level", BVRGCI.SubMenu[indexLevel1])
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[1].Value = BVRGCI.Altitude.High
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[1].SubMenu = {}
     
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[2].Menu = MENU_COALITION:New(coalition.side.BLUE,"Medium Level", BVRGCI.SubMenu[indexLevel1])
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[2].Value = BVRGCI.Altitude.Medium
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[2].SubMenu = {}
    
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[3].Menu = MENU_COALITION:New(coalition.side.BLUE,"Low Level", BVRGCI.SubMenu[indexLevel1])
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[3].Value = BVRGCI.Altitude.Low
    BVRGCI.SubMenu.Size[indexLevel1].SubMenu[3].SubMenu = {}
    
    -- Level 3 submenu- Formation
    for indexLevel2, v in ipairs(BVRGCI.SubMenu[indexLevel1]) do
      BVRGCI.SubMenu.Size[indexLevel1].SubMenu[indexLevel2].SubMenu[1] = MENU_COALITION:New(coalition.side.BLUE, "Line Abreast", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[2] = MENU_COALITION:New(coalition.side.BLUE, "Trail", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[3] = MENU_COALITION:New(coalition.side.BLUE, "Wedge", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[4] = MENU_COALITION:New(coalition.side.BLUE, "EchelonRight", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[5] = MENU_COALITION:New(coalition.side.BLUE, "EchelonLeft", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[6] = MENU_COALITION:New(coalition.side.BLUE, "FingerFour", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2].SubMenu[7] = MENU_COALITION:New(coalition.side.BLUE, "Spread", BVRGCI.SubMenu[indexLevel1].SubMenu[indexLevel2])

      -- Level 4 submenus - Distance
      for indexLevel3, v in pairs(BVRGCI.SubMenu[indexLevel1].Submenu[indexAltitude]) do
        BVRGCI.SubMenu[indexSize][indexAltitude][indexFormation].Group = MENU_COALITION:New(coalition.side.BLUE, "Group", BVRGCI.SubMenu[indexSize][indexAltitude])
        BVRGCI.SubMenu[indexSize][indexAltitude][indexFormation].Close = MENU_COALITION:New(coalition.side.BLUE, "Close", BVRGCI.SubMenu[indexSize][indexAltitude])
        BVRGCI.SubMenu[indexSize][indexAltitude][indexFormation].Open = MENU_COALITION:New(coalition.side.BLUE, "Open", BVRGCI.SubMenu[indexSize][indexAltitude])
      
        -- Level 4 submenu commands
        for indexDistance, v in pairs(BVRGCI.SubMenu[indexSize][indexAltitude][indexFormation]) do
          for i, v in ipairs(BVRGCI.Adversary) do
            typeName = v[1]
            typeSpawn = v[2]
            if GROUP:FindByName(typeSpawn) ~= nil then
                MENU_COALITION_COMMAND:New( coalition.side.BLUE, typeName, BVRGCI.SubMenu[indexSize][indexAltitude][indexFormation][indexDistance], BVRGCI.SpawnAdv, typeSpawn, Qty, typeName, ENUMS.Formation.FixedWing[Formation].Group)
            else
              _msg = "Spawn template " .. typeSpawn .. " was not found and could not be added to menu."
              MESSAGE:New(_msg):ToAll()
            end
            
          end
            
        end -- Level 4 submenu commands
        
      end -- Level 4 submenus - Distance
        
    end -- Level 3 submenu- Formation
    
  end -- Level 2 submenus - Alititude
  
end -- function BVRGCI._BuildMenus() 
