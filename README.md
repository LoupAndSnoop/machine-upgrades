[![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/CaDJzEj557)[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/LoupAndSnoop/rubia)
Reach me fastest on Discord.
---------------------

This mod allows you to make technologies upgrade a machine like with module effects. It works by secretly making invisible beacons on every single entity of a given type automatically. 

Look at **test-suite.lua** to see actual working usage.

# How to Use
For convenience, data can be passed in using a type called MUpgradeData. Input something like this in data stage:
local my_upgrade_data = {
    {
        handler = "Assembler-speed-boosting",
        technology_name = "steel-processing",
        modifier_icon = {icon="__base__/graphics/icons/electric-furnace.png"},
        entity_names = {"electric-furnace", "oil-refinery"},
        module_effects = {speed = 0.3, pollution = -0.1},
        effect_name = nil, --would make an effect that says "Electric Furnace: -10% Productivity
    },
    {
        handler = "Actually_uses_assemblers",
        technology_name = "steam-power",
        modifier_icon = {icon="__base__/graphics/icons/chemical-plant.png"},
        entity_names = {"assembling-machine-2"},
        module_effects = {productivity = -0.1, consumption = -0.1, quality = 0.2},
        effect_name = "My custom string", --would make an effect that says "My custom string: -10% Productivity
    }
}

local mupgrades = require("__machine-upgrades__.lib.technology-maker")
mupgrades.handle_modifier_data(my_upgrade_data)
---------
# Manual usage
Not recommended. If you want full manual control, the most important functions in this mod are:
    - mupgrade_lib.make_modifier : Use this in data stage to create the desired effect in a technology.
    - mupgrade_lib.add_id_flag : Use this to safely add the get-by-unit-number flag to an entity.
    - remote.call("machine-upgrades-techlink", "add_technology_effect", technology_name, entity_name, effect, entity_handler): Use this in control stage in an event callback to tie a specific entity prototype and effect to the technology's research progress.
---------

Note that entity_handler should be matched to the same entity_name(s) to save on UPS.

Thanks: plexpt for the Big Data String 2 mod, used in packing data for more convenience.