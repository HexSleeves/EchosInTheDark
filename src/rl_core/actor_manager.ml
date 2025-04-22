open Base

(* Reference the Actor module *)
type actor_id = int

(* Persistent map for actors *)
type t = Actor.t Map.M(Int).t

let create () : t = Map.empty (module Int)

let add (manager : t) (actor_id : actor_id) (actor : Actor.t) : t =
  Map.set manager ~key:actor_id ~data:actor

let remove (manager : t) (actor_id : actor_id) : t = Map.remove manager actor_id

let get (manager : t) (actor_id : actor_id) : Actor.t option =
  Map.find manager actor_id

let get_unsafe (manager : t) (actor_id : actor_id) : Actor.t =
  match get manager actor_id with
  | Some actor -> actor
  | None -> failwith "Actor not found"

let update (manager : t) (actor_id : actor_id) (f : Actor.t -> Actor.t) : t =
  match Map.find manager actor_id with
  | Some actor -> Map.set manager ~key:actor_id ~data:(f actor)
  | None -> manager

(* Actors *)

(* Create a player actor *)
let create_player_actor = Actor.create ~speed:100

(* Create a rat actor *)
let create_rat_actor = Actor.create ~speed:110

(* Create a goblin actor *)
let create_goblin_actor = Actor.create ~speed:150
let copy (t : t) : t = t (* Map is persistent, so this is just identity *)
let restore (_t : t) (src : t) : t = src (* Just return the source *)
