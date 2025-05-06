open Base

(* Use State_types.t directly, since state_types.ml does not define a module *)

type entity = int

type t = {
  next_id : entity;
  player_id : entity option;
  entity_table : (entity, unit) Hashtbl.t;
}

let create () =
  { entity_table = Hashtbl.create (module Int); next_id = 0; player_id = None }

(* All functions now take state : State_types.t as first argument *)

let register_entity id m =
  Hashtbl.set m.entity_table ~key:id ~data:();
  m

let remove_entity id m =
  Hashtbl.remove m.entity_table id;
  m

let register_player id m =
  let m = register_entity id m in
  { m with player_id = Some id }

let register_entities (entities : entity list) m =
  List.fold_left entities ~init:m ~f:(fun st id -> register_entity id st)

let remove_entities (entities : entity list) m =
  List.fold_left entities ~init:m ~f:(fun st id -> remove_entity id st)

let is_registered id m = Hashtbl.mem m.entity_table id
let all_entities m = Hashtbl.keys m.entity_table
let entity_count m = Hashtbl.length m.entity_table
let set_player_id id m = { m with player_id = Some id }
let get_player_id m = m.player_id

let is_player (id : entity) : bool =
  match Components.Kind.get id with
  | Some Components.Kind.Player -> true
  | _ -> false

let find_player_id (em : t) : entity option =
  Hashtbl.keys em.entity_table |> List.find ~f:is_player

let get_player_id_exn (em : t) : entity =
  match find_player_id em with
  | Some id -> id
  | None -> failwith "Player entity not loaded"

let save_entities path (entities : entity list) =
  Yojson.Safe.to_file path (`List (List.map ~f:(fun i -> `Int i) entities))

let load_entities path : entity list =
  match Yojson.Safe.from_file path with
  | `List lst ->
      List.filter_map ~f:(function `Int i -> Some i | _ -> None) lst
  | _ -> []

let entity_path_for_chunk (chunk_path : string) : string =
  String.substr_replace_all ~pattern:"chunk_" ~with_:"entities_" chunk_path

let spawn_entity (em : t) : entity * t =
  let id = em.next_id in
  (id, register_entity id { em with next_id = id + 1 })

let print_entities m =
  Hashtbl.iteri m.entity_table ~f:(fun ~key ~data:_ ->
      match m.player_id with
      | Some pid when pid = key ->
          Stdio.print_endline (Printf.sprintf "Entity: %d (Player)" key)
      | _ -> Stdio.print_endline (Printf.sprintf "Entity: %d" key))

let next_id m =
  let id = m.next_id in
  (id, { m with next_id = id + 1 })
