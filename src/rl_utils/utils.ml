open Base

(* Indexing *)
let xy_to_index x y width = (y * width) + x

(* Utility: Convert flat index to (x, y) coordinates given map width *)
let index_to_xy (i : int) (width : int) : int * int = (i % width, i / width)
