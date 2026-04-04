require "/scripts/util.lua"
require "/scripts/staticrandom.lua"
-- =============================================================================
-- SYSTEM DEPENDENCIES
-- =============================================================================
-- Core: Dictionary loading, persistent caching, and deep-table manipulation.
require "/scripts/genCore.lua"

-- Injectors: Specialized data modules for tooltipsLabel, abilities, fishing, and combo protocols.
require "/scripts/genInjectors.lua"

-- Nomenclature: Procedural name generation, affinity mapping, and stylistic branding (e.g., Junker/Standard).
require "/scripts/genNaming.lua"

-- Tooltips: High-level rendering engine for localization and UI field mapping.
require "/scripts/genTooltips.lua"
-- =============================================================================

--- Core build script for procedurally generated shields (Random Shields).
--- Handles dynamic assembly of randomized names, block stamina scaling,
--- and metadata injection (cooldown, defense stats) into shield parameters.
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

  if level and not configParameter("fixedLevel", false) then
    parameters.level = level
  end

  -- initialize randomization
  if seed then
    parameters.seed = seed
  else
    seed = configParameter("seed")
    if not seed then
      math.randomseed(util.seedTime())
      seed = math.random(1, 4294967295)
      parameters.seed = seed
    end
  end

  -- select the generation profile to use
  local builderConfig = {}
  if config.builderConfig then
    builderConfig = randomFromList(config.builderConfig, parameters.seed, "builderConfig")
  end

  -- build palette swap directives
  local paletteSwaps = ""
  if builderConfig.palette then
    local palette = root.assetJson(util.absolutePath(directory, builderConfig.palette))
    local selectedSwaps = randomFromList(palette.swaps, parameters.seed, "paletteSwaps")
    for k, v in pairs(selectedSwaps) do
      paletteSwaps = string.format("%s?replace=%s=%s", paletteSwaps, k, v)
    end
  end

  -- merge extra animationCustom
  if builderConfig.animationCustom then
    config.animationCustom = util.mergeTable(config.animationCustom or {}, builderConfig.animationCustom)
  end

  -- animation parts
  if builderConfig.animationParts then
    if parameters.animationParts == nil then parameters.animationParts = {} end
    for k, v in pairs(builderConfig.animationParts) do
      if parameters.animationParts[k] == nil then
        if type(v) == "table" then
          parameters.animationParts[k] = util.absolutePath(directory, string.gsub(v.path, "<variant>", randomIntInRange({1, v.variants}, parameters.seed, "animationPart"..k)))
        else
          parameters.animationParts[k] = v
        end

        -- use near idle frame of shield for inventory icon for now
        if k == "shield" and not parameters.inventoryIcon then
          parameters.inventoryIcon = parameters.animationParts[k]..":nearidle"
        end
      end
    end
  end

  -- set price
  config.price = configParameter("price", 0) * root.evalFunction("itemLevelPriceMultiplier", configParameter("level", 1))

  -- tooltip fields
  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.healthLabel = util.round(configParameter("baseShieldHealth", 0) * root.evalFunction("shieldLevelMultiplier", configParameter("level", 1)), 0)
  config.tooltipFields.cooldownLabel = configParameter("cooldownTime")

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
      
      -- Inject dynamically generated name based on category and 'Gang/Junker' status
      if generator.getRandomisedName and builderConfig.nameGenerator then
        local category = config.category or parameters.category
        local nameToTest = (parameters and parameters.itemName) or config.itemName or ""
        local isJunker = nameToTest:lower():find("gang") ~= nil
        parameters.shortdescription = generator.getRandomisedName(category, seed, isJunker)
      end
    end)
    
    if not status then
      -- Log critical failures while maintaining item integrity.
      sb.logError("RANDOM SHIELD GENERATION ERROR: %s", err)
    end
  else
    -- Debug notice: Generator scope usually loads after initial recipe scanning.
    sb.logDebug("Generator scope not ready for radomized shield: %s", config.itemName or "unknown")
  end
  -- ==========================================================

  return config, parameters
end