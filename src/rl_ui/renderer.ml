open Base
open Components
module Loc = Types.Loc
module Entity = Types.Entity
module Tile = Dungeon.Tile
open Rl_core.Backend

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

let gold = Constants.color_gold
let dark_bg = Constants.color_dark_bg

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

  let window_w = get_render_width () in
  let window_h = get_render_height () in

  let middle_width = (monitor_w / 2) - (window_w / 2) in
  let middle_height = monitor_h / 2 in

  Ui_log.info (fun m -> m "Monitor size: [%d %d]" monitor_w monitor_h);
  Ui_log.info (fun m -> m "Window size: [%d %d]" window_w window_h);
  Ui_log.info (fun m ->
      m "Setting window position: [%d %d]" middle_width middle_height);

  (* Center window on monitor *)
  set_window_position middle_width middle_height;

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

let render_ascii_cell ~glyph ~color ~fc ~loc ~origin =
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

let render_tileset_tile ~texture ~tile ~loc ~origin ~tile_render_size =
  let col, row = Tile.tile_to_tileset tile in
  Render_utils.draw_texture_ex ~texture ~pos:loc ~origin ~tile_render_size ~col
    ~row

let render_tileset_sprite ~entity ~origin ~pos ~texture ~tile_render_size =
  let col, row = Render_utils.entity_to_sprite_coords entity in
  Render_utils.draw_texture_ex ~texture ~pos ~origin ~tile_render_size ~col ~row

