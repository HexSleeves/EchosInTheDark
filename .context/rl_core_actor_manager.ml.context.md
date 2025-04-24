# Purpose
Manages actors (entities capable of taking turns) in the game, including their creation, state, and actions. Provides a persistent map for efficient actor lookup and manipulation.

# Key Functions/Types
- **module Actor**: Defines the `actor_id` type and the `Actor.t` record (`speed`, `alive`, `next_turn_time`, `next_action`).
- **create**: Initializes an empty actor manager.
- **add / remove**: Add or remove actors by ID.
- **get / get_unsafe**: Retrieve actors by ID, with or without exception on missing.
- **update**: Update an actor in the manager using a function.
- **create_player_actor / create_rat_actor / create_goblin_actor**: Constructors for specific actor types.
- **copy / restore**: Persistence utilities for the actor manager.
- **debug_print**: Logs all actors in the manager for debugging.

# Notable Implementation Details
- Uses OCaml's `Map` for persistent, functional data structure.
- Actor actions are queued and managed per-actor.
- Includes derived serialization and pretty-printing for actor types.
- Pattern of "copy" and "restore" supports undo/redo or save/load features.
