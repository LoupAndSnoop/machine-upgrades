--This file is where we do the actual beaconating
local entity_linker = require("__machine-upgrades__/script/compound-entity-link")
local module_counter = require("__machine-upgrades__/script/module-counter")


local beacon_manager = {}

local function initialize()
    --[[
    ---Dictionary of parent entity => its beacon
    ---@type table<LuaEntity, LuaEntity> 
    --storage.beacon_correlator = storage.beacon_correlator or {}
    ]]

    ---Hashset of entity names, for entities still needing an update
    ---@type table<string, boolean>
    storage.entities_needing_update = storage.entities_needing_update or {}
end

--In this mod, all the entities in the compound-entity link have an entity-beacon relationship. We'll use that.

---Try to make a beacon for that entity. If it already has one, just return the reference.
---If we fail, just return nil.
---@param entity LuaEntity
---@return LuaEntity? beacon
local function try_get_beacon(entity)
    if not entity.valid then return end
    
    local beacon_array = storage.compound_entity_parent_to_children[entity]
    if beacon_array then return beacon_array[1] end --Already exists
    
    --Does not already exist. Make one, and link it!
    local new_beacon = entity.surface.create_entity{
        name = "mupgrade-beacon",
        position = entity.position,
        force = entity.force_index,
        raise_built = true,
    }
    assert(new_beacon, "Something stopped us from making a special beacon. Alert the mod creator of how this happened.")
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
local function update_all_entity_moduling(entity_handler)
    local cached_entity_entry = storage.modified_entity_registry[entity_handler]
    if not cached_entity_entry then return end
    local entity_name = cached_entity_entry.entity_filter.name
    assert(entity_name, "No entity name in entity search filter with the handle: " .. entity_handler)

    local cached_entities = cached_entity_entry.entity_hashset
    if not cached_entities or table_size(cached_entities) == 0 then return end --Nothing to update

    local modules_to_add, total_count = module_counter.get_total_moduling(entity_name)
    assert(total_count <= MAX_MODULE_COUNT, "Beacon module count exceeded. Please tell mod creator.")
    
    for entity in pairs(cached_entities) do
        update_entity_moduling(entity, modules_to_add)
    end
end


---Set this entity-handler to be updated at next convenience
---@param entity_handler string String handler for that specific type of entity
function beacon_manager.request_entity_update(entity_handler)
    storage.entities_needing_update[entity_handler] = true
end
---Update all entities that are currently in need of updating, all at once. This prevents duplicate calls.
local function regular_update()
    for entity_handler in pairs(storage.entities_needing_update or {}) do
        update_all_entity_moduling(entity_handler)
    end
    storage.entities_needing_update = {}
end


--Events
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("beacon-manager-initialize", initialize)
event_lib.on_configuration_changed("beacon-manager-initialize", initialize)
event_lib.on_nth_tick(1, "beacon-manager-regular_update", regular_update)

return beacon_manager