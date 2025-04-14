open Base
open Ppx_yojson_conv_lib.Yojson_conv

type faction = int [@@deriving yojson]
type loc = int * int [@@deriving yojson]
type direction = North | East | South | West [@@deriving yojson]

(* Kind of entity in the game world *)
type entity_kind = Player | Creature | Item | Other of string
[@@deriving yojson]

(* Data specific to each entity kind *)
type entity_data =
  | PlayerData of {
      faction : faction;
          (* Add more player-specific fields here, e.g., inventory, health, etc. *)
    }
  | CreatureData of {
      species : string;
      health : int; (* Add more creature-specific fields here *)
    }
  | ItemData of {
      item_type : string;
      quantity : int; (* Add more item-specific fields here *)
    }
[@@deriving yojson]

type entity = {
  id : int;
  pos : loc;
  kind : entity_kind;
  direction : direction;
  data : entity_data;
}
[@@deriving yojson]

(* Specializations for convenience *)
let make_player ~id ~pos ~direction ~faction =
  { id; kind = Player; pos; direction; data = PlayerData { faction } }

let make_creature ~id ~pos ~direction ~species ~health =
  {
    id;
    kind = Creature;
    pos;
    direction;
    data = CreatureData { species; health };
  }

let make_item ~id ~pos ~direction ~item_type ~quantity =
  { id; kind = Item; pos; direction; data = ItemData { item_type; quantity } }

(* Player reference type *)
type player = { entity_id : int } [@@deriving yojson]

(* Entity manager for managing collections of entities *)
module EntityManager = struct
  type t = (int, entity) Hashtbl.t

  let create () : t = Hashtbl.create (module Int)
  let add (mgr : t) (ent : entity) = Hashtbl.set mgr ~key:ent.id ~data:ent
  let remove (mgr : t) (id : int) = Hashtbl.remove mgr id
  let find (mgr : t) (id : int) : entity option = Hashtbl.find mgr id

  let update (mgr : t) (id : int) (f : entity -> entity) =
    match Hashtbl.find mgr id with
    | Some ent -> Hashtbl.set mgr ~key:id ~data:(f ent)
    | None -> ()

  let to_list (mgr : t) : entity list =
    Hashtbl.fold mgr ~init:[] ~f:(fun ~key ~data acc -> data :: acc)
    |> List.rev (* Reverse to maintain insertion order *)
end
