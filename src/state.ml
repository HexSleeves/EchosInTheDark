open Renderer
module B = Backend

(* All state *)
type t = {
  backend : B.t;
  quitting : bool;
  font_config : font_config;
  screen : Modules_d.screen;
  mutable player_pos : Raylib.Vector2.t;
}