(* //////////////////////////////////////////////////////////////// *)
(* //////////////////////////////////////////////////////////////// *)

let render_map_tiles ~tiles ~width ~skip_positions ~origin ~ctx =
  Array.iteri tiles ~f:(fun i t ->
      let x, y = Rl_utils.Utils.index_to_xy i width in
      if not (Set.mem skip_positions (x, y)) then
        let loc = Types.Loc.make x y in
        match (ctx.render_mode, ctx.tileset_config) with
        | Constants.Tiles, Some t_cfg ->
            render_tileset_tile ~texture:t_cfg.texture ~tile:t ~loc ~origin
              ~tile_render_size:ctx.tile_render_size
        | Constants.Tiles, None | Constants.Ascii, _ ->
            let glyph, color = Render_utils.tile_glyph_and_color t in
            render_ascii_cell ~glyph ~color ~fc:ctx.font_config ~loc ~origin)

(* Utility: Render all entities *)
let render_entities ~entities ~origin ~ctx =
  let open Render_utils in
  let font_config = ctx.font_config in
  let drawn = ref (Base.Set.empty (module Int)) in

  List.iter entities ~f:(fun entity ->
      let base = Types.Entity.get_base entity in
      let pos = Position.get_exn base.id in
      let pos_tuple = (pos.x lsl 16) lor pos.y in
      if not (Base.Set.mem !drawn pos_tuple) then (
        drawn := Base.Set.add !drawn pos_tuple;

        match (ctx.render_mode, ctx.tileset_config) with
        | Constants.Tiles, Some t_cfg ->
            render_tileset_sprite ~entity ~origin ~pos ~texture:t_cfg.texture
              ~tile_render_size:ctx.tile_render_size
        | _ ->
            let glyph, color = entity_glyph_and_color entity in
            render_ascii_cell ~glyph ~color ~fc:font_config ~loc:pos ~origin))

let item_type_to_glyph = function
  | Types.Item.Potion -> ("!", Raylib.Color.skyblue)
  | Types.Item.Sword -> ("/", Raylib.Color.lightgray)
  | Types.Item.Scroll -> ("?", Raylib.Color.yellow)
  | Types.Item.Gold -> ("$", Raylib.Color.gold)
  | Types.Item.Key -> ("*", Raylib.Color.orange)

let item_type_to_sprite_coords = function
  | Types.Item.Potion -> (0, 0)
  | Types.Item.Sword -> (1, 0)
  | Types.Item.Scroll -> (2, 0)
  | Types.Item.Gold -> (3, 0)
  | Types.Item.Key -> (4, 0)

let draw_equipment_slots ~ctx ~start_y ~start_x equipment =
  let open Raylib in
  let open Render_utils in
  let slot_size = 32 in
  let slot_spacing = 12 in
  let font_config = ctx.font_config in

  List.iteri equipment ~f:(fun i (_, item_opt) ->
      let sy = start_y in
      let sx = start_x + (i * (slot_size + slot_spacing)) in
      let slot_rect =
        Rectangle.create (Float.of_int sx) (Float.of_int sy)
          (Float.of_int slot_size) (Float.of_int slot_size)
      in

      (* DRAW RECTANGLE EQUIPMENT SLOT *)
      draw_rectangle_rec slot_rect dark_bg;
      draw_rectangle_lines_ex slot_rect 2.0 gold;

      let slot_x = Int.of_float (Rectangle.x slot_rect) in
      let slot_y = Int.of_float (Rectangle.y slot_rect) in

      (* DRAW ITEM SPRITE IF ITEM EXISTS *)
      match item_opt with
      | None -> draw_text "-" (slot_x + 10) (slot_y + 2) 30 Color.gray
      | Some item ->
          (match (ctx.render_mode, ctx.tileset_config) with
          | Constants.Tiles, Some t_cfg ->
              let col, row =
                item_type_to_sprite_coords item.Types.Item.item_type
              in
              let tile_width = Constants.tile_width in
              let tile_height = Constants.tile_height in
              let src =
                Raylib.Rectangle.create
                  (Float.of_int (col * tile_width))
                  (Float.of_int (row * tile_height))
                  (Float.of_int tile_width) (Float.of_int tile_height)
              in
              let dest =
                Raylib.Rectangle.create (Float.of_int sx) (Float.of_int sy)
                  (Float.of_int slot_size) (Float.of_int slot_size)
              in
              Raylib.draw_texture_pro t_cfg.texture src dest
                (Raylib.Vector2.create 0. 0.)
                0. Color.white
          | _ ->
              let glyph, color = item_type_to_glyph item.Types.Item.item_type in
              draw_font_text ~font:font_config.font ~font_size:20.0 ~color
                ~text:glyph ~pos_x:(Float.of_int slot_x)
                ~pos_y:(Float.of_int slot_y));
          (* Draw tooltip below the slot *)
          let stat_summary = Inventory.item_stat_summary item in
          let corruption = Inventory.item_corruption_status item in
          let tooltip_y = slot_y + slot_size + 4 in
          let tooltip_lines =
            match corruption with
            | Some c -> [ stat_summary; c ]
            | None -> [ stat_summary ]
          in
          List.iteri tooltip_lines ~f:(fun j line ->
              draw_text line slot_x (tooltip_y + (j * 18)) 14 Color.lightgray))

let rounded_radius = 0.18
let rounded_segments = 12

let draw_stats_bar_vertical ~player ~rect ~ctx =
  let open Raylib in
  let padding = 8 in
  let line_height = 24 in
  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in
  match player with
  | Types.Entity.Player (base, _) ->
      let stats = Stats.get_exn base.id in
      let pos = Position.get_exn (Entity.get_id player) in
      let pos_x = pos.x in
      let pos_y = pos.y in
      let lines =
        [
          Printf.sprintf "Location: %d %d" pos_x pos_y;
          Printf.sprintf "HP: %d/%d" stats.hp stats.max_hp;
          Printf.sprintf "ATK: %d" stats.attack;
          Printf.sprintf "DEF: %d" stats.defense;
          Printf.sprintf "SPD: %d" stats.speed;
        ]
      in
      draw_rectangle_rec rect dark_bg;
      draw_rectangle_lines_ex rect 2.0 gold;
      List.iteri lines ~f:(fun i line ->
          let color = if i = 1 then gold else Color.white in
          let fc = ctx.font_config in
          let font_size = Float.of_int fc.font_size in
          let pos_x = Float.of_int x in
          let pos_y = Float.of_int (y + (i * line_height)) in
          Raylib.draw_text_ex fc.font line
            (Raylib.Vector2.create pos_x pos_y)
            font_size 0. color);
      let slot_y = y + (List.length lines * line_height) + 16 in
      get_equipment base.id
      |> Option.value ~default:Types.Equipment.empty
      |> draw_equipment_slots ~ctx ~start_y:slot_y ~start_x:x
  | _ ->
      draw_rectangle_rec rect dark_bg;
      draw_rectangle_lines_ex rect 2.0 gold;
      draw_text "Not a player" x y 20 Color.red

(* Draw the message log at the bottom *)
let draw_message_log ~messages ~rect =
  let open Raylib in
  let padding = 4 in
  let line_height = 16 in
  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in
  draw_rectangle_rounded rect rounded_radius rounded_segments dark_bg;
  draw_rectangle_rounded_lines rect rounded_radius rounded_segments 2.0 gold;
  List.iteri messages ~f:(fun i msg ->
      let color =
        if String.is_prefix msg ~prefix:"!" then gold else Color.lightgray
      in
      draw_text msg x (y + (i * line_height)) 18 color)
