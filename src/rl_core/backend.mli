module Tilemap = Dungeon.Tilemap
module Actor = Actor_manager.Actor
module Entity = Types.Entity

type t = State.t

val make : debug:bool -> w:int -> h:int -> seed:int -> current_level:int -> t

(* Control mode *)
val get_mode : t -> Types.CtrlMode.t
val set_mode : Types.CtrlMode.t -> t -> t

(* Entity *)
val get_player_id : t -> int
val get_player_entity : t -> Types.Entity.t
val get_entities : t -> Types.Entity.t list

(* Entity actions *)
val move_entity : int -> Types.Loc.t -> t -> t
val queue_actor_action : t -> Actor.actor_id -> Types.Action.t -> t

(* Map *)
val get_current_map : t -> Tilemap.t

(* AI *)
val run_ai_step : t -> t
val process_turns : t -> t
