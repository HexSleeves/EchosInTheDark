open Core

(* Min-heap of (time, entity_id) *)
module TimeEntity = struct
  type t = int * Entity.entity_id

  (* Manual comparison: Primarily by time *)
  let compare (time1, _actor1) (time2, _actor2) = Int.compare time1 time2

  (* Manual sexp_of_t: Requires Actor.sexp_of_t *)
  let sexp_of_t (time, _actor) =
    (* Placeholder: assumes Actor.t has a sexp_of_t if needed *)
    Sexplib0.Sexp_conv.sexp_of_pair Sexplib0.Sexp_conv.sexp_of_int
      (fun _ -> Sexplib0.Sexp.Atom "<actor>") (* Placeholder sexp for Actor.t *)
      (time, _actor)
end

(* Use Pairing_heap from Core_kernel *)
type t = {
  mutable current_time : int;
  mutable turn_queue : TimeEntity.t Pairing_heap.t;
}

let create () =
  {
    current_time = 0;
    turn_queue = Pairing_heap.create ~min_size:5 ~cmp:TimeEntity.compare ();
  }

let print_queue t =
  Stdio.printf "Current time: %d, Turn queue: [%s]\n" t.current_time
    (Pairing_heap.to_list t.turn_queue
    |> List.map ~f:(fun (time, actor) -> Printf.sprintf "(%d,%d)" time actor)
    |> String.concat ~sep:"; ")

let schedule_turn t (entity : Entity.entity_id) (next_time : int) =
  Pairing_heap.add t.turn_queue (next_time, entity)

let get_next_actor t : (Entity.entity_id * int) option =
  if Pairing_heap.is_empty t.turn_queue then None
  else
    let time, entity_id = Pairing_heap.pop_exn t.turn_queue in
    t.current_time <- time;
    (* t.turn_queue <- heap; *)
    Some (entity_id, time)

let current_time t = t.current_time

let peek_next t : (Entity.entity_id * int) option =
  Pairing_heap.top t.turn_queue
  |> Option.map ~f:(fun (time, entity) -> (entity, time))

let is_scheduled t (entity : Entity.entity_id) : bool =
  Pairing_heap.to_list t.turn_queue |> List.exists ~f:(fun (_, e) -> e = entity)

let time_until t (time : int) : int =
  Int.(time - t.current_time) land Int.max_value

let is_before t (time_a : int) (time_b : int) : bool =
  time_until t time_a < time_until t time_b
