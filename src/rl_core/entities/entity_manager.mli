open Types

type t = { next_id : int; alive : Base.Set.M(Base.Int).t }

val create : unit -> t
val spawn : t -> entity_id * t
val remove : t -> int -> t
val is_alive : t -> int -> bool
val to_list : t -> int list
val length : t -> int
(* val next_id : t -> int *)
