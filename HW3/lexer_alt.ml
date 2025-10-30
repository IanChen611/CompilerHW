(* Question 6.2: Lexer test program for alternating a and b *)

(* 包含自動生成的詞法分析器 *)
#use "alternating.ml";;

(* 主要的詞法分析循環 *)
let rec lex_loop text pos =
  (* 創建一個新的 buffer *)
  let b = { text = text; current = pos; last = -1 } in

  (* 嘗試調用 start 函數 *)
  try
    start b
  with e ->
    (* 檢查是否有 token 被識別 *)
    if b.last = -1 then
      (* 沒有 token 被識別，重新拋出異常 *)
      raise e
    else begin
      (* 有 token 被識別，輸出它 *)
      let token = String.sub text pos (b.last - pos) in
      Printf.printf "--> \"%s\"\n" token;

      (* 檢查是否是空 token *)
      if token = "" then begin
        Printf.printf "would now loop\n";
        raise End_of_file
      end;

      (* 檢查異常類型並決定是否繼續 *)
      match e with
      | End_of_file ->
          (* 如果是 EOF 且還有剩餘字符，繼續 *)
          if b.last < String.length text then
            lex_loop text b.last
          else
            ()
      | _ ->
          (* 其他異常，如果還有剩餘字符則繼續 *)
          if b.last < String.length text then
            lex_loop text b.last
          else
            raise e
    end

(* 主函數 *)
let () =
  if Array.length Sys.argv < 2 then begin
    Printf.printf "Usage: %s <input_string>\n" Sys.argv.(0);
    exit 1
  end;

  let input = Sys.argv.(1) in

  try
    lex_loop input 0;
    Printf.printf "Success\n"
  with
  | End_of_file -> ()
  | Failure msg -> Printf.printf "exception Failure(\"%s\")\n" msg
