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

--- Core build script for perishable consumable items.
--- Orchestrates status effect mapping, nutritional value scaling, 
--- and dynamic freshness (rotting) localization.
function build(directory, config, parameters, level, seed)
  -- Initialization: Ensure parameters is a table to prevent runtime errors
  -- during recipe scanning or asset instantiation.
  parameters = parameters or {}
  config.tooltipFields = config.tooltipFields or {}
  
  if not parameters.timeToRot then
    local rottingMultiplier = parameters.rottingMultiplier or config.rottingMultiplier or 1.0
    parameters.timeToRot = root.assetJson("/items/rotting.config:baseTimeToRot") * rottingMultiplier
  end

  -- ==========================================================
  -- ENGINE: ISOLATED ASSET GENERATION & LOCALIZATION
  -- ==========================================================
  -- Wrap execution in a protected call (pcall) to sandbox the build process.
  -- This prevents a total item crash (inventory "invisibility") if the
  -- generator logic encounters a nil value or syntax error.
  if generator and generator.generateTooltips then
    local status, err = pcall(function()
      -- Process core tooltip data and localization mapping
      generator.generateTooltips(config, parameters, level, seed, "consumables")
    end)
    
    if not status then
      -- Log critical failures while maintaining item integrity.
      sb.logError("FOOD GENERATION ERROR: %s", err)
    end
  else
    -- Debug notice: Generator scope usually loads after initial recipe scanning.
    sb.logDebug("Generator scope not ready for food: %s", config.itemName or "unknown")
  end
  -- ==========================================================
  
  local rotDesc = generator.getRotTimeDescription(parameters.timeToRot)
  config.tooltipFields.rotTimeLabel = rotDesc
  
  return config, parameters
end