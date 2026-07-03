
(* Machine virtuelle pour le cours de compilation *)

open Format
open Label
open Hstring
open Instr

(* éléments sur la pile *)

type element = 
  | Int of int
  | Float of float
  | StringA of Hstring.t (* chaîne *)
  | StackA  of int (* adresse dans la pile *)
  | CodeA   of int (* adresse de code *)
  | HeapA   of int * int (* adresse dans le tas + offset *)

(* piles *)

module Stack = struct

  type 'a t = 'a array

  let create n x = Array.create n x

  let resize s n = 
    let ns = Array.length s in
    if ns >= n then
      s
    else begin
      let a = Array.create n s.(0) in
      Array.blit s 0 a 0 ns;
      a
    end

end

(* tas *)

module IntMap = Map.Make(struct type t = int let compare = compare end)

module Heap = struct

  type 'a t = 'a IntMap.t

  let empty = IntMap.empty

  let gen_adr = let r = ref 0 in fun () -> incr r; !r

  let alloc h x =
    let a = gen_adr () in
    let h' = IntMap.add a x h in
    a, h'

  let free h a = if IntMap.mem a h then IntMap.remove a h else raise Not_found

end

(* machine virtuelle *)

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

let init_value = 666 (* éviter 0 pour vérifier visuellement les init. *)

let stack_size = ref 10000
let call_stack_size = ref 100

let vm = { 
  code = [||];
  stack = Stack.create !stack_size (Int init_value);
  sp = 0;
  fp = 0;
  gp = 0;
  pc = 0;
  heap = Heap.empty;
  strings = IntMap.empty;
  call_sp = 0;
  calls = Stack.create !call_stack_size (0,0);
  count = 0;
}

(* options *)

let trace = ref false

let silent = ref false

let set_stack_size n = 
  stack_size := n;
  vm.stack <- Stack.resize vm.stack n

let set_call_stack_size n =
  call_stack_size := n;
  vm.calls <- Stack.resize vm.calls n

(* (ré)initialisation *)

let init_strings () =
  vm.strings <- IntMap.empty;
  Array.iter
    (function 
       | Pushs s -> vm.strings <- IntMap.add s.str_adr s vm.strings
       | _ -> ())
    vm.code

let reset () =
  vm.pc <- 0;
  vm.sp <- 0;
  vm.fp <- 0;
  vm.gp <- 0;
  vm.heap <- Heap.empty;
  vm.call_sp <- 0;
  vm.count <- 0;
  init_strings ()

(* chargement de code *)

let set_code c = 
  vm.code <- c;
  reset ()

let load_code f = set_code (Code.load_and_compile f)

(* exécution *)

