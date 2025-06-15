--This file manages linking objects to make compound entities.
local entity_linker = {}


local function initialize()
    ---Dictionary of parent entity unitID => array of child entity unit numbers
    ---@type table<uint, uint[]>> 
    storage.compound_entity_parent_to_children = storage.compound_entity_parent_to_children or {}

    ---Dictionary of child entity unit_id => its parent entity unit number
    ---@type table<uint, uint>
    storage.compound_entity_child_to_parent = storage.compound_entity_child_to_parent or {}

    ---Dictionary of included entity deregistration id => unit number
    ---@type table<uint, uint>
    storage.compound_entity_deregistry = storage.compound_entity_deregistry or {}

    ---Dictionary of included entity unit number => position where it was when linked
    ---@type table<uint, MapPosition>
    storage.compound_entity_positions = storage.compound_entity_positions or {}--{["a"]=true}
end

---Link a child entity to a parent entity to be listed as a composite.
---@param parent LuaEntity
---@param child LuaEntity
function entity_linker.link_entities(parent, child)
    if not parent.valid or not child.valid then return end

    local children = storage.compound_entity_parent_to_children[parent.unit_number]
    if not children then
        storage.compound_entity_parent_to_children[parent.unit_number] = {child.unit_number}
    else 
        --Check case where they are already linked => nothing to do
        for _, entry in pairs(children) do
            if entry == child then return end
        end
        table.insert(storage.compound_entity_parent_to_children[parent.unit_number], child.unit_number)
    end

    storage.compound_entity_child_to_parent[child.unit_number] = parent.unit_number

    --Log positions
    storage.compound_entity_positions[parent.unit_number] = {parent.position.x, parent.position.y}
    storage.compound_entity_positions[child.unit_number] = {child.position.x, child.position.y}

    --Make sure we know when it is dead.
    storage.compound_entity_deregistry[script.register_on_object_destroyed(parent)] = parent.unit_number
    storage.compound_entity_deregistry[script.register_on_object_destroyed(child)] = child.unit_number
end


---When an object is destroyed, if we are keeping tabs on it, update all the data/caches.
---If it was in a compound entity, make sure all parts of the entity die together.
---@param entity_deregister_id uint Entity registration id for on_object_destroyed
---@param spare_parent boolean if set true, do NOT destroy the parent in this call. Default false
local function on_entity_destroyed(entity_deregister_id, spare_parent)
    if not storage.compound_entity_deregistry[entity_deregister_id] then return end

    local entity_no = storage.compound_entity_deregistry[entity_deregister_id]

    --Find the parent of this relationship.
    local parent_no = storage.compound_entity_child_to_parent[entity_no] or entity_no
    local children_no = storage.compound_entity_parent_to_children[parent_no]
    
    for _, child_no in pairs(children_no or {}) do
        local child = game.get_entity_by_unit_number(child_no)
        if child and child.valid then child.destroy() end
        storage.compound_entity_child_to_parent[child_no] = nil
        storage.compound_entity_positions[child_no] = nil
    end

    local parent = game.get_entity_by_unit_number(parent_no)
    if parent and parent.valid and not spare_parent then parent.destroy() end
    storage.compound_entity_positions[parent_no] = nil
    storage.compound_entity_parent_to_children[parent_no] = nil

    --Now clear the working storage
    storage.compound_entity_deregistry[entity_deregister_id] = nil
end


---Manually request all the children for a given entity to be destroyed, without also killing the parent.
---This dissolves the compound entity. If passing child, go find the parent, and kill only the children.
---@param entity_no uint Entity unit number
function entity_linker.kill_children_of(entity_no)
    --Find the parent of this relationship.
    local parent_no = storage.compound_entity_child_to_parent[entity_no] or entity_no
    local children_no = storage.compound_entity_parent_to_children[parent_no]
    if not children_no then return end --This entity number isn't something we are tracking

    local parent = game.get_entity_by_unit_number(parent_no)
    local entity_deregister_id = script.register_on_object_destroyed(parent)
    on_entity_destroyed(entity_deregister_id, true) --On-destruction function should take care of chain destruction
end


--This boolean lets us not respond repeatedly to entity teleporting calls recursively.
local entity_mid_move_lock = false
---When one entity is moved, if it is in a compound entity, make sure to move everything together.
---@param entity LuaEntity
local function on_entity_moved(entity)
    if not entity.valid then return end
    if entity_mid_move_lock then return end --We are in the middle of something! Don't recurse on me, you twat.

    local old_pos = storage.compound_entity_positions[entity.unit_number]
    if not old_pos then return end --We are not even logging this entity!

    local parent_no = storage.compound_entity_child_to_parent[entity.unit_number] or entity.unit_number
    local children_no = storage.compound_entity_parent_to_children[parent_no]
    if not children_no then return end --This entity is just not relevant to us.

    local current_pos = {entity.position.x, entity.position.y}
    local displacement = {current_pos[1] - old_pos[1], current_pos[2] - old_pos[2]}

    ---@param displace_entity LuaEntity
    local function displace(displace_entity)
        if not displace_entity.valid or entity == displace_entity then return end

        local new_position = {displace_entity.position.x + displacement[1], displace_entity.position.y + displacement[2]}
        displace_entity.teleport(new_position) --entity.surface, true)
        storage.compound_entity_positions[displace_entity.unit_number] = new_position
    end

    entity_mid_move_lock = true
    displace(game.get_entity_by_unit_number(parent_no))
    for _, child_no in pairs(children_no) do
        displace(game.get_entity_by_unit_number(child_no))
    end
    --Log the position of the entity that changed (but we don't need to displace it
    storage.compound_entity_positions[entity.unit_number] = current_pos

    entity_mid_move_lock = false
end


--Event subscriptions
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("compound-entity-link-initialize", initialize)
event_lib.on_configuration_changed("compound-entity-link-initialize", initialize)

event_lib.on_event(defines.events.on_object_destroyed, "compound-entity-update",
    function(event) on_entity_destroyed(event.registration_number) end)

event_lib.on_event({defines.events.script_raised_teleported}, "compound-entity-move",
    function(event) on_entity_moved(event.entity) end)


return entity_linker