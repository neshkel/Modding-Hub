--- @class Generator
--- Centralized translation module using a persistent global cache.
generator = generator or {}

--- @table _TRAD_CACHE
--- Internal cache shared across all script instances to optimize performance and disk I/O.
_TRAD_CACHE = _TRAD_CACHE or { generics = nil, files = {} }

--- Internal function to load JSON assets with an automated locale routing.
--- This ensures the engine looks into the correct language subfolder.
--- @param relativePath string The path relative to the locale folder (e.g., "/items/a.config").
--- @return table The loaded dictionary or an empty table on failure.
local function loadAsset(relativePath)
  -- Retrieve global configuration (defines the active language)
  local config = root.assetJson("/gen_conf.config")
  local locale = config.locale or "fr"
  
  -- Construct the localized path: /dictionary/{locale}/{relativePath}
  local fullPath = "/dictionary/" .. locale .. relativePath

  -- Return from memory cache if already loaded to save I/O cycles
  if _TRAD_CACHE.files[fullPath] then return _TRAD_CACHE.files[fullPath] end
  
  -- Safe call to prevent engine crashes if the file is missing or corrupted
  local status, data = pcall(root.assetJson, fullPath)
  
  -- Fallback logic: if the file is missing in the target locale, 
  -- we return an empty table to prevent downstream nil-value errors.
  if not status or type(data) ~= "table" then
    data = {}
  end

  -- Store the result in cache before returning
  _TRAD_CACHE.files[fullPath] = data
  return data
end

--- Retrieves common translations (UI, rarities, categories, abilities, etc.).
--- @return table The dictionary table for generic terms.
function generator.getGenerics()
  if not _TRAD_CACHE.generics then
    _TRAD_CACHE.generics = loadAsset("/generics.config")
    -- S'assure que les clés de base existent pour éviter des crashs plus loin
    local g = _TRAD_CACHE.generics
    g.ui              = g.ui or {}
    g.rarity          = g.rarity or {}
    g.category        = g.category or {}
    g.ability         = g.ability or {}
    g.combofinisher   = g.combofinisher or {}
    g.elementaltype   = g.elementaltype or {}
  end
  return _TRAD_CACHE.generics
end

--- Retrieves a specific configuration dictionary by its technical name.
--- @param dName string File name (without extension).
--- @return table The requested dictionary content.
function generator.getDictionary(dName)
  return loadAsset(string.format("/%s.config", dName))
end

--- Locates the appropriate item dictionary, handling letter-based segmentation (A-Z, 0-9).
--- @param itemType string|nil The item category (e.g., "activeitems", "objects"). Defaults to "items".
--- @param itemName string|nil The technical name of the item to determine the folder letter.
--- @return table The corresponding translation dictionary.
function generator.getItemDictionary(itemType, itemName)
  itemType = itemType or "items"
  local relativePath = "/" .. itemType .. ".config"

  -- List of large types requiring segmented folder structures for better performance
  local segmentedTypes = { 
    activeitems = true, items = true, matitems = true, 
    objects = true, consumables = true 
  }

  if itemName and itemName ~= "" and segmentedTypes[itemType] then
    local firstLetter = string.sub(itemName, 1, 1):lower()
    -- Normalization for file names starting with a digit
    if string.match(firstLetter, "%d") then firstLetter = "0" end
    relativePath = string.format("/%s/%s.config", itemType, firstLetter)
  end

  return loadAsset(relativePath)
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

--- Global helper to retrieve a translation for a specific mod.
--- Provides a safe fallback if the mod or the key is missing.
--- @param modName string The technical name of the mod (folder in /ui/mods/).
--- @param key string The translation key.
--- @param default string The fallback text (usually English).
--- @return string The translated string or the default value.
function generator.getTMod(modName, path, default)
  local gen = generator.getGenerics()
  local node = gen.ui and gen.ui.mods and gen.ui.mods[modName]
  
  if not node then return default end

  -- On découpe le chemin (ex: "theme.uiTitle")
  for key in string.gmatch(path, "([^.]+)") do
    if type(node) == "table" and node[key] then
      node = node[key]
    else
      return default
    end
  end

  return (type(node) == "string") and node or default
end