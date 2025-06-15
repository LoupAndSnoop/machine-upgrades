--This test suite also functions as an example for how to use this in other mods.
if not mupgrade_lib.DEBUG_MODE then return end

-- Data stage
if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
    table.insert(data.raw.technology["automation-science-pack"].effects,
        mupgrade_lib.make_modifier({icon="__base__/graphics/icons/assembling-machine-2.png"}, "speed", "assembler", 10))

--Control stage
elseif script then
    local event_lib = require("__machine-upgrades__.script.event-lib")
    local function register()
        remote.call("machine-upgrades-techlink", "add_technology_effect", 
                "automation-science-pack", "assembling-machine-2", {speed=0.1}, "Assembler1")
    end
    event_lib.on_init("test-suite", register)
    event_lib.on_configuration_changed("test-suite", register)
end


