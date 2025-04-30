open Base
open State_types

let update_chunk_managers (chunk_managers : (int, Chunk_manager.t) Hashtbl.t)
    (chunk_manager : Chunk_manager.t) (state : t) : t =
  Base.Hashtbl.set chunk_managers ~key:0 ~data:chunk_manager;
  { state with chunk_managers }
