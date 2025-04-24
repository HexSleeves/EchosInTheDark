# Purpose
Provides a high-level API for interacting with the game state, abstracting over the lower-level State module. Handles mode management, entity access, movement, and actor actions.

# Key Functions/Types
- **type t**: Alias for `State.t`, representing the backend state.
- **make**: Initializes the backend state with debug flag, width, height, and seed.
- **get_mode / set_mode**: Get or set the current control mode.
- **get_player_id / get_player_entity**: Access the player entity or its ID.
- **get_entities**: Retrieve all entities in the game.
- **move_entity**: Move an entity to a new location.
- **queue_actor_action**: Queue an action for an actor.
- **get_current_map**: Retrieve the current map.

# Notable Implementation Details
- Delegates all operations to the State module, providing a simplified interface.
- Encapsulates entity and map management for use by higher-level systems.
- Designed for extensibility and separation of concerns between state management and game logic.
