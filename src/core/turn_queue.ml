open Containers
module Log = (val Logger.make_logger "turn_queue" ~doc:"Turn queue logs" ())

(* time, entity_id *)
type elt = int * int [@@deriving yojson, show]

module Heap = CCHeap.Make (struct
  type t = elt

  let leq (t1, id1) (t2, id2) = t1 < t2 || (t1 = t2 && id1 <= id2)
end)

(* Mutable min-heap of (time, id) using Containers Heap *)
type t = { current_time : int; heap : Heap.t }

let to_yojson (q : t) : Yojson.Safe.t =
  let lst = Heap.to_list q.heap in
  [%to_yojson: elt list] lst

let of_yojson (js : Yojson.Safe.t) : (t, string) result =
  match [%of_yojson: elt list] js with
  | Ok lst ->
      Ok
        {
          current_time = 0;
          heap = List.fold_left (fun h e -> Heap.add h e) Heap.empty lst;
        }
  | Error e -> Error e

let create () : t = { current_time = 0; heap = Heap.empty }

let print_turn_queue (q : t) : unit =
  let lst = Heap.to_list q.heap in
  Printf.printf "TurnQueue: [";
  List.iter (fun (t, id) -> Printf.printf "(%d,%d); " t id) lst;
  Printf.printf "]\n"

let schedule_at (entity_id : int) (time : int) (q : t) : t =
  { q with heap = Heap.add q.heap (time, entity_id) }

let schedule_now (entity_id : int) (q : t) : t = schedule_at entity_id 0 q

let remove_entity (entity_id : int) (q : t) : t =
  { q with heap = Heap.filter (fun (_, id) -> id <> entity_id) q.heap }

let get_next_actor (q : t) : elt option * t =
  match Heap.take q.heap with
  | Some (q', elt) -> (Some elt, { q with heap = q' })
  | None -> (None, q)

let peek_next (q : t) : elt option = Heap.find_min q.heap

let is_scheduled (entity_id : int) (q : t) : bool =
  Heap.to_list q.heap |> List.exists (fun (_, id) -> id = entity_id)
