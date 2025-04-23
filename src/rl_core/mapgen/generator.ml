(* Mapgen modules *)
module CA = Ca
module Tile = Map.Tile
module Config = Config
module Tilemap = Map.Tilemap
open Base

let find_random_floor grid ~width ~height ~rng =
  let rec pick () =
    let x = 1 + Random.State.int rng (width - 2) in
    let y = 1 + Random.State.int rng (height - 2) in
    let idx = x + (y * width) in
    if Tile.is_floor grid.(idx) then Types.Loc.make x y else pick ()
  in
  pick ()

let neighbors (x, y) width height =
  List.filter
    ~f:(fun (nx, ny) -> nx >= 0 && ny >= 0 && nx < width && ny < height)
    [ (x - 1, y); (x + 1, y); (x, y - 1); (x, y + 1) ]

let bfs_farthest grid ~width ~height ~(start : Types.Loc.t) =
  let open Queue in
  let visited = Array.make_matrix ~dimx:width ~dimy:height false in
  let dist = Array.make_matrix ~dimx:width ~dimy:height (-1) in
  let q = create () in

  let sx, sy = (start.x, start.y) in
  visited.(sx).(sy) <- true;
  dist.(sx).(sy) <- 0;
  enqueue q (sx, sy);

  let farthest = ref [ (sx, sy) ] in
  let max_dist = ref 0 in
  while not (is_empty q) do
    let x, y = dequeue_exn q in
    let d = dist.(x).(y) in
    if d > !max_dist then (
      max_dist := d;
      farthest := [ (x, y) ])
    else if d = !max_dist then farthest := (x, y) :: !farthest;
    List.iter
      (neighbors (x, y) width height)
      ~f:(fun (nx, ny) ->
        let idx = nx + (ny * width) in
        if (not visited.(nx).(ny)) && Tile.is_floor grid.(idx) then (
          visited.(nx).(ny) <- true;
          dist.(nx).(ny) <- d + 1;
          enqueue q (nx, ny)))
  done;
  (!max_dist, !farthest)

let pick_random lst ~rng ~(n : int) =
  let sorted = List.take (List.rev lst) n in
  List.nth_exn sorted (Random.State.int rng (List.length sorted))

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
      let o = overlay.(i) in
      if is_special_tile t then t else if Tile.equal o Tile.Wall then t else o)

let rec run_algorithm (algo : algorithm) ~width ~height ~rng =
  match algo with
  | Prefab filename -> Prefab.load_prefab filename ~width ~height
  | CA -> CA.run ~width ~height ~rng
  | Rooms -> Rooms.rooms_generator ~width ~height ~rng
  | Blend algos -> (
      match algos with
      | [] -> CA.run ~width ~height ~rng
      | first :: rest ->
          let base = run_algorithm first ~width ~height ~rng in
          List.fold_left rest ~init:base ~f:(fun acc a ->
              let overlay = run_algorithm a ~width ~height ~rng in
              blend_grids acc overlay))

