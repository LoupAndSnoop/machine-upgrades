
local modifier_key = {
    productivity = {name = {"description.productivity-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-red.png"},
    speed = {name = {"description.speed-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-cyan.png"},
    efficiency = {name = {"description.consumption-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon.png"},
    pollution = {name = {"description.pollution-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-orange.png"},
    quality = {name = {"description.quality-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-purple.png"},
}
--Easier aliases
modifier_key["prod"] = modifier_key["productivity"];
modifier_key["eff"] = modifier_key["efficiency"];
modifier_key["qual"] = modifier_key["quality"];
--For pretty print in error logging
local valid_modifier_names = {}
for key in pairs(modifier_key) do table.insert(valid_modifier_names, key) end

---Make a stock technology effect, by inputting a base IconData 
---(which should really be an IconData for the machine!). Usage is in a technology prototype:
---effects = {blah, blah, mupgrade_lib.make_modifier(...), blah}
---This doesn't make the effect actually happen, but is to set up the technology
---@param base_icon data.IconData | data.IconData[] IconData for the base of the modifier
---@param modifier_name string? Optional string. Should be nil, "speed", "productivity", "efficiency", or "quality". This will make the upgrade icon match color
---@param machine_name data.LocalisedString | string? Designation for a localized string for the machine's name for the effect description. It has a default if not specified
---@param stated_effect_strength double Stated effect strength (as a percent)
function mupgrade_lib.make_modifier(base_icon, modifier_name, machine_name, stated_effect_strength)
    assert(modifier_key[modifier_name] or (not modifier_name), "Invalid modifier was passed in. No modifier is named: " 
        .. tostring(modifier_name) .. "\nValid names are actually: " .. serpent.line(valid_modifier_names))
    local modifier_data = modifier_key[modifier_name] or modifier_key.productivity

    local upgrade_icondata = {
        icon = modifier_data.icon,
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
    local full_description = {"", machine_name or "modifier-description.mupgrade-default-effect-description",
        ": ", modifier_data.name, " " .. sign .. tostring(math.abs(stated_effect_strength)) .. "%"}

    --Make the actual effect
    local effect = {
        type = "nothing",
        icons = icons,
        effect_description = full_description,
    }
    return effect
end

--Test technology (example)
--table.insert(data.raw.technology["automation-science-pack"].effects,
--    mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-1.png"}, "speed", "assembler", 10))