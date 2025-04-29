open Base
open State_types

type t = State_types.t

let add_entity_to_index = State_entities.add_entity_to_index
let get_entities_manager = State_entities.get_entities_manager
let set_entities_manager = State_entities.set_entities_manager
let get_player_id = State_entities.get_player_id
let get_entity_at_pos = State_entities.get_entity_at_pos
let get_blocking_entity_at_pos = State_entities.get_blocking_entity_at_pos
let get_entities = State_entities.get_entities
let get_creatures = State_entities.get_creatures
let move_entity = State_entities.move_entity
let remove_entity = State_entities.remove_entity

(* let spawn_creature_entity = State_entities.spawn_creature_entity *)
let get_actor = State_actors.get_actor
let add_actor = State_actors.add_actor
let remove_actor = State_actors.remove_actor
let update_actor = State_actors.update_actor
let queue_actor_action = State_actors.queue_actor_action
let setup_entities_for_level = State_levels.setup_entities_for_level
let transition_to_next_level = State_levels.transition_to_next_level
let transition_to_previous_level = State_levels.transition_to_previous_level
let rebuild_position_index = State_entities.rebuild_position_index
let get_equipment = State_entities.get_equipment
let set_equipment = State_entities.set_equipment

let make ~debug ~w ~h ~seed ~current_level =
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);

  let actor_manager = Actors.Actor_manager.create () in
  let turn_queue = Turn_queue.create () in

  let config = Mapgen.Config.make ~seed ~w ~h () in
  let map_manager = Map_manager.create ~config ~current_level in

  (* Extract player_id from the first level's entity manager *)
  let entities = Map_manager.get_entities_by_level map_manager current_level in
  let player_id =
    Entities.Entity_manager.find_player_id entities
    |> Option.value_exn
         ~message:"No player entity found in first level entity manager"
  in

  let actor_manager, turn_queue =
    setup_entities_for_level ~entities ~actor_manager ~turn_queue
  in

  let position_index = Base.Hashtbl.create (module Types.Loc) in
  Entities.Entity_manager.to_list entities
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | Some pos -> Base.Hashtbl.set position_index ~key:pos ~data:entity_id
         | None -> ());

  let state =
    {
      debug;
      entities;
      actor_manager;
      turn_queue;
      map_manager;
      player_id;
      position_index;
      mode = Types.CtrlMode.Normal;
    }
  in
  State_utils.rebuild_position_index state

let get_debug (state : t) : bool = state.debug
let get_mode (state : t) : Types.CtrlMode.t = state.mode
let set_mode (mode : Types.CtrlMode.t) (state : t) : t = { state with mode }

let set_normal_mode (state : t) : t =
  { state with mode = Types.CtrlMode.Normal }

let set_wait_input_mode (state : t) : t =
  { state with mode = Types.CtrlMode.WaitInput }

let get_turn_queue (state : t) : Turn_queue.t = state.turn_queue

let set_turn_queue (turn_queue : Turn_queue.t) (state : t) : t =
  { state with turn_queue }

let get_current_map (state : t) : Dungeon.Tilemap.t option =
  Map_manager.get_current_map state.map_manager
