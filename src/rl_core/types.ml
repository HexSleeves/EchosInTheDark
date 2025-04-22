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
(* ENTITY TYPES *)

module Entity = struct
  type entity_id = int [@@deriving yojson, show]

  type entity_kind = Player | Creature | Item | Other of string
  [@@deriving yojson]

  (* Data specific to each entity kind *)
  type entity_data =
    | PlayerData of { health : int; actor_id : int }
    | CreatureData of {
        species : string;
        (* faction : faction; *)
        health : int;
        actor_id : int;
      }
    | ItemData of { item_type : string; quantity : int }
  [@@deriving yojson]

  type entity = {
    id : entity_id;
    pos : Loc.t;
    name : string;
    glyph : string;
    description : string option;
    direction : Direction.t;
    kind : entity_kind;
    data : entity_data;
  }
  [@@deriving yojson]

  (* Player reference type *)
  type player = { entity_id : entity_id } [@@deriving yojson]
end

module Action = struct
  (*
  Enum type for all possible actions an actor can take.

  Action semantics:
  | Variant         | Description                                      | Parameters         |
  |-----------------|--------------------------------------------------|--------------------|
  | Move            | Move the actor in a direction if possible         | direction          |
  | Interact        | Interact with an entity (door, lever, etc.)       | entity_id          |
  | Pickup          | Pick up an item from the ground                   | entity_id          |
  | Drop            | Drop an item from inventory                       | entity_id          |
  | Attack          | Attack another entity (combat)                    | entity_id          |
  | StairsUp        | Use stairs to go up a level                       | -                  |
  | StairsDown      | Use stairs to go down a level                     | -                  |
  | Wait            | Do nothing for a turn                             | -                  |
*)

  type action_type =
    | Move of Direction.t
    | Interact of Entity.entity_id
    | Pickup of Entity.entity_id
    | Drop of Entity.entity_id
    | Attack of Entity.entity_id
    | StairsUp
    | StairsDown
    | Wait

  let to_string = function
    | Move dir -> "Move " ^ Direction.to_string dir
    | Interact id -> "Interact " ^ string_of_int id
    | Pickup id -> "Pickup " ^ string_of_int id
    | Drop id -> "Drop " ^ string_of_int id
    | Attack id -> "Attack " ^ string_of_int id
    | StairsUp -> "StairsUp"
    | StairsDown -> "StairsDown"
    | Wait -> "Wait"
end

(* //////////////////////// *)
(* STATS AND ITEMS *)

type stats = {
  max_hp : int;
  hp : int;
  attack : int;
  defense : int;
  speed : int;
}
[@@deriving yojson]

module Item = struct
  type item_type = Potion | Sword | Scroll | Gold | Key
  [@@deriving yojson, eq, enum]

  type item = {
    id : int; (* Unique item instance ID *)
    item_type : item_type; (* What kind of item *)
    quantity : int; (* Stack count, if stackable *)
    name : string; (* Display name *)
    description : string option; (* Optional description *)
  }
  [@@deriving yojson]
end

module Inventory = struct
  type t = Item.item list [@@deriving yojson]
end
