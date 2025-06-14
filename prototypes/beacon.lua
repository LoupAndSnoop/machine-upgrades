--#region Beacon
--Make it resist all damage
local all_resistances = {}
for _, type in pairs(data.raw["damage-type"]) do
  table.insert(all_resistances, {type = type.name, percent = 100})
end
local mupgrade_beacon = 
  {
    type = "beacon",
    name = "mupgrade-beacon",
    icons = {{icon = "__base__/graphics/icons/beacon.png", tint = {1,0.7,1}}},
    order = "zzzzzz[hidden]-mua[mu beacon]-a",
    flags = {"placeable-player", "not-rotatable", "not-blueprintable"},--"hide-alt-info", "player-creation"},
    --minable = {mining_time = 0.2, result = "beacon"},
    fast_replaceable_group = "beacon",

    --Death related
    max_health = 1000000,
    healing_per_tick = 100,
    is_military_target = false,
    resistances = all_resistances,
    hide_resistances = true,
    alert_when_damaged = false,
    create_ghost_on_death = false,
    corpse = nil,

    --Selecting related
    collision_box = {{-0.2, -0.2}, {0.1, 0.2}},
    collision_mask = {layers = {}},
    selection_box = {{-0.4, -0.4}, {0.4, 0.4}},
    selectable_in_game = false,

    --damaged_trigger_effect = hit_effects.entity(),
    --drawing_box_vertical_extension = 0.7,
    allowed_effects = {"consumption", "speed", "pollution", "productivity"},
    supply_area_distance = 0,
    
    map_color = nil,
    friendly_map_color = nil,
    hidden = true,
    hidden_in_factoriopedia = true,
    
    --Job-related
    energy_source = {type = "void"},
    energy_usage = "1kW",
    heating_energy = "0kW",
    distribution_effectivity = 1,
    distribution_effectivity_bonus_per_quality_level = 0,
    profile = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},--{1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
    beacon_counter = "same_type",
    module_slots = 200,
    icons_positioning =
    {
      {inventory_index = defines.inventory.beacon_modules, shift = {0, 0}, multi_row_initial_height_modifier = -0.3, max_icons_per_row = 2}
    },
  }



if mods["quality"] then table.insert(mupgrade_beacon.allowed_effects, "quality") end

--These are properties that are only needed for debugging.
local beacon_debug_properties = {
    radius_visualisation_picture =
    {
      filename = "__base__/graphics/entity/beacon/beacon-radius-visualization.png",
      priority = "extra-high-no-scale",
      width = 10,
      height = 10
    },
    graphics_set = util.table.deepcopy(data.raw.beacon.beacon.graphics_set),
    selection_priority = 100,
    selectable_in_game = true,
}
beacon_debug_properties.graphics_set.base_layer = "higher-object-above"
beacon_debug_properties.graphics_set.top_layer = "higher-object-above"
beacon_debug_properties.graphics_set.animation_layer = "higher-object-above"
local animation_list = beacon_debug_properties.graphics_set.animation_list
for _, entry in pairs(animation_list) do
    entry.animation.scale = 0.2--animation.scale and (animation.scale / 2) or 0.1
    for _, layer in pairs(entry.animation.layers or {}) do
        layer.scale = 0.2--layer.scale and (layer.scale / 2) or 0.1
    end
end

for key, value in pairs(beacon_debug_properties) do
  mupgrade_beacon[key] = value
end

data:extend({mupgrade_beacon})


--#endregion


--[[
local mupgrade_beacon = util.table.deepcopy(data.raw["beacon"]["beacon"])
mupgrade_beacon.name = "mupgrade-beacon"
mupgrade_beacon.icons = util.extract_icon_info(mupgrade_beacon)
mupgrade_beacon.hidden = true
mupgrade_beacon.hidden_in_factoriopedia = true
mupgrade_beacon.map_color = nil
mupgrade_beacon.friendly_map_color = nil
mupgrade_beacon.minable.result = nil
mupgrade_beacon.energy_source = { type = "void" }


mupgrade_beacon.selectable_in_game = false
mupgrade_beacon.collision_box = {{0,0},{0,0}}
mupgrade_beacon.selection_box = {{-0.1, -0.1}, {0.1, 0.1}}
mupgrade_beacon.collision_mask = {layers = {}}

mupgrade_beacon.allowed_effects = { "consumption", "speed", "productivity", "pollution"}
if mods["quality"] then table.insert(mupgrade_beacon.allowed_effects, "quality") end
mupgrade_beacon.distribution_effectivity = 1
mupgrade_beacon.distribution_effectivity_bonus_per_quality_level = 0
mupgrade_beacon.supply_area_distance = 1
mupgrade_beacon.module_slots = 100



    profile = {1,0.7071,0.5773,0.5,0.4472,0.4082,0.3779,0.3535,0.3333,0.3162,0.3015,0.2886,0.2773,0.2672,0.2581,0.25,0.2425,0.2357,0.2294,0.2236,0.2182,0.2132,0.2085,0.2041,0.2,0.1961,0.1924,0.1889,0.1856,0.1825,0.1796,0.1767,0.174,0.1714,0.169,0.1666,0.1643,0.1622,0.1601,0.1581,0.1561,0.1543,0.1524,0.1507,0.149,0.1474,0.1458,0.1443,0.1428,0.1414,0.14,0.1386,0.1373,0.136,0.1348,0.1336,0.1324,0.1313,0.1301,0.129,0.128,0.127,0.1259,0.125,0.124,0.123,0.1221,0.1212,0.1203,0.1195,0.1186,0.1178,0.117,0.1162,0.1154,0.1147,0.1139,0.1132,0.1125,0.1118,0.1111,0.1104,0.1097,0.1091,0.1084,0.1078,0.1072,0.1066,0.1059,0.1054,0.1048,0.1042,0.1036,0.1031,0.1025,0.102,0.1015,0.101,0.1005,0.1},
    impact_category = "metal",
    open_sound = {filename = "__base__/sound/open-close/beacon-open.ogg", volume = 0.25},
    close_sound = {filename = "__base__/sound/open-close/beacon-close.ogg", volume = 0.25},
    working_sound =
    {
      sound =
      {
        variations = sound_variations("__base__/sound/beacon", 2, 0.3),
        audible_distance_modifier = 0.33,
      },
      max_sounds_per_prototype = 3
    },
    water_reflection =
    {
      pictures =
      {
        filename = "__base__/graphics/entity/beacon/beacon-reflection.png",
        priority = "extra-high",
        width = 18,
        height = 29,
        shift = util.by_pixel(0, 55),
        variation_count = 1,
        scale = 5
      },
      rotate = false,
      orientation_to_variation = false
    }
      ]]