open Base
open Ppx_yojson_conv_lib.Yojson_conv

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

let table : (int, t) Hashtbl.t = Hashtbl.create (module Int)
let set id data = Hashtbl.set table ~key:id ~data
let get id = Hashtbl.find table id
