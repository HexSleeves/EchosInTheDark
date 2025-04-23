# Level Transitions Implementation Task Plan

## Current State Analysis

- We have a `MultiLevelState` module with a collection of maps for different levels
- Maps include stairs up and stairs down locations
- Actions for using stairs (StairsUp, StairsDown) are defined and validated
- Backend handles the action but doesn't currently change levels
- The mapgen module generates maps with stairs positioned correctly

## Required Tasks

### 1. Extend MultiLevelState Module (src/rl_core/state.ml)

- [ ] Add functions to navigate between levels:
  - `go_to_next_level : t -> t`
  - `go_to_previous_level : t -> t`
  - `can_go_to_next_level : t -> bool`
  - `can_go_to_previous_level : t -> bool`
- [ ] Add validation functions for level boundaries
- [ ] Add helper function to initialize levels if not already created
- [ ] Add function to get the current map from the MultiLevelState

### 2. Implement Entity State Preservation

- [ ] Modify MultiLevelState to store entity states per level
  - Add `entities_by_level` field to store EntityManager state for each level
  - Add `actor_manager_by_level` field to store Actor_manager state for each level
  - Add `turn_queue_by_level` field to store Turn_queue state for each level
- [ ] Add functions to save current level state before transition
- [ ] Add functions to restore level state after transition
- [ ] Ensure we handle the player entity specially during transitions

### 3. Update Backend Module (src/rl_core/backend.ml)

- [ ] Add functions to handle level transitions:
  - `transition_to_next_level : t -> MultiLevelState.t -> (t * MultiLevelState.t)`
  - `transition_to_previous_level : t -> MultiLevelState.t -> (t * MultiLevelState.t)`
- [ ] Modify StairsUp/StairsDown action handlers to use these functions
- [ ] Ensure backend state is properly saved and restored during transitions

### 4. Player Positioning

- [ ] Implement logic to position the player at the appropriate stairs when transitioning
  - When going up, position at stairs down in previous level
  - When going down, position at stairs up in next level
- [ ] Handle edge cases for first/last levels
- [ ] Ensure player entity is properly transferred between levels

### 5. Game State Integration

- [ ] Update game loop to handle level transitions properly
- [ ] Ensure the game state maintains consistency during transitions
- [ ] Add necessary interface functions to update the UI when transitions occur

### 6. Testing

- [ ] Test level transitions in both directions
- [ ] Verify entity state preservation
- [ ] Test edge cases (first level, last level)
- [ ] Ensure player positioning is correct after transitions

## Implementation Details

### MultiLevelState Extensions

```ocaml
module MultiLevelState = struct
  type t = {
    current_level : int;
    total_levels : int;
    player_has_amulet : bool;
    maps : (Base.int, Map.Tilemap.t) Base.Hashtbl.t;
    entities_by_level : (Base.int, Entity_manager.t) Base.Hashtbl.t;
    actor_manager_by_level : (Base.int, Actor_manager.t) Base.Hashtbl.t;
    turn_queue_by_level : (Base.int, Turn_queue.t) Base.Hashtbl.t;
  }

  (* Create a new MultiLevelState *)
  let create ~total_levels ~config =
    let maps = Base.Hashtbl.create (module Base.Int) in
    let entities_by_level = Base.Hashtbl.create (module Base.Int) in
    let actor_manager_by_level = Base.Hashtbl.create (module Base.Int) in
    let turn_queue_by_level = Base.Hashtbl.create (module Base.Int) in

    (* Generate first level map *)
    let first_map = Mapgen.Generator.generate ~config ~level:1 ~total_levels in
    Base.Hashtbl.set maps ~key:1 ~data:first_map;

    {
      current_level = 1;
      total_levels;
      player_has_amulet = false;
      maps;
      entities_by_level;
      actor_manager_by_level;
      turn_queue_by_level;
    }

  (* Get the current map *)
  let get_current_map t =
    Base.Hashtbl.find_exn t.maps t.current_level

  (* Navigation validation functions *)
  let can_go_to_previous_level t = t.current_level > 1

  let can_go_to_next_level t = t.current_level < t.total_levels

  (* Ensure the target level exists in the maps table *)
  let ensure_level_exists t level ~config =
    if not (Base.Hashtbl.mem t.maps level) then
      let new_map = Mapgen.Generator.generate ~config ~level ~total_levels:t.total_levels in
      Base.Hashtbl.set t.maps ~key:level ~data:new_map

  (* Level navigation functions *)
  let go_to_previous_level t ~config =
    if can_go_to_previous_level t then (
      let prev_level = t.current_level - 1 in
      ensure_level_exists t prev_level ~config;
      { t with current_level = prev_level }
    ) else
      t

  let go_to_next_level t ~config =
    if can_go_to_next_level t then (
      let next_level = t.current_level + 1 in
      ensure_level_exists t next_level ~config;
      { t with current_level = next_level }
    ) else
      t

  (* Entity state preservation functions *)
  let save_level_state t level ~entities ~actor_manager ~turn_queue =
    Base.Hashtbl.set t.entities_by_level ~key:level ~data:(Entity_manager.copy entities);
    Base.Hashtbl.set t.actor_manager_by_level ~key:level ~data:(Actor_manager.copy actor_manager);
    Base.Hashtbl.set t.turn_queue_by_level ~key:level ~data:(Turn_queue.copy turn_queue);
    t

  let load_level_state t level ~entities ~actor_manager ~turn_queue =
    match Base.Hashtbl.find t.entities_by_level level with
    | Some saved_entities ->
        Entity_manager.restore entities saved_entities;
        Actor_manager.restore actor_manager (Base.Hashtbl.find_exn t.actor_manager_by_level level);
        Turn_queue.restore turn_queue (Base.Hashtbl.find_exn t.turn_queue_by_level level);
        t
    | None ->
        (* New level, nothing to restore *)
        t
end
```

