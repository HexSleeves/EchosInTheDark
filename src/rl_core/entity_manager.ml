open Base
open Ppx_yojson_conv_lib.Yojson_conv
open Types

type t = (int, entity) Hashtbl.t

type partial_entity = {
  pos : Loc.t;
  name : string;
  glyph : string;
  description : string option;
  direction : direction;
  kind : entity_kind;
  data : entity_data;
}

let create () : t = Hashtbl.create (module Int)
let add (mgr : t) (ent : entity) = Hashtbl.set mgr ~key:ent.id ~data:ent
let remove (mgr : t) (id : int) = Hashtbl.remove mgr id
let find (mgr : t) (id : int) : entity option = Hashtbl.find mgr id

let find_unsafe (mgr : t) (id : int) : entity =
  match find mgr id with
  | Some ent -> ent
  | None -> failwith (Printf.sprintf "Entity not found: %d" id)

let find_by_pos (mgr : t) (pos : Loc.t) : entity option =
  Hashtbl.fold mgr ~init:None ~f:(fun ~key:_ ~data acc ->
      match acc with
      | Some _ -> acc
      | None -> if Loc.equal pos data.pos then Some data else None)

let update (mgr : t) (id : int) (f : entity -> entity) =
  match Hashtbl.find mgr id with
  | Some ent -> Hashtbl.set mgr ~key:id ~data:(f ent)
  | None -> ()

let to_list (mgr : t) : entity list =
  Hashtbl.fold mgr ~init:[] ~f:(fun ~key:_ ~data acc -> data :: acc)
  |> List.rev (* Reverse to maintain insertion order *)

let add_entity (mgr : t) (p : partial_entity) =
  let id = Hashtbl.length mgr in
  let entity =
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
  Hashtbl.set mgr ~key:id ~data:entity;
  (id, entity)

let copy (t : t) : t =
  let new_entities = Base.Hashtbl.create (module Base.Int) in
  Base.Hashtbl.iteri t ~f:(fun ~key ~data ->
      Base.Hashtbl.set new_entities ~key ~data);
  new_entities

let restore (t : t) (src : t) : unit =
  Base.Hashtbl.clear t;
  Base.Hashtbl.iteri src ~f:(fun ~key ~data -> Base.Hashtbl.set t ~key ~data)
