# Echoes in the Dark

Welcome to **Echoes in the Dark** — a modern, modular roguelike engine and game demo built in OCaml. This project is all about learning, experimentation, and pushing the boundaries of functional game development.

---

## 🚀 What is Echoes in the Dark?

- **Turn-based, entity-driven roguelike** with a focus on extensibility and clarity.
- **Entity-Component System (ECS):** All game objects are entities with flexible, composable components.
- **Infinite/Procedural World:** Powered by a dynamic chunking system for seamless exploration.
- **Modern OCaml:** Uses the [Base](https://github.com/janestreet/base) library, functional patterns, and Raylib bindings for graphics/input/audio.
- **Modular Architecture:** Clean separation of UI, core logic, resources, and utilities.

---

## 🧩 Architecture & Docs

- **[System Architecture](docs/architecture.md):** High-level overview, major modules, and how everything fits together.
- **[Project Structure](docs/project_structure.md):** Directory/module breakdown, dependency diagrams, and data flow.
- **[Chunking System](docs/chunking_design.md):** How the world is split into 32x32 chunks for infinite/procedural generation.
- **[Workflow & Coding Policies](docs/workflow_policies.md):** How we work, code, and contribute (OCaml functional style, memory files, reviews, etc.).
- **[Story & Lore](docs/story_line.md):** The narrative, world, and monster/item lists.

---

## 🛠️ Getting Started

### Prerequisites

- [OCaml](https://ocaml.org/) (via [opam](https://opam.ocaml.org/))
- [Dune](https://dune.build/)
- [Raylib](https://www.raylib.com/) (and OCaml bindings)

### Installation

```sh
opam install . --deps-only
```

### Build & Run

```sh
dune build
dune exec echoes_dark
```

---

## 🗂️ Project Structure (Quick View)

- `src/` — Main source code (ECS, systems, chunking, UI, etc.)
- `test/` — Tests
- `media/` — Screenshots and assets
- `resources/` — Game resources (fonts, images, prefabs, tiles)
- `docs/` — All project documentation (see above)

See [project_structure.md](docs/project_structure.md) for full details and diagrams.

---

## 👾 Features

- **Entity-Component System:** Flexible, extensible, and easy to hack on.
- **Dynamic Chunking:** Infinite/procedural world, loaded in 32x32 tile chunks around the player.
- **Functional OCaml:** Modern, idiomatic code using Base and best practices.
- **Raylib Integration:** Fast graphics, input, and audio.
- **Clear Docs:** Everything you need to understand, extend, or contribute.

---

## 🧑‍💻 Contributing

We welcome all contributors — whether you're new to OCaml, games, or just want to help!

- **Read the [Workflow & Coding Policies](docs/workflow_policies.md)** before starting.
- Fork the repo, create a feature branch, and open a pull request.
- All code is reviewed for clarity, style, and function.
- Update docs and memory files as you go.
- Be functional, be idiomatic, be kind.

---

## 📸 Screenshots

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

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

---

## 💡 More Info & Help

- For technical details, see [architecture.md](docs/architecture.md) and [chunking_design.md](docs/chunking_design.md).
- For project goals and roadmap, see the memory files in `docs/` and `tasks/`.
- For help or questions, open an issue or discussion!
