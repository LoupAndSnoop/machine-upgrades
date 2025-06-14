--Defines fake modules for the mod to use, and a fake beacon to put them in

--#region modules
local icon_tint = {1,0.5,1}
local modules = {
    {
      name = "mupgrade-module-prod",
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      category = "productivity",
      color_hint = { text = "P" },
      order = "zzzzzz[hidden]--b[hidden-modules]-a",
      effect =  {productivity = 0.05},
      beacon_tint =
      {
        primary = {0, 1, 0},
        secondary = {0.370, 1.000, 0.370, 1.000}, -- #5eff5eff
      },
    },
    {
      name = "mupgrade-module-speed",
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      color_hint = { text = "S" },
      category = "speed",
      order = "zzzzzz[hidden]--b[hidden-modules]-b",
      effect =  {speed=0.05},
      beacon_tint =
      {
        primary = {0.441, 0.714, 1.000, 1.000}, -- #70b6ffff
        secondary = {0.388, 0.976, 1.000, 1.000}, -- #63f8ffff
      },
    },
    {
      name = "mupgrade-module-quality",
      color_hint = { text = "Q" },
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      category = "quality",
      order = "zzzzzz[hidden]--b[hidden-modules]-d",
      effect =  {quality = 0.1},
      beacon_tint =
      {
        primary = {0.441, 0.714, 1.000, 1.000}, -- #70b6ffff
        secondary = {0.388, 0.976, 1.000, 1.000}, -- #63f8ffff
      },
    },
    {
      name = "mupgrade-module-efficiency",
      icons = {{icon="__base__/graphics/icons/efficiency-module.png", tint=icon_tint}},
      category = "efficiency",
      color_hint = { text = "E" },
      order = "zzzzzz[hidden]--b[hidden-modules]-c",
      effect =  {consumption = -0.05},
      beacon_tint =
      {
        primary = {0, 1, 0},
        secondary = {0.370, 1.000, 0.370, 1.000}, -- #5eff5eff
      },
    },
    {
      name = "mupgrade-module-pollution",
      icons = {{icon="__base__/graphics/icons/efficiency-module.png", tint=icon_tint}},
      category = "efficiency",
      color_hint = { text = "E" },
      order = "zzzzzz[hidden]--b[hidden-modules]-e",
      effect =  {pollution = -0.05},
      beacon_tint =
      {
        primary = {0, 1, 0},
        secondary = {0.370, 1.000, 0.370, 1.000}, -- #5eff5eff
      },
    },
}

if mods["quality"] then
    local quality_module = {
      name = "mupgrade-module-quality",
      color_hint = { text = "Q" },
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      category = "quality",
      order = "zzzzzz[hidden]--b[hidden-modules]-d",
      effect =  {quality = 0.1},
      beacon_tint =
      {
        primary = {0.441, 0.714, 1.000, 1.000}, -- #70b6ffff
        secondary = {0.388, 0.976, 1.000, 1.000}, -- #63f8ffff
      },
    }
    table.insert(modules, quality_module)
end


local module_common = {
  type = "module",
  requires_beacon_alt_mode = false,
  hidden = true,
  hidden_in_factoriopedia = true,
  stack_size = 50,
  weight = 999999 * kg,
  tier = 1,
  art_style = "vanilla",
}

for _, module in  pairs(modules) do
  for key, value in pairs(module_common) do
    module[key] = value
  end
end
data:extend(modules)

--#endregion

--#region Beacon

local mupgrade_beacon = util.table.deepcopy(data.raw["beacon"]["beacon"])
mupgrade_beacon.name = "mupgrade-beacon"
mupgrade_beacon.icons = util.extract_icon_info(mupgrade_beacon)
mupgrade_beacon.hidden = true
mupgrade_beacon.hidden_in_factoriopedia = true
mupgrade_beacon.map_color = nil
mupgrade_beacon.friendly_map_color = nil
mupgrade_beacon.minable.result = nil
mupgrade_beacon.energy_source = { type = "void" }
mupgrade_beacon.allowed_effects = { "consumption", "speed", "productivity", "pollution"}
if mods["quality"] then table.insert(mupgrade_beacon.allowed_effects, "quality") end
mupgrade_beacon.supply_area_distance = 0.5
mupgrade_beacon.module_slots = 100




--#endregion



--[[
data:extend({
    {
      type = "module",
      name = "mupgrade-module-prod",
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      category = "productivity",
      color_hint = { text = "P" },
      tier = 1,
      order = "zzzzzz[hidden]--b[hidden-modules]-a",
      stack_size = 50,
      weight = 999999 * kg,
      effect =  {consumption = -1, speed=-0.02},
      beacon_tint =
      {
        primary = {0, 1, 0},
        secondary = {0.370, 1.000, 0.370, 1.000}, -- #5eff5eff
      },
      art_style = "vanilla",
      requires_beacon_alt_mode = false,
      hidden = true, hidden_in_factoriopedia = true,
    },
    {
      type = "module",
      name = "mupgrade-module-speed",
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      color_hint = { text = "S" },
      category = "speed",
      tier = 1,
      order = "zzzzzz[hidden]--b[hidden-modules]-b",
      stack_size = 50,
      weight = 999999 * kg,
      effect =  {speed=0.05},
      beacon_tint =
      {
        primary = {0.441, 0.714, 1.000, 1.000}, -- #70b6ffff
        secondary = {0.388, 0.976, 1.000, 1.000}, -- #63f8ffff
      },
      art_style = "vanilla",
      requires_beacon_alt_mode = false,
      hidden = true, hidden_in_factoriopedia = true,
    },
        {
      type = "module",
      name = "mupgrade-module-quality",
      color_hint = { text = "Q" },
      icons = {{icon="__base__/graphics/icons/productivity-module.png", tint=icon_tint}},
      category = "quality",
      tier = 1,
      order = "zzzzzz[hidden]--b[hidden-modules]-d",
      stack_size = 50,
      weight = 999999 * kg,
      effect =  {quality = 0.1},
      beacon_tint =
      {
        primary = {0.441, 0.714, 1.000, 1.000}, -- #70b6ffff
        secondary = {0.388, 0.976, 1.000, 1.000}, -- #63f8ffff
      },
      art_style = "vanilla",
      requires_beacon_alt_mode = false,
      hidden = true, hidden_in_factoriopedia = true,
    },
    {
      type = "module",
      name = "mupgrade-module-efficiency",
      icons = {{icon="__base__/graphics/icons/efficiency-module.png", tint=icon_tint}},
      category = "efficiency",
      color_hint = { text = "E" },
      tier = 1,
      order = "zzzzzz[hidden]--b[hidden-modules]-c",
      stack_size = 50,
      weight = 999999 * kg,
      effect =  {consumption = -0.05},
      beacon_tint =
      {
        primary = {0, 1, 0},
        secondary = {0.370, 1.000, 0.370, 1.000}, -- #5eff5eff
      },
      art_style = "vanilla",
      requires_beacon_alt_mode = false,
      hidden = true, hidden_in_factoriopedia = true,
    },
})


]]