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

  (** Map a species string to a default faction. Expand as needed. *)
  let faction_of_species (species : string) : t =
    match String.lowercase species with
    | "rat" | "giant cave rat" | "bat" | "bloated bat" | "ore slime"
    | "copper slime" | "iron slime" ->
        `Vermin
    | "kobold" | "grumbling kobold" -> `Kobold
    | "goblin" | "goblin sapper" -> `Goblin
    | "rock golem" -> `Elemental
    | "giant spider" -> `Vermin
    | "shadow creeper" -> `Abomination
    | "undead miner" -> `Undead
    | "deep worm" -> `Abomination
    | "crystalline horror" -> `Elemental
    | "mind flayer" | "illithid" -> `Abomination
    | "elemental guardian" -> `Elemental
    | "mutated abomination" -> `Abomination
    | "glowbug" | "cave beetle" -> `FriendlyBug
    | _ -> `Neutral

  (** Determine if two factions are hostile to each other. *)
  let are_factions_hostile (f1 : t) (f2 : t) : bool =
    match (f1, f2) with
    | `Player, `Player -> false
    | `Player, (`FriendlyBug | `Neutral) -> false
    | (`FriendlyBug | `Neutral), `Player -> false
    | `FriendlyBug, `FriendlyBug -> false
    | `Vermin, `Vermin -> false
    | `Kobold, `Kobold -> false
    | `Goblin, `Goblin -> false
    | `Elemental, `Elemental -> false
    | `Undead, `Undead -> false
    | `Abomination, `Abomination -> false
    | `Player, _ | _, `Player -> true
    | `Vermin, _ | _, `Vermin -> true
    | `Kobold, _ | _, `Kobold -> true
    | `Goblin, _ | _, `Goblin -> true
    | `Elemental, _ | _, `Elemental -> true
    | `Undead, _ | _, `Undead -> true
    | `Abomination, _ | _, `Abomination -> true
    | `FriendlyBug, _ | _, `FriendlyBug -> false
    | `Neutral, _ | _, `Neutral -> false
    | `Other a, `Other b -> String.equal a b
end

module Faction = struct
  type t = Faction_data.t

  let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
  let set id data = Hashtbl.set table ~key:id ~data
  let get id = Hashtbl.find table id
end
