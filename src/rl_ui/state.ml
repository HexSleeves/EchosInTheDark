open Render
module Backend = Rl_core.Backend

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
  backend : Backend.t;
  input_ctx : Input_context.t;
  screen : Modules_d.screen;
  render_ctx : Render_types.render_context;
}
