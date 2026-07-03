
let activated = ref false

(* current position *)
let x = ref 0
let y = ref 0

type dir = North | West | South | East
let dir = ref North

let w = 100
let h1 = 10 (* sandbox height *)
let h2 = 40 (* maze height *)
let h = h1+h2

let north = 1
let west = 2
let south = 4
let east = 8
let closed = north lor west lor south lor east
let u_north = 15 lxor north
let u_west = 15 lxor west
let u_south = 15 lxor south
let u_east = 15 lxor east

let walls = ref [||]
let values = ref [||]

let get_wall i j = !walls.(i).(j)
let set_wall i j w = !walls.(i).(j) <- w
let get_val i j = !values.(i).(j)
let set_val i j v = !values.(i).(j) <- v

let print_dir fmt = function
  | North -> Format.fprintf fmt "north"
  | South -> Format.fprintf fmt "south"
  | West -> Format.fprintf fmt "west"
  | East -> Format.fprintf fmt "east"

(* makes a door in room (i,j) towards direction d *)
let make_door i j d =
  let remove i j u = let w = get_wall i j in set_wall i j (w land u) in
  match d with
  | North -> assert (j < h-1); remove i j u_north; remove i (j+1) u_south
  | West -> assert (i > 0); remove i j u_west; remove (i-1) j u_east
  | South -> assert (j > 0); remove i j u_south; remove i (j-1) u_north
  | East -> assert (i < w-1); remove i j u_east; remove (i+1) j u_west

let make_door_2 (i,j) (i',j') =
  if i = i' then
    if j' = j+1 then make_door i j North
    else if j' = j-1 then make_door i j South
    else assert false
  else if j = j' then 
    if i' = i+1 then make_door i j East
    else if i' = i-1 then make_door i j West
    else assert false

let is_wall i j d =
  let w = get_wall i j in
  let mask = match d with 
    | North -> north | South -> south | West -> west | East -> east
  in
  (w land mask) <> 0

module Cell = struct type t = int * int let compare = compare end
module Visited = Set.Make(Cell)

let in_maze (i,j) = i >= 0 && i < w && j >= h1 && j < h

let random_neighbor visited (x, y) =
  let aux choices cell =
    let unvisited = not (Visited.mem cell visited) in
    if unvisited && in_maze cell then cell :: choices else choices 
  in
  let choices = List.fold_left aux [] [x-1, y; x+1, y; x, y-1; x, y+1] in
  if choices = [] 
  then None 
  else Some (List.nth choices (Random.int (List.length choices)))

let make_maze () =
  let rec visit visited stack cell =
    let visited = Visited.add cell visited in
    match random_neighbor visited cell with
      | Some neighbor ->
          make_door_2 cell neighbor;
          visit visited (cell :: stack) neighbor
      | _ ->
          match stack with
            | [] -> ()
            | cell :: stack -> visit visited stack cell 
  in
  visit Visited.empty [] (0,h1)

(* debug *)
(***
open Graphics
let display () =
  open_graph " 800x400";
  let line x1 y1 x2 y2 = moveto x1 y1; lineto x2 y2 in
  for i = 0 to w-1 do
    for j = 0 to h-1 do
      let x = 8*i in
      let y = 8*j in
      if is_wall i j North then line x (y+7) (x+7) (y+7);
      if is_wall i j West then line x y x (y+7);
      if is_wall i j South then line x y (x+7) y;
      if is_wall i j East then line (x+7) y (x+7) (y+7)
    done
  done;
  ignore (read_key ())
***)

let initialize () =
  activated := true;
  Random.init 123;
  walls := Array.create_matrix w h closed;
  values := Array.init w (fun i -> Array.init h (fun _ -> Random.int 256));
  (* clear the sandbox *)
  for i = 0 to w-1 do
    for j = 0 to h1-1 do
      if j <> h1-1 then make_door i j North; 
      if i <> w-1 then make_door i j East;
      if j <> 0 then make_door i j South;
      if i <> 0 then make_door i j West
    done
  done;
  make_maze ();
  make_door 0 (h1-1) North
  (* display () *)

let get () = get_val !x !y
let set n = 
  (*Format.eprintf "vm.set (%d,%d) <- %d@." !x !y n;*)
  set_val !x !y n
let move () = 
  not (is_wall !x !y !dir) &&
  (begin match !dir with
    | North -> incr y
    | South -> decr y
    | West -> decr x
    | East -> incr x
   end; true)

let turn_left () = dir := match !dir with
  | North -> West
  | West -> South
  | South -> East
  | East -> North

let turn_right () = dir := match !dir with
  | North -> East
  | East -> South
  | South -> West
  | West -> North

open Format

let get () = 
  if !activated then get () else begin printf "(no maze)get@."; 0 end
let set n = 
  if !activated then set n else printf "(no maze)set %d@." n
let move () = 
  if !activated then move () else begin printf "(no maze)move@."; true end
let turn_left () = 
  if !activated then turn_left () else printf "(no maze)turnleft@."
let turn_right () = 
  if !activated then turn_right () else printf "(no maze)turnright@."
