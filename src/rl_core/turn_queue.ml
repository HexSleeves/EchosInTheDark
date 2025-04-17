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

let current_time t = t.current_time

let print_queue t =
  let queue_str =
    Pairing_heap.to_list t.turn_queue
    |> List.map ~f:(fun (time, actor) -> sprintf "(%d,%d)" time actor)
    |> String.concat ~sep:"; "
  in
  Logs.info (fun m ->
      m "Current time: %d, Turn queue: [%s]" t.current_time queue_str)

let schedule_turn t (entity : Entity.entity_id) (next_time : int) =
  Pairing_heap.add t.turn_queue (next_time, entity)

let remove_actor t (entity : Entity.entity_id) =
  let token =
    Pairing_heap.find_elt t.turn_queue ~f:(fun (_, e) -> e = entity)
  in
  match token with
  | None -> failwith "Actor not found in turn queue"
  | Some token -> Pairing_heap.remove t.turn_queue token

let get_next_actor t : (Entity.entity_id * int) option =
  if Pairing_heap.is_empty t.turn_queue then None
  else
    let time, entity_id = Pairing_heap.pop_exn t.turn_queue in
    t.current_time <- time;
    (* t.turn_queue <- heap; *)
    Some (entity_id, time)

let peek_next t : (Entity.entity_id * int) option =
  Pairing_heap.top t.turn_queue
  |> Option.map ~f:(fun (time, entity) -> (entity, time))

let is_scheduled t (entity : Entity.entity_id) : bool =
  Pairing_heap.to_list t.turn_queue |> List.exists ~f:(fun (_, e) -> e = entity)

let time_until t (time : int) : int =
  Int.(time - t.current_time) land Int.max_value

let is_before t (time_a : int) (time_b : int) : bool =
  time_until t time_a < time_until t time_b
