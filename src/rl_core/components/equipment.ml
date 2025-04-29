open Base
open Types

let table : (int, Types.Equipment.t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No equipment for entity id %d" id)

let set id equipment = Hashtbl.set table ~key:id ~data:equipment
let remove id = Hashtbl.remove table id

let slot_matches (item : Item.t) (slot : Equipment.slot) : bool =
  match (item.slot_type, slot) with
  | Item.Head, Equipment.Head -> true
  | Item.Chest, Equipment.Chest -> true
  | Item.Legs, Equipment.Legs -> true
  | Item.Weapon, Equipment.Weapon -> true
  | Item.Shield, Equipment.Shield -> true
  | Item.Accessory, (Equipment.Accessory1 | Equipment.Accessory2) -> true
  | _ -> false

let can_equip (eq : Equipment.t) (item : Item.t) (slot : Equipment.slot) : bool
    =
  slot_matches item slot
  &&
  match List.Assoc.find eq ~equal:Equipment.equal_slot slot with
  | Some None -> true
  | _ -> false

let equip_item (eq : Equipment.t) (item : Item.t) (slot : Equipment.slot) :
    (Equipment.t, string) Result.t =
  if not (slot_matches item slot) then
    Error "Item cannot be equipped in this slot!"
  else
    match List.Assoc.find eq ~equal:Equipment.equal_slot slot with
    | Some (Some _) -> Error "Slot already occupied!"
    | Some None ->
        let new_eq =
          List.map eq ~f:(fun (s, i) ->
              if Equipment.equal_slot s slot then (s, Some item) else (s, i))
        in
        Ok new_eq
    | None -> Error "Invalid slot!"

let unequip_item (eq : Equipment.t) (slot : Equipment.slot) :
    (Equipment.t, string) Result.t =
  match List.Assoc.find eq ~equal:Equipment.equal_slot slot with
  | Some (Some item) when item.is_corrupted ->
      Error "This item is corrupted and cannot be unequipped!"
  | Some (Some _) ->
      let new_eq =
        List.map eq ~f:(fun (s, i) ->
            if Equipment.equal_slot s slot then (s, None) else (s, i))
      in
      Ok new_eq
  | Some None -> Error "No item equipped in this slot!"
  | None -> Error "Invalid slot!"

let get_equipped_items (eq : Equipment.t) : Item.t list =
  List.filter_map eq ~f:(fun (_, i) -> i)
