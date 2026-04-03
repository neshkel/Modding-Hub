--- @class Generator
--- Centralized translation module using a persistent global cache.
generator = generator or {}

--- @table _TRAD_CACHE
--- Internal cache shared across all script instances to optimize performance and disk I/O.
_TRAD_CACHE = _TRAD_CACHE or { generics = nil, files = {} }

--- Loads a JSON file with error handling and caching.
--- @param path string The absolute path to the asset.
--- @return table Returns the loaded table or an empty table if the load fails.
local function loadAsset(path)
  if _TRAD_CACHE.files[path] then return _TRAD_CACHE.files[path] end
  
  local status, data = pcall(root.assetJson, path)
  local result = (status and type(data) == "table") and data or {}
  
  _TRAD_CACHE.files[path] = result
  return result
end

--- Retrieves common translations (UI, rarities, categories, abilities, etc.).
--- @return table The dictionary table for generic terms.
function generator.getGenerics()
  if not _TRAD_CACHE.generics then
    _TRAD_CACHE.generics = loadAsset("/dictionary/generics.config")
    -- S'assure que les clés de base existent pour éviter des crashs plus loin
    _TRAD_CACHE.generics.ui = _TRAD_CACHE.generics.ui or {}
    _TRAD_CACHE.generics.rarity = _TRAD_CACHE.generics.rarity or {}
    _TRAD_CACHE.generics.category = _TRAD_CACHE.generics.category or {}
    _TRAD_CACHE.generics.ability = _TRAD_CACHE.generics.ability or {}
    _TRAD_CACHE.generics.combofinisher = _TRAD_CACHE.generics.combofinisher or {}
    _TRAD_CACHE.generics.elementaltype = _TRAD_CACHE.generics.elementaltype or {}
  end
  return _TRAD_CACHE.generics
end

--- Retrieves a specific configuration dictionary by its technical name.
--- @param dName string File name (without extension).
--- @return table The requested dictionary content.
function generator.getDictionary(dName)
  return loadAsset(string.format("/dictionary/%s.config", dName))
end

--- Locates the appropriate item dictionary, handling letter-based segmentation (A-Z, 0-9).
--- @param itemType string|nil The item category (e.g., "activeitems", "objects"). Defaults to "items".
--- @param itemName string|nil The technical name of the item to determine the folder letter.
--- @return table The corresponding translation dictionary.
function generator.getItemDictionary(itemType, itemName)
  itemType = itemType or "items"
  local path = "/dictionary/" .. itemType .. ".config"

  -- List of large types requiring segmented folder structures for better performance
  local segmentedTypes = { 
    activeitems = true, items = true, matitems = true, 
    objects = true, consumables = true 
  }

  if itemName and itemName ~= "" and segmentedTypes[itemType] then
    local firstLetter = string.sub(itemName, 1, 1):lower()
    -- Normalization for file names starting with a digit
    if string.match(firstLetter, "%d") then firstLetter = "0" end
    path = string.format("/dictionary/%s/%s.config", itemType, firstLetter)
  end

  return loadAsset(path)
end

--- Injects a value into a deep table structure using a dot-separated path.
--- @param config table The target configuration table.
--- @param parameters table The parameters table (often passed by the game engine).
--- @param path string Destination path (e.g., "metadata.ability.name").
--- @param value any The value to inject.
function generator.setByPath(config, parameters, path, value)
  local keys = {}
  for key in string.gmatch(path, "([^.]+)") do
    table.insert(keys, tonumber(key) or key) 
  end

  local nodeC, nodeP = config, parameters
  
  for i = 1, #keys - 1 do
    local k = keys[i]
    local nextK = keys[i+1]

    -- Recursively create missing nodes if they don't exist
    if type(nodeC[k]) ~= "table" then nodeC[k] = {} end
    if type(nodeP[k]) ~= "table" then nodeP[k] = {} end

    nodeC, nodeP = nodeC[k], nodeP[k]
  end

  -- Synchronized final assignment between config and parameters
  local lastKey = keys[#keys]
  nodeC[lastKey] = value
  nodeP[lastKey] = value
end