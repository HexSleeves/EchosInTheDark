let tile_w = 12
let tile_h = 12

(* Init *)
let create ?(title = "Random Title") w h =
  let open Raylib in
  let w = w * tile_w in
  let h = h * tile_h in
  init_window w h title;
  set_target_fps 60;

  let font = load_font_ex "resources/KAISG.ttf" 96 None in
  gen_texture_mipmaps (addr (Font.texture font));
  set_texture_filter (Font.texture font) TextureFilter.Point;
  set_window_min_size w h;

  font

(* Dim *)
let screen_width = Raylib.get_screen_width ()
let screen_height = Raylib.get_screen_height ()
let render_width = Raylib.get_render_width ()
let render_height = Raylib.get_render_height ()
