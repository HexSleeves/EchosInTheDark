(* State type definition extracted from state.ml *)
open Entities
open Actors
open Rl_types

type t = {
  debug : bool;
  depth : int;
  player_id : int;
  mode : CtrlMode.t;
  entities : Entity_manager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  chunk_manager : Chunk_manager.t;
  chunk_managers : (int, Chunk_manager.t) Base.Hashtbl.t;
  position_index : (Loc.t, int * Components.Position.t) Base.Hashtbl.t;
}
[@@deriving show]
