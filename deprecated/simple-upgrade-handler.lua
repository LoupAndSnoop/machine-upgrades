local simple_handler = {}


---comment
---@param my_upgrade_data MUpgradeData[]
function simple_handler.handle_mupgrade_data(my_upgrade_data)
    ------You can legit copy-paste this next block of code into a file that is run in both data and control stage.
    -- What to do in Data stage
    if data and data.raw and data.raw.module and table_size(data.raw.module) > 0 then
        mupgrade_lib.handle_modifier_data(my_upgrade_data)
    --What to do in Control stage
    elseif script then
        local function register1() remote.call("machine-upgrades-techlink", "add_upgrade_data", my_upgrade_data) end

        --Use whatever event handling you want, but that remote interface needs to get called on_init and on_configuration_changed!
        local event_lib = require("__machine-upgrades__.script.event-lib")
        event_lib.on_init("test-suite-1", register1)
        event_lib.on_configuration_changed("test-suite-1", register1)
    end
end


return simple_handler