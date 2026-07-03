
(* Machine virtuelle pour le cours de compilation *)

val silent : bool ref
val trace : bool ref
val set_stack_size : int -> unit (* initialement 10000 éléments *)
val set_call_stack_size : int -> unit (* initialement 100 éléments *)

val load_code : string -> unit
val set_code : Code.compiled -> unit

(* état de la machine virtuelle *)

type element = 
  | Int of int
  | Float of float
  | StringA of Hstring.t (* chaîne *)
  | StackA  of int (* adresse dans la pile *)
  | CodeA   of int (* adresse de code *)
  | HeapA   of int * int (* adresse dans le tas + offset *)

module Stack : sig type 'a t = 'a array end

module IntMap : Map.S with type key = int 

module Heap : sig type 'a t = 'a IntMap.t end

type t = {
  mutable code : Code.compiled;
  mutable stack : element Stack.t;
  mutable sp : int;
  mutable fp : int;
  mutable gp : int;
  mutable pc : int;
  mutable heap : element array Heap.t;
  mutable strings: Hstring.t IntMap.t;
  mutable call_sp : int;
  mutable calls : (int * int) Stack.t;
  mutable count : int;
}

val vm : t

(* exécution *)

exception SegmentationFault
exception IllegalOperand
exception StackOverflow  
exception DivisionByZero
exception Error of string

val step : unit -> unit
val run : unit -> unit

val reset : unit -> unit

(* dump *)

val load : string -> unit
val save : string -> unit

(* fonctions d'interaction *)

val input_string : (unit -> string) ref
val write_string : (string -> unit) ref

val draw_line : (int -> int -> int -> int -> unit) ref
val draw_point : (int -> int -> unit) ref
val draw_circle : (int -> int -> int -> unit) ref
val draw_rect : (int -> int -> int -> int -> unit) ref
val fill_rect : (int -> int -> int -> int -> unit) ref
val set_color : (int -> int -> int -> unit) ref
val get_mouse : (unit -> int * int) ref
val clear_drawing_area : (unit -> unit) ref
val open_drawing_area : (int -> int -> unit) ref
val refresh : (unit -> unit) ref

(* pretty-print *)

open Format

val string_of_element : element -> string

val show_stack : formatter -> int -> unit (* montre au plus [n] éléments *)

