open Mode
open Base
open Types
open Entity

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
  random : Rng.State.t;
  entities : EntityManager.t;
  player : player;
}
(* [@@deriving yojson] *)

let make_default ~debug =
  let random = Rng.get_state () in
  let seed = Rng.seed_int in
  let map = Tilemap.default_map () in

  let entities = EntityManager.create () in

  {
    debug;
    seed;
    random;
    map;
    entities;
    mode = CtrlMode.Normal;
    player = { entity_id = 0 };
  }

let update b_end ~w ~h ~seed =
  { b_end with seed; map = Tilemap.generate ~seed ~w ~h }

(* Helper function to get all entities *)
let get_entities (backend : t) : entity list =
  EntityManager.to_list backend.entities

let get_entity_at_pos (entities : EntityManager.t) (pos : loc) : entity option =
  EntityManager.find_by_pos entities pos

(* Helper function to get player entity *)
let get_player_entity (backend : t) : entity option =
  EntityManager.find backend.entities backend.player.entity_id

(** [move_player backend direction]: Attempts to move the player in the given
    direction. If the target tile is walkable and no entity blocks the way,
    updates position and direction. Otherwise, only updates direction. *)
let move_player (backend : t) (dir : direction) : t =
  match EntityManager.find backend.entities backend.player.entity_id with
  | None -> backend (* Player entity not found - should not happen *)
  | Some player_ent ->
      let x, y = player_ent.pos in
      let dx, dy =
        match dir with
        | North -> (0, -1)
        | South -> (0, 1)
        | East -> (1, 0)
        | West -> (-1, 0)
      in
      let x' = x + dx in
      let y' = y + dy in
      let target_pos = (x', y') in
      let within_bounds =
        x' >= 0
        && x' < Tilemap.get_width backend.map
        && y' >= 0
        && y' < Tilemap.get_height backend.map
      in
      let walkable =
        within_bounds && Tile.walkable (Tilemap.get_tile backend.map x' y')
      in
      let no_entity_blocks =
        Option.is_none (get_entity_at_pos backend.entities target_pos)
      in

      if walkable && no_entity_blocks then (
        let updated_player =
          { player_ent with pos = target_pos; direction = dir }
        in
        EntityManager.update backend.entities backend.player.entity_id (fun _ ->
            updated_player);
        backend)
      else
        let updated_player = { player_ent with direction = dir } in
        EntityManager.update backend.entities backend.player.entity_id (fun _ ->
            updated_player);
        backend
