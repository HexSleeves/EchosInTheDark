# RL2023 OCaml Refactor Plan

## Overview

This document tracks the architectural review, refactor plan, and rationale for improvements to the `src/rl_core` directory. It serves as a living reference for ongoing and completed refactor tasks.

---

## 1. Architectural Review & Recommendations

### a. Module Boundaries & Interfaces

- **Issue:** Only `state.mli` and `backend.mli` exist; other modules lack interfaces, making boundaries fuzzy.
- **Action:**
  - Create `.mli` files for all major modules (`entity_manager`, `actor_manager`, `turn_queue`, etc.).
  - Restrict direct access to internal data structures. Expose only what's necessary.

### b. File Size & Responsibility

- **Issue:** `state.ml` is a god-object (272 lines), mixing state, entity, actor, and level logic.
- **Action:**
  - Split `state.ml` into smaller modules:
    - `state_types.ml` (types only)
    - `state_entities.ml` (entity logic)
    - `state_actors.ml` (actor logic)
    - `state_levels.ml` (level transitions)

### c. ECS/Event-Driven Patterns

- **Issue:** Entity and actor logic is scattered; systems are not clearly separated.
- **Action:**
  - Define "systems" as modules that operate on entities/components (e.g., `MovementSystem`, `CombatSystem`).
  - Use an event bus for decoupling (simple OCaml variant type + handler list).

### d. Data Structures

- **Issue:** Some code uses inefficient list traversals for lookups.
- **Action:**
  - Use `Map`/`Hashtbl` for all entity/actor lookups. Replace list traversals with direct map access.

### e. Testability

- **Issue:** Large, coupled modules are hard to test.
- **Action:**
  - Write unit tests for all pure functions in managers and state logic.
  - Mock dependencies using interfaces.

### f. Documentation

- **Issue:** No explicit documentation of architectural decisions.
- **Action:**
  - Update `docs/architecture.md` to reflect the new modular structure and rationale.

---

## 2. Concrete Refactor Example

**Before:**

- One large `state.ml` file, all logic mixed.

**After:**

- `state_types.ml`: type definitions
- `state_entities.ml`: entity-related functions
- `state_actors.ml`: actor-related functions
- `state_levels.ml`: level transition logic

---

## 3. Directory Structure Suggestion

**Before:**

- Flat, all core logic in `rl_core/`.

**After:**

- `rl_core/entities/` (entity types, manager)
- `rl_core/actors/` (actor types, manager)
- `rl_core/systems/` (movement, combat, etc.)
- `rl_core/state/` (state types, transitions)
- `rl_core/events/` (event bus, event types)

---

## 4. Best Practices & Further Progression

- Add property-based and unit tests for state transitions.
- Profile entity/actor lookups; add indices if needed.
- Validate all external inputs.
- Use explicit type annotations and local opens (`let open Base in ...`).
- Document all public functions in `.mli` files.

---

## 5. Task Table

| Step | Action | Why/Impact | Status |
|------|--------|------------|--------|
| 1 | Add `.mli` files for all managers | Enforces boundaries, improves testability | TODO |
| 2 | Split `state.ml` by responsibility | Smaller, focused modules, easier to test/extend | TODO |
| 3 | Adopt ECS/event-driven | Decouples logic, easier to add features | TODO |
| 4 | Use maps for all lookups | Performance, clarity | IN PROGRESS |
| 5 | Add unit tests | Reliability, regression safety | TODO |
| 6 | Document architecture | Onboarding, future-proofing | TODO |
| 7 | Refactor example | Concrete path to improvement | TODO |
| 8 | Directory structure | Discoverability, modularity | TODO |
| 9 | Best practices | Long-term project health | IN PROGRESS |

---

## 6. Next Steps

- Prioritize `.mli` creation and `state.ml` split.
- Begin modularizing systems and event handling.
- Update this file as tasks are completed or new issues are discovered.
