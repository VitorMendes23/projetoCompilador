
(* lexeur pour le code de la machine virtuelle *)

{
  open Printf
  open Lexing
  open Instr
  open Code_parser

  let string_buffer = Buffer.create 512

  exception LexicalError of int

  let keyword_list = [
    "add", INSTR Add; 
    "sub", INSTR Sub;
    "mul", INSTR Mul;
    "div", INSTR Div;
    "mod", INSTR Mod;
    "not", INSTR Not;
    "inf", INSTR Inf;
    "infeq", INSTR Infeq;
    "sup", INSTR Sup;
    "supeq", INSTR Supeq;
    "fadd", INSTR Fadd;
    "fsub", INSTR Fsub;
    "fmul", INSTR Fmul;
    "fdiv", INSTR Fdiv;
    "fcos", INSTR Fcos;
    "fsqrt", INSTR Fsqrt;
    "fsin", INSTR Fsin;
    "padd", INSTR Padd;
    "concat", INSTR Concat;
    "equal", INSTR Equal;
    "isaddr", INSTR Is_addr;
    "irandom" , INSTR Irandom;
    "frandom" , INSTR Frandom;
    "atoi", INSTR Atoi;
    "atof", INSTR Atof;
    "itof", INSTR Itof;
    "ftoi", INSTR Ftoi;
    "stri", INSTR Stri;
    "strf", INSTR Strf;
    "pushsp", INSTR Pushsp;
    "pushfp", INSTR Pushfp;
    "pushgp", INSTR Pushgp;
    "loadn", INSTR Loadn;
    "storen", INSTR Storen ; 
    "swap", INSTR Swap;
    "writei", INSTR Writei;
    "writef", INSTR Writef;
    "writes", INSTR Writes;
    "read", INSTR Read;
    "drawline", INSTR DrawLine;
    "drawpoint", INSTR DrawPoint;
    "drawcircle", INSTR DrawCircle;
    "drawrect", INSTR DrawRect;
    "fillrect", INSTR FillRect;
    "setcolor", INSTR SetColor;
    "cleardrawingarea", INSTR ClearDrawingArea;
    "opendrawingarea", INSTR OpenDrawingArea;
    "getmouse" , INSTR GetMouse;
    "refresh", INSTR Refresh;
    "call", INSTR Call;
    "return", INSTR Return;
    "start", INSTR Start;
    "nop", INSTR Nop;
    "stop", INSTR Stop; 
    "allocn", INSTR Allocn;
    "free", INSTR Free;
    "dupn", INSTR Dupn;
    "popn", INSTR Popn;
    (* maze *)
    "get", INSTR Get;
    "set", INSTR Set;
    "move", INSTR Move;
    "turnleft", INSTR TurnLeft;
    "turnright", INSTR TurnRight;
    (* instructions avec arguments *)
    "pushi", PUSHI;
    "pushn", PUSHN;
    "pushf", PUSHF;
    "pushs", PUSHS;
    "pushg", PUSHG;
    "pushl", PUSHL;
    "load", LOAD;
    "dup", DUP;
    "pop", POP;
    "storel", STOREL;
    "storeg", STOREG;
    "store", STORE;
    "check", CHECK;
    "label", LABEL;
    "jump", JUMP;
    "jz", JZ;
    "pusha", PUSHA;
    "err", ERR;
    "alloc", ALLOC;
 ]

  let keyword =
    let t = Hashtbl.create 73 in
    List.iter (fun (name,kwd) -> Hashtbl.add t name kwd) keyword_list;
    fun s -> 
      let ls = String.lowercase s in
      try Hashtbl.find t ls with Not_found -> IDENT s

}

let blank = [' ' '\n' '\t' '\r']
let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident_char = alpha | digit | '\'' | '_'
let ident = (alpha | '_') ident_char*
let integer = '-'? digit+
let float = '-'? digit+ ('.' digit* )? (['e' 'E'] ['+' '-']? digit+)?

rule token = parse
  | blank+		{ token lexbuf }
  | "//"([^ '\n']* as c){ COMMENT c }
  | ident               { let s = lexeme lexbuf in keyword s }
  | ":"                 { COLON }
  | ","                 { COMMA }
  | integer   	        { INT (int_of_string (lexeme lexbuf)) }
  | float               { FLOAT (float_of_string (lexeme lexbuf)) }
  | '"'
      { Buffer.clear string_buffer;
	string lexbuf;
	STRING (Buffer.contents string_buffer) }
  | eof			{ EOF }
  | _ { raise (LexicalError (lexeme_start lexbuf)) }


(* Lecture d'une chaîne de caractères *)

and string = parse
  | '"'
      { lexeme_end lexbuf }
  | '\\' 'n' 
      { Buffer.add_char string_buffer '\n';
	string lexbuf }
  | '\\' '\\' 
      { Buffer.add_char string_buffer '\\';
	string lexbuf }
  | '\\' '"' 
      { Buffer.add_char string_buffer '"';
	string lexbuf }
  | [^ '\\' '"' '\n']+ 
      { Buffer.add_string string_buffer (lexeme lexbuf);
	string lexbuf }
  | '\\' 
      { raise (LexicalError (lexeme_start lexbuf)) }
  | '\n' | eof
      { raise (LexicalError (lexeme_start lexbuf)) }


{

}
