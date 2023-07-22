(* open Containers *)

(* All state *)
type t = { mutable backend : Backend.t; screen : Screen.t }
