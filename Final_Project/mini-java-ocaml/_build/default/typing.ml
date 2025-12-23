
open Ast

let debug = ref false

let dummy_loc = Lexing.dummy_pos, Lexing.dummy_pos

exception Error of Ast.location * string

(* use the following function to signal typing errors, e.g.
      error ~loc "unbound variable %s" id
*)
let error ?(loc=dummy_loc) f =
  Format.kasprintf (fun s -> raise (Error (loc, s))) ("@[" ^^ f ^^ "@]")

(* Predefined classes *)
let class_Object = {
  class_name = "Object";
  class_extends = Obj.magic ();  (* will be fixed later *)
  class_methods = Hashtbl.create 16;
  class_attributes = Hashtbl.create 16;
}

let class_String = {
  class_name = "String";
  class_extends = class_Object;
  class_methods = Hashtbl.create 16;
  class_attributes = Hashtbl.create 16;
}

(* Fix class_Object extends *)
let () = class_Object.class_extends <- class_Object

(* Add String.equals method *)
let () =
  let equals_method = {
    meth_name = "equals";
    meth_type = Tboolean;
    meth_params = [{ var_name = "s"; var_type = Tclass class_String; var_ofs = 0 }];
    meth_ofs = 0;
  } in
  Hashtbl.add class_String.class_methods "equals" equals_method

(* Global environment *)
type env = {
  classes : (string, class_) Hashtbl.t;
  current_class : class_ ref;
  variables : (string, var) Hashtbl.t;
  return_type : typ ref;
  constructors : (string, var list option) Hashtbl.t;  (* class_name -> constructor params *)
}

let create_env () = {
  classes = Hashtbl.create 16;
  current_class = ref class_Object;
  variables = Hashtbl.create 16;
  return_type = ref Tvoid;
  constructors = Hashtbl.create 16;
}

let find_class env name =
  try Hashtbl.find env.classes name
  with Not_found -> error "unknown class %s" name

(* Subtyping *)
let rec subtype t1 t2 =
  match t1, t2 with
  | Tboolean, Tboolean | Tint, Tint | Tvoid, Tvoid -> true
  | Tnull, Tclass _ -> true
  | Tnull, Tnull -> true
  | Tclass c1, Tclass c2 -> subclass c1 c2
  | _ -> false

and subclass c1 c2 =
  c1.class_name = c2.class_name ||
  (c1.class_name <> "Object" && subclass c1.class_extends c2)

let compatible t1 t2 = subtype t1 t2 || subtype t2 t1

(* Find method in class hierarchy *)
let rec find_method c name =
  try
    Hashtbl.find c.class_methods name
  with Not_found ->
    if c.class_name = "Object" then raise Not_found
    else find_method c.class_extends name

(* Find attribute in class hierarchy *)
let rec find_attribute c name =
  try
    Hashtbl.find c.class_attributes name
  with Not_found ->
    if c.class_name = "Object" then raise Not_found
    else find_attribute c.class_extends name

(* Convert pexpr_typ to typ *)
let rec ptype_to_type env pt loc =
  match pt with
  | PTboolean -> Tboolean
  | PTint -> Tint
  | PTident id ->
      let c = find_class env id.id in
      Tclass c

