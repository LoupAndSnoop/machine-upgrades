--Make an interface to allow other mods to tell me: X machine should be getting X effect from whatever technology.

local module_counter = require("__machine-upgrades__/script/module-counter")
local beacon_manager = require("__machine-upgrades__/script/beacon-manager")
local entity_modifier = require("__machine-upgrades__/script/entity-modifier")

--#region Effect logging table
--@field technology_name string

---@class (exact) MUTechEffect
---@field entity_name string Name of actual entity prototype
---@field entity_handler string Unique string associated with this search, that won't change even if the entity_name changes.
---@field technology_name string Name of the technology prototype from which this effect starts
---@field effect ModuleEffects
---@field modules table<string, uint> Dictionary of counts of modules that make the effect (just 1 level worth)
local MUTechEffect={}


local function initialize_storage()
    ---@type table<string, MUTechEffect[]> string of technology prototype => TechEffects
    storage.linked_technologies = storage.linked_technologies or {}
    ---@type table<string, MUTechEffect[]> string of entity prototype name => TechEffects
    storage.linked_entity_prototypes = storage.linked_technologies or {}

    ---@type table<string, string> Dictionary of name of the actual entity prototype to entity_handler string 
    storage.entity_name_to_handler = storage.entity_name_to_handler or {}
end


---Whenever we have an update, register this entity to be updated.
---@param entity_name string
---@param force LuaForce? Optionally limit update to just that force
local function update_entity(entity_name, force)
    local entity_handler = storage.entity_name_to_handler[entity_name]
    assert(entity_handler, "No entity handler found for " .. entity_name)
    beacon_manager.request_entity_update(entity_handler, force)
end


---Add a new technology effect.
---@param new_effect MUTechEffect
local function add_technology_effect(new_effect)
    assert(prototypes.technology[new_effect.technology_name], "Invalid technology name: " .. new_effect.technology_name)
    --If technology has nothing in it, then need new list. Otherwise, add to the array.
    local tech_effects = storage.linked_technologies[new_effect.technology_name]
    if not tech_effects then
        storage.linked_technologies[new_effect.technology_name] = {new_effect}
    else --Has something in it, so we must check for overwriting
        local found = false
        for index, entry in pairs(tech_effects or {}) do
            if entry.entity_name == new_effect.entity_name then
                tech_effects[index] = new_effect
                found = true
                break
            end
        end
        if not found then table.insert(tech_effects, new_effect) end
    end

    --If entity has nothing in it, then need new list. Otherwise, add to the array.
    local entity_effects = storage.linked_entity_prototypes[new_effect.entity_name]
    if not entity_effects then
        storage.linked_entity_prototypes[new_effect.entity_name] = {new_effect}
    else 
        local found = false
        for index, entry in pairs(entity_effects or {}) do
            if entry.technology_name == new_effect.technology_name then
                entity_effects[index] = new_effect
                found = true;
                break
            end
        end
        if not found then table.insert(entity_effects, new_effect) end
    end

    update_entity(new_effect.entity_name)
end

---Remove a technology link between a specific entity and technology.
---@param technology_name string
---@param entity_name_input string | string[]
local function remove_technology_effect(technology_name, entity_name_input)
    local tech_effects = storage.linked_technologies[technology_name]
    --If technology has no linked effects, we're actually done.
    if not tech_effects then return end

    local entity_name_array = (type(entity_name_input) == "table") and entity_name_input or {entity_name_input--[[@as string]]}
    assert(table_size(entity_name_array) > 0, "Entity name array is empty!")

    for _, entity_name in pairs(entity_name_array) do
        --Remove a relevant effect.
        for index, entry in pairs(tech_effects or {}) do
            if entry.entity_name == entity_name then
                table.remove(tech_effects, index)
                break
            end
        end
        if tech_effects and table_size(tech_effects) == 0 then
            storage.linked_technologies[technology_name] = nil
        end

        --Go remove the relevant tech for the entity
        local entity_effects = storage.linked_entity_prototypes[entity_name]
        for index, entry in pairs(tech_effects or {}) do
            if entry.technology_name == technology_name then
                table.remove(entity_effects, index)
                break
            end
        end
        if entity_effects and table_size(entity_effects) == 0 then
            storage.linked_entity_prototypes[entity_name] = nil
        end

        update_entity(entity_name)
    end
end


--Remove ALL links. Include cleanup of beacons.
local function clear_all_effects()
    local entity_no_to_clear = {}
    for handler, entry in pairs(storage.modified_entity_registry) do
        for entity_no in pairs(entry.entity_hashset) do
            entity_no_to_clear[entity_no] = true
        end
    end 

    for entity_no in pairs(entity_no_to_clear) do
        beacon_manager.remove_beacon_from(entity_no)
    end

    storage.linked_entity_prototypes = {}
    storage.linked_technologies = {}

    entity_modifier.clear_cache()
end

