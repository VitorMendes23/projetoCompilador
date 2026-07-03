
(* Instructions pour la machine virtuelle *)

type t = 
  (* opérations sur les entiers *)
  | Add
  | Sub
  | Mul
  | Div
  | Mod
  | Not
  | Irandom
  (* opérations sur les réels *)
  | Fadd
  | Fsqrt
  | Fsub
  | Fmul
  | Fdiv
  | Fcos
  | Fsin
  | Frandom
  (* opérations sur les adresses *)
  | Padd
  (* opération sur les chaînes *)
  | Concat
  (* opérations sur le tas *)
  | Alloc of int
  | Allocn 
  | Free
  (* égalité *)
  | Equal
  | Is_addr
  (* comparaison *)
  | Inf
  | Infeq
  | Sup
  | Supeq
  (* conversions *)
  | Atoi
  | Atof
  | Itof
  | Ftoi
  | Stri
  | Strf
  (* empiler *)
  | Pushi of int
  | Pushn of int
  | Pushf of float
  | Pushs of Hstring.t
  | Pushg of int
  | Pushl of int
  | Pushsp
  | Pushfp
  | Pushgp
  | Load of int
  | Loadn
  | Dup of int
  | Dupn
  (* dépiler *)
  | Pop of int
  | Popn
  (* Stocker *)
  | Storel of int
  | Storeg of int
  | Store of int 
  | Storen 
  (* divers *)
  | Check of int * int
  | Swap
  (* entrées-sorties *)
  | Writei
  | Writef
  | Writes
  | Read
  (* primitives graphiques *)
  | DrawLine
  | DrawPoint
  | DrawCircle
  | DrawRect
  | FillRect
  | SetColor
  | OpenDrawingArea
  | ClearDrawingArea 
  | GetMouse
  | Refresh
  (* labyrinthe *)
  | Get
  | Set
  | Move
  | TurnLeft
  | TurnRight
  (* sauts *)
  | Label of Label.t
  | Jump of Label.t
  | Jz of Label.t
  | Pusha of Label.t
  (* procédures *)
  | Call
  | Return
  (* initialisation *)
  | Start
  | Nop
  | Err of string
  | Stop

