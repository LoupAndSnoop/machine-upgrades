--This file is where we do the actual beaconating
local entity_linker = require("__machine-upgrades__/script/compound-entity-link")
local module_counter = require("__machine-upgrades__/script/module-counter")
local entity_modifier = require("__machine-upgrades__/script/entity-modifier")

local beacon_manager = {}

local function initialize()
    ---entity names => hashset of relevant forces, for entities still needing an update in that force
    ---@type table<string, table<LuaForce, boolean>>
    storage.entities_needing_update = storage.entities_needing_update or {}
end

--In this mod, all the entities in the compound-entity link have an entity-beacon relationship. We'll use that.

--This is an error message for the case when a mupgrade-beacon was immediately destroyed by another mod in an entity-build callback.
--This error has happened before, and it will continue to happen whenever someone does this.
local BEACON_DESTROYED_ERROR_MSG = "\n\n[color=255,125,0][font=default-semibold]This crash is likely caused by a DIFFERENT mod (not by Machine Upgrades/Rubia).[/font][/color] "
        .. "To fix, please identify which mod causes the crash, and send its author this report. "
        .. "Don't report to Machine Upgrades/Rubia (I can't fix it, and will just mark it as an incompatibility).\n\n"
        .. "----------------\n"
        .. "Crash Report:\nMachine Upgrades uses invisible beacons to create its technology effects. "
        .. "It seems that a mod is automatically destroying an entity called mupgrade-beacon as soon as it is created, in the event callback of on_built_entity (or related build event). "
        .. "Machine Upgrades performs a consistency check immediately after creating a mupgrade beacon to ensure it has not been destroyed. "
        .. "This assertion has been tripped. Destroying such entities while they are being created can cause other mods to crash (including Machine Upgrades). "
        .. "You can blacklist mupgrade-beacon from being destroyed, but you will probably have the same issue with a different mod in the future. "
        .. "Please avoid destroying other mods' entities immediately after creation. "
        .. "For reproduction, you will want to recreate the player's whole modlist (not just Rubia/Machine Upgrades). "
        .. "This mupgrade-beacon's construction was triggered by the placement of the following entity: "
---Try to make a beacon for that entity. If it already has one, just return the reference.
---If we fail, just return nil.
---@param entity LuaEntity
---@return LuaEntity? beacon
local function try_get_beacon(entity)
    if not entity.valid then return end
    
    local beacon_array = storage.compound_entity_parent_to_children[entity.unit_number]
    if beacon_array then return game.get_entity_by_unit_number(beacon_array[1]) end --Already exists
    
    --Get accurate position as the center of the collision box.
    local left_top, right_bottom = entity.bounding_box.left_top, entity.bounding_box.right_bottom
    local center = {x = (left_top.x + right_bottom.x)/2, y = (left_top.y + right_bottom.y)/2}

    --Does not already exist. Make one, and link it!
    local new_beacon = entity.surface.create_entity{
        name = "mupgrade-beacon",
        position = center,--entity.position,
        force = entity.force_index,
        raise_built = true,
    }
    
    assert(new_beacon, BEACON_DESTROYED_ERROR_MSG .. entity.name)
    entity_linker.link_entities(entity, new_beacon)

    return new_beacon
end


---Update the moduling/beaconing of the one entity to match.
---@param entity LuaEntity
---@param module_list table<string, uint>
local function update_entity_moduling(entity, module_list)
    if not entity.valid then return end
    local beacon = try_get_beacon(entity)
    
    if not beacon or not beacon.valid then error("No beacon found, or beacon invalid. Still WIP."); return end
    local module_inventory = beacon.get_module_inventory()
    module_inventory.clear()

    for module_name, count in pairs(module_list) do
        module_inventory.insert({name=module_name, count = count})
    end
end

--local modules_to_add, total_count = module_counter.get_total_moduling(entity_name)

local MAX_MODULE_COUNT = prototypes.entity["mupgrade-beacon"].module_inventory_size

