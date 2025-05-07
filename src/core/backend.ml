open Base
open Types

type t = { state : State.t }

let make ~debug ~w ~h ~seed ~depth () : t =
  (* Initialize systems *)
  Systems.init ();

  (* This now initializes Log_system and Combat_system *)

  (* Initialize performance optimization systems *)
  let state =
    try State.make ~debug ~w ~h ~seed ~depth
    with e ->
      Logger.warn (fun m ->
          m "Failed to initialize performance systems: %s" (Exn.to_string e));

      State.make ~debug ~w ~h ~seed ~depth
  in

  { state }

let get_console_messages : string list = Console.get_console_messages ()
let get_debug (backend : t) : bool = State.get_debug backend.state
let get_mode (backend : t) = State.get_mode backend.state

let set_mode mode (backend : t) : t =
  { state = State.set_mode mode backend.state }

(* Entity *)
let get_player_id (backend : t) = State.get_player_id backend.state
let get_entities (backend : t) = State.get_entities backend.state

(* Chunk *)
let get_chunk_manager (backend : t) : Chunk_manager.t =
  State.get_chunk_manager backend.state

(* Queue an action for an actor *)
let queue_actor_action (backend : t) (actor_id : Actor.actor_id)
    (action : Action.t) : t =
  let new_state = State.queue_actor_action backend.state actor_id action in
  let new_state =
    State.set_turn_queue
      (Turn_queue.schedule_now (State.get_turn_queue new_state) actor_id)
      new_state
  in
  { state = new_state }

(* Process turns using the appropriate approach based on configuration *)
let process_turns (backend : t) : t =
  { state = Effect_systems.process_turns backend.state }

(* Run an AI step *)
let run_ai_step (backend : t) : t =
  Logs.info (fun m -> m "Running AI step");
  let new_state =
    List.fold (State.get_creatures backend.state) ~init:backend.state
      ~f:(fun state' creature_id ->
        match State.get_actor state' creature_id with
        | Some actor when Option.is_none (Actor.peek_next_action actor) ->
            let action = Ai.Wander.decide creature_id state' in
            let new_state =
              State.queue_actor_action state' creature_id action
            in
            State.set_turn_queue
              (Turn_queue.schedule_now
                 (State.get_turn_queue new_state)
                 creature_id)
              new_state
        | _ -> state')
  in
  let new_state = State.set_normal_mode new_state in
  { state = new_state }
