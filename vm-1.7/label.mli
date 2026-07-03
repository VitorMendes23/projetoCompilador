
(* les labels sont créés pendant le parsing et partagés *)

type t = { symbolic : string; mutable address : int }

val clear : unit -> unit

val create : string -> t



