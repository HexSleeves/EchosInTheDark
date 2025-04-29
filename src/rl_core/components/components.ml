open Base
open Types

(* Exports *)
module Equipment = Equipment
module Faction = Faction
module Inventory = Inventory
module Item = Item
module Stats = Stats

module Name = struct
  type t = { name : string }

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id name = Hashtbl.set table ~key:id ~data:name
  let get id = Hashtbl.find table id
end

module Description = struct
  type t = string

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id description = Hashtbl.set table ~key:id ~data:description
  let get id = Hashtbl.find table id
end

module Renderable = struct
  type t = { glyph : char }

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end

module Blocking = struct
  type t = bool

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
end

module Position = struct
  type t = Types.Loc.t

  let table : (int, t) Hashtbl.t = Hashtbl.Poly.create ()
  let get id = Hashtbl.find table id

  let get_exn id =
    Option.value_exn (Hashtbl.find table id)
      ~message:(Printf.sprintf "No position for entity id %d" id)

  let set id pos = Hashtbl.set table ~key:id ~data:pos
  let remove id = Hashtbl.remove table id
end

module Kind = struct
  type t = Player | Creature | Item | Corpse

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end
