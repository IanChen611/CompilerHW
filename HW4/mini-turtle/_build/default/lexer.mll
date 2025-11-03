
(* Lexical analyser for mini-Turtle *)

{
  open Lexing
  open Parser

  (* raise exception to report a lexical error *)
  exception Lexing_error of string

  (* note : remember to call the Lexing.new_line function
at each carriage return ('\n' character) *)

}

rule token = parse
  | [' ' '\t']     { token lexbuf }  (* 忽略空格和 tab *)
  | '\n'           { new_line lexbuf; token lexbuf }  (* 換行 *)
  | "//" [^ '\n']* { token lexbuf }  (* 單行註解 // ... *)
  | "(*"           { comment lexbuf }  (* 多行註解 (* ... *) *)

  (* 關鍵字 - 這裡示範幾個，你可以補完其他的 *)
  | "if"           { IF }
  | "else"         { ELSE }
  | "def"          { DEF }
  | "repeat"       { REPEAT }
  | "forward"      { FORWARD }
  | "penup"        { PENUP }
  | "pendown"      { PENDOWN }
  | "turnleft"     { TURNLEFT }
  | "turnright"    { TURNRIGHT }
  | "color"        { COLOR }

  (* 顏色關鍵字 *)
  | "black"        { BLACK }
  | "white"        { WHITE }
  | "red"          { RED }
  | "green"        { GREEN }
  | "blue"         { BLUE }

  (* 運算符號和標點符號 *)
  | "+"            { PLUS }
  | "-"            { MINUS }
  | "*"            { TIMES }
  | "/"            { DIV }
  | "("            { LPAR }
  | ")"            { RPAR }
  | "{"            { LBRACE }
  | "}"            { RBRACE }
  | ","            { COMMA }

  (* 整數 *)
  | ['0'-'9']+ as n { INT (int_of_string n) }

  (* 識別字 - 必須放在關鍵字之後 *)
  | ['a'-'z' 'A'-'Z'] ['a'-'z' 'A'-'Z' '0'-'9' '_']* as id
      { IDENT id }

  (* 檔案結束 *)
  | eof            { EOF }

  | _ as c { raise (Lexing_error ("illegal character: " ^ String.make 1 c)) }

(* 處理多行註解的輔助函數 *)
and comment = parse
  | "*)"  { token lexbuf }  (* 註解結束，回到主 token 函數 *)
  | '\n'  { new_line lexbuf; comment lexbuf }  (* 註解中的換行 *)
  | eof   { raise (Lexing_error "unterminated comment") }
  | _     { comment lexbuf }  (* 繼續讀取註解內容 *)
