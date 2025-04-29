open Base
open Types

let table : (int, Types.Stats.t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No stats for entity id %d" id)

let set id stats = Hashtbl.set table ~key:id ~data:stats
let remove id = Hashtbl.remove table id

let apply_equipment_modifiers (base : Stats.t) (items : Item.t list) : Stats.t =
  let total_mods =
    List.fold items ~init:StatModifiers.empty ~f:(fun acc item ->
        let m = item.stat_modifiers in
        {
          StatModifiers.attack = acc.attack + m.attack;
          defense = acc.defense + m.defense;
          speed = acc.speed + m.speed;
          max_hp = acc.max_hp + m.max_hp;
        })
  in
  {
    Stats.max_hp = base.max_hp + total_mods.max_hp;
    hp = base.hp;
    (* HP is not modified directly by equipment *)
    attack = base.attack + total_mods.attack;
    defense = base.defense + total_mods.defense;
    speed = base.speed + total_mods.speed;
  }
