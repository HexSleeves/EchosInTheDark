open Base
open State_types

type t = State_types.t

let create_default_state () =
  Entities.Entity_manager.create () |> fun entities ->
  State_levels.setup_entities_for_level ~entities
    ~turn_queue:(Turn_queue.create ())
    ~actor_manager:(Actors.Actor_manager.create ())
  |> fun (actor_manager, turn_queue) -> (actor_manager, turn_queue, entities)

let make ~debug ~w ~h ~seed ~depth =
  Core_log.info (fun m -> m "Width: %d, Height: %d" w h);
  Core_log.info (fun m -> m "Creating state with seed: %d" seed);

  (* Generate the first chunk and pick a player start position *)
  let chunk_coords = Types.Loc.make 0 0 in
  let chunk =
    Mapgen.Chunk_generator.generate chunk_coords ~world_seed:seed ~depth
  in
  let chunk_manager =
    Chunk_manager.set_loaded_chunk chunk_coords chunk
      (Chunk_manager.create ~world_seed:seed)
  in

  (* Find a floor tile for player start, fallback to (0,0) *)
  let player_start =
    let found =
      let open Option in
      let rec search y =
        if y >= Array.length chunk.tiles then None
        else
          let row = chunk.tiles.(y) in
          let rec search_row x =
            if x >= Array.length row then search (y + 1)
            else if Dungeon.Tile.is_floor row.(x) then Some (Types.Loc.make x y)
            else search_row (x + 1)
          in
          search_row 0
      in
      search 0
    in
    Option.value found ~default:(Types.Loc.make 0 0)
  in

  (* Spawn the player at the chosen position *)
  let entities = Entities.Entity_manager.create () in
  let entities = Entities.Spawner.spawn_player ~pos:player_start entities in
  let player_id =
    Entities.Entity_manager.find_player_id entities |> Option.value_exn
  in

  (* Set up actor manager and turn queue *)
  let actor_manager, turn_queue =
    State_levels.setup_entities_for_level ~entities
      ~turn_queue:(Turn_queue.create ())
      ~actor_manager:(Actors.Actor_manager.create ())
  in

  let chunk_manager = Chunk_manager.tick ~depth player_start chunk_manager in
  let chunk_managers = Base.Hashtbl.create (module Int) in
  Base.Hashtbl.set chunk_managers ~key:0 ~data:chunk_manager;

  let position_index = Base.Hashtbl.create (module Types.Loc) in
  Entities.Entity_manager.to_list entities
  |> List.iter ~f:(fun entity_id ->
         match Components.Position.get entity_id with
         | Some pos -> Base.Hashtbl.set position_index ~key:pos ~data:entity_id
         | None -> ());

  let state =
    {
      debug;
      depth;
      entities;
      actor_manager;
      turn_queue;
      chunk_manager;
      chunk_managers;
      position_index;
      player_id;
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

let get_chunk_manager (state : t) : Chunk_manager.t = state.chunk_manager

let get_tile_at (state : t) (world_pos : Types.world_pos) :
    Dungeon.Tile.t option =
  Chunk_manager.get_tile_at world_pos state.chunk_manager

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
let transition_to_next_level = State_levels.transition_to_next_level
let transition_to_previous_level = State_levels.transition_to_previous_level
let rebuild_position_index = State_entities.rebuild_position_index
let get_equipment = State_entities.get_equipment
let set_equipment = State_entities.set_equipment
