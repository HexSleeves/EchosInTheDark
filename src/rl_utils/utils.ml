open Base
module Bitset = Bitset
module Rng = Rng
module Fov = Fov

(* Indexing *)
let xy_to_index x y width = (y * width) + x

(* Utility: Convert flat index to (x, y) coordinates given map width *)
let index_to_xy (i : int) (width : int) : int * int = (i % width, i / width)

(* Safe array access: returns Some value or None if out of bounds *)
let array_get_opt arr idx =
  if idx >= 0 && idx < Array.length arr then Some arr.(idx) else None

(* Safe list nth: returns Some value or None if out of bounds *)
let list_nth_opt lst idx = Base.List.nth lst idx

(* Safe xy_to_index: returns Some index if in bounds, else None *)
let xy_to_index_opt x y width height =
  if x >= 0 && x < width && y >= 0 && y < height then Some ((y * width) + x)
  else None

let floor_div x y = if x >= 0 then x / y else ((x + 1) / y) - 1

let cartesian_product xs ys =
  List.concat_map xs ~f:(fun x -> List.map ys ~f:(fun y -> (x, y)))

let range a b = List.init (b - a) ~f:(( + ) a)

let ensure_dir path =
  if not (Stdlib.Sys.file_exists path) then Stdlib.Sys.mkdir path 0o755
