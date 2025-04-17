open Base
open Types
module P = Pos

module LocKey = struct
  type t = P.loc

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
  Hashtbl.create (module LocKey)

class move_action (dir : P.direction) (entity : Entity.entity) =
  object
    method execute (backend : Common.backend) : (int, exn) Result.t =
      try
        let entity_id = entity.id in
        let x, y = entity.pos in
        let dx, dy =
          match dir with
          | P.North -> (0, -1)
          | P.South -> (0, 1)
          | P.East -> (1, 0)
          | P.West -> (-1, 0)
        in
        let new_x = x + dx in
        let new_y = y + dy in

        let within_bounds =
          new_x >= 0
          && new_x < backend#get_map_width
          && new_y >= 0
          && new_y < backend#get_map_height
        in

        let walkable = backend#is_tile_walkable new_x new_y in
        let no_entity_blocks =
          not (Hashtbl.mem blocked_positions (new_x, new_y))
        in

        if within_bounds && walkable && no_entity_blocks then (
          (* Remove from old position *)
          Hashtbl.remove blocked_positions (x, y);

          (* Add to new position *)
          Hashtbl.set blocked_positions ~key:(new_x, new_y) ~data:entity_id;

          backend#move_entity entity_id new_x new_y;

          Ok 100)
        else Error (Failure "Cannot move here")
      with exn -> Error exn

    method to_string : string =
      let direction_str =
        match dir with
        | P.North -> "north"
        | P.South -> "south"
        | P.East -> "east"
        | P.West -> "west"
      in
      Printf.sprintf "Move(%s, entity=%d, name=%s)" direction_str entity.id
        entity.name
  end

let make_move_action dir entity = new move_action dir entity
