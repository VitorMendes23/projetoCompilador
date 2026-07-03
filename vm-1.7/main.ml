
(* machine virtuelle pour le cours de compilation *)

open Format
open Vm
open Arg

let file = ref None
let dump = ref false
let count = ref false

let _ = eprintf "VM version %s@." Version.version

let () = 
  Arg.parse 
    ["-dump", Set dump, 
       "  dump state when execution is finished";
     "-silent", Set Vm.silent,
       "  silent execution (nothing is printed)";
     "-ssize", Int Vm.set_stack_size, 
        "<int>  set stack size (def. 10000)";
     "-csize", Int Vm.set_call_stack_size, 
        "<int>  set call stack size (def 100)";
     "-count", Set count, 
       "  dump number of steps when execution is finished";
     "-version", Unit (fun () -> exit 0),
       "  print version number and exit";
     "-maze", Unit Maze.initialize, 
       "activate the maze"]
    (fun f -> file := Some f)
    "usage: vm [options] [file]"

let do_dump () =
  if !dump then begin
    eprintf "PC = %d SP = %d FP = %d GP = %d " vm.pc vm.sp vm.fp vm.gp;
    eprintf "Stack top = %a@." show_stack 1
  end;
  if !count then begin
    eprintf "%d steps@." Vm.vm.count
  end

let report = function
  | SegmentationFault -> "VM error: Segmentation Fault", 1
  | IllegalOperand -> "VM error: Illegal Operand", 1
  | StackOverflow  -> "VM error: Stack Overflow", 1
  | DivisionByZero -> "VM error: Division By Zero", 1
  | Error s -> "VM error: Error \"" ^ s ^ "\"", 1
  | Code_lexer.LexicalError n -> sprintf "lexical error at character %d" n, 1
  | Code.SyntaxError n -> sprintf "syntax error at character %d" n, 1
  | e -> "Anomaly: " ^ Printexc.to_string e, 2

let () = 
  begin try match !file with
    | None -> 
	let c = Code.from_channel stdin in
	let cc = Code.compile c in
	set_code cc;
    | Some f ->
	load_code f
  with
    | e -> 
	let m,c = report e in eprintf "%s@." m; exit c
  end;
  try
    run (); do_dump ()
  with e ->
    do_dump (); 
    let m,c = report e in eprintf "%s@." m; exit c