(* exceptions pouvant être levées durant l'exécution *)
  
exception SegmentationFault
exception IllegalOperand
exception StackOverflow  
exception DivisionByZero
exception Error of string

(* fonction d'interaction *)

let input_string = ref (fun () -> printf "read => @."; read_line ())

let write_string = ref (fun s -> printf "%s@?" s)

let draw_line_aux x1 y1 x2 y2 = printf "DrawLine %d,%d -> %d,%d@." x1 y1 x2 y2

let draw_line = ref draw_line_aux
   
let draw_point_aux x y = printf "DrawPoint %d,%d@." x y
  
let draw_point = ref draw_point_aux

let draw_circle_aux x y r = printf "DrawCircle %d,%d ; %d@." x y r

let draw_circle = ref draw_circle_aux

let set_color_aux x y z = printf "SetColor %d,%d,%d@." x y z

let draw_rect_aux x y w h = printf "DrawRect %d,%d,%d,%d@." x y w h

let draw_rect = ref draw_rect_aux

let fill_rect_aux x y w h = printf "FillRect %d,%d,%d,%d@." x y w h

let fill_rect = ref fill_rect_aux

let set_color = ref set_color_aux

let clear_drawing_area =  ref (fun () -> printf "ClearDrawingArea@.")

let open_drawing_area =  ref (fun x y -> printf "OpenDrawingArea %d,%d@." x y)

let get_mouse = ref (fun () -> printf "get_mouse@."; 0,0)

let refresh = ref (fun () -> () (* printf "Refresh@." *))

(* diverses fonctions d'accès et de modification aux piles et aux tas *)

let gp i =
  let a = vm.gp + i in
  if a < 0 || a > Array.length vm.stack then raise SegmentationFault;
  vm.stack.(a)

let fp i =
  let a = vm.fp + i in
  if a < 0 || a > Array.length vm.stack then raise SegmentationFault;
  vm.stack.(a)

let pop f () = 
  let sp' = vm.sp - 1 in
  if sp' < 0 || sp' > Array.length vm.stack then raise SegmentationFault;
  let v = f vm.stack.(sp') in 
  vm.sp <- sp'; 
  v

let pop_int = pop (function Int i -> i | _ -> raise IllegalOperand)

let pop_float = pop (function Float f -> f | _ -> raise IllegalOperand)

let pop_stack_a = pop (function StackA a -> a | _ -> raise IllegalOperand)

let pop_string_a = pop (function StringA a -> a | _ -> raise IllegalOperand)

let pop_heap_a = pop (function HeapA (a,_) -> a | _ -> raise IllegalOperand)

let pop_value = pop (fun v -> v)

let push v =
  if vm.sp = Array.length vm.stack then raise StackOverflow;
  vm.stack.(vm.sp) <- v;
  vm.sp <- vm.sp + 1

let push_call v =
  if vm.call_sp = Array.length vm.calls then raise StackOverflow;
  vm.calls.(vm.call_sp) <- v;
  vm.call_sp <- vm.call_sp + 1

let pop_call () =
  if vm.call_sp = 0 then raise SegmentationFault;
  let sp' = vm.call_sp - 1 in
  let v = vm.calls.(sp') in
  vm.call_sp <- sp';
  v

let int_bin_op op = 
  let n = pop_int () in let m = pop_int () in push (Int (op m n))

let int_division n m = if m = 0 then raise DivisionByZero; n / m

let int_bin_cmp cmp = 
  int_bin_op (fun m n -> if cmp m n then 1 else 0)

let float_un_op op =
  let n = pop_float () in push (Float (op n))

let float_bin_op op = 
  let n = pop_float () in let m = pop_float () in push (Float (op m n))

let float_bin_cmp cmp = 
  let n = pop_float () in let m = pop_float () in 
  push (Int (if cmp m n then 1 else 0))

let offset a n =
  let an = a + n in
  if an < 0 || an > Array.length vm.stack then raise SegmentationFault;
  an

let alloc_string s =
  let s = Hstring.create s in
  vm.strings <- IntMap.add s.str_adr s vm.strings;
  s

let alloc_bloc n =
  if n < 0 then raise IllegalOperand;
  let b = Array.create n (Int init_value) in
  let a,h = Heap.alloc vm.heap b in
  vm.heap <- h;
  a

let get_field a n =
  try
    let bl = IntMap.find a vm.heap in
    if n < 0 || n >= Array.length bl then raise SegmentationFault;
    bl.(n)
  with Not_found -> 
    raise SegmentationFault

let set_field a n v =
  try
    let bl = IntMap.find a vm.heap in
    if n < 0 || n >= Array.length bl then raise SegmentationFault;
    bl.(n) <- v
  with Not_found -> 
    raise SegmentationFault

let free_bloc a =
  try
    vm.heap <- Heap.free vm.heap a
  with Not_found ->
    raise SegmentationFault

(* un pas d'exécution *)

let step () = 
  if vm.pc < 0 || vm.pc >= Array.length vm.code then raise SegmentationFault;
  let inst = vm.code.(vm.pc) in
  vm.pc <- vm.pc + 1;
  vm.count <- vm.count + 1;
  match inst with
  (* opérations sur les entiers *)
    | Add -> int_bin_op (+)
    | Sub -> int_bin_op (-)
    | Mul -> int_bin_op ( * )
    | Div -> int_bin_op int_division
    | Mod -> int_bin_op (mod)
    | Not -> let n = pop_int () in push (Int (if n = 0 then 1 else 0))
    | Irandom -> 
	let n = pop_int () in 
	push (Int (Random.int n))
  (* opérations sur les réels *)
    | Fadd -> float_bin_op (+.)
    | Fsub -> float_bin_op (-.)
    | Fmul -> float_bin_op ( *. )
    | Fdiv -> float_bin_op (/.)
    | Fcos -> float_un_op cos
    | Fsin -> float_un_op sin
    | Fsqrt -> float_un_op sqrt
   
    | Frandom -> 
	let n = pop_float () in 
	push (Float (Random.float n))
  (* opérations sur les adresses *)
    | Padd -> 
	let ofs = pop_int () in
	(match pop_value () with
	   | StackA a -> push (StackA (a + ofs))
	   | HeapA (a, n) -> push (HeapA (a, n + ofs))
	   | _ -> raise IllegalOperand)
  (* opération sur les chaînes *)
    | Concat ->
	let a1 = pop_string_a () in
	let a2 = pop_string_a () in
	let s = alloc_string (a1.str_it ^ a2.str_it) in
	push (StringA s)
  (* opérations sur le tas *)
    | Alloc n -> 
	let a = alloc_bloc n in push (HeapA (a, 0))
    | Allocn -> 
	let n = pop_int () in let a = alloc_bloc n in push (HeapA (a,0))
    | Free -> 
	let a = pop_heap_a () in free_bloc a
  (* égalité *)
    | Equal ->
	let b = match pop_value (), pop_value () with
	  | Int a, Int b
	  | StackA a, StackA b 
	  | CodeA a, CodeA b -> a = b
	  | HeapA (a,oa), HeapA (b,ob) -> a = b && oa = ob
	  | Float a, Float b -> a = b
	  | StringA a, StringA b -> a == b
	  | _ -> false
	in
	push (Int (if b then 1 else 0))

    | Inf | Sup | Infeq | Supeq -> 
	let comp = fun x y -> match inst with 
	  | Inf -> x < y
	  | Sup -> x > y
	  | Infeq -> x <= y
	  | Supeq -> x >= y
	  | _ -> assert false
	in
	let b = match pop_value (), pop_value () with
	  | Int a, Int b -> comp b a
	  | Float a, Float b -> comp b a
	  | StringA a, StringA b -> comp b.str_it a.str_it
	  | _ -> raise IllegalOperand
	in
	push (Int (if b then 1 else 0))

    | Is_addr ->
	(match pop_value () with
	   | StackA _ | HeapA _ -> push (Int 1)
	   | _ -> push (Int 0))
  (* conversions *)
    | Atoi ->
	let a = pop_string_a () in push (Int (int_of_string a.str_it))
    | Atof ->
	let a = pop_string_a () in push (Float (float_of_string a.str_it))
    | Itof ->
	let i = pop_int () in push (Float (float_of_int i))
    | Ftoi ->
	let f = pop_float () in push (Int (int_of_float f))
    | Stri ->
	let i = pop_int () in push (StringA (alloc_string (string_of_int i)))
    | Strf ->
	let f = pop_float () in 
	push (StringA (alloc_string (string_of_float f)))
  (* empiler *)
    | Pushi i -> push (Int i)
    | Pushn n -> for i = 1 to n do push (Int 0) done
    | Pushf f -> push (Float f)
    | Pushs s -> push (StringA s)
    | Pushg i -> push (gp i)
    | Pushl i -> push (fp i)
    | Pushsp -> push (StackA vm.sp)
    | Pushfp -> push (StackA vm.fp)
    | Pushgp -> push (StackA vm.gp)
    | Load n -> 
	(match pop_value () with
	   | StackA a -> push vm.stack.(offset a n)
	   | HeapA  (a, ofs) -> push (get_field a (n + ofs))
	   | _ -> raise IllegalOperand)
    | Loadn -> 
	let n = pop_int () in
	(match pop_value () with
	   | StackA a -> push vm.stack.(offset a n)
	   | HeapA  (a, ofs) -> push (get_field a (n + ofs))
	   | _ -> raise IllegalOperand)
    | Dup n ->
	if vm.sp < n || vm.sp + n >= Array.length vm.stack then 
	  raise SegmentationFault;
	Array.blit vm.stack (vm.sp - n) vm.stack vm.sp n;
	vm.sp <- vm.sp + n
    | Dupn ->
	let n = pop_int () in
	if vm.sp < n || vm.sp + n >= Array.length vm.stack then 
	  raise SegmentationFault;
	Array.blit vm.stack (vm.sp - n) vm.stack vm.sp n;
	vm.sp <- vm.sp + n
  (* dépiler *)
    | Pop n ->
	for i = 1 to n do ignore (pop (fun _ -> ()) ()) done
    | Popn ->
	let n = pop_int () in
	for i = 1 to n do ignore (pop (fun _ -> ()) ()) done
  (* stocker *)
    | Storel n ->
	let v = pop_value () in
	let a = offset vm.fp n in
	vm.stack.(a) <- v
    | Storeg n ->
	let v = pop_value () in
	let a = offset vm.gp n in
	vm.stack.(a) <- v
    | Store n ->
	let v = pop_value () in
	let a = pop_value () in
	(match a with
	   | StackA a -> let a = offset a n in vm.stack.(a) <- v
	   | HeapA  (a, ofs) -> set_field a (n + ofs) v
	   | _ -> raise IllegalOperand)
    | Storen ->
	let v = pop_value () in
	let n = pop_int () in
	let a = pop_value () in
	(match a with
	   | StackA a -> let a = offset a n in vm.stack.(a) <- v
	   | HeapA  (a, ofs) -> set_field a (n + ofs) v
	   | _ -> raise IllegalOperand)
  (* divers *)
    | Check (n,p) ->
	let i = pop_int () in
	if i < n || i > p then raise IllegalOperand
    | Swap -> 
	let n = pop_value () in 
	let m = pop_value () in
	push n; 
	push m
  (* entrées-sorties *)
    | Writei ->	
	let n = pop_int () in 
	if not !silent then !write_string (string_of_int n)
    | Writef ->	
	let f = pop_float () in 
	if not !silent then !write_string (string_of_float f)
    | Writes -> 
	let a = pop_string_a () in 
	if not !silent then !write_string a.str_it
    | Read ->
	let s = !input_string () in
	push (StringA (alloc_string s))
  (* primitives graphiques *) 
    | DrawLine -> 
	let y2 = pop_int () in
	let x2 = pop_int () in 
	let y1 = pop_int () in
	let x1 = pop_int () in 
	if not !silent then !draw_line x1 y1 x2 y2
    | DrawPoint ->
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !draw_point x y    
    | DrawCircle ->
	let r = pop_int () in
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !draw_circle x y r
    | DrawRect ->
	let h = pop_int () in
	let w = pop_int () in
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !draw_rect x y w h
    | FillRect ->
	let h = pop_int () in
	let w = pop_int () in
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !fill_rect x y w h
    | SetColor ->
	let z = pop_int () in
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !set_color x y z
    | ClearDrawingArea -> 
	if not !silent then !clear_drawing_area ()
    | OpenDrawingArea -> 
	let y = pop_int () in
	let x = pop_int () in 
	if not !silent then !open_drawing_area x y
    | GetMouse ->
	if not !silent then 
	  let x,y = !get_mouse () in
	  push (Int x);
	  push (Int y)
    | Refresh -> !refresh ()
  (* primitives labyrinthe *)
    | Get -> push (Int (Maze.get()))
    | Set -> let n = pop_int () in Maze.set n
    | Move -> let b = Maze.move () in push (Int (if b then 1 else 0))
    | TurnLeft -> Maze.turn_left ()
    | TurnRight -> Maze.turn_right ()
  (* modification du PC *)
    | Jump l ->
	vm.pc <- l.address
    | Jz l ->
	let n = pop_int () in
	if n = 0 then vm.pc <- l.address
    | Pusha l ->
	push (CodeA l.address)
  (* appels *)
    | Call ->
	(match pop_value () with
	   | CodeA a ->
	       push_call (vm.pc, vm.fp);
	       vm.fp <- vm.sp;
	       vm.pc <- a
	   | _ -> raise IllegalOperand)
    | Return ->
	vm.sp <- vm.fp;
	let (pc,fp) = pop_call () in
	vm.pc <- pc;
	vm.fp <- fp
  (* initialisation et fin *)
    | Stop -> raise Exit
    | Nop -> ()
    | Start -> vm.fp <- vm.sp
    | Err s -> raise (Error s)
  (* absurde *)
    | Label _ -> assert false

(* exécution jusqu'à [Stop] ou jusqu'à la première exception *)
	
let run () = try while true do step () done with Exit -> ()

(* écriture/lecture de l'état de la machine sur le disque *)

let save f =
  let c = open_out f in
  output_value c vm;
  close_out c

let load f =
  let c = open_in f in
  let v = input_value c in
  close_in c;
  vm.code <- v.code;
  vm.stack <- v.stack;
  vm.sp <- v.sp;
  vm.fp <- v.fp;
  vm.gp <- v.gp;
  vm.pc <- v.pc;
  vm.strings <- v.strings;
  vm.heap <- v.heap;
  vm.call_sp <- v.call_sp;
  vm.calls <- v.calls

(* pretty-print *)

open Format

let show_element fmt = function
  | Int i -> fprintf fmt "Int %d" i
  | Float f -> fprintf fmt "Float %f" f
  | StringA a -> fprintf fmt "StringA %d" a.str_adr
  | StackA a -> fprintf fmt "StackA %d" a
  | CodeA a -> fprintf fmt "CodeA %d" a
  | HeapA (a,ofs) -> fprintf fmt "HeapA %d(%d)" a ofs

let show_stack fmt n =
  fprintf fmt "@[";
  for i = vm.sp - 1 downto max 0 (vm.sp - n) do
    fprintf fmt "[%a]" show_element vm.stack.(i)
  done;
  fprintf fmt "@]@?"

let string_of_element = Util.print_to_string show_element