(* Type checking for expressions *)
let rec type_expr env e =
  let desc, typ = match e.pexpr_desc with
    | PEconstant c ->
        let t = match c with
          | Cbool _ -> Tboolean
          | Cint _ -> Tint
          | Cstring _ -> Tclass class_String
        in
        Econstant c, t

    | PEthis ->
        Ethis, Tclass !(env.current_class)

    | PEnull ->
        Enull, Tnull

    | PEident id ->
        (try
          let v = Hashtbl.find env.variables id.id in
          Evar v, v.var_type
        with Not_found ->
          try
            let c = !(env.current_class) in
            let a = find_attribute c id.id in
            Eattr ({ expr_desc = Ethis; expr_type = Tclass c }, a), a.attr_type
          with Not_found ->
            error ~loc:e.pexpr_loc "unbound variable %s" id.id)

    | PEdot (e1, id) ->
        let te1 = type_expr env e1 in
        (match te1.expr_type with
        | Tclass c ->
            (try
              let a = find_attribute c id.id in
              Eattr (te1, a), a.attr_type
            with Not_found ->
              error ~loc:e.pexpr_loc "unknown attribute %s" id.id)
        | _ -> error ~loc:e.pexpr_loc "object expected")

    | PEassign_ident (id, e2) ->
        let te2 = type_expr env e2 in
        (try
          let v = Hashtbl.find env.variables id.id in
          if not (subtype te2.expr_type v.var_type) then
            error ~loc:e.pexpr_loc "type mismatch in assignment";
          Eassign_var (v, te2), v.var_type
        with Not_found ->
          try
            let c = !(env.current_class) in
            let a = find_attribute c id.id in
            if not (subtype te2.expr_type a.attr_type) then
              error ~loc:e.pexpr_loc "type mismatch in assignment";
            Eassign_attr ({ expr_desc = Ethis; expr_type = Tclass c }, a, te2), a.attr_type
          with Not_found ->
            error ~loc:e.pexpr_loc "unbound variable %s" id.id)

    | PEassign_dot (e1, id, e2) ->
        let te1 = type_expr env e1 in
        let te2 = type_expr env e2 in
        (match te1.expr_type with
        | Tclass c ->
            (try
              let a = find_attribute c id.id in
              if not (subtype te2.expr_type a.attr_type) then
                error ~loc:e.pexpr_loc "type mismatch in assignment";
              Eassign_attr (te1, a, te2), a.attr_type
            with Not_found ->
              error ~loc:e.pexpr_loc "unknown attribute %s" id.id)
        | _ -> error ~loc:e.pexpr_loc "object expected")

    | PEunop (op, e1) ->
        let te1 = type_expr env e1 in
        (match op with
        | Uneg ->
            if te1.expr_type <> Tint then
              error ~loc:e.pexpr_loc "integer expected";
            Eunop (op, te1), Tint
        | Unot ->
            if te1.expr_type <> Tboolean then
              error ~loc:e.pexpr_loc "boolean expected";
            Eunop (op, te1), Tboolean
        | Ustring_of_int ->
            Eunop (op, te1), Tclass class_String)

    | PEbinop (op, e1, e2) ->
        let te1 = type_expr env e1 in
        let te2 = type_expr env e2 in
        (match op with
        | Badd ->
            if te1.expr_type = Tint && te2.expr_type = Tint then
              Ebinop (op, te1, te2), Tint
            else if (match te1.expr_type with Tclass c -> c.class_name = "String" | _ -> false) ||
                    (match te2.expr_type with Tclass c -> c.class_name = "String" | _ -> false) then
              (* Check that both operands are int or String *)
              let is_valid_for_concat t =
                t = Tint || (match t with Tclass c -> c.class_name = "String" | _ -> false)
              in
              if not (is_valid_for_concat te1.expr_type && is_valid_for_concat te2.expr_type) then
                error ~loc:e.pexpr_loc "can only concatenate int or string with string";
              let te1 = if te1.expr_type = Tint then
                { expr_desc = Eunop (Ustring_of_int, te1); expr_type = Tclass class_String }
              else te1 in
              let te2 = if te2.expr_type = Tint then
                { expr_desc = Eunop (Ustring_of_int, te2); expr_type = Tclass class_String }
              else te2 in
              Ebinop (Badd_s, te1, te2), Tclass class_String
            else
              error ~loc:e.pexpr_loc "integer or string expected"
        | Bsub | Bmul | Bdiv | Bmod ->
            if te1.expr_type <> Tint || te2.expr_type <> Tint then
              error ~loc:e.pexpr_loc "integer expected";
            Ebinop (op, te1, te2), Tint
        | Blt | Ble | Bgt | Bge ->
            if te1.expr_type <> Tint || te2.expr_type <> Tint then
              error ~loc:e.pexpr_loc "integer expected";
            Ebinop (op, te1, te2), Tboolean
        | Beq | Bneq ->
            if not (compatible te1.expr_type te2.expr_type) then
              error ~loc:e.pexpr_loc "incompatible types";
            Ebinop (op, te1, te2), Tboolean
        | Band | Bor ->
            if te1.expr_type <> Tboolean || te2.expr_type <> Tboolean then
              error ~loc:e.pexpr_loc "boolean expected";
            Ebinop (op, te1, te2), Tboolean
        | Badd_s ->
            Ebinop (op, te1, te2), Tclass class_String)

    | PEcall (e1, id, args) ->
        let te1 = type_expr env e1 in
        let targs = List.map (type_expr env) args in
        (match te1.expr_type with
        | Tclass c ->
            (try
              let m = find_method c id.id in
              if List.length m.meth_params <> List.length targs then
                error ~loc:e.pexpr_loc "wrong number of arguments";
              List.iter2 (fun v te ->
                if not (subtype te.expr_type v.var_type) then
                  error ~loc:e.pexpr_loc "type mismatch in argument"
              ) m.meth_params targs;
              Ecall (te1, m, targs), m.meth_type
            with Not_found ->
              error ~loc:e.pexpr_loc "unknown method %s" id.id)
        | _ -> error ~loc:e.pexpr_loc "object expected")

    | PEnew (id, args) ->
        let c = find_class env id.id in
        let targs = List.map (type_expr env) args in
        (* Check constructor parameters *)
        (match Hashtbl.find_opt env.constructors c.class_name with
        | Some (Some params) ->
            (* Constructor is defined with parameters *)
            if List.length targs <> List.length params then
              error ~loc:e.pexpr_loc "constructor %s expects %d arguments, got %d"
                c.class_name (List.length params) (List.length targs);
            List.iter2 (fun targ param ->
              if not (subtype targ.expr_type param.var_type) then
                error ~loc:e.pexpr_loc "type mismatch in constructor argument"
            ) targs params
        | Some None | None ->
            (* No constructor defined, or default constructor *)
            if List.length targs <> 0 then
              error ~loc:e.pexpr_loc "constructor %s expects 0 arguments, got %d"
                c.class_name (List.length targs));
        Enew (c, targs), Tclass c

    | PEcast (pt, e1) ->
        let t = ptype_to_type env pt e.pexpr_loc in
        let te1 = type_expr env e1 in
        (match t with
        | Tint ->
            if te1.expr_type <> Tint then
              error ~loc:e.pexpr_loc "integer expected";
            te1.expr_desc, Tint
        | Tboolean ->
            if te1.expr_type <> Tboolean then
              error ~loc:e.pexpr_loc "boolean expected";
            te1.expr_desc, Tboolean
        | Tclass c ->
            (match te1.expr_type with
            | Tnull ->
                Ecast (c, te1), Tclass c
            | Tclass c1 ->
                (* Check that cast is valid (c and c1 must be in same hierarchy) *)
                if not (subclass c c1 || subclass c1 c) then
                  error ~loc:e.pexpr_loc "incompatible cast";
                Ecast (c, te1), Tclass c
            | _ -> error ~loc:e.pexpr_loc "object expected")
        | _ -> error ~loc:e.pexpr_loc "unsupported cast")

    | PEinstanceof (e1, pt) ->
        let te1 = type_expr env e1 in
        let t = ptype_to_type env pt e.pexpr_loc in
        (match t with
        | Tclass c ->
            (match te1.expr_type with
            | Tnull ->
                Einstanceof (te1, c.class_name), Tboolean
            | Tclass c1 ->
                (* Check that classes are in same hierarchy *)
                if not (subclass c c1 || subclass c1 c) then
                  error ~loc:e.pexpr_loc "incompatible instanceof check";
                Einstanceof (te1, c.class_name), Tboolean
            | _ -> error ~loc:e.pexpr_loc "object expected")
        | _ -> error ~loc:e.pexpr_loc "class expected")
  in
  { expr_desc = desc; expr_type = typ }

