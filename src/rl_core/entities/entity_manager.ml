open Base
open Types

type t = { next_id : int; alive : Set.M(Int).t }

let create () : t = { next_id = 0; alive = Set.empty (module Int) }

let spawn (mgr : t) : entity_id * t =
  let id = mgr.next_id in
  (id, { next_id = id + 1; alive = Set.add mgr.alive id })

let remove (mgr : t) (id : entity_id) : t =
  { mgr with alive = Set.remove mgr.alive id }

let is_alive (mgr : t) (id : entity_id) : bool = Set.mem mgr.alive id
let to_list (mgr : t) : entity_id list = Set.to_list mgr.alive
let length (mgr : t) : int = Set.length mgr.alive
let next_id (mgr : t) : int = mgr.next_id
