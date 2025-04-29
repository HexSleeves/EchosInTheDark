open Base
open Types
open Ppx_yojson_conv_lib.Yojson_conv

module StatModifiers = struct
  type t = {
    attack : int;
    defense : int;
    speed : int;
    max_hp : int; (* Add more as needed *)
  }
  [@@deriving yojson, show]

  let empty = { attack = 0; defense = 0; speed = 0; max_hp = 0 }
end

module Item_data = struct
  type item_type = Potion | Sword | Scroll | Gold | Key
  [@@deriving yojson, eq, enum, show]

  type slot_type =
    | Head
    | Chest
    | Legs
    | Weapon
    | Shield
    | Accessory
    | NoneSlot
  [@@deriving yojson, eq, enum, show]

  type t = {
    id : int; (* Unique item instance ID *)
    item_type : item_type; (* What kind of item *)
    quantity : int; (* Stack count, if stackable *)
    name : string; (* Display name *)
    description : string option; (* Optional description *)
    slot_type : slot_type;
        (* What slot this item can be equipped in, or NoneSlot *)
    stat_modifiers : StatModifiers.t; (* Stat changes when equipped *)
    is_corrupted : bool; (* Is this item corrupted? *)
    corruption_effects : string option; (* Description of corruption effects *)
  }
  [@@deriving yojson, show]

  let create ~item_type ~quantity ~name ?(description = None)
      ?(slot_type = NoneSlot) ?(stat_modifiers = StatModifiers.empty)
      ?(is_corrupted = false) ?(corruption_effects = None) () =
    {
      id = 0;
      item_type;
      quantity;
      name;
      description;
      slot_type;
      stat_modifiers;
      is_corrupted;
      corruption_effects;
    }
end

type t = Item_data.t

let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
let set id data = Hashtbl.set table ~key:id ~data
let get id = Hashtbl.find table id
let remove id = Hashtbl.remove table id

let create_item ~item_type ~quantity ~name ?(description = None)
    ?(slot_type = Item_data.NoneSlot) ?(stat_modifiers = StatModifiers.empty)
    ?(is_corrupted = false) ?(corruption_effects = None) () =
  let item =
    Item_data.create ~item_type ~quantity ~name ?description ~slot_type
      ~stat_modifiers ~is_corrupted ~corruption_effects ()
  in
  set item.id item
