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