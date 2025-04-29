# System Architecture: Echoes in the Dark

This document describes the high-level architecture of the Echoes in the Dark roguelike engine, focusing on modularity, extensibility, and the new chunking system for infinite/procedural worlds.

---

## 1. Overview

Echoes in the Dark is built around a modular, entity-component-system (ECS) core, with a focus on functional OCaml patterns and clean separation of concerns. The architecture is designed for easy extension, robust gameplay logic, and efficient rendering/input via Raylib bindings.

- **Entity-Component System (ECS):** All game objects are entities with attached components (position, stats, renderable, etc.). Systems operate on entities with relevant components.
- **Chunking System:** The world is divided into 32x32 tile chunks, loaded/unloaded dynamically around the player for infinite/procedural exploration. See [chunking_design.md](chunking_design.md).
- **Modular Layers:**
  - **UI Layer:** Handles rendering, input, and user feedback (via Raylib).
  - **Core Logic:** Game rules, ECS, map/chunk management, turn system, AI, etc.
  - **Resource/Loader Layer:** Loads assets, prefabs, and resources.
  - **Utils:** Shared utilities, helpers, and functional patterns.

---

## 2. Major Modules & Relationships

```mermaid
flowchart TD
    UI[rl_ui]
    RLCore[rl_core]
    Raylib[Raylib]
    RLUtils[rl_utils]
    RLLoader[rl_loader]
    RLCoreMap[rl_core.map/rl_core.mapgen]
    RLCoreChunk[rl_core.dungeon/chunk_manager]
    RLCoreActors[rl_core.actors]
    RLCoreEntities[rl_core.entities]
    RLCoreComponents[rl_core.components]
    RLCoreSystems[rl_core.systems]
    RLCoreState[rl_core.state]
    RLCoreTypes[rl_core.types]

    UI --> RLCore
    UI --> Raylib
    RLCore --> RLCoreActors
    RLCore --> RLCoreEntities
    RLCore --> RLCoreComponents
    RLCore --> RLCoreSystems
    RLCore --> RLCoreMap
    RLCore --> RLCoreChunk
    RLCore --> RLCoreState
    RLCore --> RLCoreTypes
    RLCore --> RLUtils
    RLCore --> RLLoader
    RLCoreMap --> RLCoreChunk
    RLCoreChunk --> RLCoreEntities
    RLCoreChunk --> RLCoreComponents
    RLCoreActors --> RLCoreEntities
    RLCoreActors --> RLCoreComponents
    RLCoreEntities --> RLCoreComponents
    RLCoreSystems --> RLCoreEntities
    RLCoreSystems --> RLCoreComponents
    RLCoreState --> RLCoreEntities
    RLCoreState --> RLCoreComponents
    RLCoreState --> RLCoreChunk
    RLCoreState --> RLCoreMap
    RLLoader --> RLCore
    RLUtils --> RLCore
```

**Key Points:**

- The UI layer depends on both the core logic and Raylib.
- The core logic is composed of submodules for actors, entities, components, systems, map/chunk management, and state.
- The chunking system is central to world management and interacts with mapgen, entities, and state.
- All modules use functional, OCaml-idiomatic patterns and the Base library.

---

## 3. Chunking System

See [chunking_design.md](chunking_design.md) for a detailed design. In summary:

- The world is split into 32x32 tile chunks, loaded/unloaded in a 5x5 grid around the player.
- Chunks are generated deterministically using coordinate-based seeding for infinite/procedural worlds.
- Entities are managed globally, but each chunk tracks which entities are present within its bounds.
- The renderer and systems query the chunk manager for tile/entity data as needed.

---

## 4. Data & Control Flow

```mermaid
flowchart TD
    subgraph UI Layer
        UIPlay[play.ml]
        UIModules[modules.ml]
        UIRenderer[renderer.ml]
    end

    subgraph Core Logic
        Input[input.ml]
        Backend[backend.ml]
        TurnSystem[turn_system.ml]
        Actor[actor.ml]
        Entity[entity.ml]
        Actions[action.ml/actions.ml]
        State[state.ml]
        Types[types.ml]
    end

    subgraph Data
        Map[map/mapgen]
        ChunkManager[chunk_manager.ml]
        Spawner[spawner.ml]
    end

    UIPlay -- "calls" --> Input
    Input -- "returns action_type" --> UIPlay
    UIPlay -- "queues action" --> Backend
    Backend -- "processes turn" --> TurnSystem
    TurnSystem -- "gets/updates" --> Actor
    TurnSystem -- "gets/updates" --> Entity
    TurnSystem -- "executes" --> Actions
    Backend -- "updates" --> State
    Backend -- "reads/writes" --> Map
    Backend -- "spawns" --> Spawner
    Backend -- "loads/unloads" --> ChunkManager
    Actor -- "references" --> Types
    Entity -- "references" --> Types
    Actions -- "references" --> Types
    State -- "references" --> Types
```

---

## 5. External Dependencies

- **Raylib:** Graphics, input, and audio via OCaml bindings.
- **Base:** Modern standard library for OCaml, used throughout the codebase.
- **Other Libraries:** Noise generation for mapgen, etc.

---

## 6. Extensibility & Testing

- The modular design allows for easy addition of new systems, components, and features.
- All code follows functional, OCaml-idiomatic patterns (see [workflow_policies.md](workflow_policies.md)).
- Testing and documentation are encouraged for all new modules.

---

*See also: [chunking_design.md](chunking_design.md), [project_structure.md](project_structure.md), [workflow_policies.md](workflow_policies.md)*
