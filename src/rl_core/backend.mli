module Tilemap = Map.Tilemap
module Actor = Actor_manager.Actor
module Entity = Types.Entity

type t = State.t

val make : debug:bool -> w:int -> h:int -> seed:int -> t

(* Control mode *)
val get_mode : t -> Types.CtrlMode.t
val set_mode : t -> Types.CtrlMode.t -> t

(* Entity *)
val get_player_id : t -> int
val get_player_entity : t -> Types.Entity.t
val get_entities : t -> Types.Entity.t list
val move_entity : t -> int -> Types.Loc.t -> t
val queue_actor_action : t -> Actor.actor_id -> Types.Action.t -> t

(* Map *)
val get_current_map : t -> Tilemap.t

(* Spawn helpers *)
val spawn_player : t -> pos:Types.Loc.t -> direction:Types.Direction.t -> t

val spawn_creature :
  t ->
  pos:Types.Loc.t ->
  direction:Types.Direction.t ->
  species:string ->
  health:int ->
  glyph:string ->
  name:string ->
  description:string ->
  t
