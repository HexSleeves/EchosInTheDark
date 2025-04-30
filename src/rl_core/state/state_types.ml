(* State type definition extracted from state.ml *)
open Entities
open Actors
open Types

type t = {
  debug : bool;
  depth : int;
  player_id : entity_id;
  mode : CtrlMode.t;
  entities : Entity_manager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  chunk_manager : Chunk_manager.t;
  chunk_managers : (int, Chunk_manager.t) Base.Hashtbl.t;
  position_index : (Loc.t, entity_id) Base.Hashtbl.t; (* Fast position lookup *)
}
[@@deriving show]
