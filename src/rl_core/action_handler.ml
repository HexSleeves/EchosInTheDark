(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
*)

open Base
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
  (* Ensure at least 1 damage *)
  max 1 base_damage

let is_entity_dead (id : Types.Entity.id) (backend : State.t) : bool =
  Base.Option.bind (State.get_entity backend id) ~f:get_entity_stats
  |> Base.Option.value_map ~default:false ~f:(fun stats -> stats.Stats.hp <= 0)

let can_use_stairs_down state id =
  State.get_entity state id
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile (State.get_current_map state) base.pos
         |> Dungeon.Tile.equal Dungeon.Tile.Stairs_down)

let can_use_stairs_up state id =
  State.get_entity state id
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile (State.get_current_map state) base.pos
         |> Dungeon.Tile.equal Dungeon.Tile.Stairs_up)

(* ////////////////////////////// *)
(* ENTITY MANAGEMENT *)
(* ////////////////////////////// *)

let update_entity_stats (state : State.t) (id : Types.Entity.id)
    (f : Types.Stats.t -> Types.Stats.t) : State.t =
  Entity_manager.update_entity_stats (State.get_entities_manager state) id f
  |> State.set_entities_manager state

let handle_entity_death (id : Types.Entity.id) (state : State.t) : State.t =
  State.get_entity state id
  |> Base.Option.value_map ~default:state ~f:(fun entity ->
         (* Remove from entity manager *)
         let state = State.remove_entity id state in

         (* Remove from actor manager and turn queue if actor *)
         match entity with
         | Types.Entity.Player _ ->
             let state = State.remove_actor (Entity.get_base entity).id state in
             let turn_queue =
               Turn_queue.remove_actor (State.get_turn_queue state) id
             in
             State.set_turn_queue turn_queue state
         | Types.Entity.Creature (base, _) ->
             (* Add a corpse at the same position *)
             let state =
               State.set_entities_manager state
                 (Entity_manager.spawn_corpse
                    (State.get_entities_manager state)
                    base.pos)
             in
             let state = State.remove_actor base.id state in
             let turn_queue =
               Turn_queue.remove_actor (State.get_turn_queue state) id
             in
             State.set_turn_queue turn_queue state
         | _ -> state)

let rec handle_action (state : State.t) (id : Entity.id) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  | Action.Move dir ->
      State.get_entity state id
      |> Option.value_map ~default:(state, Error (Failure "Entity not found"))
           ~f:(fun entity ->
             let base = Entity.get_base entity in
             let delta = Direction.to_point dir in
             let new_pos = Loc.(base.pos + delta) in
             let in_bounds =
               Dungeon.Tilemap.in_bounds (State.get_current_map state) new_pos
             in
             let walkable =
               Dungeon.Tile.is_walkable
                 (Dungeon.Tilemap.get_tile
                    (State.get_current_map state)
                    new_pos)
             in
             State.get_entity_at_pos state new_pos
             |> Option.value_map
                  ~default:
                    (if in_bounds && walkable then
                       let state = State.move_entity state id new_pos in
                       (state, Ok 100)
                     else
                       ( state,
                         Error (Failure "Cannot move here: terrain blocked") ))
                  ~f:(fun target_entity ->
                    let target_base = Entity.get_base target_entity in
                    get_entity_stats target_entity
                    |> Option.value_map
                         ~default:
                           ( state,
                             Error (Failure "Blocked by non-attackable entity")
                           ) ~f:(fun _ ->
                           handle_action state id (Action.Attack target_base.id))))
  | Action.StairsUp ->
      State.get_entity state id
      |> Option.value_map ~default:(state, Error (Failure "Entity not found"))
           ~f:(fun entity ->
             let base = Entity.get_base entity in
             let tile =
               Dungeon.Tilemap.get_tile (State.get_current_map state) base.pos
             in
             if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up then
               let state, _ = State.transition_to_previous_level state in
               (state, Ok 0)
             else (state, Error (Failure "Not on stairs up")))
  | Action.StairsDown ->
      State.get_entity state id
      |> Option.value_map ~default:(state, Error (Failure "Entity not found"))
           ~f:(fun entity ->
             let base = Entity.get_base entity in
             let tile =
               Dungeon.Tilemap.get_tile (State.get_current_map state) base.pos
             in
             if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down then
               let state, _ = State.transition_to_next_level state in
               (state, Ok 0)
             else (state, Error (Failure "Not on stairs down")))
  | Action.Attack target_id ->
      Option.bind (State.get_entity state id) ~f:(fun attacker ->
          Option.bind (State.get_entity state target_id) ~f:(fun defender ->
              Option.bind (get_entity_stats attacker) ~f:(fun attacker_stats ->
                  Option.bind (get_entity_stats defender)
                    ~f:(fun defender_stats ->
                      Some (attacker, defender, attacker_stats, defender_stats)))))
      |> Option.value_map
           ~default:
             ( state,
               Error (Failure "Attacker or defender not found or missing stats")
             ) ~f:(fun (attacker, defender, attacker_stats, defender_stats) ->
             let damage = calculate_damage ~attacker_stats ~defender_stats in
             let state =
               update_entity_stats state target_id (fun stats ->
                   { stats with hp = stats.hp - damage })
             in
             let state =
               if is_entity_dead target_id state then
                 handle_entity_death target_id state
               else state
             in
             (state, Ok 100))
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup _ -> (state, Error (Failure "Pickup not implemented yet"))
  | Action.Drop _ -> (state, Error (Failure "Drop not implemented yet"))
