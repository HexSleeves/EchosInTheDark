# Map Chunking System Design

**Version:** 1.0
**Date:** 2025-04-28

## 1. Overview

This document outlines the design for a dynamic map chunking system for the OCaml roguelike `rl2023_ocaml`. It replaces the current static, level-based map loading with a system that loads and unloads fixed-size map chunks around the player, enabling a potentially infinite, flat world. Generation uses a hybrid approach combining noise functions for base terrain/biomes and rule-based triggering of existing/adapted algorithms for specific features.

## 2. Coordinate Systems

*   **World Coordinates (`world_pos`):** Absolute `(x, y)` integer coordinates within the infinite world space. Used for entity positions. Type: `int * int`.
*   **Chunk Coordinates (`chunk_coord`):** Integer pairs `(cx, cy)` identifying a specific chunk. Calculated as `cx = floor(world_x / chunk_width)`, `cy = floor(world_y / chunk_height)`. Chunk size is fixed at 32x32. Type: `int * int`.
*   **Local Coordinates (`local_pos`):** Integer pairs `(lx, ly)` representing a tile's position *within* a chunk (0 to 31). Calculated as `lx = world_x mod 32`, `ly = world_y mod 32`. Type: `int * int`.

## 3. Data Structures

*   **`Chunk.t`:** Represents a single map chunk. To be defined in a new file, e.g., `src/rl_core/dungeon/chunk.ml`.

    ```ocaml
    type chunk_coord = int * int
    type biome_type = Plains | Forest | Mountain | Water_Body (* ... etc *)

    type chunk_metadata = {
      seed: int;
      biome: biome_type;
      (* ... other flags like 'has_feature_x', 'is_river_source' *)
    }

    type t = {
      coords : chunk_coord; (* (cx, cy) *)
      tiles : Tile.t array array; (* 2D array [32][32] *)
      entity_ids : Entity_id.t list; (* IDs of entities physically within this chunk's bounds *)
      metadata : chunk_metadata;
      mutable last_accessed_turn : int; (* For potential LRU cache eviction optimization *)
    }
    ```

*   **`ActiveChunks.t`:** Manages currently loaded chunks. Likely managed within a revised `Map_manager` or a new `Chunk_manager`. Uses a Hashtbl for efficient lookup by `chunk_coord`.

    ```ocaml
    (* Module: Chunk_manager *)
    type t = {
      active_chunks: (chunk_coord, Chunk.t) Hashtbl.t;
      (* ... other manager state *)
    }
    ```

*   **Entity Management:** Entities remain globally managed (e.g., by `Entity_manager`). Chunks store references (`entity_ids`) to entities currently within their bounds. The `Position` component (`src/rl_core/components/position.ml`) will store `world_pos`.

## 4. Chunk Loading/Unloading

*   **Trigger:** Player movement that results in a change of the player's `chunk_coord`.
*   **Radius:** A 5x5 grid of chunks centered on the player's current chunk `(pcx, pcy)`. The required chunk coordinates range from `(pcx-2, pcy-2)` to `(pcx+2, pcy+2)`.
*   **Algorithm:**
    1.  When the player's `chunk_coord` changes:
        *   Calculate the new set of required `chunk_coord`s based on the 5x5 radius.
        *   Get the set of currently loaded `chunk_coord`s (keys from `ActiveChunks.t`).
        *   **Chunks to Load:** Identify required coordinates *not* currently loaded. For each, trigger generation/loading and add the resulting `Chunk.t` to `ActiveChunks.t`.
        *   **Chunks to Unload:** Identify loaded coordinates *not* in the required set. Remove these chunks from `ActiveChunks.t` (allowing GC).
*   **Persistence:** Unloaded chunks are discarded. They will be regenerated identically if revisited due to deterministic, coordinate-based seeding. State changes *to the chunk itself* (e.g., terrain destruction) or persistent entity states within the chunk would require a separate saving mechanism if needed (considered out of scope for this initial design).

## 5. Generation Strategy (Hybrid)

