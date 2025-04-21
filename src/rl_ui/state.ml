(* All state *)
type t = {
  quitting : bool;
  screen : Modules_d.screen;
  font_config : Renderer.font_config;
  game_state : Rl_core.State.game_state;
}
