open Containers

(* Indexing *)
let calc_offset width x y = (y * width) + x

(* SDL *)
let get_time () = Raylib.get_time ()
let get_delta_time () = Raylib.get_frame_time ()

(* *)
let round_prob xf =
  let z = int_of_float (floor xf) in
  let dz = if Rng.float 1.0 Rng.state <. xf -. float z then 1 else 0 in
  z + dz

let round xf = int_of_float (floor (0.5 +. xf))
let rec fold_lim f a x xl = if x <= xl then fold_lim f (f a x) (x + 1) xl else a
let vec_of_loc (i, j) = (float i, float j)
let vec_len (x, y) = sqrt ((x *. x) +. (y *. y))
