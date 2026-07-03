
(* chaînes hachées *)

type t = { str_it : string; str_adr : int }

val clear : unit -> unit

val create : string -> t

val iter : (t -> unit) -> unit

