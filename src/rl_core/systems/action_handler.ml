(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
*)

open Base
open Types
open Entities
open Events.Event_bus
module Log = (val Core_log.make_logger "action_handler" : Logs.LOG)

type action_result = (int, exn) Result.t

let is_entity_dead (id : Types.Entity.id) : bool =
  Components.Stats.get id
  |> Base.Option.value_map ~default:false ~f:(fun stats -> stats.Stats.hp <= 0)

let can_use_stairs_down state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         match State.get_current_map state with
         | Some dungeon -> (
             match
               Dungeon.Tilemap.get_tile
                 (Components.Position.get_exn base.id)
                 dungeon
             with
             | Some tile -> Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down
             | None -> false)
         | None -> false)

let can_use_stairs_up state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         match State.get_current_map state with
         | Some dungeon -> (
             match
               Dungeon.Tilemap.get_tile
                 (Components.Position.get_exn base.id)
                 dungeon
             with
             | Some tile -> Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up
             | None -> false)
         | None -> false)

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
           Logs.info (fun m -> m "Removing corpse for entity %d" id);

           Some
             (State.remove_entity id state
             |> State.spawn_corpse_entity
                  ~pos:(Components.Position.get_exn base.id)
             |> State.remove_actor base.id
             |> State.set_turn_queue
                  (Turn_queue.remove_actor (State.get_turn_queue state) id))
       | _ -> None)
  |> Option.value ~default:state

let handle_move ~(state : State.t) ~(id : Entity.id) ~(dir : Direction.t)
    ~handle_action : State.t * action_result =
  State.get_entity id state
  |> Option.map ~f:(fun entity ->
         let base = Entity.get_base entity in
         let delta = Direction.to_point dir in
         let pos = Components.Position.get_exn base.id in
         let new_pos = Loc.(pos + delta) in

         match State.get_current_map state with
         | Some dungeon ->
             let in_bounds = Dungeon.Tilemap.in_bounds new_pos dungeon in
             let walkable =
               match Dungeon.Tilemap.get_tile new_pos dungeon with
               | Some tile -> Dungeon.Tile.is_walkable tile
               | None -> false
             in
             State.get_blocking_entity_at_pos new_pos state
             |> Option.map ~f:(fun target_entity ->
                    Components.Stats.get id
                    |> Option.map ~f:(fun _ ->
                           handle_action state id
                             (Action.Attack (Entity.get_base target_entity).id))
                    |> Option.value
                         ~default:
                           ( state,
                             Error (Failure "Blocked by non-attackable entity")
                           ))
             |> Option.value
                  ~default:
                    (if in_bounds && walkable then
                       let state =
                         Movement_system.move_entity ~id ~to_pos:new_pos state
                       in
                       (state, Ok 100)
                     else
                       ( state,
                         Error (Failure "Cannot move here: terrain blocked") ))
         | None -> (state, Error (Failure "No dungeon map loaded")))
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
             match State.get_current_map state with
             | Some dungeon -> (
                 match
                   Dungeon.Tilemap.get_tile
                     (Components.Position.get_exn (Entity.get_base entity).id)
                     dungeon
                 with
                 | Some tile ->
                     if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up then
                       Ok (State.transition_to_previous_level state, -1)
                     else Error (Failure "Not on stairs up")
                 | None -> Error (Failure "Invalid tile position"))
             | None -> Error (Failure "No dungeon map loaded"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.StairsDown -> (
      State.get_entity id state
      |> Result.of_option ~error:(Failure "Entity not found")
      |> Result.bind ~f:(fun entity ->
             match State.get_current_map state with
             | Some dungeon -> (
                 match
                   Dungeon.Tilemap.get_tile
                     (Components.Position.get_exn (Entity.get_base entity).id)
                     dungeon
                 with
                 | Some tile ->
                     if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_down then
                       Ok (State.transition_to_next_level state, -1)
                     else Error (Failure "Not on stairs down")
                 | None -> Error (Failure "Invalid tile position"))
             | None -> Error (Failure "No dungeon map loaded"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.Attack target_id ->
      State.get_entity id state
      |> Option.bind ~f:(fun _attacker ->
             State.get_entity target_id state
             |> Option.map ~f:(fun _defender -> ()))
      |> Option.map ~f:(fun () ->
             publish
               (EntityAttacked { attacker_id = id; defender_id = target_id });
             (state, Ok 100))
      |> Option.value
           ~default:
             ( state,
               Error (Failure "Attacker or defender not found or missing stats")
             )
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup _ -> (state, Error (Failure "Pickup not implemented yet"))
  | Action.Drop _ -> (state, Error (Failure "Drop not implemented yet"))
