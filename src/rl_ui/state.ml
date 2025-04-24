module Input_context = struct
  type t = {
    held_key : Raylib.Key.t option;
    held_since : float option;
    last_repeat : float option;
  }

  let empty = { held_key = None; held_since = None; last_repeat = None }
end

(* All state *)
type t = {
  quitting : bool;
  screen : Modules_d.screen;
  backend : Rl_core.State.t;
  render_ctx : Renderer.render_context;
  input_ctx : Input_context.t;
}
