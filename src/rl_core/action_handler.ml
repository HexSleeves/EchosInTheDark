(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
*)

open Base
open Types
module Log = (val Core_log.make_logger "action_handler" : Logs.LOG)

type action_result = (int, exn) Result.t

let get_entity_stats = function
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
  Base.Option.bind (State.get_entity id backend) ~f:get_entity_stats
  |> Base.Option.value_map ~default:false ~f:(fun stats -> stats.Stats.hp <= 0)

let can_use_stairs_down state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile base.pos (State.get_current_map state)
         |> Dungeon.Tile.equal Dungeon.Tile.Stairs_down)

let can_use_stairs_up state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile base.pos (State.get_current_map state)
         |> Dungeon.Tile.equal Dungeon.Tile.Stairs_up)

(* ////////////////////////////// *)
(* ENTITY MANAGEMENT *)
(* ////////////////////////////// *)

let update_entity_stats (id : Types.Entity.id) (state : State.t)
    (f : Types.Stats.t -> Types.Stats.t) : State.t =
  Entity_manager.update_entity_stats (State.get_entities_manager state) id f
  |> State.set_entities_manager state

let handle_entity_death (id : Types.Entity.id) (state : State.t) : State.t =
  State.get_entity id state
  |> Option.bind ~f:(function
       | Types.Entity.Player _ ->
           Some
             (State.remove_entity id state
             |> State.remove_actor id
             |> State.set_turn_queue
                  (Turn_queue.remove_actor (State.get_turn_queue state) id))
       | Types.Entity.Creature (base, _) ->
           Some
             (State.remove_entity id state
             |> State.get_entities_manager
             |> Entity_manager.spawn_corpse base.pos
             |> State.set_entities_manager state
             |> State.remove_actor base.id
             |> State.set_turn_queue
                  (Turn_queue.remove_actor (State.get_turn_queue state) id))
       | _ -> None)
  |> Option.value ~default:state

let handle_move ~(state : State.t) ~(id : Entity.id) ~(dir : Direction.t)
    ~(handle_action :
       State.t -> Entity.id -> Action.t -> State.t * action_result) :
    State.t * action_result =
  State.get_entity id state
  |> Option.map ~f:(fun entity ->
         let base = Entity.get_base entity in
         let delta = Direction.to_point dir in
         let new_pos = Loc.(base.pos + delta) in

         let dungeon = State.get_current_map state in
         let in_bounds = Dungeon.Tilemap.in_bounds new_pos dungeon in
         let walkable =
           Dungeon.Tile.is_walkable (Dungeon.Tilemap.get_tile new_pos dungeon)
         in

         State.get_blocking_entity_at_pos new_pos state
         |> Option.map ~f:(fun target_entity ->
                get_entity_stats target_entity
                |> Option.map ~f:(fun _ ->
                       handle_action state id
                         (Action.Attack (Entity.get_base target_entity).id))
                |> Option.value
                     ~default:
                       ( state,
                         Error (Failure "Blocked by non-attackable entity") ))
         |> Option.value
              ~default:
                (if in_bounds && walkable then
                   let state = State.move_entity id new_pos state in
                   (state, Ok 100)
                 else
                   (state, Error (Failure "Cannot move here: terrain blocked"))))
  |> Option.value ~default:(state, Error (Failure "Entity not found"))

let rec handle_action (state : State.t) (id : Entity.id) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  | Action.Move dir -> handle_move ~state ~id ~dir ~handle_action
  | Action.StairsUp -> (
      State.get_entity id state
      |> Result.of_option ~error:(Failure "Entity not found")
      |> Result.bind ~f:(fun entity ->
             let tile =
               Dungeon.Tilemap.get_tile (Entity.get_pos entity)
                 (State.get_current_map state)
             in
             if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up then
               Ok (State.transition_to_previous_level state, 0)
             else Error (Failure "Not on stairs up"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.StairsDown -> (
      State.get_entity id state
      |> Result.of_option ~error:(Failure "Entity not found")
      |> Result.bind ~f:(fun entity ->
             State.get_current_map state
             |> Dungeon.Tilemap.get_tile (Entity.get_pos entity)
             |> Dungeon.Tile.equal Dungeon.Tile.Stairs_down
             |> fun is_equal ->
             if is_equal then Ok (State.transition_to_next_level state, 0)
             else Error (Failure "Not on stairs down"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.Attack target_id ->
      State.get_entity id state
      |> Option.bind ~f:(fun attacker ->
             State.get_entity target_id state
             |> Option.bind ~f:(fun defender ->
                    get_entity_stats attacker
                    |> Option.bind ~f:(fun attacker_stats ->
                           get_entity_stats defender
                           |> Option.map ~f:(fun defender_stats ->
                                  ( attacker,
                                    defender,
                                    attacker_stats,
                                    defender_stats )))))
      |> Option.map
           ~f:(fun (_attacker, _defender, attacker_stats, defender_stats) ->
             let damage = calculate_damage ~attacker_stats ~defender_stats in

             let state =
               update_entity_stats target_id state (fun stats ->
                   { stats with hp = stats.hp - damage })
             in

             let state =
               if is_entity_dead target_id state then
                 handle_entity_death target_id state
               else state
             in

             (state, Ok 100))
      |> Option.value
           ~default:
             ( state,
               Error (Failure "Attacker or defender not found or missing stats")
             )
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup _ -> (state, Error (Failure "Pickup not implemented yet"))
  | Action.Drop _ -> (state, Error (Failure "Drop not implemented yet"))