---Return one big string that shows the links of all technologies. Used for debugging
local function show_all_links()
    local link_count = 0
    for _, entry in pairs(storage.linked_technologies or {}) do
        link_count = link_count + table_size(entry)
    end

    local string = "\nTechnologies linked (" .. tostring(table_size(storage.linked_technologies)) .. " technologies, "
        .. tostring(link_count) .. " total links):\n"
    for _, entry in pairs(storage.linked_technologies or {}) do
        for _, effect in pairs(entry) do
            string = "     " .. string .. tostring(effect.technology_name) .. " <=> " .. tostring(effect.entity_name) .. "\n"
        end
    end
    
    string = string .. "\nEntities linked (" .. tostring(table_size(storage.linked_entity_prototypes)) .. "):\n"
    for _, entry in pairs(storage.linked_entity_prototypes or {}) do
        for _, effect in pairs(entry) do
            string = "     " .. string .. tostring(effect.entity_name) .. " <=> " .. tostring(effect.technology_name) .. "\n"
        end
    end

    return string
end


_G.mupgrade_lib = mupgrade_lib or {}
--Print all technology effect links, for debugging purposes
function mupgrade_lib.print_technology_links()
    local string = show_all_links()
    log(string)
    game.print(string)
end


--Interface for other mods to tell us what links to make
remote.add_interface("machine-upgrades-techlink",{
    ---Add a specific effect to the given technology, to apply that module effect to the given entity.
    ---@param technology_name string
    ---@param entity_name string | string[]
    ---@param effect ModuleEffects
    ---@param entity_handler string Permanent string to reference that entity, so if the entity name changes/migrates, we don't have problems!
    ---@param auto_merge_handler boolean? If set true, then automatically merge handler with whatever was there previously. It is recommended to turn this on to merge with other mod.
    add_technology_effect = function(technology_name, entity_name, effect, entity_handler, auto_merge_handler)
        assert(prototypes.technology[technology_name],"Invalid technology name was passed: " .. technology_name)
        local entity_name_array = (type(entity_name) == "table") and entity_name or {entity_name--[[@as string]]}
        for _, each_entity_name in pairs(entity_name_array) do
            assert(prototypes.entity[each_entity_name],"Invalid entity name was passed: " .. each_entity_name)
            assert(prototypes.entity[each_entity_name].has_flag("get-by-unit-number"), "This entity needs the get-by-unit-number flag to function: " .. each_entity_name)
            assert(entity_handler ~= each_entity_name, "Entity handler should not match the entity name, to protect vs migration. See: " .. entity_handler)
        end

        local modules = module_counter.effect_to_module_counts(effect)
        --If no modules, then we actually want to do a removal
        if not modules or table_size(modules) == 0 then
            remove_technology_effect(technology_name, entity_name)
        end

        local filter = {name=entity_name}
        local is_unique, previous_handler = entity_modifier.is_unique_filter(filter)
        if not auto_merge_handler then
            assert(is_unique or (previous_handler == entity_handler), "We have two entity handlers that are different, but search for the same entity. Please clear the old handler: " 
                .. tostring(previous_handler) .. ", new handler was: " .. tostring(entity_handler) 
                .."\nThis check is here as a safeguard to prevent duplicate calls from the same mod. Consider the optional merge argument if you need to override.")
        --Auto-merge
        elseif not is_unique and previous_handler then entity_handler = previous_handler
        end
        
        --Make each effect
        for _, each_entity_name in pairs(entity_name_array) do
            storage.entity_name_to_handler[each_entity_name] = entity_handler
            local new_tech_effect = {
                technology_name = technology_name,
                entity_name = each_entity_name,
                entity_handler = entity_handler,
                effect = mupgrade_lib.deepcopy(effect),
                modules = modules,
            }
            add_technology_effect(new_tech_effect)
        end

        entity_modifier.create_entity_cache(entity_handler, filter)
        entity_modifier.assign_modifier(entity_handler, "update-beacon")
        entity_modifier.apply_auto_modifier(entity_handler)
    end,

    ---Remove the whole entity cache associated with this handler.
    ---@param entity_handler string
    remove_old_entity_handler = function(entity_handler) entity_modifier.remove_entity_cache(entity_handler) end,

    ---Remove whatever effect may be linking the two technologies.
    ---@param technology_name string
    ---@param entity_name string
    remove_technology_effect = function(technology_name, entity_name)
        assert(prototypes.technology[technology_name],"Invalid technology name was passed: " .. technology_name)
        local prototype = prototypes.entity[entity_name]
        assert(prototype,"Invalid entity name was passed: " .. entity_name)
        assert(prototype.has_flag("get-by-unit-number"), "This entity needs the get-by-unit-number flag to function: " .. entity_name)

        local old_handler = storage.entity_name_to_handler[entity_name]
        entity_modifier.remove_entity_cache(old_handler)

        remove_technology_effect(technology_name, entity_name)
    end,

    ---Print and log a record of all the technology effects currently in place by the mod.
    print_current_links = function() mupgrade_lib.print_links() end,

    ---Set up quickly multiple mupgrades.
    ---@param mupgrade_data_array MUpgradeData[]
    add_upgrade_data = function(mupgrade_data_array)
        assert(mupgrade_data_array, "MUpgrade data array was null!")
        assert(table_size(mupgrade_data_array) > 0,"There are no MUpgrades in this array to work with!")
    
        for _, mupgrade_data in pairs(mupgrade_data_array) do
            mupgrade_lib.assert_valid_mupgrade_data(mupgrade_data)
            remote.call("machine-upgrades-techlink", "add_technology_effect",
                mupgrade_data.technology_name, mupgrade_data.entity_names, mupgrade_data.module_effects, 
                mupgrade_data.handler, false)
        end
    end,
})



