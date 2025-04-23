(* All state *)
type t = {
  quitting : bool;
  screen : Modules_d.screen;
  backend : Rl_core.State.t;
  render_ctx : Renderer.render_context;
}
