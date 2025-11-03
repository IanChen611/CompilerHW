
/* Parsing for mini-Turtle */

%{
  open Ast

%}

/* Declaration of tokens */

%token EOF

(* 關鍵字 *)
%token IF ELSE DEF REPEAT FORWARD PENUP PENDOWN TURNLEFT TURNRIGHT COLOR

(* 顏色 *)
%token BLACK WHITE RED GREEN BLUE

(* 運算符號 *)
%token PLUS MINUS TIMES DIV

(* 標點符號 *)
%token LPAR RPAR      (* ( ) *)
%token LBRACE RBRACE  (* { } *)
%token COMMA          (* , *)

(* 識別字和整數 *)
%token <string> IDENT
%token <int> INT

/* Priorities and associativity of tokens */

(* 運算符號優先順序：從低到高 *)
%left PLUS MINUS        (* 加減，左結合 *)
%left TIMES DIV         (* 乘除，左結合，優先順序高於加減 *)
%nonassoc UMINUS        (* 一元負號，最高優先順序 *)

/* Axiom of the grammar */
%start prog

/* Type of values ​​returned by the parser */
%type <Ast.program> prog

%%

/* Production rules of the grammar */

prog:
  | def_list stmt_list EOF   { { defs = $1; main = Sblock $2 } }
;

stmt_list:
  | /* empty */           { [] }
  | stmt stmt_list        { $1 :: $2 }
;

expr:
  | INT                           { Econst $1 }
  | IDENT                         { Evar $1 }
  | LPAR expr RPAR                { $2 }
  | expr PLUS expr                { Ebinop (Add, $1, $3) }
  | expr MINUS expr               { Ebinop (Sub, $1, $3) }
  | expr TIMES expr               { Ebinop (Mul, $1, $3) }
  | expr DIV expr                 { Ebinop (Div, $1, $3) }
  | MINUS expr %prec UMINUS       { Ebinop (Sub, Econst 0, $2) }
;

color:
  | BLACK   { Turtle.black }
  | WHITE   { Turtle.white }
  | RED     { Turtle.red }
  | GREEN   { Turtle.green }
  | BLUE    { Turtle.blue }
;

stmt:
  | FORWARD expr                  { Sforward $2 }
  | PENUP                         { Spenup }
  | PENDOWN                       { Spendown }
  | TURNLEFT expr                 { Sturn $2 }
  | TURNRIGHT expr                { Sturn (Ebinop (Sub, Econst 0, $2))} /* 因為在AST中，只有左轉 */
  | COLOR color                   { Scolor $2 }
  | IF expr stmt ELSE stmt        { Sif ($2, $3, $5) }
  | IF expr stmt                  { Sif ($2, $3, Sblock []) }
  | REPEAT expr stmt              { Srepeat ($2, $3) }
  | LBRACE stmt_list RBRACE       { Sblock $2 }
  | IDENT LPAR expr_list RPAR     { Scall ($1, $3) }
;

/* 函數定義列表 */
def_list:
  | /* empty */           { [] }
  | def def_list          { $1 :: $2 }
;

/* 單個函數定義 */
def:
  | DEF IDENT LPAR formal_list RPAR stmt
      { { name = $2; formals = $4; body = $6 } }
;

/* 函數參數列表（定義時） */
formal_list:
  | /* empty */                   { [] }
  | IDENT                         { [$1] }
  | IDENT COMMA formal_list       { $1 :: $3 }
;

/* 表達式列表（函數呼叫時） */
expr_list:
  | /* empty */                   { [] }
  | expr                          { [$1] }
  | expr COMMA expr_list          { $1 :: $3 }
;

