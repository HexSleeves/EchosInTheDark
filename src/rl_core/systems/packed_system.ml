open Base
open Packed_components

let to_packed_position (p : Components.Position.t) :
    Packed_components.Position.t =
  { world_pos = p.world_pos; chunk_pos = p.chunk_pos; local_pos = p.local_pos }

let to_packed_stats (s : Components.Stats.t) : Packed_components.Stats.t =
  {
    max_hp = s.max_hp;
    hp = s.hp;
    attack = s.attack;
    defense = s.defense;
    speed = s.speed;
    level = s.level;
  }

let to_packed_blocking (b : Components.Blocking.t) :
    Packed_components.Blocking.t =
  b

let to_packed_renderable (r : Components.Renderable.t) :
    Packed_components.Renderable.t =
  { glyph = r.glyph }

let from_packed_position (p : Packed_components.Position.t) :
    Components.Position.t =
  { world_pos = p.world_pos; chunk_pos = p.chunk_pos; local_pos = p.local_pos }

let from_packed_stats (s : Packed_components.Stats.t) : Components.Stats.t =
  {
    max_hp = s.max_hp;
    hp = s.hp;
    attack = s.attack;
    defense = s.defense;
    speed = s.speed;
    level = s.level;
  }

let from_packed_blocking (b : Packed_components.Blocking.t) :
    Components.Blocking.t =
  b

let from_packed_renderable (r : Packed_components.Renderable.t) :
    Components.Renderable.t =
  { glyph = r.glyph }

(* Global packed components storage *)
let packed_components = ref (create ())

(* Initialize the packed system by creating empty component arrays *)
let init () = packed_components := create ()

(* Sync from hashtable components to packed arrays *)
let sync_from_hashtables () =
  (* Get all entities from entity manager *)
  let entities =
    List.filter (List.init max_entities ~f:Fn.id) ~f:(fun id ->
        !packed_components.masks.has_position.(id))
  in

  (* Sync Position components *)
  List.iter entities ~f:(fun id ->
      match Components.Position.get id with
      | Some pos ->
          Packed_components.set_position !packed_components id
            (to_packed_position pos)
      | None -> Packed_components.remove_position !packed_components id);

  (* Sync Stats components *)
  List.iter entities ~f:(fun id ->
      match Components.Stats.get id with
      | Some stats ->
          Packed_components.set_stats !packed_components id
            (to_packed_stats stats)
      | None -> Packed_components.remove_stats !packed_components id);

  (* Sync Blocking components *)
  List.iter entities ~f:(fun id ->
      match Components.Blocking.get id with
      | Some blocking ->
          Packed_components.set_blocking !packed_components id
            (to_packed_blocking blocking)
      | None -> Packed_components.remove_blocking !packed_components id);

  (* Sync Renderable components *)
  List.iter entities ~f:(fun id ->
      match Components.Renderable.get id with
      | Some renderable ->
          Packed_components.set_renderable !packed_components id
            (to_packed_renderable renderable)
      | None -> Packed_components.remove_renderable !packed_components id)

(* Sync from packed arrays back to hashtables *)
let sync_to_hashtables () =
  (* Find all entities that have at least one component *)
  let entities_with_position =
    find_entities_with_components !packed_components ~has_position:true
      ~has_stats:false ~has_blocking:false ~has_renderable:false
  in

  let entities_with_stats =
    find_entities_with_components !packed_components ~has_position:false
      ~has_stats:true ~has_blocking:false ~has_renderable:false
  in

  let entities_with_blocking =
    find_entities_with_components !packed_components ~has_position:false
      ~has_stats:false ~has_blocking:true ~has_renderable:false
  in

  let entities_with_renderable =
    find_entities_with_components !packed_components ~has_position:false
      ~has_stats:false ~has_blocking:false ~has_renderable:true
  in

  (* Update position components in hashtables *)
  List.iter entities_with_position ~f:(fun id ->
      match get_position !packed_components id with
      | Some pos -> Components.Position.set id (from_packed_position pos)
      | None -> ());

  (* Update stats components in hashtables *)
  List.iter entities_with_stats ~f:(fun id ->
      match get_stats !packed_components id with
      | Some stats -> Components.Stats.set id (from_packed_stats stats)
      | None -> ());

  (* Update blocking components in hashtables *)
  List.iter entities_with_blocking ~f:(fun id ->
      match get_blocking !packed_components id with
      | Some blocking ->
          Components.Blocking.set id (from_packed_blocking blocking)
      | None -> ());

  (* Update renderable components in hashtables *)
  List.iter entities_with_renderable ~f:(fun id ->
      match get_renderable !packed_components id with
      | Some renderable ->
          Components.Renderable.set id (from_packed_renderable renderable)
      | None -> ())

