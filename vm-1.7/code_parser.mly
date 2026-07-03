%{
  open Instr
%}               

%token <string> IDENT
%token <int> INT
%token <float> FLOAT
%token <string> STRING
%token <Instr.t> INSTR 
%token PUSHI PUSHN PUSHF PUSHS PUSHG PUSHL LOAD DUP POP STOREL STOREG
%token STORE CHECK LABEL JUMP JZ PUSHA ERR ALLOC
%token COLON EOF COMMA
%token <string> COMMENT

%start main
%type <(Instr.t*string option) list> main
%%

main:
  | EOF                 { [] }
  | instrs EOF	        { $1 }
  | comms instrs EOF    { $2 }
;

instrs:
  | instr_com instrs        { $1 :: $2 }
  | instr_com               { [ $1 ] }
;

instr_com:
  | instr comms {$1,Some $2}
  | instr {$1,None}
;

comms:
  | COMMENT comms {$1}
  | COMMENT       {$1}

instr:
  | IDENT COLON   { Label (Label.create $1) }
  | INSTR         { $1 }
  | PUSHI INT     { Pushi $2 }
  | PUSHN INT     { Pushn $2 }
  | PUSHF FLOAT   { Pushf $2 }
  | PUSHS STRING  { Pushs (Hstring.create $2) }
  | PUSHG INT     { Pushg $2 }
  | PUSHL INT     { Pushl $2 }
  | LOAD INT      { Load $2 }
  | DUP INT       { Dup $2 }
  | POP INT       { Pop $2 }
  | STOREL INT    { Storel $2 }
  | STOREG INT    { Storeg $2 }
  | STORE INT     { Store $2 } 
  | CHECK INT COMMA INT { Check ($2, $4) }
  | JUMP IDENT    { Jump (Label.create $2) }
  | JZ IDENT      { Jz (Label.create $2) }
  | PUSHA IDENT   { Pusha (Label.create $2) }
  | ERR STRING    { Err $2 }
  | ALLOC INT     { Alloc $2 }
;

