(* action_handler.ml
   This module interprets Actions as state transitions.
   All state queries/updates go through the State API.
*)

open Base
open Rl_types
open Events.Event_bus
open Components
module Log = (val Core_log.make_logger "action_handler" : Logs.LOG)

type action_result = (int, exn) Result.t

let is_entity_dead (id : int) : bool =
  Stats.get id
  |> Base.Option.value_map ~default:false ~f:(fun stats ->
         Stats.Stats_data.get_hp stats <= 0)

let rec handle_action (state : State.t) (entity_id : int) (action : Action.t) :
    State.t * action_result =
  match action with
  | Action.Wait -> (state, Ok 100)
  | Action.Move dir -> (
      let new_state, move_result =
        Movement_system.try_move_entity ~state ~entity_id ~dir
      in
      match move_result with
      | Moved -> (new_state, Ok 100)
      | Blocked_by_entity { target_id } ->
          handle_action new_state entity_id (Action.Attack target_id)
      | Blocked_by_terrain ->
          (new_state, Error (Failure "Cannot move here: terrain blocked")))
  (* | Action.Move dir -> handle_move ~state ~entity_id ~dir ~handle_action *)
  | Action.StairsUp -> (publish (StairsUp { entity_id }) state, Ok 0)
  | Action.StairsDown -> (publish (StairsDown { entity_id }) state, Ok 0)
  | Action.Attack target_id -> (
      let attacker_stats = Stats.get entity_id in
      let defender_stats = Stats.get target_id in
      match (attacker_stats, defender_stats) with
      | Some _, Some _ ->
          ( publish
              (EntityAttacked
                 { attacker_id = entity_id; defender_id = target_id })
              state,
            Ok 100 )
      | _ ->
          ( state,
            Error (Failure "Attacker or defender not found or missing stats") ))
  | Action.Interact _ -> (state, Error (Failure "Interact not implemented yet"))
  | Action.Pickup item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          ( publish (ItemPickedUp { player_id = entity_id; item_id }) state,
            Ok 100 )
      | _ -> (state, Error (Failure "Pickup failed: invalid entity")))
  | Action.Drop item_id -> (
      match Kind.get entity_id with
      | Some Kind.Player ->
          ( publish (ItemDropped { player_id = entity_id; item_id }) state,
            Ok 100 )
      | _ -> (state, Error (Failure "Drop failed: invalid entity")))
