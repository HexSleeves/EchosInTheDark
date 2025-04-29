open Base
open Types
open Item

type t = { items : Item_data.t list; max_slots : int } [@@deriving yojson, show]

let table : (entity_id, t) Hashtbl.t = Hashtbl.create (module Int)
let get id = Hashtbl.find table id
let set id data = Hashtbl.set table ~key:id ~data
let remove id = Hashtbl.remove table id
let is_full (inv : t) : bool = List.length inv.items >= inv.max_slots
let can_add_item (inv : t) : bool = not (is_full inv)

let add_item (inv : t) (item_id : entity_id) : (t, string) Result.t =
  if is_full inv then Error "Inventory is full!"
  else
    let item = Item.get item_id in
    match item with
    | Some item -> Ok { inv with items = item :: inv.items }
    | None -> Error "Item not found!"

let remove_item (inv : t) (item_id : entity_id) : (t, string) Result.t =
  match List.findi inv.items ~f:(fun _ i -> i.id = item_id) with
  | None -> Error "Item not found in inventory!"
  | Some (idx, _) ->
      let new_items = List.filteri inv.items ~f:(fun i _ -> i <> idx) in
      Ok { inv with items = new_items }

let item_stat_summary (item : Item_data.t) : string =
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

let item_corruption_status (item : Item_data.t) : string option =
  if item.is_corrupted then
    Some
      (match item.corruption_effects with
      | Some desc -> "Corrupted: " ^ desc
      | None ->
          "Corrupted: This item cannot be unequipped and has negative effects!")
  else None
