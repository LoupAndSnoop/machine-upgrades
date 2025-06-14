--This file manages linking objects to make compound entities.
local entity_linker = {}


local function initialize()
    ---Dictionary of parent entity => hashset of child entities.
    ---@type table<LuaEntity, table<LuaEntity,boolean>> 
    storage.compound_entity_parent_to_children = storage.compound_entity_parent_to_children or {}

    ---Dictionary of child entity => its parent entity
    ---@type table<LuaEntity, LuaEntity>
    storage.compound_entity_child_to_parent = storage.compound_entity_child_to_parent or {}

    ---Dictionary of included entity => deregistration id
    ---@type table<uint, LuaEntity>
    storage.compound_entity_deregistry = storage.compound_entity_deregistry or {}

    ---Dictionary of included entity => position where it was when linked
    ---@type table<LuaEntity, MapPosition>
    storage.compound_entity_positions = storage.compound_entity_positions or {}
end

---Link a child entity to a parent entity to be listed as a composite.
---@param parent LuaEntity
---@param child LuaEntity
function entity_linker.link_entities(parent, child)
    if not parent.valid or not child.valid then return end

    if not storage.compound_entity_parent_to_children[parent] then
        storage.compound_entity_parent_to_children[parent] = {[child] = true}
    else storage.compound_entity_parent_to_children[parent][child] = true
    end

    storage.compound_entity_child_to_parent[child] = parent

    --Log positions
    storage.compound_entity_positions[parent] = {parent.position.x, parent.position.y}
    storage.compound_entity_positions[child] = {child.position.x, child.position.y}

    --Make sure we know when it is dead.
    storage.compound_entity_deregister[script.register_on_object_destroyed(parent)] = parent
    storage.compound_entity_deregistry[script.register_on_object_destroyed(child)] = child
end


---When an object is destroyed, if we are keeping tabs on it, update all the data/caches.
---If it was in a compound entity, make sure all parts of the entity die together.
---@param entity_deregister_id uint Entity registration id for on_object_destroyed
local function on_entity_destroyed(entity_deregister_id)
    if not storage.compound_entity_deregistry[entity_deregister_id] then return end

    local entity = storage.compound_entity_deregistry[entity_deregister_id]

    --Find the parent of this relationship.
    local parent = storage.compound_entity_child_to_parent[entity] or entity
    assert(storage.compound_entity_parent_to_children[parent], "This entity isn't a parent!")
    local children = storage.compound_entity_parent_to_children[parent]
    for child in pairs(children) do
        if child.valid then child.destroy() end
        storage.compound_entity_child_to_parent[child] = nil
        storage.compound_entity_positions[child] = nil
    end

    if parent.valid then parent.destroy() end
    storage.compound_entity_positions[parent] = nil
    storage.compound_entity_parent_to_children[parent] = nil

    --Now clear the working storage
    storage.compound_entity_deregistry[entity_deregister_id] = nil
end

--This boolean lets us not respond repeatedly to entity teleporting calls recursively.
local entity_mid_move_lock = false

---When one entity is moved, if it is in a compound entity, make sure to move everything together.
---@param entity LuaEntity
local function on_entity_moved(entity)
    if not entity.valid then return end
    if entity_mid_move_lock then return end --We are in the middle of something! Don't recurse on me, you twat.

    local old_pos = storage.compound_entity_positions[entity]
    if not old_pos then return end --We are not even logging this entity!

    local parent = storage.compound_entity_child_to_parent[entity] or entity
    local children = storage.compound_entity_parent_to_children[parent]
    if not children then return end --This entity is just not relevant to us.

    local current_pos = {x = entity.position.x, y = entity.position.y}
    local displacement = {x = current_pos.x - old_pos.x, y = current_pos.y - old_pos.y}

    ---@param displace_entity LuaEntity
    local function displace(displace_entity)
        if not displace_entity.valid or entity == displace_entity then return end
        local current_position = displace_entity.position
        displace_entity.teleport({current_position.x + displacement.x, current_position.y + displacement.y},
            entity.surface, false)
        storage.compound_entity_positions[displace_entity] = displace_entity.position
    end

    entity_mid_move_lock = true
    displace(parent)
    for child in pairs(children) do
        displace(child)
    end
    entity_mid_move_lock = false
end


--Event subscriptions
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("compound-entity-link-initialize", initialize)
event_lib.on_configuration_changed("compound-entity-link-initialize", initialize)

event_lib.on_event(defines.events.on_object_destroyed, "compound-entity-update",
    function(event) on_entity_destroyed(event.registration_number) end)

event_lib.on_event({defines.events.script_raised_teleported, }, "compound-entity-move",
    function(event) on_entity_moved(event.entity) end)


return entity_linker