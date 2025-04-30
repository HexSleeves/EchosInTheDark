open Base
open Dungeon

let load_prefab ~width ~height filename =
  let lines = Stdio.In_channel.read_lines filename in
  let prefab_height = List.length lines in
  let prefab_width =
    List.fold_left lines ~init:0 ~f:(fun acc l -> max acc (String.length l))
  in
  let grid = Stdlib.Array.make (width * height) Tile.Wall in

  let y_offset = max 0 ((height - prefab_height) / 2) in
  let x_offset = max 0 ((width - prefab_width) / 2) in

  Base.List.iteri lines ~f:(fun y line ->
      if y + y_offset < height then
        Base.String.iteri line ~f:(fun x ch ->
            if x + x_offset < width then
              match
                Rl_utils.Utils.xy_to_index_opt (x + x_offset) (y + y_offset)
                  width height
              with
              | Some idx when idx >= 0 && idx < Array.length grid ->
                  grid.(idx) <-
                    (match ch with
                    | '.' -> Tile.Floor
                    | '#' -> Tile.Wall
                    | '>' -> Tile.Stairs_down
                    | '<' -> Tile.Stairs_up
                    | '~' -> Tile.Water
                    | 'S' -> Tile.Secret_door
                    | 'C' -> Tile.Chasm
                    | 'D' -> Tile.Door
                    | 'T' -> Tile.Tree
                    | _ -> Tile.Unknown)
              | _ -> ()));
  grid