(* Special handling for System.out.print *)
let rec is_print_call e =
  match e.pexpr_desc with
  | PEcall (obj, id, args) when id.id = "print" ->
      (match obj.pexpr_desc with
      | PEdot (sys, out_id) when out_id.id = "out" ->
          (match sys.pexpr_desc with
          | PEident system when system.id = "System" -> Some args
          | _ -> None)
      | _ -> None)
  | _ -> None

(* Check if a statement definitely returns *)
let rec stmt_returns s =
  match s with
  | Sblock stmts -> List.exists stmt_returns stmts
  | Sif (_, s1, s2) -> stmt_returns s1 && stmt_returns s2
  | Sreturn _ -> true
  | _ -> false

(* Type checking for statements *)
let rec type_stmt env s =
  match s.pstmt_desc with
  | PSblock stmts ->
      let old_vars = Hashtbl.copy env.variables in
      let tstmts = List.map (type_stmt env) stmts in
      Hashtbl.clear env.variables;
      Hashtbl.iter (Hashtbl.add env.variables) old_vars;
      Sblock tstmts

  | PSexpr e ->
      (match is_print_call e with
      | Some [arg] ->
          let te = type_expr env arg in
          (match te.expr_type with
          | Tclass c when c.class_name = "String" ->
              Sexpr { expr_desc = Eprint te; expr_type = Tvoid }
          | Tint ->
              let te = { expr_desc = Eunop (Ustring_of_int, te); expr_type = Tclass class_String } in
              Sexpr { expr_desc = Eprint te; expr_type = Tvoid }
          | _ -> error ~loc:s.pstmt_loc "string or int expected for print")
      | Some _ -> error ~loc:s.pstmt_loc "print expects one argument"
      | None ->
          let te = type_expr env e in
          Sexpr te)

  | PSvar (pt, id, init) ->
      let t = ptype_to_type env pt s.pstmt_loc in
      if Hashtbl.mem env.variables id.id then
        error ~loc:s.pstmt_loc "variable %s already declared" id.id;
      let v = { var_name = id.id; var_type = t; var_ofs = 0 } in
      Hashtbl.add env.variables id.id v;
      (match init with
      | None ->
          let init_val = match t with
            | Tboolean -> { expr_desc = Econstant (Cbool false); expr_type = Tboolean }
            | Tint -> { expr_desc = Econstant (Cint Int32.zero); expr_type = Tint }
            | _ -> { expr_desc = Enull; expr_type = Tnull }
          in
          Svar (v, init_val)
      | Some e ->
          let te = type_expr env e in
          if not (subtype te.expr_type t) then
            error ~loc:s.pstmt_loc "type mismatch in initialization";
          Svar (v, te))

  | PSif (e, s1, s2) ->
      let te = type_expr env e in
      if te.expr_type <> Tboolean then
        error ~loc:s.pstmt_loc "boolean expected";
      (* Each branch has its own scope *)
      let old_vars = Hashtbl.copy env.variables in
      let ts1 = type_stmt env s1 in
      Hashtbl.clear env.variables;
      Hashtbl.iter (fun k v -> Hashtbl.add env.variables k v) old_vars;
      let ts2 = type_stmt env s2 in
      Hashtbl.clear env.variables;
      Hashtbl.iter (fun k v -> Hashtbl.add env.variables k v) old_vars;
      Sif (te, ts1, ts2)

  | PSfor (init, cond, incr, body) ->
      let old_vars = Hashtbl.copy env.variables in
      let tinit = type_stmt env init in
      let tcond = type_expr env cond in
      if tcond.expr_type <> Tboolean then
        error ~loc:s.pstmt_loc "boolean expected";
      let tincr = type_stmt env incr in
      let tbody = type_stmt env body in
      Hashtbl.clear env.variables;
      Hashtbl.iter (Hashtbl.add env.variables) old_vars;
      Sfor (tinit, tcond, tincr, tbody)

  | PSreturn None ->
      if !(env.return_type) <> Tvoid then
        error ~loc:s.pstmt_loc "return value expected";
      Sreturn None

  | PSreturn (Some e) ->
      let te = type_expr env e in
      if not (subtype te.expr_type !(env.return_type)) then
        error ~loc:s.pstmt_loc "type mismatch in return";
      Sreturn (Some te)