(* Helper functions for optimized queries *)

(* Find all entities within a certain distance of a position *)
let find_entities_near_point ~center_x ~center_y ~radius =
  (* Find all entities with position *)
  let entities_with_pos =
    find_entities_with_components !packed_components ~has_position:true
      ~has_stats:false ~has_blocking:false ~has_renderable:false
  in

  (* Filter to those within radius *)
  List.filter entities_with_pos ~f:(fun id ->
      match get_position !packed_components id with
      | Some pos ->
          let dx = pos.world_pos.x - center_x in
          let dy = pos.world_pos.y - center_y in
          (dx * dx) + (dy * dy) <= radius * radius
      | None -> false)

(* Find all blocking entities in a specific area *)
let find_blocking_in_area ~min_x ~min_y ~max_x ~max_y =
  find_blocking_entities_in_region !packed_components ~min_x ~min_y ~max_x
    ~max_y

(* Optimized visibility check *)
let check_visibility ~from_id ~to_id =
  match
    ( get_position !packed_components from_id,
      get_position !packed_components to_id )
  with
  | Some from_pos, Some to_pos ->
      (* Basic line-of-sight check using positions *)
      let dx = to_pos.world_pos.x - from_pos.world_pos.x in
      let dy = to_pos.world_pos.y - from_pos.world_pos.y in
      let distance =
        Float.to_int (Float.sqrt (Float.of_int ((dx * dx) + (dy * dy))))
      in

      (* Check each point along the line for blocking entities *)
      let blocking_found = ref false in
      for t = 1 to distance - 1 do
        let x = from_pos.world_pos.x + (dx * t / distance) in
        let y = from_pos.world_pos.y + (dy * t / distance) in

        let blockers =
          find_blocking_in_area ~min_x:x ~min_y:y ~max_x:x ~max_y:y
        in
        if not (List.is_empty blockers) then blocking_found := true
      done;

      not !blocking_found
  | _, _ -> false

(* Optimized batch damage calculation for combat *)
let batch_calculate_damage ~attacker_ids ~defender_ids =
  (* Get all stats in batches *)
  let attacker_stats =
    List.filter_map attacker_ids ~f:(fun id -> get_stats !packed_components id)
  in
  let defender_stats =
    List.filter_map defender_ids ~f:(fun id -> get_stats !packed_components id)
  in

  (* Calculate damage for each pair *)
  List.zip_exn attacker_ids defender_ids
  |> List.mapi ~f:(fun i (attacker_id, defender_id) ->
         let attacker_stat = List.nth_exn attacker_stats i in
         let defender_stat = List.nth_exn defender_stats i in

         (* Basic damage formula *)
         let raw_damage =
           max 1 (attacker_stat.attack - defender_stat.defense)
         in
         (attacker_id, defender_id, raw_damage))

(* Update the game state using the packed component system *)
let update (state : State_types.t) : State_types.t =
  (* Ensure packed components are in sync with hashtables *)
  sync_from_hashtables ();

  (* Apply game logic using packed components for efficiency *)
  (* ... game logic using packed components ... *)

  (* Sync changes back to hashtables *)
  sync_to_hashtables ();

  state
