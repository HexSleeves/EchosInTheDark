open Base

(* Only import what we need from Rl_types, avoiding the entity type *)
module Direction = Rl_types.Direction
module Loc = Rl_types.Loc
module BiomeType = Rl_types.BiomeType
open Ppx_yojson_conv_lib.Yojson_conv

(* Maximum number of entities we expect in the system - can be adjusted *)
let max_entities = 10000

(* Module for tracking which entities have which components *)
module ComponentMask = struct
  type t = {
    has_position : bool array;
    has_stats : bool array;
    has_blocking : bool array;
    has_renderable : bool array;
  }

  let create () =
    {
      has_position = Base.Array.create ~len:max_entities false;
      has_stats = Base.Array.create ~len:max_entities false;
      has_blocking = Base.Array.create ~len:max_entities false;
      has_renderable = Base.Array.create ~len:max_entities false;
    }

  let has_component component_array (id : int) =
    if id >= 0 && id < max_entities then component_array.(id) else false

  let has_position t id = has_component t.has_position id
  let has_stats t id = has_component t.has_stats id
  let has_blocking t id = has_component t.has_blocking id
  let has_renderable t id = has_component t.has_renderable id

  let set_has_component component_array id value =
    if id >= 0 && id < max_entities then component_array.(id) <- value

  let set_has_position t id value = set_has_component t.has_position id value
  let set_has_stats t id value = set_has_component t.has_stats id value
  let set_has_blocking t id value = set_has_component t.has_blocking id value

  let set_has_renderable t id value =
    set_has_component t.has_renderable id value
end

(* Packed Position component *)
module Position = struct
  open Chunk

  type t = {
    world_pos : world_pos;
    chunk_pos : chunk_coord;
    local_pos : local_pos;
  }
  [@@deriving yojson, show, eq]

  type packed = {
    world_pos_x : int array;
    world_pos_y : int array;
    chunk_pos_x : int array;
    chunk_pos_y : int array;
    local_pos_x : int array;
    local_pos_y : int array;
  }

  let create_packed () =
    {
      world_pos_x = Array.create ~len:max_entities 0;
      world_pos_y = Array.create ~len:max_entities 0;
      chunk_pos_x = Array.create ~len:max_entities 0;
      chunk_pos_y = Array.create ~len:max_entities 0;
      local_pos_x = Array.create ~len:max_entities 0;
      local_pos_y = Array.create ~len:max_entities 0;
    }

  let get packed (id : int) =
    if id >= 0 && id < max_entities then
      Some
        {
          world_pos = Loc.make packed.world_pos_x.(id) packed.world_pos_y.(id);
          chunk_pos = Loc.make packed.chunk_pos_x.(id) packed.chunk_pos_y.(id);
          local_pos = Loc.make packed.local_pos_x.(id) packed.local_pos_y.(id);
        }
    else None

  let set packed (id : int) (pos : t) =
    if id >= 0 && id < max_entities then (
      packed.world_pos_x.(id) <- pos.world_pos.x;
      packed.world_pos_y.(id) <- pos.world_pos.y;
      packed.chunk_pos_x.(id) <- pos.chunk_pos.x;
      packed.chunk_pos_y.(id) <- pos.chunk_pos.y;
      packed.local_pos_x.(id) <- pos.local_pos.x;
      packed.local_pos_y.(id) <- pos.local_pos.y)

  let remove packed (id : int) =
    if id >= 0 && id < max_entities then (
      packed.world_pos_x.(id) <- 0;
      packed.world_pos_y.(id) <- 0;
      packed.chunk_pos_x.(id) <- 0;
      packed.chunk_pos_y.(id) <- 0;
      packed.local_pos_x.(id) <- 0;
      packed.local_pos_y.(id) <- 0)

  let show t =
    Printf.sprintf "World: %s, Chunk: %s, Local: %s"
      (Loc.to_string t.world_pos)
      (Loc.to_string t.chunk_pos)
      (Loc.to_string t.local_pos)

  let make (world : Loc.t) : t =
    let chunk : chunk_coord = world_to_chunk_coord world in
    let local : local_pos = world_to_local_coord world in
    { world_pos = world; chunk_pos = chunk; local_pos = local }

  (* Get a position as a struct of arrays for batch processing *)
  let get_batch packed entity_ids =
    let count = Array.length entity_ids in
    let result =
      {
        world_pos_x = Array.create ~len:count 0;
        world_pos_y = Array.create ~len:count 0;
        chunk_pos_x = Array.create ~len:count 0;
        chunk_pos_y = Array.create ~len:count 0;
        local_pos_x = Array.create ~len:count 0;
        local_pos_y = Array.create ~len:count 0;
      }
    in

    Array.iteri entity_ids ~f:(fun i id ->
        if id >= 0 && id < max_entities then (
          result.world_pos_x.(i) <- packed.world_pos_x.(id);
          result.world_pos_y.(i) <- packed.world_pos_y.(id);
          result.chunk_pos_x.(i) <- packed.chunk_pos_x.(id);
          result.chunk_pos_y.(i) <- packed.chunk_pos_y.(id);
          result.local_pos_x.(i) <- packed.local_pos_x.(id);
          result.local_pos_y.(i) <- packed.local_pos_y.(id)));
    result