(* Phase 1: Declare all classes *)
let declare_classes pfile =
  let env = create_env () in
  Hashtbl.add env.classes "Object" class_Object;
  Hashtbl.add env.classes "String" class_String;

  (* Create all class structures *)
  List.iter (fun (id, _, _) ->
    if Hashtbl.mem env.classes id.id then
      error ~loc:id.loc "class %s already declared" id.id;
    let c = {
      class_name = id.id;
      class_extends = class_Object;  (* default *)
      class_methods = Hashtbl.create 16;
      class_attributes = Hashtbl.create 16;
    } in
    Hashtbl.add env.classes id.id c
  ) pfile;

  env

(* Phase 2: Set inheritance and check for cycles *)
let set_inheritance env pfile =
  List.iter (fun (id, ext, _) ->
    let c = Hashtbl.find env.classes id.id in
    match ext with
    | None -> c.class_extends <- class_Object
    | Some ext_id ->
        if ext_id.id = "String" then
          error ~loc:ext_id.loc "cannot inherit from String";
        let parent = find_class env ext_id.id in
        c.class_extends <- parent
  ) pfile;

  (* Check for cycles *)
  let rec has_cycle c visited =
    if List.mem c.class_name visited then true
    else if c.class_name = "Object" then false
    else has_cycle c.class_extends (c.class_name :: visited)
  in
  List.iter (fun (id, _, _) ->
    let c = Hashtbl.find env.classes id.id in
    if has_cycle c [] then
      error ~loc:id.loc "cyclic inheritance for class %s" id.id
  ) pfile

