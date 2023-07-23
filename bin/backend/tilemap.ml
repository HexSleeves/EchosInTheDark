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

let generate w h ~seed =
  let width = w in
  let height = h in
  let map = Array.make (width * height) @@ Tile.Wall in
  { map; seed; width; height }
