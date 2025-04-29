(* Mapgen modules *)
open Base
open Entities
open Dungeon

(* Algorithm type for map generation *)
type algorithm =
  | CA
  | Rooms
  | Blend of algorithm list
  | Prefab of string (* filename *)

let is_special_tile = function
  | Tile.Stairs_up | Tile.Stairs_down -> true
  | _ -> false

let blend_grids (base : Tile.t array) (overlay : Tile.t array) : Tile.t array =
  Array.mapi base ~f:(fun i t ->
      match Rl_utils.Utils.array_get_opt overlay i with
      | Some o ->
          if is_special_tile t then t
          else if Tile.equal o Tile.Wall then t
          else o
      | None -> t)

let rec run_algorithm (algo : algorithm) ~width ~height ~rng ~depth ~entities =
  match algo with
  | Prefab filename -> (Prefab.load_prefab filename ~width ~height, entities, [])
  | CA ->
      let grid = Ca.run ~width ~height ~rng in
      let entity_manager =
        Ca.place_monsters ~grid ~width ~height ~rng entities
      in
      (grid, entity_manager, [])
  | Rooms ->
      Logs.info (fun m -> m "Generating rooms");
      let grid, rooms = Rooms.rooms_generator ~width ~height ~rng in
      let entity_manager =
        Rooms.place_monsters ~grid ~width ~rooms ~rng ~depth entities
      in
      (grid, entity_manager, rooms)
  | Blend algos -> (
      match algos with
      | [] -> (Ca.run ~width ~height ~rng, entities, [])
      | first :: rest ->
          let base_grid, base_entities, base_rooms =
            run_algorithm first ~width ~height ~rng ~depth ~entities
          in
          List.fold_left rest ~init:(base_grid, base_entities, base_rooms)
            ~f:(fun (acc_grid, acc_entities, acc_rooms) a ->
              let overlay_grid, _overlay_entities, overlay_rooms =
                run_algorithm a ~width ~height ~rng ~depth ~entities
              in
              ( blend_grids acc_grid overlay_grid,
                acc_entities,
                acc_rooms @ overlay_rooms )))

let generate_water ~width ~height ~rng grid =
  Util.carve_path ~tile:Tile.Water ~length:(width + height) ~rng ~width ~height
    grid

let generate_chasm ~width ~height ~rng grid =
  Util.carve_path ~tile:Tile.Chasm
    ~length:((width / 2) + (height / 2))
    ~rng grid ~width ~height

let generate_traps ~width ~height ~rng grid =
  let trap_count = width * height / 100 in
  let rec place_traps placed =
    if placed >= trap_count then ()
    else
      let x = 1 + Random.State.int rng (width - 2) in
      let y = 1 + Random.State.int rng (height - 2) in
      match Rl_utils.Utils.xy_to_index_opt x y width height with
      | Some idx when idx >= 0 && idx < Array.length grid -> (
          match Rl_utils.Utils.array_get_opt grid idx with
          | Some t when Tile.is_floor t ->
              grid.(idx) <- Tile.Trap;
              place_traps (placed + 1)
          | _ -> place_traps placed)
      | _ -> place_traps placed
  in

  place_traps 0

let generate_secret_doors ~width ~height ~rng grid =
  let secret_door_count = (width + height) / 20 in
  let rec place_secret_doors placed =
    if placed >= secret_door_count then ()
    else
      let x = 1 + Random.State.int rng (width - 2) in
      let y = 1 + Random.State.int rng (height - 2) in
      match Rl_utils.Utils.xy_to_index_opt x y width height with
      | Some idx when idx >= 0 && idx < Array.length grid -> (
          match Rl_utils.Utils.array_get_opt grid idx with
          | Some t when Tile.equal t Tile.Wall ->
              let neighbors =
                [ (x - 1, y); (x + 1, y); (x, y - 1); (x, y + 1) ]
              in
              let floor_neighbors =
                List.filter neighbors ~f:(fun (nx, ny) ->
                    match Rl_utils.Utils.xy_to_index_opt nx ny width height with
                    | Some nidx -> (
                        nx >= 0 && nx < width && ny >= 0 && ny < height
                        &&
                        match Rl_utils.Utils.array_get_opt grid nidx with
                        | Some t -> Tile.is_floor t
                        | None -> false)
                    | None -> false)
              in
              if List.length floor_neighbors >= 2 then (
                grid.(idx) <- Tile.Secret_door;
                place_secret_doors (placed + 1))
              else place_secret_doors placed
          | _ -> place_secret_doors placed)
      | _ -> place_secret_doors placed
  in
  place_secret_doors 0

(** Generate a map for a specific [level] within [total_levels] using [config].
*)
let generate ~(config : Config.t) ~(level : int) =
  let seed = config.seed + level in
  let rng = Random.State.make [| seed |] in

  let width = config.width in
  let height = config.height in
  let total_levels = config.max_levels in

  let entities = Entity_manager.create () in

  Core_log.info (fun m -> m "Generating map for level %d" level);

  (* Select algorithm per level *)
  let grid, entity_manager, rooms =
    match level with
    | 1 ->
        run_algorithm (Prefab "resources/prefabs/level1.txt") ~width ~height
          ~rng ~depth:level ~entities
    | _ ->
        run_algorithm (Blend [ CA ]) (* (Blend [ CA; Rooms ]) *)
          ~width ~height ~rng ~depth:level ~entities
  in

  let () =
    if level <> 1 then (
      let water_roll = Random.State.float rng 1.0 in
      let chasm_roll = Random.State.float rng 1.0 in

      if Float.compare water_roll 0.5 < 0 then
        generate_water ~width ~height ~rng grid;
      if Float.compare chasm_roll 0.3 < 0 then
        generate_chasm ~width ~height ~rng grid
      (* generate_traps ~width ~height ~rng grid; *)
      (* generate_secret_doors ~width ~height ~rng grid *))
  in

  let random_floor = Util.find_random_floor grid ~width ~height ~rng in
  let stairs_up = Option.some_if (level <> 1) random_floor in
  let player_start =
    match stairs_up with Some loc -> loc | None -> random_floor
  in

  let entity_manager =
    match level with
    | 1 -> Spawner.spawn_player entity_manager ~pos:player_start
    | _ -> entity_manager
  in

  let _, farthest = Util.bfs_farthest grid ~width ~height ~start:player_start in
  let stairs_down =
    Option.some_if (level <> total_levels)
      (match Util.pick_random farthest ~rng ~n:3 with
      | Some (x, y) -> Types.Loc.make x y
      | None -> random_floor)
  in

  Option.iter stairs_up ~f:(fun loc ->
      match Rl_utils.Utils.xy_to_index_opt loc.x loc.y width height with
      | Some idx when idx >= 0 && idx < Array.length grid ->
          grid.(idx) <- Tile.Stairs_up
      | _ -> ());
  Option.iter stairs_down ~f:(fun loc ->
      match Rl_utils.Utils.xy_to_index_opt loc.x loc.y width height with
      | Some idx when idx >= 0 && idx < Array.length grid ->
          grid.(idx) <- Tile.Stairs_down
      | _ -> ());

  let tilemap =
    {
      Tilemap.seed;
      Tilemap.width;
      Tilemap.height;
      Tilemap.map = grid;
      Tilemap.player_start;
      Tilemap.stairs_up;
      Tilemap.stairs_down;
    }
  in

  (tilemap, entity_manager, rooms)