(* Phase 3a: Declare attributes and methods (without override checking) *)
let declare_members env pfile =
  List.iter (fun (id, _, decls) ->
    let c = Hashtbl.find env.classes id.id in
    env.current_class := c;

    (* Copy inherited attributes *)
    if c.class_name <> "Object" && c.class_extends.class_name <> "Object" then begin
      Hashtbl.iter (fun name attr ->
        Hashtbl.add c.class_attributes name attr
      ) c.class_extends.class_attributes
    end;

    (* Process declarations *)
    let has_constructor = ref false in
    let defined_methods = Hashtbl.create 16 in  (* Track methods defined in THIS class *)
    List.iter (function
      | PDattribute (pt, attr_id) ->
          if Hashtbl.mem c.class_attributes attr_id.id then
            error ~loc:attr_id.loc "attribute %s already declared" attr_id.id;
          let t = ptype_to_type env pt attr_id.loc in
          let a = { attr_name = attr_id.id; attr_type = t; attr_ofs = 0 } in
          Hashtbl.add c.class_attributes attr_id.id a
      | PDmethod (ret_opt, meth_id, params, _) ->
          let ret = match ret_opt with
            | None -> Tvoid
            | Some pt -> ptype_to_type env pt meth_id.loc
          in
          (* Check for duplicate parameters *)
          let param_names = Hashtbl.create 16 in
          let param_vars = List.map (fun (pt, param_id) ->
            if Hashtbl.mem param_names param_id.id then
              error ~loc:param_id.loc "duplicate parameter %s" param_id.id;
            Hashtbl.add param_names param_id.id ();
            let t = ptype_to_type env pt param_id.loc in
            { var_name = param_id.id; var_type = t; var_ofs = 0 }
          ) params in
          let m = {
            meth_name = meth_id.id;
            meth_type = ret;
            meth_params = param_vars;
            meth_ofs = 0;
          } in
          (* Check if method already defined in THIS class *)
          if Hashtbl.mem defined_methods meth_id.id then
            error ~loc:meth_id.loc "method %s already declared" meth_id.id;
          Hashtbl.add defined_methods meth_id.id ();
          Hashtbl.add c.class_methods meth_id.id m
      | PDconstructor (id, params, _) ->
          if id.id <> c.class_name then
            error ~loc:id.loc "constructor name must match class name";
          if !has_constructor then
            error ~loc:id.loc "multiple constructors declared";
          has_constructor := true;
          (* Store constructor parameters *)
          let param_vars = List.map (fun (pt, param_id) ->
            let t = ptype_to_type env pt param_id.loc in
            { var_name = param_id.id; var_type = t; var_ofs = 0 }
          ) params in
          Hashtbl.replace env.constructors c.class_name (Some param_vars)
    ) decls
  ) pfile

