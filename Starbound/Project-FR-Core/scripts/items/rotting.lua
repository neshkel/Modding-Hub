require "/scripts/genCore.lua"
require "/scripts/genInjectors.lua"

function ageItem(baseItem, aging)
  if baseItem.parameters.timeToRot then
    baseItem.parameters.timeToRot = baseItem.parameters.timeToRot - aging

    baseItem.parameters.tooltipFields = baseItem.parameters.tooltipFields or {}

    baseItem.parameters.tooltipFields.rotTimeLabel = generator.getRotTimeDescription(baseItem.parameters.timeToRot)

    if baseItem.parameters.timeToRot <= 0 then
      local itemConfig = root.itemConfig(baseItem.name)
      return {
        name = itemConfig.config.rottedItem or root.assetJson("/items/rotting.config:rottedItem"),
        count = baseItem.count,
        parameters = {}
      }
    end
  end

  return baseItem
end
