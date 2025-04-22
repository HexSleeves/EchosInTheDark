open Base
open Types
module EntityManager = Entity_manager
module Actor = Actor_manager.Actor

let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Helper: Safely retrieve an actor from the actor manager using entity data.
   Logs an error if the actor is not found or the entity is not an actor. *)
let get_actor_safe actor_manager (entity : Entity.entity) =
  match entity.data with
  | Some (Entity.PlayerData { actor_id; _ })
  | Some (Entity.CreatureData { actor_id; _ }) -> (
      try Some (Actor_manager.get_unsafe actor_manager actor_id)
      with _ ->
        Core_log.err (fun m -> m "Actor not found for entity: %d" entity.id);
        None)
  | _ ->
      Core_log.err (fun m -> m "Entity %d is not a valid actor" entity.id);
      None

(* Helper: Safely retrieve an entity from the entity manager.
   Logs an error if the entity is not found. *)
let get_entity_safe entities entity_id =
  try Some (EntityManager.find_unsafe entities entity_id)
  with _ ->
    Core_log.err (fun m -> m "Entity not found: %d" entity_id);
    None

(* Helper: Determine if the game should wait for player input.
   This is true if the entity is the player and has no action queued. *)
let should_wait_for_player_input entity actor =
  match entity.Entity.kind with
  | Entity.Player -> Option.is_none (Actor.peek_next_action actor)
  | _ -> false

(* Helper: Remove a dead actor from the turn queue. *)
let remove_dead_actor turn_queue entity_id =
  Core_log.info (fun m -> m "Removing dead actor %d from queue" entity_id);
  Turn_queue.remove_actor turn_queue entity_id

(* Context record for passing necessary data to handle_actor_event *)
type ctx = {
  backend : State.t;
  tq : Turn_queue.t;
  actor_id : Actor.actor_id;
  actor : Actor.t;
  entity_id : Entity.entity_id;
  entity : Entity.entity;
  time : int;
}

(* Handles the core logic for an actor taking its turn: dequeuing an action,
   updating the actor manager, and either rescheduling (if no action)
   or executing the action and rescheduling based on the result. *)
let handle_actor_event (ctx : ctx) : State.t =
  let { backend; tq; actor_id; actor; entity_id; entity; time } = ctx in

  (* Attempt to get the next action from the actor's internal queue.
     Also get the actor state *after* dequeuing the action. *)
  let maybe_action, updated_actor = Actor.next_action actor in
  (* Update the actor manager with the state reflecting the dequeued action. *)
  let backend = State.update_actor backend actor_id (fun _ -> updated_actor) in

  match maybe_action with
  | None ->
      Core_log.info (fun m ->
          m "No action for entity: %d. Rescheduling turn." entity_id);
      let turn_queue = Turn_queue.schedule_turn tq entity_id time in
      State.set_turn_queue backend turn_queue
  | Some action -> (
      Core_log.info (fun m -> m "Action for entity: %d. Executing..." entity_id);
      let backend_after_action, result =
        Action_handler.handle_action backend entity_id action
      in
      match result with
      | Ok d_time ->
          let turn_queue =
            Turn_queue.schedule_turn tq entity_id (time + d_time)
          in
          State.set_turn_queue backend_after_action turn_queue
      | Error e ->
          Core_log.err (fun m ->
              m "Failed to perform action: %s" (Exn.to_string e));
          let delay =
            match entity.Entity.kind with
            | Entity.Player -> player_retry_delay
            | _ -> monster_reschedule_delay
          in
          let turn_queue =
            Turn_queue.schedule_turn tq entity_id (time + delay)
          in
          State.set_turn_queue backend turn_queue)

(* Processes a single event from the turn queue for a given entity_id at a specific time.
   Handles fetching the entity and actor, checking liveness, waiting for player input,
   and dispatching to handle_actor_event for action execution. *)
let process_actor_event (backend : State.t) (tq : Turn_queue.t)
    (entities : EntityManager.t) (entity_id : Entity.entity_id) (time : int) :
    State.t =
  match get_entity_safe entities entity_id with
  | None -> backend
  | Some entity -> (
      let actor_id =
        match entity.data with
        | Some (Entity.PlayerData { actor_id; _ }) -> actor_id
        | Some (Entity.CreatureData { actor_id; _ }) -> actor_id
        | _ -> entity_id
      in
      match State.get_actor backend actor_id with
      | None -> backend
      | Some actor ->
          (* Remove dead actor from queue *)
          if not (Actor.is_alive actor) then
            State.set_turn_queue backend (remove_dead_actor tq entity_id)
          else if should_wait_for_player_input entity actor then (
            Core_log.info (fun m -> m "Player is awaiting input");
            State.set_mode backend CtrlMode.WaitInput)
          else
            let ctx =
              { backend; tq; actor_id; actor; entity_id; entity; time }
            in
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
        | Some (entity_id, time) ->
            process_loop
              (process_actor_event current_backend next_tq
                 (State.get_entities_manager current_backend)
                 entity_id time))
  in
  if State.get_debug backend then
    Turn_queue.print_queue (State.get_turn_queue backend);
  process_loop backend
