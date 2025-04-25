open Base
module Tile = Rl_core.Dungeon.Tile

(* Font configuration for grid rendering *)
type font_config = { font : Raylib.Font.t; font_size : int; font_path : string }

type tileset_config = {
  texture : Raylib.Texture.t;
  width : int;
  height : int;
  path : string;
}

type render_context = {
  title : string;
  window_width : int;
  window_height : int;
  tile_render_size : int;
  font_config : font_config;
  flags : Raylib.ConfigFlags.t list;
  render_mode : Constants.render_mode;
  tileset_config : tileset_config option;
}

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
  set_window_min_size window_width window_height

let create_render_context ?(title = "Echoes in the Dark")
    ?(font_path = Constants.font_path) ?(font_size = Constants.font_size)
    ?(window_width = 1280) ?(window_height = 720)
    ?(flags =
      [ Raylib.ConfigFlags.Window_resizable; Raylib.ConfigFlags.Vsync_hint ])
    ?(tile_width = Constants.tile_width) ?(tile_height = Constants.tile_height)
    ?(tileset_path = Constants.tileset_path)
    ?(render_mode = !Constants.render_mode_ref)
    ?(tile_render_size = Constants.tile_render_size) () : render_context =
  (* Initialize window *)
  init_window ~flags ~window_width ~window_height ~title;

  (* Get monitor dimensions *)
  let open Raylib in
  let current_monitor = get_current_monitor () in
  let monitor_w = get_monitor_width current_monitor in
  let monitor_h = get_monitor_height current_monitor in

  let num_tiles_h =
    Int.of_float (Float.of_int monitor_h /. Float.of_int Constants.font_size)
  in
  let num_tiles_w =
    Int.of_float (Float.of_int monitor_w /. Float.of_int Constants.font_size)
  in

  let window_w = num_tiles_w * Constants.font_size in
  let window_h = num_tiles_h * Constants.font_size in

  Ui_log.info (fun m -> m "Monitor size: [%d %d]" monitor_w monitor_h);
  Ui_log.info (fun m -> m "Num tiles: [%d %d]" num_tiles_w num_tiles_h);
  Ui_log.info (fun m -> m "Window size: [%d %d]" window_w window_h);

  set_target_fps 60;

  (* Center window on monitor *)
  set_window_position
    ((monitor_w / 2) - (window_w / 2))
    ((monitor_h / 2) - (window_h / 2));

  let font_config = init_font_config ~font_path ~font_size in
  let tileset_config =
    try Some (init_tileset_config ~tileset_path ~tile_width ~tile_height)
    with _ -> None
  in
  {
    title;
    flags;
    font_config;
    render_mode;
    window_width;
    window_height;
    tileset_config;
    tile_render_size;
  }

(** [cleanup font_config] unloads the font and closes the Raylib window. *)
let cleanup (fc : font_config) =
  Ui_log.info (fun m -> m "Cleaning up font config");
  Raylib.unload_font fc.font;
  Raylib.close_window ()

(* Draw FPS overlay in the corner *)
let render_fps_overlay (fc : font_config) : unit =
  let open Raylib in
  let fps = get_fps () in
  let fps_text = Int.to_string fps in
  let text_width = measure_text fps_text fc.font_size in
  let padding = 4 in
  let box_height = Float.of_int (fc.font_size + (padding * 2)) in
  let box_width = Float.of_int (text_width + (padding * 2)) in
  let padding = Float.of_int padding in
  let box_x = Float.of_int (get_screen_width ()) -. box_width -. padding in
  let box_y = Float.of_int (get_screen_height ()) -. box_height -. padding in
  let box = Rectangle.create box_x box_y box_width box_height in
  draw_rectangle_rec box (Raylib.fade Color.gray 0.75);
  let text_x = Float.to_int (box_x +. padding) in
  let text_y = Float.to_int (box_y +. padding) in
  draw_text fps_text text_x text_y fc.font_size Color.white

let render_cell ~glyph ~color ~fc ~loc ~origin =
  let open Raylib in
  let open Render_utils in
  let font_size = Float.of_int fc.font_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let screen_pos =
    let base_pos = grid_to_screen loc in
    Vector2.add base_pos origin
  in

  let offset =
    Vector2.create
      ((font_size -. Vector2.x glyph_size) /. 2.)
      ((font_size -. Vector2.y glyph_size) /. 2.)
  in

  let spacing = 0. in
  let centered_pos = Vector2.add screen_pos offset in

  (* Font, Text, Position, Font-size, Spacing, Color *)
  draw_text_ex fc.font glyph centered_pos font_size spacing color

