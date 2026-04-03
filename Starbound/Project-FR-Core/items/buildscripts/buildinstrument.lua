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

--- Core build script for musical instruments and audio tools.
--- Handles dynamic translation of instrument names, sound descriptions,
--- and metadata injection (song list, tuning) into item parameters.
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
      generator.generateTooltips(config, parameters, level, seed, "instruments")
    end)
    
    if not status then
      -- Log critical failures while maintaining item integrity.
      sb.logError("INSTRUMENT GENERATION ERROR: %s", err)
    end
  else
    -- Debug notice: Generator scope usually loads after initial recipe scanning.
    sb.logDebug("Generator scope not ready for instrument: %s", config.itemName or "unknown")
  end
  -- ==========================================================
  
  return config, parameters
end