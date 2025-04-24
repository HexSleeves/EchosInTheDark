open Base
open Ppx_yojson_conv_lib.Yojson_conv

module CtrlMode = struct
  type t = Normal | WaitInput | Died of float
  (* [@@deriving yojson] *)
end

module Loc = struct
  type t = { x : int; y : int } [@@deriving yojson, show, eq]

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
(* ENTITY TYPES *)

module Entity = struct
  type id = int [@@deriving yojson, show]

  type base_entity = {
    id : id;
    pos : Loc.t;
    name : string;
    glyph : string;
    blocking : bool;
    description : string option;
    direction : Direction.t;
  }
  [@@deriving yojson, show]

  let make_base_entity ?(blocking = true) ~id ~pos ~name ~glyph ~description
      ~direction () =
    { id; pos; name; glyph; blocking; description; direction }

  type player_data = { stats : Stats.t } [@@deriving yojson, show]

  type creature_data = { species : string; stats : Stats.t }
  [@@deriving yojson, show]

  type item_data = { item : Item.t } [@@deriving yojson, show]

  type t =
    | Player of base_entity * player_data
    | Creature of base_entity * creature_data
    | Item of base_entity * item_data
    | Corpse of base_entity
  [@@deriving yojson, show]

  let get_id = function
    | Player (base, _) | Creature (base, _) | Item (base, _) | Corpse base ->
        base.id

  let get_blocking = function
    | Player (base, _) | Creature (base, _) | Item (base, _) | Corpse base ->
        base.blocking

  let get_base = function
    | Player (base, _) -> base
    | Creature (base, _) -> base
    | Item (base, _) -> base
    | Corpse base -> base

  let get_pos = function
    | Player (base, _) | Creature (base, _) | Item (base, _) | Corpse base ->
        base.pos
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
