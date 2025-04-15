open Raylib

let default_font_size = 16
let tile_width = default_font_size
let tile_height = default_font_size

(* Font configuration for grid rendering *)
type font_config = { font : Font.t; font_size : int }

(* Initialize font and measure character metrics *)
let init_font_config ~font_path ~font_size =
  Log.info "Creating font config";

  let font = load_font_ex font_path font_size None in
  gen_texture_mipmaps (addr (Font.texture font));
  set_texture_filter (Font.texture font) TextureFilter.Point;

  { font; font_size }

(* Init *)
let create ?(title = "Rougelike Tutorial 2025")
    ?(font_path = "resources/JetBrainsMono-Regular")
    ?(font_size = default_font_size) () =
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
  let num_tiles_h = int_of_float (target_h /. float_of_int tile_height) in
  let window_h = num_tiles_h * tile_height in

  (* Calculate width based on 80% of monitor width *)
  let target_w = float_of_int monitor_w *. 0.8 in
  let num_tiles_w = int_of_float (target_w /. float_of_int tile_width) in
  let window_w = num_tiles_w * tile_width in

  (Logs.info @@ fun m -> m "Num tiles: %d %d" num_tiles_w num_tiles_h);
  (Logs.info @@ fun m -> m "Window size: %d %d" window_w window_h);

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
  Log.info "Cleaning up font config";
  Raylib.unload_font fc.font;
  Raylib.close_window ()