---Go update all the entity handling for all entities tied to this handler.
---@param entity_handler string Handler for the relevant entity. This should NOT be automatically the same as the entity_name, so migration doesn't fuck everything up.
---@param force_set table<LuaForce, boolean> hashset of all forces for which we need to update.
local function update_all_entity_moduling(entity_handler, force_set)
    local cached_entity_entry = storage.modified_entity_registry[entity_handler]
    if not cached_entity_entry then return end
    local entity_name_all = cached_entity_entry.entity_filter.name
    assert(entity_name_all, "No entity name in entity search filter with the handle: " .. entity_handler)
    ---@type string[]
    entity_name_all = (type(entity_name_all) == "table") and entity_name_all or {entity_name_all} --Standardize to string[]

    local cached_entities = cached_entity_entry.entity_hashset
    if not cached_entities or table_size(cached_entities) == 0 then return end --Nothing to update

    --Make a lookup table for each entity, and force
    local module_lookup = {}
    for force in pairs(force_set or {}) do
        module_lookup[force.index] = {}
        for _, entity_name in pairs(entity_name_all) do
            local modules_to_add, total_count = module_counter.get_total_moduling(entity_name, force)
            assert(total_count <= MAX_MODULE_COUNT, "Beacon module count exceeded. Please tell mod creator.")
            module_lookup[force.index][entity_name] = modules_to_add
        end
    end

    --Now go update them
    for entity_no in pairs(cached_entities) do
        local entity = game.get_entity_by_unit_number(entity_no)
        if entity and entity.valid then
            local modules = module_lookup[entity.force_index]
            if modules then --This effectively filters following the force set.
                update_entity_moduling(entity, modules[entity.name])
            end
        end
    end
end

---When this entity gets an on-build, if it needs beacon+moduling, do it.
---@param entity LuaEntity
local function update_beacon_on_build(entity)
    if not entity.valid then return end
    local modules_to_add, total_count = module_counter.get_total_moduling(entity.name, game.forces[entity.force_index])
    assert(total_count <= MAX_MODULE_COUNT, "Beacon module count exceeded. Please tell mod creator.")
    update_entity_moduling(entity, modules_to_add)
end
entity_modifier.register_function("update-beacon", update_beacon_on_build)

---Remove beacon from this entity
---@param entity_no uint Unit id of entity from which to remove beacons.
function beacon_manager.remove_beacon_from(entity_no)
    entity_linker.kill_children_of(entity_no)
end


---Set this entity-handler to be updated at next convenience
---@param entity_handler string String handler for that specific type of entity
---@param force LuaForce? optionally limit to just this lua force
function beacon_manager.request_entity_update(entity_handler, force)
    assert(entity_handler, "Null entity handler passed!")
    --log("Requesting update: " .. tostring(entity_handler) .. ", Force = " .. tostring(force))
    --All forces, if not specified
    if not force then
        storage.entities_needing_update[entity_handler] = 
            mupgrade_lib.dictionary_values_to_hashset(game.forces)
    else
        local existing_forces = storage.entities_needing_update[entity_handler]
        if existing_forces then existing_forces[force] = true
        else storage.entities_needing_update[entity_handler] = {[force] = true}
        end
    end
end

---Request an update for all handlers for this force.
---@param force LuaForce? For this force. If nil, then do ALL forces.
local function request_force_update(force)
    for entity_handler in pairs(storage.modified_entity_registry or {}) do
        beacon_manager.request_entity_update(entity_handler, force)
    end
end


---Update all entities that are currently in need of updating, all at once. This prevents duplicate calls.
function beacon_manager.regular_update()
    for entity_handler, force_set in pairs(storage.entities_needing_update or {}) do
        update_all_entity_moduling(entity_handler, force_set)
    end
    storage.entities_needing_update = {}
end
--Cancel any pending updates
function beacon_manager.cancel_updates() storage.entities_needing_update = {} end


--Events
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("beacon-manager-initialize", initialize)
event_lib.on_configuration_changed("beacon-manager-initialize", initialize)
--event_lib.on_configuration_changed("beacon-manager-cancel-updates", cancel_updates)
event_lib.on_nth_tick(1, "beacon-manager-regular_update", beacon_manager.regular_update)

--Some mods fuck with forces
event_lib.on_event({defines.events.on_force_created, defines.events.on_force_reset},"beacon-manager-forces-changed",
    function(event) request_force_update(event.force) end)
event_lib.on_event({defines.events.on_forces_merging},"beacon-manager-forces-changed",
    function(event) request_force_update(event.source); request_force_update(event.destination) end)

return beacon_manager