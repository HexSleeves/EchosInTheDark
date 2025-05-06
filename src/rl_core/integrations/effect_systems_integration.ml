(* Effect Systems Integration

   This module provides a unified interface for all game systems using effect handlers.
   It composes the individual effect handler modules to create a layered approach
   where each system focuses on its specific domain.
*)

open Base
open Rl_types
open Stdlib

(* Import the individual effect handler modules *)
module Turn = Effect_turn_system_integration
module Event = Effect_event_system_integration
module Action = Effect_action_handler_integration
module State = Effect_state_integration

(* Re-export the effect types and utility functions from the individual modules *)

(* Turn System Effects *)
let schedule_actor = Turn.schedule_actor
let get_next_actor = Turn.get_next_actor
let is_actor_alive = Turn.is_actor_alive
let is_player = Turn.is_player
let has_queued_action = Turn.has_queued_action
let get_actor = Turn.get_actor
let update_actor = Turn.update_actor
let perform_action = Turn.perform_action
let set_mode = Turn.set_mode

(* Event System Effects *)
let publish_event = Event.publish_event
let subscribe = Event.subscribe
let subscribe_category = Event.subscribe_category
let subscribe_player_events = Event.subscribe_player_events
let subscribe_movement_events = Event.subscribe_movement_events
let subscribe_combat_events = Event.subscribe_combat_events
let subscribe_item_events = Event.subscribe_item_events
let subscribe_stairs_events = Event.subscribe_stairs_events

(* Action Handler Effects *)
let perform_action_and_update = Action.perform_action_and_update
let process_wait_action = Action.process_wait_action
let process_move_action = Action.process_move_action
let process_attack_action = Action.process_attack_action

(* State Effects *)
let get_state = State.get_state
let put_state = State.put_state
let update_state = State.update_state
let get_player_id_effect = State.get_player_id_effect
let set_game_mode_effect = State.set_game_mode_effect
let move_entity_effect = State.move_entity_effect
let remove_entity_effect = State.remove_entity_effect
let get_entities_effect = State.get_entities_effect
let get_creatures_effect = State.get_creatures_effect
let get_actor_effect = State.get_actor_effect
let update_actor_effect = State.update_actor_effect
let queue_actor_action_effect = State.queue_actor_action_effect
let transition_to_next_level_effect = State.transition_to_next_level_effect

let transition_to_previous_level_effect =
  State.transition_to_previous_level_effect

(* ========== Layered Handler Implementation ========== *)

(* Run a computation with all system handlers in a layered approach *)
let with_all_handlers (state : State.t) (f : unit -> 'a) : 'a * State.t =
  (* Apply handlers in a specific order, from innermost to outermost *)
  let result, state_after =
    State.with_state_handler state f |> fun (result, state_after_state) ->
    Action.with_action_handler state_after_state (fun () -> result)
    |> fun (result, state_after_action) ->
    Event.with_event_system state_after_action (fun () -> result)
    |> fun (result, state_after_event) ->
    Turn.with_turn_queue state_after_event (fun () -> result)
  in

  (result, state_after)

(* Run a function with all system handlers and return the updated state *)
let run_with_all_handlers (state : State.t) (f : unit -> 'a) : State.t =
  let _, final_state = with_all_handlers state f in
  final_state

(* Process turns using the layered effect handler approach *)
let process_turns (state : State.t) : State.t =
  (* Define the process_turns_loop function *)
  let rec process_turns_loop () =
    match State.get_mode state with
    | CtrlMode.WaitInput ->
        Core_log.info (fun m -> m "Waiting for player input")
    | _ -> (
        match Turn.get_next_actor () with
        | Some (id, time) ->
            (* Process the actor's turn *)
            (if not (Turn.is_actor_alive id) then
               Core_log.info (fun m ->
                   m "Actor %d is dead, removing from turn queue" id)
             else
               match Turn.get_actor id with
               | None -> Core_log.warn (fun m -> m "Actor %d not found" id)
               | Some actor -> (
                   (* Get the next action from the actor *)
                   let maybe_action, updated_actor = Actor.next_action actor in

                   (* Update the actor *)
                   Turn.update_actor id (fun _ -> updated_actor);

                   match maybe_action with
                   | Some action -> (
                       (* Handle the action *)
                       match Turn.perform_action id action with
                       | Ok d_time when d_time >= 0 ->
                           (* Schedule the actor for its next turn *)
                           Turn.schedule_actor id (time + d_time)
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
                           Turn.schedule_actor id (time + delay))
                   | None ->
                       (* No action available *)
                       if Turn.is_player id then
                         Turn.set_mode CtrlMode.WaitInput
                       else Turn.schedule_actor id (time + 100)));

            (* Continue processing turns *)
            process_turns_loop ()
        | None -> Core_log.info (fun m -> m "Turn queue is empty"))
  in

  (* Run the process_turns_loop with all effect handlers *)
  run_with_all_handlers state process_turns_loop
