open Base
open Types
module EntityManager = Entity_manager
module Actor = Actor_manager.Actor

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
  Core_log.info (fun m -> m "Removing dead actor %d from queue" id);
  Turn_queue.remove_actor turn_queue id

(* Context record for passing necessary data to handle_actor_event *)
type ctx = {
  backend : State.t;
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
  let { backend; tq; actor; id; entity; time } = ctx in

  (* Attempt to get the next action from the actor's internal queue.
     Also get the actor state *after* dequeuing the action. *)
  let maybe_action, updated_actor = Actor.next_action actor in
  (* Update the actor manager with the state reflecting the dequeued action. *)
  let backend = State.update_actor backend id (fun _ -> updated_actor) in

  match maybe_action with
  | None ->
      Core_log.info (fun m ->
          m "No action for entity: %d. Rescheduling turn." id);
      let turn_queue = Turn_queue.schedule_turn tq id time in
      State.set_turn_queue backend turn_queue
  | Some action -> (
      Core_log.info (fun m -> m "Action for entity: %d. Executing..." id);
      let backend_after_action, result =
        Action_handler.handle_action backend id action
      in
      match result with
      | Ok d_time ->
          let turn_queue = Turn_queue.schedule_turn tq id (time + d_time) in
          State.set_turn_queue backend_after_action turn_queue
      | Error e ->
          Core_log.err (fun m ->
              m "Failed to perform action: %s" (Exn.to_string e));
          let delay =
            match entity with
            | Entity.Player _ -> player_retry_delay
            | _ -> monster_reschedule_delay
          in
          let turn_queue = Turn_queue.schedule_turn tq id (time + delay) in
          State.set_turn_queue backend turn_queue)

(* Processes a single event from the turn queue for a given id at a specific time.
   Handles fetching the entity and actor, checking liveness, waiting for player input,
   and dispatching to handle_actor_event for action execution. *)
let process_actor_event (backend : State.t) (tq : Turn_queue.t) (id : Entity.id)
    (time : int) : State.t =
  match State.get_entity backend id with
  | None -> backend
  | Some entity -> (
      match State.get_actor backend id with
      | None -> backend
      | Some actor ->
          (* Remove dead actor from queue *)
          if not (Actor.is_alive actor) then
            State.set_turn_queue backend (remove_dead_actor tq id)
          else if should_wait_for_player_input entity actor then (
            Core_log.info (fun m -> m "Player is awaiting input");
            State.set_mode backend CtrlMode.WaitInput)
          else
            let ctx = { backend; tq; actor; id; entity; time } in
            handle_actor_event ctx)

(* Main turn processing function.
   Continuously processes actors from the turn queue until the queue is empty
   or the game enters WaitInput mode. *)
let process_turns (backend : State.t) : State.t =
  let rec process_loop (current_backend : State.t) : State.t =
    match State.get_mode current_backend with
    | CtrlMode.WaitInput ->
        Core_log.info (fun m -> m "Waiting for player input");
        current_backend
    | _ -> (
        let result, next_tq =
          Turn_queue.get_next_actor (State.get_turn_queue current_backend)
        in
        match result with
        | None -> State.set_turn_queue current_backend next_tq
        | Some (id, time) ->
            process_loop (process_actor_event current_backend next_tq id time))
  in
  if State.get_debug backend then
    Turn_queue.print_queue (State.get_turn_queue backend);
  process_loop backend
