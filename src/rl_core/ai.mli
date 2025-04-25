(** AI interface for creatures. *)
module type S = sig
  val decide : Types.Entity.t -> State.t -> Types.Action.t
  (** [decide entity state] returns the next action for [entity] given the
      current [state]. *)
end

module Wander : S
