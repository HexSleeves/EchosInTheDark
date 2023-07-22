let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

(* This is the backend. All game-modifying functions go through here *)

(* The actual game (server) state
   Observers can observe data in the backend,
   but actions can only be taken via messages (Backend.Action)
*)

type t = { seed : int } [@@deriving yojson]

let default ~random ~seed = { seed }
