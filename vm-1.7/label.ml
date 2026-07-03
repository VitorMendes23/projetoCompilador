
type t = { symbolic : string; mutable address : int }

let table = Hashtbl.create 97

let clear () = Hashtbl.clear table

let create s =
  try
    Hashtbl.find table s
  with Not_found ->
    let l = { symbolic = s; address = -1 } in 
    Hashtbl.add table s l;
    l

