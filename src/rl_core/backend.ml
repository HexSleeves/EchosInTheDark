open Base
open Rl_types

(* Configuration for the backend *)
type config = { use_effects : bool; use_hybrid : bool; use_unified : bool }

(* Default configuration *)
let default_config =
  { use_effects = false; use_hybrid = false; use_unified = false }

type t = { state : State.t; config : config }

let make ?(config = default_config) ~debug ~w ~h ~seed ~depth () : t =
  (* Initialize systems *)
  Systems.Log_system.init ();
  Systems.Combat_system.init ();
  Systems.Item_system.init ();

  (* Initialize performance optimization systems *)
  let state =
    try State.make ~debug ~w ~h ~seed ~depth
    with e ->
      Core_log.warn (fun m ->
          m "Failed to initialize performance systems: %s" (Exn.to_string e));

      State.make ~debug ~w ~h ~seed ~depth
  in

  { state; config }

let get_debug (backend : t) : bool = State.get_debug backend.state
let get_mode (backend : t) = State.get_mode backend.state

let set_mode mode (backend : t) : t =
  { backend with state = State.set_mode mode backend.state }

(* Entity *)
let get_player_id (backend : t) = State.get_player_id backend.state
let get_entities (backend : t) = State.get_entities backend.state

(* Chunk *)
let get_chunk_manager (backend : t) : Chunk_manager.t =
  State.get_chunk_manager backend.state

let queue_actor_action (backend : t) (actor_id : Actor.actor_id)
    (action : Action.t) : t =
  let new_state = State.queue_actor_action backend.state actor_id action in
  let new_state =
    State.set_turn_queue
      (Turn_queue.schedule_now (State.get_turn_queue new_state) actor_id)
      new_state
  in
  { backend with state = new_state }

let move_entity (id : int) (position : Components.Position.t) (backend : t) : t
    =
  { backend with state = State.move_entity id position backend.state }

(* Process turns using the traditional approach *)
let process_turns_traditional (backend : t) : t =
  { backend with state = Systems.Turn_system.process_turns backend.state }

(* Process turns using the effect-based approach *)
let process_turns_with_effects (backend : t) : t =
  {
    backend with
    state =
      Effect_integrations.Effect_turn_system_integration.process_turns
        backend.state;
  }

(* Process turns using the hybrid approach (gradual adoption) *)
let process_turns_hybrid (backend : t) : t =
  {
    backend with
    state =
      Effect_integrations.Effect_turn_system_integration.process_turns_hybrid
        backend.state;
  }

(* Process turns using the unified effect system *)
let process_turns_unified (backend : t) : t =
  let module ESI = Effect_integrations.Effect_systems_integration in
  { backend with state = ESI.process_turns backend.state }

(* Process turns using the appropriate approach based on configuration *)
let process_turns (backend : t) : t =
  if backend.config.use_effects then
    if backend.config.use_hybrid then process_turns_hybrid backend
    else if backend.config.use_unified then process_turns_unified backend
    else process_turns_with_effects backend
  else process_turns_traditional backend

(* Get the configuration *)
let get_config (backend : t) : config = backend.config

(* Check if effects are enabled *)
let config_use_effects (config : config) : bool = config.use_effects

(* Check if hybrid mode is enabled *)
let config_use_hybrid (config : config) : bool = config.use_hybrid

(* Check if unified mode is enabled *)
let config_use_unified (config : config) : bool = config.use_unified

(* Enable effect handlers *)
let enable_effects (backend : t) : t =
  {
    backend with
    config = { use_effects = true; use_hybrid = false; use_unified = false };
  }

(* Enable hybrid mode (gradual adoption) *)
let enable_hybrid (backend : t) : t =
  {
    backend with
    config = { use_effects = true; use_hybrid = true; use_unified = false };
  }

(* Enable unified mode *)
let enable_unified (backend : t) : t =
  {
    backend with
    config = { use_effects = true; use_hybrid = false; use_unified = true };
  }

(* Disable effect handlers *)
let disable_effects (backend : t) : t =
  {
    backend with
    config = { use_effects = false; use_hybrid = false; use_unified = false };
  }

let run_ai_step (backend : t) : t =
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
  { backend with state = new_state }
