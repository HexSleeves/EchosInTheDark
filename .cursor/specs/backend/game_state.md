# Game State Management Specification

## Overview

This specification defines the game state management system for the RL2025 OCaml Roguelike game. The state management system is responsible for storing, updating, and providing access to the game state, including map, entities, control modes, and randomization.

## Requirements

### Core State Management

- [x] Define a core game state data structure in `backend.ml`
- [x] Implement state initialization with configurable parameters
- [x] Provide read access to game state for observers
- [ ] Implement action-based modification of game state
- [ ] Create state serialization and deserialization for save/load

### Map System

- [x] Generate procedural maps with configurable dimensions and seed
- [x] Provide tile access functions for getting/setting tiles
- [x] Handle map boundaries
- [ ] Implement map modification during gameplay
- [ ] Support multiple map levels/floors

### Control Mode System

- [x] Define different control modes (Normal, WaitInput, Died)
- [ ] Implement proper mode transitions
- [ ] Handle mode-specific input processing
- [ ] Support for mode-specific rendering

### Entity Management

- [ ] Create entity representation in the game state
- [ ] Implement entity creation, modification, and removal
- [ ] Handle entity positioning and movement
- [ ] Support entity interactions and combat

### Random Number Generation

- [x] Implement seeded random number generation
- [x] Support reproducible game states with the same seed
- [ ] Add utilities for common random operations (e.g., dice rolls)

## Acceptance Criteria

1. Game state can be properly initialized with different seeds
2. Map generation produces varied but consistent results for the same seed
3. Game modes function correctly and handle transitions
4. Entities can be created, positioned, and interact with the world
5. Game state can be saved and loaded
6. Random number generation produces consistent results for the same seed

## Technical Design

The game state is managed through the `Backend.t` type, which contains all necessary information:

```ocaml
type t = {
  seed : int;
  debug : bool;
  map : Tilemap.t;
  mode : CtrlMode.t;
  controller_id : int;
  random : Rng.State.t;
}
```

Access to this state is controlled through specific functions that allow:

1. Reading state information via getter functions
2. Modifying state only through validated actions
3. Maintaining consistency of the game state

The system follows an observer pattern where:

- Direct modifications to the state are not allowed
- All changes go through well-defined functions in the Backend module
- State can be observed but not directly modified by other components

## Notes

- Consider adding an event system for state changes
- Map generation could be expanded with different algorithms
- Entity component system might be needed for complex entities
