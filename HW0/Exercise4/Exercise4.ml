let split arr =
  let n = Array.length arr in
  let mid = n lsr 1 in
  let left = Array.sub arr 0 mid in
  let right = Array.sub arr mid (n - mid) in
  (left, right)

let merge l r =
  let len_l = Array.length l in
  let len_r = Array.length r in
  let i = ref 0 in
  let j = ref 0 in
  let init =
    if len_l > 0 then l.(0)
    else r.(0) (* 這裡 len_r 必定 > 0，因為 merge 只在至少一邊非空時被呼叫 *)
  in
  let result = Array.make (len_l + len_r) init in
  while !i < len_l && !j < len_r do
    if l.(!i) <= r.(!j) then begin
      result.(!i + !j) <- l.(!i);
      incr i
    end else begin
      result.(!i + !j) <- r.(!j);
      incr j
    end
  done;
  while !i < len_l do
    result.(!i + !j) <- l.(!i);
    incr i
  done;
  while !j < len_r do
    result.(!i + !j) <- r.(!j);
    incr j
  done;
  result

let rec merge_sort arr =
  if Array.length arr < 2 then
    arr
  else
    let left, right = split arr in
    let l = merge_sort left in
    let r = merge_sort right in
    merge l r

(* 測試 *)
let arr = [|12; 11; 13; 5; 6; 7|]

let () =
  Printf.printf "arr : ";
  Array.iter (Printf.printf "%d ") arr;
  print_newline ();
  let sorted = merge_sort arr in
  Printf.printf "after sort arr : ";
  Array.iter (Printf.printf "%d ") sorted;
  print_newline ();
