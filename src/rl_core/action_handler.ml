(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
*)

open Types

type action_result = (int, exn) Result.t

let get_entity_stats (entity : Entity.t) =
  match entity with
  | Entity.Player (_, { stats }) | Entity.Creature (_, { stats; _ }) ->
      Some stats
  | _ -> None

(* Calculate damage based on attacker and defender stats *)
let calculate_damage ~attacker_stats ~defender_stats =
  let base_damage =
    attacker_stats.Stats.attack - defender_stats.Stats.defense
  in
  let damage = max 1 base_damage in
  (* Ensure at least 1 damage *)
  damage

let is_entity_dead (backend : State.t) (id : Types.Entity.id) : bool =
  match State.get_entity backend id with
  | Some entity -> (
      match get_entity_stats entity with
      | Some stats -> stats.hp <= 0
      | None -> false)
  | None -> false

let can_use_stairs_down state id =
  match State.get_entity state id with
  | None -> false
  | Some entity ->
      let base = Entity.get_base entity in
      let tile = Map.Tilemap.get_tile (State.get_current_map state) base.pos in
      Map.Tile.equal tile Map.Tile.Stairs_down

let can_use_stairs_up state id =
  match State.get_entity state id with
  | None -> false
  | Some entity ->
      let base = Entity.get_base entity in
      let tile = Map.Tilemap.get_tile (State.get_current_map state) base.pos in
      Map.Tile.equal tile Map.Tile.Stairs_up

(* ////////////////////////////// *)
(* ENTITY MANAGEMENT *)
(* ////////////////////////////// *)

let update_entity_stats (state : State.t) (id : Types.Entity.id)
    (f : Types.Stats.t -> Types.Stats.t) : State.t =
  let entities =
    Entity_manager.update_entity_stats (State.get_entities_manager state) id f
  in
  State.set_entities_manager state entities

let handle_entity_death (state : State.t) (id : Types.Entity.id) : State.t =
  let state =
    match State.get_entity state id with
    | Some entity -> (
        (* Remove from entity manager *)
        let state = State.remove_entity state id in

        (* Remove from actor manager and turn queue if actor *)
        match entity with
        | Types.Entity.Player _ | Types.Entity.Creature _ ->
            let state = State.remove_actor state (Entity.get_base entity).id in
            let turn_queue =
              Turn_queue.remove_actor (State.get_turn_queue state) id
            in
            State.set_turn_queue state turn_queue
        | _ -> state)
    | None -> state
  in
  state

let rec handle_action (state : State.t) (id : Entity.id) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  | Action.Move dir -> (
      match State.get_entity state id with
      | None -> (state, Error (Failure "Entity not found"))
      | Some entity -> (
          let base = Entity.get_base entity in
          let delta = Direction.to_point dir in
          let new_pos = Loc.(base.pos + delta) in
          let in_bounds =
            Map.Tilemap.in_bounds (State.get_current_map state) new_pos
          in
          let walkable =
            Map.Tile.is_walkable
              (Map.Tilemap.get_tile (State.get_current_map state) new_pos)
          in
          match State.get_entity_at_pos state new_pos with
          | Some target_entity -> (
              let target_base = Entity.get_base target_entity in
              match get_entity_stats target_entity with
              | Some _ -> handle_action state id (Action.Attack target_base.id)
              | None ->
                  (state, Error (Failure "Blocked by non-attackable entity")))
          | None ->
              if in_bounds && walkable then
                let state = State.move_entity state id new_pos in
                (state, Ok 100)
              else (state, Error (Failure "Cannot move here: terrain blocked")))
      )
  | Action.StairsUp -> (
      match State.get_entity state id with
      | None -> (state, Error (Failure "Entity not found"))
      | Some entity ->
          let base = Entity.get_base entity in
          let tile =
            Map.Tilemap.get_tile (State.get_current_map state) base.pos
          in
          if Map.Tile.equal tile Map.Tile.Stairs_up then
            let state, _ = State.transition_to_previous_level state in
            (state, Ok 0)
          else (state, Error (Failure "Not on stairs up")))
  | Action.StairsDown -> (
      match State.get_entity state id with
      | None -> (state, Error (Failure "Entity not found"))
      | Some entity ->
          let base = Entity.get_base entity in
          let tile =
            Map.Tilemap.get_tile (State.get_current_map state) base.pos
          in
          if Map.Tile.equal tile Map.Tile.Stairs_down then
            let state, _ = State.transition_to_next_level state in
            (state, Ok 0)
          else (state, Error (Failure "Not on stairs down")))
  | Action.Attack target_id -> (
      match (State.get_entity state id, State.get_entity state target_id) with
      | Some attacker, Some defender -> (
          match (get_entity_stats attacker, get_entity_stats defender) with
          | Some attacker_stats, Some defender_stats ->
              let damage = calculate_damage ~attacker_stats ~defender_stats in
              let state =
                update_entity_stats state target_id (fun stats ->
                    { stats with hp = stats.hp - damage })
              in
              let state =
                if is_entity_dead state target_id then
                  handle_entity_death state target_id
                else state
              in
              (state, Ok 100)
          | _ -> (state, Error (Failure "Cannot attack: missing stats")))
      | _ -> (state, Error (Failure "Attacker or defender not found")))
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup _ -> (state, Error (Failure "Pickup not implemented yet"))
  | Action.Drop _ -> (state, Error (Failure "Drop not implemented yet"))
