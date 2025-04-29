open Base
open Types

module type S = sig
  val decide : entity_id -> State.t -> Action.t
end

module Wander : sig
  val decide : entity_id -> State.t -> Action.t
end = struct
  let decide _entity_id _state =
    let dir =
      match
        List.random_element
          ~random_state:(Random.State.make_self_init ())
          Direction.all
      with
      | Some d -> d
      | None -> Direction.North
    in
    Action.Move dir
end
