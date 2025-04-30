open Base

(* Define font_config and tileset_config types locally in the interface *)
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
  render_mode : Render_constants.render_mode; (* Use unqualified name *)
  tileset_config : tileset_config;
}
(** Rendering context containing window, font, and tileset configurations. *)

val create_render_context :
  ?title:string ->
  ?font_path:string ->
  ?font_size:int ->
  ?window_width:int ->
  ?window_height:int ->
  ?flags:Raylib.ConfigFlags.t list ->
  ?tile_width:int ->
  ?tile_height:int ->
  ?tileset_path:string ->
  ?render_mode:Render_constants.render_mode ->
  ?tile_render_size:int ->
  unit ->
  render_context
(** Creates and initializes the rendering context, including the Raylib window.
*)

val cleanup :
  render_context -> unit (* Changed from font_config to render_context *)
(** Cleans up rendering resources (font, window). *)

val render_fps_overlay :
  render_context -> unit (* Changed from font_config to render_context *)
(** Renders the FPS overlay. *)

val render_map_tiles :
  tiles:Dungeon.Tile.t array ->
  width:int ->
  skip_positions:Set.M(Render_utils.PosSet).t ->
  origin:Raylib.Vector2.t ->
  ctx:render_context ->
  unit
(** Renders the map tiles within the specified view. *)

val render_entities :
  entities:Rl_types.entity_id list ->
  origin:Raylib.Vector2.t ->
  ctx:render_context ->
  unit
(** Renders entities on the map. *)

val draw_message_log : messages:string list -> rect:Raylib.Rectangle.t -> unit
(** Renders the message log. *)

val draw_top_bar :
  rect:Raylib.Rectangle.t ->
  backend:Rl_core.Backend.t ->
  ctx:render_context ->
  unit
(** Renders the top status bar. *)

val draw_minimap :
  rect:Raylib.Rectangle.t ->
  backend:Rl_core.Backend.t ->
  ctx:render_context ->
  unit
(** Renders the minimap. *)

val draw_bottom_bar :
  rect:Raylib.Rectangle.t ->
  backend:Rl_core.Backend.t ->
  ctx:render_context ->
  unit
(** Renders the bottom UI bar (abilities, effects, target). *)
