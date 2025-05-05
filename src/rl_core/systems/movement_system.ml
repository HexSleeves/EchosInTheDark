open Base
open Events.Event_bus
open Components
open Rl_types

let move_entity ~(entity_id : int) ~(go_to : Loc.t) (state : State_types.t) :
    State_types.t =
  let from_pos = Position.get_exn entity_id in
  let to_pos = Chunk_manager.make_position go_to in

  (* Update the Position component table *)
  State.move_entity entity_id to_pos state
  |> publish (EntityMoved { entity_id; from_pos; to_pos })

type move_result =
  | Moved
  | Blocked_by_entity of { target_id : entity }
  | Blocked_by_terrain

let try_move_entity ~(state : State.t) ~(entity_id : int) ~(dir : Direction.t) :
    State.t * move_result =
  let open Chunk_manager in
  let chunk_width = Constants.chunk_w in
  let chunk_height = Constants.chunk_h in

  let delta = Direction.to_point dir in
  let pos = Position.get_exn entity_id in
  let new_pos = Loc.(pos.world_pos + delta) in

  let crossed_chunk_boundary =
    let old_chunk = world_to_chunk_coord pos.world_pos in
    let new_chunk = world_to_chunk_coord new_pos in
    let crossed = not Poly.(old_chunk = new_chunk) in
    crossed
  in

  let old_local = world_to_local_coord pos.world_pos in
  let wrapped_new_pos =
    if crossed_chunk_boundary then
      let cx, cy = Loc.to_tuple (world_to_chunk_coord pos.world_pos) in

      let wrapped =
        match dir with
        | Direction.North ->
            let wrapped_cy = cy - 1 in
            Logs.info (fun m ->
                m "height: %d, cx: %d, cy: %d (wrapped_cy: %d)" chunk_height cx
                  cy wrapped_cy);
            Loc.make
              ((cx * chunk_width) + old_local.x)
              ((wrapped_cy * chunk_height) + (chunk_height - 1))
        | Direction.South ->
            let wrapped_cy = cy + 1 in
            Loc.make
              ((cx * chunk_width) + old_local.x)
              (wrapped_cy * chunk_height)
        | Direction.West ->
            let wrapped_cx = cx - 1 in
            Loc.make
              ((wrapped_cx * chunk_width) + (chunk_width - 1))
              ((cy * chunk_height) + old_local.y)
        | Direction.East ->
            let wrapped_cx = cx + 1 in
            Loc.make (wrapped_cx * chunk_width)
              ((cy * chunk_height) + old_local.y)
      in

      wrapped
    else new_pos
  in

  match State.get_blocking_entity_at_pos wrapped_new_pos state with
  | Some target_entity ->
      (state, Blocked_by_entity { target_id = target_entity })
  | None -> (
      match State.get_tile_at state wrapped_new_pos with
      | Some tile when Dungeon.Tile.is_walkable tile ->
          (move_entity ~entity_id ~go_to:wrapped_new_pos state, Moved)
      | _ -> (state, Blocked_by_terrain))
