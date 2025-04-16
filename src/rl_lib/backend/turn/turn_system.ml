open Base
module B = Backend
module Log = Backend.Log
module E = Entity

let monster_reschedule_delay = 100

(* Helper: get actor or log error and skip *)
let get_actor_safe actor_manager entity =
  match entity.E.data with
  | E.PlayerData { actor_id; _ } | E.CreatureData { actor_id; _ } -> (
      try Some (Actor_manager.get_unsafe actor_manager actor_id)
      with _ ->
        Log.err (fun m -> m "Actor not found for entity: %d" entity.id);
        None)
  | _ ->
      Log.err (fun m -> m "Entity %d is not a valid actor" entity.id);
      None

let get_entity_safe entities entity_id =
  try Some (Entity.EntityManager.find_unsafe entities entity_id)
  with _ ->
    Log.err (fun m -> m "Entity not found: %d" entity_id);
    None

let get_next_actor actor_manager turn_queue entities =
  match Turn_queue.get_next_actor turn_queue with
  | None -> None
  | Some (entity_id, time) -> (
      Log.info (fun m -> m "Processing turn for entity: %d" entity_id);
      let entity = get_entity_safe entities entity_id in
      match entity with
      | None -> None
      | Some entity -> (
          match get_actor_safe actor_manager entity with
          | None -> None
          | Some actor -> Some (entity_id, time, actor)))

(* Helper: should wait for player input? *)
let should_wait_for_player_input entity actor =
  match entity.E.kind with
  | E.Player -> Option.is_none (Actor.peek_next_action actor)
  | _ -> false

(* Remove dead actor from queue *)
let remove_dead_actor turn_queue entity_id =
  Log.info (fun m -> m "Removing dead actor %d from queue" entity_id);
  () (* Implement if Turn_queue supports removal; else, just log *)

let rec process_turns (backend : B.t) : B.t =
  let turn_queue = backend.turn_queue in
  let entities = backend.entities in
  if backend.debug then Turn_queue.print_queue turn_queue;

  match backend.mode with
  | Mode.CtrlMode.WaitInput ->
      Log.info (fun m -> m "Waiting for player input");
      backend
  | _ ->
      let rec loop (backend : B.t) =
        match Turn_queue.get_next_actor turn_queue with
        | None -> backend
        | Some (entity_id, time) -> (
            Log.info (fun m -> m "Processing turn for entity: %d" entity_id);
            let entity =
              try Some (Entity.EntityManager.find_unsafe entities entity_id)
              with _ ->
                Log.err (fun m -> m "Entity not found: %d" entity_id);
                None
            in
            match entity with
            | None -> loop backend
            | Some entity -> (
                match get_actor_safe backend.actor_manager entity with
                | None -> loop backend
                | Some actor -> (
                    if not (Actor.is_alive actor) then (
                      Log.info (fun m ->
                          m "Actor %d is dead. Removing from queue." entity_id);
                      remove_dead_actor turn_queue entity_id;
                      loop backend)
                    else if should_wait_for_player_input entity actor then (
                      Log.info (fun m ->
                          m "Player is awaiting input: %d" entity_id);
                      let new_backend =
                        { backend with mode = Mode.CtrlMode.WaitInput }
                      in
                      Turn_queue.schedule_turn turn_queue entity_id time;
                      new_backend)
                    else
                      match Actor.next_action actor with
                      | None ->
                          Log.info (fun m ->
                              m "No action for entity: %d. Rescheduling turn."
                                entity_id);
                          Turn_queue.schedule_turn turn_queue entity_id time;
                          loop backend
                      | Some action -> (
                          Log.info (fun m ->
                              m "Action for entity: %d. Executing..." entity_id);
                          (* Side effect: action may mutate game state via backend *)
                          match
                            action#execute (Backend.to_common_backend backend)
                          with
                          | Ok d_time ->
                              Turn_queue.schedule_turn turn_queue entity_id
                                (time + d_time);
                              loop backend
                          | Error e ->
                              Log.err (fun m ->
                                  m "Failed to perform action: %s"
                                    (Exn.to_string e));
                              let delay =
                                match entity.E.kind with
                                | E.Player -> 0
                                | _ -> monster_reschedule_delay
                              in
                              Turn_queue.schedule_turn turn_queue entity_id
                                (time + delay);
                              loop backend))))
      in
      loop backend
