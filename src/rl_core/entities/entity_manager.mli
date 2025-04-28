open Types

type t

val create : unit -> t
val add : Entity.t -> t -> t
val add_entity : Entity.t -> t -> t
val remove : int -> t -> t
val copy : t -> t
val find : int -> t -> Entity.t option
val find_unsafe : int -> t -> Entity.t
val find_by_pos : Loc.t -> t -> Entity.t option
val find_player : t -> Entity.t option
val find_player_id : t -> int option
val update : int -> (Entity.t -> Entity.t) -> t -> t
val to_list : t -> Entity.t list
val add_entity : Entity.t -> t -> t
val next_id : t -> int
val update_entity_stats : t -> Entity.id -> (Stats.t -> Stats.t) -> t

