--Destroy all beacons, as we have some that are not registered.
for _, surface in pairs(game.surfaces) do
    local to_delete = surface.find_entities_filtered{name="mupgrade-beacon"}
    for _, entity in pairs(to_delete) do
        if entity and entity.valid then entity.destroy() end
    end
end