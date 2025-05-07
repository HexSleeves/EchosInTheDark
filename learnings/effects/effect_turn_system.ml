(* Effect-based Turn System

   This module demonstrates how to use effect handlers to simplify
   the turn system in the game.
*)

open Base
open Types
open Stdlib

module Log =
  (val Logger.make_logger "effect_turn_system" ~doc:"Effect turn system logs" ())

(* Define our own logging functions *)
let log_info msg = Log.info (fun m -> m "%s" msg)
let log_debug msg = Log.debug (fun m -> m "%s" msg)
let log_warn msg = Log.warn (fun m -> m "%s" msg)
let log_error msg = Log.err (fun m -> m "%s" msg)

(* Define a simple update_state function *)
let update_state _f = ()

(* Define a simple get_state function *)
let get_state () = State.make ~debug:false ~w:100 ~h:100 ~seed:0 ~depth:0

(* Define a simple raise_error function *)
let raise_error msg = failwith msg

(* Define a simple perform_action function *)
let perform_action (_entity_id, _action) = Ok 100
(* Simplified implementation that always succeeds with a time cost of 100 *)

(* Define a simple run_stateful function *)
let run_stateful state _f = state

(* Constants *)
let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Effect for scheduling an actor *)
type _ Effect.t += Schedule_actor : int * int -> unit Effect.t

(* Effect for getting the next actor *)
type _ Effect.t += Get_next_actor : (int * int) option Effect.t

(* Effect for checking if an actor is alive *)
type _ Effect.t += Is_actor_alive : int -> bool Effect.t

(* Effect for checking if an actor is the player *)
type _ Effect.t += Is_player : int -> bool Effect.t

(* Effect for checking if the player has an action queued *)
type _ Effect.t += Has_queued_action : int -> bool Effect.t

(* Handler for turn queue effects *)
let with_turn_queue (f : unit -> 'a) : 'a = f ()

(* Schedule an actor *)
let schedule_actor id time = Effect.perform (Schedule_actor (id, time))

(* Get the next actor *)
let get_next_actor () = Effect.perform Get_next_actor

(* Check if an actor is alive *)
let is_actor_alive id = Effect.perform (Is_actor_alive id)

(* Check if an actor is the player *)
let is_player id = Effect.perform (Is_player id)

(* Check if the player has an action queued *)
let has_queued_action id = Effect.perform (Has_queued_action id)

(* Process a single actor's turn *)
let process_actor_turn (id : int) (time : int) : unit =
  (* Check if the actor is alive *)
  if not (is_actor_alive id) then
    log_info (Printf.sprintf "Actor %d is dead, removing from turn queue" id)
  else if is_player id && not (has_queued_action id) then (
    (* Player is waiting for input *)
    log_info "Player is waiting for input";
    update_state State.set_wait_input_mode)
  else (
    (* Process the actor's action *)
    log_info (Printf.sprintf "Processing turn for actor %d at time %d" id time);

    let state = get_state () in
    let actor =
      match State.get_actor state id with
      | Some a -> a
      | None -> raise_error (Printf.sprintf "Actor %d not found" id)
    in

    (* Get the next action from the actor *)
    let maybe_action, updated_actor = Actor.next_action actor in

    (* Update the actor *)
    update_state (fun s -> State.update_actor s id (fun _ -> updated_actor));

    match maybe_action with
    | Some action -> (
        (* Handle the action *)
        let result = perform_action (id, action) in

        match result with
        | Ok d_time when d_time >= 0 ->
            (* Schedule the actor for its next turn *)
            schedule_actor id (time + d_time)
        | Ok _ ->
            (* Action completed with no time cost *)
            ()
        | Error exn ->
            (* Action failed *)
            log_error (Printf.sprintf "Action failed: %s" (Exn.to_string exn));

            (* Reschedule with appropriate delay *)
            let delay =
              if is_player id then player_retry_delay
              else monster_reschedule_delay
            in
            schedule_actor id (time + delay))
    | None ->
        (* No action available *)
        if is_player id then update_state State.set_wait_input_mode
        else schedule_actor id (time + monster_reschedule_delay))

(* Process turns until the game enters WaitInput mode or the turn queue is empty *)
let rec process_turns_loop () : unit =
  let state = get_state () in
  match State.get_mode state with
  | CtrlMode.WaitInput -> log_info "Waiting for player input"
  | _ -> (
      match get_next_actor () with
      | Some (id, time) ->
          process_actor_turn id time;
          process_turns_loop ()
      | None -> log_info "Turn queue is empty")

(* Main entry point for processing turns *)
let process_turns (state : State.t) : State.t =
  if State.get_debug state then
    State.get_turn_queue state |> Turn_queue.print_turn_queue;

  run_stateful state (fun () -> with_turn_queue process_turns_loop)
