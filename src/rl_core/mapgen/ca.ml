(* Alias tile constructors from rl_core Map module to avoid Base.Map conflict *)
module Tile = Map.Tile
open Base

let index ~width x y = x + (y * width)

(** Initialize a random grid with walls at borders and random interior walls. *)
let init_grid ~rng ~width ~height ~(wall_prob : float) =
  Base.Array.init (width * height) ~f:(fun idx ->
      let x = idx % width in
      let y = idx / width in
      if x = 0 || x = width - 1 || y = 0 || y = height - 1 then Tile.Wall
      else if Float.(Random.State.float rng 1.0 < wall_prob) then Tile.Wall
      else Tile.Floor)

(** Count wall neighbors for a cell at (x,y). Borders count as walls. *)
let count_wall_neighbors (grid : Tile.t array) ~width ~height x y =
  let count = ref 0 in
  for dy = -1 to 1 do
    for dx = -1 to 1 do
      if dx <> 0 || dy <> 0 then
        let nx = x + dx and ny = y + dy in
        if nx < 0 || ny < 0 || nx >= width || ny >= height then Int.incr count
        else if Tile.equal grid.(index ~width nx ny) Tile.Wall then
          Int.incr count
    done
  done;
  !count

(** Perform smoothing passes on the grid using cellular automata rules. *)
let smooth grid ~width ~height ~passes =
  let current = Base.Array.copy grid in
  let next = Base.Array.copy grid in
  for _ = 1 to passes do
    for y = 0 to height - 1 do
      for x = 0 to width - 1 do
        let idx = index ~width x y in
        if x = 0 || x = width - 1 || y = 0 || y = height - 1 then
          next.(idx) <- Tile.Wall
        else
          let walls = count_wall_neighbors current ~width ~height x y in
          (* if too many neighbors, be a wall, else floor *)
          if walls >= 5 then next.(idx) <- Tile.Wall
          else next.(idx) <- Tile.Floor
      done
    done;
    Base.Array.blit ~src:next ~dst:current ~src_pos:0 ~dst_pos:0
      ~len:(width * height)
  done;
  current

(** Run the CA generator: init and smooth, return tile array. *)
let run ~width ~height ~rng =
  let wall_prob = 0.45 in
  let passes = 4 in
  let grid = init_grid ~rng ~width ~height ~wall_prob in
  smooth grid ~width ~height ~passes