*   **`Chunk_generator.ml` (New Module):** Responsible for generating a `Chunk.t` given a `chunk_coord`.
*   **Coordinate Seeding:** The primary RNG seed for generating chunk `(cx, cy)` must be derived deterministically from `(cx, cy)` and a global world seed (e.g., `seed = hash(world_seed, cx, cy)`). This ensures reproducibility.
*   **Step 1: Base Terrain/Biome Generation:**
    *   Use a noise function (e.g., Simplex noise via an OCaml library) seeded by the deterministic chunk seed.
    *   Sample noise at multiple frequencies/octaves. Critically, use **world coordinates** `(world_x, world_y)` corresponding to each `local_pos` as input to the noise function to ensure seamless values across chunk boundaries.
    *   Map noise values to base `Tile.t` types (e.g., Water, Grass, Sand, Rock) to populate the `chunk.tiles` array.
    *   Determine a primary `biome_type` for the chunk based on noise characteristics (e.g., average height, roughness) and store it in `chunk_metadata`.
*   **Step 2: Feature Overlay:**
    *   Based on `chunk_coord` and/or the generated biome/noise values, decide if a larger feature (dungeon entrance, village outline, river segment, prefab placement area) should be placed *starting* in this chunk. Use deterministic rules (e.g., `hash(chunk_seed, 'feature_type') mod N < threshold`).
    *   Adapt existing algorithms (`Ca.run`, `Rooms.rooms_generator`, `Prefab.load_prefab`) to operate on the chunk's `tiles` array, potentially modifying the base terrain. These algorithms must also use the deterministic chunk seed.
    *   Features spanning multiple chunks require careful design. Initial implementation could constrain features to single chunks or use generation logic that can query neighbor data (or pre-calculate feature locations globally based on coordinates).
*   **Step 3: Entity Placement:**
    *   Based on the final tiles, biome, and features within the chunk, place relevant entities (monsters, items, NPCs).
    *   Use the chunk seed for deterministic placement rules (e.g., "In Forest biome chunks, place 1-3 wolf entities at random valid floor tiles.").
    *   Create entities using `Entity_manager.add_entity` and store their returned `Entity_id.t` in the `Chunk.t.entity_ids` list. Assign their `Position` component using the calculated `world_pos`.

## 6. Rendering

*   **`Renderer.ml`:** Needs modification to handle world coordinates and chunked data.
*   **Viewport:** Define the player's view dimensions (e.g., `view_width`, `view_height` in tiles).
*   **Camera:** Conceptually centered on the player's `world_pos`. Determine the top-left `world_pos` of the camera view.
*   **Tile Access for Rendering:**
    1.  Iterate through the screen tile coordinates `(sx, sy)` from `(0, 0)` to `(view_width-1, view_height-1)`.
    2.  For each `(sx, sy)`, calculate the corresponding `world_pos = (camera_top_left_x + sx, camera_top_left_y + sy)`.
    3.  Calculate the `chunk_coord` and `local_pos` for this `world_pos`.
    4.  Look up the `Chunk.t` in `ActiveChunks.t` using `chunk_coord`.
    5.  If found, access `chunk.tiles[local_pos.y][local_pos.x]` (adjust indexing based on array layout) to get the `Tile.t` to draw at `(sx, sy)`.
    6.  If not found (error condition, should be pre-loaded), render a default/void tile and log an error.
    7.  Also query `Entity_manager` for renderable entities at this `world_pos` to draw on top of the tile.

## 7. Integration Points & Refactoring

*   **`Map_manager.ml`:** Heavily refactor or replace with `Chunk_manager.ml`. Remove level-based logic. Manage `ActiveChunks.t`. Coordinate loading/unloading via `Chunk_generator`. Provide functions like `get_tile_at(world_pos): Tile.t option` and potentially `get_chunk(chunk_coord): Chunk.t option`.
*   **`Dungeon.Tilemap.ml`:** Likely deprecated or significantly reduced. The concept of a single large map array disappears. `Tile.t` remains essential.
*   **`Mapgen/`:**
    *   Create `Chunk_generator.ml`.
    *   Adapt `Ca.ml`, `Rooms.ml`, `Prefab.ml` to potentially work on smaller 32x32 grids or integrate with the chunk generation flow. Need noise library integration (find/choose an OCaml noise library).
    *   `Generator.ml` (current top-level) likely deprecated for world generation.
