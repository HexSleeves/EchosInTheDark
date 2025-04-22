(* All state *)
type t = {
  quitting : bool;
  screen : Modules_d.screen;
  backend : Rl_core.State.t;
  font_config : Renderer.font_config;
}
