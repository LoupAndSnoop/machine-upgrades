assert(mupgrade_lib, "mupgrade_lib not defined!")
assert(mupgrade_lib.get_current_stage() == "data", "This library is for data stage only.")


---Make sure the target prototype can be gotten by unit number
---@param prototype data.EntityPrototype
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