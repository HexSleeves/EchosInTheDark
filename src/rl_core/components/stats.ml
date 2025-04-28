open Base

let table : (int, Types.Stats.t) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id

let get_exn id =
  Option.value_exn (Hashtbl.find table id)
    ~message:(Printf.sprintf "No stats for entity id %d" id)

let set id stats = Hashtbl.set table ~key:id ~data:stats
let remove id = Hashtbl.remove table id