---Update everything from that tech, optionally limited to just that force.
---@param technology_name string
---@param force LuaForce? No force means every force
local function update_from_tech(technology_name, force)
    assert(prototypes.technology[technology_name], "Invalid technology name: " .. technology_name)
    --assert(storage.linked_technologies[technology_name], "No linked technology effects were found under the technology name: " .. technology_name)
    local effects = storage.linked_technologies[technology_name]
    for _, entry in pairs(effects or {}) do
        update_entity(entry.entity_name, force)
    end
end
---Update ALL entities via ALL techs.
local function update_all_entities()
    for key in pairs(storage.linked_technologies) do update_from_tech(key) end
end

--#endregion

----Event Registration
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("tech-link-initialize", initialize_storage)
event_lib.on_configuration_changed("tech-link-initialize", initialize_storage)

event_lib.on_init("tech-link-clear", clear_all_effects)
event_lib.on_configuration_changed("tech-link-clear", clear_all_effects)

--This needs to delay by a tick, so other scripts can tell us what they need
local function update_all_next_tick()
    event_lib.on_nth_tick(1, "tech-link-force-update", function()
        update_all_entities()
        event_lib.on_nth_tick(1, "tech-link-force-update", nil)
    end)
end
event_lib.on_init("tech-link-update-all", update_all_next_tick)
event_lib.on_configuration_changed("tech-link-update-all", update_all_next_tick)

event_lib.on_event(defines.events.on_technology_effects_reset,
    "tech-link-update-all", update_all_next_tick)

event_lib.on_event(defines.events.on_research_finished, "tech-link-update", function(event)
  update_from_tech(event.research.name, event.research.force) end)

--[[
---Remove stale data for any technologies that don't currently exist.
local function remove_stale_technology_references()
    local stale_technology_effects = {}
    for technology_name, effect in pairs(storage.linked_technologies) do 
        if not prototypes.technology[technology_name] then
            table.insert(stale_technology_names, technology_name)
        end
    end

    for _, technology_name in pairs(stale_technology_names) do
        remove_technology_effect

    end
end
]]

--[[
    --In clear_cache
    local entities_to_update = {}
    for key in pairs(storage.linked_entity_prototypes) do
        table.insert(entities_to_update, key)
    end

    beacon_manager.cancel_updates()
    for _, entity_name in pairs(entities_to_update) do
        update_entity(entity_name)
    end
    beacon_manager.regular_update()



    ---Add a specific effect to the given technology, to apply that module effect to the given entity.
    ---@param technology_name string
    ---@param entity_name string | string[]
    ---@param effect ModuleEffects
    ---@param entity_handler string Permanent string to reference that entity, so if the entity name changes/migrates, we don't have problems!
    ---@param auto_merge_handler boolean? If set true, then automatically merge handler with whatever was there previously. It is recommended to turn this on to merge with other mod.
    add_technology_effect = function(technology_name, entity_name, effect, entity_handler, auto_merge_handler)
        assert(prototypes.technology[technology_name],"Invalid technology name was passed: " .. technology_name)
        assert(prototypes.entity[entity_name],"Invalid entity name was passed: " .. entity_name)
        assert(prototypes.entity[entity_name].has_flag("get-by-unit-number"), "This entity needs the get-by-unit-number flag to function: " .. entity_name)
        assert(entity_handler ~= entity_name, "Entity handler should not match the entity name, to protect vs migration. See: " .. entity_handler)

        local modules = module_counter.effect_to_module_counts(effect)
        --If no modules, then we actually want to do a removal
        if not modules or table_size(modules) == 0 then
            remove_technology_effect(technology_name, entity_name)
        end

        local filter = {name=entity_name}
        local is_unique, previous_handler = entity_modifier.is_unique_filter(filter)
        if not auto_merge_handler then
            assert(is_unique, "We have two entity handlers that are different, but search for the same entity. Please clear the old handler: " 
                .. tostring(previous_handler) .."\nThis check is here as a safeguard to prevent duplicate calls from the same mod. Consider the optional merge argument.")
        --Auto-merge
        elseif not is_unique and previous_handler then entity_handler = previous_handler
        end
        
        storage.entity_name_to_handler[entity_name] = entity_handler
        entity_modifier.create_entity_cache(entity_handler, filter)
        entity_modifier.assign_modifier(entity_handler, "update-beacon")

        local new_tech_effect = {
            technology_name = technology_name,
            entity_name = entity_name,
            entity_handler = entity_handler,
            effect = mupgrade_lib.deepcopy(effect),
            modules = modules,
        }

        add_technology_effect(new_tech_effect)
        entity_modifier.apply_auto_modifier(entity_handler)
    end,
]]