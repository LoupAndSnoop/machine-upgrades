--In case other mods fuck with our modules, we need to un-fuck them. >:(
--data:extend(mupgrade_lib.module_prototypes_copy)
for _, entry in pairs(mupgrade_lib.module_prototypes_copy) do
    local module = data.raw.module[entry.name]
    assert(module, "Some other mod actively deleted a module prototype that is needed for this mod to function! (" .. entry.name .."). What a dick!")
    module.effect = entry.effect
end