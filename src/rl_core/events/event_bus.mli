open Types

type event =
  | EntityMoved of { entity_id : int; from_pos : Loc.t; to_pos : Loc.t }
  | ActorDamaged of { actor_id : int; amount : int }
  | TrapTriggered of { entity_id : int; trap_id : int }
  | EntityAttacked of { attacker_id : int; defender_id : int; damage : int }

(* Handler type: takes an event and returns unit *)
type handler = event -> unit

val subscribe : handler -> unit
val publish : event -> unit
