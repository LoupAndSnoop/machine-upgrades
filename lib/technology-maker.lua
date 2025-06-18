local mupgrade_tech_maker = {}
local AUTO_PACK_PREFIX = mupgrade_lib.AUTO_PACK_PREFIX
mupgrade_tech_maker.add_id_flag = mupgrade_lib.add_id_flag

--Make the entry for a given modifier
local function make_modifier_key(name, color_string) return {
    name = {name},
    icon_small = "__machine-upgrades__/graphics/upgrade-subicon-" .. color_string .. ".png",
    icon_big = "__machine-upgrades__/graphics/upgrade-subicon-256-" .. color_string .. ".png"
}
end
local modifier_key = {
    productivity = make_modifier_key("description.productivity-bonus", "red"),
    speed = make_modifier_key("description.speed-bonus", "cyan"),
    efficiency = make_modifier_key("description.consumption-bonus", "green"),
    pollution = make_modifier_key("description.pollution-bonus", "orange"),
    quality = make_modifier_key("description.quality-bonus", "purple"),
}
--Easier aliases
modifier_key["prod"] = modifier_key["productivity"];
modifier_key["eff"] = modifier_key["efficiency"];
modifier_key["consumption"] = modifier_key["efficiency"];
--modifier_key["qual"] = modifier_key["quality"];
--For pretty print in error logging
local valid_modifier_names = {}
for key in pairs(modifier_key) do table.insert(valid_modifier_names, key) end

---@class (exact) MUpgradeData The full info for a mupgrade effect. This encodes the data of exactly what effect(s) to apply, to which entities, when whatever technology is researched. This can be conveniently parsed in both data stage and control stage
---@field handler string This is a permanent string to use to uniquely identify everything associated with this when we start searching for entities at runtime.
---@field technology_name string Name of the technology prototype to which this will be tied
---@field modifier_icon data.IconData | data.IconData[] Icon for the effect(s) to show on the technology
---@field entity_names string[] Array of strings of entity names for everything affected
---@field effect_name data.LocalisedString | string? Entity name of the machine to use in the effect modifier. Defaults to the first entry in the entity_names array
---@field module_effects ModuleEffects module effects to be assigning to everything included
local MUpgradeData = {}



---Make a stock technology effect, by inputting a base IconData 
---(which should really be an IconData for the machine!). Usage is in a technology prototype:
---effects = {blah, blah, mupgrade_tech_maker.make_modifier(...), blah}
---This doesn't make the effect actually happen, but is to set up the technology
---@param base_icon data.IconData | data.IconData[] IconData for the base of the modifier
---@param modifier_name string? Optional string. Should be nil, "speed", "productivity", "efficiency", or "quality". This will make the upgrade icon match color
---@param machine_name data.LocalisedString | string? Designation for a localized string for the machine's name for the effect description. It has a default if not specified
---@param stated_effect_strength double Stated effect strength (as a percent)
---@param entity_names string[]? Array of names of entities to use when displaying all the machines to be affected by this modifier
function mupgrade_tech_maker.make_modifier(base_icon, modifier_name, machine_name, stated_effect_strength, entity_names)
    assert(modifier_key[modifier_name] or (not modifier_name), "Invalid modifier was passed in. No modifier is named: " 
        .. tostring(modifier_name) .. "\nValid names are actually: " .. serpent.line(valid_modifier_names))
    local modifier_data = modifier_key[modifier_name] or modifier_key.productivity

    local upgrade_icondata = {
        icon = modifier_data.icon_small,
        icon_size = 64
    }

    --Assemble the full icon
    local icons
    if base_icon.icon then --Then it is one icon data
        icons = {base_icon, upgrade_icondata}
    else --List of icon data
        icons = util.table.deepcopy(base_icon)
        table.insert(icons, upgrade_icondata)
    end

    --Make the description
    local sign = (stated_effect_strength > 0) and "+" or "-"
    local full_description = {""}
    for _, each_name in pairs(entity_names or {}) do
        table.insert(full_description, "[entity=" .. each_name .. "] ")
        table.insert(full_description, {"entity-name." .. each_name})
        table.insert(full_description, "\n")
    end
    local post_description = {machine_name or "modifier-description.mupgrade-default-effect-description",
         ": ", modifier_data.name, " " .. sign .. tostring(math.abs(stated_effect_strength)) .. "%"}
    for _, entry in pairs(post_description) do
        table.insert(full_description, entry)
    end
    --local full_description = {"", machine_name or "modifier-description.mupgrade-default-effect-description",
     --   ": ", modifier_data.name, " " .. sign .. tostring(math.abs(stated_effect_strength)) .. "%"}

    --Make the actual effect
    local effect = {
        type = "nothing",
        icons = icons,
        effect_description = full_description,
    }
    return effect
