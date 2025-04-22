# RL2025 OCaml Project Overview

## Project Description

RL2025 is an experimental roguelike game development project implemented in OCaml, focusing on learning OCaml through practical game design implementation. The project uses entity-based architecture for game object management and features procedural dungeon generation with multiple levels.

## Key Features

- Entity-Component System Architecture
- Game Object Management through EntityManager
- 2D Turn-based Roguelike Gameplay
- Procedural Map Generation using Cellular Automata
- Multi-level Dungeon with Level Transitions
- Raylib Integration for Graphics

## Technical Stack

- Language: OCaml
- Build System: Dune 3.9
- Package Manager: OPAM
- Graphics: Raylib (via OCaml bindings)
- License: MIT

## Core Components

1. Entity System
   - Centralized EntityManager
   - Entity abstraction for game objects
   - Flexible entity type system
   - Actor system for turn-based gameplay

2. Map Generation
   - Procedural generation using cellular automata
   - Multi-level dungeon with stairs
   - Level state persistence for backtracking

3. Game Logic
   - Turn-based system with action handling
   - Player and creature movement
   - Level transitions (ascending/descending stairs)

4. UI and Rendering
   - Raylib-based rendering
   - ASCII-style graphics
   - Game state visualization

5. Project Structure
   - src/rl_core/: Core game logic and types
   - src/rl_ui/: UI and rendering
   - src/rl_utils/: Utility functions
   - src/bin/: Main executable
   - test/: Test files
   - media/: Game assets and screenshots
   - resources/: Additional resources
   - static/: Static assets

## Development Guidelines

1. All game logic should use the entity and EntityManager abstractions
2. Use the specialized spawn functions for entity creation
3. Follow OCaml best practices and coding standards
4. Maintain documentation for new features
5. Use the established entity management patterns for consistency
