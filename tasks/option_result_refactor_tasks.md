# Option/Result Utility Refactor Task List

## src/rl_core/action_handler.ml

- [x] `can_use_stairs_down` and `can_use_stairs_up`: Use Option.value_map instead of explicit match for entity lookup.
- [ ] `handle_action`:
  - [x] `Action.Move`: Use Option.value_map for entity lookup and for get_entity_at_pos.
  - [x] `Action.StairsUp`/`Action.StairsDown`: Use Option.value_map for entity lookup.
  - [x] `Action.Attack`: Use Option.bind or Option.value_map for attacker/defender lookup and stats lookup.

## src/rl_core/turn_system.ml

- [x] `process_actor_event`: Use Option.value_map or Option.bind for entity and actor lookup.

## src/rl_core/entity_manager.ml

- [x] `find_unsafe`: Use Option.value_map or Option.get with error for more idiomatic error handling.
- [x] `find_by_pos`: Use Option.first_some or Option.value_map for fold logic.
- [x] `update`: Already refactored, but review for further pipeline opportunities.

## src/rl_core/actor_manager.ml

- [x] `get_unsafe`: Use Option.value_map or Option.get with error for more idiomatic error handling.
- [x] `update`: Use Option.value_map instead of explicit match.

---

For each function, refactor to use Base.Option or Result utilities and pipeline style where possible. Check for nested matches and replace with chaining or mapping.
