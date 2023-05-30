------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- BEGIN MOVING TARGETS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- R62 T6208 MOVING TARGETS

local function rangeMovingTarget(targetId)
    local spawnMovingTarget = SPAWN:New( targetId )
    spawnMovingTarget:Spawn()
  end

  local MenuT6208 = MENU_COALITION:New( coalition.side.BLUE, "Target 62-08" )
  local MenuT6208_1 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  4x4 (46 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-1")
  local MenuT6208_2 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  Truck (23 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-2")
  local MenuT6208_3 = MENU_COALITION_COMMAND:New( coalition.side.BLUE, "TGT 6208: Activate  T-55 (11 mph)", MenuT6208, rangeMovingTarget, "Vehicle6208-3")

  -- END R62 T6208

--- END MOVING TARGETS 