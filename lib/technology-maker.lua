
local modifier_key = {
    productivity = {name = {"description.productivity-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-red.png"},
    speed = {name = {"description.speed-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-cyan.png"},
    efficiency = {name = {"description.efficiency-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon.png"},
    pollution = {name = {"description.pollution-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-orange.png"},
    quality = {name = {"description.quality-bonus"}, icon = "__machine-upgrades__/graphics/upgrade-subicon-purple.png"},
}

---Make a stock technology effect, by inputting a base IconData 
---(which should really be an IconData for the machine!). Usage is in a technology prototype:
---effects = {blah, blah, mupgrade_lib.make_modifier(...), blah}
---This doesn't make the effect actually happen, but is to set up the technology
---@param base_icon data.IconData | data.IconData[] IconData for the base of the modifier
---@param modifier string? Optional string. Should be nil, "speed", "productivity", "efficiency", or "quality". This will make the upgrade icon match color
---@param machine_name string? Designation for a localized string for the machine's name for the effect description. It has a default if not specified
---@param stated_effect_strength double Stated effect strength (as a percent)
function mupgrade_lib.make_modifier(base_icon, modifier, machine_name, stated_effect_strength)
    assert(modifier_key[modifier] or (not modifier), "Invalid modifier was passed in. No modifier is named: " .. tostring(modifier))
    local modifier_data = modifier_key[modifier] or modifier_key.productivity

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
        " ", modifier_data.name, ": " .. sign .. tostring(stated_effect_strength) .. "%"}

    --Make the actual effect
    local effect = {
        type = "nothing",
        icons = icons,
        effect_description = full_description,
    }
    return effect
end

--Test technology (example)
table.insert(data.raw.technology["automation-science-pack"].effects,
    mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-1.png"}, "speed", "assembler", 10))