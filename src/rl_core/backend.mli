module Tilemap = Map.Tilemap
module Actor = Actor_manager.Actor

type t = State.t

val make : debug:bool -> w:int -> h:int -> seed:int -> t

(* Map *)
val get_current_map : t -> Tilemap.t

(* Control mode *)
val get_mode : t -> Types.CtrlMode.t
val set_mode : t -> Types.CtrlMode.t -> t

(* Entity *)
val get_player : t -> Types.Entity.entity
val get_entities : t -> Types.Entity.entity list
val move_entity : t -> Types.Entity.entity_id -> Types.Loc.t -> t

(* Actor actions *)
val queue_actor_action : t -> Actor.actor_id -> Types.Action.t -> t

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
  actor_id:int ->
  description:string ->
  t
