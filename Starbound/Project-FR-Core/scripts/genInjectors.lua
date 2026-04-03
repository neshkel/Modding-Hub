--- @class Generator
--- Extension of the Generator module focused on injecting translated data into item configurations.
generator = generator or {}

--- Injects UI labels into the item's tooltip configuration.
--- Handles specific logic for weapon handedness (1-Handed/2-Handed).
--- @param config table The item configuration to modify.
--- @param genT table The generic translations table (containing UI and tooltip keys).
function generator.injectTooltipLabels(config, genT)
  if not genT or not genT.ui or not genT.ui.tooltip then return end

  local kind = config.tooltipKind
  if kind then
    local labels = genT.ui.tooltip[kind:lower()]
    
    if labels then
      config.tooltipFields = config.tooltipFields or {}
      for k, v in pairs(labels) do
        local value = v
        -- Special handling for handedness labels based on item properties
        if k == "handednessLabel" then
          value = config.twoHanded and (genT.ui.twoHandedLabel or "2-Handed") or (genT.ui.oneHandedLabel or "1-Handed")
        end
        config.tooltipFields[k] = value
      end
    end
  end
end

--- Translates and injects primary and secondary abilities into the tooltip.
--- Supports elemental name replacement within ability strings (e.g., replacing <elementalName> with "Fire").
--- @param config table The weapon configuration.
--- @param genT table The generic translations table.
--- @param metadata table The items metadata (used for custom ability names).
--- @return table The modified configuration.
function generator.injectAbility(config, genT, metadata)
  if not config.primaryAbility and not config.altAbility then return end

  local eType = config.elementalType or (config.primaryAbility and config.primaryAbility.elementalType) or "physical"
  local eName = ""
  if eType ~= "physical" then
    local trad = genT.elementaltype and genT.elementaltype[eType]
    
    if trad then
      eName = trad
    else
      eName = eType:gsub("^%l", string.upper)
    end
    
    eName = eName .. " "
  end
  
  if config.primaryAbility then
    local abilityName = genT.ability and genT.ability[config.primaryAbility.type] or config.primaryAbility.name or ""
    config.tooltipFields.primaryAbilityTitleLabel = genT.ui and genT.ui.primaryAbilityLabel or "Primary:"
    config.tooltipFields.primaryAbilityLabel = abilityName:gsub("<elementalName>%s?", eName)
  end

  if config.altAbility then
    local altName = metadata["altAbility.name"] or (genT.ability and genT.ability[config.altAbility.type]) or config.altAbility.name or ""
    config.tooltipFields.altAbilityTitleLabel = genT.ui and genT.ui.secondAbilityLabel or "Special:"
    config.tooltipFields.altAbilityLabel = altName:gsub("<elementalName>%s?", eName)
  end

  return config
end

--- Injects translated combo finisher labels into the tooltip.
--- @param config table The weapon configuration.
--- @return table The modified configuration.
function generator.injectComboFinisher(config)
  local dict = generator.getGenerics("generics")
  if not config.comboFinisher then return end

  config.tooltipFields.comboFinisherTitleLabel = dict.ui and dict.ui.finalAbilityLabel or "Finish:"
  local cbfRaw = config.comboFinisher.name or ""
  local cbfKey = cbfRaw:lower()
  config.tooltipFields.comboFinisherLabel = dict.combofinisher[cbfKey] or cbfRaw

  return config
end

-- FISHING ROD INJECTIONS
-- ==========================================================

--- Translates and injects fishing reel augment data into the fishing rod tooltip.
--- @param config table The fishing rod base configuration.
--- @param parameters table The items dynamic parameters (current augments).
--- @return table, table The modified config and parameters.
function generator.injectFishingRodReel(config, parameters)
  local name = parameters.reelName or config.reelName
  if not name then return end

  local dict = generator.getDictionary("augments")
  local icon = parameters.reelIcon or config.reelIcon
  local types = parameters.reelType or config.reelType or ""
  local lookupKey = "fishingreel" .. tostring(types)

  -- Look up translated augment name
  if dict[lookupKey] then
    name = dict[lookupKey].name or config.reelName
  end

  config.tooltipFields.reelNameLabel = name
  config.tooltipFields.reelIconImage = icon

  return config, parameters
end

--- Translates and injects fishing lure augment data into the fishing rod tooltip.
--- @param config table The fishing rod base configuration.
--- @param parameters table The items dynamic parameters (current augments).
function generator.injectFishingRodLure(config, parameters)
  local name = parameters.lureName or config.lureName
  if not name then return end

  local dict = generator.getDictionary("augments")
  local icon = parameters.lureIcon or config.lureIcon
  local types = parameters.lureType or config.lureType or ""
  local lookupKey = "fishinglure" .. tostring(types)

  -- Look up translated augment name
  if dict[lookupKey] then
    name = dict[lookupKey].name or config.lureName
  end

  config.tooltipFields.lureNameLabel = name
  config.tooltipFields.lureIconImage = icon
end

-- CONSUMABLES
-- ==========================================================

--- Determines the translated text description for an item's remaining shelf life.
--- Uses thresholds defined in the generic dictionary (ui.rotTimeDescription).
--- @param rotTime number The remaining time before the item rots (in seconds).
--- @return string The translated rot time description (e.g., "Fresh", "Stale").
function generator.getRotTimeDescription(rotTime)
  local dict = generator.getGenerics()
  local rotDesc = dict.ui.rotTimeDescription

  -- Iterates through thresholds to find the matching description
  for i, desc in ipairs(rotDesc) do
    if rotTime <= desc[1] then return desc[2] end
  end
  
  -- Fallback to the last available description (usually the "worst" state)
  return rotDesc[#rotDesc]
end