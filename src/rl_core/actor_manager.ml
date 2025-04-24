open Base
open Types
open Ppx_yojson_conv_lib.Yojson_conv

module Actor = struct
  (* --- BEGIN MERGED FROM actor.ml --- *)
  type actor_id = int [@@deriving yojson, show]

  (* TurnActor type *)
  type t = {
    speed : int;
    alive : bool;
    next_turn_time : int;
    next_action : Action.t option;
  }
  [@@deriving yojson, show]

  (* Constructor *)
  let create ~next_turn_time ~speed =
    { speed; alive = true; next_turn_time; next_action = None }

  (* Queue an action and return new actor *)
  let queue_action t (action : Action.t) = { t with next_action = Some action }

  (* Pop the next action, return (action option * new actor) *)
  let next_action t : Action.t option * t =
    match t.next_action with
    | None -> (None, t)
    | Some a -> (Some a, { t with next_action = None })

  (* Peek at the next action *)
  let peek_next_action t : Action.t option = t.next_action

  (* Is alive? *)
  let is_alive t = t.alive
  (* --- END MERGED FROM actor.ml --- *)
end

(* Persistent map for actors *)
type t = Actor.t Map.M(Int).t

let create () : t = Map.empty (module Int)

let add (actor_id : Actor.actor_id) (actor : Actor.t) (manager : t) : t =
  Map.set manager ~key:actor_id ~data:actor

let remove (actor_id : Actor.actor_id) (manager : t) : t =
  Map.remove manager actor_id

let get (actor_id : Actor.actor_id) (manager : t) : Actor.t option =
  Map.find manager actor_id

let get_unsafe (actor_id : Actor.actor_id) (manager : t) : Actor.t =
  Option.value_exn (get actor_id manager) ~message:"Actor not found"

let update (actor_id : Actor.actor_id) (f : Actor.t -> Actor.t) (manager : t) :
    t =
  Option.value_map (Map.find manager actor_id) ~default:manager ~f:(fun actor ->
      Map.set manager ~key:actor_id ~data:(f actor))

(* Actors *)

(* Create a player actor *)
let create_player_actor = Actor.create ~speed:100

(* Create a rat actor *)
let create_rat_actor = Actor.create ~speed:110

(* Create a goblin actor *)
let create_goblin_actor = Actor.create ~speed:150
let copy (t : t) : t = t (* Map is persistent, so this is just identity *)
let restore (_t : t) (src : t) : t = src (* Just return the source *)

let debug_print (manager : t) : unit =
  Map.iteri manager ~f:(fun ~key ~data ->
      Core_log.info (fun m -> m "Actor %d: %s" key (Actor.show data)))
