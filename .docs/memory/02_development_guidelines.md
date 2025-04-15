# Development Guidelines

## 1. Code Organization

### Entity System Usage

- Always use the EntityManager for game object management
- Use the specialized spawn functions (e.g., `spawn_player`, `spawn_creature`, `spawn_item`) from `spawner.ml` for entity creation
- Follow the established entity patterns
- Example:

```ocaml
open Backend.Spawner

let mgr = EntityManager.create ()
let () = spawn_player mgr ~pos:(0,0) ~direction:North
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

### Documentation

- Document public interfaces
- Include examples for complex functionality
- Explain non-obvious design decisions
- Keep README.md updated

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

### Performance Considerations

- Be mindful of memory usage
- Consider performance implications
- Use appropriate data structures

## 5. Contributing

- Fork the repository
- Create feature branches
- Submit pull requests
- Follow the project's coding standards
