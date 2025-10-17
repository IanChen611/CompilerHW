(* Test the compare_value function *)

type value =
  | Vnone
  | Vbool of bool
  | Vint of int
  | Vstring of string
  | Vlist of value array

let rec compare_value v1 v2 =
  match v1, v2 with
  | Vnone, Vnone -> 0
  | Vnone, _ -> -1
  | _, Vnone -> 1
  | Vbool b1, Vbool b2 -> compare b1 b2
  | Vbool _, _ -> -1
  | _, Vbool _ -> 1
  | Vint n1, Vint n2 -> compare n1 n2
  | Vint _, _ -> -1
  | _, Vint _ -> 1
  | Vstring s1, Vstring s2 -> String.compare s1 s2
  | Vstring _, _ -> -1
  | _, Vstring _ -> 1
  | Vlist a1, Vlist a2 ->
      (* Lexicographic comparison for lists *)
      let len1 = Array.length a1 in
      let len2 = Array.length a2 in
      let rec compare_elements i =
        if i >= len1 && i >= len2 then 0
        else if i >= len1 then -1  (* a1 is shorter *)
        else if i >= len2 then 1   (* a2 is shorter *)
        else
          let cmp = compare_value a1.(i) a2.(i) in
          if cmp <> 0 then cmp
          else compare_elements (i + 1)
      in
      compare_elements 0

(* Test cases *)
let () =
  (* Test 1: [0, 1, 1] < [1] should be True *)
  let list1 = Vlist [| Vint 0; Vint 1; Vint 1 |] in
  let list2 = Vlist [| Vint 1 |] in
  Printf.printf "Test 1: [0,1,1] < [1] = %b (expected: true)\n" (compare_value list1 list2 < 0);

  (* Test 2: [1] > [0, 1, 1] should be True *)
  Printf.printf "Test 2: [1] > [0,1,1] = %b (expected: true)\n" (compare_value list2 list1 > 0);

  (* Test 3: [1, 2] < [1, 3] should be True *)
  let list3 = Vlist [| Vint 1; Vint 2 |] in
  let list4 = Vlist [| Vint 1; Vint 3 |] in
  Printf.printf "Test 3: [1,2] < [1,3] = %b (expected: true)\n" (compare_value list3 list4 < 0);

  (* Test 4: [1, 2] == [1, 2] should be True *)
  let list5 = Vlist [| Vint 1; Vint 2 |] in
  Printf.printf "Test 4: [1,2] == [1,2] = %b (expected: true)\n" (compare_value list3 list5 = 0);

  Printf.printf "\nAll tests passed!\n"
