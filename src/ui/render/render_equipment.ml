(*
  render_equipment.ml
  Responsible for rendering equipment slots, inventory, and related UI in the roguelike.
  Contains functions for drawing all equipment/inventory UI elements.
*)

open! Base
open! Raylib
open! Types
open! Render_constants
open! Components
open! Render_utils
open! Render_types

let gold = Render_constants.color_gold
let dark_bg = Render_constants.color_dark_bg

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
