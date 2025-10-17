
open Ast
open Format

(* Exception raised for signaling an error during interpretation *)
exception Error of string
let error s = raise (Error s)

(* Values of Mini-Python.

   Two main differences wrt Python:

   - We use here machine integers (OCaml type `int`) while Python
     integers are arbitrary-precision integers (we could use an OCaml
     library for big integers, such as zarith, but we opt for simplicity
     here).

   - What Python calls a ``list'' is a resizeable array. In Mini-Python,
     there is no way to modify the length, so a mere OCaml array can be used.
*)
type value =
  | Vnone
  | Vbool of bool
  | Vint of int
  | Vstring of string
  | Vlist of value array

(* Print a value on standard output *)
let rec print_value = function
  | Vnone -> printf "None"
  | Vbool true -> printf "True"
  | Vbool false -> printf "False"
  | Vint n -> printf "%d" n
  | Vstring s -> printf "%s" s
  | Vlist a ->
    let n = Array.length a in
    printf "[";
    for i = 0 to n-1 do print_value a.(i); if i < n-1 then printf ", " done;
    printf "]"

(* Boolean interpretation of a value

   In Python, any value can be used as a Boolean: None, the integer 0,
   the empty string, and the empty list are all considered to be
   False, and any other value to be True.
*)
(* 
  第二題需要實作的內容

  1. is_false 和 is_true 函數：判斷一個值的真假
  2. 比較運算子：==, !=(<>), <, <=, >, >=
  3. 布林常數：True, False
  4. 布林運算子：and, or, not
  5. if 語句：條件判斷
*)
let is_false (v: value) = 
    match v with 
    | Vnone -> true
    | Vbool false -> true
    | Vint 0 -> true
    | Vstring "" -> true
    | Vlist a when Array.length a = 0 -> true
    | _ -> false

let is_true (v: value) = not (is_false v)

(* Bonus: Structural comparison compatible with Python

   Python uses lexicographic order for lists, while OCaml compares
   lengths first. This function implements Python-compatible comparison.

   Returns:
   - negative integer if v1 < v2
   - zero if v1 = v2
   - positive integer if v1 > v2
*)
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

(* We only have global functions in Mini-Python *)

let functions = (Hashtbl.create 16 : (string, ident list * stmt) Hashtbl.t)

