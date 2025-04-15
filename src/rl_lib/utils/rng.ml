(* Expand Random to serialize the state *)
include Containers.Random

let state = Random.State.make_self_init ()

module State = struct
  include Random.State

  let t_of_yojson = function
    | `String s -> Marshal.from_string s 0
    | _ -> failwith "unexpected json"

  let yojson_of_t v = `String (Marshal.to_string v [])
end

let seed_int = State.int state 0x7FFF
