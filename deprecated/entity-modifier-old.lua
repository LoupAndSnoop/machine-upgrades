--[[
--This file controls the runtime modification of entities in a generic way.
local entity_modifier = {}


--Initialize storage
local function initialize()
    ---@class (exact) MURegistryEntry
    ---@field entity_hashset table<LuaEntity, boolean>
    ---@field entity_filter EntitySearchFilters 
    ---@field auto_modifier? string String used to look up a function and do it, for whenever an entity needs to be updated (or added to that cache)
    local MURegistryEntry = {}

    ---Maintain a global cache stored of that specific entity
    ---string that corresponds to a handle of a specific sort of entity to store => hashset of that LuaEntity.
    ---@type table<string, MURegistryEntry>
    storage.modified_entity_registry = storage.modified_entity_registry or {}

    ---Table of all entities which are registed to remove from the cache when destroyed.
    ---@type table<uint, LuaEntity>
    storage.modified_entity_deregistry = storage.modified_entity_deregistry or {}
end


--#region Modifier function registration and invocation
--Dictionary of "function_name" => function. Must be populated on each session,
--as functions cannot be serialized.
local function_register = {}

---Add a key to the table, so function_register[function_name] => function_to_invoke
--- The function should be of the form function(arguments[1], arguments[2]...)
---@param function_to_invoke function A function of LuaEntity
---@param function_name string
entity_modifier.register_function = function(function_name, function_to_invoke)
  assert(not game, "Cannot register a function outside the main chunk")
  assert(not function_register[function_name], "This function name has been added twice to the function lookup register: " .. function_name)
  function_register[function_name] = function_to_invoke
end



---Assign a function to automatically call on every entity that enters
---the cache associated with that entity_handler.
---@param entity_handler string string that represents the ID associated with that entity category.
---@param auto_modifier string string to associate with a function of LuaEntity to apply to every entity that enters this cache.
entity_modifier.assign_modifier = function(entity_handler, auto_modifier)
    assert(function_register[auto_modifier], "Function register has no function listed for the name: " .. auto_modifier)
    local entity_register = storage.modified_entity_registry and storage.modified_entity_registry[entity_handler]
    assert(entity_register, "There is currently no entity cache associated with the handler: " .. entity_handler)
    entity_register.auto_modifier = auto_modifier
end

---Apply the auto-modifier currently assigned to that entity handler, if it has an auto-modifier at all.
---If the argument is nil, then do it for ALL things in the registry.
---@param entity_handler string string that represents the ID associated with that entity category.
entity_modifier.apply_auto_modifier = function(entity_handler)
    --Apply the modifier for one specific entry of the registry
    local function try_apply_modifier(entry)
        if not entry.auto_modifier then return end
        to_call = function_register[entry.auto_modifier]
        assert(to_call, "There was no registered function found under the modifier ID: " .. entry.auto_modifier)
        for _, entity in pairs(entry.entity_hashset) do
            if entity.valid then to_call(entity) end
        end
    end

    --Full registry case
    if not entity_handler then
        for _, entry in pairs(storage.modified_entity_registry) do
            try_apply_modifier(entry)
        end
    --Partial registry case
    else
        local entity_register = storage.modified_entity_registry and storage.modified_entity_registry[entity_handler]
        assert(entity_register, "There is currently no entity cache associated with the handler: " .. entity_handler)
        try_apply_modifier(entity_register)
    end
end
--#endregion

--#region Standard make/maintain cache

---Return TRUE if the entity search filter is unique. False if it is not.
---@param filter EntitySearchFilters
---@return boolean result
---@return string? pre_existing_handler
function entity_modifier.is_unique_filter(filter)
    for handler, entry in pairs(storage.modified_entity_registry or {}) do
        for key, value in pairs(entry.entity_filter) do
            if filter[key] ~= value then goto continue end 
        end
        for key, value in pairs(filter) do
            if entry.entity_filter[key] ~= value then goto continue end 
        end
        if table_size(filter) ~= table_size(entry.entity_filter) then goto continue end
        --If we didn't skip, then we have a duplicate
        if true then return false, handler end
        ::continue::
    end

    return true, nil
end

---Find ALL entities across ALL surfaces that satisfy a specific filter.
---This function can be used to either create a new cache from scratch OR
---for hard refreshing a given cache.
---@param entity_handler string string that represents the ID associated with that entity category.
---@param entity_filter EntitySearchFilters filter of what entities should count.
entity_modifier.create_entity_cache = function(entity_handler, entity_filter)
    --local each_surface_entities = {}
    --for i, surface in pairs(game.surfaces) do
    --    table.insert(each_surface_entities, 
    --        surface.find_entities_filtered(entity_filter))
    --end ----entity_list = rubia_lib.array_concat(each_surface_entities),

    --Make a hashset
    local entity_hashset = {}
    for _, surface in pairs(game.surfaces) do
        local surface_entities = surface.find_entities_filtered(entity_filter)
        for _, entity in pairs(surface_entities) do
            entity_hashset[entity] = true
        end
    end

    --storage.modified_entity_registry = storage.modified_entity_registry or {}
    storage.modified_entity_registry[entity_handler] = {
        entity_hashset = entity_hashset,
        entity_filter = entity_filter,
    }
end


---Destroy this entity cache, and stop logging it
---@param entity_handler string? string that represents the ID associated with that entity category.
entity_modifier.remove_entity_cache = function(entity_handler)
    if not entity_handler then return end
    storage.modified_entity_registry[entity_handler] = nil
end

------Helpers
--If the input array contains the given value, return the index of that value (=true!)
--Otherwise, output false
local function array_find(array, value)
  for index, val in pairs(array) do
    if val == value then return index end
  end
  return false
end
--If the input array contains a value such that check(value) = true, 
--then return its index (=true!) Otherwise, output false
local function array_find_condition(array, condition)
  for index, val in pairs(array) do
    if condition(val) then return index end
  end
  return false
end


---Return true if the LuaEntity satisfies the given EntitySearchFilters.
---Don't check every possible part of the filter--just key parts.
---@param entity LuaEntity
---@param filter EntitySearchFilters
local function entity_satisfies_filter(entity, filter)
    if not entity.valid then return false end

    --Reject by entity type. (most common case)
    if filter.name then
        if type(filter.name) ~= table then
            if (entity.name ~= (filter.name.name or filter.name)) then return false end --Checks case of filter = string or LuaEntity/Prototype
        elseif not array_find_condition(filter.name, function(entityID) --Case of array of ID
                return entity.name == (entityID.name or entityID) end) then return false
        end
    end
    --if filter.name and (entity.name ~= (filter.name.name or filter.name)) then
    --    --Need to check by array
    --    reject = true
    --    for _, entityID in filter.name do
    --        reject = entity.name == (entityID.name or entityID)
    --    end
    --    if reject then return false end
    --end

    local reject = false

    --Reject by ghost type
    if filter.ghost_name and (entity.ghost_name ~= (filter.ghost_name.name or filter.ghost_name)) then
        --Need to check by array
        reject = true
        for _, entityID in filter.ghost_name do
            reject = entity.ghost_name == (entityID.ghost_name or entityID)
        end
        if reject then return false end
    end


    --Reject by wrong prototype, as true name
    --local prototype = (entity.type ~= "entity-ghost") and entity.type or entity.ghost_type
    --if filter.type and (prototype ~= filter.type)
    --    and not array_find(filter.type, prototype) then
    --    return false
    --end

    --Prototype rejection. Filters has separation for ghost types
    if filter.type and (entity.type ~= filter.type)
        and not array_find(filter.type, entity.type) then
        return false
    end
    if filter.ghost_type and (entity.ghost_type ~= filter.ghost_type)
        and not array_find(filter.ghost_type, entity.ghost_type) then
        return false
    end

    --Reject by wrong force
    if filter.force and (entity.force ~= (game.forces[filter.force] or filter.force)) then
        --Need to check by array
        reject = true
        for _, forceID in filter.force do
            reject = entity.force == (game.forces[forceID] or forceID)
        end
        if reject then return false end
    end
    
    return true
end

---LuaEntity was just built. Add it to caches as may be applicable.
---@param entity LuaEntity add this entity to the cache.
local function update_on_build(entity)
    if not entity.valid then return end

    local to_deregister = false
    for _, entry in pairs(storage.modified_entity_registry or {}) do
        if entity_satisfies_filter(entity, entry.entity_filter) then
            entry.entity_hashset[entity] = true
            to_deregister = true

            --Auto-modify
            if entry.auto_modifier then
                local to_invoke = function_register[entry.auto_modifier]
                assert(to_invoke, "We need to invoke an auto-modifier for an entity being added to the registry, "
                .. "but its function isn't registered yet! Current auto-register key = " .. tostring(entry.auto_modifier))
                to_invoke(entity)
            end
        end
    end

    --Make sure we deregister
    if to_deregister then
        local delist_ID = script.register_on_object_destroyed(entity)
        --storage.modified_entity_deregistry = storage.modified_entity_deregistry or {}
        storage.modified_entity_deregistry[delist_ID] = entity
    end
end

---LuaEntity was just destroyed. Delist it.
---@param entity_reg_ID uint Entity registration ID
local function update_on_object_destroyed(entity_reg_ID)
    local entity = storage.modified_entity_deregistry 
        and storage.modified_entity_deregistry[entity_reg_ID]

    if not entity then return end --Was never registered
    --Then go delist
    for _, entry in pairs(storage.modified_entity_registry or {}) do
        entry.entity_hashset[entity] = nil
    end
    storage.modified_entity_deregistry[entity_reg_ID] = nil
end


---Call this function on each LuaEntity. This function does not need to be registered.
---@param entity_handler string string that represents the ID associated with that entity category.
---@param execute function function of LuaEntity to invoke on LuaEntity connected to that entity handler.
entity_modifier.apply_to_all_entities = function(entity_handler, execute)
    local registry = storage.modified_entity_registry[entity_handler]
    assert(registry, "We can't invoke a function tied to that entity handler if its cache has not been made yet! Handler = " .. entity_handler)
    for _, entity in pairs(registry.entity_hashset) do
        if entity.valid then execute(entity) end
    end
end

---Print whatever is in the current registry.
---@return string
function entity_modifier.show_registry_stats()
    local string = "Registry:\n"
    for key, value in pairs(storage.modified_entity_registry or {}) do
        string = string .. "Handler = " .. key .. ", Filter = " .. serpent.line(value.entity_filter) 
            .. "\n     Entities = " .. table_size(value.entity_hashset) .. ", Auto-execute = " .. tostring(value.auto_modifier) .. "\n"
    end
    return string
    
end


_G.mupgrade = mupgrade or {}
--Print all event handlers, to see what is currently subscribed.
function mupgrade.print_registry_stats()
    local string = entity_modifier.show_registry_stats()
    log(string)
    game.print(string)
end

--#endregion

--Event subscriptions
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("entity-cache-initialize", initialize)
event_lib.on_configuration_changed("entity-cache-initialize", initialize)
event_lib.on_built("entity-cache-update", update_on_build)
event_lib.on_event(defines.events.on_object_destroyed, "entity-cache-update",
    function(event) update_on_object_destroyed(event.registration_number) end)


return entity_modifier
]]