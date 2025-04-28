open Base

(* Indexing *)
let xy_to_index x y width = (y * width) + x

(* Utility: Convert flat index to (x, y) coordinates given map width *)
let index_to_xy (i : int) (width : int) : int * int = (i % width, i / width)

(* Safe array access: returns Some value or None if out of bounds *)
let array_get_opt arr idx =
  if idx >= 0 && idx < Array.length arr then Some arr.(idx) else None

(* Safe list nth: returns Some value or None if out of bounds *)
let list_nth_opt lst idx =
  if idx < 0 then None
  else
    let rec aux i = function
      | [] -> None
      | x :: xs -> if i = 0 then Some x else aux (i - 1) xs
    in
    aux idx lst

(* Safe xy_to_index: returns Some index if in bounds, else None *)
let xy_to_index_opt x y width height =
  if x >= 0 && x < width && y >= 0 && y < height then Some ((y * width) + x)
  else None
