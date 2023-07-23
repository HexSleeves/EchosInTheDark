open Ppx_yojson_conv_lib.Yojson_conv

let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

(* This is the backend. All game-modifying functions go through here *)

(* The actual game (server) state
   Observers can observe data in the backend,
   but actions can only be taken via messages (Backend.Action)
*)

type t = { seed : int; map : Tilemap.t; random : Utils.Random.State.t }
[@@deriving yojson]

let default w h ~random ~seed =
  let map = Tilemap.generate w h ~seed in
  { seed; random; map }

let get_tile v x y = Tilemap.get_tile v.map x y
