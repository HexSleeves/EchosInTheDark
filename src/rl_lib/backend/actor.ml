open Core
open Base

(* TurnActor type *)
type t = {
  speed : int;
  alive : bool;
  mutable next_turn_time : int;
  actions : Common.game_action ref Deque.t;
}

let create ~speed ~alive ~next_turn_time ~actions =
  { speed; alive; next_turn_time; actions }

let yojson_of_t (t : t) : Yojson.Safe.t =
  `Assoc
    [
      ("speed", `Int t.speed);
      ("alive", `Bool t.alive);
      ("next_turn_time", `Int t.next_turn_time);
      (* ("actions", `List (Deque.to_list t.actions)); *)
    ]

let t_of_yojson (json : Yojson.Safe.t) : t =
  match json with
  | `Assoc fields ->
      let speed =
        match Stdlib.List.assoc "speed" fields with
        | `Int n -> n
        | _ -> failwith "speed"
      in
      let alive =
        match Stdlib.List.assoc "alive" fields with
        | `Bool b -> b
        | _ -> failwith "alive"
      in
      let next_turn_time =
        match Stdlib.List.assoc "next_turn_time" fields with
        | `Int n -> n
        | _ -> failwith "next_turn_time"
      in
      { speed; alive; next_turn_time; actions = Deque.create () }
  | _ -> failwith "Actor.t_of_yojson: expected object"

(* Constructor *)
let create ~next_turn_time ~speed =
  { speed; alive = true; next_turn_time; actions = Deque.create () }

(* Queue an action and return self for chaining *)
let queue_action t (action : #Common.game_action) =
  Deque.enqueue_back t.actions (ref (action :> Common.game_action));
  t

(* Add an action (no chaining) *)
let add_action t (action : #Common.game_action) =
  Deque.enqueue_back t.actions (ref (action :> Common.game_action))

(* Pop the next action *)
let next_action t : Common.game_action option =
  Option.map ~f:( ! ) (Deque.dequeue_front t.actions)

(* Peek at the next action *)
let peek_next_action t : Common.game_action option =
  Option.map ~f:( ! ) (Deque.peek_front t.actions)

(* Is alive? *)
let is_alive t = t.alive

(* Example usage: *)
(*
class my_action = object
  method execute () = printf "Action!\n"
end

let actor = create ~speed:10
let () =
  queue_action actor (new my_action) |> ignore;
  match next_action actor with
  | Some action -> action#execute ()
  | None -> ()
*)
