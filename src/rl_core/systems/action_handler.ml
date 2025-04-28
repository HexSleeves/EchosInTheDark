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

(* Calculate damage based on attacker and defender stats *)
let calculate_damage ~attacker_stats ~defender_stats =
  let base_damage =
    attacker_stats.Stats.attack - defender_stats.Stats.defense
  in
  (* Ensure at least 1 damage *)
  max 1 base_damage

let is_entity_dead (id : Types.Entity.id) : bool =
  Components.Stats.get id
  |> Base.Option.value_map ~default:false ~f:(fun stats -> stats.Stats.hp <= 0)

let can_use_stairs_down state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile
           (Components.Position.get_exn base.id)
           (State.get_current_map state)
         |> Dungeon.Tile.equal Dungeon.Tile.Stairs_down)

let can_use_stairs_up state id =
  State.get_entity id state
  |> Base.Option.value_map ~default:false ~f:(fun entity ->
         let base = Entity.get_base entity in
         Dungeon.Tilemap.get_tile
           (Components.Position.get_exn base.id)
           (State.get_current_map state)
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
           Logs.info (fun m -> m "Removing corpse for entity %d" id);

           Some
             (State.remove_entity id state
             |> State.get_entities_manager
             |> Spawner.spawn_corpse ~pos:(Components.Position.get_exn base.id)
             |> State.set_entities_manager state
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

         let dungeon = State.get_current_map state in
         let in_bounds = Dungeon.Tilemap.in_bounds new_pos dungeon in
         let walkable =
           Dungeon.Tile.is_walkable (Dungeon.Tilemap.get_tile new_pos dungeon)
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
                         Error (Failure "Blocked by non-attackable entity") ))
         |> Option.value
              ~default:
                (if in_bounds && walkable then
                   let state =
                     Movement_system.move_entity ~id ~to_pos:new_pos state
                   in
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
               Dungeon.Tilemap.get_tile
                 (Components.Position.get_exn (Entity.get_base entity).id)
                 (State.get_current_map state)
             in
             if Dungeon.Tile.equal tile Dungeon.Tile.Stairs_up then
               Ok (State.transition_to_previous_level state, -1)
             else Error (Failure "Not on stairs up"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.StairsDown -> (
      State.get_entity id state
      |> Result.of_option ~error:(Failure "Entity not found")
      |> Result.bind ~f:(fun entity ->
             State.get_current_map state
             |> Dungeon.Tilemap.get_tile
                  (Components.Position.get_exn (Entity.get_base entity).id)
             |> Dungeon.Tile.equal Dungeon.Tile.Stairs_down
             |> fun is_equal ->
             if is_equal then Ok (State.transition_to_next_level state, -1)
             else Error (Failure "Not on stairs down"))
      |> function
      | Ok (state, time) -> (state, Ok time)
      | Error e -> (state, Error e))
  | Action.Attack target_id ->
      State.get_entity id state
      |> Option.bind ~f:(fun attacker ->
             State.get_entity target_id state
             |> Option.bind ~f:(fun defender ->
                    Components.Stats.get id
                    |> Option.bind ~f:(fun attacker_stats ->
                           Components.Stats.get target_id
                           |> Option.map ~f:(fun defender_stats ->
                                  ( attacker,
                                    defender,
                                    attacker_stats,
                                    defender_stats )))))
      |> Option.map
           ~f:(fun (_attacker, _defender, attacker_stats, defender_stats) ->
             let damage = calculate_damage ~attacker_stats ~defender_stats in

             publish
               (EntityAttacked
                  { attacker_id = id; defender_id = target_id; damage });

             let state =
               update_entity_stats target_id state (fun stats ->
                   { stats with hp = stats.hp - damage })
             in

             let state =
               match is_entity_dead target_id with
               | true -> handle_entity_death target_id state
               | false -> state
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
