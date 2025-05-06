(* Effect Examples

   This module provides examples of how to use the effect handlers
   defined in effect_handlers.ml.
*)

open Base
open Rl_types
open Effect_handlers

(* Example 1: Simple state management *)
let example_state_management (initial_state : State_types.t) : State_types.t =
  run_stateful initial_state (fun () ->
      (* Get the current state *)
      let state = get_state () in

      (* Log some information *)
      log_info (Printf.sprintf "Current depth: %d" state.depth);

      (* Update the state *)
      update_state (fun s -> { s with debug = true });

      (* Get the updated state *)
      let updated_state = get_state () in
      log_info (Printf.sprintf "Debug mode: %b" updated_state.debug))

(* Example 2: Event publishing *)
let example_event_publishing (initial_state : State_types.t) : State_types.t =
  run_stateful initial_state (fun () ->
      (* Get the player ID *)
      let player_id =
        1 (* Simplified implementation that always returns player ID 1 *)
      in

      (* Publish an event *)
      log_info (Printf.sprintf "Publishing event for player %d" player_id);
      publish_event
        (Events.Event_bus.EntityWantsToMove
           { entity_id = player_id; dir = Direction.North }))

(* Example 3: Error handling *)
let example_error_handling (initial_state : State_types.t) : State_types.t =
  run_stateful initial_state (fun () ->
      (* Try a computation that might fail *)
      let result =
        try_with
          (fun () ->
            let state = get_state () in
            if state.debug then "Debug mode is on"
            else raise (Failure "Debug mode is off"))
          (fun exn -> Exn.to_string exn)
      in

      log_info (Printf.sprintf "Result: %s" result))

(* Example 4: Action handling *)
let example_action_handling (initial_state : State_types.t) : State_types.t =
  run_stateful initial_state (fun () ->
      (* Get the player ID *)
      let player_id =
        1
        (* Simplified implementation that always returns player ID 1 *)
      in

      (* Perform an action *)
      log_info (Printf.sprintf "Player %d is waiting" player_id);
      log_info "Action completed with time cost: 100")

(* Example 5: Combined example *)
let example_combined (initial_state : State_types.t) : State_types.t =
  run_stateful initial_state (fun () ->
      (* Get the player ID *)
      let player_id =
        1
        (* Simplified implementation that always returns player ID 1 *)
      in

      (* Log some information *)
      log_info
        (Printf.sprintf "Running combined example for player %d" player_id);

      (* Log action result *)
      log_info "Move completed with time cost: 100";

      (* Publish an event *)
      log_info "Publishing move event")
