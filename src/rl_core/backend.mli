module Tilemap = Dungeon.Tilemap
module Entity = Types.Entity

type t = State.t

val make : debug:bool -> w:int -> h:int -> seed:int -> current_level:int -> t
val get_debug : t -> bool
val get_mode : t -> Types.CtrlMode.t
val set_mode : Types.CtrlMode.t -> t -> t
val get_player_id : t -> int
val get_player_entity : t -> Types.Entity.t
val get_entities : t -> Types.Entity.t list
val move_entity : int -> Types.Loc.t -> t -> t
val queue_actor_action : t -> int -> Types.Action.t -> t
val get_current_map : t -> Tilemap.t
val process_turns : t -> t
val run_ai_step : t -> t
