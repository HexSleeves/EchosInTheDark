# Tilemap System Specification

## Overview

This specification defines the tilemap system for the RL2025 OCaml Roguelike game. The tilemap system is responsible for representing, generating, and managing the game's map, including tiles, terrain, and spatial relationships.

## Requirements

### Map Representation

- [x] Define a tilemap data structure with width, height, and tile array
- [x] Support efficient indexing of tiles by coordinates
- [x] Store map seed for reproducibility
- [ ] Support additional map metadata (level, name, etc.)

### Map Generation

- [x] Implement procedural map generation with configurable dimensions
- [x] Generate maps with consistent results for the same seed
- [x] Create boundary walls automatically
- [ ] Support different map generation algorithms
- [ ] Allow configuration of map features (room size, corridor width, etc.)
- [ ] Generate special features (rooms, corridors, doors, etc.)

### Tile Access and Manipulation

- [x] Provide functions to get tiles at specific coordinates
- [x] Implement functions to set tiles at specific coordinates
- [ ] Add utility functions for finding specific tile types
- [ ] Support efficient area operations (fill, clear, etc.)

### Map Analysis

- [ ] Implement pathfinding between points on the map
- [ ] Support field of view and line of sight calculations
- [ ] Add functions to identify rooms, corridors, and other features
- [ ] Provide distance calculations between points

## Acceptance Criteria

1. Maps can be generated with different seeds and dimensions
2. Map generation is consistent for the same seed
3. Boundary walls prevent leaving the map
4. Tile access is efficient and bounds-checked
5. Maps support all needed tile types
6. Map generation creates playable, connected levels

## Technical Design

The tilemap is managed through the `Tilemap.t` type:

```ocaml
type t = {
  seed : int; (* 15 bit value *)
  width : int;
  height : int;
  map : Tile.t array;
}
```

The system provides these key functions:

- `get_height v` and `get_width v` - Get map dimensions
- `get_tile v x y` - Access a tile at coordinates
- `set_tile v x y tile` - Set a tile at coordinates
- `generate ?w ?h ~seed` - Generate a new map

Map coordinates start at the top-left (0,0) and increase to the right (x) and down (y).

The map is stored as a 1D array for efficiency, with utility functions to convert between 2D coordinates and 1D indices.

## Map Generation Algorithm

The current implementation:

1. Creates an empty map filled with floor tiles
2. Places walls around the perimeter
3. (Future) Will add rooms, corridors, and other features

## Notes

- Consider implementing multiple map generation algorithms
- Chunking might be needed for larger maps
- Multi-level maps will require extensions to this system
- Region tagging could be useful for gameplay features
- Performance optimizations may be needed for larger maps or complex operations
