module B = Backend

(* All state *)
type t = {
  quitting : bool;
  font : Raylib.Font.t;
  backend : B.t;
  screen : Modules_d.screen;
  mutable player_pos : int * int;
}
