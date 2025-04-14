open Mode
open Base

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

let make_default ~debug =
  let random = Rng.get_state () in
  let seed = Rng.seed_int in
  let map = Tilemap.default_map () in
  { debug; seed; random; map; mode = CtrlMode.Normal; controller_id = 0 }

let update b_end ~w ~h ~seed =
  { b_end with seed; map = Tilemap.generate ~seed ~w ~h }

let get_tile v x y = Tilemap.get_tile v.map x y
