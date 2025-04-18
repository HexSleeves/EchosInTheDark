## Map Generation & Level Progression

- The `mapgen` module handles procedural map generation using cellular automata, random player spawn, and stair placement.
- Stairs (up/down) are placed using a BFS-based farthest-point algorithm, with randomness for replayability.
- The `Tilemap.t` type now includes `player_start`, `stairs_up`, and `stairs_down` fields for multi-level support.
- Graphical support for new tile types (stairs) is handled in the UI layer.
- Multi-level transitions will use these fields to place the player and manage level state.
