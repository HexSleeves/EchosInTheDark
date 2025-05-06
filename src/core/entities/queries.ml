open Base
open Types
open Components

(* Returns (id, pos) for all entities with a position *)
let with_position () : (int * Loc.t) list =
  Hashtbl.fold Position.table ~init:[] ~f:(fun ~key:id ~data:pos acc ->
      (id, pos.world_pos) :: acc)

(* Returns (id, pos, health) for all entities with both position and health *)
let with_position_and_health () : (int * Loc.t * int) list =
  Hashtbl.fold Position.table ~init:[] ~f:(fun ~key:id ~data:pos acc ->
      match Stats.get id with
      | Some stats -> (id, pos.world_pos, stats.max_hp) :: acc
      | None -> acc)

(* Returns (id, pos) for all player entities with a position *)
let players_with_position () : (int * Loc.t) list =
  Hashtbl.fold Position.table ~init:[] ~f:(fun ~key:id ~data:pos acc ->
      match Kind.get id with
      | Some Kind.Player -> (id, pos.world_pos) :: acc
      | _ -> acc)
