[![Discord](https://img.shields.io/badge/Discord-%235865F2.svg?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/CaDJzEj557)[![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)](https://github.com/LoupAndSnoop/rubia)
Reach me fastest on Discord.

This mod allows you to make technologies upgrade a machine like with the effect of a module effect.

The most important functions in this mod are:
    - mupgrade_lib.make_modifier : Use this in data stage to create the desired effect in a technology.
    - mupgrade_lib.add_id_flag : Use this to safely add the get-by-unit-number flag to an entity.
    - remote.call("machine-upgrades-techlink", "add_technology_effect", technology_name, entity_name, effect, entity_handler): Use this in control stage in an event callback to tie a specific entity prototype and effect to the technology's research progress.
Look at **test-suite.lua** to see actual working usage.

Note that entity_handler should be matched to the same entity_name to save on UPS.