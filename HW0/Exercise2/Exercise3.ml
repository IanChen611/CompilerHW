let rec is_palindrome s i =
    let k = String.length s in
    let l = k lsr 1 in
    if i > l then
        true
    else if (String.get s i) != (String.get s (k - i - 1)) then
        false
    else 
        is_palindrome s (i + 1)

let palindrome s = is_palindrome s 0

let compare a b =
    String.compare a b < 0

let factor m1 m2 =
    let len1 = String.length m1 in
    let len2 = String.length m2 in
    let rec loop i = 
        if (i+len1) > len2 then
            false
        else if String.sub m2 i len1 = m1 then true
        else loop(i+1)
    in 
    if len1 = 0 then true
    else loop 0


let () = Printf.printf "abcba is palindrome? %b\n" (is_palindrome "abcba" 0)
let () = Printf.printf "abaa is palindrome? %b\n" (is_palindrome "abaa" 0)
let () = Printf.printf "Compare apple and banana? %b\n" (compare "apple" "banana")
let () = Printf.printf "Compare banana and apple? %b\n" (compare "banana" "apple")
let () = Printf.printf "factor na and banana? %b\n" (factor "na" "banana")
let () = Printf.printf "factor bb and banana? %b\n" (factor "bb" "banana")