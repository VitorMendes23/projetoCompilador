
(* chaînes hachées *)

type t = { str_it : string; str_adr : int }

let h = Hashtbl.create 97

let clear () = Hashtbl.clear h

let create =
  let r = ref 0 in
  fun s ->
    try
      let x = Hashtbl.find h s in
      x
    with Not_found ->
      incr r;
      let str = { str_it = s; str_adr = !r } in
      Hashtbl.add h s str;
      str

let iter f = Hashtbl.iter (fun _ x -> f x) h

