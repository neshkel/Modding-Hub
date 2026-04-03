--- @class Generator
--- Extension of the Generator module focused on procedural generation.
generator = generator or {}

--- Safely picks a random element from a list with a fallback value.
--- @param list table The list to pick from.
--- @param default string The fallback value if the list is empty or invalid.
--- @return any The randomly selected element or the default value.
local function safePick(list, default)
  if not list or type(list) ~= "table" or #list == 0 then 
    return default or "Unknown" 
  end
  return list[math.random(#list)]
end

--- Generates a procedurally randomized weapon name based on category and style.
--- Handles logic for junker-style, standard, and epic naming conventions.
--- @param category string The weapon category (e.g., "pistol", "broadsword").
--- @param seed number The random seed for reproducibility.
--- @param isJunker boolean Whether to apply the "junker/gang" naming style.
--- @return string The fully generated localized name.
function generator.getRandomisedName(category, seed, isJunker)
  -- Initialize random seed and perform warmup for better distribution
  math.randomseed(seed)
  for i=1, 3 do math.random() end

  local naming = generator.getDictionary("namings")
  if not naming or not naming.types[category] then return "Unknown Items" end

  -- 1. GROUP AND AFFINITY DETERMINATION
  -- Determines which word pools to use based on weapon type and random affinity.
  local typeLabel = naming.types[category]
  local groupData = naming.group
  local mainGroup = "" -- e.g., melee, ranged, magic, shield
  local subGroup = ""  -- e.g., blunt, slash, firearms

  -- Traverse the naming group structure to find the category's parent groups
  for gName, gContent in pairs(groupData) do
    if type(gContent) == "table" then
      for subName, subList in pairs(gContent) do
        for _, t in ipairs(subList) do if t == category then mainGroup = gName subGroup = subName end end
      end
    else
      if gContent == category then mainGroup = gName end
    end
  end

  -- Select a random flavor affinity for naming consistency
  local affinities = {"elemental", "cosmic", "mystic", "tech", "nature"}
  local currentAffinity = safePick(affinities, "elemental")

  -- 2. GENERATION LOGIC
  
  -- STYLE: JUNKER / GANG
  -- Produces brutal, short, or composite names for low-tech/scrap weapons.
  if isJunker then
    local style = math.random(1, 2)
    local name = ""
    local junkManu = safePick(naming.manufacturers.gang)
    
    if style == 1 then -- Brutal Verb + Gang Suffix (e.g., "Crushbone")
      local v = naming.short_verbs.brutal[math.random(#naming.short_verbs.brutal)]
      local s = naming.suffixes.gang[math.random(#naming.suffixes.gang)]
      name = v .. s
    else -- Junk Word Components (e.g., "Scraptrap")
      local p = naming.word_components.junk.prefixes[math.random(#naming.word_components.junk.prefixes)]
      local s = naming.word_components.junk.suffixes[math.random(#naming.word_components.junk.suffixes)]
      name = p .. s
    end
    
    return name .. " " .. junkManu
  end

  -- STYLE: STANDARD AND EPIC
  -- Produces cleaner, manufacturer-branded names.
  local style = math.random(1, 3)
  local mainManu = safePick(naming.manufacturers.main, "Anonyme")

  -- French grammar handling for manufacturer naming (e.g., "de " vs " d'")
  local manuArt = (mainManu:sub(1,1):find("[AEIOUYaeiouy]") and " d'") or " de "
  local finalName = ""

  if style == 1 then
    -- COMPONENT STYLE: Affinity-based Prefix + Suffix (e.g., "Cryo-pulse")
    local affData = naming.word_components[currentAffinity] or naming.word_components["elemental"]
    local p = safePick(affData.prefixes)
    local s = safePick(affData.suffixes)
    finalName = p .. s

  elseif style == 2 then
    -- VERB STYLE: Action-based Verb + Affinity Suffix (e.g., "Slasher-vortex")
    local vList = {}
    -- Determine if we use category-specific verbs or affinity-based ones
    if math.random() > 0.5 and mainGroup ~= "" then
      vList = (subGroup ~= "" and naming.short_verbs[mainGroup] and naming.short_verbs[mainGroup][subGroup]) or naming.short_verbs[mainGroup]
    else
      vList = naming.short_verbs.affinity_verbs[currentAffinity]
    end
    
    local v = safePick(vList, "Proto")
    local s = safePick(naming.suffixes[currentAffinity] or naming.suffixes["elemental"])
    finalName = v .. s -- Changé ici pour éviter le double typeLabel si tu veux un nom court

  else
    -- NOBLE STYLE: Category Name + Affinity Suffix (e.g., "Broadsword-Alpha")
    local sList = naming.suffixes[currentAffinity] or naming.suffixes["elemental"]
    local s = safePick(sList, "Alpha")
    
    finalName = typeLabel .. "-" .. s
    -- Length check: Swap order if the generated name is too long for the UI
    if #finalName > 15 then
      finalName = s .. "-" .. typeLabel
    end
  end

  return finalName .. manuArt .. mainManu
end