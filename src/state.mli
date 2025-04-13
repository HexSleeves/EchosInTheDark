(* State interface *)

type t = {
  font : Raylib.Font.t;
  backend : Backend.t;
  screen : Modules_d.t;
  mutable player_pos : int * int;
}

(* Any functions that operate on the state can be declared here *)
