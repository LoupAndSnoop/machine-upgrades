if not mods["module-category-defaults"] then return end

if ModuleCategoryDefaults and ModuleCategoryDefaults.default_categories then
    table.insert(ModuleCategoryDefaults.default_categories, "mupgrade")
end