*   **`Movement_system.ml`:** Update to work with `world_pos`. Check tile walkability using `Chunk_manager.get_tile_at(target_world_pos)`. Trigger chunk loading checks in `Chunk_manager` when player `chunk_coord` changes.
*   **`Entity_manager.ml` / `Position.ml`:** Use `world_pos`. Need efficient ways to query entities within a given world-space bounding box (for rendering, AI, etc.). This might eventually require spatial partitioning (e.g., a quadtree or spatial hash mapped to `world_pos`) separate from the chunk system itself, or iterating through entities only in currently loaded chunks.
*   **`Actor_manager.ml` / `Turn_queue.ml`:** Remove per-level separation. Actors operate in the continuous world space. AI needs to consider chunk boundaries/loading when pathfinding over longer distances (pathfinding might need to request chunk generation).
*   **`State.ml`:** Refactor to remove level-specific state; world state is now continuous. Player position is `world_pos`. Game state needs to include the `Chunk_manager`'s state.
*   **`Types.ml`:** Define `world_pos`, `chunk_coord`, `local_pos` types.

## 8. Performance Considerations

*   **Memory:** Only loaded chunks (5x5 = 25 chunks) consume significant memory for tile data. Entity data depends on density. `32*32 tiles/chunk * 25 chunks = 25600` tiles loaded, which is generally manageable.
*   **Latency:** Chunk generation is the main latency concern, especially if complex algorithms or noise functions are used. Keep generation algorithms fast. Consider asynchronous loading/generation in background threads/processes if initial synchronous generation proves too slow during gameplay, potentially displaying placeholder visuals until ready.
*   **Tile Access:** Hash table lookups for chunks are fast (average O(1)). Accessing tiles within a chunk's 2D array is O(1).
*   **Entity Queries:** Querying entities in a world area (e.g., "find all entities within X distance of player") might become a bottleneck if iterating through all global entities. Filtering by loaded chunks first helps. Spatial partitioning may be necessary for larger entity counts.

## 9. Diagrams

### Component Interaction

```mermaid
graph TD
    PlayerInput --> MovementSystem;
    MovementSystem -- Updates world_pos --> PlayerPosition[Player Position Component];
    MovementSystem -- Checks walkability --> ChunkManager;
    MovementSystem -- Notifies chunk change --> ChunkManager;
    ChunkManager -- Determines required chunks --> ActiveChunks{ActiveChunks (Hashtbl)};
    ChunkManager -- Requests chunk --> ChunkGenerator;
    ChunkGenerator -- Uses noise/rules --> NoiseLib[Noise Library];
    ChunkGenerator -- Uses algorithms --> MapgenAlgos[CA, Rooms, Prefab];
    ChunkGenerator -- Creates entities --> EntityManager;
    ChunkGenerator -- Returns Chunk.t --> ChunkManager;
    ChunkManager -- Stores chunk --> ActiveChunks;
    ChunkManager -- Provides tile data --> Renderer;
    ChunkManager -- Provides tile data --> AISystem[AI System];
    Renderer -- Reads player pos --> PlayerPosition;
    Renderer -- Reads entity pos/renderable --> EntityManager;
    Renderer -- Draws to screen --> Screen;
    AISystem -- Reads entity pos --> EntityManager;
    AISystem -- Pathfinds --> ChunkManager;

    subgraph Chunking Core
        ChunkManager
        ActiveChunks
        ChunkGenerator
    end

    subgraph Existing Systems (Modified)
        MovementSystem
        Renderer
        EntityManager
        AISystem
        MapgenAlgos
    end
```

### Coordinate Translation

```mermaid
graph LR
    WorldPos[World Position (x, y)] -- floor(pos / 32) --> ChunkCoord[Chunk Coordinate (cx, cy)];
    WorldPos -- pos mod 32 --> LocalPos[Local Position (lx, ly)];
    ChunkCoord -- Lookup --> ActiveChunks{Active Chunks};
    ActiveChunks -- Returns --> ChunkData[Chunk.t];
    ChunkData -- Access with LocalPos --> TileData[Tile.t @ tiles[ly][lx]];
