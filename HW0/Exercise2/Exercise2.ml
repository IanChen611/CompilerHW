let size = 1 lsl 16
let table : (int * int) list array = Array.make size []

let hash k =
  (k lxor (k lsl 16) + 5003) land (size - 1)

let add k v =
  let i = hash k in
  table.(i) <- (k, v) :: table.(i)

let find k =
  let rec lookup = function
    | [] -> raise Not_found
    | (k', v) :: s -> if k' = k then v else lookup s
  in
  let i = hash k in
  lookup table.(i)

let rec fibo_raw n =
  if n <= 1 then n
  else memo_count (n - 1) + memo_count (n - 2)

and memo_count n =
  try find n
  with Not_found ->
    let v = fibo_raw n in
    add n v;
    v
    
let () =
  Printf.printf "fib(10) = %d\n" (memo_count 10);
