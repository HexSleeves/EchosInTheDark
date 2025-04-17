open Rl_core

(* All state *)
type t = {
  backend : Backend.t;
  quitting : bool;
  font_config : Renderer.font_config;
  screen : Modules_d.screen;
}
