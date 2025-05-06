(* Effect State Integration

   This module provides integration between the existing state management
   and the effect-based approach. It serves as a bridge that allows
   gradual adoption of effect handlers without disrupting the existing codebase.
*)

open Base
open Types
open Stdlib

(* ========== Effect Types ========== *)

type _ Effect.t +=
  | (* Effect for getting the current state *)
      Get_state :
      State.t Effect.t
  | (* Effect for updating the state *)
      Put_state :
      State.t
      -> unit Effect.t
  | (* Effect for getting the current mode *)
      Get_mode :
      CtrlMode.t Effect.t
  | (* Effect for setting the mode *)
      Set_mode :
      CtrlMode.t
      -> unit Effect.t
  | (* Effect for getting the next actor from the turn queue *)
      Get_next_actor :
      (int * int) option Effect.t
  | (* Effect for checking if an actor is alive *)
      Is_actor_alive :
      int
      -> bool Effect.t
  | (* Effect for checking if the player has an action queued *)
      Has_queued_action :
      int
      -> bool Effect.t
  | (* Effect for getting an actor *)
      Get_actor :
      int
      -> Actor.t option Effect.t
  | (* Effect for updating an actor *)
      Update_actor :
      int * (Actor.t -> Actor.t)
      -> unit Effect.t

(* ========== Handler Implementation ========== *)

type t = State.t

(* Run a computation with state handlers *)
let with_state_handler (initial_state : State.t) (f : unit -> 'a) : 'a * State.t
    =
  let state_ref = ref initial_state in
  let result =
    Effect.Deep.try_with f ()
      {
        effc =
          (fun (type a) (eff : a Effect.t) ->
            match eff with
            | Get_state ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    Effect.Deep.continue k !state_ref)
            | Put_state new_state ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    state_ref := new_state;
                    Effect.Deep.continue k ())
            | Get_mode ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    let mode = State.get_mode !state_ref in
                    Effect.Deep.continue k mode)
            | Set_mode mode ->
                Some
                  (fun (k : (a, _) Effect.Deep.continuation) ->
                    state_ref := State.set_mode mode !state_ref;
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
            | _ -> None);
      }
  in
  (result, !state_ref)

(* ========== Utility Functions ========== *)

(* Get the current state *)
let get_state () = Effect.perform Get_state

(* Update the state *)
let put_state state = Effect.perform (Put_state state)

(* Get the current mode *)
let get_mode () = Effect.perform Get_mode

(* Set the mode *)
let set_mode mode = Effect.perform (Set_mode mode)

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
