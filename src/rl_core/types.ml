open Ppx_yojson_conv_lib.Yojson_conv

module CtrlMode = struct
  type t = Normal | WaitInput | Died of float
  (* [@@deriving yojson] *)
end

module Loc = struct
  type t = { x : int; y : int } [@@deriving yojson, show]

  let make x y = { x; y }
  let add a b = { x = a.x + b.x; y = a.y + b.y }
  let ( + ) = add
end

type entity_id = int [@@deriving yojson, show]

(* type faction = int [@@deriving yojson, show] *)
type loc = Loc.t [@@deriving yojson, show]
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
