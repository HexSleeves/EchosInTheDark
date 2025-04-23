open Raylib
open Base

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

  (* Creates a window of the monitor size. *)
  init_window 1280 720 title;
  set_window_min_size 1280 720;

  (* Get monitor dimensions *)
  let current_monitor = get_current_monitor () in
  let monitor_w = get_monitor_width current_monitor in
  let monitor_h = get_monitor_height current_monitor in

  (* Calculate target dimensions (e.g., 80% of height) *)
  let target_h = Float.of_int monitor_h *. 0.8 in
  let num_tiles_h = Int.of_float (target_h /. Float.of_int tile_height) in
  let window_h = num_tiles_h * tile_height in

  (* Calculate width based on 80% of monitor width *)
  let target_w = Float.of_int monitor_w *. 0.8 in
  let num_tiles_w = Int.of_float (target_w /. Float.of_int tile_width) in
  let window_w = num_tiles_w * tile_width in

  Ui_log.info (fun m -> m "Target size: [%f %f]" target_w target_h);
  Ui_log.info (fun m -> m "Num tiles: [%d %d]" num_tiles_w num_tiles_h);
  Ui_log.info (fun m -> m "Window size: [%d %d]" window_w window_h);

  set_target_fps 60;

  (* Set window size and min size *)
  (* set_window_size window_w window_h; *)
  (* set_window_min_size window_w window_h; *)

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
      Stdlib.Format.eprintf "Warning: Unhandled tile type encountered@.";
      ("?", Color.red)

(* Map grid (tile) position to screen position using FontConfig *)
let grid_to_screen (loc : Rl_core.Types.Loc.t) =
  Raylib.Vector2.create
    (Float.of_int loc.x *. Float.of_int tile_width)
    (Float.of_int loc.y *. Float.of_int tile_height)

let screen_to_grid (vec : Vector2.t) =
  Rl_core.Types.Loc.make
    (Float.to_int (Vector2.x vec /. Float.of_int tile_width))
    (Float.to_int (Vector2.y vec /. Float.of_int tile_height))

let render_cell glyph color (fc : font_config) (loc : Rl_core.Types.Loc.t) =
  let font_size = Float.of_int fc.font_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let offset =
    Vector2.create
      ((Float.of_int tile_width -. Vector2.x glyph_size) /. 2.)
      ((Float.of_int tile_height -. Vector2.y glyph_size) /. 2.)
  in

  let spacing = 0. in
  let screen_pos = grid_to_screen loc in
  let centered_pos = Vector2.add screen_pos offset in

  (* Font, Text, Position, Font-size, Spacing, Color *)
  draw_text_ex fc.font glyph centered_pos font_size spacing color
(* --- END MERGED FROM grafx.ml --- *)

(* Get glyph for an entity *)
let entity_glyph (entity : Rl_core.Types.Entity.t) : string =
  let base = Rl_core.Types.Entity.get_base entity in
  base.glyph

(* Get color for an entity *)
let entity_color (entity : Rl_core.Types.Entity.t) : Color.t =
  match entity with
  | Rl_core.Types.Entity.Player _ -> Color.white
  | Rl_core.Types.Entity.Creature _ -> Color.red
  | Rl_core.Types.Entity.Item _ -> Color.yellow
  | Rl_core.Types.Entity.Corpse _ -> Color.gray

(* Draw FPS overlay in the corner *)
let draw_fps_overlay (fc : font_config) : unit =
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

(* Utility: Get set of occupied positions from a list of entities *)
module PosSet = struct
  module T = struct
    type t = int * int [@@deriving compare, sexp]
  end

  include T
  include Comparator.Make (T)
end

let occupied_positions (entities : Rl_core.Types.Entity.t list) :
    Set.M(PosSet).t =
  List.fold entities
    ~init:(Set.empty (module PosSet))
    ~f:(fun acc e ->
      let base = Rl_core.Types.Entity.get_base e in
      Set.add acc (base.pos.x, base.pos.y))

(* Utility: Convert flat index to (x, y) coordinates given map width *)
let index_to_xy (i : int) (width : int) : int * int = (i % width, i / width)

(* Utility: Render map tiles, skipping those in skip_positions *)
let render_map_tiles ~tiles ~width ~skip_positions ~font_config =
  Array.iteri tiles ~f:(fun i t ->
      let x, y = index_to_xy i width in
      if not (Set.mem skip_positions (x, y)) then
        let glyph, color = tile_glyph_and_color t in
        render_cell glyph color font_config (Rl_core.Types.Loc.make x y))

(* Utility: Render all entities *)
let render_entities ~entities ~font_config =
  List.iter entities ~f:(fun entity ->
      let color = entity_color entity in
      let glyph = entity_glyph entity in
      let base = Rl_core.Types.Entity.get_base entity in
      render_cell glyph color font_config base.pos)
