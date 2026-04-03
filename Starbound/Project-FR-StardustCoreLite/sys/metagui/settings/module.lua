require "/scripts/genCore.lua"

local mg = metagui
local m = settings.module { weight = -10000 }

local function default(v, d)
  if v == nil then return d end
  return v
end

-- Project FR: Helper function to fetch translations from the Core Engine
local _T = function(key, default)
  return generator.getTMod("stardustCoreLite", key, default)
end
-------------------------------------------------------------------------

do
  -- Project FR: Localized strings for the Theme tab
  local themeT = {
    uiLabel = _T("theme.uiTitle", "UI Themes"),
    settingsLabel = _T("theme.settingsTitle", "Theme Settings"),
    defaultName = _T("theme.defaultInfoName", "Default (%s)"),
    defaultDesc = _T("theme.defaultInfoDesc", "No preference selected")
  }
  -----------------------------------
  local p = m:page { title = themeT.uiLabel, icon = "themes.png",
    contents = {
      { type = "panel", style = "concave", expandMode = {1, 2}, children = {
        { type = "scrollArea", id = "themeList", children = { { spacing = 1 } } }
      } }
    }
  }
  
  local tp = m:page { title = themeT.settingsLabel, icon = "themesettings.png",
    contents = {
      { type = "layout", id = "stack", mode = "stack", expandMode = {2, 2} }
    }
  }
  
  local themes = { }
  local defaultInfo = {
    -- defaultAccentColor = "accent",
    name = themeT.defaultName,
    description = themeT.defaultDesc,
  }
  
  local function themeSelected(w)
    metagui.settings.theme = w.theme
    local theme = themes[w.theme]
    if not theme then -- default, no settings
      tp.tab:setVisible(false)
      return
    end
    tp.tab.titleWidget:setText(theme.name)
    tp.tab:setVisible(not not theme.hasSettingsPanel)
  end
  
  local function addThemeEntry(themeId)
    local theme = themes[themeId] or defaultInfo
    local li = p.themeList:addChild {
      type = "listItem", size = {128, 32}, children = { -- set to 48 when preview pics are in
        { mode = "horizontal" },
        {
          { type = "label", color = theme.defaultAccentColor, text = theme.name },
          { type = "label", color = "bfbfbf", text = theme.description }
        }
      }
    }
    li.theme = themeId
    li.onSelected = themeSelected
    if themeId == metagui.settings.theme then li:select() end
  end
  
  function p:init()
    for k, p in pairs(registry.themes) do
      local themeData = root.assetJson(p .. "theme.json")

      -- Project FR: Translate theme name and description dynamically
      -- Looks for "theme.themeID.name" and "theme.themeID.desc"
      themeData.name = _T("theme." .. k .. ".name", themeData.name)
      themeData.description = _T("theme." .. k .. ".desc", themeData.description)

      themes[k] = themeData
      themes[k].id = k
      themes[k].path = p
    end
    
    local def = registry.defaultTheme
    if not themes[def] then for k in pairs(themes) do def = k break end end
    defaultInfo.name = string.format(defaultInfo.name, themes[def].name)
    
    local themeOrder = { }
    for _, theme in pairs(themes) do table.insert(themeOrder, theme) end
    table.sort(themeOrder, function(a, b) return (b.sortWeight or 0) > (a.sortWeight or 0) end)
    
    addThemeEntry()
    for _, theme in pairs(themeOrder) do
      addThemeEntry(theme.id)
    end
  end
  
  -- -- --
  
  function _ENV.themeSettings()
    return themes[mg.settings.theme].settingsModule
  end
  
  local themeSettings = { }
  themeSettings.__index = themeSettings
  
  function themeSettings:init() end
  function themeSettings:save() end
  
  function tp:init()
    --
  end
  
  function tp:onSwitch()
    local theme = themes[mg.settings.theme]
    if not theme.settingsModule then
      -- set up settings table
      if not mg.settings.themeSettings then mg.settings.themeSettings = { } end
      local tst = util.mergeTable({ }, theme.defaultSettings or { })
      util.mergeTable(tst, mg.settings.themeSettings[theme.id] or { })
      mg.settings.themeSettings[theme.id] = tst -- install
      
      -- and the module itself
      local ts = setmetatable({ theme = theme, settings = tst }, themeSettings)
      theme.settingsModule = ts
      
      mg.cfg.assetPath = theme.path
      mg.widgetContext = ts
      require(theme.path .. "settings.lua")
      ts.page = mg.createImplicitLayout(ts.contents or ts.layout, tp.stack, { mode = "vertical", expandMode = {2, 2} })
      ts:init()
    end
    
    for _, pg in pairs(tp.stack.children) do
      pg:setVisible(pg == theme.settingsModule.page)
    end
  end
  
  function tp:save()
    for _, t in pairs(themes) do
      if t.settingsModule then t.settingsModule:save() end
    end
  end
  
  
end
do
  -- Project FR: Localized strings for the General settings tab
  local generalT = {
    title = _T("general.generalTitle", "General"),
    quickbarDismissLabel = _T("general.dismissQuickbar", "Dismiss Quickbar on selection"),
    scrollingMode = _T("general.scrollingMode", "Scrolling mode"),
    wheelFling = _T("general.wheelFling", "Wheel & Fling"),
    wheelOnly = _T("general.wheelOnly", "Wheel only"),
    flingOnly = _T("general.flingOnly", "Fling only")
  }
  ----------------------------------------------
  local p = m:page { title = generalT.title, icon = "settings.icon.png",
    contents = {
      {
        { type = "checkBox", id = "quickbarAutoDismiss", checked = default(mg.settings.quickbarAutoDismiss, true) },
        { type = "label", text = generalT.quickbarDismissLabel } },
      8, -- spacer
      { -- sidebars
        { -- left
          { type = "panel", style = "convex", children = {
            { type = "label", text = generalT.scrollingMode, inline = true },
              { { type = "checkBox", id = "scrollWF", radioGroup = "scrollMode", value = {true, true} }, { type = "label", text = generalT.wheelFling } },
              { { type = "checkBox", id = "scrollW", radioGroup = "scrollMode", value = {true, false} }, { type = "label", text = generalT.wheelOnly } },
              { { type = "checkBox", id = "scrollF", radioGroup = "scrollMode", value = {false, true} }, { type = "label", text = generalT.flingOnly } },
          } },
        },
        {"spacer"}, -- right (blank for now)
      }
    }
  }
  
  function p:init()
    -- load scroll mode
    local sm = mg.settings.scrollMode or {true, true}
    if sm[1] and not sm[2] then p.scrollW:setChecked(true)
    elseif sm[2] and not sm[1] then p.scrollF:setChecked(true)
    else p.scrollWF:setChecked(true) end -- done like this so "both" is selected if neither flag is set
  end
  
  function p:save()
    mg.settings.quickbarAutoDismiss = p.quickbarAutoDismiss.checked
    mg.settings.scrollMode = p.scrollWF:getGroupValue()
  end
  
end
--local aaa = m:page { title = "Another tab's testing" }
