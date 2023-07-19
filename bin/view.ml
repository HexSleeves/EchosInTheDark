let draw_scene draw_func =
  let open Raylib in
  begin_drawing ();
  clear_background Color.raywhite;

  draw_func ();

  end_drawing ()
