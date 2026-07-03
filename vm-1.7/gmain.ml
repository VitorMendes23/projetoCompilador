
(* interface graphique *)

open Printf
open Label
open Hstring
open Instr
open Code
open Vm
open Gobject.Data
open GtkTree
open Arg

let file = ref None

let _ = printf "VM version %s\n" Version.version; flush stdout

let () = 
  Arg.parse 
    ["-ssize", Int Vm.set_stack_size, 
        "<int>  set stack size (def. 10000)";
     "-csize", Int Vm.set_call_stack_size, 
        "<int>  set call stack size (def 100)";
     "-version", Unit (fun () -> exit 0),
       "  print version number and exit";
     "-maze", Unit Maze.initialize, 
       "activate the maze";
    ]
    (fun f -> file := Some f)
    "usage: gvm [options] [file]"

let _ = GMain.Main.init ()

let _ = Glib.Main.setlocale `NUMERIC (Some "C")


let width = 800
let height = 600
let window = GWindow.window ~width ~height ()

let _ = window#connect#destroy ~callback:(fun () -> exit 0)

let vbox = GPack.vbox ~packing:window#add ()

let menubar = GMenu.menu_bar ~packing:vbox#pack ()

let machine = GPack.vbox ~packing:vbox#add ()

let couleur_fond = ref `WHITE

