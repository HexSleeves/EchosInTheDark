open Base
open Types
module EntityManager = Entity_manager

let monster_reschedule_delay = 100
let player_retry_delay = 0

(* Helper: Safely retrieve an actor from the actor manager using entity data.
   Logs an error if the actor is not found or the entity is not an actor. *)
let get_actor_safe actor_manager (entity : Entity.entity) =
  match entity.data with
  | Entity.PlayerData { actor_id; _ } | Entity.CreatureData { actor_id; _ } -> (
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
  backend : Backend.t;
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
let handle_actor_event (ctx : ctx) : Backend.t =
  let { backend; tq; actor_id; actor; entity_id; entity; time } = ctx in

  (* Attempt to get the next action from the actor's internal queue.
     Also get the actor state *after* dequeuing the action. *)
  let maybe_action, updated_actor = Actor.next_action actor in
  (* Update the actor manager with the state reflecting the dequeued action. *)
  let actor_manager =
    Actor_manager.update backend.actor_manager actor_id (fun _ -> updated_actor)
  in

  match maybe_action with
  | None ->
      (* If the actor has no action queued, it might be waiting or thinking.
         Currently, reschedule immediately at the same time.
         WARNING: This could potentially lead to loops if the actor never gets an action.
         Consider adding a small time cost (e.g., implicit wait) instead. *)
      Core_log.info (fun m ->
          m "No action for entity: %d. Rescheduling turn." entity_id);
      let turn_queue = Turn_queue.schedule_turn tq entity_id time in
      { backend with turn_queue; actor_manager }
  | Some action -> (
      (* Execute action *)
      Core_log.info (fun m -> m "Action for entity: %d. Executing..." entity_id);
      let backend_after_action, result =
        Backend.handle_action backend entity_id action
      in
      match result with
      | Ok d_time ->
          let turn_queue =
            Turn_queue.schedule_turn tq entity_id (time + d_time)
          in
          { backend_after_action with actor_manager; turn_queue }
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
          (* Return the backend state *before* the action (correct),
             but INCLUDE the updated actor_manager where the action was dequeued. *)
          { backend with actor_manager; turn_queue })

(* Processes a single event from the turn queue for a given entity_id at a specific time.
   Handles fetching the entity and actor, checking liveness, waiting for player input,
   and dispatching to handle_actor_event for action execution. *)
let process_actor_event (backend : Backend.t) (tq : Turn_queue.t)
    (entities : EntityManager.t) (entity_id : Entity.entity_id) (time : int) :
    Backend.t =
  match get_entity_safe entities entity_id with
  | None -> backend
  | Some entity -> (
      match get_actor_safe backend.actor_manager entity with
      | None -> backend
      | Some actor ->
          let actor_id =
            match entity.data with
            | Entity.PlayerData { actor_id; _ } -> actor_id
            | Entity.CreatureData { actor_id; _ } -> actor_id
            | _ -> entity_id (* fallback, but should not happen for actors *)
          in
          (* Remove dead actor from queue *)
          if not (Actor.is_alive actor) then
            { backend with turn_queue = remove_dead_actor tq entity_id }
            (* Next, check if it's the player and needs input. If so, pause processing. *)
          else if should_wait_for_player_input entity actor then (
            Core_log.info (fun m -> m "Player is awaiting input");
            { backend with mode = CtrlMode.WaitInput })
          (* Otherwise, the actor is alive and ready to act. Handle the event. *)
            else
            let ctx =
              { backend; tq; actor_id; actor; entity_id; entity; time }
            in
            handle_actor_event ctx)

(* Main turn processing function.
   Continuously processes actors from the turn queue until the queue is empty
   or the game enters WaitInput mode. *)
let process_turns (backend : Backend.t) : Backend.t =
  let rec process_loop (current_backend : Backend.t) : Backend.t =
    match current_backend.mode with
    | CtrlMode.WaitInput ->
        (* If waiting for input, stop processing turns for now. *)
        Core_log.info (fun m -> m "Waiting for player input");
        current_backend
    | _ -> (
        (* Get the next actor and the updated turn queue state. *)
        let result, next_tq =
          Turn_queue.get_next_actor current_backend.turn_queue
        in
        match result with
        | None ->
            (* Turn queue is empty, stop processing. Return backend with the empty queue state. *)
            { current_backend with turn_queue = next_tq }
        | Some (entity_id, time) ->
            process_loop
              (process_actor_event current_backend next_tq
                 current_backend.entities entity_id time))
  in
  if backend.debug then Turn_queue.print_queue backend.turn_queue;
  process_loop backend
