open Raylib
open Base

(* Font configuration for grid rendering *)
type font_config = { font : Font.t; font_size : int }

val create :
  ?title:string -> ?font_path:string -> ?font_size:int -> unit -> font_config

val tile_glyph_and_color : Rl_core.Map.Tile.t -> char * Color.t
val grid_to_screen : Rl_core.Types.Loc.t -> Vector2.t
val screen_to_grid : Vector2.t -> Rl_core.Types.Loc.t

val render_cell :
  string -> Color.t -> font_config -> Rl_core.Types.Loc.t -> unit

val entity_glyph : Rl_core.Types.Entity.t -> string
val entity_color : Rl_core.Types.Entity.t -> Color.t
val draw_fps_overlay : font_config -> unit

module PosSet : sig
  type t = int * int [@@deriving compare, sexp]

  include Comparator.S with type t := t
end

val occupied_positions : Rl_core.Types.Entity.t list -> Set.M(PosSet).t
val index_to_xy : int -> int -> int * int
val cleanup : font_config -> unit

val render_map_tiles :
  tiles:Rl_core.Map.Tile.t array ->
  width:int ->
  skip_positions:Base.Set.M(PosSet).t ->
  font_config:font_config ->
  origin:Raylib.Vector2.t ->
  unit

val render_entities :
  entities:Rl_core.Types.Entity.t list ->
  font_config:font_config ->
  origin:Raylib.Vector2.t ->
  unit

val draw_stats_bar_vertical :
  player:Rl_core.Types.Entity.t -> rect:Rectangle.t -> unit

val draw_message_log : messages:string list -> rect:Rectangle.t -> unit
val init_font_config : font_path:string -> font_size:int -> font_config

module Ui_constants : sig
  val log_height : int
  val stats_bar_width_min : int
  val stats_bar_width_frac : float
end
