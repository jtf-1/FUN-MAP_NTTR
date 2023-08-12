env.info( "[JTF-1] staticranges" )
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- STATIC RANGES
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Add static bombing and strafing range(s)
--
-- Two files are used by this module;
--     staticranges.lua
--     staticranges_data.lua
--
-- 1. staticranges.lua
-- Core file. Contains functions, key values and GLOBAL settings.
--
-- 2. staticranges_data.lua
-- Contains settings that are specific to the miz.
-- Settings in staticranges_data.lua will override the defaults in the core file.
--
-- Load order in miz MUST be;
--     1. staticranges.lua
--     2. staticranges_data.lua
--

STATICRANGES = {}
local _msg

STATICRANGES.default = {
  strafeMaxAlt             = 1530, -- [5000ft] in metres. Height of strafe box.
  strafeBoxLength          = 3000, -- [10000ft] in metres. Length of strafe box.
  strafeBoxWidth           = 300, -- [1000ft] in metres. Width of Strafe pit box (from 1st listed lane).
  strafeFoullineDistance   = 610, -- [2000ft] in metres. Min distance for from target for rounds to be counted.
  strafeGoodPass           = 20, -- Min hits for a good pass.
  --rangeSoundFilesPath      = "Range Soundfiles/" -- Range sound files path in miz
}

function STATICRANGES:Start()
  _msg = "[JTF-1 STATICRANGES] Start()."
  BASE:T(_msg)
  -- set defaults
  self.strafeMaxAlt = self.strafeMaxAlt or self.default.strafeMaxAlt
  self.strafeBoxLength = self.strafeBoxLength or self.default.strafeBoxLength
  self.strafeBoxWidth = self.strafeBoxWidth or self.default.strafeBoxWidth
  self.strafeFoullineDistance = self.strafeFoullineDistance or self.default.strafeFoullineDistance
  self.strafeGoodPass = self.strafeGoodPass or self.default.strafeGoodPass
  -- Parse STATICRANGES.Ranges and build range
  if self.Ranges then
    _msg = "[JTF-1 STATICRANGES] Add ranges."
    BASE:T({_msg,self.Ranges})
    self:AddStaticRanges(self.Ranges)
  else
    _msg = "[JTF-1 STATICRANGES] No Ranges defined!"
    BASE:E(_msg)
  end
end

function STATICRANGES:AddStaticRanges(TableRanges)

  for rangeIndex, rangeData in ipairs(TableRanges) do
  
    local rangeObject = "Range_" .. rangeData.rangeId
    
    self[rangeObject] = RANGE:New(rangeData.rangeName)
      self[rangeObject]:DebugOFF()  
      self[rangeObject]:SetRangeZone(ZONE_POLYGON:FindByName(rangeData.rangeZone))
      self[rangeObject]:SetMaxStrafeAlt(self.strafeMaxAlt)
      self[rangeObject]:SetDefaultPlayerSmokeBomb(false)
 
    if rangeData.groups ~= nil then -- add groups of targets
      _msg = string.format("[JTF-1 STATICRANGES] Add range groups for index %d.", rangeIndex)
      BASE:T(_msg)
        for tgtIndex, tgtName in ipairs(rangeData.groups) do
        self[rangeObject]:AddBombingTargetGroup(GROUP:FindByName(tgtName))
      end
    end
    
    if rangeData.units ~= nil then -- add individual targets
      _msg = string.format("[JTF-1 STATICRANGES] Add range units for index %d.", rangeIndex)
      BASE:T(_msg)
      for tgtIndex, tgtName in ipairs(rangeData.units) do
        self[rangeObject]:AddBombingTargets( tgtName )
      end
    end
    
    if rangeData.strafepits ~= nil then -- add strafe targets
      _msg = string.format("[JTF-1 STATICRANGES] Add range strafe pits for index %d.", rangeIndex)
      BASE:T(_msg)
      for strafepitIndex, strafepit in ipairs(rangeData.strafepits) do
        self[rangeObject]:AddStrafePit(strafepit, self.strafeBoxLength, self.strafeBoxWidth, nil, true, self.strafeGoodPass, self.strafeFoullineDistance)
      end  
    end
    
    if rangeData.rangeControlFrequency ~= nil then
      _msg = string.format("[JTF-1 STATICRANGES] Range Control frequency = %.3f.", rangeData.rangeControlFrequency)
      BASE:T(_msg)
    end

    -- Start the Range
    self[rangeObject]:Start()
  end

end

--- END STATIC RANGES