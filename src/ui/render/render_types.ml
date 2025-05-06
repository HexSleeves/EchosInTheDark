open Base
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
  tile_render_size : Raylib.Vector2.t;
  font_config : font_config;
  flags : Raylib.ConfigFlags.t list;
  render_mode : Render_constants.render_mode;
  tileset_config : tileset_config;
  map_origin : Raylib.Vector2.t;
}
