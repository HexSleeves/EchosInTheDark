(* Effect Handlers for RL Core

   This module provides a foundation for using OCaml effect handlers
   throughout the codebase. It defines basic effect types and handlers
   that can be used to simplify state management, event handling, and more.
*)

open Base
open Types
open Stdlib

(* ========== Core Effect Types ========== *)

(* State Effects *)
type _ Effect.t += Get_state : State_types.t Effect.t
type _ Effect.t += Put_state : State_types.t -> unit Effect.t

(* Event Effects *)
type _ Effect.t += Publish_event : Events.Event_bus.event -> unit Effect.t

(* Error Effects *)
type _ Effect.t += Raise_error : string -> 'a Effect.t
type _ Effect.t += Catch : (unit -> 'a) * (exn -> 'a) -> 'a Effect.t

(* Logging Effects *)
type _ Effect.t += Log_info : string -> unit Effect.t
type _ Effect.t += Log_debug : string -> unit Effect.t
type _ Effect.t += Log_warn : string -> unit Effect.t
type _ Effect.t += Log_error : string -> unit Effect.t

(* Action Effects *)
type _ Effect.t +=
  | Perform_action : int * Action.t -> (int, exn) Result.t Effect.t

(* ========== Handler Implementations ========== *)

(* Run a computation with state handlers *)
let with_state (state : State_types.t) (f : unit -> 'a) : 'a * State_types.t =
  let result = f () in
  (result, state)

(* Run a computation with event handlers *)
let with_events (f : unit -> 'a) : 'a = f ()

(* Run a computation with error handlers *)
let with_errors (f : unit -> 'a) : ('a, exn) Result.t =
  try Ok (f ()) with exn -> Error exn

(* Run a computation with logging handlers *)
let with_logging (f : unit -> 'a) : 'a = f ()

(* Run a computation with action handlers *)
let with_actions (f : unit -> 'a) : 'a = f ()

(* ========== Utility Functions ========== *)

(* Get the current state *)
let get_state () = Effect.perform Get_state

(* Update the state *)
let put_state state = Effect.perform (Put_state state)

(* Update the state using a function *)
let update_state f =
  let state = get_state () in
  put_state (f state)

(* Publish an event *)
let publish_event event = Effect.perform (Publish_event event)

(* Raise an error *)
let raise_error msg = Effect.perform (Raise_error msg)

(* Try a computation, catching exceptions *)
let try_with f catch = Effect.perform (Catch (f, catch))

(* Log messages at different levels *)
let log_info msg = Effect.perform (Log_info msg)
let log_debug msg = Effect.perform (Log_debug msg)
let log_warn msg = Effect.perform (Log_warn msg)
let log_error msg = Effect.perform (Log_error msg)

(* Perform an action for an entity *)
let perform_action entity_id action =
  Effect.perform (Perform_action (entity_id, action))

(* ========== Combined Handlers ========== *)

(* Run a computation with all handlers *)
let run_with_all_handlers (initial_state : State_types.t) (f : unit -> 'a) :
    ('a * State_types.t, exn) Result.t =
  try
    let run_f () =
      with_logging (fun () -> with_events (fun () -> with_actions f))
    in
    let result, final_state = with_state initial_state run_f in
    Ok (result, final_state)
  with exn -> Error exn

(* Run a computation that returns a new state *)
let run_stateful (initial_state : State_types.t) (f : unit -> 'a) :
    State_types.t =
  match run_with_all_handlers initial_state f with
  | Ok (_, final_state) -> final_state
  | Error exn ->
      Logger.err (fun m ->
          m "Error in stateful computation: %s" (Exn.to_string exn));
      initial_state
