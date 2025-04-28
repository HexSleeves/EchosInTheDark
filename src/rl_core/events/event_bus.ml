open Types

(* Define core event types here. Expand as needed. *)
type event =
  | EntityMoved of { entity_id : int; from_pos : Loc.t; to_pos : Loc.t }
  | ActorDamaged of { actor_id : int; amount : int }
  | TrapTriggered of { entity_id : int; trap_id : int }
  | EntityAttacked of { attacker_id : int; defender_id : int; damage : int }
(* Add more events as needed *)

(* Handler type: takes an event and returns unit *)
type handler = event -> unit

(* Internal list of handlers *)
let handlers : handler list ref = ref []
let subscribe (f : handler) : unit = handlers := f :: !handlers
let publish (ev : event) : unit = List.iter (fun h -> h ev) !handlers
