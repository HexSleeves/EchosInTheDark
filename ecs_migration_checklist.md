# ECS Migration Checklist

## 1. Types

- [x] Redefine `Entity` as just an `entity_id = int` in `types.ml`.
- [x] Remove all sum type variants for entities (Player, Creature, Item, Corpse, etc).
- [x] Add a `Kind` (or Tag) component for entity type tagging.

## 2. Components

- [x] Move all entity data (stats, position, inventory, item data, etc) into component modules.
- [x] Each component should provide `set`, `get`, and `remove` functions indexed by `entity_id`.
- [x] Use `Base.Hashtbl` for component storage.

## 3. Events & Systems

- [x] Refactor all events to pass only `entity_id` (and other IDs as needed), not full entity records.
- [x] In systems, always look up data from components using the ID.
- [x] Remove all pattern matches on entity variants; use Kind/Tag and component lookups instead.

## 4. Entity Creation/Spawning

- [x] When spawning, allocate a new ID and set up all required components for that entity.
- [x] Register the entity's kind/tag in the Kind component.

## 5. Entity Removal

- [x] When removing an entity, remove its ID from all component tables.

## 6. Usage Patterns

- [x] Pass around only IDs in events, systems, and game logic.
- [x] To get data, always use the relevant component's `get` function.
- [x] To mutate data, use the component's `set` function.

## 7. Testing & Validation

- [ ] Test all major game flows (spawning, pickup, drop, combat, etc) to ensure data is correctly stored and retrieved from components.
- [ ] Remove any remaining code that relies on the old entity sum type or direct data storage in entities.

---

**Tip:**

- If you need to know "what kind" of entity something is, use the `Kind` component.
- If you need to know "what data" an entity has, check if the relevant component returns `Some` for its ID.

---

**You now have a true ECS foundation!**
