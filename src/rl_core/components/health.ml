open Base

let table : (int, int) Hashtbl.t = Hashtbl.Poly.create ()
let get id = Hashtbl.find table id
let set id health = Hashtbl.set table ~key:id ~data:health
let remove id = Hashtbl.remove table id
