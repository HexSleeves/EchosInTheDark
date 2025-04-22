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

type direction = North | East | South | West [@@deriving yojson, show]

module Direction = struct
  type t = direction [@@deriving yojson, show]

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

type stats = {
  max_hp : int;
  hp : int;
  attack : int;
  defense : int;
  speed : int;
}
[@@deriving yojson]

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

type inventory = item list [@@deriving yojson]

(* //////////////////////// *)
(* ENTITY TYPES *)

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
  direction : direction;
  kind : entity_kind;
  data : entity_data;
}
[@@deriving yojson]

(* Player reference type *)
type player = { entity_id : entity_id } [@@deriving yojson]
