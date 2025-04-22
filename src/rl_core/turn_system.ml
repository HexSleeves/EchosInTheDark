open Base
open Types
module B = Backend
module EntityManager = Entity_manager

let monster_reschedule_delay = 100

(* Helper: get actor or log error and skip *)
let get_actor_safe actor_manager (entity : Types.entity) =
  match entity.data with
  | Types.PlayerData { actor_id; _ } | Types.CreatureData { actor_id; _ } -> (
      try Some (Actor_manager.get_unsafe actor_manager actor_id)
      with _ ->
        Core_log.err (fun m -> m "Actor not found for entity: %d" entity.id);
        None)
  | _ ->
      Core_log.err (fun m -> m "Entity %d is not a valid actor" entity.id);
      None

let get_entity_safe entities entity_id =
  try Some (EntityManager.find_unsafe entities entity_id)
  with _ ->
    Core_log.err (fun m -> m "Entity not found: %d" entity_id);
    None

let get_next_actor actor_manager turn_queue entities =
  match Turn_queue.get_next_actor turn_queue with
  | None -> None
  | Some (entity_id, time) -> (
      Core_log.info (fun m -> m "Processing turn for entity: %d" entity_id);
      let entity = get_entity_safe entities entity_id in
      match entity with
      | None -> None
      | Some entity -> (
          match get_actor_safe actor_manager entity with
          | None -> None
          | Some actor -> Some (entity_id, time, actor)))

(* Helper: should wait for player input? *)
let should_wait_for_player_input entity actor =
  match entity.Types.kind with
  | Types.Player -> Option.is_none (Actor.peek_next_action actor)
  | _ -> false

(* Remove dead actor from queue *)
let remove_dead_actor turn_queue entity_id =
  Core_log.info (fun m -> m "Removing dead actor %d from queue" entity_id);
  Turn_queue.remove_actor turn_queue entity_id

(* Add helper to process a single actor's turn *)
let process_actor_event (backend : B.t) turn_queue entities entity_id time : B.t
    =
  Core_log.info (fun m -> m "Processing turn for entity: %d" entity_id);
  match get_entity_safe entities entity_id with
  | None -> backend
  | Some entity -> (
      match get_actor_safe backend.actor_manager entity with
      | None -> backend
      | Some actor -> (
          if not (Actor.is_alive actor) then (
            Core_log.info (fun m ->
                m "Actor %d is dead. Removing from queue." entity_id);
            remove_dead_actor turn_queue entity_id;
            backend)
          else if should_wait_for_player_input entity actor then (
            Core_log.info (fun m -> m "Player is awaiting input");
            let backend = { backend with mode = CtrlMode.WaitInput } in
            Turn_queue.schedule_turn turn_queue entity_id time;
            backend)
          else
            match Actor.next_action actor with
            | None ->
                Core_log.info (fun m ->
                    m "No action for entity: %d. Rescheduling turn." entity_id);
                Turn_queue.schedule_turn turn_queue entity_id time;
                backend
            | Some action -> (
                Core_log.info (fun m ->
                    m "Action for entity: %d. Executing..." entity_id);
                let backend, result =
                  Backend.handle_action backend entity_id action
                in
                match result with
                | Ok d_time ->
                    Turn_queue.schedule_turn turn_queue entity_id (time + d_time);
                    backend
                | Error e ->
                    Core_log.err (fun m ->
                        m "Failed to perform action: %s" (Exn.to_string e));
                    let delay =
                      match entity.Types.kind with
                      | Types.Player -> 0
                      | _ -> monster_reschedule_delay
                    in
                    Turn_queue.schedule_turn turn_queue entity_id (time + delay);
                    backend)))

let process_turns (backend : B.t) : B.t =
  let turn_queue = backend.turn_queue in
  let entities = backend.entities in
  if backend.debug then Turn_queue.print_queue turn_queue;

  let rec process_loop (backend : B.t) =
    match backend.mode with
    | CtrlMode.WaitInput ->
        Core_log.info (fun m -> m "Waiting for player input");
        backend
    | _ -> (
        match Turn_queue.get_next_actor turn_queue with
        | None -> backend
        | Some (entity_id, time) ->
            let backend =
              process_actor_event backend turn_queue entities entity_id time
            in
            process_loop backend)
  in
  process_loop backend
