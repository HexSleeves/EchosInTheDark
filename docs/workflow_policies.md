# OCaml Project Workflow & Coding Policies

This document formalizes the workflow, coding style, and contribution policies for Echoes in the Dark. All contributors and LLMs must follow these guidelines to ensure code quality, maintainability, and idiomatic OCaml practices.

---

## 1. Build & Test Discipline

- **Always run `dune build` after each code change.**
  - Catch errors early, prevent broken builds, and keep the project stable.
- **Run tests before pushing.**
  - Use `dune runtest` if tests exist. Add tests for new features/bugfixes.

---

## 2. OCaml Functional & Idiomatic Style

- **Use the [Base](https://github.com/janestreet/base) library** for standard types and utilities.
- **Error handling:** Use `Option.t` and `Result.t` instead of exceptions.
- **Functional patterns:**
  - Use combinators like `Option.bind`, `Option.value`, `Result.map`, etc.
  - Prefer pure functions and avoid side effects except for IO.
- **Explicit imports:** Open modules locally (e.g., `let open Base in ...`).
- **Explicit types:** Add type annotations for public functions and module interfaces.
- **Consistent naming:**
  - `snake_case` for values/functions
  - `PascalCase` for types/modules
- **Short, focused functions:** Each function should do one thing well.
- **No Pervasives:** Avoid OCaml's shadowed standard library unless necessary.

**Examples:**

```ocaml
let sum_positive (xs : int list) : int =
  List.filter xs ~f:(fun x -> x > 0)
  |> List.fold ~init:0 ~f:(+)

let divide x y =
  if y = 0 then Error "Division by zero"
  else Ok (x / y)

let find_and_double tbl key =
  Hashtbl.find tbl key
  |> Option.bind ~f:(fun v -> Some (v * 2))
```

---

## 3. Code Review & Documentation

- **All PRs must be reviewed** by at least one other contributor.
- **Document major modules, types, and functions.**
- **Update docs** (in `docs/`) when architecture, workflow, or major features change.
- **Cross-link**: Reference related docs (see [architecture.md](architecture.md), [project_structure.md](project_structure.md)).

---

## 4. Memory/Core Files Workflow

- **Project memory files** (see [Memory Files Structure](architecture.md)) must be kept up to date:
  - `docs/architecture.md`: System/component relationships
  - `docs/project_structure.md`: Directory/module structure
  - `docs/chunking_design.md`: Chunking system design
  - `docs/story_line.md`: Narrative and world design
  - `tasks/active_context.md`, `tasks/tasks_plan.md`: Current work focus and backlog
- **Update memory files** after significant changes, discoveries, or fixes.
- **Log errors/lessons** in `.cursor/rules/error-documentation.mdc` and `.cursor/rules/lessons-learned.mdc`.

---

## 5. Contributing & Onboarding

- **Fork, branch, and PR:** Standard GitHub workflow.
- **Follow these policies** for all code, docs, and reviews.
- **Ask for clarification** if requirements are unclear.
- **Be functional, be idiomatic, be kind.**

---

*For more, see [architecture.md](architecture.md), [project_structure.md](project_structure.md), [chunking_design.md](chunking_design.md).*