end


---Make a stock technology icon, with the relevant upgrade icon placed over it.
---Usage: icons = mupgrade_tech_maker.make_technology_icon({icon = "__base__/my_icon.png", icon_size = 256}, "efficiency")
---@param base_icon data.IconData | data.IconData[] IconData for the base of the modifier
---@param modifier_name string? Optional string. Should be nil, "speed", "productivity", "efficiency", or "quality". This will make the upgrade icon match color
---@return data.IconData[] icons Multiple icons, to be passed into "icons" field
function mupgrade_tech_maker.make_technology_icon(base_icon, modifier_name)
    assert(modifier_key[modifier_name] or (not modifier_name), "Invalid modifier was passed in. No modifier is named: " 
        .. tostring(modifier_name) .. "\nValid names are actually: " .. serpent.line(valid_modifier_names))
    local modifier_data = modifier_key[modifier_name] or modifier_key.productivity

    local upgrade_icondata = {icon = modifier_data.icon_big, icon_size = 256}

    --Assemble the full icon
    local icons
    if base_icon.icon then --Then it is one icon data
        icons = {base_icon, upgrade_icondata}
    else --List of icon data
        icons = util.table.deepcopy(base_icon)
        table.insert(icons, upgrade_icondata)
    end

    return icons
end

---Find a prototype tied to a specific entity name.
---@param entity_name string
local function find_entity_prototype(entity_name)
    assert(entity_name, "Null entity name!")
    for type in pairs(defines.prototypes.entity) do
        local prototype = data.raw[type] and data.raw[type][entity_name]
        if prototype then return prototype end
    end
    error("No entity prototype found by the name: " .. entity_name) 
end



----Sending MUpgradeData to control stage
---@param mupgrade_data MUpgradeData
local function pack_for_control_stage(mupgrade_data)
    local bigpack = require("__machine-upgrades__.lib.big-data-string-pack")
    data:extend{bigpack(AUTO_PACK_PREFIX .. mupgrade_data.handler, serpent.dump(mupgrade_data))}
end


---Go handle all the relevant MUpgrade data, making all the effects on the relevant techs, during data stage.
---@param mupgrade_data_array MUpgradeData[]
---@param manual_pack boolean? (default to false). If set false, then the MUpgrade mod will automatically pack up and take care of everything in control stage as well. Set false to do it full auto.
function mupgrade_tech_maker.handle_modifier_data(mupgrade_data_array, manual_pack)
    for _, mupgrade_data in pairs(mupgrade_data_array) do
        assert(mupgrade_data.entity_names, "No entity names are included!")
        assert(table_size(mupgrade_data.entity_names) > 0, "No entity names are in the effect!")

        if not mupgrade_data.effect_name then 
            mupgrade_data.effect_name = {"entity-name." .. mupgrade_data.entity_names[1]}
        end
        local technology = data.raw["technology"][mupgrade_data.technology_name]
        assert(technology, "No technology prototype found by the name: " .. mupgrade_data.technology_name)

        --Make sure all the entities have the ID flag:
        for _, name in pairs(mupgrade_data.entity_names) do
            mupgrade_tech_maker.add_id_flag(find_entity_prototype(name))
        end

        --Go add the effect to the existing technology prototype.
        for effect_name, effect_str in pairs(mupgrade_data.module_effects) do
            local stated_strength = effect_str * ((effect_name == "quality") and 10 or 100)

            local modifier = mupgrade_tech_maker.make_modifier(mupgrade_data.modifier_icon, effect_name, mupgrade_data.effect_name,
                stated_strength, mupgrade_data.entity_names)
            if not technology.effects then technology.effects = {modifier}
            else table.insert(technology.effects, modifier)
            end
        end

        if (not manual_pack) then pack_for_control_stage(mupgrade_data) end
    end
end

--Put it all in our global variable, for alternate access.
for x, y in pairs(mupgrade_tech_maker) do mupgrade_lib[x] = y end

return mupgrade_tech_maker

--Test technology (example)
--table.insert(data.raw.technology["automation-science-pack"].effects,
--    mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-1.png"}, "speed", "assembler", 10))