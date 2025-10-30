type ichar = char * int

module Cset = Set.Make(struct type t = ichar let compare = Stdlib.compare end)

type regexp =
  | Epsilon
  | Character of ichar
  | Union of regexp * regexp
  | Concat of regexp * regexp
  | Star of regexp

(* Question 1: Nullity of a regular expression *)
let rec null (r : regexp) : bool =
  match r with
  | Epsilon -> (* Epsilon 空字串*)
      true

  | Character _ -> (* 任何字元都需要至少一個字元，所以不接受空字串 *)
      false

  | Union (r1, r2) -> (* 聯集：只要其中一個接受空字串就可以 *)
      null r1 || null r2

  | Concat (r1, r2) -> (* 串接：兩個都要接受空字串才可以 *)
      null r1 && null r2

  | Star _ -> (* Kleene star 代表 0 次或多次，0 次就是空字串 *)
      true

(* Question 2: First and Last *)
let rec first (r : regexp) : Cset.t =
  match r with
  | Epsilon -> 
      Cset.empty
  | Character c -> (* 單個字母 *)
      Cset.singleton c
  | Union (r1, r2) ->
      Cset.union (first r1) (first r2)

  | Concat (r1, r2) ->
      if null r1 then
        Cset.union (first r1) (first r2)
      else
        first r1 
  | Star r1 ->
      first r1

let rec last (r : regexp) : Cset.t =
  match r with
  | Epsilon -> 
      Cset.empty
  | Character c -> 
      Cset.singleton c
  | Union (r1, r2) -> 
      Cset.union (last r1) (last r2)
  | Concat (r1, r2) -> 
      if null r2 then
        Cset.union (last r1) (last r2)
      else
        last r2
  | Star r1 -> 
      last r1


(* Question 3: The follow *)
(* follow c r：計算在正則表達式 r 識別的字串中，可以跟隨在字符 c 後面的所有字符 *)
let rec follow (c : ichar) (r : regexp) : Cset.t =
  match r with
  | Epsilon ->
      Cset.empty
  | Character _ ->
      (* 單個字符沒有後續關係 *)
      Cset.empty
  | Union (r1, r2) ->
      (* 聯集：收集兩邊子表達式中 c 的 follow set *)
      Cset.union (follow c r1) (follow c r2)

  | Concat (r1, r2) ->
      if Cset.mem c (last r1) then (* 如果 c 在 last r1 中，則需要找 first r2 *)
        Cset.union (first r2) (Cset.union (follow c r1) (follow c r2))
      else 
        Cset.union (follow c r1) (follow c r2)

  | Star r1 ->
      (* 1. 如果 c ∈ last(r1)，那麼 first(r1) 中的字符都可以跟隨 c（循環）
         2. 遞迴地收集 r1 內部 c 的 follow 關係 *)
      if Cset.mem c (last r1) then
        Cset.union (first r1) (follow c r1)
      else
        (follow c r1)

(* 測試程式碼 *)
let test_null () =
  let a = Character ('a', 0) in
  assert (not (null a));
  assert (null (Star a));
  assert (null (Concat (Epsilon, Star Epsilon)));
  assert (null (Union (Epsilon, a)));
  assert (not (null (Concat (a, Star a))));

  print_endline "所有null的測試通過"


let test_first () =
  let ca = ('a', 0) and cb = ('b', 0) in
  let a = Character ca and b = Character cb in
  let ab = Concat (a, b) in
  let eq = Cset.equal in
  assert (eq (first a) (Cset.singleton ca));
  assert (eq (first ab) (Cset.singleton ca));
  assert (eq (first (Star ab)) (Cset.singleton ca));

  print_endline "所有first的測試通過"


let test_last () =
  let ca = ('a', 0) and cb = ('b', 0) in
  let a = Character ca and b = Character cb in
  let ab = Concat (a, b) in
  let eq = Cset.equal in
  assert (eq (last b) (Cset.singleton cb));
  assert (eq (last ab) (Cset.singleton cb));
  assert (Cset.cardinal (first (Union (a, b))) = 2);
  assert (Cset.cardinal (first (Concat (Star a, b))) = 2);
  assert (Cset.cardinal (last (Concat (a, Star b))) = 2);

  print_endline "所有last的測試通過"

