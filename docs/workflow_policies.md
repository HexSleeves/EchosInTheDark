# OCaml Project Workflow Policies

This document formalizes key workflow policies for this project. All contributors and LLMs should follow these guidelines to ensure code quality, maintainability, and idiomatic OCaml practices.

---

## 1. Always Run `dune build` After Each Code Change

**Policy:**
After every code change, you must run `dune build` to verify that the project builds successfully.

**Rationale:**
Running the build immediately after changes ensures that errors are caught early, prevents broken builds from being committed, and maintains project stability.

**Example:**
```sh
# After editing any .ml or .mli file
dune build
```

---

## 2. Always Use the `base` Library in New Code and Refactoring

**Policy:**
All new code and refactoring must use the [`base`](https://github.com/janestreet/base) library for standard utilities, data structures, and functional patterns.

**Rationale:**
`base` provides a modern, consistent, and well-maintained standard library for OCaml. It encourages best practices and improves code readability and reliability.

**Example:**
```ocaml
open Base

let numbers = [1; 2; 3]
let incremented = List.map ~f:(fun x -> x + 1) numbers
```

---

## 3. Prefer Functional and OCaml-Idiomatic Patterns

**Policy:**
Always use the most functional and OCaml-idiomatic approach to problem solving. This includes, but is not limited to, using types and combinators such as `Result.t`, `Option.value`, `Option.bind`, and other patterns from the OCaml ecosystem.

**Rationale:**
Functional and idiomatic code is more robust, composable, and easier to reason about. Leveraging OCaml’s type system and functional patterns reduces bugs and improves maintainability.

**Examples:**

- **Using `Result.t` for error handling:**
  ```ocaml
  let divide x y =
    if y = 0 then Error "Division by zero"
    else Ok (x / y)
  ```

- **Chaining with `Option.bind`:**
  ```ocaml
  let find_and_double tbl key =
    Hashtbl.find tbl key
    |> Option.bind ~f:(fun v -> Some (v * 2))
  ```

- **Providing defaults with `Option.value`:**
  ```ocaml
  let port = Option.value ~default:8080 maybe_port
  ```

---

**Adherence to these policies is required for all code contributions.**
