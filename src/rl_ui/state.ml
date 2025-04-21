(* All state *)
type t = {
  quitting : bool;
  screen : Modules_d.screen;
  backend : Rl_core.Backend.t;
  font_config : Renderer.font_config;
}