let test_follow () =
  let ca = (
  'a', 0) and cb = (
  'b', 0) in
  let a = Character ca and b = Character cb in
  let ab = Concat (a, b) in
  assert (Cset.equal (follow ca ab) (Cset.singleton cb));
  assert (Cset.is_empty (follow cb ab));
  let r = Star (Union (a, b)) in
  assert (Cset.cardinal (follow ca r) = 2);
  assert (Cset.cardinal (follow cb r) = 2);
  let r2 = Star (Concat (a, Star b)) in
  assert (Cset.cardinal (follow cb r2) = 2);
  let r3 = Concat (Star a, b) in
  assert (Cset.cardinal (follow ca r3) = 2);

  print_endline "所有follow的測試通過"


(* Question 4: Construction of the automaton *)

(* 類型定義 *)
type state = Cset.t (* a state is a set of characters *)
module Cmap = Map.Make(Char) (* dictionary whose keys are characters *)
module Smap = Map.Make(Cset) (* dictionary whose keys are states *)

type autom = {
  start : state;
  trans : state Cmap.t Smap.t (* state dictionary -> (character dictionary -> state) *)
}

(* EOF 字符 *)
let eof = ('#', -1)

(* Question 4.1: next_state function *)
(* next_state r q c：從狀態 q 讀取字符 c 後的下一個狀態 *)
let next_state (r : regexp) (q : state) (c : char) : state =
  (* 遍歷狀態 q 中所有字符 ci，如果 fst ci = c，則收集 follow ci r *)
  Cset.fold (fun ci acc ->
    if fst ci = c then
      Cset.union (follow ci r) acc
    else
      acc
  ) q Cset.empty

(* Question 4.2: make_dfa function *)
let make_dfa (r : regexp) : autom =
  (* 在 r 後面加上 EOF 字符 *)
  let r = Concat (r, Character eof) in
  (* transitions 正在構建中 *)
  let trans = ref Smap.empty in
  (* 記錄已訪問的狀態 *)
  let visited = ref Smap.empty in

  (* transitions 函數構建狀態 q 的所有轉移 *)
  let rec transitions q =
    (* 如果已經訪問過這個狀態，直接返回 *)
    if Smap.mem q !visited then ()
    else begin
      (* 標記為已訪問 *)
      visited := Smap.add q () !visited;

      (* 收集狀態 q 中所有可能的字符 *)
      let chars = Cset.fold (fun (c, _) acc ->
        if List.mem c acc then acc
        else c :: acc
      ) q [] in

      (* 為每個字符建立轉移 *)
      let state_trans = List.fold_left (fun acc c ->
        let q' = next_state r q c in
        if Cset.is_empty q' then acc
        else begin
          (* 遞歸處理新狀態 *)
          if c <> '#' then transitions q';  (* 不遞歸處理 # 的目標狀態 *)
          Cmap.add c q' acc
        end
      ) Cmap.empty chars in

      (* 如果有轉移，加入 trans *)
      if not (Cmap.is_empty state_trans) then
        trans := Smap.add q state_trans !trans
    end
  in

  (* 初始狀態是 first r *)
  let q0 = first r in
  transitions q0;
  { start = q0; trans = !trans }

(* Visualization with the dot tool *)
let fprint_state fmt q =
  Cset.iter (fun (c,i) ->
    if c = '#' then Format.fprintf fmt "# " else Format.fprintf fmt "%c%i " c i)
    q

let fprint_transition fmt q c q' =
  Format.fprintf fmt "\"%a\" -> \"%a\" [label=\"%c\"];@\n"
    fprint_state q
    fprint_state q'
    c

