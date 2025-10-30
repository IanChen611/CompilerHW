(* 測試交替 a 和 b 的正則表達式 (b|epsilon)(ab)*(a|epsilon) *)
#use "Parser.ml";;

let r = Concat (
  Union (Character ('b', 1), Epsilon),
  Concat (
    Star (Concat (Character ('a', 1), Character ('b', 2))),
    Union (Character ('a', 2), Epsilon)
  )
) in

let a = make_dfa r in
generate "alternating.ml" a;;

print_endline "已生成 alternating.ml";;
