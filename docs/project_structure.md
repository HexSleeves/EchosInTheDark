# Project Structure and Module Dependency Overview

This document provides a high-level overview of the architecture and module dependencies for the project, using Mermaid diagrams for clarity.

---

## 1. Core Module Dependency Flow

```mermaid
flowchart TD
    UI['rl_ui']
    RLCore['rl_core']
    Raylib['Raylib']
    RLUtils['rl_utils']
    RLCoreMap['rl_core.map/rl_core.mapgen']
    RLCoreActions['rl_core.action/actions/input']
    RLCoreBackend['rl_core.backend']
    RLCoreTurn['rl_core.turn_system/turn_queue']
    RLCoreActor['rl_core.actor/actor_manager']
    RLCoreEntity['rl_core.entity']
    RLCoreState['rl_core.state']
    RLCoreTypes['rl_core.types']
    RLCoreSpawner['rl_core.spawner']

    UI --> RLCore
    UI --> Raylib
    RLCore --> RLCoreActions
    RLCore --> RLCoreBackend
    RLCore --> RLCoreTurn
    RLCore --> RLCoreActor
    RLCore --> RLCoreEntity
    RLCore --> RLCoreState
    RLCore --> RLCoreTypes
    RLCore --> RLCoreSpawner
    RLCore --> RLCoreMap
    RLCore --> RLUtils
    RLCoreActions --> RLCoreTypes
    RLCoreActions --> RLCoreEntity
    RLCoreBackend --> RLCoreActor
    RLCoreBackend --> RLCoreEntity
    RLCoreBackend --> RLCoreTurn
    RLCoreBackend --> RLCoreMap
    RLCoreBackend --> RLCoreTypes
    RLCoreTurn --> RLCoreActor
    RLCoreTurn --> RLCoreTurn
    RLCoreTurn --> RLCoreEntity
    RLCoreTurn --> RLCoreBackend
    RLCoreActor --> RLCoreTypes
    RLCoreActor --> RLCoreEntity
    RLCoreActor --> RLCoreActions
    RLCoreEntity --> RLCoreTypes
    RLCoreSpawner --> RLCoreEntity
    RLCoreSpawner --> RLCoreActor
    RLCoreSpawner --> RLCoreTypes
    RLCoreMap --> RLCoreTypes
    RLCoreMap --> RLUtils
    RLCoreState --> RLCoreBackend
    RLCoreState --> RLCoreTypes
    RLCoreInput[rl_core.input]
    UI --> RLCoreInput
    RLCoreInput --> RLCoreActions
    RLCoreInput --> RLCoreTypes
    RLCoreInput --> Raylib
```

**Explanation:**

- Shows the main modules and their dependencies.
- UI depends on both rl_core and Raylib.
- rl_core is composed of several submodules, each with their own dependencies.

---

## 2. Game Loop and Data Flow

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
    Actor -- "references" --> Types
    Entity -- "references" --> Types
    Actions -- "references" --> Types
    State -- "references" --> Types
```

**Explanation:**

- Illustrates the flow of data and control through the main game loop.
- Shows how input is processed, actions are queued, and the backend updates the game state.

---

## 3. Input Handling Flow

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

This structure is modular, testable, and easy to extend. Update this document as the architecture evolves.