(* Phase 3b: Check method overrides *)
let check_overrides env pfile =
  List.iter (fun (id, _, decls) ->
    let c = Hashtbl.find env.classes id.id in
    List.iter (function
      | PDmethod (_, meth_id, _, _) ->
          if c.class_name <> "Object" then begin
            try
              let m = Hashtbl.find c.class_methods meth_id.id in
              let parent_m = find_method c.class_extends meth_id.id in
              (* Check overriding compatibility *)
              if parent_m.meth_type <> m.meth_type ||
                 List.length parent_m.meth_params <> List.length m.meth_params ||
                 not (List.for_all2 (fun v1 v2 -> v1.var_type = v2.var_type)
                       parent_m.meth_params m.meth_params) then
                error ~loc:meth_id.loc "incompatible override of method %s" meth_id.id
            with Not_found -> ()
          end
      | _ -> ()
    ) decls
  ) pfile

(* Phase 4: Type check method and constructor bodies *)
let type_check_bodies env pfile =
  List.map (fun (id, _, decls) ->
    let c = Hashtbl.find env.classes id.id in
    env.current_class := c;

    let typed_decls = List.map (function
      | PDattribute _ -> None
      | PDconstructor (_, params, body) ->
          Hashtbl.clear env.variables;
          env.return_type := Tvoid;
          (* Check for duplicate parameters *)
          let param_names = Hashtbl.create 16 in
          let param_vars = List.map (fun (pt, param_id) ->
            if Hashtbl.mem param_names param_id.id then
              error ~loc:param_id.loc "duplicate parameter %s" param_id.id;
            Hashtbl.add param_names param_id.id ();
            let t = ptype_to_type env pt param_id.loc in
            let v = { var_name = param_id.id; var_type = t; var_ofs = 0 } in
            Hashtbl.add env.variables param_id.id v;
            v
          ) params in
          let tbody = type_stmt env body in
          Some (Dconstructor (param_vars, tbody))
      | PDmethod (ret_opt, meth_id, params, body) ->
          Hashtbl.clear env.variables;
          let m = Hashtbl.find c.class_methods meth_id.id in
          env.return_type := m.meth_type;
          List.iter (fun v ->
            Hashtbl.add env.variables v.var_name v
          ) m.meth_params;
          let tbody = type_stmt env body in
          (* Check if non-void method has return statement *)
          if m.meth_type <> Tvoid && not (stmt_returns tbody) then
            error ~loc:meth_id.loc "missing return statement";
          Some (Dmethod (m, tbody))
    ) decls in

    (c, List.filter_map (fun x -> x) typed_decls)
  ) pfile

let file ?debug:(b=false) (p: Ast.pfile) : Ast.tfile =
  debug := b;
  let env = declare_classes p in
  set_inheritance env p;
  declare_members env p;
  check_overrides env p;
  type_check_bodies env p
