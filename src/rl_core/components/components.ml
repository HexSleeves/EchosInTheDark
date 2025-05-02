open Base
open Rl_types

(* Exports *)
module Equipment = Equipment
module Faction = Faction
module Inventory = Inventory
module Item = Item
module Stats = Stats
module Field_of_view = Field_of_view

module Name = struct
  type t = { name : string }

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id name = Hashtbl.set table ~key:id ~data:name
  let get id = Hashtbl.find table id
end

module Description = struct
  type t = string

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id description = Hashtbl.set table ~key:id ~data:description
  let get id = Hashtbl.find table id
end

module Renderable = struct
  type t = { glyph : char }

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end

module Blocking = struct
  type t = bool

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end

module Position = struct
  open Chunk

  type t = {
    world_pos : world_pos;
    chunk_pos : chunk_coord;
    local_pos : local_pos;
  }
  [@@deriving yojson, show, eq]

  let table : (int, t) Hashtbl.t = Hashtbl.Poly.create ()
  let get id = Hashtbl.find table id

  let get_exn id =
    Option.value_exn (Hashtbl.find table id)
      ~message:(Printf.sprintf "No position for entity id %d" id)

  let set id pos = Hashtbl.set table ~key:id ~data:pos
  let remove id = Hashtbl.remove table id

  let show t =
    Printf.sprintf "World: %s, Chunk: %s, Local: %s"
      (Loc.to_string t.world_pos)
      (Loc.to_string t.chunk_pos)
      (Loc.to_string t.local_pos)

  let make (world : Loc.t) : t =
    let chunk : chunk_coord = world_to_chunk_coord world in
    let local : local_pos = world_to_local_coord world in
    { world_pos = world; chunk_pos = chunk; local_pos = local }
end

module Kind = struct
  type t = Player | Creature | Item | Corpse

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
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

  let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id species = Hashtbl.set table ~key:id ~data:species
  let get id = Hashtbl.find table id
end
