# RL2023 OCaml Roguelike Overview

## Project Description

RL2023 is a roguelike game implementation in OCaml, following the "Complete Roguelike Tutorial" but using OCaml's functional programming paradigm instead of the more traditional procedural approach. The project uses Raylib bindings for OCaml to handle graphics and input.

## Project Goals

1. Create a complete roguelike game in OCaml
2. Explore functional programming patterns for game development
3. Leverage OCaml's type system for safer game logic
4. Implement core roguelike features:
   - Procedural map generation
   - Turn-based gameplay
   - Entity management
   - Combat system
   - FOV and exploration
   - Items and inventory

## Architecture Overview

### Core Components

1. **Backend System**
   - Game state management
   - Entity system
   - Map representation and generation
   - Random number generation
   - Action processing

2. **UI System**
   - Screen management (menu, play, game over)
   - User input handling
   - Event processing

3. **View System**
   - Rendering components
   - Visual effects
   - Screen-specific rendering

4. **Utils**
   - Common utilities
   - Logging
   - Random number generation
   - Mathematical helpers

### Data Flow

1. User input is captured by the main loop
2. Input is translated into game actions
3. Actions are processed by the backend
4. Game state is updated
5. New state is rendered to the screen

## Current Status

The project has implemented:

- Basic game state management
- Simple map generation with walls
- Control mode system for different game states
- Main menu and play screens
- Integration with Raylib for rendering

## Development Roadmap

### Phase 1: Core Systems (Current)

- [x] Project setup
- [x] Basic map generation
- [x] Game state management
- [ ] Entity system
- [ ] Combat system

### Phase 2: Gameplay Features

- [ ] Enhanced map generation with rooms and corridors
- [ ] Field of view
- [ ] Pathfinding
- [ ] AI for enemies
- [ ] Items and inventory

### Phase 3: Polish and Extensions

- [ ] Save/load system
- [ ] Multiple dungeon levels
- [ ] Improved UI
- [ ] Sound effects and music
- [ ] Game progression and victory conditions

## Development Environment

- OCaml compiler
- Dune build system
- Raylib bindings for graphics
- Various OCaml libraries (ppx_deriving, etc.)

## Resources

- [Original Roguelike Tutorial](http://rogueliketutorials.com/)
- [OCaml Documentation](https://ocaml.org/docs)
- [Raylib Bindings for OCaml](https://github.com/tjammer/raylib-ocaml)
