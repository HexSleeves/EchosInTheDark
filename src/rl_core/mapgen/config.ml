open Base

(* Difficulty parameters for a given level *)
type difficulty_params = { monsters : int; traps : int }
type render_mode = Tiles | Ascii

(* Map generation configuration *)
type t = {
  seed : int;
  min_levels : int;
  max_levels : int;
  width : int;
  height : int;
  difficulty_curve : depth:int -> difficulty_params;
  render_mode : render_mode;
}

let default ~seed ?(render_mode = Tiles) () =
  let min_levels = 3 in
  let max_levels = 5 in
  let width = 80 in
  let height = 25 in
  let difficulty_curve ~depth = { monsters = depth * 2; traps = depth } in
  { seed; min_levels; max_levels; width; height; difficulty_curve; render_mode }

let make ~seed ~w ~h ?(render_mode = Tiles) () =
  let min_levels = 3 in
  let max_levels = 5 in
  let difficulty_curve ~depth = { monsters = depth * 2; traps = depth } in
  {
    seed;
    min_levels;
    max_levels;
    difficulty_curve;
    width = w;
    height = h;
    render_mode;
  }

let pick_total_levels config =
  let rng = Random.State.make [| config.seed |] in
  Random.State.int rng (config.max_levels - config.min_levels + 1)
  + config.min_levels
