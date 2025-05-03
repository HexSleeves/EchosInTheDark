open Base
open Render_types
module Loc = Rl_types.Loc
module Tile = Dungeon.Tile
module Backend = Rl_core.Backend

let gold = Render_constants.color_gold
let dark_bg = Render_constants.color_dark_bg
let tile_width = Render_constants.tile_width
let tile_height = Render_constants.tile_height

(* //////////////////////////////////////////////////////////////// *)
(* Init *)
(* //////////////////////////////////////////////////////////////// *)

(* Initialize font and measure character metrics *)
let init_font_config ~font_path ~font_size =
  let open Raylib in
  let font = load_font_ex font_path font_size None in
  gen_texture_mipmaps (addr (Font.texture font));
  set_texture_filter (Font.texture font) TextureFilter.Point;

  { font; font_size; font_path }

let init_tileset_config ~tileset_path ~tile_width ~tile_height =
  let texture = Raylib.load_texture tileset_path in
  { texture; width = tile_width; height = tile_height; path = tileset_path }

let init_window ~flags ~window_width ~window_height ~title =
  let open Raylib in
  set_config_flags flags;
  init_window window_width window_height title;
  set_window_min_size window_width window_height;
  set_target_fps 60

let create_render_context ?(title = "Echoes in the Dark")
    ?(font_path = Render_constants.font_path)
    ?(font_size = Render_constants.font_size) ?(window_width = 1280)
    ?(window_height = 720)
    ?(flags =
      [ Raylib.ConfigFlags.Window_resizable; Raylib.ConfigFlags.Vsync_hint ])
    ?(tile_width = Render_constants.tile_width)
    ?(tile_height = Render_constants.tile_height)
    ?(tileset_path = Render_constants.tileset_path)
    ?(render_mode = Render_constants.Tiles)
    ?(tile_render_size = Render_constants.tile_render_size) () : render_context
    =
  (* Initialize window *)
  init_window ~flags ~window_width ~window_height ~title;

  (* Get monitor dimensions *)
  let open Raylib in
  let current_monitor = get_current_monitor () in
  let monitor_w = get_monitor_width current_monitor in
  let monitor_h = get_monitor_height current_monitor in

  let window_w = window_width in
  let window_h = window_height in

  let middle_width = monitor_w / 2 in
  let middle_height = monitor_h / 2 in

  Ui_log.info (fun m -> m "Monitor size: [%d %d]" monitor_w monitor_h);
  Ui_log.info (fun m -> m "Window size: [%d %d]" window_w window_h);
  Ui_log.info (fun m ->
      m "Setting window position: [%d %d]" middle_width middle_height);

  (* Center window on monitor *)
  set_window_position
    ((monitor_w / 2) - (window_w / 2))
    ((monitor_h / 2) - (window_h / 2));

  {
    title;
    flags;
    render_mode;
    window_width;
    window_height;
    tile_render_size;
    font_config = init_font_config ~font_path ~font_size;
    tileset_config = init_tileset_config ~tileset_path ~tile_width ~tile_height;
  }

(** [cleanup font_config] unloads the font and closes the Raylib window. *)
let cleanup (ctx : render_context) =
  Ui_log.info (fun m -> m "Cleaning up font config");
  Raylib.unload_font ctx.font_config.font;
  Raylib.close_window ()

(* Draw FPS overlay in the corner *)
let render_fps_overlay = Render_ui.render_fps_overlay
let render_map = Render_map.render_map_tiles
let render_entities = Render_map.render_entities
let draw_top_bar = Render_ui.draw_top_bar
let draw_minimap = Render_ui.draw_minimap
let draw_message_log = Render_ui.draw_message_log
let draw_bottom_bar = Render_ui.draw_bottom_bar

let render_chunk (chunk : Chunk.t) ~ctx ~backend ~map_origin ~entities =
  let entity_positions =
    Render_utils.occupied_positions (Backend.get_entities backend)
  in

  render_map
    ~tiles:(Array.concat (Array.to_list chunk.tiles))
    ~width:Constants.chunk_w ~skip_positions:entity_positions ~origin:map_origin
    ~ctx;

  render_entities ~entities ~origin:map_origin ~ctx
