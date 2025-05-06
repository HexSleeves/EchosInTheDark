(* Effect Action Handler Integration

   This module provides integration between the existing action handler
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Types

(* ========== Effect Types ========== *)

(* Effect for performing an action *)
type _ Stdlib.Effect.t +=
  | Perform_action : int * Action.t -> (int, exn) Result.t Stdlib.Effect.t

(* ========== Handler Implementation ========== *)

(* Run a computation with action handler *)
let with_action_handler (state : State.t) (f : unit -> 'a) : 'a * State.t =
  let state_ref = ref state in
  let result =
    Stdlib.Effect.Deep.try_with f ()
      {
        effc =
          (fun (type a) (eff : a Stdlib.Effect.t) ->
            match eff with
            | Perform_action (entity_id, action) ->
                Some
                  (fun (k : (a, _) Stdlib.Effect.Deep.continuation) ->
                    let new_state, result =
                      Systems.Action_handler.handle_action !state_ref entity_id
                        action
                    in
                    state_ref := new_state;
                    Stdlib.Effect.Deep.continue k result)
            | _ -> None);
      }
  in
  (result, !state_ref)

(* ========== Utility Functions ========== *)

(* Perform an action for an entity *)
let perform_action entity_id action =
  Stdlib.Effect.perform (Perform_action (entity_id, action))

(* ========== Integration Functions ========== *)

(* Run a function with action handlers and return the updated state *)
let run_with_actions (state : State.t) (f : unit -> 'a) : State.t =
  let _, final_state = with_action_handler state f in
  final_state

(* Perform an action and return the updated state *)
let perform_action_and_update (entity_id : int) (action : Action.t)
    (state : State.t) : State.t * (int, exn) Result.t =
  let result_ref = ref (Ok 0) in
  let final_state =
    run_with_actions state (fun () ->
        let result = perform_action entity_id action in
        result_ref := result)
  in
  (final_state, !result_ref)

(* ========== Gradual Integration ========== *)

(* Example: Process a wait action using effects *)
let process_wait_action (entity_id : int) (state : State.t) : State.t =
  run_with_actions state (fun () ->
      match perform_action entity_id Action.Wait with
      | Ok time_cost ->
          Logger.info (fun m ->
              m "Entity %d waited for %d time units" entity_id time_cost)
      | Error exn ->
          Logger.err (fun m ->
              m "Entity %d failed to wait: %s" entity_id (Exn.to_string exn)))

(* Example: Process a move action using effects *)
let process_move_action (entity_id : int) (dir : Direction.t) (state : State.t)
    : State.t =
  run_with_actions state (fun () ->
      match perform_action entity_id (Action.Move dir) with
      | Ok time_cost ->
          Logger.info (fun m ->
              m "Entity %d moved %s for %d time units" entity_id
                (Direction.show dir) time_cost)
      | Error exn ->
          Logger.err (fun m ->
              m "Entity %d failed to move %s: %s" entity_id (Direction.show dir)
                (Exn.to_string exn)))

(* Example: Process an attack action using effects *)
let process_attack_action (attacker_id : int) (defender_id : int)
    (state : State.t) : State.t =
  run_with_actions state (fun () ->
      match perform_action attacker_id (Action.Attack defender_id) with
      | Ok time_cost ->
          Logger.info (fun m ->
              m "Entity %d attacked entity %d for %d time units" attacker_id
                defender_id time_cost)
      | Error exn ->
          Logger.err (fun m ->
              m "Entity %d failed to attack entity %d: %s" attacker_id
                defender_id (Exn.to_string exn)))
