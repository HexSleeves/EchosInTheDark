open Mode
open Ppx_yojson_conv_lib.Yojson_conv

let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

(* This is the backend. All game-modifying functions go through here *)

(* The actual game (server) state
   Observers can observe data in the backend,
   but actions can only be taken via messages (Backend.Action)
*)

type t = {
  seed : int;
  debug : bool;
  map : Tilemap.t;
  mode : CtrlMode.t;
  controller_id : int;
  random : Rng.State.t;
}
(* [@@deriving yojson] *)

let bump ?(step = 1) x = x + step

let make ~debug ~w ~h ~random ~seed =
  let map = Tilemap.generate ~w ~h ~seed in

  (* player *)
  let controller_id = 0 in
  { debug; seed; random; map; mode = CtrlMode.Normal; controller_id }

let get_tile v x y = Tilemap.get_tile v.map x y
