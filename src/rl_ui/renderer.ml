open Raylib

let default_font_size = 16
let tile_width = default_font_size
let tile_height = default_font_size

(* Font configuration for grid rendering *)
type font_config = { font : Font.t; font_size : int }

(* Initialize font and measure character metrics *)
let init_font_config ~font_path ~font_size =
  let open Raylib in
  Ui_log.info (fun m -> m "Creating font config");

  let font = load_font_ex font_path font_size None in
  gen_texture_mipmaps (addr (Font.texture font));
  set_texture_filter (Font.texture font) TextureFilter.Point;

  { font; font_size }

(* Init *)
let create ?(title = "Rougelike Tutorial 2025")
    ?(font_path = "resources/JetBrainsMono-Regular")
    ?(font_size = default_font_size) () =
  let open Raylib in
  set_config_flags [ ConfigFlags.Window_resizable; ConfigFlags.Vsync_hint ];

  (* This is needed to get the monitor dimensions. *)
  (* Creates a window of the monitor size. *)
  (* init_window 0 0 title; *)
  init_window 1280 720 title;
  set_window_min_size 1280 720;

  (* Get monitor dimensions *)
  let current_monitor = get_current_monitor () in
  let monitor_w = get_monitor_width current_monitor in
  let monitor_h = get_monitor_height current_monitor in

  (* Calculate target dimensions (e.g., 80% of height) *)
  let target_h = float_of_int monitor_h *. 0.8 in
  let num_tiles_h = int_of_float (target_h /. float_of_int tile_height) in
  let window_h = num_tiles_h * tile_height in

  (* Calculate width based on 80% of monitor width *)
  let target_w = float_of_int monitor_w *. 0.8 in
  let num_tiles_w = int_of_float (target_w /. float_of_int tile_width) in
  let window_w = num_tiles_w * tile_width in

  Ui_log.info (fun m -> m "Num tiles: [%d %d]" num_tiles_w num_tiles_h);
  Ui_log.info (fun m -> m "Window size: [%d %d]" window_w window_h);

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

(** [cleanup font_config] unloads the font and closes the Raylib window. *)
let cleanup (fc : font_config) =
  Ui_log.info (fun m -> m "Cleaning up font config");
  Raylib.unload_font fc.font;
  Raylib.close_window ()

(* --- BEGIN MERGED FROM grafx.ml --- *)
module T = Rl_core.Map.Tile

(* Get glyph and color for a tile *)
let[@warning "-11"] tile_glyph_and_color (tile : T.t) : string * Color.t =
  match tile with
  | T.Wall -> ("#", Color.gray)
  | T.Floor -> (".", Color.lightgray)
  | T.Stairs_up -> ("<", Color.gold)
  | T.Stairs_down -> (">", Color.orange)
  | _ ->
      Printf.printf "Warning: Unhandled tile type encountered\n";
      ("?", Color.red)

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen (loc : Rl_core.Types.Loc.t) =
  Raylib.Vector2.create
    (float_of_int loc.x *. float_of_int tile_width)
    (float_of_int loc.y *. float_of_int tile_height)

let screen_to_grid (vec : Vector2.t) =
  Rl_core.Types.Loc.make
    (int_of_float (Vector2.x vec /. float_of_int tile_width))
    (int_of_float (Vector2.y vec /. float_of_int tile_height))

let render_cell glyph color (fc : font_config) (loc : Rl_core.Types.Loc.t) =
  let font_size = float_of_int fc.font_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let offset =
    Vector2.create
      ((float_of_int tile_width -. Vector2.x glyph_size) /. 2.)
      ((float_of_int tile_height -. Vector2.y glyph_size) /. 2.)
  in

  let spacing = 0. in
  let screen_pos = grid_to_screen loc in
  let centered_pos = Vector2.add screen_pos offset in

  (* Font, Text, Position, Font-size, Spacing, Color *)
  draw_text_ex fc.font glyph centered_pos font_size spacing color
(* --- END MERGED FROM grafx.ml --- *)
