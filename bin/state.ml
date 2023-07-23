(* open Containers *)

(* All state *)
type t = {
  screen : Screen.t;
  term : Notty_lwt.Term.t;
  mutable backend : Backend.t;
}

(* Backend *)
let get_backend t = t.backend
let set_backend t backend = t.backend <- backend

(* Screen *)
let get_screen t = t.screen

(* Term *)
let get_term t = t.term
