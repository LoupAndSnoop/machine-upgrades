_G.mupgrade_lib = {}

mupgrade_lib.DEBUG_MODE = true

--Deepcopy, allowed in control stage
function mupgrade_lib.deepcopy(object)
  local lookup_table = {}
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = {}
    lookup_table[object] = new_table
    for index, value in pairs(object) do
      new_table[_copy(index)] = _copy(value)
    end
    return setmetatable(new_table, getmetatable(object))
  end
  return _copy(object)
end

--Make sure the target prototype can be gotten by unit number
function mupgrade_lib.add_id_flag(prototype)
  local unit_flag = "get-by-unit-number"
  if not prototype.flags or table_size(prototype.flags) == 0 then prototype.flags = {unit_flag}
  else
    for _, flag in pairs(prototype.flags) do
      if flag == unit_flag then return end --Already there
    end
    table.insert(prototype.flags, unit_flag)
  end
end

--mupgrade_lib.base_icon_tint = {1,0.5,1}

