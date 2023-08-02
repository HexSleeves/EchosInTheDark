open Ppx_yojson_conv_lib.Yojson_conv

let map_width_default = 80
let map_height_default = 50

(* Map data type. Starts at top left *)
type t = {
  seed : int; (* 15 bit value *)
  width : int;
  height : int;
  map : Tile.t array;
}
[@@deriving yojson]

(* Dim *)
let get_height v = v.height
let get_width v = v.width

(* Tile *)
let get_tile v x y = v.map.(Utils.calc_offset v.width x y)
let set_tile v x y tile = v.map.(Utils.calc_offset v.width x y) <- tile

let generate ?(w = map_width_default) ?(h = map_height_default) ~seed =
  let width = w in
  let height = h in
  let map = Array.make (width * height) @@ Tile.Floor in

  for x = 0 to width - 1 do
    map.(Utils.calc_offset width x 0) <- Tile.Wall;
    map.(Utils.calc_offset width x (height - 1)) <- Tile.Wall
  done;

  for y = 0 to height - 1 do
    map.(Utils.calc_offset width 0 y) <- Tile.Wall;
    map.(Utils.calc_offset width (width - 1) y) <- Tile.Wall
  done;

  { map; seed; width; height }
