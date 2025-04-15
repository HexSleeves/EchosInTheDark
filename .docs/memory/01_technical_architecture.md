# Technical Architecture

## Core Architecture Components

### 1. Entity System

```ocaml
(* Core abstractions *)
EntityManager: Manages game entities
Entity: Base type for all game objects
```

### 2. Directory Structure

```
src/
  ├── backend/       # Core game logic and types
  │   └── types.ml   # Entity and type definitions
  ├── frontend/      # UI and rendering
  └── game/          # Game-specific logic

test/               # Test suite
lib/                # Shared libraries
resources/          # Game resources
static/            # Static assets
media/             # Media assets and screenshots
```

### 3. Key Abstractions

#### Entity Management

- **EntityManager**: Central manager for all game entities
  - Entity creation
  - Entity lifecycle management
  - Entity queries and updates

#### Game Objects

- **Player Entity**: Represents the player character
  - Position tracking
  - Direction handling
  - Faction management

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

- Core OCaml libraries
- Development tools:
  - dune (build system)
  - ocamlformat (code formatting)
  - VSCode integration
