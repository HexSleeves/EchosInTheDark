(* State type definition extracted from state.ml *)
open Types

(* NOTE: Ensure Entity_manager is built before this module in dune *)

type t = {
  debug : bool;
  depth : int;
  mode : CtrlMode.t;
  em : Entity_manager.t;
  turn_queue : Turn_queue.t;
  actor_manager : Actor_manager.t;
  chunk_manager : Chunk_manager.t;
  chunk_managers : (int, Chunk_manager.t) Base.Hashtbl.t;
  position_index : (Loc.t, int * Components.Position.t) Base.Hashtbl.t;
}
[@@deriving show]
