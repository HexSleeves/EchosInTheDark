# RL2025 OCaml Project Overview

## Project Description

RL2025 is an experimental game development project implemented in OCaml, focusing on learning OCaml through practical game design implementation. The project uses entity-based architecture for game object management.

## Key Features

- Entity-Component System Architecture
- Game Object Management through EntityManager
- 2D Game Environment
- Turn-based Gameplay (based on screenshots)

## Technical Stack

- Language: OCaml
- Build System: Dune 3.9
- Package Manager: OPAM
- License: MIT

## Core Components

1. Entity System
   - Centralized EntityManager
   - Entity abstraction for game objects
   - Flexible entity type system

2. Backend Systems
   - Type definitions in `src/backend/types.ml`
   - Entity management and game logic

3. Project Structure
   - src/: Source code
   - test/: Test files
   - lib/: Library code
   - media/: Game assets and screenshots
   - resources/: Additional resources
   - static/: Static assets

## Development Guidelines

1. All game logic should use the entity and EntityManager abstractions
2. Follow OCaml best practices and coding standards
3. Maintain documentation for new features
4. Use the established entity management patterns for consistency
