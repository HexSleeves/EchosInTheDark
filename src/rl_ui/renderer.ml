open Base
open Components
open Constants
module Loc = Rl_types.Loc
module Tile = Dungeon.Tile

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
  render_mode : Render_constants.render_mode;
  tileset_config : tileset_config;
}

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
let render_fps_overlay (ctx : render_context) : unit =
  let open Raylib in
  let fc = ctx.font_config in
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

let render_tileset_sprite ~entity_id ~origin ~pos ~texture ~tile_render_size =
  let col, row = Render_utils.entity_to_sprite_coords entity_id in
  Render_utils.draw_texture_ex ~texture ~pos ~origin ~tile_render_size ~col ~row

(* //////////////////////////////////////////////////////////////// *)
(* //////////////////////////////////////////////////////////////// *)

let render_map_tiles ~tiles ~width ~skip_positions ~origin ~ctx =
  Array.iteri tiles ~f:(fun i t ->
      let x, y = Rl_utils.Utils.index_to_xy i width in
      if not (Set.mem skip_positions (x, y)) then
        let loc = Rl_types.Loc.make x y in
        match (ctx.render_mode, ctx.tileset_config) with
        | Render_constants.Tiles, t_cfg ->
            render_tileset_tile ~texture:t_cfg.texture ~tile:t ~loc ~origin
              ~tile_render_size:ctx.tile_render_size
        | _ ->
            let glyph, color = Render_utils.tile_glyph_and_color t in
            render_ascii_cell ~glyph ~color ~fc:ctx.font_config ~loc ~origin)

(* Utility: Render all entities *)
let render_entities ~entities ~origin ~ctx =
  let open Render_utils in
  let font_config = ctx.font_config in
  let drawn = ref (Base.Set.empty (module Int)) in

  List.iter entities ~f:(fun entity_id ->
      let world_position = Position.get_exn entity_id in
      let local_pos =
        Chunk_manager.world_to_local_coord world_position.world_pos
      in

      let pos_tuple = (local_pos.x lsl 16) lor local_pos.y in
      if not (Base.Set.mem !drawn pos_tuple) then (
        drawn := Base.Set.add !drawn pos_tuple;

        match (ctx.render_mode, ctx.tileset_config) with
        | Render_constants.Tiles, t_cfg ->
            render_tileset_sprite ~entity_id ~origin ~pos:local_pos
              ~texture:t_cfg.texture ~tile_render_size:ctx.tile_render_size
        | _ ->
            let glyph, color = entity_glyph_and_color entity_id in
            render_ascii_cell ~glyph ~color ~fc:font_config ~loc:local_pos
              ~origin))

let item_type_to_glyph = function
  | Item.Item_data.Potion -> ("!", Raylib.Color.skyblue)
  | Item.Item_data.Sword -> ("/", Raylib.Color.lightgray)
  | Item.Item_data.Scroll -> ("?", Raylib.Color.yellow)
  | Item.Item_data.Gold -> ("$", Raylib.Color.gold)
  | Item.Item_data.Key -> ("*", Raylib.Color.orange)

let item_type_to_sprite_coords = function
  | Item.Item_data.Potion -> (0, 0)
  | Item.Item_data.Sword -> (1, 0)
  | Item.Item_data.Scroll -> (2, 0)
  | Item.Item_data.Gold -> (3, 0)
  | Item.Item_data.Key -> (4, 0)

let draw_equipment_slots ~ctx ~end_y ~end_x (equipment : Equipment.t) =
  let open Raylib in
  let slot_size = 32 in
  let slot_spacing = 12 in

  let texture = ctx.tileset_config.texture in

  List.iteri equipment ~f:(fun i (_slot, maybe_item_id) ->
      let sy = end_y in
      let sx = end_x + (i * (slot_size + slot_spacing)) in
      let slot_rect =
        Rectangle.create (Float.of_int sx) (Float.of_int sy)
          (Float.of_int slot_size) (Float.of_int slot_size)
      in

      (* DRAW RECTANGLE EQUIPMENT SLOT *)
      draw_rectangle_rec slot_rect dark_bg;
      draw_rectangle_lines_ex slot_rect 2.0 gold;

      let slot_x = Int.of_float (Rectangle.x slot_rect) in
      let slot_y = Int.of_float (Rectangle.y slot_rect) in

      let draw_empty () =
        draw_text "-" (slot_x + 10) (slot_y + 2) 30 Color.gray
      in

      maybe_item_id
      |> Option.iter ~f:(fun item_id ->
             match Item.get item_id with
             | Some item ->
                 let col, row = item_type_to_sprite_coords item.item_type in

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

                 Raylib.draw_texture_pro texture src dest
                   (Raylib.Vector2.create 0. 0.)
                   0. Color.white
             | None -> draw_empty ());
      if Option.is_none maybe_item_id then draw_empty ())

let rounded_radius = 0.18
let rounded_segments = 12

let draw_player_stats_box ~player_id ~rect ~ctx ~line_height ~padding =
  let open Raylib in
  let lines =
    Option.bind (Stats.get player_id) ~f:(fun stats ->
        Option.map (Position.get player_id) ~f:(fun pos ->
            let chunk = Chunk_manager.world_to_chunk_coord pos.world_pos in
            let local = Chunk_manager.world_to_local_coord pos.world_pos in
            [
              Printf.sprintf "Chunk: %s" (Loc.to_string chunk);
              Printf.sprintf "Local: %s" (Loc.to_string local);
              Printf.sprintf "World: %s" (Loc.to_string pos.world_pos);
              Printf.sprintf "HP: %d/%d" stats.hp stats.max_hp;
              Printf.sprintf "ATK: %d" stats.attack;
              Printf.sprintf "DEF: %d" stats.defense;
              Printf.sprintf "SPD: %d" stats.speed;
            ]))
    |> Option.value ~default:[ "Player data unavailable" ]
  in

  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 2.0 gold;

  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in

  List.iteri lines ~f:(fun i line ->
      let color = if i = 1 then gold else Color.white in
      let fc = ctx.font_config in
      let font_size = Float.of_int fc.font_size in
      let pos_x = Float.of_int x in
      let pos_y = Float.of_int (y + (i * line_height)) in
      Raylib.draw_text_ex fc.font line
        (Raylib.Vector2.create pos_x pos_y)
        font_size 0. color);

  (x, y + (List.length lines * line_height) + 16)

let draw_stats_bar_vertical ~player_id ~rect ~ctx =
  let padding = 8 in
  let line_height = 24 in

  let end_x, end_y =
    draw_player_stats_box ~ctx ~player_id ~rect ~line_height ~padding
  in

  match Equipment.get player_id with
  | Some equipment -> draw_equipment_slots ~ctx ~end_x ~end_y equipment
  | None -> ()

(* Draw the message log at the bottom *)
let draw_message_log ~messages ~rect =
  let open Raylib in
  let padding = 4 in
  let line_height = 16 in
  let x = Int.of_float (Rectangle.x rect) + padding in
  let y = Int.of_float (Rectangle.y rect) + padding in
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;
  List.iteri messages ~f:(fun i msg ->
      let color =
        if String.is_prefix msg ~prefix:"!" then gold else Color.lightgray
      in
      draw_text msg x (y + (i * line_height)) 18 color)

(* //////////////////////////////////////////////////////////////// *)
(* UI Panel Renderers *)
(* //////////////////////////////////////////////////////////////// *)

let draw_top_bar ~rect ~(backend : Rl_core.Backend.t) ~(ctx : render_context) =
  let open Raylib in
  let padding = 4 in
  let line_height = ctx.font_config.font_size + padding in

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  (* Fetch Player Data *)
  let player_id = Rl_core.Backend.get_player_id backend in
  let stats_opt = Components.Stats.get player_id in

  (* --- Left Section (HP/LVL) --- *)
  let hp_text =
    match stats_opt with
    | Some stats -> Printf.sprintf "HP: %d / %d" stats.hp stats.max_hp
    | None -> "HP: N/A"
  in
  let text_x = Float.to_int (Rectangle.x rect) + padding in
  let text_y = Float.to_int (Rectangle.y rect) + padding in
  draw_text_ex ctx.font_config.font hp_text
    (Vector2.create (Float.of_int text_x) (Float.of_int text_y))
    (Float.of_int ctx.font_config.font_size)
    0. Color.white;

  (* Draw Level/XP text below/next to HP *)
  let lvl_text =
    match stats_opt with
    | Some stats -> Printf.sprintf "LVL: %d" stats.level
    | None -> "LVL: N/A"
  in
  let hp_text_width = Raylib.measure_text hp_text ctx.font_config.font_size in
  let lvl_text_x = text_x + hp_text_width + (padding * 4) in
  (* Add spacing *)
  draw_text_ex ctx.font_config.font lvl_text
    (Vector2.create (Float.of_int lvl_text_x) (Float.of_int text_y))
    (Float.of_int ctx.font_config.font_size)
    0. Color.white;

  (* --- Middle Section (Combat Stats) --- *)
  (* Placeholder *)
  let qn_text = "QN: N/A" in
  let ms_text =
    match stats_opt with
    | Some stats -> Printf.sprintf "MS: %d" stats.speed
    | None -> "MS: N/A"
  in
  let av_text =
    match stats_opt with
    | Some stats -> Printf.sprintf "AV: %d" stats.defense
    | None -> "AV: N/A"
  in
  let dv_text = "DV: N/A" in
  (* Placeholder *)
  let ma_text = "MA: N/A" in
  (* Placeholder *)

  let combat_stats_text =
    String.concat ~sep:"   " [ qn_text; ms_text; av_text; dv_text; ma_text ]
  in
  let combat_stats_width =
    Raylib.measure_text combat_stats_text ctx.font_config.font_size
  in
  let combat_stats_x =
    Float.to_int
      (((Rectangle.width rect -. Float.of_int combat_stats_width) /. 2.)
      +. Rectangle.x rect)
    (* Centered *)
  in
  (* Connects calculations to draw call *)
  draw_text_ex ctx.font_config.font combat_stats_text
    (Vector2.create (Float.of_int combat_stats_x) (Float.of_int text_y))
    (Float.of_int ctx.font_config.font_size)
    0. Color.white;

  (* --- Right Section (Date/Zone) --- *)
  (* TODO: Fetch Date/Time and Zone Name *)
  ()

let draw_minimap ~rect ~(backend : Rl_core.Backend.t) ~(ctx : render_context) =
  let open Raylib in
  let padding = 2.0 in

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  (* Get Player Position and Chunk Data *)
  let player_id = Rl_core.Backend.get_player_id backend in
  let player_pos_opt = Components.Position.get player_id in
  let chunk_manager = Rl_core.Backend.get_chunk_manager backend in

  match player_pos_opt with
  | None ->
      (* Player position not found *)
      let text = "Minimap N/A" in
      let text_w = measure_text text ctx.font_config.font_size in
      let text_x =
        Rectangle.x rect
        +. ((Rectangle.width rect -. Float.of_int text_w) /. 2.0)
      in
      let text_y =
        Rectangle.y rect
        +. (Rectangle.height rect -. Float.of_int ctx.font_config.font_size)
           /. 2.0
      in
      draw_text text (Float.to_int text_x) (Float.to_int text_y)
        ctx.font_config.font_size Color.gray
  | Some player_pos -> (
      let chunk_coords =
        Chunk_manager.world_to_chunk_coord player_pos.world_pos
      in
      let local_coords : Rl_types.Loc.t =
        Chunk_manager.world_to_local_coord player_pos.world_pos
      in
      (* Add type annotation *)
      match Chunk_manager.get_loaded_chunk chunk_coords chunk_manager with
      | None ->
          (* Chunk not loaded *)
          let text = "Chunk N/A" in
          let text_w = measure_text text ctx.font_config.font_size in
          let text_x =
            Rectangle.x rect
            +. ((Rectangle.width rect -. Float.of_int text_w) /. 2.0)
          in
          let text_y =
            Rectangle.y rect
            +. (Rectangle.height rect -. Float.of_int ctx.font_config.font_size)
               /. 2.0
          in
          draw_text text (Float.to_int text_x) (Float.to_int text_y)
            ctx.font_config.font_size Color.gray
      | Some chunk ->
          (* Calculate minimap tile size *)
          let available_w = Rectangle.width rect -. (padding *. 2.0) in
          let available_h = Rectangle.height rect -. (padding *. 2.0) in
          let tile_w = available_w /. Float.of_int Chunk.chunk_width in
          let tile_h = available_h /. Float.of_int Chunk.chunk_height in

          (* Draw chunk tiles *)
          Array.iteri chunk.tiles ~f:(fun y row ->
              Array.iteri row ~f:(fun x tile ->
                  let tile_screen_x =
                    Rectangle.x rect +. padding +. (Float.of_int x *. tile_w)
                  in
                  let tile_screen_y =
                    Rectangle.y rect +. padding +. (Float.of_int y *. tile_h)
                  in
                  let color = Dungeon.Tile.tile_to_color tile in
                  draw_rectangle
                    (Float.to_int tile_screen_x)
                    (Float.to_int tile_screen_y)
                    (Float.to_int (Float.max 1.0 tile_w))
                    (Float.to_int (Float.max 1.0 tile_h))
                    color));

          (* Draw player marker *)
          let player_marker_x =
            Rectangle.x rect +. padding
            +. (Float.of_int local_coords.x *. tile_w)
          in
          let player_marker_y =
            Rectangle.y rect +. padding
            +. (Float.of_int local_coords.y *. tile_h)
          in
          draw_rectangle
            (Float.to_int player_marker_x)
            (Float.to_int player_marker_y)
            (Float.to_int (Float.max 1.0 tile_w))
            (Float.to_int (Float.max 1.0 tile_h))
            Color.white;

          ())

(* --- Bottom Bar Helpers --- *)

(* Represents an ability shown on the bar *)
type displayed_ability = {
  name : string;
  key_display : string;
  action : Rl_types.Action.t;
}

(* Static list of abilities to display for now *)
let abilities_to_display : displayed_ability list =
  [
    {
      name = "Move";
      key_display = "Arrows/WASD";
      action = Rl_types.Action.Move Rl_types.Direction.North;
    };
    { name = "Wait"; key_display = "Space"; action = Rl_types.Action.Wait };
    (* TODO: Add Pickup, Interact, etc. as needed *)
  ]

(* Draws a single ability slot *)
let draw_ability_slot ~rect ~ability ~(font : Raylib.Font.t) ~(font_size : int)
    =
  let open Raylib in
  let padding = 4 in
  let font_size_f = Float.of_int font_size in
  (* Draw slot background/border (optional) *)
  (* draw_rectangle_rec rect (Color.create 40 40 40 200); *)
  draw_rectangle_lines_ex rect 1.0 Color.darkgray;

  (* Draw ability name *)
  let name_x = Float.to_int (Rectangle.x rect) + padding in
  let name_y = Float.to_int (Rectangle.y rect) + padding in
  draw_text_ex font ability.name
    (Vector2.create (Float.of_int name_x) (Float.of_int name_y))
    font_size_f 0. Color.lightgray;

  (* Draw keybind *)
  let key_text = Printf.sprintf "[%s]" ability.key_display in
  let key_text_width = measure_text key_text font_size in
  let key_x =
    Float.to_int
      (Rectangle.x rect +. Rectangle.width rect -. Float.of_int key_text_width)
    - padding
  in
  let key_y =
    Float.to_int (Rectangle.y rect +. Rectangle.height rect -. font_size_f)
    - padding
  in
  draw_text_ex font key_text
    (Vector2.create (Float.of_int key_x) (Float.of_int key_y))
    font_size_f 0. Color.gold;

  ()

(* --- Main Panel Renderers --- *)

let draw_bottom_bar ~rect ~(backend : Rl_core.Backend.t) ~(ctx : render_context)
    =
  let open Raylib in
  let padding = 4 in

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  (* TODO: Implement sections: Active Effects, Target Info *)
  let placeholder_text = "Bottom Bar Placeholder" in
  let text_w = measure_text placeholder_text ctx.font_config.font_size in
  let text_x = Rectangle.x rect +. (Float.of_int padding /. 2.0) in
  let text_y =
    Rectangle.y rect
    +. ((Rectangle.height rect -. Float.of_int ctx.font_config.font_size) /. 2.0)
  in
  draw_text placeholder_text (Float.to_int text_x) (Float.to_int text_y)
    ctx.font_config.font_size Color.gray;

  (* Draw Abilities Section (Right side) *)
  let ability_slot_width = 150.0 in
  let ability_slot_height =
    Rectangle.height rect -. (Float.of_int padding *. 2.0)
  in
  let ability_start_x =
    Rectangle.x rect +. Rectangle.width rect -. Float.of_int padding
  in

  List.iteri abilities_to_display ~f:(fun i ability ->
      let slot_x =
        ability_start_x -. (Float.of_int (i + 1) *. ability_slot_width)
      in
      let slot_y = Rectangle.y rect +. Float.of_int padding in
      let slot_rect =
        Rectangle.create slot_x slot_y ability_slot_width ability_slot_height
      in
      draw_ability_slot ~rect:slot_rect ~ability ~font:ctx.font_config.font
        ~font_size:ctx.font_config.font_size);

  ()
