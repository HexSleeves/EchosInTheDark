open Base
open Types
open Item
open Ppx_yojson_conv_lib.Yojson_conv

module Equipment_data = struct
  type slot = Head | Chest | Legs | Weapon | Shield | Accessory1 | Accessory2
  [@@deriving yojson, show, eq, enum]

  type t = (slot * entity_id option) list [@@deriving yojson, show]

  let empty =
    [
      (Head, None);
      (Chest, None);
      (Legs, None);
      (Weapon, None);
      (Shield, None);
      (Accessory1, None);
      (Accessory2, None);
    ]
end

type t = Equipment_data.t

let table : (int, t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No equipment for entity id %d" id)

let set id equipment = Hashtbl.set table ~key:id ~data:equipment
let remove id = Hashtbl.remove table id
let empty = Equipment_data.empty

let slot_of_item_slot_type (s : Item_data.slot_type) :
    Equipment_data.slot option =
  match s with
  | Item_data.Head -> Some Equipment_data.Head
  | Item_data.Chest -> Some Equipment_data.Chest
  | Item_data.Legs -> Some Equipment_data.Legs
  | Item_data.Weapon -> Some Equipment_data.Weapon
  | Item_data.Shield -> Some Equipment_data.Shield
  | Item_data.Accessory -> Some Equipment_data.Accessory1 (* or Accessory2 *)
  | Item_data.NoneSlot -> None

let equip_item player_id item_id =
  match Item.get item_id with
  | Some item -> (
      match slot_of_item_slot_type item.slot_type with
      | Some slot ->
          let equipment =
            get player_id |> Option.value ~default:Equipment_data.empty
          in
          let new_equipment =
            List.map equipment ~f:(fun (s, v) ->
                if Poly.(s = slot) then (s, Some item_id) else (s, v))
          in
          set player_id new_equipment
      | None -> ())
  | None -> ()

let unequip_item player_id (slot : Equipment_data.slot) :
    (unit, string) Result.t =
  match get player_id with
  | None -> Error "No equipment found for this entity."
  | Some eq -> (
      match List.Assoc.find eq ~equal:Poly.( = ) slot with
      | Some (Some item_id) -> (
          match Item.get item_id with
          | Some item when item.is_corrupted ->
              Error "This item is corrupted and cannot be unequipped!"
          | _ ->
              let new_eq =
                List.map eq ~f:(fun (s, i) ->
                    if Poly.(s = slot) then (s, None) else (s, i))
              in
              set player_id new_eq;
              Ok ())
      | Some None -> Error "No item equipped in this slot!"
      | None -> Error "Invalid slot!")

let get_equipped_items (eq : Equipment_data.t) : entity_id list =
  List.filter_map eq ~f:(fun (_, i) -> i)