### Backend Integration

```ocaml
(* In backend.ml *)
let transition_to_next_level backend multi_level ~config =
  (* Save current level state *)
  let multi_level =
    MultiLevelState.save_level_state multi_level multi_level.current_level
      ~entities:backend.entities
      ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Go to next level *)
  let multi_level = MultiLevelState.go_to_next_level multi_level ~config in

  (* Get new map *)
  let new_map = MultiLevelState.get_current_map multi_level in

  (* Either load existing level state or initialize new level *)
  let multi_level =
    MultiLevelState.load_level_state multi_level multi_level.current_level
      ~entities:backend.entities
      ~actor_manager:backend.actor_manager
      ~turn_queue:backend.turn_queue
  in

  (* Position player at stairs_up in new level *)
  let player = get_player backend in
  match new_map.stairs_up with
  | Some stairs_pos ->
      move_entity backend player.id stairs_pos;
      ({ backend with map = new_map }, multi_level)
  | None ->
      (* Shouldn't happen since we always have stairs up except on level 1 *)
      ({ backend with map = new_map }, multi_level)

let transition_to_previous_level backend multi_level ~config =
  (* Similar implementation as transition_to_next_level but for previous level *)
  (* Position player at stairs_down in previous level *)

(* Update the action handler to integrate with game_state *)
let handle_action (game_state : game_state) (id : Types.id)
    (action : Action.action_type) : (game_state, exn) Result.t =
  match action with
  | StairsDown ->
      (match can_use_stairs_down game_state id with
      | true ->
          let backend, multi_level =
            transition_to_next_level game_state.backend game_state.multi_level ~config
          in
          Ok { backend; multi_level }
      | false ->
          Error (Failure "Cannot use stairs down"))

  | StairsUp ->
      (match can_use_stairs_up game_state id with
      | true ->
          let backend, multi_level =
            transition_to_previous_level game_state.backend game_state.multi_level ~config
          in
          Ok { backend; multi_level }
      | false ->
          Error (Failure "Cannot use stairs up"))

  | _ ->
      (* Handle other actions using existing logic *)
      match Actions.handle_action ctx id action with
      | Ok cost -> (* Process action normally *) Ok game_state
      | Error e -> Error e
```

### Additional Requirements

1. We need to add copy and restore functions to the following modules:
   - `Entity_manager`
   - `Actor_manager`
   - `Turn_queue`

2. We need to modify the mapgen to ensure consistent positioning of stairs:
   - When generating a new level, ensure stairs up position corresponds with stairs down from previous level
   - This ensures the player appears in a logical place when transitioning

3. We need to ensure proper game state transitions:
   - The action handler needs to be updated to work with the overall game_state
   - Level transitions should be atomic operations that maintain game consistency
