

let square_sum l = 
  let result = List.map (fun x -> x * x) l in
  List.fold_left ( + ) 0 result


let arr = [1; 2; 3; 4; 5]
let () = Printf.printf "arr square_sum : %d\n" (square_sum arr)
