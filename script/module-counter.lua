--This file's job is to take in a ModuleEffects and output a table of how many of what modules are needed to make it happen.


local module_counter = {}


---Module effects go in. Out goes a dictionary of how many of what modules are needed to make that effect. Just for 1 level's worth.
---@param effect ModuleEffects
---@return table<string, uint> modules Dictionary of modules => how many need to be added
function module_counter.get_modules(effect)
    local modules = {}

    --TODO


    return modules
end



return module_counter