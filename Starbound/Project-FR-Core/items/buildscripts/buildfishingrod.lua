-- =============================================================================
-- SYSTEM DEPENDENCIES
-- =============================================================================
-- Core: Dictionary loading, persistent caching, and deep-table manipulation.
require "/scripts/genCore.lua"

-- Injectors: Specialized data modules for tooltipsLabel, abilities, fishing, and combo protocols.
require "/scripts/genInjectors.lua"

-- Tooltips: High-level rendering engine for localization and UI field mapping.
require "/scripts/genTooltips.lua"
-- =============================================================================

--- Core build script for fishing-type apparatus.
--- Orchestrates line physics, modular lure/reel parameter mapping,
--- and secure metadata localization through the shared engine.
function build(directory, config, parameters, level, seed)
  -- Initialization: Ensure parameters is a table to prevent runtime errors 
  -- during recipe scanning or asset instantiation.
  parameters = parameters or {}

  -- ==========================================================
  -- ENGINE: ISOLATED ASSET GENERATION & LOCALIZATION
  -- ==========================================================
  -- Wrap execution in a protected call (pcall) to sandbox the build process.
  -- This prevents a total item crash (inventory "invisibility") if the
  -- generator logic encounters a nil value or syntax error.
  if generator and generator.generateTooltips then
    local status, err = pcall(function()
      -- Process core tooltip data and localization mapping
      generator.generateTooltips(config, parameters, level, seed, "activeitems")
      
      -- Inject modular component data (Reel & Lure) into the tooltip
      if generator.injectFishingRodReel then generator.injectFishingRodReel(config, parameters) end
      if generator.injectFishingRodLure then generator.injectFishingRodLure(config, parameters) end
    end)
    
    if not status then
      -- Log critical failures while maintaining item integrity.
      sb.logError("FISHING GENERATION ERROR: %s", err)
    end
  else
    -- Debug notice: Generator scope usually loads after initial recipe scanning.
    sb.logDebug("Generator scope not ready for fishing tool: %s", config.itemName or "unknown")
  end
  -- ==========================================================
  
  return config, parameters
end

function getRotTimeDescription(rotTime)
  local descList = root.assetJson("/items/rotting.config:rotTimeDescriptions")
  for i, desc in ipairs(descList) do
    if rotTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
