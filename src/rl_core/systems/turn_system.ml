open Base
open Types
open Actors
module Log = (val Core_log.make_logger "turn_system" : Logs.LOG)

let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Helper: Determine if the game should wait for player input.
   This is true if the entity is the player and has no action queued. *)
let should_wait_for_player_input entity actor =
  match entity with
  | Entity.Player _ -> Option.is_none (Actor.peek_next_action actor)
  | _ -> false

(* Helper: Remove a dead actor from the turn queue. *)
let remove_dead_actor turn_queue id =
  Log.info (fun m -> m "Removing dead actor %d from queue" id);
  Turn_queue.remove_actor turn_queue id

(* Context record for passing necessary data to handle_actor_event *)
type ctx = {
  state : State.t;
  tq : Turn_queue.t;
  actor : Actor.t;
  id : Entity.id;
  entity : Entity.t;
  time : int;
}

(* Handles the core logic for an actor taking its turn: dequeuing an action,
   updating the actor manager, and either rescheduling (if no action)
   or executing the action and rescheduling based on the result. *)
let handle_actor_event (ctx : ctx) : State.t =
  let { state; tq; actor; id; entity; time } = ctx in

  (* Attempt to get the next action from the actor's internal queue.
     Also get the actor state *after* dequeuing the action. *)
  let maybe_action, updated_actor = Actor.next_action actor in

  (* Update the actor manager with the state reflecting the dequeued action. *)
  let backend =
    (* Update the actor manager with the state reflecting the dequeued action. *)
    State.update_actor state id (fun _ -> updated_actor)
    (* Set the turn queue to the new turn queue. *)
    |> State.set_turn_queue tq
  in

  match maybe_action with
  | Some action -> (
      let backend_after_action, result =
        Action_handler.handle_action backend id action
      in

      let tq_after_action = State.get_turn_queue backend_after_action in

      match result with
      | Ok d_time when d_time >= 0 ->
          State.set_turn_queue
            (Turn_queue.schedule_turn tq_after_action id (time + d_time))
            backend_after_action
      | Ok _ -> backend_after_action
      | Error e ->
          Log.err (fun m ->
              m "Entity %d failed to perform action: %s" id (Exn.to_string e));
          let delay =
            match entity with
            | Entity.Player _ -> player_retry_delay
            | _ -> monster_reschedule_delay
          in
          Turn_queue.schedule_turn tq_after_action id (time + delay)
          |> fun turn_queue ->
          State.set_turn_queue turn_queue backend_after_action)
  | None ->
      Turn_queue.schedule_turn tq id (time + 100) |> fun turn_queue ->
      State.set_turn_queue turn_queue backend

(* Processes a single event from the turn queue for a given id at a specific time.
   Handles fetching the entity and actor, checking liveness, waiting for player input,
   and dispatching to handle_actor_event for action execution. *)
let process_actor_event (state : State.t) (tq : Turn_queue.t) (id : Entity.id)
    (time : int) : State.t =
  State.get_entity id state
  |> Option.bind ~f:(fun entity ->
         State.get_actor state id
         |> Option.map ~f:(fun actor -> (entity, actor)))
  |> Option.value_map ~default:state ~f:(fun (entity, actor) ->
         match
           (Actor.is_alive actor, should_wait_for_player_input entity actor)
         with
         | false, _ ->
             State.set_turn_queue (remove_dead_actor tq id) state
             |> fun state -> state
         | true, true -> State.set_wait_input_mode state
         | true, false ->
             let ctx = { state; tq; actor; id; entity; time } in
             handle_actor_event ctx)

(* Main turn processing function.
   Continuously processes actors from the turn queue until the queue is empty
   or the game enters WaitInput mode. *)
let process_turns (backend : State.t) : State.t =
  let rec process_loop current_backend =
    match State.get_mode current_backend with
    | Types.CtrlMode.WaitInput -> current_backend
    | _ ->
        Turn_queue.get_next_actor (State.get_turn_queue current_backend)
        |> fun (result, next_tq) ->
        Option.value_map result
          ~default:(State.set_turn_queue next_tq current_backend)
          ~f:(fun (id, time) ->
            process_loop (process_actor_event current_backend next_tq id time))
  in

  if State.get_debug backend then
    State.get_turn_queue backend |> Turn_queue.print_turn_queue;

  process_loop backend
