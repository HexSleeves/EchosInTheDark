(* Map generation configuration signature *)

type difficulty_params = {
  monsters : int;
  traps    : int;
}

(** Configuration for map generation and progression. *)
type t = {
  seed             : int;
  min_levels       : int;
  max_levels       : int;
  width            : int;
  height           : int;
  difficulty_curve : depth:int -> difficulty_params;
}

(** [default ~seed] returns a default mapgen config with stage bounds and dimensions. *)
val default : seed:int -> t

(** [pick_total_levels config] deterministically picks a number of levels between [min_levels] and [max_levels] based on the seed. *)
val pick_total_levels : t -> int
