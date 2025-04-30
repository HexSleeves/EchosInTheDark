open Base
open Types

type t = { next_id : int; alive : Set.M(Int).t }

let create () : t = { next_id = 0; alive = Set.empty (module Int) }

let print (mgr : t) : unit =
  (* Loop through all alive entities and print their IDs *)
  Logs.info (fun m -> m "EntityManager:");
  Set.iter mgr.alive ~f:(fun id -> Logs.info (fun m -> m "Entity: %d" id))

let add (id : entity_id) (mgr : t) : t =
  { mgr with alive = Set.add mgr.alive id }

let spawn (mgr : t) : entity_id * t =
  let id = mgr.next_id in
  (id, { next_id = id + 1; alive = Set.add mgr.alive id })

let remove (id : entity_id) (mgr : t) : t =
  { mgr with alive = Set.remove mgr.alive id }

let is_alive (id : entity_id) (mgr : t) : bool = Set.mem mgr.alive id
let to_list (mgr : t) : entity_id list = Set.to_list mgr.alive
let length (mgr : t) : int = Set.length mgr.alive

let find_player_id (mgr : t) : entity_id option =
  to_list mgr
  |> List.find ~f:(fun id ->
         match Components.Kind.get id with
         | Some Components.Kind.Player -> true
         | _ -> false)

let get_player_id_exn (mgr : t) : entity_id =
  to_list mgr
  |> List.find_exn ~f:(fun id ->
         match Components.Kind.get id with
         | Some Components.Kind.Player -> true
         | _ -> false)
