(*
  render_ui.ml
  Responsible for rendering UI panels: top bar, bottom bar, minimap, message log, overlays, etc.
  Contains functions for drawing all non-map, non-entity UI elements.
*)

open! Base
open! Raylib
open! Render_constants
open! Components
open! Render_utils
open! Render_types

let gold = Render_constants.color_gold
let dark_bg = Render_constants.color_dark_bg

let render_fps_overlay ~(ctx : render_context) =
  let open Raylib in
  let padding = 4 in
  let fc = ctx.font_config in

  let fps = get_fps () in
  let fps_text = Int.to_string fps in

  let text_width = measure_text fps_text fc.font_size in
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

(* //////////////////////////////////////////////////////////////// *)
(* Top Bar *)
(* //////////////////////////////////////////////////////////////// *)

let draw_top_bar ~rect ~(ctx : render_context) ~backend =
  let open Raylib in
  let padding = 4 in
  (* let line_height = ctx.font_config.font_size + padding in *)

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  (* Fetch Player Data *)
  let player_id = Game_core.Backend.get_player_id backend in
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

  (* --- Right Section (Date/Zone/Player Pos) --- *)
  (* TODO: Fetch Date/Time and Zone Name *)
  let player_pos_opt = Components.Position.get player_id in
  match player_pos_opt with
  | Some pos ->
      let world_pos = pos.world_pos in
      let local_pos = pos.local_pos in
      let chunk_pos = pos.chunk_pos in

      draw_text_ex ctx.font_config.font
        (Printf.sprintf "World: %d, %d" world_pos.x world_pos.y)
        (Vector2.create 10.0 (Float.of_int (text_y + 30)))
        (Float.of_int ctx.font_config.font_size)
        0. Color.white;

      draw_text_ex ctx.font_config.font
        (Printf.sprintf "Chunk: %d, %d" chunk_pos.x chunk_pos.y)
        (Vector2.create 150.0 (Float.of_int (text_y + 30)))
        (Float.of_int ctx.font_config.font_size)
        0. Color.white;

      draw_text_ex ctx.font_config.font
        (Printf.sprintf "Local: %d, %d" local_pos.x local_pos.y)
        (Vector2.create 270.0 (Float.of_int (text_y + 30)))
        (Float.of_int ctx.font_config.font_size)
        0. Color.white
  | None -> ()

(* //////////////////////////////////////////////////////////////// *)
(* Bottom Bar *)
(* //////////////////////////////////////////////////////////////// *)

type displayed_ability = {
  name : string;
  key_display : string;
  action : Types.Action.t;
}

let abilities_to_display : displayed_ability list =
  [
    {
      name = "Move";
      key_display = "Arrows/WASD";
      action = Types.Action.Move Types.Direction.North;
    };
    { name = "Wait"; key_display = "Space"; action = Types.Action.Wait };
  ]

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

let draw_bottom_bar ~rect ~(ctx : render_context) =
  let open Raylib in
  let padding = 4 in

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  let placeholder_text = "Bottom Bar Placeholder" in
  (* let text_w = measure_text placeholder_text ctx.font_config.font_size in *)
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

(* //////////////////////////////////////////////////////////////// *)
(* Minimap *)
(* //////////////////////////////////////////////////////////////// *)

let draw_minimap ~rect ~(backend : Game_core.Backend.t) ~(ctx : render_context)
    =
  let open Raylib in
  let padding = 2.0 in

  (* Draw background and border *)
  draw_rectangle_rec rect dark_bg;
  draw_rectangle_lines_ex rect 1.0 gold;

  (* Get Player Position and Chunk Data *)
  let player_id = Game_core.Backend.get_player_id backend in
  let player_pos_opt = Components.Position.get player_id in
  let chunk_manager = Game_core.Backend.get_chunk_manager backend in

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
      let local_coords : Types.Loc.t =
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
          let tile_w = available_w /. Float.of_int Constants.chunk_w in
          let tile_h = available_h /. Float.of_int Constants.chunk_h in

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

(* //////////////////////////////////////////////////////////////// *)
(* Message Log *)
(* //////////////////////////////////////////////////////////////// *)

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
      draw_text msg x (y + (i * line_height)) 18 color);

  draw_text "Message Log" x y 20 Color.blue