(** Generate a map for a specific [level] within [total_levels] using [config].
*)
let generate ~(config : Config.t) ~(level : int) : Tilemap.t =
  let seed = config.seed + level in
  let rng = Random.State.make [| seed |] in
  let total_levels = config.max_levels in
  let width = config.width in
  let height = config.height in

  (* Select algorithm per level *)
  let grid =
    if level = 1 then
      run_algorithm (Prefab "resources/prefabs/level1.txt") ~width ~height ~rng
    else run_algorithm (Blend [ CA; Rooms ]) ~width ~height ~rng
  in

  if level <> 1 then (
    (* --- Add environmental features: rivers and chasms --- *)
    let carve_path ~tile ~length ~rng grid ~width ~height =
      let x = 1 + Random.State.int rng (width - 2) in
      let y = 1 + Random.State.int rng (height - 2) in
      let rec walk n x y =
        if n = 0 then ()
        else
          let idx = x + (y * width) in
          if Tile.is_floor grid.(idx) then grid.(idx) <- tile;
          let dirs = [ (1, 0); (-1, 0); (0, 1); (0, -1) ] in
          let dx, dy = List.nth_exn dirs (Random.State.int rng 4) in
          let nx = Int.max 1 (Int.min (x + dx) (width - 2)) in
          let ny = Int.max 1 (Int.min (y + dy) (height - 2)) in
          walk (n - 1) nx ny
      in
      walk length x y
    in
    (* Chance to generate a river *)
    Core_log.info (fun m -> m "Generating rivers...");
    let river_roll = Random.State.float rng 1.0 in
    if Float.compare river_roll 0.5 < 0 then
      carve_path ~tile:Tile.River ~length:(width + height) ~rng grid ~width
        ~height;

    (* Chance to generate a chasm *)
    Core_log.info (fun m -> m "Generating chasms...");
    let chasm_roll = Random.State.float rng 1.0 in
    if Float.compare chasm_roll 0.3 < 0 then
      carve_path ~tile:Tile.Chasm
        ~length:((width / 2) + (height / 2))
        ~rng grid ~width ~height;

    (* --- Add traps --- *)
    Core_log.info (fun m -> m "Generating traps...");
    let trap_count = width * height / 100 in
    let placed = ref 0 in
    while !placed < trap_count do
      let x = 1 + Random.State.int rng (width - 2) in
      let y = 1 + Random.State.int rng (height - 2) in
      let idx = x + (y * width) in
      if Tile.is_floor grid.(idx) then (
        grid.(idx) <- Tile.Trap;
        Int.incr placed)
    done;

    (* --- Add secret doors --- *)
    Core_log.info (fun m -> m "Generating secret doors...");
    let secret_door_count = (width + height) / 20 in
    let placed = ref 0 in
    while !placed < secret_door_count do
      let x = 1 + Random.State.int rng (width - 2) in
      let y = 1 + Random.State.int rng (height - 2) in
      let idx = x + (y * width) in
      if Tile.equal grid.(idx) Tile.Wall then
        let neighbors = [ (x - 1, y); (x + 1, y); (x, y - 1); (x, y + 1) ] in
        let floor_neighbors =
          List.filter neighbors ~f:(fun (nx, ny) ->
              nx >= 0 && nx < width && ny >= 0 && ny < height
              && Tile.is_floor grid.(nx + (ny * width)))
        in
        if List.length floor_neighbors >= 2 then (
          grid.(idx) <- Tile.Secret_door;
          Int.incr placed)
    done);

  (* --- End environmental features --- *)
  Core_log.info (fun m -> m "Generating map for level %d" level);

  let random_floor = find_random_floor grid ~width ~height ~rng in
  let stairs_up = if level = 1 then None else Some random_floor in
  let player_start =
    if level = 1 then random_floor
    else
      match stairs_up with
      | Some loc -> loc
      | None -> failwith "No stairs up found"
  in

  (* Find farthest walkable tiles from player_start *)
  let _, farthest = bfs_farthest grid ~width ~height ~start:player_start in

  let stairs_down =
    if level = total_levels then None
    else
      let x, y = pick_random farthest ~rng ~n:3 in
      Some (Types.Loc.make x y)
  in

  (* Place stairs tiles in the grid *)
  (match stairs_up with
  | Some loc -> grid.((loc.y * width) + loc.x) <- Tile.Stairs_up
  | None -> ());
  (match stairs_down with
  | Some loc -> grid.((loc.y * width) + loc.x) <- Tile.Stairs_down
  | None -> ());

  (* Construct Tilemap record *)
  {
    Tilemap.seed;
    Tilemap.width;
    Tilemap.height;
    Tilemap.map = grid;
    Tilemap.player_start;
    Tilemap.stairs_up;
    Tilemap.stairs_down;
  }
