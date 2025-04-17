open Ppx_yojson_conv_lib.Yojson_conv

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
