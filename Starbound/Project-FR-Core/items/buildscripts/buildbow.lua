require "/scripts/util.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"
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

--- Core build script for bow-type weaponry.
--- Orchestrates draw-power physics, energy consumption mapping, 
--- and secure metadata localization through the shared generator engine.
function build(directory, config, parameters, level, seed)
  -- Initialization: Ensure parameters is a table to prevent runtime errors 
  -- during recipe scanning or asset instantiation.
  parameters = parameters or {}

  local configParameter = function(keyName, defaultValue)
    if parameters[keyName] ~= nil then
      return parameters[keyName]
    elseif config[keyName] ~= nil then
      return config[keyName]
    else
      return defaultValue
    end
  end

  if level and not configParameter("fixedLevel", true) then
    parameters.level = level
  end

  -- select, load and merge abilities
  setupAbility(config, parameters, "alt")
  setupAbility(config, parameters, "primary")

  -- elemental type
  local elementalType = parameters.elementalType or config.elementalType or "physical"
  replacePatternInData(config, nil, "<elementalType>", elementalType)

  -- calculate damage level multiplier
  config.damageLevelMultiplier = root.evalFunction("weaponDamageLevelMultiplier", configParameter("level", 1))

  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.energyPerShotLabel = config.primaryAbility.energyPerShot or 0
  local bestDrawTime = (config.primaryAbility.powerProjectileTime[1] + config.primaryAbility.powerProjectileTime[2]) / 2
  local bestDrawMultiplier = root.evalFunction(config.primaryAbility.drawPowerMultiplier, bestDrawTime)
  config.tooltipFields.maxDamageLabel = util.round(config.primaryAbility.projectileParameters.power * config.damageLevelMultiplier * bestDrawMultiplier, 1)
  if elementalType ~= "physical" then
    config.tooltipFields.damageKindImage = "/interface/elements/"..elementalType..".png"
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
      generator.generateTooltips(config, parameters, level, seed, "weapons")
    end)
    
    if not status then
      -- Log critical failures while maintaining item integrity.
      sb.logError("BOW GENERATION ERROR: %s", err)
    end
  else
    -- Debug notice: Generator scope usually loads after initial recipe scanning.
    sb.logDebug("Generator scope not ready for bow: %s", config.itemName or "unknown")
  end
  -- ==========================================================

  -- set price
  config.price = (config.price or 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  return config, parameters
end
