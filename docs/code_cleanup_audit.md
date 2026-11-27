# Formal project cleanup audit

Branch: feature/code-cleanup-modules. Local changes only; no upload authorized.

## Completed

- Ocean, jungle and sky orange groups now share orange_collection_group.gd for creation, ring layout, swept pickup detection and ledger forwarding. Stage modules retain authored positions, actor eligibility and attraction settings.
- Retired permanent orange counter scene/script/UID moved outside the Godot project to archive/retired_orange_counter. No gameplay or test code referenced the retired scene; current orange_counter test exercises OrangePickupCounter instead. Archived scene is historical source, not a standalone runnable scene.
- Original artwork, orange IDs/counts, death persistence and shared ledger interface remain unchanged.

## Confirmed retained legacy code

- SurfaceGrab in formal_ocean_fish.tscn is disabled. Its script still preloads tendril/camera/prompt/art and is instantiated. Future removal must also remove reset and state checks in fish teleport and checkpoint flows; deleting only its script would break these callers.
- Five *_prototype level scenes remain in the formal project. They are not the shipped main flow. Their dependencies must be checked before removing shared actor/environment code.
- scenes/previews/settlement_descent.tscn and halo_reward_preview.tscn ARE used by the production ending. Do not remove by filename.
- Wall join and outline modules are active rendering fixes, not unused code.

## Current organization

173 GDScript files before this cleanup. Existing folders separate movement, input, possession, camera, enemies, status, visual, UI, audio and collectibles. Environment (43 scripts) mixes level assembly, checkpoints, combat and rendering glue. Follow-up refactors should move one subsystem at a time and update scene references/tests. There is no measured basis to attribute current performance to unused source files alone; instantiated nodes and preloaded textures require profiling.


## Retired gameplay removal (feature/remove-retired-gameplay)

- Removed SurfaceGrab from formal_ocean_fish and removed production reset, teleport, shore-exit, shortcut and camera dependencies.
- Archived its four exclusive scripts and UID files outside the project. Shared jellyfish tendrils/warnings and main-menu surface_arrow_volley remain active and unchanged.
- Archived the five prototype scene/controller pairs, their old game_flow scene/controller and two old prototype sky transitions. No production scene/script referenced these entry points.
- Archived three tests dedicated to the removed grab; updated active fixtures and final-shark/shore/camera assertions to test the current flow.
- Archive preserves original source for reference; it is not an independently runnable Godot project. Original artwork is retained because shared assets are not proven unused.
- Formal ending preview scenes are retained because production handoff still uses them.
