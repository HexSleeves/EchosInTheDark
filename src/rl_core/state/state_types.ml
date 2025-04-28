(* State type definition extracted from state.ml *)
open Entities
open Actors
open Types

type t = {
  debug : bool;
  player_id : Types.Entity.id;
  mode : CtrlMode.t;
  entities : Entity_manager.t;
  actor_manager : Actor_manager.t;
  turn_queue : Turn_queue.t;
  map_manager : Map_manager.t;
  position_index : (Types.Loc.t, Types.Entity.id) Base.Hashtbl.t;
      (* Fast position lookup *)
}
