open Mode

let src = Logs.Src.create "backend" ~doc:"Backend"

module Log = (val Logs.src_log src : Logs.LOG)

(* This is the backend. All game-modifying functions go through here *)

(* The actual game (server) state
   Observers can observe data in the backend,
   but actions can only be taken via messages (Backend.Action)
*)

type t = {
  seed : int;
  debug : bool;
  map : Tilemap.t;
  mode : CtrlMode.t;
  controller_id : int;
  random : Rng.State.t;
  entities : Entity_manager.t; (* Entity management system *)
}
(* [@@deriving yojson] *)

let bump ?(step = 1) x = x + step

let make ~debug ~w ~h ~random ~seed =
  let map = Tilemap.generate ~w ~h ~seed in
  let entities = Entity_manager.make () in

  (* Create player entity *)
  let player = Entity.make_player ~pos_x:20 ~pos_y:20 ~name:"Player" in
  let entities_with_player = Entity_manager.add_player entities player in

  (* Add some test entities *)
  let entities_final =
    if debug then
      let test_enemy =
        Entity.make_enemy ~pos_x:1 ~pos_y:1 ~name:"Test Enemy" ()
      in
      let health_potion =
        Entity.make_item ~pos_x:8 ~pos_y:8 ~name:"Health Potion"
          ~item_type:Entity.Potion ~item_effect:(Entity.Heal 5) ()
      in
      Entity_manager.add_entities entities_with_player
        [ test_enemy; health_potion ]
    else entities_with_player
  in

  (* player *)
  let controller_id = 0 in
  {
    debug;
    seed;
    random;
    map;
    mode = CtrlMode.Normal;
    controller_id;
    entities = entities_final;
  }

let get_tile v x y = Tilemap.get_tile v.map x y

(* Get player entity or raise an exception *)
let get_player v =
  match v.entities.Entity_manager.player with
  | Some player -> player
  | None -> failwith "No player entity found"

(* Get player position *)
let get_player_pos v =
  let player = get_player v in
  (player.Entity.pos_x, player.Entity.pos_y)

(* Try to move the player in the given direction *)
let try_move_player v dx dy =
  let player = get_player v in
  let updated_entities =
    Entity_manager.try_move_entity v.entities player dx dy v.map
  in
  { v with entities = updated_entities }

(* Get all entities at a position *)
let get_entities_at v x y = Entity_manager.get_entities_at v.entities x y

(* Get a blocking entity at a position if any *)
let get_blocking_entity_at v x y =
  Entity_manager.get_blocking_entity_at v.entities x y

(* Apply damage to an entity at a position *)
let damage_entity_at v x y amount =
  let updated_entities =
    Entity_manager.damage_entity_at v.entities x y amount
  in
  let updated_entities = Entity_manager.remove_dead_entities updated_entities in
  { v with entities = updated_entities }
