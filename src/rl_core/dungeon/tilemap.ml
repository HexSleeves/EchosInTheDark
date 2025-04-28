open Base
open Types
open Ppx_yojson_conv_lib.Yojson_conv

let map_width_default = 80
let map_height_default = 50

(* Map data type. Starts at top left *)
type t = {
  seed : int; (* 15 bit value *)
  width : int;
  height : int;
  map : Tile.t array;
  player_start : Loc.t;
  stairs_up : Loc.t option;
  stairs_down : Loc.t option;
}
[@@deriving yojson]

(* Dim *)
let get_height v = v.height
let get_width v = v.width

(* Tile *)
let get_tile (loc : Loc.t) d =
  d.map.(Rl_utils.Utils.xy_to_index loc.x loc.y d.width)

let set_tile (loc : Loc.t) (tile : Tile.t) (d : t) =
  d.map.(Rl_utils.Utils.xy_to_index loc.x loc.y d.width) <- tile

let in_bounds (loc : Loc.t) (d : t) =
  loc.x >= 0 && loc.x < d.width && loc.y >= 0 && loc.y < d.height