let create_graphic_window width height = 
  let graphicwindow = GWindow.window 
      ~title:"Graphic Output"
      ~allow_shrink:false
      ~allow_grow:false
      ~width:width 
      ~height:height ()
  in
  (* (ignore (graphicwindow#event#connect#delete ~callback:(fun _ ->  true)));*)
  let area =  GMisc.drawing_area ~height:(height) ~packing:graphicwindow#add () in
  let w = area#misc#realize (); area#misc#window in
  let drawing = new GDraw.drawable w in
  let pixmap = GDraw.pixmap width height () in
  let affiche_buffer () = drawing#put_pixmap ~x:0 ~y:0 pixmap#pixmap in
  
  let clear_drawing_area () =
    (* on efface le buffer *)
    pixmap#set_foreground !couleur_fond;
    pixmap#rectangle ~x:0 ~y:0
      ~width:width ~height:height ~filled:true ();
    pixmap#set_foreground `BLACK;
  in
  
  clear_drawing_area ();
  let expose_event _ = affiche_buffer();false in
  ignore (area#event#connect#expose ~callback:expose_event);

  let draw_point x y = pixmap#point x y in
  let draw_line x y z t = pixmap#line ~x:x ~y:y ~x:z ~y:t in
  let draw_circle x y r = 
    let d = 2*r in
    pixmap#arc ~x:(x-r) ~y:(y-r) ~width:d ~height:d () in
  let draw_rect x y w h =
    pixmap#rectangle ~x ~y ~width:w ~height:h ~filled:false ()
  in
  let fill_rect x y w h =
    pixmap#rectangle ~x ~y ~width:w ~height:h ~filled:true ()
  in
  let set_color x y z = pixmap#set_foreground (`RGB(x,y,z)) in
  let get_mouse () = area#misc#pointer in
  Vm.draw_line := draw_line;
  Vm.draw_point := draw_point;
  Vm.draw_circle := draw_circle;
  Vm.draw_rect := draw_rect;
  Vm.fill_rect := fill_rect;
  Vm.set_color := set_color; 
  Vm.clear_drawing_area := clear_drawing_area;
  Vm.refresh := affiche_buffer;
  Vm.get_mouse := get_mouse;
  graphicwindow#show ()


let hp1 = GPack.paned `HORIZONTAL 
	  ~packing:(machine#pack ~fill:true ~expand:true) ()
let _ = hp1#misc#connect#realize 
        ~callback:(fun _ -> hp1#set_position (width/2))
let sw1 = GBin.scrolled_window ~packing:hp1#add1 
	  ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ()

let hp2 = GPack.paned `HORIZONTAL ~packing:hp1#add2 ()
let _ = hp2#misc#connect#realize 
        ~callback:(fun _ -> hp2#set_position (width * 1 / 6))
let sw2 = GBin.scrolled_window ~packing:hp2#add1 
	  ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ()

let hp3 = GPack.paned `HORIZONTAL ~packing:hp2#add2 ()
let _ = hp3#misc#connect#realize 
        ~callback:(fun _ -> hp3#set_position (width * 1 / 6))
let sw3 = GBin.scrolled_window ~packing:hp3#add1 
	  ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ()

let vp = GPack.paned `VERTICAL ~packing:hp3#add2 ()
let _ = vp#misc#connect#realize 
        ~callback:(fun _ -> vp#set_position (height/2))
let sw4 = GBin.scrolled_window ~packing:vp#add1
	  ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ()

let sw5 = GBin.scrolled_window ~packing:vp#add2
	  ~hpolicy:`AUTOMATIC ~vpolicy:`AUTOMATIC ()

let hbox = GPack.hbox ~packing:vbox#pack ()

let status_bar = 
  GMisc.statusbar ~packing:(hbox#pack  ~fill:true ~expand:true) ()

let label = GMisc.label ~text:"..." ~packing:hbox#pack ()

let flash_info =
  let flash_context = status_bar#new_context "Flash" in
  ignore (flash_context#push "Ready");
  fun s -> ignore (flash_context#pop ()); ignore (flash_context#push s)

let path_of_int i = 
  GtkTree.TreePath.from_string (string_of_int (if i < 0 then 0 else i))

(* code *)
let code_model, set_code, refresh_code, code_view = 
  let cols = new GTree.column_list in
  let pc_col = cols#add string in
  let instr_col = cols#add string in
  let model = GTree.tree_store cols in
  let adr = ref [||] in
  let set_code code =
    adr := Array.create (1 + Array.length vm.code) 0;
    let adr = !adr in
    model#clear ();
    let pc = ref 0 in
    let count = ref (-1) in
    List.iter 
      (fun i -> 
	 incr count;
	 let row = model#append () in
	 match i with
	   | Label l,_ -> 
	       model#set ~row ~column:pc_col l.symbolic
	   | i -> 
	       model#set ~row ~column:pc_col (string_of_int !pc);
	       model#set ~row ~column:instr_col (string_of_instr i);
	       adr.(!pc) <- !count;
	       incr pc)
      code;
    adr.(!pc) <- !count + 1;
    ignore (model#append ())
  in
  let view = GTree.view ~model ~packing:sw1#add () in
  view#set_rules_hint true;
  view#selection#set_mode `SINGLE;
  let refresh () =
    let i = !adr.(vm.pc) in
    (* patch Avenel *)
    let path = path_of_int i in
    let h= sw1#vadjustment#page_size in
    if h <> 0. then begin
      let pathofpos_end = view#get_path_at_pos 1 (int_of_float h) in
      let pathofpos_first = view#get_path_at_pos 1 1 in
      match (pathofpos_first, pathofpos_end) with
	| (Some (first_path,_,_,_), Some (last_path,_,_,_)) -> 
	    let min = int_of_string (GtkTree.TreePath.to_string first_path) in
	    let max = int_of_string (GtkTree.TreePath.to_string last_path) in
	    if (i <= min || i >= max) then
	      view#scroll_to_cell ~align:(0.1,0.0) path (view#get_column 1)
	| (Some (first_path,_,_,_), _) -> 
	    let min = int_of_string (GtkTree.TreePath.to_string first_path) in
	    if (i <= min) then
	      view#scroll_to_cell ~align:(0.1,0.0) path (view#get_column 1)
	| _ -> ()
    end;
    (***)
    view#selection#select_iter (model#get_iter (path_of_int i))
  in
  let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let _ = 
    view#append_column
      (GTree.view_column ~renderer:(renderer, ["text", pc_col])
	 ())
  in
  let _ = 
    view#append_column
      (GTree.view_column ~title:"code" 
                         ~renderer:(renderer, ["text", instr_col]) ())
  in
  model, set_code, refresh, view

(* pile *)
let stack_model, refresh_stack, stack_view = 
  let cols = new GTree.column_list in
  let i_col = cols#add string in
  let elt_col = cols#add string in
  let stack_color_col = cols#add string in
  let model = GTree.tree_store cols in
  let display = Array.create (Array.length vm.stack) None in
  let display_n = ref 0 in
  let index i = !display_n - i - 1 in
  let grow_stack n =
    let new_n = min (2 * n) (Array.length vm.stack) in
    for i = !display_n to new_n - 1 do
      (*let elt = vm.stack.(i) in*)
      let row = model#prepend () in
      model#set ~row ~column:i_col (string_of_int i)
      (* model#set ~row ~column:elt_col (string_of_element elt); *)
    done;
    display_n := new_n
  in
  grow_stack (min 5 (Array.length vm.stack) - 1);
  let view = GTree.view ~model ~packing:sw2#add () in
  (* view#set_rules_hint true; *)
  view#selection#set_mode `NONE;
  let refresh_fp =
    let old = ref 0 in
    fun p -> 
      let row = model#get_iter (path_of_int (index !old)) in
      model#set ~row ~column:stack_color_col "white";
      let path = path_of_int (index p) in
      let row = model#get_iter path in
      model#set ~row ~column:stack_color_col "light green";
      old := p;
      path
  in
  let refresh_pointers () =
    ignore (refresh_fp vm.fp);
    let path = path_of_int (index vm.sp) in
    view#scroll_to_cell ~align:(0.1,0.0) path (view#get_column 1)
  in
  let refresh () =
    Array.iteri
      (fun i e -> 
	 let e' = if i >= vm.sp then None else Some e in
	 if e' != display.(i) then begin
	   if i >= !display_n then grow_stack i;
	   let row = model#get_iter (path_of_int (index i)) in
	   let s = if i >= vm.sp then "" else string_of_element e in
	   model#set ~row ~column:elt_col s;
	   display.(i) <- e'
	 end)
      vm.stack;
    refresh_pointers ()
  in
  let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let _ = 
    view#append_column
      (GTree.view_column ~renderer:(renderer, ["text", i_col]) ())
  in
  let stack_renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let stack_column = 
    GTree.view_column 
      ~title:"stack" 
      ~renderer:(stack_renderer, ["text", elt_col]) 
      ()
  in
  let () = 
    stack_column#add_attribute stack_renderer "background" stack_color_col
  in
  let _ = view#append_column stack_column in
  refresh_pointers ();
  model, refresh, view

(* tas *)
let heap_model, refresh_heap, reset_heap, heap_view = 
  let cols = new GTree.column_list in
  let col = cols#add string in
  let model = GTree.tree_store cols in
  (* la table [where] associe à chaque adresse la ligne où elle est affichée
     et le bloc actuellement affiché *)
  let where = Hashtbl.create 97 in
  let add_heap a bl =
    let row_a = model#append () in
    model#set ~row:row_a ~column:col ("@" ^ string_of_int a);
    let bl0 = 
      Array.map
	(fun elt ->
	   let row = model#append ~parent:row_a () in
	   model#set ~row ~column:col (string_of_element elt);
	   elt, row)
	bl
    in
    Hashtbl.add where a (row_a, bl0)
  in
  let refresh () =
    IntMap.iter
      (fun a bl -> 
	 try
	   let r,bl0 = Hashtbl.find where a in
	   Array.iteri 
	     (fun i (e0,r) -> 
		let e = bl.(i) in 
		if e != e0 then begin
		  bl0.(i) <- (e,r);
		  model#set ~row:r ~column:col (string_of_element e)
		end) 
	     bl0
	 with Not_found ->
	   add_heap a bl
      )
      vm.heap
  in
  let reset () =
    model#clear ();
    Hashtbl.clear where
  in
  let view = GTree.view ~model ~packing:sw3#add () in
  view#set_rules_hint true;
  view#selection#set_mode `SINGLE;
  let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let _ = 
    view#append_column
      (GTree.view_column ~title:"heap" ~renderer:(renderer, ["text", col])
	 ())
  in
  model, refresh, reset, view

(* chaînes *)
let string_model, refresh_string, string_view = 
  let cols = new GTree.column_list in
  let adr_col = cols#add string in
  let str_col = cols#add string in
  let model = GTree.tree_store cols in
  let old = ref vm.strings in
  let refresh () =
    if vm.strings != !old then begin
      model#clear ();
      IntMap.iter
	(fun _ s ->
	   let row = model#append () in
	   model#set ~row ~column:adr_col ("@" ^ string_of_int s.str_adr);
	   model#set ~row ~column:str_col ("\"" ^ s.str_it ^ "\""))
	vm.strings;
      old := vm.strings
    end
  in
  let view = GTree.view ~model ~packing:sw4#add () in
  view#set_rules_hint true;
  view#selection#set_mode `SINGLE;
  let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let _ = 
    view#append_column
      (GTree.view_column ~renderer:(renderer, ["text", adr_col])
	 ())
  in
  let _ = 
    view#append_column
      (GTree.view_column ~title:"strings" 
                         ~renderer:(renderer, ["text", str_col]) ())
  in
  model, refresh, view

(* pile d'appels *)
let call_model, refresh_call_stack, call_view = 
  let cols = new GTree.column_list in
  let pc_col = cols#add string in
  let fp_col = cols#add string in
  let model = GTree.tree_store cols in
  let refresh () =
    model#clear ();
    for i = 0 to vm.call_sp - 1 do
      let (pc,fp) = vm.calls.(i) in
      let row = model#prepend () in
      model#set ~row ~column:pc_col ("@" ^ string_of_int pc);
      model#set ~row ~column:fp_col (string_of_int fp);
    done
  in
  let view = GTree.view ~model ~packing:sw5#add () in
  view#set_rules_hint true;
  view#selection#set_mode `SINGLE;
  let renderer = GTree.cell_renderer_text [`XALIGN 0.] in
  let _ = 
    view#append_column
      (GTree.view_column ~title:"pc" ~renderer:(renderer, ["text", pc_col]) ())
  in
  let _ = 
    view#append_column
      (GTree.view_column ~title:"fp" ~renderer:(renderer, ["text", fp_col]) ())
  in
  model, refresh, view




let refresh_all () =
  refresh_code ();
  refresh_stack ();
  refresh_heap ();
  refresh_call_stack ();
  refresh_string ();
  label#set_text 
    (sprintf "PC = %d SP = %d FP = %d GP = %d count = %d" 
       vm.pc vm.sp vm.fp vm.gp vm.count);
  while Glib.Main.pending () do ignore (Glib.Main.iteration false) done

let ready = ref true

let load_file f =
  let c = Code.from_file f in
  Vm.set_code (Code.compile c);
  set_code c; 
  flash_info "Ready";
  ready := true;
  refresh_all ()

let select_file () = match GToolbox.select_file ~title:"Load code" () with
  | None -> ()
  | Some f -> load_file f

let report = function
  | Exit -> "Program terminated"
  | e -> Printexc.to_string e

let do_step () =
  if !ready then begin
    begin 
      try
	Vm.step (); 
      with e ->
	ready := false;
	flash_info (report e)
    end;
    refresh_all ()
  end


let do_animate () = 
  if !ready then begin
    try
      while true do Vm.step (); refresh_all () done
    with e ->
      ready := false; flash_info (report e); refresh_all ()
  end

let do_run () = 
  if !ready then begin
    try
      while true do Vm.step () done
    with e ->
      ready := false; flash_info (report e); refresh_all ()
  end

let do_reset () = 
  Vm.reset (); 
  reset_heap ();   
  flash_info "Ready";
  ready := true;
(*  clear_drawing_area(); *)
  refresh_all ()

let with_code f () =
  if Array.length vm.code = 0 then flash_info "No code" else f ()

(* menu *)
let () =
  let factory = new GMenu.factory menubar in
  let accel_group = factory#accel_group in
  let file_menu = factory#add_submenu "File" in
  let file_factory = new GMenu.factory file_menu ~accel_group in
  let _ = file_factory#add_item "Load" ~key:GdkKeysyms._L 
	       ~callback:select_file in
  let _ = file_factory#add_item "Quit" ~key:GdkKeysyms._Q
	       ~callback:(fun () -> exit 0) in
  let exec_menu = factory#add_submenu "Exec" in
  let exec_factory = new GMenu.factory exec_menu ~accel_group in
  let _ = exec_factory#add_item "Reset" ~key:GdkKeysyms._Z
		~callback:(with_code do_reset) in
  let _ = exec_factory#add_item "Step" ~key:GdkKeysyms._S
	       ~callback:(with_code do_step) in
  let _ = exec_factory#add_item "Animate" ~key:GdkKeysyms._A
	       ~callback:(with_code do_animate) in
  let _ = exec_factory#add_item "Run" ~key:GdkKeysyms._R
	       ~callback:(with_code do_run) in
  window#add_accel_group accel_group


(* On change les fonctions d'interactions : on installe leur equivalent
graphique *)

let input_string () =
  let res = GToolbox.input_string ~title:"" "Read =>" in
  match res with None -> "" | Some s -> s
let () = Vm.input_string := input_string

let write_string s = flash_info (sprintf "Write => \"%s\"" s)
let () = Vm.write_string := write_string

let () = Vm.open_drawing_area := create_graphic_window 

let () = match !file with Some f -> load_file f | None -> ()

let () = window#show ()


let () = GMain.Main.main ()

