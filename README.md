# rl2023_ocaml

This is an experimental project for learning OCaml, inspired by a love of game design.
## Guideline: Use of Entity and EntityManager Abstractions

**All new game logic and feature implementations should use the `entity` and `EntityManager` abstractions.**

These abstractions provide:
- **Extensibility:** Easily add new entity types or behaviors.
- **Maintainability:** Centralizes entity logic, reducing code duplication and simplifying updates.
- **Consistency:** Ensures a uniform approach to managing game objects across the codebase.

See [`src/backend/types.ml`](src/backend/types.ml) for canonical definitions and constructors.

**Minimal Example:**

```ocaml
open Backend.Types

let mgr = EntityManager.create ()
let player = make_player ~id:1 ~pos:(0,0) ~direction:North ~faction:0
let () = EntityManager.add mgr player
let found = EntityManager.find mgr 1
```

Contributors are encouraged to follow this pattern for all new features and logic. For more details and advanced usage, see the documentation and type definitions in `src/backend/types.ml`.


## Installation and Running

To install dependencies and run the game, you will need [opam](https://opam.ocaml.org/) and [dune](https://dune.build/).

1. Install dependencies:

   ```sh
   opam install . --deps-only
   ```

2. Build the project:

   ```sh
   dune build
   ```

3. Run the game:

   ```sh
   dune exec rl2023
   ```

## Screenshots / Videos

<div align="center">
<table>
<tr>
<td width="400px" align="center">
  <img src="media/base_screen.png" alt="Base Screen" width="400px"/><br/>
  <em>Base Screen - Main Menu</em>
</td>
<td width="400px" align="center">
  <img src="media/play.gif" alt="Gameplay" width="400px"/><br/>
  <em>Gameplay Demo</em>
</td>
</tr>
</table>
</div>

_To add a screenshot, place the image in the `media/` directory and add it to the grid above._

## Contributing

Contributions are welcome! If you would like to contribute, please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
