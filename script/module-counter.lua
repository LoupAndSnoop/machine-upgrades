--This file's job is to take in a ModuleEffects and output a table of how many of what modules are needed to make it happen.


local module_counter = {}
local OTHER_MODDER_MESSAGE = "\n\nPlease let that mod's creator know: \"Please blacklist any modules with 'mupgrade' in the name to avoid the crash.\"\n\n"

--All modules that belong to us
--local module_names = {"mupgrade-module-prod", "mupgrade-module-quality", "mupgrade-module-speed", "mupgrade-module-efficiency","mupgrade-module-pollution"}
local modules = {}
local module_effect_categories = {}
local all_modules = prototypes.get_item_filtered({{filter = "type", type = "module"}})
for _, entry in pairs(all_modules) do
    if prototypes.get_history("module", entry.name).created == "machine-upgrades" then
        table.insert(modules, entry)
        assert(table_size(entry.module_effects) == 1, "This module prototype has multiple effects! Someone else messed with this module: " 
            .. entry.name .. ".\nEffects = " .. serpent.line(entry.module_effects) 
            .. ".\n\n Mods that are causing the crash: " .. serpent.line(prototypes.get_history("module", entry.name).changed or {})
            .. OTHER_MODDER_MESSAGE)
        for key in pairs(entry.module_effects) do 
            if module_effect_categories[key] then table.insert(module_effect_categories[key], entry)
            else module_effect_categories[key] = {entry} end
        end
    end
end


--Show all the mods that are editting these prototypes
local function display_history(prototype1, prototype2)
    local mods_affecting1 = prototypes.get_history("module", prototype1.name).changed
    local mods_affecting2 = prototypes.get_history("module", prototype2.name).changed
    local all_mods = mupgrade_lib.hashset_union(mupgrade_lib.array_to_hashset(mods_affecting1),
                    mupgrade_lib.array_to_hashset(mods_affecting2))
    local all_mods = mupgrade_lib.hashset_to_array(all_mods)
    return "\n\nMod(s) causing the crash: " .. serpent.line(all_mods) .. OTHER_MODDER_MESSAGE
end

--Now I need to get two for each category. Positive and negative.
local module_table = {}
for category, modules in pairs(module_effect_categories) do
    assert(table_size(modules) == 2, "I'm expecting to find exactly 1 positive and 1 negative module under this category (" 
        .. category .. "), but I found these: " .. serpent.block(modules))
    assert(modules[1].module_effects[category] * modules[2].module_effects[category] < 0, "I expected the modules for this category (" .. category 
        .. ") to have effects that are opposite in sign! " .. serpent.block(modules)
        .. display_history(modules[1], modules[2]))
    assert(math.abs(modules[1].module_effects[category]) == math.abs(modules[2].module_effects[category]), "Positive and negative modules for this category (" .. category
        .. ") were supposed to have equal magnitude in effect, but opposite sign! " .. serpent.block(modules)
        .. display_history(modules[1], modules[2]))
    local positive_index = (modules[1].module_effects[category] > 0) and 1 or 2
    module_table[category] = {
        positive_module_name = modules[positive_index].name,
        module_magnitude = modules[positive_index].module_effects[category],
        negative_module_name = modules[3-positive_index].name,
    }
end




---Module effects go in. Out goes a dictionary of how many of what modules are needed to make that effect. Just for 1 level's worth.
---@param effect ModuleEffects
---@return table<string, uint> modules Dictionary of modules => how many need to be added
---@return uint total_modules total number of modules for this effect
function module_counter.effect_to_module_counts(effect)
    local modules = {}
    local total_modules = 0
    for category, strength in pairs(effect) do
        local mod_magnitude = module_table[category].module_magnitude
        local mod_count = math.floor(math.abs(strength) / mod_magnitude + 0.01)
        local mod_name
        if strength < 0 then mod_name = module_table[category].negative_module_name
        else mod_name = module_table[category].positive_module_name end

        assert(mod_count > 0, "Got a non-zero number of required modules!")
        modules[mod_name] = mod_count --table.insert(modules, {mod_name, mod_count})
        total_modules = total_modules + mod_count
    end

    return modules, total_modules
end


---Output number of times this technology should count as researched.
---@param technology LuaTechnology
---@return int research_count
local function technology_counter(technology)
    if technology.researched then
        return technology.level - technology.prototype.level + 1
    else return technology.level - technology.prototype.level
    end
end

    --[[
    if not technology.upgrade then
        if technology.researched then return technology.level
        else return technology.level - 1 end --Not researched, and not an upgrade
    else --It is an upgrade 
        local under_level = 0
        for _, parent in pairs(technology.prerequisites) do
            if parent.upgrade then under_level = parent.level; break end
        end

        if technology.researched then return technology.level - under_level
        else return technology.level - under_level - 1 end
    end]]

---Get a table that includes the total moduling for the given beacon.
---@param entity_name string
---@param force LuaForce relevant luaforce
---@return table<string, uint> module_total table of module-name => module count
---@return uint total_modules Count of total modules
function module_counter.get_total_moduling(entity_name, force)
    local tech_effects = storage.linked_entity_prototypes[entity_name]
    if not tech_effects then return {}, 0 end
    
    local module_total = {}
    local total_modules = 0
    for _, effect in pairs(tech_effects) do
        --Need to find out how much that technology applies for this force
        local multiplier = technology_counter(force.technologies[effect.technology_name])
        if multiplier == 0 then goto continue end --No contribution

        for module_name, count in pairs(effect.modules) do
            count = count * multiplier
            total_modules = total_modules + count
            if not module_total[module_name] then module_total[module_name] = count
            else module_total[module_name] = module_total[module_name] + count
            end
        end
        ::continue::
    end

    return module_total, total_modules
end



return module_counter