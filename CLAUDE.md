# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Build project: `dune build`
- Run application: `dune exec echoes_dark`
- Run tests: `dune runtest`
- Run specific test: `dune exec test/echoes_dark.exe`

## Code Style Guidelines
- **Modules**: Snake_case, properly namespaced (core, ui, utils, loader)
- **Functions**: Snake_case with labeled arguments
- **Types**: Use module signatures (.mli) for interfaces, prefer immutable data structures
- **Formatting**: Follow OCaml conventional style
- **Error handling**: Use Option types for potential missing values, exceptions for errors
- **Imports**: Organize by functionality, prefer qualified imports
- **Documentation**: Document module interfaces in .mli files
- **Functional style**: Use pipeline operator (|>), pattern matching, and immutable data

## Project Structure
- Core game logic: src/core
- User interface: src/ui
- Utilities: src/utils
- Resource loading: src/loader

Prefer functional programming patterns with immutable data and explicit state passing.
