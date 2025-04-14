open Raylib

(* choose color *)
(* let set_color r g b a = Raylib.color_to_hsv.color ~alpha:a (r, g, b) *)

let draw_raylib_scene draw_func =
  begin_drawing ();
  clear_background Color.black;

  (* Main Draw fn *)
  let result = draw_func () in

  (* Wrapup  *)
  end_drawing ();
  result
