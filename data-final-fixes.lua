--In case other mods fuck with our modules, we need to un-fuck them. >:(
--data:extend(mupgrade_lib.module_prototypes_copy)
for _, entry in pairs(mupgrade_lib.module_prototypes_copy) do
    local module = data.raw.module[entry.name]
    assert(module, "Some other mod actively deleted a module prototype that is needed for this mod to function! (" .. entry.name .."). What a dick!")
    module.effect = entry.effect
end

--Make sure all crafting machines can accept a mupgrade module effect
for category in pairs(defines.prototypes.entity) do
    for _, proto in pairs(data.raw[category] or {}) do
        if proto.allowed_module_categories then
            table.insert(proto.allowed_module_categories, "mupgrade")
        end
    end
end