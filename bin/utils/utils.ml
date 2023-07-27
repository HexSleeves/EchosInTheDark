open Tsdl
open Containers

module Random = struct
  (* Expand Random to serialize the state *)
  include Random

  module State = struct
    include Random.State

    let t_of_yojson = function
      | `String s -> Marshal.from_string s 0
      | _ -> failwith "unexpected json"
    ;;

    let yojson_of_t v = `String (Marshal.to_string v [])
  end
end

(* Indexing *)
let calc_offset width x y = (y * width) + x

(* SDL *)
let get_time () = Sdl.get_ticks () |> Int32.to_int
