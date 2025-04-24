open Base

let cartesian_product xs ys =
  List.concat_map xs ~f:(fun x -> List.map ys ~f:(fun y -> (x, y)))

let random_choice lst ~rng =
  List.nth_exn lst (Random.State.int rng (List.length lst))

let range a b = List.init (b - a) ~f:(( + ) a)

let pick_random lst ~rng ~(n : int) =
  let sorted = List.take (List.rev lst) n in
  List.nth_exn sorted (Random.State.int rng (List.length sorted))

let find_random_floor grid ~width ~height ~rng =
  let rec pick () =
    let x = 1 + Random.State.int rng (width - 2) in
    let y = 1 + Random.State.int rng (height - 2) in
    let idx = x + (y * width) in
    if Dungeon.Tile.is_floor grid.(idx) then Types.Loc.make x y else pick ()
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
        if (not visited.(nx).(ny)) && Dungeon.Tile.is_floor grid.(idx) then (
          visited.(nx).(ny) <- true;
          dist.(nx).(ny) <- d + 1;
          enqueue q (nx, ny)))
  done;
  (!max_dist, !farthest)
