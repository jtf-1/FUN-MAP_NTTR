env.info( "[JTF-1] disableai.lua" )
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

_msg = string.format("%sStart Disable AI.", DISABLEAI.traceTitle)
BASE:T({_msg, Exclude_List = DISABLEAI.excludeAI})


DISABLEAI.setGroupGroundActive:ForEachGroup(
  function(activeGroup)

    -- name of the group we're checking
    local activeGroupName = activeGroup:GetName()
    -- list of group name prefixes to exclude
    local excludeAI = DISABLEAI.excludeAI
    -- flag to trigger disabling AI
    local disableGroup = true

    -- check if group name prefix is in exclusion list
    for _, stringExclude in pairs(excludeAI) do
      if string.find(activeGroupName, stringExclude) ~= nil then
        disableGroup = false
        _msg = string.format("%sSkip group: %s", DISABLEAI.traceTitle, activeGroupName)
        break
      end
    end

    -- Disable AI if group was not in exclusion list
    if disableGroup == true then
      activeGroup:SetAIOnOff(false)
      _msg = string.format("%sDisable group: %s", DISABLEAI.traceTitle, activeGroupName)
    end

    BASE:T(_msg)

  end
)

-- remove set object
DISABLEAI.setGroupGroundActive = nil

---  END DISABLE AI