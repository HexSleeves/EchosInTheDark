open Types

(* Define core event types here. Expand as needed. *)
type event =
  | EntityMoved of { entity_id : int; from_pos : Loc.t; to_pos : Loc.t }
  | ActorDamaged of { actor_id : int; amount : int }
  | TrapTriggered of { entity_id : int; trap_id : int }
  | EntityAttacked of { attacker_id : int; defender_id : int }
  | EntityDied of { entity_id : int }
  | ItemPickedUp of { player_id : int; item_id : entity_id }
  | ItemDropped of { player_id : int; item_id : entity_id }
(* Add more events as needed *)

type t = event

(* Handler type: takes an event and returns unit *)
type handler = event -> State_types.t -> State_types.t

(* Internal list of handlers *)
let handlers : handler list ref = ref []
let subscribe (f : handler) : unit = handlers := f :: !handlers

let publish (ev : event) (state : State_types.t) : State_types.t =
  List.fold_left (fun st h -> h ev st) state !handlers
