(* Map generation configuration signature *)

type difficulty_params = { monsters : int; traps : int }
type render_mode = Tiles | Ascii

type t = {
  seed : int;
  min_levels : int;
  max_levels : int;
  width : int;
  height : int;
  difficulty_curve : depth:int -> difficulty_params;
  render_mode : render_mode;
}
(** Configuration for map generation and progression. *)

val make : seed:int -> w:int -> h:int -> ?render_mode:render_mode -> unit -> t
(** [make ~seed ~w ~h] returns a mapgen config with stage bounds and dimensions.
*)

val default : seed:int -> ?render_mode:render_mode -> unit -> t
(** [default ~seed] returns a default mapgen config with stage bounds and
    dimensions. *)

val pick_total_levels : t -> int
(** [pick_total_levels config] deterministically picks a number of levels
    between [min_levels] and [max_levels] based on the seed. *)
