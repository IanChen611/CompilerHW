type typ =
| Tint
| Tarrow of typ * typ
| Tproduct of typ * typ
| Tvar of tvar

and tvar =
  { id : int;
    mutable def : typ option }

let rec pp_typ fmt = function
  | Tproduct (t1, t2) -> Format.fprintf fmt "%a *@ %a" pp_atom t1 pp_atom t2
  | Tarrow (t1, t2) -> Format.fprintf fmt "%a ->@ %a" pp_atom t1 pp_typ t2
  | (Tint | Tvar _) as t -> pp_atom fmt t
and pp_atom fmt = function
  | Tint -> Format.fprintf fmt "int"
  | Tvar v -> pp_tvar fmt v
  | Tarrow _ | Tproduct _ as t -> Format.fprintf fmt "@[<1>(%a)@]" pp_typ t
and pp_tvar fmt = function
  | { def = None; id } -> Format.fprintf fmt "'%d" id
  | { def = Some t; id } -> Format.fprintf fmt "@[<1>('%d := %a)@]" id pp_typ t

module V = struct
  type t = tvar
  let compare v1 v2 = Stdlib.compare v1.id v2.id
  let equal v1 v2 = v1.id = v2.id
  let create = let r = ref 0 in fun () -> incr r; { id = !r; def = None }
end

