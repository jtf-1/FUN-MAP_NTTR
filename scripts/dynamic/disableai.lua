env.info( "[JTF-1] disableai" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- Disable AI for ground targets
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DISABLEAI = {}
DISABLEAI.traceTitle = "[JTF-1 DISABLEAI] "
DISABLEAI.setGroupGroundActive = SET_GROUP:New()
  :FilterActive()
  :FilterCategoryGround()
  :FilterOnce()
--local setGroupGroundActive = SET_GROUP:New():FilterActive():FilterCategoryGround():FilterOnce()

-- table of Prefixes for groups for which AI should NOT be disabled
DISABLEAI.excludeAI = {"BLUFOR", "FAC", "JTAC", "66%-"}
--local excludeAI = "BLUFOR"


DISABLEAI.setGroupGroundActive:ForEachGroup(
  function(activeGroup)
    local _msg
    -- name of the group we're checking
    local activeGroupName = activeGroup:GetName()
    -- list of group name prefixes to exclude
    local excludeAI = DISABLEAI.excludeAI
    -- flag to trigger disabling AI
    local disableGroup = true

    -- check if group name prefix is in exclusion list
    for _, stringExclude in pairs(excludeAI) do

      if string.find(activeGroupName, stringExclude) then
        _msg = string.format("%sSkipping group: %s", DISABLEAI.traceTitle, activeGroupName)
        disableGroup = false
        break
      end

    end

    -- Disable AI if group was not in exclusion list
    if disableGroup then
      local _msg = string.format("%sDisable group: %s", DISABLEAI.traceTitle, activeGroupName)
      activeGroup:SetAIOff()
    end

    BASE:T(_msg)

  end
)

-- remove set object
DISABLEAI.setGroupGroundActive = nil

---  END DISABLE AI