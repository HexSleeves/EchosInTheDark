open Base
open Rl_types
module Log = (val Core_log.make_logger "turn_queue" : Logs.LOG)

(* Persistent min-heap of (time, id) using a sorted list *)
type t = {
  current_time : int;
  turn_queue : (int * entity_id) list; (* Sorted by time ascending *)
}

let create () : t = { current_time = 0; turn_queue = [] }
let current_time t = t.current_time

let print_turn_queue t =
  let queue_str =
    List.map t.turn_queue ~f:(fun (time, actor) ->
        Printf.sprintf "(time: %d, actor: %d)" time actor)
    |> String.concat ~sep:"; "
  in
  Log.info (fun m ->
      m "Current time: %d, Turn queue: [%s]" t.current_time queue_str)

(* let rec insert_sorted queue (time, entity) =
  match queue with
  | [] -> [ (time, entity) ]
  | (t, _) :: _ when time < t -> (time, entity) :: queue
  | (t, e) :: rest -> (t, e) :: insert_sorted rest (time, entity) *)

let schedule_at t (entity_id : entity_id) (next_time : int) =
  let new_queue = List.append t.turn_queue [ (next_time, entity_id) ] in
  {
    t with
    turn_queue =
      List.sort new_queue ~compare:(fun (t1, _) (t2, _) -> Int.compare t1 t2);
  }

(* Prepend the turn to the front of the queue *)
let schedule_now t (entity_id : entity_id) =
  { t with turn_queue = List.cons (current_time t, entity_id) t.turn_queue }

let remove_actor t (entity_id : entity_id) =
  {
    t with
    turn_queue = List.filter t.turn_queue ~f:(fun (_, e) -> e <> entity_id);
  }

let get_next_actor t : (int * int) option * t =
  match t.turn_queue with
  | [] -> (None, t)
  | (time, id) :: rest ->
      (Some (id, time), { current_time = time; turn_queue = rest })

let peek_next t : (int * int) option =
  match t.turn_queue with
  | [] -> None
  | (time, entity) :: _ -> Some (entity, time)

let is_scheduled t (entity_id : entity_id) : bool =
  List.exists t.turn_queue ~f:(fun (_, e) -> e = entity_id)

let time_until t (time : int) : int =
  Int.(time - t.current_time) land Int.max_value

let is_before t (time_a : int) (time_b : int) : bool =
  time_until t time_a < time_until t time_b

let to_list t = t.turn_queue
let copy (t : t) : t = t (* Already persistent *)