let fprint_autom fmt a =
  Format.fprintf fmt "digraph A {@\n";
  Format.fprintf fmt " @[\"%a\" [ shape = \"rect\"];@\n" fprint_state a.start;
  (* 添加一個空的終止狀態節點 *)
  Format.fprintf fmt " \"\" [ shape = \"ellipse\"];@\n";
  Smap.iter
    (fun q t ->
      (* 如果狀態 q 包含 #，添加到終止狀態的轉移 *)
      if Cset.exists (fun (c, _) -> c = '#') q then
        Format.fprintf fmt "\"%a\" -> \"\" [label=\"#\"];@\n" fprint_state q;
      (* 輸出所有非 # 的轉移 *)
      Cmap.iter (fun c q' ->
        if c <> '#' then fprint_transition fmt q c q'
      ) t)
    a.trans;
  Format.fprintf fmt "@]@\n}@."

let save_autom file a =
  let ch = open_out file in
  Format.fprintf (Format.formatter_of_out_channel ch) "%a" fprint_autom a;
  close_out ch

(* Question 5: Word recognition *)
let recognize (a : autom) (w : string) : bool =
  (* 從初始狀態開始 *)
  let rec run state pos =
    (* 如果已經讀完整個字串 *)
    if pos = String.length w then
      (* 檢查當前狀態是否包含 # (接受狀態) *)
      Cset.exists (fun (c, _) -> c = '#') state
    else
      (* 讀取當前字符 *)
      let c = w.[pos] in
      (* 查找當前狀態的轉移表 *)
      match Smap.find_opt state a.trans with
      | None -> false  (* 沒有轉移，拒絕 *)
      | Some trans_map ->
          (* 查找字符 c 的轉移 *)
          match Cmap.find_opt c trans_map with
          | None -> false  (* 沒有對應字符的轉移，拒絕 *)
          | Some next_state -> run next_state (pos + 1)  (* 轉移到下一個狀態 *)
  in
  run a.start 0

(* 測試自動機 *)
let test_make_dfa () =
  (* (a|b)*a(a|b) *)
  let r = Concat (
    Star (Union (Character ('a', 1), Character ('b', 1))),
    Concat (
      Character ('a', 2),
      Union (Character ('a', 3), Character ('b', 2))
    )
  ) in
  let a = make_dfa r in
  save_autom "autom.dot" a;
  print_endline "make_dfa 測試完成，已生成 autom.dot"

(* 測試 recognize 函數 *)
let test_recognize () =
  (* (a|b)*a(a|b) *)
  let r = Concat (
    Star (Union (Character ('a', 1), Character ('b', 1))),
    Concat (
      Character ('a', 2),
      Union (Character ('a', 3), Character ('b', 2))
    )
  ) in
  let a = make_dfa r in

  (* 正面測試 *)
  assert (recognize a "aa");
  assert (recognize a "ab");
  assert (recognize a "abababaab");
  assert (recognize a "babababab");
  assert (recognize a (String.make 1000 'b' ^ "ab"));

  (* 負面測試 *)
  assert (not (recognize a ""));
  assert (not (recognize a "a"));
  assert (not (recognize a "b"));
  assert (not (recognize a "ba"));
  assert (not (recognize a "aba"));
  assert (not (recognize a "abababaaba"));

  print_endline "所有 recognize 測試通過 (測試 1)"

(* 測試偶數個 b 的正則表達式 *)
let test_recognize2 () =
  let r = Star (Union (Star (Character ('a', 1)),
                Concat (Character ('b', 1),
                 Concat (Star (Character ('a',2)),
                  Character ('b', 2))))) in
  let a = make_dfa r in
  save_autom "autom2.dot" a;

  (* 正面測試 *)
  assert (recognize a "");
  assert (recognize a "bb");
  assert (recognize a "aaa");
  assert (recognize a "aaabbaaababaaa");
  assert (recognize a "bbbbbbbbbbbbbb");
  assert (recognize a "bbbbabbbbabbbabbb");

  (* 負面測試 *)
  assert (not (recognize a "b"));
  assert (not (recognize a "ba"));
  assert (not (recognize a "ab"));
  assert (not (recognize a "aaabbaaaaabaaa"));
  assert (not (recognize a "bbbbbbbbbbbbb"));
  assert (not (recognize a "bbbbabbbbabbbabbbb"));

  print_endline "所有 recognize 測試通過 (測試 2)"

(* Question 6: Generating a lexical analyzer *)

(* Question 6.1: generate function *)
let generate (filename : string) (a : autom) : unit =
  let ch = open_out filename in
  let fmt = Format.formatter_of_out_channel ch in

  (* 為每個狀態分配一個編號 *)
  let state_num = ref 0 in
  let state_to_num = ref Smap.empty in

  (* 為狀態分配編號的函數 *)
  let get_state_num q =
    match Smap.find_opt q !state_to_num with
    | Some n -> n
    | None ->
        let n = !state_num in
        state_num := n + 1;
        state_to_num := Smap.add q n !state_to_num;
        n
  in

  (* 先為起始狀態分配編號 *)
  let start_num = get_state_num a.start in

  (* 為所有狀態分配編號 *)
  Smap.iter (fun q _ -> ignore (get_state_num q)) a.trans;

  (* 同時收集所有作為目標的狀態 *)
  Smap.iter (fun _ trans_map ->
    Cmap.iter (fun _ q' -> ignore (get_state_num q')) trans_map
  ) a.trans;

  (* 輸出前導代碼 *)
  Format.fprintf fmt "(* Auto-generated lexical analyzer *)@\n@\n";
  Format.fprintf fmt "type buffer = { text: string; mutable current: int; mutable last: int }@\n@\n";
  Format.fprintf fmt "let next_char b =@\n";
  Format.fprintf fmt "  if b.current = String.length b.text then raise End_of_file;@\n";
  Format.fprintf fmt "  let c = b.text.[b.current] in@\n";
  Format.fprintf fmt "  b.current <- b.current + 1;@\n";
  Format.fprintf fmt "  c@\n@\n";

  (* 收集所有狀態（包括沒有出邊的狀態） *)
  let all_states = ref Smap.empty in
  Smap.iter (fun q _ -> all_states := Smap.add q () !all_states) a.trans;
  Smap.iter (fun _ trans_map ->
    Cmap.iter (fun _ q' -> all_states := Smap.add q' () !all_states) trans_map
  ) a.trans;

  (* 輸出所有狀態函數 *)
  let states_list = Smap.fold (fun q _ acc -> q :: acc) !all_states [] in
  let states_sorted = List.sort (fun q1 q2 ->
    compare (get_state_num q1) (get_state_num q2)
  ) states_list in

  List.iteri (fun i q ->
    let num = get_state_num q in
    if i = 0 then
      Format.fprintf fmt "let rec state%d b =@\n" num
    else
      Format.fprintf fmt "and state%d b =@\n" num;

    let is_accepting = Cset.exists (fun (c, _) -> c = '#') q in

    (* 如果是接受狀態，更新 last *)
    if is_accepting then
      Format.fprintf fmt "  b.last <- b.current;@\n";

    (* 讀取下一個字符並根據轉移表決定下一步 *)
    Format.fprintf fmt "  try@\n";
    Format.fprintf fmt "    let c = next_char b in@\n";
    Format.fprintf fmt "    match c with@\n";

    (* 生成每個字符的轉移 *)
    (match Smap.find_opt q a.trans with
     | None -> ()
     | Some trans_map ->
         Cmap.iter (fun c q' ->
           if c <> '#' then begin
             let next_num = get_state_num q' in
             Format.fprintf fmt "    | '%c' -> state%d b@\n" c next_num
           end
         ) trans_map);

    (* 如果沒有匹配的字符，拋出錯誤 *)
    Format.fprintf fmt "    | _ -> failwith \"lexical error\"@\n";
    Format.fprintf fmt "  with End_of_file -> raise End_of_file@\n";
    Format.fprintf fmt "@\n"
  ) states_sorted;

  (* 輸出起始狀態 *)
  Format.fprintf fmt "let start = state%d@\n" start_num;

  Format.pp_print_flush fmt ();
  close_out ch

(* 測試 generate 函數 *)
let test_generate () =
  let r3 = Concat (Star (Character ('a', 1)), Character ('b', 1)) in
  let a = make_dfa r3 in
  generate "a.ml" a;
  print_endline "已生成 a.ml"

let () = test_null ()
let () = test_first ()
let () = test_last ()
let () = test_follow ()
let () = test_make_dfa ()
let () = test_recognize ()
let () = test_recognize2 ()
let () = test_generate ()
