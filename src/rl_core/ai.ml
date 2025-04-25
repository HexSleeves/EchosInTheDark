open Base
open Types

module type S = sig
  val decide : Types.Entity.t -> State.t -> Types.Action.t
end

module Wander : sig
  val decide : Types.Entity.t -> State.t -> Types.Action.t
end = struct
  let decide _entity _state =
    let dirs =
      [ Direction.North; Direction.South; Direction.East; Direction.West ]
    in

    let dir =
      List.random_element_exn
        ~random_state:(Random.State.make_self_init ())
        dirs
    in
    Action.Move dir
end
