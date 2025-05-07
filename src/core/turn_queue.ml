open Base
module Log = (val Logger.make_logger "turn_queue" ~doc:"Turn queue logs" ())

module MinHeap = Binary_heap.Make (struct
  type t = int * int [@@deriving yojson]

  let compare (a_time, _) (b_time, _) = Int.compare a_time b_time
end)
[@@deriving yojson, show]

(* Mutable min-heap of (time, id) using Binary_heap *)
type t = { mutable current_time : int; mutable heap : MinHeap.t }
[@@deriving yojson, show]

let to_yojson t =
  let elements = ref [] in
  MinHeap.iter (fun x -> elements := x :: !elements) t.heap;
  `Assoc
    [
      ("current_time", `Int t.current_time);
      ( "heap_elements",
        `List
          (List.rev !elements
          |> List.map ~f:(fun (time, id) -> `List [ `Int time; `Int id ])) );
    ]

let of_yojson = function
  | `Assoc
      [ ("current_time", `Int current_time); ("heap_elements", `List elements) ]
    -> (
      try
        let heap = MinHeap.create ~dummy:(-1, -1) 16 in
        List.iter elements ~f:(function
          | `List [ `Int time; `Int id ] -> MinHeap.add heap (time, id)
          | _ -> raise (Invalid_argument "malformed heap element"));
        Ok { current_time; heap }
      with Invalid_argument msg -> Error msg)
  | _ -> Error "malformed turn queue"

let create () : t =
  { current_time = 0; heap = MinHeap.create ~dummy:(-1, -1) 16 }

let current_time t = t.current_time

let print_turn_queue t =
  let elements = ref [] in
  MinHeap.iter (fun x -> elements := x :: !elements) t.heap;
  let queue_str =
    List.rev !elements
    |> List.map ~f:(fun (time, actor) ->
           Printf.sprintf "(time: %d, actor: %d)" time actor)
    |> String.concat ~sep:"; "
  in
  Log.info (fun m ->
      m "Current time: %d, Turn queue: [%s]" t.current_time queue_str)

let schedule_at t (entity_id : int) (next_time : int) =
  MinHeap.add t.heap (next_time, entity_id);
  t

let schedule_now t (entity_id : int) =
  MinHeap.add t.heap (current_time t, entity_id);
  t

let remove_actor t (entity_id : int) =
  let temp_heap = MinHeap.create ~dummy:(-1, -1) 16 in
  let elements = ref [] in
  MinHeap.iter (fun x -> elements := x :: !elements) t.heap;
  List.iter (List.rev !elements) ~f:(fun ((_, id) as x) ->
      if id <> entity_id then MinHeap.add temp_heap x);
  t.heap <- temp_heap;
  t

let get_next_actor t : (int * int) option * t =
  if MinHeap.is_empty t.heap then (None, t)
  else
    let time, id = MinHeap.minimum t.heap in
    MinHeap.remove t.heap;
    t.current_time <- time;
    (Some (id, time), t)

let peek_next t : (int * int) option =
  if MinHeap.is_empty t.heap then None
  else
    let time, entity = MinHeap.minimum t.heap in
    Some (entity, time)

let is_scheduled t (entity_id : int) : bool =
  let found = ref false in
  MinHeap.iter (fun (_, id) -> if id = entity_id then found := true) t.heap;
  !found

let time_until t (time : int) : int =
  Int.(time - t.current_time) land Int.max_value

let is_before t (time_a : int) (time_b : int) : bool =
  time_until t time_a < time_until t time_b

let to_list t =
  let elements = ref [] in
  MinHeap.iter (fun x -> elements := x :: !elements) t.heap;
  List.rev !elements

let copy (t : t) : t =
  let new_heap = MinHeap.create ~dummy:(-1, -1) 16 in
  MinHeap.iter (fun x -> MinHeap.add new_heap x) t.heap;
  { current_time = t.current_time; heap = new_heap }
