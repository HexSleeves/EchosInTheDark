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
  match Rl_utils.Utils.xy_to_index_opt loc.x loc.y d.width d.height with
  | Some idx -> Rl_utils.Utils.array_get_opt d.map idx
  | None -> None

let set_tile (loc : Loc.t) (tile : Tile.t) (d : t) =
  match Rl_utils.Utils.xy_to_index_opt loc.x loc.y d.width d.height with
  | Some idx when idx >= 0 && idx < Array.length d.map ->
      d.map.(idx) <- tile;
      true
  | _ -> false

let in_bounds (loc : Loc.t) (d : t) =
  loc.x >= 0 && loc.x < d.width && loc.y >= 0 && loc.y < d.height
