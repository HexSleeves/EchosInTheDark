open Base
open Rl_types

type t = State.t

let make ~debug ~w ~h ~seed ~depth : t =
  (* Initialize systems *)
  Systems.Log_system.init ();
  Systems.Combat_system.init ();
  Systems.Item_system.init ();

  (* Initialize performance optimization systems *)
  try
    Profiler.init ();
    Systems.Packed_system.init ();
    State.make ~debug ~w ~h ~seed ~depth
  with e ->
    Core_log.warn (fun m ->
        m "Failed to initialize performance systems: %s" (Exn.to_string e));

    State.make ~debug ~w ~h ~seed ~depth

let get_debug (state : t) : bool = State.get_debug state
let get_mode (state : t) = State.get_mode state
let set_mode mode (state : t) : t = State.set_mode mode state

(* Entity *)
let get_player_id (state : t) = State.get_player_id state
let get_entities (state : t) = State.get_entities state

(* Chunk *)
let get_chunk_manager (state : t) : Chunk_manager.t =
  State.get_chunk_manager state

let queue_actor_action (state : t) (actor_id : Actor.actor_id)
    (action : Action.t) : t =
  State.queue_actor_action state actor_id action |> fun state ->
  State.set_turn_queue
    (Turn_queue.schedule_now (State.get_turn_queue state) actor_id)
    state

let move_entity (id : int) (position : Components.Position.t) (state : t) : t =
  State.move_entity id position state

let process_turns (state : t) : t =
  (* Run performance reporting if needed *)
  (try Profiler.Performance_profiler.generate_report () with _ -> ());

  Systems.Turn_system.process_turns state

let run_ai_step (state : t) : t =
  List.fold (State.get_creatures state) ~init:state
    ~f:(fun state' creature_id ->
      match State.get_actor state' creature_id with
      | Some actor when Option.is_none (Actor.peek_next_action actor) ->
          Ai.Wander.decide creature_id state'
          |> queue_actor_action state' creature_id
      | _ -> state')
  |> fun state -> State.set_normal_mode state

let sync_from_hashtables () = Systems.Packed_system.sync_from_hashtables ()
let sync_to_hashtables () = Systems.Packed_system.sync_to_hashtables ()
