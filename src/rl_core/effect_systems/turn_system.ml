(* Effect Turn System Integration

   This module provides integration between the existing turn system
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Rl_types
open Stdlib

(* Import the action handler integration for performing actions *)
module Action_handler = Effect_action_handler_integration

(* ========== Effect Types ========== *)

type _ Effect.t +=
  | (* Effect for scheduling an actor in the turn queue *)
      Schedule_actor :
      int * int
      -> unit Effect.t
  | (* Effect for checking if an actor is the player *)
      Is_player :
      int
      -> bool Effect.t

(* ========== Handler Implementation ========== *)

(* Run a computation with turn queue handlers *)
let with_turn_queue (state : State.t) (f : unit -> 'a) : 'a * State.t =
  let state_ref = ref state in
  let result =
    Effect.Deep.try_with f ()
      {
        effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Schedule_actor (id, time) ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let turn_queue = State.get_turn_queue !state_ref in
                    let new_turn_queue =
                      Turn_queue.schedule_at turn_queue id time
                    in
                    state_ref := State.set_turn_queue new_turn_queue !state_ref;
                    Effect.Deep.continue k ())
            | Is_player id ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let is_player =
                      match Components.Kind.get id with
                      | Some Components.Kind.Player -> true
                      | _ -> false
                    in
                    Effect.Deep.continue k is_player)
            | _ -> None);
      }
  in
  (result, !state_ref)

(* ========== Utility Functions ========== *)

(* Schedule an actor in the turn queue *)
let schedule_actor id time = Effect.perform (Schedule_actor (id, time))

(* Check if an actor is the player *)
let is_player id = Effect.perform (Is_player id)

(* ========== Action Handler Integration ========== *)

(* Perform an action - now using the action handler integration *)
let perform_action = Effect_action_handler_integration.perform_action

(* ========== State Integration ========== *)
(* Get the game mode *)
let get_mode () = Effect_state_integration.get_mode ()

(* Set the game mode *)
let set_mode mode = Effect_state_integration.set_mode mode

(* Check if an actor is alive *)
let is_actor_alive id =
  Effect.perform (Effect_state_integration.Is_actor_alive id)

(* Get an actor *)
let get_actor id = Effect.perform (Effect_state_integration.Get_actor id)

(* Get the next actor from the turn queue *)
let get_next_actor () = Effect.perform Effect_state_integration.Get_next_actor

(* Check if the player has an action queued *)
let has_queued_action id =
  Effect.perform (Effect_state_integration.Has_queued_action id)

(* Update an actor *)
let update_actor id f =
  Effect.perform (Effect_state_integration.Update_actor (id, f))

(* ========== Integration Functions ========== *)

(* Constants *)
let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Processes a single event from the turn queue for a given id at a specific time.
   Handles fetching the entity and actor, checking liveness, waiting for player input,
   and dispatching to handle_actor_event for action execution. *)
let process_actor_turn (id : int) (time : int) : unit =
  (* Check if the actor is alive *)
  if not (is_actor_alive id) then
    Core_log.info (fun m -> m "Actor %d is dead, removing from turn queue" id)
  else if is_player id && not (has_queued_action id) then (
    (* Player is waiting for input *)
    Core_log.info (fun m -> m "Player is waiting for input");
    set_mode CtrlMode.WaitInput)
  else
    (* Get the actor *)
    match get_actor id with
    | None -> Core_log.warn (fun m -> m "Actor %d not found" id)
    | Some actor -> (
        (* Get the next action from the actor *)
        let maybe_action, updated_actor = Actor.next_action actor in

        (* Update the actor *)
        update_actor id (fun _ -> updated_actor);

        match maybe_action with
        | Some action -> (
            (* Handle the action *)
            match perform_action id action with
            | Ok d_time when d_time >= 0 ->
                (* Schedule the actor for its next turn *)
                schedule_actor id (time + d_time)
            | Ok _ ->
                (* Action completed with no time cost *)
                ()
            | Error exn ->
                (* Action failed *)
                Core_log.err (fun m ->
                    m "Action failed: %s" (Exn.to_string exn));

                (* Reschedule with appropriate delay *)
                let delay =
                  if is_player id then player_retry_delay
                  else monster_reschedule_delay
                in
                schedule_actor id (time + delay))
        | None ->
            (* No action available *)
            if is_player id then set_mode CtrlMode.WaitInput
            else schedule_actor id (time + monster_reschedule_delay))

(* ========== Gradual Integration ========== *)

(* This function allows for integration with the effect systems integration.
   It uses effect handlers for turn queue and action handling, and is designed to be
   called from within the effect_systems_integration.ml's run_with_all_handlers function. *)
let process_turns_hybrid (_state : State.t) : unit =
  (* Define the process_turns_loop function *)
  let rec process_turns_loop () =
    match get_mode () with
    | CtrlMode.WaitInput ->
        Core_log.info (fun m -> m "Waiting for player input")
    | _ -> (
        match get_next_actor () with
        | Some (id, time) ->
            (* Process the actor's turn *)
            (if not (is_actor_alive id) then
               Core_log.info (fun m ->
                   m "Actor %d is dead, removing from turn queue" id)
             else
               match get_actor id with
               | None -> Core_log.warn (fun m -> m "Actor %d not found" id)
               | Some actor -> (
                   (* Get the next action from the actor *)
                   let maybe_action, updated_actor = Actor.next_action actor in

                   (* Update the actor *)
                   update_actor id (fun _ -> updated_actor);

                   match maybe_action with
                   | Some action -> (
                       (* Handle the action using the action handler integration *)
                       match perform_action id action with
                       | Ok d_time when d_time >= 0 ->
                           (* Schedule the actor for its next turn *)
                           schedule_actor id (time + d_time)
                       | Ok _ ->
                           (* Action completed with no time cost *)
                           ()
                       | Error exn ->
                           (* Action failed *)
                           Core_log.err (fun m ->
                               m "Action failed: %s" (Exn.to_string exn));

                           (* Reschedule with appropriate delay *)
                           let delay = 100 in
                           (* Default delay *)
                           schedule_actor id (time + delay))
                   | None ->
                       (* No action available *)
                       if is_player id then set_mode CtrlMode.WaitInput
                       else schedule_actor id (time + 100)));

            (* Continue processing turns *)
            process_turns_loop ()
        | None -> Core_log.info (fun m -> m "Turn queue is empty"))
  in

  (* Start the processing loop *)
  process_turns_loop ()
