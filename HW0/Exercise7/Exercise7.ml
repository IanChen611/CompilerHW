(*
  BigO過大
let rec concat l1 l2 = match l1 with
  | [] -> l2
  | x::xs -> x :: (concat xs l2)
*)

type 'a seq =
| Elt of 'a
| Seq of 'a seq * 'a seq

let (@@) x y = Seq(x, y)

exception Empty_seq

(* a 小題 *)

let fold_left_seq f acc s =
  (* 左→右逐元素累積，不展平成 list，也不會爆堆疊 *)
  let rec go acc stk node =
    match node with
    | Elt x ->
        let acc' = f acc x in
        (match stk with
         | [] -> acc'
         | t :: ts -> go acc' ts t)
    | Seq (l, r) ->
        (* 先處理左子樹，右子樹暫存到堆疊等會兒處理 *)
        go acc (r :: stk) l
  in
  go acc [] s

let fold_right_seq f s acc =
  (* 右→左逐元素累積 *)
  let rec go acc stk node =
    match node with
    | Elt x ->
        let acc' = f x acc in
        (match stk with
         | [] -> acc'
         | t :: ts -> go acc' ts t)
    | Seq (l, r) ->
        (* 先處理右子樹，左子樹暫存到堆疊等會兒處理 *)
        go acc (l :: stk) r
  in
  go acc [] s


let hd s = 
  let rec leftmost node = 
    match node with
    | Elt x -> x
    | Seq (l, r) -> leftmost l
  in
  leftmost s

let tl s = 
   (* 刪掉第一個元素，回傳剩餘序列。
     如果只有一個元素，就沒有「空序列」可表示，拋例外。 *)
  let rec drop_first stk node =
    match node with
     | Elt _ ->
        (* 把一路走下來堆疊到的右子樹接回去 *)
        let rec rejoin n = 
          match n with
            | []      -> raise Empty_seq
            | [x]     -> x
            | x :: xs -> Seq (x, rejoin xs)
        in
        rejoin (List.rev stk)
    | Seq (l, r) -> drop_first (r :: stk) l
  in
  drop_first [] s


let mem x s =
  fold_left_seq (fun acc y -> acc || y = x) false s

let rec rev s =
  match s with
  | Elt x       -> Elt x
  | Seq (l, r)  -> Seq (rev r, rev l)


let rec map f s =
  match s with
  | Elt x       -> Elt (f x)
  | Seq (l, r)  -> Seq (map f l, map f r)
  (* 解樹形不變 只把葉子 Elt 的值做 f *)

(* b 小題 *)
(* 尾端遞迴版本 *)
let seq2list s =
  let rec go acc stk = function
    | Elt x ->
        let acc' = x :: acc in
        (match stk with
         | [] -> List.rev acc'
         | t :: ts -> go acc' ts t)
    | Seq (l, r) ->
        go acc (r :: stk) l
  in
  go [] [] s



(* c 小題 *)
let find_opt x s =
  let rec go base = function
    | Elt y ->
        if y = x then Some base else None
    | Seq (l, r) ->
        match go base l with
        | Some i -> Some i
        | None ->
            (* 左邊沒找到，base 需要加上左子樹長度 *)
            let len =
              let rec size = function
                | Elt _ -> 1
                | Seq (a, b) -> size a + size b
              in size l
            in
            go (base + len) r
  in
  go 0 s

(* d 小題 *)
let nth n s =
  if n < 0 then invalid_arg "nth";
  let rec go i stk = function
    | Elt x ->
        if i = 0 then x
        else
          (match stk with
           | [] -> failwith "nth: index out of bounds"
           | t :: ts -> go (i - 1) ts t)
    | Seq (l, r) ->
        go i (r :: stk) l
  in
  go n [] s

let s = (Elt 1 @@ Elt 2) @@ (Elt 3 @@ (Elt 4 @@ Elt 5))

(* 測試結果 *)
let () =
  Printf.printf "hd = %d\n" (hd s);                (* 1 *)
  let s' = tl s in
  Printf.printf "hd (tl s) = %d\n" (hd s');        (* 2 *)
  Printf.printf "mem 4 = %b\n" (mem 4 s);          (* true *)
  let r = rev s in
  Printf.printf "hd (rev s) = %d\n" (hd r);        (* 5 *)
  let s2 = map (fun x -> x * 10) s in
  Printf.printf "hd (map (*10) s) = %d\n" (hd s2); (* 10 *)
  let l = seq2list s in
  Printf.printf "seq2list s = ";
  List.iter (Printf.printf "%d ") l; print_newline ();
  let show = function None -> "None" | Some i -> "Some " ^ string_of_int i in
  Printf.printf "find_opt 1 = %s\n" (show (find_opt 1 s));
  Printf.printf "find_opt 4 = %s\n" (show (find_opt 4 s));
  Printf.printf "find_opt 9 = %s\n" (show (find_opt 9 s));
  Printf.printf "nth 3 = %d\n" (nth 3 s);
  ()
