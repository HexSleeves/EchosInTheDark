type t

val create : unit -> t
val add : Actor.actor_id -> Actor.t -> t -> t
val remove : Actor.actor_id -> t -> t
val get : Actor.actor_id -> t -> Actor.t option
val get_unsafe : Actor.actor_id -> t -> Actor.t
val update : Actor.actor_id -> (Actor.t -> Actor.t) -> t -> t
val create_player_actor : Actor.t
val create_rat_actor : Actor.t
val create_goblin_actor : Actor.t
val copy : t -> t
val print_actor_manager : t -> unit
