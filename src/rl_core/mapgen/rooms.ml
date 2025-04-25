open Base
open Dungeon

let rooms_generator ~width ~height ~rng =
  let grid = Stdlib.Array.make (width * height) Tile.Wall in
  let max_rooms = 8 + Random.State.int rng 8 in
  let min_size = 4 in
  let max_size = 10 in
  let rooms = ref [] in
  let rects_overlap (x1, y1, w1, h1) (x2, y2, w2, h2) =
    not (x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1)
  in
  let carve_room (x, y, w, h) =
    for i = x to x + w - 1 do
      for j = y to y + h - 1 do
        if i > 0 && i < width - 1 && j > 0 && j < height - 1 then
          grid.(i + (j * width)) <- Tile.Floor
      done
    done
  in
  let carve_h_corridor x1 x2 y =
    for x = min x1 x2 to max x1 x2 do
      if x > 0 && x < width - 1 && y > 0 && y < height - 1 then
        grid.(x + (y * width)) <- Tile.Floor
    done
  in
  let carve_v_corridor y1 y2 x =
    for y = min y1 y2 to max y1 y2 do
      if x > 0 && x < width - 1 && y > 0 && y < height - 1 then
        grid.(x + (y * width)) <- Tile.Floor
    done
  in
  for _ = 1 to max_rooms do
    let w = min_size + Random.State.int rng (max_size - min_size + 1) in
    let h = min_size + Random.State.int rng (max_size - min_size + 1) in
    let x = 1 + Random.State.int rng (width - w - 2) in
    let y = 1 + Random.State.int rng (height - h - 2) in
    let new_room = (x, y, w, h) in
    if not (List.exists !rooms ~f:(rects_overlap new_room)) then (
      carve_room new_room;
      (match !rooms with
      | [] -> ()
      | (px, py, pw, ph) :: _ ->
          let nx, ny = (x + (w / 2), y + (h / 2)) in
          let pxc, pyc = (px + (pw / 2), py + (ph / 2)) in
          if Random.State.bool rng then (
            carve_h_corridor pxc nx pyc;
            carve_v_corridor pyc ny nx)
          else (
            carve_v_corridor pyc ny pxc;
            carve_h_corridor pxc nx ny));
      rooms := new_room :: !rooms)
  done;
  (grid, !rooms)

let place_monsters ~grid ~width ~rooms ~rng ~depth entity_manager =
  List.fold rooms ~init:entity_manager ~f:(fun em (x, y, w, h) ->
      if Random.State.bool rng then
        let positions =
          Util.cartesian_product (Util.range x (x + w)) (Util.range y (y + h))
          |> List.filter ~f:(fun (i, j) ->
                 let idx = i + (j * width) in
                 Tile.is_floor grid.(idx))
          |> List.map ~f:(fun (i, j) -> Types.Loc.make i j)
        in
        Monster_placement.place_band_in_room ~entity_manager:em
          ~room_positions:positions ~depth ~rng
      else em)