end

(* Packed Stats component *)
module Stats = struct
  type t = {
    max_hp : int;
    hp : int;
    attack : int;
    defense : int;
    speed : int;
    level : int;
  }
  [@@deriving yojson, show]

  type packed = {
    max_hp : int array;
    hp : int array;
    attack : int array;
    defense : int array;
    speed : int array;
    level : int array;
  }

  (* Create an array of default values *)
  let create_packed () =
    {
      max_hp = Array.create ~len:max_entities 0;
      hp = Array.create ~len:max_entities 0;
      attack = Array.create ~len:max_entities 0;
      defense = Array.create ~len:max_entities 0;
      speed = Array.create ~len:max_entities 0;
      level = Array.create ~len:max_entities 0;
    }

  (* Extract a single entity's stats from the packed representation *)
  let get packed (id : int) =
    if id >= 0 && id < max_entities then
      Some
        ({
           max_hp = packed.max_hp.(id);
           hp = packed.hp.(id);
           attack = packed.attack.(id);
           defense = packed.defense.(id);
           speed = packed.speed.(id);
           level = packed.level.(id);
         }
          : t)
    else None

  let get_exn packed (id : int) = get packed id |> Option.value_exn

  (* Store a single entity's stats in the packed representation *)
  let set packed (id : int) (stats : t) =
    if id >= 0 && id < max_entities then (
      packed.max_hp.(id) <- stats.max_hp;
      packed.hp.(id) <- stats.hp;
      packed.attack.(id) <- stats.attack;
      packed.defense.(id) <- stats.defense;
      packed.speed.(id) <- stats.speed;
      packed.level.(id) <- stats.level)

  let set_exn packed (id : int) (stats : t) = set packed id stats

  (* Reset an entity's stats to default values *)
  let remove packed (id : int) =
    if id >= 0 && id < max_entities then (
      packed.max_hp.(id) <- 0;
      packed.hp.(id) <- 0;
      packed.attack.(id) <- 0;
      packed.defense.(id) <- 0;
      packed.speed.(id) <- 0;
      packed.level.(id) <- 0)

  (* Default stats for new entities *)
  let default () : t =
    { max_hp = 30; hp = 30; attack = 10; defense = 5; speed = 100; level = 1 }

  (* Create stats with specified values *)
  let create ~max_hp ~hp ~attack ~defense ~speed ?(level = 1) () : t =
    { max_hp; hp; attack; defense; speed; level }

  (* Batch operations for efficient processing *)
  let get_batch packed entity_ids =
    let count = Array.length entity_ids in
    let result =
      {
        max_hp = Array.create ~len:count 0;
        hp = Array.create ~len:count 0;
        attack = Array.create ~len:count 0;
        defense = Array.create ~len:count 0;
        speed = Array.create ~len:count 0;
        level = Array.create ~len:count 0;
      }
    in

    Array.iteri entity_ids ~f:(fun i id ->
        if id >= 0 && id < max_entities then (
          result.max_hp.(i) <- packed.max_hp.(id);
          result.hp.(i) <- packed.hp.(id);
          result.attack.(i) <- packed.attack.(id);
          result.defense.(i) <- packed.defense.(id);
          result.speed.(i) <- packed.speed.(id);
          result.level.(i) <- packed.level.(id)));
    result
end

(* Packed Blocking component *)
module Blocking = struct
  type t = bool

  (* For boolean components, we can use a single bit array *)
  type packed = bool array

  let create_packed () = Array.create ~len:max_entities false

  let get packed (id : int) =
    if id >= 0 && id < max_entities then Some packed.(id) else None

  let set packed (id : int) value =
    if id >= 0 && id < max_entities then packed.(id) <- value

  let remove packed (id : int) =
    if id >= 0 && id < max_entities then packed.(id) <- false
end

(* Packed Renderable component *)
module Renderable = struct
  type t = { glyph : char }

  (* For simple components, we can just use arrays *)
  type packed = { glyph : char array }

  let create_packed () = { glyph = Array.create ~len:max_entities ' ' }

  let get packed (id : int) =
    if id >= 0 && id < max_entities then
      Some ({ glyph = packed.glyph.(id) } : t)
    else None

  let set packed (id : int) (renderable : t) =
    if id >= 0 && id < max_entities then packed.glyph.(id) <- renderable.glyph

  let remove packed (id : int) =
    if id >= 0 && id < max_entities then packed.glyph.(id) <- ' '
end

(* Core storage for all packed components *)
type t = {
  masks : ComponentMask.t;
  positions : Position.packed;
  stats : Stats.packed;
  blocking : Blocking.packed;
  renderables : Renderable.packed;
}

(* Create a new packed component storage *)
let create () =
  {
    masks = ComponentMask.create ();
    positions = Position.create_packed ();
    stats = Stats.create_packed ();
    blocking = Blocking.create_packed ();
    renderables = Renderable.create_packed ();
  }

(* Position component operations *)
let has_position t (id : int) = ComponentMask.has_position t.masks id

let get_position t (id : int) =
  if has_position t id then Position.get t.positions id else None

let set_position t (id : int) pos =
  Position.set t.positions id pos;
  ComponentMask.set_has_position t.masks id true

let remove_position t (id : int) =
  Position.remove t.positions id;
  ComponentMask.set_has_position t.masks id false

(* Stats component operations *)
let has_stats t (id : int) = ComponentMask.has_stats t.masks id

let get_stats t (id : int) =
  if has_stats t id then Stats.get t.stats id else None

let set_stats t (id : int) stats =
  Stats.set t.stats id stats;
  ComponentMask.set_has_stats t.masks id true

let remove_stats t (id : int) =
  Stats.remove t.stats id;
  ComponentMask.set_has_stats t.masks id false

(* Blocking component operations *)
let has_blocking t (id : int) = ComponentMask.has_blocking t.masks id

let get_blocking t (id : int) =
  if has_blocking t id then Blocking.get t.blocking id else None

let set_blocking t (id : int) value =
  Blocking.set t.blocking id value;
  ComponentMask.set_has_blocking t.masks id true

let remove_blocking t (id : int) =
  Blocking.set t.blocking id false;
  ComponentMask.set_has_blocking t.masks id false

(* Renderable component operations *)
let has_renderable t (id : int) = ComponentMask.has_renderable t.masks id

let get_renderable t (id : int) =
  if has_renderable t id then Renderable.get t.renderables id else None

let set_renderable t (id : int) renderable =
  Renderable.set t.renderables id renderable;
  ComponentMask.set_has_renderable t.masks id true

let remove_renderable t (id : int) =
  Renderable.remove t.renderables id;
  ComponentMask.set_has_renderable t.masks id false

(* Utility functions for finding entities with specific components *)
let find_entities_with_components t ~has_position ~has_stats ~has_blocking
    ~has_renderable =
  let result = ref [] in
  for id = 0 to max_entities - 1 do
    let matches =
      ((not has_position) || ComponentMask.has_position t.masks id)
      && ((not has_stats) || ComponentMask.has_stats t.masks id)
      && ((not has_blocking) || ComponentMask.has_blocking t.masks id)
      && ((not has_renderable) || ComponentMask.has_renderable t.masks id)
    in
    if matches then result := id :: !result
  done;
  !result

(* Batch processing example: update all positions *)
let batch_update_positions t entity_ids ~update_fn =
  let entity_ids_array = Array.of_list entity_ids in
  let positions = Position.get_batch t.positions entity_ids_array in
  (* Process positions in a batch-friendly way using update_fn *)
  Array.iteri entity_ids_array ~f:(fun i id ->
      (* This is where you'd apply your batch update logic *)
      ())

(* Advanced batch query: find all blocking entities in a specific region *)
let find_blocking_entities_in_region t ~min_x ~min_y ~max_x ~max_y =
  let candidates =
    find_entities_with_components t ~has_position:true ~has_blocking:true
      ~has_stats:false ~has_renderable:false
  in

  List.filter candidates ~f:(fun id ->
      match get_position t id with
      | Some pos -> (
          pos.world_pos.x >= min_x && pos.world_pos.x <= max_x
          && pos.world_pos.y >= min_y && pos.world_pos.y <= max_y
          && match get_blocking t id with Some true -> true | _ -> false)
      | None -> false)
