open Types

(* Helper to convert direction to position delta *)
let direction_to_point (dir : direction) : Loc.t =
  match dir with
  | North -> Loc.make 0 (-1)
  | South -> Loc.make 0 1
  | East -> Loc.make 1 0
  | West -> Loc.make (-1) 0
