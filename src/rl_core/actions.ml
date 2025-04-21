(* open Base
module T = Types

module LocKey = struct
  type t = T.loc

  let compare (x1, y1) (x2, y2) =
    let c = Int.compare x1 x2 in
    if c <> 0 then c else Int.compare y1 y2

  let hash (x, y) = Hashtbl.hash (x, y)

  let sexp_of_t (x, y) =
    Sexp.List [ Sexp.Atom (Int.to_string x); Sexp.Atom (Int.to_string y) ]

  let t_of_sexp sexp =
    match sexp with
    | Sexp.List [ Sexp.Atom x; Sexp.Atom y ] ->
        (Int.of_string x, Int.of_string y)
    | _ -> failwith "Invalid sexp for LocKey"
end

(* List of entity IDs blocking specific positions *)
let blocked_positions : (LocKey.t, int) Hashtbl.t =
  Hashtbl.create (module LocKey) *)
