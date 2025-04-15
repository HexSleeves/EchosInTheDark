open Base
module B = Backend
module Log = Backend.Log
module E = Entity

(* Create a player actor *)
let create_player_actor = Actor.create ~speed:100

(* Create a rat actor *)
let create_rat_actor = Actor.create ~speed:110

(* Create a goblin actor *)
let create_goblin_actor = Actor.create ~speed:150

(* Initialize the turn system with a player and monsters *)
let initialize_turn_system =
  let queue = Turn_queue.create () in
  queue

let rec process_turns (backend : B.t) (turn_queue : Turn_queue.t)
    (entities : Entity.EntityManager.t) : B.t =
  Turn_queue.print_queue turn_queue;

  if phys_equal backend.mode Mode.CtrlMode.WaitInput then (
    (Log.info @@ fun m -> m "Waiting for player input");
    backend)
  else
    let rec loop (backend : B.t) =
      match Turn_queue.get_next_actor turn_queue with
      | None -> backend
      | Some (entity_id, time) -> (
          (Log.info @@ fun m -> m "Processing turn for entity: %d" entity_id);
          let entity = Entity.EntityManager.find_unsafe entities entity_id in

          let actor =
            match entity.data with
            | Entity.PlayerData { actor_id; _ }
            | Entity.CreatureData { actor_id; _ } ->
                Actor_manager.get_unsafe backend.actor_manager actor_id
            | _ -> failwith "Actor not found"
          in

          if not (Actor.is_alive actor) then (
            ( Log.info @@ fun m ->
              m "Actor is dead. Why is it still in the queue?" );
            loop backend)
          else
            let is_player = phys_equal entity.kind E.Player in
            let has_action = Option.is_some (Actor.peek_next_action actor) in

            (* Print player actor *)
            Logs.info (fun m -> m "Player actor has action: %b" has_action);

            (* Player is waiting for input *)
            if is_player && not has_action then (
              (Log.info @@ fun m -> m "Player is awaiting input: %d" entity_id);
              let new_backend =
                { backend with mode = Mode.CtrlMode.WaitInput }
              in
              Turn_queue.schedule_turn turn_queue entity_id time;
              new_backend)
            else
              match Actor.next_action actor with
              | None ->
                  ( Log.info @@ fun m ->
                    m "No action for entity: %d. Rescheduling turn." entity_id
                  );
                  Turn_queue.schedule_turn turn_queue entity_id time;
                  loop backend
              | Some action -> (
                  Logs.info (fun m ->
                      m "Action for entity: %d. Executing..." entity_id);

                  match action#execute (Backend.to_common_backend backend) with
                  | Ok d_time ->
                      Turn_queue.schedule_turn turn_queue entity_id
                        (time + d_time);
                      loop backend
                  | Error e ->
                      ( Log.err @@ fun m ->
                        m "Failed to perform action: %s" (Exn.to_string e) );
                      if is_player then
                        Turn_queue.schedule_turn turn_queue entity_id time
                      else
                        Turn_queue.schedule_turn turn_queue entity_id
                          (time + 100);
                      loop backend))
    in
    loop backend
