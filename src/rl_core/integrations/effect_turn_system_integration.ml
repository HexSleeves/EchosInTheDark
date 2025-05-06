(* Effect Turn System Integration

   This module provides integration between the existing turn system
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Rl_types
open Stdlib

(* ========== Effect Types ========== *)

(* Effect for scheduling an actor in the turn queue *)
type _ Effect.t += Schedule_actor : int * int -> unit Effect.t

(* Effect for getting the next actor from the turn queue *)
type _ Effect.t += Get_next_actor : (int * int) option Effect.t

(* Effect for checking if an actor is alive *)
type _ Effect.t += Is_actor_alive : int -> bool Effect.t

(* Effect for checking if an actor is the player *)
type _ Effect.t += Is_player : int -> bool Effect.t

(* Effect for checking if the player has an action queued *)
type _ Effect.t += Has_queued_action : int -> bool Effect.t

(* Effect for getting an actor *)
type _ Effect.t += Get_actor : int -> Actor.t option Effect.t

(* Effect for updating an actor *)
type _ Effect.t += Update_actor : int * (Actor.t -> Actor.t) -> unit Effect.t

(* Effect for performing an action *)
type _ Effect.t +=
  | Perform_action : int * Action.t -> (int, exn) Result.t Effect.t

(* Effect for setting the game mode *)
type _ Effect.t += Set_mode : CtrlMode.t -> unit Effect.t

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
            | Get_next_actor ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let turn_queue = State.get_turn_queue !state_ref in
                    let result, new_turn_queue =
                      Turn_queue.get_next_actor turn_queue
                    in
                    state_ref := State.set_turn_queue new_turn_queue !state_ref;
                    Effect.Deep.continue k result)
            | Is_actor_alive id ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let is_alive =
                      match State.get_actor !state_ref id with
                      | Some actor -> Actor.is_alive actor
                      | None -> false
                    in
                    Effect.Deep.continue k is_alive)
            | Is_player id ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let is_player =
                      match Components.Kind.get id with
                      | Some Components.Kind.Player -> true
                      | _ -> false
                    in
                    Effect.Deep.continue k is_player)
            | Has_queued_action id ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let has_action =
                      match State.get_actor !state_ref id with
                      | Some actor ->
                          Option.is_some (Actor.peek_next_action actor)
                      | None -> false
                    in
                    Effect.Deep.continue k has_action)
            | Get_actor id ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let actor = State.get_actor !state_ref id in
                    Effect.Deep.continue k actor)
            | Update_actor (id, f) ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    state_ref := State.update_actor !state_ref id f;
                    Effect.Deep.continue k ())
            | Perform_action (entity_id, action) ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let new_state, result =
                      Systems.Action_handler.handle_action !state_ref entity_id
                        action
                    in
                    state_ref := new_state;
                    Effect.Deep.continue k result)
            | Set_mode mode ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    state_ref := State.set_mode mode !state_ref;
                    Effect.Deep.continue k ())
            | _ -> None);
      }
  in
  (result, !state_ref)

(* ========== Utility Functions ========== *)

(* Schedule an actor in the turn queue *)
let schedule_actor id time = Effect.perform (Schedule_actor (id, time))

(* Get the next actor from the turn queue *)
let get_next_actor () = Effect.perform Get_next_actor

(* Check if an actor is alive *)
let is_actor_alive id = Effect.perform (Is_actor_alive id)

(* Check if an actor is the player *)
let is_player id = Effect.perform (Is_player id)

(* Check if the player has an action queued *)
let has_queued_action id = Effect.perform (Has_queued_action id)

(* Get an actor *)
let get_actor id = Effect.perform (Get_actor id)

(* Update an actor *)
let update_actor id f = Effect.perform (Update_actor (id, f))

(* Perform an action *)
let perform_action entity_id action =
  Effect.perform (Perform_action (entity_id, action))

(* Set the game mode *)
let set_mode mode = Effect.perform (Set_mode mode)

(* ========== Integration Functions ========== *)

(* Constants *)
let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Process a single actor's turn using effect handlers *)
let process_actor_turn (id : int) (time : int) : unit =
  (* Check if the actor is alive *)
  if not (is_actor_alive id) then
    Core_log.info (fun m -> m "Actor %d is dead, removing from turn queue" id)
  else if is_player id && not (has_queued_action id) then (
    (* Player is waiting for input *)
    Core_log.info (fun m -> m "Player is waiting for input");
    set_mode CtrlMode.WaitInput)
  else (
    (* Process the actor's action *)
    Core_log.info (fun m -> m "Processing turn for actor %d at time %d" id time);

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
            else schedule_actor id (time + monster_reschedule_delay)))

(* Process turns until the game enters WaitInput mode or the turn queue is empty *)
let rec process_turns_loop (state : State.t) : unit =
  match State.get_mode state with
  | CtrlMode.WaitInput -> Core_log.info (fun m -> m "Waiting for player input")
  | _ -> (
      match get_next_actor () with
      | Some (id, time) ->
          process_actor_turn id time;
          process_turns_loop state
      | None -> Core_log.info (fun m -> m "Turn queue is empty"))

(* Main entry point for processing turns using effect handlers *)
let process_turns (state : State.t) : State.t =
  if State.get_debug state then
    State.get_turn_queue state |> Turn_queue.print_turn_queue;

  let _, final_state =
    with_turn_queue state (fun () -> process_turns_loop state)
  in
  final_state

(* ========== Gradual Integration ========== *)

(* This function allows for gradual integration with the existing turn system.
   It uses effect handlers for some operations while delegating others to the
   existing turn system. It's a complete drop-in replacement for Systems.Turn_system.process_turns. *)
let process_turns_hybrid (state : State.t) : State.t =
  (* Check if we're already in WaitInput mode *)
  if State.get_mode state = CtrlMode.WaitInput then state
  else
    (* Process turns until we enter WaitInput mode or the turn queue is empty *)
    let rec process_hybrid_loop current_state =
      (* Check if we're in WaitInput mode *)
      if State.get_mode current_state = CtrlMode.WaitInput then current_state
      else
        (* Use effect handlers for getting the next actor *)
        let next_actor, state_after_get =
          with_turn_queue current_state get_next_actor
        in

        match next_actor with
        | Some (id, time) ->
            (* Use the existing turn system to process the actor *)
            let new_state =
              Systems.Turn_system.process_actor_event state_after_get
                (State.get_turn_queue state_after_get)
                id time
            in
            (* Continue processing *)
            process_hybrid_loop new_state
        | None ->
            (* No actors to process, return the state as is *)
            state_after_get
    in

    Logs.info (fun m -> m "Processing turns in hybrid mode");

    (* Start the processing loop *)
    process_hybrid_loop state