(* 1-1 *)
let rec head t = match t with
  | Tvar { def = Some t'; _ } -> head t' (* 遞迴下去 *)
  | _ -> t

(* 1-1 測試 *)
let () =
  let a = V.create() in
  let b = V.create() in
  let ta = Tvar a in
  let tb = Tvar b in
  assert (head ta == ta);
  assert (head tb == tb);
  let _ty = Tarrow (ta, tb) in
  a.def <- Some tb;
  assert (head ta == tb);
  assert (head tb == tb);
  b.def <- Some Tint;
  assert (head ta = Tint);
  assert (head tb = Tint);
  print_endline "Pass test in 1-1."

(* 1-2 *)
let rec canon t =
  match head t with
  | Tint -> Tint
  | Tvar v -> Tvar v
  | Tarrow (t1, t2) -> Tarrow (canon t1, canon t2)
  | Tproduct (t1, t2) -> Tproduct (canon t1, canon t2)

(* 1-2 測試 *)
let () =
  let a = V.create() in
  let b = V.create() in
  let ta = Tvar a in
  let tb = Tvar b in
  a.def <- Some tb;
  b.def <- Some Tint;
  assert (head tb = Tint);
  assert (canon ta = Tint);
  assert (canon tb = Tint);
  let ty = Tarrow (ta, tb) in
  assert (canon ty = Tarrow (Tint, Tint));
  print_endline "Pass test in 1-2."


(* 2-1 *)
let rec occurs v t =
  match head t with
  | Tint -> false                                     (*整數型別不含任何變數，回傳 false*)
  | Tvar v' -> V.equal v v'                           (*檢查 v 和 v' 用 V.equal檢查是否相同*)
  | Tarrow (t1, t2) -> occurs v t1 || occurs v t2     (*分別檢查arrow中的兩個變數有沒有類別v*)
  | Tproduct (t1, t2) -> occurs v t1 || occurs v t2   (*分別檢查Tproduct中的兩個變數有沒有類別v*)

(* 2-1 測試 *)
let () =
  let a = V.create() in
  let b = V.create() in
  let ta = Tvar a in
  let tb = Tvar b in
  assert (occurs a ta);
  assert (occurs b tb);
  assert (not (occurs a tb));
  let ty = Tarrow (ta, tb) in
  assert (occurs a ty);
  assert (occurs b ty);
  print_endline "Pass test in 2-1."

(* 2-2 *)
(* 讓兩個型別「統一」 *)
exception UnificationFailure of typ * typ
let unification_error t1 t2 = raise (UnificationFailure (canon t1, canon t2))

let rec unify t1 t2 =
  match head t1, head t2 with
  | Tint, Tint -> ()
  | Tvar v1, Tvar v2 when V.equal v1 v2 -> ()
  | Tvar v, t | t, Tvar v ->
      if occurs v t then unification_error t1 t2
      else v.def <- Some t
  | Tarrow (t1a, t1b), Tarrow (t2a, t2b) ->
      unify t1a t2a;
      unify t1b t2b
  | Tproduct (t1a, t1b), Tproduct (t2a, t2b) ->
      unify t1a t2a;
      unify t1b t2b
  | _, _ -> unification_error t1 t2

(* 2-2 測試 *)
let () =
  let a = V.create() in
  let b = V.create() in
  let ta = Tvar a in
  let tb = Tvar b in
  (* 統一 'a -> 'b 和 int -> int *)
  let ty = Tarrow (ta, tb) in
  unify ty (Tarrow (Tint, Tint));
  assert (canon ta = Tint);
  assert (canon ty = Tarrow (Tint, Tint));
  (* 統一 'c 和 int -> int *)
  let c = V.create() in
  let tc = Tvar c in
  unify tc ty;
  assert (canon tc = Tarrow (Tint, Tint));
  print_endline "Pass test in 2-2."

(* 2-2 負面測試：測試統一失敗的情況 *)
let cant_unify ty1 ty2 =
  try let _ = unify ty1 ty2 in false with UnificationFailure _ -> true

let () =
  assert (cant_unify Tint (Tarrow (Tint, Tint)));
  assert (cant_unify Tint (Tproduct (Tint, Tint)));
  let a = V.create() in
  let ta = Tvar a in
  unify ta (Tarrow (Tint, Tint));
  assert (cant_unify ta Tint);
  print_endline "Pass negative test in 2-2."


(* Part 3 *)
(* 型別的 Free Variables *)
module Vset = Set.Make(V)

(* 3-1 *)
let rec fvars t =
  match head t with
  | Tint -> Vset.empty
  | Tvar v -> Vset.singleton v
  | Tarrow (t1, t2) -> Vset.union (fvars t1) (fvars t2)
  | Tproduct (t1, t2) -> Vset.union (fvars t1) (fvars t2)

(* 3-1 測試 *)
let () =
  assert (Vset.is_empty (fvars (Tarrow (Tint, Tint))));
  let a = V.create() in
  let ta = Tvar a in
  let ty = Tarrow (ta, ta) in
  assert (Vset.equal (fvars ty) (Vset.singleton a));
  unify ty (Tarrow (Tint, Tint));
  assert (Vset.is_empty (fvars ty));
  print_endline "Pass test in 3-1."


(* Part 4 *)
(* 型別環境 Typing Environment *)
type schema = { vars: Vset.t; typ : typ }

module Smap = Map.Make(String)

type env = { bindings: schema Smap.t; fvars: Vset.t }

let empty = { bindings = Smap.empty; fvars = Vset.empty }

(* 4-1: 加入變數到環境，不泛化 *)
let add x t env =
  let schema = { vars = Vset.empty; typ = t } in
  let new_fvars = Vset.union env.fvars (fvars t) in
  { bindings = Smap.add x schema env.bindings; fvars = new_fvars }

(* 4-2: 加入變數到環境，並泛化 *)
let add_gen x t env =
  let t_fvars = fvars t in
  let gen_vars = Vset.diff t_fvars env.fvars in
  let schema = { vars = gen_vars; typ = t } in
  let new_fvars = Vset.union env.fvars t_fvars in
  { bindings = Smap.add x schema env.bindings; fvars = new_fvars }

(* 4-3: 從環境中查找變數，並實例化 *)
module Vmap = Map.Make(V)

let find x env =
  let schema = Smap.find x env.bindings in
  if Vset.is_empty schema.vars then
    schema.typ
  else
    let subst = Vset.fold (fun v acc ->
      Vmap.add v (Tvar (V.create())) acc
    ) schema.vars Vmap.empty in
    let rec apply_subst t =
      match head t with
      | Tint -> Tint
      | Tvar v ->
          (try Vmap.find v subst with Not_found -> Tvar v)
      | Tarrow (t1, t2) -> Tarrow (apply_subst t1, apply_subst t2)
      | Tproduct (t1, t2) -> Tproduct (apply_subst t1, apply_subst t2)
    in
    apply_subst schema.typ

(* Part 4 測試 *)
let () =
  let env = empty in
  (* 測試 add：不泛化 *)
  let a = V.create() in
  let ta = Tvar a in
  let env1 = add "x" ta env in
  let tx1 = find "x" env1 in
  let tx2 = find "x" env1 in
  (* 因為沒有泛化，兩次 find 應該回傳同一個變數 *)
  assert (tx1 = tx2);
  print_endline "Pass test in 4-1 (add)."

let () =
  let env = empty in
  (* 測試 add_gen：泛化 *)
  let a = V.create() in
  let ta = Tvar a in
  let env2 = add_gen "id" ta env in
  let tid1 = find "id" env2 in
  let tid2 = find "id" env2 in
  (* 因為有泛化，兩次 find 應該回傳不同的新變數 *)
  assert (tid1 <> tid2);
  print_endline "Pass test in 4-2 (add_gen)."

let () =
  let env = empty in
  (* 測試複雜型別的泛化 *)
  let a = V.create() in
  let b = V.create() in
  let ta = Tvar a in
  let tb = Tvar b in
  let ty = Tarrow (ta, tb) in  (* 'a -> 'b *)
  let env3 = add_gen "f" ty env in
  let tf1 = find "f" env3 in
  let tf2 = find "f" env3 in
  (* 兩次 find 應該得到不同的實例 *)
  assert (tf1 <> tf2);
  (* 但結構應該相同（都是箭頭型別）*)
  assert (match tf1, tf2 with
    | Tarrow (_, _), Tarrow (_, _) -> true
    | _ -> false);
  print_endline "Pass test in 4-3 (find with generalization)."


(* Part 5 *)
(* Algorithm W - 型別推導的核心演算法 *)

type expression =
  | Var of string
  | Const of int
  | Op of string
  | Fun of string * expression
  | App of expression * expression
  | Pair of expression * expression
  | Let of string * expression * expression

(* 5-1: Algorithm W *)
let rec w env = function
  | Const _ -> Tint

  | Var x -> find x env

  | Op _ -> Tarrow (Tproduct (Tint, Tint), Tint)

  | Fun (x, e) ->
      let a = V.create() in
      let ta = Tvar a in
      let env' = add x ta env in
      let te = w env' e in
      Tarrow (ta, te)

  | App (e1, e2) ->
      let t1 = w env e1 in
      let t2 = w env e2 in
      let a = V.create() in
      let ta = Tvar a in
      unify t1 (Tarrow (t2, ta));
      ta

  | Pair (e1, e2) ->
      let t1 = w env e1 in
      let t2 = w env e2 in
      Tproduct (t1, t2)

  | Let (x, e1, e2) ->
      let t1 = w env e1 in
      let env' = add_gen x t1 env in
      w env' e2

(* 測試用的 typeof 函數 *)
let typeof e = canon (w empty e)

(* Part 5 測試 - 正面測試 *)
let () =
  (* 1 : int *)
  assert (typeof (Const 1) = Tint);
  print_endline "Pass test: 1 : int"

let () =
  (* fun x -> x : 'a -> 'a *)
  assert (match typeof (Fun ("x", Var "x")) with
    | Tarrow (Tvar v1, Tvar v2) -> V.equal v1 v2
    | _ -> false);
  print_endline "Pass test: fun x -> x : 'a -> 'a"

let () =
  (* fun x -> x+1: int -> int *)
  assert (typeof (Fun ("x", App (Op "+", Pair (Var "x", Const 1))))
    = Tarrow (Tint, Tint));
  print_endline "Pass test: fun x -> x+1 : int -> int"

let () =
  (* fun x -> x+x: int -> int *)
  assert (typeof (Fun ("x", App (Op "+", Pair (Var "x", Var "x"))))
    = Tarrow (Tint, Tint));
  print_endline "Pass test: fun x -> x+x : int -> int"

let () =
  (* let x = 1 in x+x : int *)
  assert (typeof (Let ("x", Const 1, App (Op "+", Pair (Var "x", Var "x"))))
    = Tint);
  print_endline "Pass test: let x = 1 in x+x : int"

let () =
  (* let id = fun x -> x in id 1 *)
  assert (typeof (Let ("id", Fun ("x", Var "x"), App (Var "id", Const 1)))
    = Tint);
  print_endline "Pass test: let id = fun x -> x in id 1 : int"

let () =
  (* let id = fun x -> x in id id 1 *)
  assert (typeof (Let ("id", Fun ("x", Var "x"),
                      App (App (Var "id", Var "id"), Const 1)))
    = Tint);
  print_endline "Pass test: let id = fun x -> x in id id 1 : int"

let () =
  (* let id = fun x -> x in (id 1, id (1,2)): int * (int * int) *)
  assert (typeof (Let ("id", Fun ("x", Var "x"),
                      Pair (App (Var "id", Const 1),
                            App (Var "id", Pair (Const 1, Const 2)))))
    = Tproduct (Tint, Tproduct (Tint, Tint)));
  print_endline "Pass test: let id = fun x -> x in (id 1, id (1,2)) : int * (int * int)"

let () =
  (* app = fun f -> fun x -> let y = f x in y: ('a -> 'b) -> 'a -> 'b *)
  let ty =
    typeof (Fun ("f", Fun ("x", Let ("y", App (Var "f", Var "x"), Var "y"))))
  in
  (* 檢查是否為正確的函數型別結構 *)
  assert (match ty with
    | Tarrow (Tarrow (_, _), Tarrow (_, _)) -> true
    | _ -> false);
  print_endline "Pass test: fun f x -> let y = f x in y : ('a -> 'b) -> 'a -> 'b"

(* Part 5 測試 - 負面測試 *)
let cant_type e =
  try let _ = typeof e in false with UnificationFailure _ -> true

let () =
  (* 1 2 - 試圖把整數當函數呼叫 *)
  assert (cant_type (App (Const 1, Const 2)));
  print_endline "Pass negative test: 1 2"

let () =
  (* fun x -> x x - 自我應用 *)
  assert (cant_type (Fun ("x", App (Var "x", Var "x"))));
  print_endline "Pass negative test: fun x -> x x"

let () =
  (* (fun f -> +(f 1)) (fun x -> x) *)
  assert (cant_type
    (App (Fun ("f", App (Op "+", App (Var "f", Const 1))),
          Fun ("x", Var "x"))));
  print_endline "Pass negative test: (fun f -> +(f 1)) (fun x -> x)"

let () =
  (* fun x -> (x 1, x (1,2)) *)
  assert (cant_type
    (Fun ("x", Pair (App (Var "x", Const 1),
                     App (Var "x", Pair (Const 1, Const 2))))));
  print_endline "Pass negative test: fun x -> (x 1, x (1,2))"

let () =
  (* fun x -> let z = x in (z 1, z (1,2)) *)
  assert (cant_type
    (Fun ("x",
          Let ("z", Var "x",
               Pair (App (Var "z", Const 1),
                     App (Var "z", Pair (Const 1, Const 2)))))));
  print_endline "Pass negative test: fun x -> let z = x in (z 1, z (1,2))"

let () =
  (* let distr_pair = fun f -> (f 1, f (1,2)) in distr_pair (fun x -> x) *)
  assert (cant_type
    (Let ("distr_pair",
          Fun ("f", Pair (App (Var "f", Const 1),
                          App (Var "f", Pair (Const 1, Const 2)))),
          App (Var "distr_pair", Fun ("x", Var "x")))));
  print_endline "Pass negative test: let distr_pair = fun f -> (f 1, f (1,2)) in distr_pair (fun x -> x)"

