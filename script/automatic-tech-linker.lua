---This file takes data that was packed in data stage to go get it, and set up tech links in control stage.



---Credit: Thanks to plexpt. Code taken from the Big Data string 2 mod for the actual (un)packing.
local function decode(data)
    if type(data) == "string" then
        return data
    end
    local str = {}
    for i = 2, #data do
        str[i - 1] = decode(data[i])
    end
    return table.concat(str, "")
end
--Unpack data that was packed before by name.
local function bigunpack(name)
    assert(type(name) == "string", "missing name!")
    local prototype = prototypes.entity[name]
    assert(prototype, string.format("big data '%s' not defined!", name))
    return decode(prototype.localised_description)
end


---Go find all prototypes that are linked to packed mupgrade data.
local function find_packed_data_prototype_names()
    local prefix = mupgrade_lib.AUTO_PACK_PREFIX
    local prefix_length = string.len(prefix)

    local found_prototype_names = {}
    for name, _ in pairs(prototypes.entity) do
        if string.sub(name, 1, prefix_length) == prefix then
            table.insert(found_prototype_names, name)
            log("Found packed mupgrade data: " .. string.sub(name, prefix_length + 1, string.len(name)))
        end
    end

    return found_prototype_names
end

---Go find and make an array of all packed mupgrade data
---@return MUpgradeData[] mupgrade_data_array Array of all packed mupgrade data
local function get_all_packed_mupgrade_data()
    --Go find all packed MUpgrade data
    local all_mupgrade_data_names = find_packed_data_prototype_names()
    local all_mupgrade_data = {}
    for _, name in pairs(all_mupgrade_data_names) do
        local success, any_data_or_error = serpent.load(bigunpack(name))
        assert(success, "Found invalid data under the prototype name: " .. name .."\n    Error was: " .. tostring(any_data_or_error))
        table.insert(all_mupgrade_data, any_data_or_error)
    end
    return all_mupgrade_data
end

--Register to our own event subscriptions.
local function register_auto_tech_links() 
    local all_mupgrade_data = get_all_packed_mupgrade_data()
    if all_mupgrade_data and table_size(all_mupgrade_data) > 0 then
        remote.call("machine-upgrades-techlink", "add_upgrade_data", all_mupgrade_data)
    end
end
--Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
local event_lib = require("__machine-upgrades__.script.event-lib")
event_lib.on_init("mupgrade-automatic-technology-link", register_auto_tech_links) --This particular event handler would need a unique string here
event_lib.on_configuration_changed("mupgrade-automatic-technology-link", register_auto_tech_links)
