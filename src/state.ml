open Containers

(* All state *)
type t = {
  font : Raylib.Font.t;
  backend : Backend.t;
  screen : Modules_d.t;
  mutable player_pos : int * int;
}
