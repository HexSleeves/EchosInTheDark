open Base
open Types

let is_full (inv : Inventory.t) : bool = List.length inv.items >= inv.max_slots
let can_add_item (inv : Inventory.t) : bool = not (is_full inv)

let add_item (inv : Inventory.t) (item : Item.t) :
    (Inventory.t, string) Result.t =
  if is_full inv then Error "Inventory is full!"
  else Ok { inv with items = item :: inv.items }

let remove_item (inv : Inventory.t) (item : Item.t) :
    (Inventory.t, string) Result.t =
  match List.findi inv.items ~f:(fun _ i -> i.id = item.id) with
  | None -> Error "Item not found in inventory!"
  | Some (idx, _) ->
      let new_items = List.filteri inv.items ~f:(fun i _ -> i <> idx) in
      Ok { inv with items = new_items }

let item_stat_summary (item : Item.t) : string =
  let m = item.stat_modifiers in
  let parts =
    [
      (if m.attack <> 0 then Some (Printf.sprintf "Attack %+d" m.attack)
       else None);
      (if m.defense <> 0 then Some (Printf.sprintf "Defense %+d" m.defense)
       else None);
      (if m.speed <> 0 then Some (Printf.sprintf "Speed %+d" m.speed) else None);
      (if m.max_hp <> 0 then Some (Printf.sprintf "Max HP %+d" m.max_hp)
       else None);
    ]
    |> List.filter_map ~f:Fn.id
  in
  if List.is_empty parts then "No stat modifiers"
  else String.concat ~sep:", " parts

let item_corruption_status (item : Item.t) : string option =
  if item.is_corrupted then
    Some
      (match item.corruption_effects with
      | Some desc -> "Corrupted: " ^ desc
      | None ->
          "Corrupted: This item cannot be unequipped and has negative effects!")
  else None
