open Core
open Types

(* Persistent min-heap of (time, entity_id) using a sorted list *)
type t = {
  current_time : int;
  turn_queue : (int * Entity.entity_id) list; (* Sorted by time ascending *)
}

let create () = { current_time = 0; turn_queue = [] }
let current_time t = t.current_time

let print_queue t =
  let queue_str =
    List.map t.turn_queue ~f:(fun (time, actor) ->
        sprintf "(time: %d, actor: %d)" time actor)
    |> String.concat ~sep:"; "
  in
  Core_log.info (fun m ->
      m "Current time: %d, Turn queue: [%s]" t.current_time queue_str)

let rec insert_sorted queue (time, entity) =
  match queue with
  | [] -> [ (time, entity) ]
  | (t, _) :: _ when time < t -> (time, entity) :: queue
  | (t, e) :: rest -> (t, e) :: insert_sorted rest (time, entity)

let schedule_turn t (entity : Entity.entity_id) (next_time : int) =
  Core_log.info (fun m ->
      m "Scheduling turn for entity: %d at time: %d" entity next_time);
  { t with turn_queue = insert_sorted t.turn_queue (next_time, entity) }

let schedule_now t (entity : Entity.entity_id) =
  schedule_turn t entity (current_time t)

let remove_actor t (entity : Entity.entity_id) =
  {
    t with
    turn_queue = List.filter t.turn_queue ~f:(fun (_, e) -> e <> entity);
  }

let get_next_actor t : (Entity.entity_id * int) option * t =
  match t.turn_queue with
  | [] -> (None, t)
  | (time, entity_id) :: rest ->
      (Some (entity_id, time), { current_time = time; turn_queue = rest })

let peek_next t : (Entity.entity_id * int) option =
  match t.turn_queue with
  | [] -> None
  | (time, entity) :: _ -> Some (entity, time)

let is_scheduled t (entity : Entity.entity_id) : bool =
  List.exists t.turn_queue ~f:(fun (_, e) -> e = entity)

let time_until t (time : int) : int =
  Int.(time - t.current_time) land Int.max_value

let is_before t (time_a : int) (time_b : int) : bool =
  time_until t time_a < time_until t time_b

let to_list t = t.turn_queue
let copy (t : t) : t = t (* Already persistent *)
let restore (_t : t) (src : t) : t = src (* Just return the source *)
