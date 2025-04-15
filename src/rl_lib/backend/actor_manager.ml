(* Reference the Actor module *)
type actor_id = int
type t = (actor_id, Actor.t) Hashtbl.t

let create () : t = (Hashtbl.create 16 : (actor_id, Actor.t) Hashtbl.t)

let add (manager : t) (actor_id : actor_id) (actor : Actor.t) : unit =
  Hashtbl.replace manager actor_id actor

let remove (manager : t) (actor_id : actor_id) : unit =
  Hashtbl.remove manager actor_id

let get (manager : t) (actor_id : actor_id) : Actor.t option =
  try Some (Hashtbl.find manager actor_id) with Not_found -> None

let get_unsafe (manager : t) (actor_id : actor_id) : Actor.t =
  match get manager actor_id with
  | Some actor -> actor
  | None -> failwith "Actor not found"

let update (manager : t) (actor_id : actor_id) (f : Actor.t -> Actor.t) : unit =
  match get manager actor_id with
  | Some actor -> Hashtbl.replace manager actor_id (f actor)
  | None -> ()
