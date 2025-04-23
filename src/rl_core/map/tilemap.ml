open Ppx_yojson_conv_lib.Yojson_conv
open Base
open Types

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
let get_tile v (loc : Loc.t) =
  v.map.(Rl_utils.Utils.xy_to_index loc.x loc.y v.width)

let set_tile v (loc : Loc.t) tile =
  v.map.(Rl_utils.Utils.xy_to_index loc.x loc.y v.width) <- tile

let in_bounds v (loc : Loc.t) =
  loc.x >= 0 && loc.x < v.width && loc.y >= 0 && loc.y < v.height
