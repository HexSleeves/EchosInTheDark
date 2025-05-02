(* Alias tile constructors from rl_core Map module to avoid Base.Map conflict *)
module Tile = Dungeon.Tile
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
        else
          match Rl_utils.Utils.xy_to_index_opt nx ny width height with
          | Some idx -> (
              match Rl_utils.Utils.array_get_opt grid idx with
              | Some tile when Tile.equal tile Tile.Wall -> Int.incr count
              | _ -> ())
          | None -> ()
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
        match Rl_utils.Utils.xy_to_index_opt x y width height with
        | Some idx when idx >= 0 && idx < Array.length next ->
            if x = 0 || x = width - 1 || y = 0 || y = height - 1 then
              next.(idx) <- Tile.Wall
            else
              let walls = count_wall_neighbors current ~width ~height x y in
              if walls >= 5 then next.(idx) <- Tile.Wall
              else next.(idx) <- Tile.Floor
        | _ -> ()
      done
    done;
    Base.Array.blit ~src:next ~dst:current ~src_pos:0 ~dst_pos:0
      ~len:(width * height)
  done;
  current

(** Run the CA generator: init and smooth, return tile array. *)
let run ~width ~height ~rng =
  let wall_prob = 0.58 in
  (* More initial walls *)
  let passes = 6 in
  (* More smoothing passes *)
  let grid = init_grid ~rng ~width ~height ~wall_prob in
  smooth grid ~width ~height ~passes

let place_monsters ~grid ~width ~height ~rng entity_manager =
  let floor_positions =
    List.filter_map
      (List.init (width * height) ~f:Fn.id)
      ~f:(fun idx ->
        match Rl_utils.Utils.array_get_opt grid idx with
        | Some tile when Tile.is_floor tile ->
            let x = idx % width in
            let y = idx / width in
            Some (Rl_types.Loc.make x y)
        | _ -> None)
  in
  (* let num_monsters = Int.max 1 (width * height / 120) in *)
  let num_monsters = 2 in
  let shuffled = List.permute floor_positions ~random_state:rng in
  let monster_positions = List.take shuffled num_monsters in
  Core_log.info (fun m -> m "Placing %d monsters..." num_monsters);
  List.fold monster_positions ~init:entity_manager ~f:(fun em pos ->
      let spec = Monster_placement.get_template "Rat" in
      Monster_placement.place_monster ~entity_manager:em ~pos spec)
