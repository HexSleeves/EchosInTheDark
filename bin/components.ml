open Rl2023.Engine

module Commands = struct
  type command = GoUp | GoDown | GoLeft | GoRight | Attack
end

module Input = InputFrom (Commands)

module Health = struct
  type s = int

  include (val Component.create () : Component.Sig with type t = s)
end

(* Tags *)
module Enemy = struct
  type s = unit

  include (val Component.create () : Component.Sig with type t = s)
end
