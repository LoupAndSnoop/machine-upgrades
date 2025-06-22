--wretlaw's beacon reabalance mod messes with mods that try to overload beacons.
--"wret-beacon-rebalance-mod". The problem is that they currently store everything into local, and not storage.
--There are several forks, all with the same problem. Which can cause desync. All have the same interface.
local beacon_rebalance_mods = {
    "wret-beacon-rebalance-mod", "wret-beacon-rebalance-mod-bobs-module-fork", "wret-beacon-rebalance-mod-k2-fix"}
local found_mod = false
for _, entry in pairs(beacon_rebalance_mods) do
    found_mod = found_mod or (not not script.active_mods[entry])
end
if found_mod then
    local function to_call()
        if remote.interfaces["wr-beacon-rebalance"] and settings.startup["wret-overload-disable-overloaded"].value then
            remote.call("wr-beacon-rebalance", "add_whitelisted_beacon", "mupgrade-beacon")
            remote.call("wr-beacon-rebalance", "reset_beacons")
        end
    end
    local event_lib = require("__machine-upgrades__.script.event-lib")
    event_lib.on_load("wret-beacon-rebalance-whitelist", to_call)
    event_lib.on_event(defines.events.on_player_joined_game, "wret-beacon-rebalance-whitelist", to_call)
end