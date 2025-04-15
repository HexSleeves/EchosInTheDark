open Base
open Ppx_yojson_conv_lib.Yojson_conv

type loc = int * int [@@deriving yojson, show]
type direction = North | East | South | West [@@deriving yojson, show]
type faction = int [@@deriving yojson, show]

type stats = {
  max_hp : int;
  hp : int;
  attack : int;
  defense : int;
  speed : int;
}
[@@deriving yojson]

type item_type = Potion | Sword | Scroll | Gold | Key
[@@deriving yojson, show, eq, enum]

type item = {
  id : int; (* Unique item instance ID *)
  item_type : item_type; (* What kind of item *)
  quantity : int; (* Stack count, if stackable *)
  name : string; (* Display name *)
  description : string option; (* Optional description *)
}
[@@deriving yojson, show]

type inventory = item list [@@deriving yojson]

(* Kind of entity in the game world *)
type entity_kind = Player | Creature | Item | Other of string
[@@deriving yojson, show]

(* Data specific to each entity kind *)
type entity_data =
  | PlayerData of {
      health : int;
      faction : faction;
          (* Add more player-specific fields here, e.g., inventory, health, etc. *)
    }
  | CreatureData of {
      species : string;
      faction : faction;
      health : int; (* Add more creature-specific fields here *)
    }
  | ItemData of {
      item_type : string;
      quantity : int; (* Add more item-specific fields here *)
    }
[@@deriving yojson, show]
