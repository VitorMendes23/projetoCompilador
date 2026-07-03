
open Label
open Hstring
open Instr

exception SyntaxError of int

let from_channel cin =
  Hstring.clear ();
  Label.clear ();
  let lb = Lexing.from_channel cin in
  try
    Code_parser.main Code_lexer.token lb
  with Parsing.Parse_error ->
    raise (SyntaxError (Lexing.lexeme_start lb))

let from_file f =
  let cin = open_in f in
  let c = from_channel cin in
  close_in cin;
  c

let compile c =
  (* une table pour conserver tous les labels que l'on croise *)
  let labels = Hashtbl.create 97 in
  let add_label = function
    | Jump l | Jz l | Pusha l -> Hashtbl.add labels l ()
    | _ -> ()
  in
  (* première passe: calcule la longeur du code *)
  let n = List.fold_left (fun i -> function Label _,_ -> i | _ -> i + 1) 0 c 
  in
  (* seconde passe: met le code dans un tableau *)
  let a = Array.create n Nop in
  let pc = ref 0 in
  List.iter 
    (function
       | Label l,_ -> l.address <- !pc
       | i,_ -> a.(!pc) <- i; incr pc; add_label i)
    c;
  (* on vérifie que tous les labels ont bien été définis *)
  let check_label l = 
    if l.address = -1 then failwith ("undefined label " ^ l.symbolic) 
  in
  Hashtbl.iter (fun l _ -> check_label l) labels;
  a

let load_and_compile f = compile (from_file f)

open Format

let print_label fmt l = 
  if l.address = -1 then
    fprintf fmt "%s" l.symbolic
  else
    fprintf fmt "%s (%d)" l.symbolic l.address

let print_com fmt = function
  | Some s -> fprintf fmt " // %s" s
  | None -> ()

let print_instr' fmt = function
  | Add -> fprintf fmt "add"
  | Sub -> fprintf fmt "sub"
  | Mul -> fprintf fmt "mul"
  | Div -> fprintf fmt "div"
  | Mod -> fprintf fmt "mod"
  | Not -> fprintf fmt "not"
  | Inf -> fprintf fmt "inf"
  | Infeq -> fprintf fmt "infeq"
  | Sup -> fprintf fmt "sup"
  | Supeq -> fprintf fmt "supeq"
  | Irandom -> fprintf fmt "irandom"
  (* opérations sur les réels *)
  | Fsqrt -> fprintf fmt "fsqrt"
  | Fadd -> fprintf fmt "fadd"
  | Fsub -> fprintf fmt "fsub"
  | Fmul -> fprintf fmt "fmul"
  | Fdiv -> fprintf fmt "fdiv"
  | Fcos -> fprintf fmt "fcos"
  | Fsin -> fprintf fmt "fsin"
  | Frandom -> fprintf fmt "frandom"
  (* opérations sur les adresses *)
  | Padd -> fprintf fmt "padd"
  (* opération sur les chaînes *)
  | Concat -> fprintf fmt "concat"
  (* opérations sur le tas *)
  | Alloc n -> fprintf fmt "alloc %d" n
  | Allocn -> fprintf fmt "allocn"
  | Free -> fprintf fmt "free"
  (* égalité *)
  | Equal -> fprintf fmt "equal"
  | Is_addr -> fprintf fmt "isaddr"
  (* conversions *)
  | Atoi -> fprintf fmt "atoi"
  | Atof -> fprintf fmt "atof"
  | Itof -> fprintf fmt "itof"
  | Ftoi -> fprintf fmt "ftoi"
  | Stri -> fprintf fmt "stri"
  | Strf -> fprintf fmt "strf"
  (* empiler *)
  | Pushi i -> fprintf fmt "pushi %d" i
  | Pushn i -> fprintf fmt "pushn %d" i
  | Pushf f -> fprintf fmt "pushf %f" f
  | Pushs s -> fprintf fmt "pushs \"%s\"" s.str_it
  | Pushg i -> fprintf fmt "pushg %d" i
  | Pushl i -> fprintf fmt "pushl %d" i
  | Pushsp -> fprintf fmt "pushsp"
  | Pushfp -> fprintf fmt "pushfp"
  | Pushgp -> fprintf fmt "pushgp"
  | Load i -> fprintf fmt "load %d" i
  | Loadn -> fprintf fmt "loadn"
  | Dup i -> fprintf fmt "dup %d" i
  | Dupn -> fprintf fmt "dupn"
  (* dépiler *)
  | Pop i -> fprintf fmt "pop %d" i
  | Popn -> fprintf fmt "popn"
  (* Stocker *)
  | Storel i -> fprintf fmt "storel %d" i
  | Storeg i -> fprintf fmt "storeg %d" i
  | Store i -> fprintf fmt "store %d" i
  | Storen -> fprintf fmt "storen" 
  (* divers *)
  | Check (i,j) -> fprintf fmt "check %d, %d" i j
  | Swap -> fprintf fmt "swap"
  (* entrées-sorties *)
  | Writei -> fprintf fmt "writei"
  | Writef -> fprintf fmt "writef"
  | Writes -> fprintf fmt "writes"
  | Read -> fprintf fmt "read"
  (* primitives graphiques *)
  | DrawLine -> fprintf fmt "drawline"
  | DrawPoint -> fprintf fmt "drawpoint"
  | DrawCircle ->  fprintf fmt "drawcircle"
  | DrawRect ->  fprintf fmt "drawrect"
  | FillRect ->  fprintf fmt "fillrect"
  | SetColor ->  fprintf fmt "setcolor"
  | ClearDrawingArea -> fprintf fmt "cleardrawingarea"
  | OpenDrawingArea ->  fprintf fmt "opendrawingarea"
  | GetMouse -> fprintf fmt "getmouse"
  | Refresh ->  fprintf fmt "refresh"
  (* labyrinthe *)
  | Get -> fprintf fmt "get"
  | Set -> fprintf fmt "set"
  | Move -> fprintf fmt "move"
  | TurnLeft -> fprintf fmt "turnleft"
  | TurnRight -> fprintf fmt "turnright"
  (* sauts *)
  | Label _ -> ()
  | Jump l -> fprintf fmt "jump %a" print_label l
  | Jz l -> fprintf fmt "jz %a" print_label l
  | Pusha l -> fprintf fmt "pusha %a" print_label l
  (* procédures *)
  | Call -> fprintf fmt "call"
  | Return -> fprintf fmt "return"
  (* initialisation *)
  | Start -> fprintf fmt "start"
  | Nop -> fprintf fmt "nop"
  | Err s -> fprintf fmt "err \"%s\"" s
  | Stop -> fprintf fmt "stop"

let print_instr fmt (i,c) = print_instr' fmt i ; print_com fmt c 

type symbolic = (Instr.t*string option) list

type compiled = Instr.t array

let print_i fmt = function
  | Label l,_ when l.address = -1 -> fprintf fmt "%s:\n" l.symbolic
  | Label l,_ -> fprintf fmt "%s: // %d\n" l.symbolic l.address
  | i -> fprintf fmt "\t%a\n" print_instr i

let print_list fmt c =
  fprintf fmt "@["; List.iter (print_i fmt) c; fprintf fmt "@]@?"

let print_array fmt c =
  fprintf fmt "@["; Array.iter (print_i fmt) c; fprintf fmt "@]@?"

let string_of_instr = Util.print_to_string print_instr
