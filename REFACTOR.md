# RL2023 OCaml Refactor Plan

## Overview

This document tracks the architectural review, refactor plan, and rationale for improvements to the `src/rl_core` directory. It serves as a living reference for ongoing and completed refactor tasks.

---

## 1. Architectural Review & Recommendations

### c. ECS/Event-Driven Patterns

- **Issue:** Entity and actor logic is scattered; systems are not clearly separated.
- **Action:**
  - Define "systems" as modules that operate on entities/components (e.g., `MovementSystem`, `CombatSystem`).
  - Use an event bus for decoupling (simple OCaml variant type + handler list).

### d. Data Structures

- **Issue:** Some code uses inefficient list traversals for lookups.
- **Action:**
  - Use `Map`/`Hashtbl` for all entity/actor lookups. Replace list traversals with direct map access.

---

## 2. Best Practices & Further Progression

- Add property-based and unit tests for state transitions.
- Profile entity/actor lookups; add indices if needed.
- Validate all external inputs.
- Use explicit type annotations and local opens (`let open Base in ...`).
- Document all public functions in `.mli` files.

---

## 5. Task Table

**Current Status:**

- We are actively working on Task #3 (Adopt ECS/event-driven) and continuing to refactor code to use maps for all lookups (Task #4).

| Step | Action | Why/Impact | Status |
|------|--------|------------|--------|
| 3 | Adopt ECS/event-driven | Decouples logic, easier to add features | IN PROGRESS |
| 4 | Use maps for all lookups | Performance, clarity | IN PROGRESS |
| 6 | Document architecture | Onboarding, future-proofing | TODO |
| 7 | Refactor example | Concrete path to improvement | TODO |
| 8 | Directory structure | Discoverability, modularity | TODO |
| 9 | Best practices | Long-term project health | IN PROGRESS |

---

## 6. Next Steps

- Continue modularizing systems and implementing event-driven (ECS) patterns.
- Refactor all entity/actor lookups to use maps instead of lists.
- Update this file as tasks are completed or new issues are discovered.