let render_tile ~texture ~tile ~loc ~origin ~tile_render_size =
  let open Raylib in
  let col, row = Tile.tile_to_tileset tile in

  let src =
    let tile_width = Constants.tile_width in
    let tile_height = Constants.tile_height in
    Rectangle.create
      (Float.of_int (col * tile_width))
      (Float.of_int (row * tile_height))
      (Float.of_int tile_width) (Float.of_int tile_height)
  in

  let dest =
    let base = Render_utils.grid_to_screen loc in
    Vector2.add base origin
  in

  let dest_rect =
    Rectangle.create (Vector2.x dest) (Vector2.y dest)
      (Float.of_int tile_render_size)
      (Float.of_int tile_render_size)
  in

  let rotation = 0. in
  let img_origin = Vector2.create 0. 0. in
  draw_texture_pro texture src dest_rect img_origin rotation Color.white

(* //////////////////////////////////////////////////////////////// *)
(* //////////////////////////////////////////////////////////////// *)

let render_map_tiles ~tiles ~width ~skip_positions ~origin ~ctx =
  Array.iteri tiles ~f:(fun i t ->
      let x, y = Rl_utils.Utils.index_to_xy i width in
      if not (Set.mem skip_positions (x, y)) then
        let loc = Rl_core.Types.Loc.make x y in
        match (ctx.render_mode, ctx.tileset_config) with
        | Constants.Tiles, Some t_cfg ->
            render_tile ~texture:t_cfg.texture ~tile:t ~loc ~origin
              ~tile_render_size:ctx.tile_render_size
        | Constants.Tiles, None | Constants.Ascii, _ ->
            let glyph, color = Render_utils.tile_glyph_and_color t in
            render_cell ~glyph ~color ~fc:ctx.font_config ~loc ~origin)

(* Utility: Render all entities *)
let render_entities ~entities ~origin ~ctx =
  let open Render_utils in
  let font_config = ctx.font_config in
  List.iter entities ~f:(fun entity ->
      let base = Rl_core.Types.Entity.get_base entity in
      match (ctx.render_mode, ctx.tileset_config) with
      | Constants.Tiles, Some t_cfg ->
          let col, row = Render_utils.entity_to_sprite_coords entity in
          let tile_width = Constants.tile_width in
          let tile_height = Constants.tile_height in
          let src =
            Raylib.Rectangle.create
              (Float.of_int (col * tile_width))
              (Float.of_int (row * tile_height))
              (Float.of_int tile_width) (Float.of_int tile_height)
          in
          let dest =
            let base_pos = grid_to_screen base.pos in
            Raylib.Vector2.add base_pos origin
          in
          let dest_rect =
            Raylib.Rectangle.create (Raylib.Vector2.x dest)
              (Raylib.Vector2.y dest)
              (Float.of_int ctx.tile_render_size)
              (Float.of_int ctx.tile_render_size)
          in
          let rotation = 0. in
          let img_origin = Raylib.Vector2.create 0. 0. in
          Raylib.draw_texture_pro t_cfg.texture src dest_rect img_origin
            rotation Raylib.Color.white
      | _ ->
          let glyph, color = entity_glyph_and_color entity in
          render_cell ~glyph ~color ~fc:font_config ~loc:base.pos ~origin)

(* Draw the vertical player stats bar *)
let draw_stats_bar_vertical ~player ~rect =
  let open Raylib in
  let padding = 8 in
  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in
  let line_height = 24 in
  match player with
  | Rl_core.Types.Entity.Player (_, pdata) ->
      let stats = pdata.stats in
      let lines =
        [
          Printf.sprintf "HP: %d/%d" stats.hp stats.max_hp;
          Printf.sprintf "ATK: %d" stats.attack;
          Printf.sprintf "DEF: %d" stats.defense;
          Printf.sprintf "SPD: %d" stats.speed;
        ]
      in
      draw_rectangle_rec rect Color.darkgray;
      List.iteri lines ~f:(fun i line ->
          draw_text line x (y + (i * line_height)) 20 Color.white)
  | _ ->
      draw_rectangle_rec rect Color.darkgray;
      draw_text "Not a player" x y 20 Color.red

(* Draw the message log at the bottom *)
let draw_message_log ~messages ~rect =
  let open Raylib in
  let padding = 4 in
  let line_height = 16 in

  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in

  draw_rectangle_rec rect Color.black;
  draw_rectangle_lines
    (Int.of_float (Rectangle.x rect))
    (Int.of_float (Rectangle.y rect))
    (Int.of_float (Rectangle.width rect))
    (Int.of_float (Rectangle.height rect))
    Color.white;
  List.iteri messages ~f:(fun i msg ->
      draw_text msg x (y + (i * line_height)) 18 Color.lightgray)
