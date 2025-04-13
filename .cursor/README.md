# RL2023 OCaml Roguelike Development

Welcome to the AI-assisted development environment for the RL2023 OCaml Roguelike project. This environment helps manage project specifications, tasks, knowledge, and documentation.

## Project Overview

The RL2023 OCaml Roguelike is an implementation of a roguelike game using OCaml and Raylib, following the "Complete Roguelike Tutorial" but with a functional programming approach. For a complete project description, see [Project Overview](.cursor/docs/project_overview.md).

## Directory Structure

### `/specs`

Contains project specifications:

- [Game State Management](specs/backend/game_state.md)
- [Tilemap System](specs/backend/tilemap.md)
- [Specifications Index](SPECS.md)

### `/tasks`

Contains development tasks:

- [Entity System Implementation](tasks/TASK-001.md)
- [Tasks Index](TASKS.md)

### `/learnings`

Contains knowledge and learnings:

- [OCaml for Roguelike Development](learnings/LEARN-001.md)
- [Learnings Index](LEARNINGS.md)

### `/docs`

Contains project documentation:

- [Project Overview](docs/project_overview.md)

### `/output`

Contains generated reports and analysis:

- [Codebase Analysis](output/codebase_analysis.md)

## Development Workflow

### Working with Specifications

1. View existing specifications in the `/specs` directory
2. Create new specifications when needed:
   - Define clear requirements
   - Use checkboxes for tracking completion
   - Link to related specifications

### Working with Tasks

1. View current tasks in the `/tasks` directory
2. Create new tasks when new work is needed:
   - Link to relevant specifications
   - Define clear acceptance criteria
   - Update task status as work progresses

### Capturing Knowledge

1. Review existing learnings in the `/learnings` directory
2. Create new learning documents when discovering useful information:
   - Document patterns, challenges, and solutions
   - Use code examples when helpful
   - Link to related project components

## Getting Started

1. Review the [Project Overview](docs/project_overview.md) to understand the project goals and architecture
2. Look at the [Specifications Index](SPECS.md) to see what components are defined
3. Check the [Tasks Index](TASKS.md) to see current and planned work
4. Review [OCaml for Roguelike Development](learnings/LEARN-001.md) to understand the programming approach

## Contribution Guidelines

1. Implement against specifications
2. Create tasks for unplanned work
3. Document learnings and insights
4. Keep indices updated
5. Maintain code quality with:
   - Clear type definitions
   - Comprehensive docstrings
   - Unit tests for key functions

## Building and Running

To build the project:

```bash
dune build
```

To run the game:

```bash
dune exec rl2023
```

## Additional Resources

- [OCaml Documentation](https://ocaml.org/docs)
- [Raylib Bindings for OCaml](https://github.com/tjammer/raylib-ocaml)
- [Original Roguelike Tutorial](http://rogueliketutorials.com/)
