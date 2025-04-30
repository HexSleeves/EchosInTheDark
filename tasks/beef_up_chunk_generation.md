# Beef Up Chunk Generation

[x] In Progress
[] Completed
[] TODO

A checklist for modularizing and improving chunk generation using all available algorithms (CA, rooms, etc.) and making the system pluggable and extensible.

## Tasks

- [ ] Refactor `mapgen/generator.ml` to expose a unified `generate_chunk` function that can use different algorithms (CA, rooms, custom, etc.)
- [ ] Define a `chunk_gen_algo` type and a strategy selection function (by biome, depth, or random)
- [ ] Update `chunk_manager.ml` to use the new modular chunk generation and select the algorithm per chunk
- [ ] Ensure entity/monster placement is called after tile generation, using the right placement logic for each algorithm
- [ ] Make it easy to add new algorithms or tweak parameters per chunk
- [ ] Test: Chunks are generated with different algorithms as expected
- [ ] Test: Entities/monsters are placed correctly for each chunk type
- [ ] Document the new chunk generation pipeline and how to add new algorithms

---

**Review this checklist as you work. Check off each item as you complete it!**
