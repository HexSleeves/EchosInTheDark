# Technical Architecture

## Core Architecture Components

### 1. Entity System

```ocaml
(* Core abstractions *)
EntityManager: Manages game entities
Entity: Base type for all game objects
Actor: Represents entities that can take turns
Turn_queue: Manages turn order for actors
```

### 2. Directory Structure

```
src/
  ├── bin/           # Main executable
  │   └── rl2025.ml  # Entry point
  ├── rl_core/       # Core game logic and types
  │   ├── types.ml   # Entity and type definitions
  │   ├── backend.ml # Main game state container
  │   ├── actions.ml # Action handling
  │   ├── actor.ml   # Actor definitions
  │   ├── actor_manager.ml # Actor management
  │   ├── entity_manager.ml # Entity management
  │   ├── turn_queue.ml # Turn scheduling
  │   ├── turn_system.ml # Turn processing
  │   ├── map/       # Map-related modules
  │   │   ├── tile.ml # Tile definitions
  │   │   └── tilemap.ml # Map structure
  │   ├── mapgen/    # Map generation
  │   │   ├── ca.ml  # Cellular automata
  │   │   ├── config.ml # Generation config
  │   │   └── generator.ml # Map generator
  │   └── map_manager.ml # Multi-level management
  ├── rl_ui/         # UI and rendering
  │   ├── renderer.ml # Rendering utilities
  │   ├── play.ml    # Play screen
  │   ├── mainmenu.ml # Main menu
  │   └── modules.ml # Module initialization
  └── rl_utils/      # Utility functions
      ├── rng.ml     # Random number generation
      └── utils.ml   # General utilities

test/               # Test suite
media/             # Media assets and screenshots
resources/          # Game resources
static/            # Static assets
```

### 3. Key Abstractions

#### Entity Management

- **EntityManager**: Central manager for all game entities
  - Entity creation and deletion
  - Entity lifecycle management
  - Entity queries and updates
  - Position tracking

#### Actor System

- **Actor**: Represents entities that can take turns
  - Action queue management
  - Turn scheduling
  - Speed and timing control

- **Turn_queue**: Manages the order of actor turns
  - Priority queue based on timing
  - Actor scheduling

#### Map Generation and Management

- **Mapgen.Generator**: Creates procedural dungeon levels
  - Cellular automata for cave generation
  - Stairs placement using farthest-point algorithm
  - Player start position selection

- **Map_manager**: Manages multiple dungeon levels
  - Level state persistence
  - Level transitions
  - Current level tracking

#### Game Objects

- **Player Entity**: Represents the player character
  - Position tracking
  - Direction handling
  - Stats and attributes

- **Creature Entity**: Represents NPCs and monsters
  - Species and attributes
  - Stats and behavior

### 4. Build and Development

#### Build System

- Uses Dune 3.9 for build management
- OPAM package management
- Development tools configuration (.vscode, .editorconfig)

#### Development Workflow

1. Code organization follows OCaml conventions
2. Entity-based architecture for game objects
3. Centralized type definitions
4. Test-driven development support

### 5. Dependencies

- Core OCaml libraries:
  - base
  - core_kernel
  - containers
  - logs
- Graphics libraries:
  - raylib (via OCaml bindings)
  - raygui
- Development tools:
  - dune (build system)
  - ocamlformat (code formatting)
  - ppx extensions (deriving, yojson_conv, etc.)
