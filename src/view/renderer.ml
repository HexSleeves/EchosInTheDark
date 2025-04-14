open Raylib

(* Font configuration for grid rendering *)
type font_config = { font : Font.t; font_size : int }

(* Entity type for grid-based rendering *)
type entity = { glyph : string; color : Color.t; pos : int * int }

(* Initialize font and measure character metrics *)
let init_font_config ~font_path ~font_size =
  Logs.info (fun m -> m "Creating font config");

  let font = load_font_ex font_path font_size None in
  gen_texture_mipmaps (addr (Font.texture font));
  set_texture_filter (Font.texture font) TextureFilter.Point;

  { font; font_size }

(* Init *)
let create ?(title = "Random Title")
    ?(font_path = "resources/JetBrainsMono-Regular")
    ?(font_size = Tile_coords.font_size) () =
  let open Raylib in
  (* This is needed to get the monitor dimensions. *)
  (* Creates a window of the monitor size. *)
  init_window 0 0 title;

  (* Get monitor dimensions *)
  let current_monitor = get_current_monitor () in
  let monitor_w = get_monitor_width current_monitor in
  let monitor_h = get_monitor_height current_monitor in

  (* Calculate target dimensions (e.g., 80% of height) *)
  let target_h = float_of_int monitor_h *. 0.8 in
  let num_tiles_h =
    int_of_float (target_h /. float_of_int Tile_coords.tile_height)
  in
  let window_h = num_tiles_h * Tile_coords.tile_height in

  (* Calculate width based on 80% of monitor width *)
  let target_w = float_of_int monitor_w *. 0.8 in
  let num_tiles_w =
    int_of_float (target_w /. float_of_int Tile_coords.tile_width)
  in
  let window_w = num_tiles_w * Tile_coords.tile_width in

  set_target_fps 60;

  (* Set window size and min size *)
  set_window_size window_w window_h;
  set_window_min_size window_w window_h;

  (* Center window on monitor *)
  set_window_position
    ((monitor_w / 2) - (window_w / 2))
    ((monitor_h / 2) - (window_h / 2));

  let font_config = init_font_config ~font_path ~font_size in

  font_config

(* Get glyph and color for a tile *)
let tile_glyph_and_color = function
  | Tile.Wall -> ("#", Color.gray)
  | Tile.Floor -> (".", Color.lightgray)

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen (x, y) =
  Raylib.Vector2.create
    (float_of_int x *. float_of_int Tile_coords.tile_width)
    (float_of_int y *. float_of_int Tile_coords.tile_height)

let render_cell glyph color (fc : font_config) (x, y) =
  let font_size = float_of_int fc.font_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let offset =
    Vector2.create
      ((float_of_int Tile_coords.tile_width -. Vector2.x glyph_size) /. 2.)
      ((float_of_int Tile_coords.tile_height -. Vector2.y glyph_size) /. 2.)
  in

  let spacing = 0. in
  let screen_pos = grid_to_screen (x, y) in
  let centered_pos = Vector2.add screen_pos offset in

  (* Font, Text, Position, Font-size, Spacing, Color *)
  draw_text_ex fc.font glyph centered_pos font_size spacing color