(* The following exception is used to interpret Python's `return` *)

exception Return of value

(* Local variables (function parameters and variables introduced by
   assignments) are stored in a hash table passed as an argument to
   the following functions under the name 'ctx' *)


type ctx = (string, value) Hashtbl.t

(* Interpreting an expression (returns a value) *)

let rec expr (ctx: ctx) = function
  | Ecst Cnone ->
      Vnone
  | Ecst (Cstring s) ->
      Vstring s
  (* arithmetic *)
  | Ecst (Cint n) ->
      Vint (Int64.to_int n)
  | Ebinop (Badd | Bsub | Bmul | Bdiv | Bmod |
            Beq | Bneq | Blt | Ble | Bgt | Bge as op, e1, e2) ->
      let v1 = expr ctx e1 in
      let v2 = expr ctx e2 in
      begin match op, v1, v2 with
        | Badd, Vint n1, Vint n2 -> Vint (n1 + n2)
        | Bsub, Vint n1, Vint n2 -> Vint (n1 - n2)
        | Bmul, Vint n1, Vint n2 -> Vint (n1 * n2)
        | Bdiv, Vint n1, Vint n2 ->
            if n2 = 0 then error "division by zero"
            else Vint (n1 / n2)
        | Bmod, Vint n1, Vint n2 ->
            if n2 = 0 then error "modulo by zero"
            else Vint (n1 mod n2)
        | Beq, _, _  -> Vbool (compare_value v1 v2 = 0)
        | Bneq, _, _ -> Vbool (compare_value v1 v2 <> 0)
        | Blt, _, _  -> Vbool (compare_value v1 v2 < 0)
        | Ble, _, _  -> Vbool (compare_value v1 v2 <= 0)
        | Bgt, _, _  -> Vbool (compare_value v1 v2 > 0)
        | Bge, _, _  -> Vbool (compare_value v1 v2 >= 0)
        | Badd, Vstring s1, Vstring s2 ->
            Vstring (s1 ^ s2)
        | Badd, Vlist l1, Vlist l2 ->
            Vlist (Array.append l1 l2)
        | _ -> error "unsupported operand types"
      end
  | Eunop (Uneg, e1) ->
      begin match expr ctx e1 with
        | Vint n -> Vint (-n)
        | _ -> error "unsupported operand type for unary -"
      end
  (* booleans *)
  | Ecst (Cbool b) ->
      Vbool b
  | Ebinop (Band, e1, e2) ->
      let v1 = expr ctx e1 in
      if is_false v1 then v1 else expr ctx e2
  | Ebinop (Bor, e1, e2) ->
      let v1 = expr ctx e1 in
      if is_true v1 then v1 else expr ctx e2
  | Eunop (Unot, e1) ->
      let v1 = expr ctx e1 in
      Vbool (is_false v1)
  | Eident id ->
      (try Hashtbl.find ctx id.id
       with Not_found -> error ("unbound variable " ^ id.id))
  (* function call *)
  | Ecall ({id="len"; _}, [e1]) ->
      begin match expr ctx e1 with
        | Vlist arr -> Vint (Array.length arr)
        | _ -> error "len() requires a list"
      end
  | Ecall ({id="list"; _}, [Ecall ({id="range"; _}, [e1])]) ->
      begin match expr ctx e1 with
        | Vint n when n >= 0 ->
            Vlist (Array.init n (fun i -> Vint i))
        | Vint n ->
            error ("range() argument must be non-negative, got " ^ string_of_int n)
        | _ ->
            error "range() argument must be an integer"
      end
  | Ecall (f, el) ->
      (* 找到函數定義 *)
      let (params, body) =
        try Hashtbl.find functions f.id
        with Not_found -> error ("undefined function " ^ f.id)
      in
      (* 檢查參數數量 *)
      if List.length params <> List.length el then
        error ("function " ^ f.id ^ " expects " ^
               string_of_int (List.length params) ^ " arguments")
      else begin
        (* 計算所有實際參數的值 *)
        let args = List.map (expr ctx) el in
        (* 建立新的環境 *)
        let local_ctx = Hashtbl.create 16 in
        (* 將形式參數綁定到實際參數的值 *)
        List.iter2 (fun param arg ->
          Hashtbl.add local_ctx param.id arg
        ) params args;
        (* 執行函數主體，捕捉 Return exception *)
        try
          stmt local_ctx body;
          Vnone  (* 如果沒有 return，返回 None *)
        with Return v -> v
      end
  | Elist el ->
      (* 計算所有元素的值並建立陣列 *)
      let values = List.map (expr ctx) el in
      Vlist (Array.of_list values)
  | Eget (e1, e2) ->
      (* 存取串列元素 e1[e2] *)
      let v1 = expr ctx e1 in
      let v2 = expr ctx e2 in
      begin match v1, v2 with
        | Vlist arr, Vint i ->
            if i >= 0 && i < Array.length arr then
              arr.(i)
            else
              error ("list index out of range: " ^ string_of_int i)
        | Vlist _, _ ->
            error "list index must be an integer"
        | _ ->
            error "indexing requires a list"
      end

(* Interpreting a statement (does not return anything but may raise exception `Return`) *)

and stmt (ctx: ctx) = function
  | Seval e ->
      ignore (expr ctx e)
  | Sprint e ->
      print_value (expr ctx e); printf "@."
  | Sblock bl ->
      block ctx bl
  | Sif (e, s1, s2) ->
      let v = expr ctx e in
      if is_true v then stmt ctx s1 else stmt ctx s2
  | Sassign (id, e1) ->
      let v1 = expr ctx e1 in
      Hashtbl.replace ctx id.id v1
  | Sreturn e ->
      let v = expr ctx e in
      raise (Return v)
  | Sfor (x, e, s) ->
      (* for 迴圈：依序將串列 e 的每個值賦給變數 x，並執行語句 s *)
      (* 重要：表達式 e 只能計算一次 *)
      let list_val = expr ctx e in
      begin match list_val with
        | Vlist arr ->
            Array.iter (fun v ->
              Hashtbl.replace ctx x.id v;
              stmt ctx s
            ) arr
        | _ ->
            error "for loop requires a list"
      end
  | Sset (e1, e2, e3) ->
      (* 串列元素賦值：e1[e2] = e3 *)
      let v1 = expr ctx e1 in
      let v2 = expr ctx e2 in
      let v3 = expr ctx e3 in
      begin match v1, v2 with
        | Vlist arr, Vint i ->
            if i >= 0 && i < Array.length arr then
              arr.(i) <- v3
            else
              error ("list assignment index out of range: " ^ string_of_int i)
        | Vlist _, _ ->
            error "list index must be an integer"
        | _ ->
            error "list assignment requires a list"
      end

(* Interpreting a block i.e. a sequence of statements *)

and block (ctx: ctx) = function
  | [] -> ()
  | s :: sl -> stmt ctx s; block ctx sl

(* Interpreting a file
   - dl is a list of function definitions (cf Ast.def)
   - s is a statement, which represents the global statements
 *)

let file ((dl: def list), (s: stmt)) =
  List.iter (fun (fname, params, body) ->
    Hashtbl.add functions fname.id (params, body)
  ) dl;
  stmt (Hashtbl.create 16) s



