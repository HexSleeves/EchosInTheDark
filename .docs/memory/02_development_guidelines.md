# Development Guidelines

## 1. Code Organization

### Entity System Usage

- Always use the EntityManager for game object management
- Use the specialized spawn functions from the Backend module for entity creation
- Follow the established entity patterns
- Example:

```ocaml
(* Spawn player using Backend function. This handles entity creation,
   actor manager update, and scheduling the first turn. *)
let backend = B.spawn_player ~pos:player_start ~direction:T.Direction.North backend

(* Spawn creature using Backend function. This handles entity/actor creation. *)
let backend = B.spawn_creature backend
  ~pos:(T.Loc.add player_start (T.Loc.make 1 1))
  ~direction:T.Direction.North ~species:"Rat" ~health:10 ~glyph:"r"
  ~name:"Rat" ~actor_id:1 ~description:"A small, brown rodent."
```

### Map and Level Management

- Use the Map_manager module for level transitions and state persistence
- Use the Mapgen.Generator module for procedural map generation
- Handle level transitions through the Backend module's helper functions
- Example:

```ocaml
(* Handle stairs down action *)
match action with
| StairsDown ->
    Core_log.info (fun m -> m "Transitioning to next level");
    let backend, map_manager = transition_to_next_level backend in
    { backend with map_manager }
```

### File Structure

- Keep related functionality together
- Use meaningful module names
- Follow OCaml naming conventions
  - Modules: PascalCase
  - Functions: snake_case
  - Types: snake_case

## 2. Code Style

### OCaml Formatting

- Use .ocamlformat for consistent formatting
- Follow the project's .editorconfig settings
- Keep functions focused and small
- Use meaningful variable names
- Use appropriate comments for complex logic

### Documentation

- Document public interfaces
- Include examples for complex functionality
- Explain non-obvious design decisions
- Keep README.md and memory docs updated

## 3. Development Workflow

### Version Control

- Use meaningful commit messages
- Keep changes focused and atomic
- Follow Git best practices

### Testing

- Write tests for new functionality
- Ensure existing tests pass
- Use the test/ directory structure

## 4. Project Standards

### Code Quality

- Use type annotations for clarity
- Handle errors explicitly
- Avoid unnecessary mutations
- Keep the codebase modular
- Use Result types for error handling

### Performance Considerations

- Be mindful of memory usage
- Consider performance implications
- Use appropriate data structures
- Optimize critical paths

## 5. Game Design Principles

### Turn-Based Mechanics

- All game actions should be processed through the turn system
- Use the Actor system for entities that can take actions
- Queue actions through the Backend module

### Map Generation

- Follow the established patterns for map generation
- Use the farthest-point algorithm for stairs placement
- Ensure proper level transitions

## 6. Contributing

- Fork the repository
- Create feature branches
- Submit pull requests
- Follow the project's coding standards
- Update documentation for new features
