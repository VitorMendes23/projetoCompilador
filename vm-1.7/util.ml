
open Format

let print_to_string f x =
  let b = Buffer.create 1024 in
  Buffer.clear b;
  let fmt = formatter_of_buffer b in
  fprintf fmt "%a" f x;
  pp_print_flush fmt ();
  Buffer.contents b
