(* open Containers *)

(* All state *)
type t =
  { screen : Screen.t
  ; mutable backend : Backend.t
  ; mutable player_pos : int * int
  }

(* Backend *)
let get_backend t = t.backend
let set_backend t backend = t.backend <- backend

(* Screen *)
let get_screen t = t.screen
