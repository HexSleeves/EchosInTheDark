open Ppx_yojson_conv_lib.Yojson_conv
open Base

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

let default_map () =
  {
    seed = 0;
    width = map_width_default;
    height = map_height_default;
    map = Array.create ~len:(map_width_default * map_height_default) Tile.Floor;
  }

let generate ~seed ~w ~h =
  let map = Array.create ~len:(w * h) Tile.Floor in

  for x = 0 to w - 1 do
    map.(Utils.calc_offset w x 0) <- Tile.Wall;
    map.(Utils.calc_offset w x (h - 1)) <- Tile.Wall
  done;

  for y = 0 to h - 1 do
    map.(Utils.calc_offset w 0 y) <- Tile.Wall;
    map.(Utils.calc_offset w (w - 1) y) <- Tile.Wall
  done;

  { map; seed; width = w; height = h }
