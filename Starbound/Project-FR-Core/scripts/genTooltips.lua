--- @class Generator
--- Extension of the Generator module providing the main entry point for tooltip generation.
generator = generator or {}

--- Orchestrates the entire tooltip generation process for an item.
--- It handles name/description mapping, tier upgrades, metadata injection, and sub-component localization.
--- @param config table The base configuration of the item.
--- @param parameters table The dynamic parameters of the item instance.
--- @param level number The level/tier of the item.
--- @param seed number The random seed for the item.
--- @param dToLoad string The name of the specific dictionary file to load (e.g., "objects").
--- @return table, table The modified config and parameters ready for rendering.
function generator.generateTooltips(config, parameters, level, seed, dToLoad)
  -- Secure extraction of the internal item name
  local itemName = parameters.itemName or config.itemName or parameters.objectName or config.objectName
  if type(itemName) ~= "string" then itemName = "" end

  -- Data retrieval (Guaranteed to return tables, even if empty)
  local t = generator.getItemDictionary(dToLoad, itemName)
  local genT = generator.getGenerics()
  local itemData = t[itemName]

  -- Initialize text fields with existing fallbacks
  local finalName = parameters.shortdescription or config.shortdescription or "unknown"
  local finalDesc = parameters.description or config.description or ""

  -- 1. DICTIONARY MAPPING
  -- If the item exists in the translation dictionary, override default values.
  if itemData and type(itemData) == "table" then
    finalName = itemData.name or finalName
    finalDesc = itemData.desc or finalDesc

    -- Handle Tier 6 / Upgraded items
    if config.upgradeParameters then
      -- Check if the current icon matches the upgraded icon to detect upgrade state
      local isUp = (parameters.inventoryIcon == config.upgradeParameters.inventoryIcon)
      if isUp then
        -- Use specific upgraded name if defined, otherwise append a yellow star icon
        if itemData.metadata and itemData.metadata["upgradeParameters.shortdescription"] then
          finalName = itemData.metadata["upgradeParameters.shortdescription"]
        else
          finalName = finalName .. " ^yellow;^reset;"
        end
      end
    end

    -- Metadata Injection (Racial descriptions, custom stats, etc.)
    if itemData.metadata and type(itemData.metadata) == "table" then
      -- Prevent overwriting core naming fields during generic metadata loop
      local blacklist = {
        ["shortdescription"] = true,
        ["upgradeParameters.shortdescription"] = true,
        ["altAbility.name"] = true
      }
      for key, value in pairs(itemData.metadata) do
        if not blacklist[key] then
          generator.setByPath(config, parameters, key, value)
        end
      end
    end
  end

  -- Validate mandatory fields to prevent rendering errors in the Starbound UI
  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.shortdescription = finalName
  config.tooltipFields.description = finalDesc
  parameters.shortdescription = finalName
  parameters.description = finalDesc

  -- 2. SUB-COMPONENT LOCALIZATION
  -- Handle primary and special abilities if present
  if (config.primaryAbility and config.primaryAbility.name or config.altAbility) then
    -- Pass specific item metadata if it exists, otherwise pass an empty table
    local meta = (itemData and itemData.metadata) or {}
    generator.injectAbility(config, genT, meta)
  end
  
  -- Inject standard UI labels (Handedness, DPS labels, etc.)
  generator.injectTooltipLabels(config, genT)

  -- 3. RARITY AND CATEGORY LOCALIZATION
  -- Translate the rarity tier (Common, Uncommon, etc.)
  if genT.rarity then
    local r = (parameters.rarity or config.rarity or "common"):lower()
    config.tooltipFields.rarityLabel = genT.rarity[r] or r
  end

  -- Translate the item category (e.g., "Broadsword", "Crafting Material")
  if genT.category then
    local c = parameters.category or config.category
    if c then
      -- Normalize key: lowercase and remove spaces for dictionary matching
      local cKey = c:lower():gsub("%s", "")
      config.tooltipFields.subtitle = genT.category[cKey] or c
    end
  end

  return config, parameters
end