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

(** Generate a map for a specific [level] within [total_levels] using [config].
*)
let generate ~(config : Config.t) ~(level : int) ~(total_levels : int) :
    Tilemap.t =
  (* Vary seed per level for unique layouts *)
  let seed = config.seed + level in
  let rng = Random.State.make [| seed |] in

  (* Run cellular automata to get raw grid *)
  let grid = CA.run ~width:config.width ~height:config.height ~rng in

  let width = config.width in
  let height = config.height in

  let player_start =
    if level = 1 then find_random_floor grid ~width ~height ~rng
    else Types.Loc.make 0 0
    (* Will be set to stairs_up for non-first levels *)
  in

  let stairs_up = if level = 1 then None else Some player_start in

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
