# Convert to Chunk Manager

[] In Progress
[x] Completed
[ ] TODO

A checklist for migrating the codebase from the old map_manager system to the new chunk_manager system.

## Tasks

- [x] Remove all references to `map_manager` and `Map_manager` in state modules
- [x] Add `chunk_manager : Chunk_manager.t` to the State type in `state_types.ml`
- [x] In `state.ml`, replace all map_manager logic with chunk_manager logic
  - [x] Use `Chunk_manager.create` in state construction
  - [x] Replace map/level access with chunk-based access (e.g., `get_tile_at`)
- [x] Refactor `state_levels.ml` to remove level transition logic tied to map_manager
  - [x] Remove `save_level_state`, `go_to_next_level`, `load_level_state` calls
  - [x] Replace with logic to move player and update chunk_manager
- [x] Update all tile/entity access in state to use chunk_manager
- [x] Ensure entity initialization places entities in the world and registers them with chunk_manager
- [x] Remove or refactor any code that assumes a single big map
- [x] Test: Player movement loads/unloads chunks as expected
- [x] Test: Entities are correctly tracked in chunks
- [x] Test: Rendering uses chunk_manager for tile lookups

---

**Review this checklist as you work. Check off each item as you complete it!**
