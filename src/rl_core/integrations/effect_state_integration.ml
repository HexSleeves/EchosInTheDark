(* Effect State Integration

   This module provides integration between the existing state management
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Rl_types
open Stdlib

(* ========== Effect Types ========== *)

(* Effect for getting the current state *)
type _ Effect.t += Get_state : State.t Effect.t

(* Effect for updating the state *)
type _ Effect.t += Put_state : State.t -> unit Effect.t

(* ========== Handler Implementation ========== *)

(* Run a computation with state handlers *)
let with_state_handler (initial_state : State.t) (f : unit -> 'a) : 'a * State.t
    =
  let state = ref initial_state in
  let result =
    Effect.Deep.try_with f ()
      {
        effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Get_state ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    Effect.Deep.continue k !state)
            | Put_state new_state ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    state := new_state;
                    Effect.Deep.continue k ())
            | _ -> None);
      }
  in
  (result, !state)

(* ========== Utility Functions ========== *)

(* Get the current state *)
let get_state () = Effect.perform Get_state

(* Update the state *)
let put_state state = Effect.perform (Put_state state)

(* Update the state using a function *)
let update_state f =
  let state = get_state () in
  put_state (f state)

(* ========== Integration Functions ========== *)

(* Run a function with state handlers and return the updated state *)
let run_with_state (state : State.t) (f : unit -> 'a) : State.t =
  let _, final_state = with_state_handler state f in
  final_state

(* ========== Gradual Integration ========== *)

(* Example: Get player ID using effects *)
let get_player_id_effect () : int option =
  let state = get_state () in
  match State.get_player_id state with player_id -> Some player_id

(* Example: Set game mode using effects *)
let set_game_mode_effect (mode : CtrlMode.t) : unit =
  update_state (fun state -> State.set_mode mode state)

(* Example: Move entity using effects *)
let move_entity_effect (entity_id : int) (pos : Components.Position.t) : unit =
  update_state (fun state -> State.move_entity entity_id pos state)

(* Example: Remove entity using effects *)
let remove_entity_effect (entity_id : int) : unit =
  update_state (fun state -> State.remove_entity entity_id state)

(* Example: Get entities using effects *)
let get_entities_effect () : int list =
  let state = get_state () in
  State.get_entities state

(* Example: Get creatures using effects *)
let get_creatures_effect () : int list =
  let state = get_state () in
  State.get_creatures state

(* Example: Get actor using effects *)
let get_actor_effect (actor_id : int) : Actor.t option =
  let state = get_state () in
  State.get_actor state actor_id

(* Example: Update actor using effects *)
let update_actor_effect (actor_id : int) (f : Actor.t -> Actor.t) : unit =
  update_state (fun state -> State.update_actor state actor_id f)

(* Example: Queue actor action using effects *)
let queue_actor_action_effect (actor_id : int) (action : Action.t) : unit =
  update_state (fun state ->
      match State.get_actor state actor_id with
      | Some actor ->
          let actor' = Actor.queue_action actor action in
          State.update_actor state actor_id (fun _ -> actor')
      | None -> state)

(* Example: Transition to next level using effects *)
let transition_to_next_level_effect () : unit =
  update_state State.transition_to_next_level

(* Example: Transition to previous level using effects *)
let transition_to_previous_level_effect () : unit =
  update_state State.transition_to_previous_level
