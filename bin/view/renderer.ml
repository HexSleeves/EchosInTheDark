(* Init *)
let create ?(title = "Random Tutle") w h =
  Raylib.init_window w h title;
  Raylib.set_target_fps 60;
  Raylib.set_window_min_size w h
;;

(* Dim *)
let screen_width = Raylib.get_screen_width ()
let screen_height = Raylib.get_screen_height ()
let render_width = Raylib.get_render_width ()
let render_height = Raylib.get_render_height ()
