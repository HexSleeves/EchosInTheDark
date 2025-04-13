(* State interface *)

type t = {
  quitting : bool;
  font : Raylib.Font.t;
  backend : Backend.t;
  screen : Modules_d.screen;
  mutable player_pos : int * int;
}

(* Any functions that operate on the state can be declared here *)
