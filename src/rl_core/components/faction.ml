open Base
open Types

module Faction_data = struct
  type t =
    [ `Player
    | `Vermin
    | `Kobold
    | `Goblin
    | `Undead
    | `Elemental
    | `Abomination
    | `Neutral
    | `FriendlyBug
    | `Other of string ]
  [@@deriving yojson, show, eq]
  (** Faction type for entities. Expand as needed. *)
end

type t = Faction_data.t

let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
let set id data = Hashtbl.set table ~key:id ~data
let get id = Hashtbl.find table id
