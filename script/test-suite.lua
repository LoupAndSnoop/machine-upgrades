--This test suite also functions as an example for how to use this in other mods.
if not mupgrade_lib.DEBUG_MODE then return end

----------------------

--#region Example 1: Multiple entities at once via the easy custom mupgrade data

---Define this object the same way in both data and control stage
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

if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    --Option 1: Easiest. Full auto mode. Call this function in data stage, and you are done!
    mupgrade_lib.handle_modifier_data(my_upgrade_data)

end
----Option 2: Full manual control, where you can decide event subscription
--[[
----You can legit copy-paste this next block of code into a file that is run in both data and control stage.
-- What to do in Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    mupgrade_lib.handle_modifier_data(my_upgrade_data, true)
--What to do in Control stage
elseif script then
    local function register() remote.call("machine-upgrades-techlink", "add_upgrade_data", my_upgrade_data) end

    --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_init("test-suite-1", register) --This particular event handler would need a unique string here
    event_lib.on_configuration_changed("test-suite-1", register)
end

--------------------

--#region Example 2: Assembler-2 gets speed in automation science pack
-- What to do in Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    table.insert(data.raw.technology["automation-science-pack"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-2.png"},
        "speed", {"entity-name.assembling-machine-2"}, 10))
    mupgrade_lib.add_id_flag(data.raw["assembling-machine"]["assembling-machine-2"])

--What to do in Control stage
elseif script then
    local function register1()
        remote.call("machine-upgrades-techlink", "add_technology_effect", 
                "automation-science-pack", "assembling-machine-2", {speed=0.1}, "Assembler1")
    end

    --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_init("test-suite", register1)
    event_lib.on_configuration_changed("test-suite", register1)
end
--#endregion

-------------------
--#region Example 3: Multiple entities at once (which is substantially more UPS-efficient!)
-- What to do in Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    table.insert(data.raw.technology["logistic-science-pack"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/chemical-plant.png"}, "productivity",
        "My unlocalized multiple entity text", 10))
    table.insert(data.raw.technology["logistic-science-pack"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/chemical-plant.png"}, "efficiency",
        {"entity-name.chemical-plant"}, -30))
    mupgrade_lib.add_id_flag(data.raw["assembling-machine"]["chemical-plant"])
    mupgrade_lib.add_id_flag(data.raw["mining-drill"]["electric-mining-drill"])

--What to do in Control stage
elseif script then
    local function register2()
        remote.call("machine-upgrades-techlink", "add_technology_effect", 
                "logistic-science-pack", {"chemical-plant", "electric-mining-drill"},
                {productivity=0.1, consumption= -0.3}, "I think I'll call this chemical plant and drill")
    end

    --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_init("test-suite-2", register2)
    event_lib.on_configuration_changed("test-suite-2", register2)
end
--#endregion



--#region Example 4: An infinite technology
-- What to do in Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    table.insert(data.raw.technology["physical-projectile-damage-7"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-3.png"},
            "pollution", {"entity-name.assembling-machine-3"}, 15))
    mupgrade_lib.add_id_flag(data.raw["assembling-machine"]["assembling-machine-3"])

--What to do in Control stage
elseif script then
    local function register3()
        remote.call("machine-upgrades-techlink", "add_technology_effect", 
                "physical-projectile-damage-7", "assembling-machine-3", {pollution=0.15}, "Assembler3")
    end

    --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_init("test-suite-3", register3)
    event_lib.on_configuration_changed("test-suite-3", register3)
end
--#endregion


--[[
--#region Helpful console commands:
--Get linked positions
/c __machine-upgrades__ game.print(serpent.block(storage.compound_entity_positions))

--Find out what we are logging
/c __machine-upgrades__ mupgrade.print_registry_stats()

--Show what is actually in each tech link
/c __machine-upgrades__ mupgrade_lib.print_technology_links()

--Show all event registrations
/c __machine-upgrades__ mupgrade.print_events()

--#endregion
]]


--[[
-------Scrapped test for items that lack module capability
-- What to do in Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    table.insert(data.raw.technology["automation-science-pack"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/steel-furnace.png"}, "productivity", "Burner furnaces text", 10))
    mupgrade_lib.add_id_flag(data.raw["furnace"]["steel-furnace"])
    mupgrade_lib.add_id_flag(data.raw["furnace"]["stone-furnace"])

--What to do in Control stage
elseif script then
    local function register2()
        remote.call("machine-upgrades-techlink", "add_technology_effect", 
                "automation-science-pack", {"steel-furnace", "stone-furnace"},
                {productivity=0.1, consumption= -0.2}, "my_burner_furnaces")
    end

    --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_init("test-suite-2", register2)
    event_lib.on_configuration_changed("test-suite-2", register2)
end
]]



