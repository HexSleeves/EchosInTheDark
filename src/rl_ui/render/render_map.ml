(*
  render_map.ml
  Responsible for rendering the map grid, tiles, and entities in the roguelike.
  Contains functions for drawing the map and all in-chunk entities.
*)

open! Base
open! Raylib
open! Rl_types
open! Render_constants
open! Components
open! Rl_utils
open! Render_types

let render_tileset_sprite ~entity_id ~origin ~pos ~texture ~tile_render_size =
  let col, row = Render_utils.entity_to_sprite_coords entity_id in
  Render_utils.draw_texture_ex ~texture ~pos ~origin ~tile_render_size ~col ~row

let render_tileset_tile ~texture ~tile ~loc ~origin ~tile_render_size =
  let col, row = Tile.tile_to_tileset tile in
  Render_utils.draw_texture_ex ~texture ~pos:loc ~origin ~tile_render_size ~col
    ~row

let render_ascii_cell ~glyph ~color ~fc ~loc ~origin ~tile_render_size =
  let open Raylib in
  let open Render_utils in
  let font_size = Vector2.x tile_render_size in
  let glyph_size = measure_text_ex fc.font glyph font_size 0. in

  let screen_pos =
    let base_pos = grid_to_screen ~tile_render_size loc in
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

let render_map_tiles ~tiles ~width ~skip_positions ~origin ~ctx =
  Array.iteri
    ~f:(fun i t ->
      let x, y = Utils.index_to_xy i width in
      if not (Set.mem skip_positions (x, y)) then
        let loc = Loc.make x y in
        match (ctx.render_mode, ctx.tileset_config) with
        | Tiles, t_cfg ->
            render_tileset_tile ~texture:t_cfg.texture ~tile:t ~loc ~origin
              ~tile_render_size:ctx.tile_render_size
        | _ ->
            let glyph, color = Render_utils.tile_glyph_and_color t in
            render_ascii_cell ~glyph ~color ~fc:ctx.font_config ~loc ~origin
              ~tile_render_size:ctx.tile_render_size)
    tiles

let render_entities ~entities ~origin ~ctx =
  let open Render_utils in
  let font_config = ctx.font_config in
  let drawn = ref (Set.empty (module Int)) in

  List.iter entities ~f:(fun entity_id ->
      let world_position = Position.get_exn entity_id in
      let local_pos =
        Chunk_manager.world_to_local_coord world_position.world_pos
      in

      let pos_tuple = (local_pos.x lsl 16) lor local_pos.y in
      if not (Set.mem !drawn pos_tuple) then (
        drawn := Set.add !drawn pos_tuple;

        match (ctx.render_mode, ctx.tileset_config) with
        | Tiles, t_cfg ->
            render_tileset_sprite ~entity_id ~origin ~pos:local_pos
              ~texture:t_cfg.texture ~tile_render_size:ctx.tile_render_size
        | _ ->
            let glyph, color = entity_glyph_and_color entity_id in
            render_ascii_cell ~glyph ~color ~fc:font_config ~loc:local_pos
              ~origin ~tile_render_size:ctx.tile_render_size))
