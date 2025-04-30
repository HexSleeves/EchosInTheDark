open Base

let cartesian_product xs ys =
  List.concat_map xs ~f:(fun x -> List.map ys ~f:(fun y -> (x, y)))

let random_choice lst ~rng =
  Rl_utils.Utils.list_nth_opt lst (Random.State.int rng (List.length lst))

let range a b = List.init (b - a) ~f:(( + ) a)

let pick_random lst ~rng ~(n : int) =
  let sorted = List.take (List.rev lst) n in
  Rl_utils.Utils.list_nth_opt sorted (Random.State.int rng (List.length sorted))

let find_random_floor grid ~width ~height ~rng =
  let rec pick () =
    let x = 1 + Random.State.int rng (width - 2) in
    let y = 1 + Random.State.int rng (height - 2) in
    match Rl_utils.Utils.xy_to_index_opt x y width height with
    | Some idx -> (
        match Rl_utils.Utils.array_get_opt grid idx with
        | Some tile when Dungeon.Tile.is_floor tile -> Types.Loc.make x y
        | _ -> pick ())
    | None -> pick ()
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
  if sx >= 0 && sx < width && sy >= 0 && sy < height then (
    visited.(sx).(sy) <- true;
    dist.(sx).(sy) <- 0;
    enqueue q (sx, sy));

  let farthest = ref [ (sx, sy) ] in
  let max_dist = ref 0 in
  while not (is_empty q) do
    let x, y = dequeue_exn q in
    let d =
      if x >= 0 && x < width && y >= 0 && y < height then dist.(x).(y) else -1
    in
    if d > !max_dist then (
      max_dist := d;
      farthest := [ (x, y) ])
    else if d = !max_dist then farthest := (x, y) :: !farthest;
    List.iter
      (neighbors (x, y) width height)
      ~f:(fun (nx, ny) ->
        match Rl_utils.Utils.xy_to_index_opt nx ny width height with
        | Some idx -> (
            if
              (nx >= 0 && nx < width && ny >= 0 && ny < height)
              && not visited.(nx).(ny)
            then
              match Rl_utils.Utils.array_get_opt grid idx with
              | Some tile when Dungeon.Tile.is_floor tile ->
                  visited.(nx).(ny) <- true;
                  dist.(nx).(ny) <- d + 1;
                  enqueue q (nx, ny)
              | _ -> ())
        | None -> ())
  done;
  (!max_dist, !farthest)

let carve_path ~tile ~length ~rng grid ~width ~height =
  let rec walk n x y =
    if n = 0 then ()
    else
      match Rl_utils.Utils.xy_to_index_opt x y width height with
      | Some idx when idx >= 0 && idx < Array.length grid ->
          (match Rl_utils.Utils.array_get_opt grid idx with
          | Some t when Dungeon.Tile.is_floor t -> grid.(idx) <- tile
          | _ -> ());
          let dirs = [ (1, 0); (-1, 0); (0, 1); (0, -1) ] in
          let dx, dy =
            match Rl_utils.Utils.list_nth_opt dirs (Random.State.int rng 4) with
            | Some (dx, dy) -> (dx, dy)
            | None -> (0, 0)
          in
          let nx = Int.max 1 (Int.min (x + dx) (width - 2)) in
          let ny = Int.max 1 (Int.min (y + dy) (height - 2)) in
          walk (n - 1) nx ny
      | _ -> ()
  in
  let x = 1 + Random.State.int rng (width - 2) in
  let y = 1 + Random.State.int rng (height - 2) in
  walk length x y

(* Placeholder for noise function - replace with actual library call *)
let get_noise_value (rng : Random.State.t) (_world_x : int) (_world_y : int) :
    float =
  Random.State.float rng 1.0
