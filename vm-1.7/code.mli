
(* chargement de code: [load_code f] charge le code contenu dans le fichier
   [f]; [compile f] compile les étiquettes symboliques vers des adresses
   numériques; [load_and_compile] fait les deux. *)

type symbolic = (Instr.t*string option) list

exception SyntaxError of int

val from_channel : in_channel -> symbolic
val from_file : string -> symbolic

type compiled = Instr.t array

val compile : symbolic -> compiled

val load_and_compile : string -> compiled


(* afficheurs *)

open Format

val print_instr : formatter -> Instr.t*string option -> unit
val string_of_instr : Instr.t*string option -> string

val print_list  : formatter -> (Instr.t*string option) list -> unit
val print_array : formatter -> (Instr.t*string option) array -> unit

