open Ppx_yojson_conv_lib.Yojson_conv

type faction = int [@@deriving yojson, show]
type loc = int * int [@@deriving yojson, show]
type direction = North | East | South | West [@@deriving yojson, show]

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
