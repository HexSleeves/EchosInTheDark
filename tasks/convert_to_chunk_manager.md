# Convert to Chunk Manager

[x] In Progress
[] Completed
[] TODO

A checklist for migrating the codebase from the old map_manager system to the new chunk_manager system.

## Tasks

- [ ] Remove all references to `map_manager` and `Map_manager` in state modules
- [ ] Add `chunk_manager : Chunk_manager.t` to the State type in `state_types.ml`
- [ ] In `state.ml`, replace all map_manager logic with chunk_manager logic
  - [ ] Use `Chunk_manager.create` in state construction
  - [ ] Replace map/level access with chunk-based access (e.g., `get_tile_at`)
- [ ] Refactor `state_levels.ml` to remove level transition logic tied to map_manager
  - [ ] Remove `save_level_state`, `go_to_next_level`, `load_level_state` calls
  - [ ] Replace with logic to move player and update chunk_manager
- [ ] Update all tile/entity access in state to use chunk_manager
- [ ] Ensure entity initialization places entities in the world and registers them with chunk_manager
- [ ] Remove or refactor any code that assumes a single big map
- [ ] Test: Player movement loads/unloads chunks as expected
- [ ] Test: Entities are correctly tracked in chunks
- [ ] Test: Rendering uses chunk_manager for tile lookups

---

**Review this checklist as you work. Check off each item as you complete it!**
