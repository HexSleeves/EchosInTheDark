module B = Backend

(* All state *)
type t = {
  font : Raylib.Font.t;
  backend : B.t;
  screen : Modules_d.t;
  mutable player_pos : int * int;
}
