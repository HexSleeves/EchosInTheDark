open Base
open Ppx_yojson_conv_lib.Yojson_conv

module CtrlMode = struct
  type t = Normal | WaitInput | AI | Died of float [@@deriving yojson]
end

module Loc = struct
  type t = { x : int; y : int }
  [@@deriving yojson, show, eq, compare, hash, sexp]

  let make x y = { x; y }
  let add a b = { x = a.x + b.x; y = a.y + b.y }
  let ( + ) = add
end

module Direction = struct
  type t = North | East | South | West [@@deriving yojson, show]

  let to_point = function
    | North -> Loc.make 0 (-1)
    | East -> Loc.make 1 0
    | South -> Loc.make 0 1
    | West -> Loc.make (-1) 0

  let to_string = function
    | North -> "North"
    | East -> "East"
    | South -> "South"
    | West -> "West"
end

(* //////////////////////// *)
(* STATS AND ITEMS *)

module Stats = struct
  type t = { max_hp : int; hp : int; attack : int; defense : int; speed : int }
  [@@deriving yojson, show]

  let default = { max_hp = 30; hp = 30; attack = 10; defense = 5; speed = 100 }

  let create ~max_hp ~hp ~attack ~defense ~speed =
    { max_hp; hp; attack; defense; speed }
end

module Item = struct
  type item_type = Potion | Sword | Scroll | Gold | Key
  [@@deriving yojson, eq, enum, show]

  type t = {
    id : int; (* Unique item instance ID *)
    item_type : item_type; (* What kind of item *)
    quantity : int; (* Stack count, if stackable *)
    name : string; (* Display name *)
    description : string option; (* Optional description *)
  }
  [@@deriving yojson, show]

  let create ~item_type ~quantity ~name ?(description = None) () =
    { id = 0; item_type; quantity; name; description }
end

module Inventory = struct
  type t = Item.t list [@@deriving yojson, show]
end

(* //////////////////////// *)
(* FACTIONS *)

type faction =
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
let faction_of_species (species : string) : faction =
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
let are_factions_hostile (f1 : faction) (f2 : faction) : bool =
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

(* //////////////////////// *)
(* ENTITY TYPES *)

module Entity = struct
  type id = int [@@deriving yojson, show]

  type base_entity = {
    id : id;
    name : string;
    glyph : string;
    blocking : bool;
    description : string option;
    direction : Direction.t;
  }
  [@@deriving yojson, show]

  type creature_data = { species : string; stats : Stats.t; faction : faction }
  [@@deriving yojson, show]

  type item_data = { item : Item.t } [@@deriving yojson, show]

  type t =
    | Player of base_entity
    | Creature of base_entity * creature_data
    | Item of base_entity * item_data
    | Corpse of base_entity
  [@@deriving yojson, show]

  let make_base_entity ~id ~name ~glyph ~description ~direction
      ?(blocking = true) () =
    { id; name; glyph; blocking; description; direction }

  let is_player = function Player _ -> true | _ -> false

  let get_id = function
    | Player base | Creature (base, _) | Item (base, _) | Corpse base -> base.id

  let get_name = function
    | Player base | Creature (base, _) | Item (base, _) | Corpse base ->
        base.name

  let get_blocking = function
    | Player base | Creature (base, _) | Item (base, _) | Corpse base ->
        base.blocking

  let get_base = function
    | Player base -> base
    | Creature (base, _) -> base
    | Item (base, _) -> base
    | Corpse base -> base
end

module Action = struct
  (*
  Enum type for all possible actions an actor can take.

  Action semantics:
  | Variant         | Description                                      | Parameters         |
  |-----------------|--------------------------------------------------|--------------------|
  | Move            | Move the actor in a direction if possible         | direction          |
  | Interact        | Interact with an entity (door, lever, etc.)       | id          |
  | Pickup          | Pick up an item from the ground                   | id          |
  | Drop            | Drop an item from inventory                       | id          |
  | Attack          | Attack another entity (combat)                    | id          |
  | StairsUp        | Use stairs to go up a level                       | -                  |
  | StairsDown      | Use stairs to go down a level                     | -                  |
  | Wait            | Do nothing for a turn                             | -                  |
*)

  type t =
    | Move of Direction.t
    | Interact of Entity.id
    | Pickup of Entity.id
    | Drop of Entity.id
    | Attack of Entity.id
    | StairsUp
    | StairsDown
    | Wait
  [@@deriving yojson, show]

  let to_string = function
    | Move dir -> "Move " ^ Direction.to_string dir
    | Interact id -> "Interact " ^ Int.to_string id
    | Pickup id -> "Pickup " ^ Int.to_string id
    | Drop id -> "Drop " ^ Int.to_string id
    | Attack id -> "Attack " ^ Int.to_string id
    | StairsUp -> "StairsUp"
    | StairsDown -> "StairsDown"
    | Wait -> "Wait"
end
