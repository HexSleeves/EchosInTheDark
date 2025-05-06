open Base
open Entities
open State_types
open Worldgen.Generators
module Types = Types

type t = State_types.t [@@deriving show]

let create_default_state ~player_start em =
  let em = Spawner.spawn_player ~pos:player_start em in
  State_levels.setup_entities_for_level ~em ~turn_queue:(Turn_queue.create ())
    ~actor_manager:(Actor_manager.create ())
  |> fun (actor_manager, turn_queue) -> (em, actor_manager, turn_queue)

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

let get_chunk_manager (state : t) : Chunk_manager.t = state.chunk_manager

let set_chunk_manager (chunk_manager : Chunk_manager.t) (state : t) : t =
  { state with chunk_manager }

let get_tile_at (state : t) (world_pos : Chunk.world_pos) :
    Dungeon.Tile.t option =
  Chunk_manager.get_tile_at world_pos state.chunk_manager

let add_entity_to_index = State_entities.add_entity_to_index
let get_entity_at_pos = State_entities.get_entity_at_pos
let get_blocking_entity_at_pos = State_entities.get_blocking_entity_at_pos
let get_entities = State_entities.get_entities
let get_creatures = State_entities.get_creatures
let move_entity = State_entities.move_entity
let remove_entity = State_entities.remove_entity
let is_player = State_entities.is_player
let get_player_id = State_entities.get_player_id

(* let spawn_creature_entity = State_entities.spawn_creature_entity *)
let get_actor = State_actors.get_actor
let add_actor = State_actors.add_actor
let remove_actor = State_actors.remove_actor
let update_actor = State_actors.update_actor
let queue_actor_action = State_actors.queue_actor_action
let transition_to_next_level = State_levels.transition_to_next_level
let transition_to_previous_level = State_levels.transition_to_previous_level
let rebuild_position_index = State_entities.rebuild_position_index
let get_equipment = State_entities.get_equipment
let set_equipment = State_entities.set_equipment

let make ~debug ~w ~h ~seed ~depth =
  Logger.info (fun m -> m "Width: %d, Height: %d" w h);
  Logger.info (fun m -> m "Creating state with seed: %d" seed);

  let config = Worldgen.Config.make ~seed ~w:256 ~h:256 () in
  let em =
    World_generator.generate_world ~config ~depth ~em:(Entity_manager.create ())
  in

  (* Generate the first chunk and pick a player start position *)
  let chunk_coords = Types.Loc.make 0 0 in
  let chunk_path =
    Printf.sprintf "resources/chunks/%d/chunk_%d_%d.json" depth chunk_coords.x
      chunk_coords.y
  in
  let chunk = Chunk.load_chunk chunk_path in

  (* Find a floor tile for player start, fallback to (0,0) *)
  let player_start =
    let width = Array.length chunk.tiles.(0) in
    let height = Array.length chunk.tiles in
    let rng = Random.State.make [| seed |] in
    let loc =
      Worldgen.Worldgen_utils.find_random_floor
        (Array.concat (Array.to_list chunk.tiles))
        ~width ~height ~rng
    in
    Logger.info (fun m -> m "[SPAWN] Player starting at (%d, %d)" loc.x loc.y);
    loc
  in

  (* Set up actor manager and turn queue *)
  let em, actor_manager, turn_queue = create_default_state ~player_start em in

  Turn_queue.print_turn_queue turn_queue;
  Entity_manager.print_entities em;

  let chunk_managers = Base.Hashtbl.create (module Int) in
  let chunk_manager, em =
    Chunk_manager.set_loaded_chunk chunk_coords chunk
      (Chunk_manager.create ~world_seed:seed ~level:(Int.to_string depth))
    |> Chunk_manager.tick em player_start ~depth
  in

  Base.Hashtbl.set chunk_managers ~key:0 ~data:chunk_manager;
  let state =
    {
      debug;
      depth;
      em;
      actor_manager;
      turn_queue;
      chunk_manager;
      chunk_managers;
      mode = Types.CtrlMode.Normal;
      position_index = Base.Hashtbl.create (module Types.Loc);
    }
  in
  State_utils.rebuild_position_index state
