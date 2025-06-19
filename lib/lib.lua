_G.mupgrade_lib = {}

--mupgrade_lib.DEBUG_MODE = true
mupgrade_lib.AUTO_PACK_PREFIX = "mupgrade-lib-packed-"

---Get the current stage that we are in
---@return string stage Should be "control", "data", "settings"
function mupgrade_lib.get_current_stage()
  if data and data.raw and (table_size(data.raw.item or {}) == 0) then return "settings"
  elseif data and data.raw then return "data"
  elseif script then return "control"
  else error("Could not determine load order stage.")
  end
end

if mupgrade_lib.get_current_stage() == "data" then require("__machine-upgrades__/lib/data-lib")
elseif mupgrade_lib.get_current_stage() == "control" then require("__machine-upgrades__/lib/control-lib")
end


---Dictionary go in. Make a new hashset of all the different values in it
---@param dictionary table<any, any>
---@return table<any, boolean> hashset
function mupgrade_lib.dictionary_values_to_hashset(dictionary)
  local hashset = {}
  for _, value in pairs(dictionary) do hashset[value] = true end
  return hashset
end



---Assert that the given mupgrade data is valid. Usable in data or control stages
---@param mupgrade_data MUpgradeData
function mupgrade_lib.assert_valid_mupgrade_data(mupgrade_data)
  --Handler
  assert(mupgrade_data, "Null mupgrade data!")
  assert(mupgrade_data.handler, "No handler found for this Mupgrade data: " .. serpent.block(mupgrade_data))
  assert(type(mupgrade_data.handler) == "string",
    "Invalid handler for mupgrade data with handler: " .. tostring(mupgrade_data.handler))
  local handler_string = "Error in Mupgrade data with handler = " .. tostring(mupgrade_data.handler) .. "\n    "

  --Tech
  local stage = mupgrade_lib.get_current_stage()
  assert(stage == "data" or stage == "control", "Assertion checker was called during invalid data lifecycle stage: " .. stage)
  local technology = nil
  if stage == "data" then technology = data.raw["technology"][mupgrade_data.technology_name]
  else technology = prototypes.technology[mupgrade_data.technology_name]
  end
  assert(technology, handler_string .. "No valid technology found by the name: " .. tostring(mupgrade_data.technology_name))

  --Entity name
  local function find_entity_prototype(entity_name)
      local prototype
      if mupgrade_lib.get_current_stage() == "data" then
        for type in pairs(defines.prototypes.entity) do
            prototype = data.raw[type] and data.raw[type][entity_name]
            if prototype then return prototype end
        end
        error(handler_string .. "No entity prototype found by the name: " .. entity_name) 
      else return prototypes.entity[entity_name]
      end
  end

  for _, entity_name in pairs(mupgrade_data.entity_names) do
    assert(entity_name, handler_string .. "Null entity name!")
    assert(entity_name ~= "", handler_string .. "Entity name is an empty string!")
    assert(find_entity_prototype(entity_name), handler_string .. "No valid entity prototype found under the name: " .. tostring(entity_name))
  end

  --Module effects
  assert(mupgrade_data.module_effects, handler_string .. "No module effects found.")
  local modifiers = {["speed"]=true, ["consumption"]=true, ["productivity"]=true, ["pollution"]=true, ["quality"]=true}
  for effect in pairs(mupgrade_data.module_effects) do 
    assert(mupgrade_data.module_effects[effect], handler_string .. "Invalid name for a module effect: " .. tostring(effect))
  end
end