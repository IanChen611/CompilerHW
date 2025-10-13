let l = List.init 1_000_001 (fun i -> i)

let rev lst =
  let rec aux acc = function
    | [] -> acc
    | x :: xs -> aux (x :: acc) xs
  in
  aux [] lst

let map f lst =
  let rec aux acc = function
    | [] -> List.rev acc
    | x :: xs -> aux (f x :: acc) xs
  in
  aux [] lst



let l = List.init 1_000_001 (fun i -> i)

let () =
  let l_rev = rev l in
  let l_double = map (fun x -> x * 2) l in
  Printf.printf "First 5 of reversed: ";
  List.iteri (fun i x -> if i < 5 then Printf.printf "%d " x) l_rev;
  print_newline ();
  Printf.printf "First 5 of doubled: ";
  List.iteri (fun i x -> if i < 5 then Printf.printf "%d " x) l_double;
  print_newline ();
