module R = Renderer
module B = Backend

(* All state *)
type t = {
  backend : B.t;
  quitting : bool;
  font_config : R.font_config;
  screen : Modules_d.screen;
}
