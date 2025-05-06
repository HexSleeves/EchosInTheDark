open Base
open Types

(* Persistent map for actors *)
type t = Actor.t Map.M(Int).t

let create () : t = Map.empty (module Int)

let add (actor_id : Actor.actor_id) (actor : Actor.t) (manager : t) : t =
  Map.set manager ~key:actor_id ~data:actor

let remove (actor_id : Actor.actor_id) (manager : t) : t =
  Map.remove manager actor_id

let get (actor_id : Actor.actor_id) (manager : t) : Actor.t option =
  Map.find manager actor_id

let update (actor_id : Actor.actor_id) (f : Actor.t -> Actor.t) (manager : t) :
    t =
  Map.find manager actor_id
  |> Option.value_map ~default:manager ~f:(fun actor ->
         Map.set manager ~key:actor_id ~data:(f actor))

(* Actors *)

(* Create a player actor *)
let create_player_actor = Actor.create ~speed:100

(* Create a rat actor *)
let create_rat_actor = Actor.create ~speed:110

(* Create a goblin actor *)
let create_goblin_actor = Actor.create ~speed:150
let copy (t : t) : t = t (* Map is persistent, so this is just identity *)

let print_actor_manager (manager : t) : unit =
  Map.iteri manager ~f:(fun ~key ~data ->
      Core_log.info (fun m -> m "Actor %d: %s" key (Actor.show data)))
