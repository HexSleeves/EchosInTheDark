# Project Structure and Module Dependency Overview

This document provides an up-to-date overview of the architecture and module dependencies for Echoes in the Dark, including directory/module descriptions and diagrams. For a high-level system view, see [architecture.md](architecture.md). For chunking details, see [chunking_design.md](chunking_design.md).

---

## 1. Directory & Module Overview

- **src/** — Main source code
  - **bin/** — Game entry point(s)
  - **rl_core/** — Core game logic (ECS, systems, map/chunk management, etc.)
    - **actors/** — Actor/AI logic
    - **components/** — ECS components (position, stats, etc.)
    - **dungeon/** — Chunking, mapgen, tile types
    - **entities/** — Entity spawning and management
    - **events/** — Event system
    - **mapgen/** — Procedural map/chunk generation
    - **state/** — Game state, save/load
    - **systems/** — ECS systems (movement, combat, etc.)
  - **rl_loader/** — Resource and prefab loading
  - **rl_ui/** — UI, rendering, input (Raylib integration)
  - **rl_utils/** — Shared utilities and helpers
- **test/** — Tests
- **media/** — Screenshots and assets
- **resources/** — Game resources (fonts, images, prefabs, tiles)
- **docs/** — Documentation

---

## 2. Core Module Dependency Flow

```mermaid
flowchart TD
    UI['rl_ui']
    RLCore['rl_core']
    Raylib['Raylib']
    RLUtils['rl_utils']
    RLLoader['rl_loader']
    RLCoreMap['rl_core.map/rl_core.mapgen']
    RLCoreChunk['rl_core.dungeon/chunk_manager']
    RLCoreActors['rl_core.actors']
    RLCoreEntities['rl_core.entities']
    RLCoreComponents['rl_core.components']
    RLCoreSystems['rl_core.systems']
    RLCoreState['rl_core.state']
    RLCoreTypes['rl_core.types']

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

**Explanation:**

- UI depends on both rl_core and Raylib.
- rl_core is composed of several submodules, each with their own dependencies.
- The chunking system (dungeon/chunk_manager) is central to world management.

---

## 3. Game Loop and Data Flow

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

**Explanation:**

- Shows the flow of data and control through the main game loop.
- Input is processed, actions are queued, backend updates state, and chunking is managed dynamically.

---

## 4. Input Handling Flow

```mermaid
flowchart TD
    RaylibInput[Raylib.is_key_pressed]
    InputModule[input.ml]
    UIPlay[play.ml]
    Backend[backend.ml]

    RaylibInput --> InputModule
    InputModule -- "action_type option" --> UIPlay
    UIPlay -- "queue action" --> Backend
```

**Explanation:**

- Shows how input is handled from the raw key press to the action being queued for the backend.

---

## 5. Cross-References

- For high-level architecture: [architecture.md](architecture.md)
- For chunking system: [chunking_design.md](chunking_design.md)
- For workflow/coding policies: [workflow_policies.md](workflow_policies.md)
