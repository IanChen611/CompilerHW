type ichar = char * int

module Cset = Set.Make(struct type t = ichar let compare = Stdlib.compare end)

type regexp =
  | Epsilon
  | Character of ichar
  | Union of regexp * regexp
  | Concat of regexp * regexp
  | Star of regexp

(* Question 1: 判斷正規表達式是否接受空字串 *)
let rec null (r : regexp) : bool =
  match r with
  | Epsilon -> (* Epsilon 就是空字串，所以接受空字串 *)
      true

  | Character _ -> (* 任何字元都需要至少一個字元，所以不接受空字串 *)
      false

  | Union (r1, r2) -> (* 聯集：只要其中一個接受空字串就可以 *)
      null r1 || null r2

  | Concat (r1, r2) -> (* 串接：兩個都要接受空字串才可以 *)
      null r1 && null r2

  | Star _ -> (* Kleene star 代表 0 次或多次，0 次就是空字串 *)
      true


let rec first (r : regexp) : Cset.t =
  match r with
  | Epsilon -> 
      Cset.empty
  | Character c -> (* 單個字母 *)
      Cset.singleton c
  | Union (r1, r2) -> (*  *)
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


let () = test_null ()
let () = test_first ()
let () = test_last ()
