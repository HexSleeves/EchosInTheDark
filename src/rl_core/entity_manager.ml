open Base
open Types

type t = Entity.entity Map.M(Int).t

type partial_entity = {
  pos : Loc.t;
  name : string;
  glyph : string;
  description : string option;
  direction : Direction.t;
  kind : Entity.entity_kind;
  data : Entity.entity_data;
}

let create () : t = Map.empty (module Int)
let add (mgr : t) (ent : Entity.entity) : t = Map.set mgr ~key:ent.id ~data:ent
let remove (mgr : t) (id : int) : t = Map.remove mgr id
let find (mgr : t) (id : int) : Entity.entity option = Map.find mgr id

let find_unsafe (mgr : t) (id : int) : Entity.entity =
  match find mgr id with
  | Some ent -> ent
  | None -> failwith (Printf.sprintf "Entity not found: %d" id)

let find_by_pos (mgr : t) (pos : Loc.t) : Entity.entity option =
  Map.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      match acc with
      | Some _ -> acc
      | None -> if Loc.equal pos data.pos then Some data else None)

let update (mgr : t) (id : int) (f : Entity.entity -> Entity.entity) : t =
  match Map.find mgr id with
  | Some ent -> Map.set mgr ~key:id ~data:(f ent)
  | None -> mgr

let to_list (mgr : t) : Entity.entity list = Map.data mgr

let add_entity (mgr : t) (p : partial_entity) : t * int * Entity.entity =
  let id : Entity.entity_id =
    match Map.max_elt mgr with Some (max_id, _) -> max_id + 1 | None -> 0
  in
  let entity : Entity.entity =
    {
      id;
      name = p.name;
      glyph = p.glyph;
      description = p.description;
      kind = p.kind;
      pos = p.pos;
      direction = p.direction;
      data = p.data;
    }
  in
  (Map.set mgr ~key:id ~data:entity, id, entity)

let copy (t : t) : t = t (* Map is persistent, so this is just identity *)
let restore (_t : t) (src : t) : t = src (* Just return the source *)
