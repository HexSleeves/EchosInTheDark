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
  let get id = Hashtbl.find table id
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
  let show t = Types.Loc.show t
end

module Kind = struct
  type t = Player | Creature | Item | Corpse

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end
[@@deriving show]

module Species = struct
  type t =
    [ `Bat
    | `Bloated_Bat
    | `Cave_Beetle
    | `Copper_Slime
    | `Crystalline_Horror
    | `Deep_Worm
    | `Elemental_Guardian
    | `FriendlyBug
    | `Giant_Cave_Rat
    | `Giant_Spider
    | `Glowbug
    | `Goblin
    | `Goblin_Sapper
    | `Goblin_Shaman
    | `Grumbling_Kobold
    | `Illithid
    | `Iron_Slime
    | `Kobold
    | `Kobold_Mage
    | `Kobold_Sapper
    | `Kobold_Shaman
    | `Kobold_Warrior
    | `Mind_Flayer
    | `Mutated_Abomination
    | `Ore_Slime
    | `Player
    | `Rat
    | `Rock_Golem
    | `Shadow_Creeper
    | `Spider
    | `Undead_Miner ]
  [@@deriving yojson, show, eq, compare, hash, sexp]

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id species = Hashtbl.set table ~key:id ~data:species
  let get id = Hashtbl.find table id
end
