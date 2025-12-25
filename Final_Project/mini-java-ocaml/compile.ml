
open Format
open X86_64
open Ast

let debug = ref false

(* Label counter *)
let label_counter = ref 0
let new_label () =
  incr label_counter;
  sprintf "L%d" !label_counter

(* String counter and table *)
let string_counter = ref 0
let string_table = Hashtbl.create 16

let add_string s =
  try
    Hashtbl.find string_table s
  with Not_found ->
    incr string_counter;
    let label = sprintf "S%d" !string_counter in
    Hashtbl.add string_table s label;
    label

(* Environment for compilation *)
type compile_env = {
  mutable stack_offset: int;  (* Current offset from %rbp *)
  local_vars: (string, int) Hashtbl.t;  (* variable name -> offset from %rbp *)
}

let create_compile_env () = {
  stack_offset = -8;  (* Start after saved %rbp *)
  local_vars = Hashtbl.create 16;
}

(* Allocate space for a local variable *)
let alloc_var env name =
  let ofs = env.stack_offset in
  Hashtbl.add env.local_vars name ofs;
  env.stack_offset <- env.stack_offset - 8;
  ofs

(* Get variable offset *)
let get_var_offset env name =
  try Hashtbl.find env.local_vars name
  with Not_found -> failwith ("Unknown variable: " ^ name)

(* Calculate attribute offset *)
let compute_attribute_offsets c =
  let ofs = ref 8 in  (* Skip class descriptor pointer *)
  let rec add_attrs parent =
    if parent.class_name <> "Object" then
      add_attrs parent.class_extends;
    (* Convert hashtbl to list and sort by declaration order *)
    let attrs = Hashtbl.fold (fun name attr acc -> (name, attr) :: acc) parent.class_attributes [] in
    let sorted_attrs = List.sort (fun (_, a1) (_, a2) -> compare a1.attr_decl_order a2.attr_decl_order) attrs in
    List.iter (fun (name, attr) ->
      if attr.attr_ofs = 0 then begin
        attr.attr_ofs <- !ofs;
      end;
      (* Update ofs to be after this attribute, even if already set *)
      if attr.attr_ofs + 8 > !ofs then
        ofs := attr.attr_ofs + 8
    ) sorted_attrs
  in
  add_attrs c;
  !ofs

(* Calculate method offsets *)
let compute_method_offsets c =
  let ofs = ref 8 in  (* Skip parent descriptor pointer *)

  (* First, collect parent method offsets to handle overriding *)
  let parent_method_offsets = Hashtbl.create 16 in
  let rec collect_parent_offsets parent =
    if parent.class_name <> "Object" then begin
      collect_parent_offsets parent.class_extends;
      (* Convert to list and sort for deterministic ordering *)
      let parent_meths = Hashtbl.fold (fun name meth acc -> (name, meth) :: acc) parent.class_methods [] in
      let sorted_parent_meths = List.sort (fun (n1, _) (n2, _) -> String.compare n1 n2) parent_meths in
      List.iter (fun (name, meth) ->
        (* Ensure parent method has offset *)
        if meth.meth_ofs = 0 then begin
          meth.meth_ofs <- !ofs;
          ofs := !ofs + 8
        end;
        (* Record offset for this method name *)
        if not (Hashtbl.mem parent_method_offsets name) then
          Hashtbl.add parent_method_offsets name meth.meth_ofs;
        (* Update max offset *)
        if meth.meth_ofs + 8 > !ofs then
          ofs := meth.meth_ofs + 8
      ) sorted_parent_meths
    end
  in

  if c.class_name <> "Object" then
    collect_parent_offsets c.class_extends;

  (* Process current class methods *)
  let meths = Hashtbl.fold (fun name meth acc -> (name, meth) :: acc) c.class_methods [] in
  let sorted_meths = List.sort (fun (n1, _) (n2, _) -> String.compare n1 n2) meths in
  List.iter (fun (name, meth) ->
    (* Check if this method overrides a parent method *)
    try
      let parent_offset = Hashtbl.find parent_method_offsets name in
      (* Always use parent offset for overriding methods *)
      meth.meth_ofs <- parent_offset;
      if parent_offset + 8 > !ofs then
        ofs := parent_offset + 8
    with Not_found ->
      (* New method, assign offset if not already set *)
      if meth.meth_ofs = 0 then begin
        meth.meth_ofs <- !ofs;
        ofs := !ofs + 8
      end else begin
        if meth.meth_ofs + 8 > !ofs then
          ofs := meth.meth_ofs + 8
      end
  ) sorted_meths;

  !ofs

(* Compile an expression *)
let rec compile_expr env e =
  match e.expr_desc with
  | Econstant c ->
      (match c with
      | Cbool b -> movq (imm (if b then 1 else 0)) (reg rax)
      | Cint n -> movq (imm32 n) (reg rax)
      | Cstring s ->
          let lbl = add_string s in
          leaq (lab lbl) rax)

  | Ethis ->
      (* 'this' is at 16(%rbp) - first parameter *)
      movq (ind ~ofs:16 rbp) (reg rax)

  | Enull ->
      xorq (reg rax) (reg rax)

  | Evar v ->
      let ofs = get_var_offset env v.var_name in
      movq (ind ~ofs rbp) (reg rax)

  | Eassign_var (v, e1) ->
      let code = compile_expr env e1 in
      let ofs = get_var_offset env v.var_name in
      code ++
      movq (reg rax) (ind ~ofs rbp)

  | Eattr (obj, attr) ->
      compile_expr env obj ++
      movq (ind ~ofs:attr.attr_ofs rax) (reg rax)

  | Eassign_attr (obj, attr, e1) ->
      compile_expr env obj ++
      pushq (reg rax) ++
      compile_expr env e1 ++
      popq rbx ++
      movq (reg rax) (ind ~ofs:attr.attr_ofs rbx)

  | Eunop (op, e1) ->
      let code = compile_expr env e1 in
      (match op with
      | Uneg -> code ++ negq (reg rax)
      | Unot ->
          code ++
          xorq (reg rbx) (reg rbx) ++
          testq (reg rax) (reg rax) ++
          sete (reg (register8 rbx)) ++
          movq (reg rbx) (reg rax)
      | Ustring_of_int ->
          (* Allocate 32 bytes for the string *)
          code ++
          movq (reg rax) (reg r12) ++  (* Save integer value to r12 (callee-saved) *)
          movq (imm 32) (reg rdi) ++
          call "my_malloc" ++
          (* Store class descriptor *)
          leaq (lab "class_String") rbx ++
          movq (reg rbx) (ind rax) ++
          (* Convert integer to string *)
          pushq (reg rax) ++  (* Save string object *)
          leaq (ind ~ofs:8 rax) rdi ++  (* destination -> rdi *)
          leaq (lab "int_format") rsi ++  (* format -> rsi *)
          movq (reg r12) (reg rdx) ++  (* integer value -> rdx *)
          xorq (reg rax) (reg rax) ++
          call "my_sprintf" ++
          popq rax  (* Restore string object *))

  | Ebinop (op, e1, e2) ->
      let code1 = compile_expr env e1 in
      let code2 = compile_expr env e2 in
      (match op with
      | Badd ->
          code1 ++
          pushq (reg rax) ++
          code2 ++
          popq rbx ++
          addq (reg rbx) (reg rax)
      | Bsub ->
          code1 ++
          pushq (reg rax) ++
          code2 ++
          movq (reg rax) (reg rbx) ++
          popq rax ++
          subq (reg rbx) (reg rax)
      | Bmul ->
          code1 ++
          pushq (reg rax) ++
          code2 ++
          popq rbx ++
          imulq (reg rbx) (reg rax)
      | Bdiv | Bmod ->
          code1 ++
          pushq (reg rax) ++
          code2 ++
          movq (reg rax) (reg rbx) ++
          popq rax ++
          cqto ++
          idivq (reg rbx) ++
          (if op = Bmod then movq (reg rdx) (reg rax) else nop)
      | Beq | Bneq | Blt | Ble | Bgt | Bge ->
          code1 ++
          pushq (reg rax) ++
          code2 ++
          popq rbx ++
          xorq (reg rcx) (reg rcx) ++
          cmpq (reg rax) (reg rbx) ++
          (match op with
          | Beq -> sete (reg (register8 rcx))
          | Bneq -> setne (reg (register8 rcx))
          | Blt -> setl (reg (register8 rcx))
          | Ble -> setle (reg (register8 rcx))
          | Bgt -> setg (reg (register8 rcx))
          | Bge -> setge (reg (register8 rcx))
          | _ -> nop) ++
          movq (reg rcx) (reg rax)
      | Band ->
          let lfalse = new_label () in
          let lend = new_label () in
          code1 ++
          testq (reg rax) (reg rax) ++
          jz lfalse ++
          code2 ++
          testq (reg rax) (reg rax) ++
          jz lfalse ++
          movq (imm 1) (reg rax) ++
          jmp lend ++
          label lfalse ++
          xorq (reg rax) (reg rax) ++
          label lend
      | Bor ->
          let ltrue = new_label () in
          let lend = new_label () in
          code1 ++
          testq (reg rax) (reg rax) ++
          jnz ltrue ++
          code2 ++
          testq (reg rax) (reg rax) ++
          jnz ltrue ++
          xorq (reg rax) (reg rax) ++
          jmp lend ++
          label ltrue ++
          movq (imm 1) (reg rax) ++
          label lend
      | Badd_s ->
          (* String concatenation *)
          code1 ++
          pushq (reg rax) ++
          code2 ++
          movq (reg rax) (reg rsi) ++
          popq rdi ++
          call "my_strcat" ++
          movq (reg rax) (reg rax))

  | Enew (c, args) ->
      (* Allocate object *)
      let size = compute_attribute_offsets c in
      movq (imm size) (reg rdi) ++
      call "my_malloc" ++
      (* Store class descriptor *)
      pushq (reg rax) ++
      leaq (lab ("class_" ^ c.class_name)) rbx ++
      popq rax ++
      movq (reg rbx) (ind rax) ++
      (* Always try to call constructor (will fail at link time if not defined) *)
      pushq (reg rax) ++
      (* Push arguments *)
      List.fold_left (fun code arg ->
        code ++
        compile_expr env arg ++
        pushq (reg rax)
      ) nop (List.rev args) ++
      (* Push 'this' *)
      movq (ind ~ofs:((List.length args) * 8) rsp) (reg rdi) ++
      pushq (reg rdi) ++
      (* Call constructor *)
      call (c.class_name ^ "_constructor") ++
      (* Clean up stack *)
      addq (imm ((List.length args + 1) * 8)) (reg rsp) ++
      popq rax

  | Ecall (obj, meth, args) ->
      (* Evaluate object *)
      compile_expr env obj ++
      pushq (reg rax) ++
      (* Push arguments *)
      List.fold_left (fun code arg ->
        code ++
        compile_expr env arg ++
        pushq (reg rax)
      ) nop (List.rev args) ++
      (* Push 'this' *)
      movq (ind ~ofs:((List.length args) * 8) rsp) (reg rdi) ++
      pushq (reg rdi) ++
      (* Get method from vtable *)
      movq (ind ~ofs:0 rdi) (reg rbx) ++
      (* Use offset 8 for predefined methods (String.equals) if offset is 0 *)
      let method_offset = if meth.meth_ofs = 0 then 8 else meth.meth_ofs in
      movq (ind ~ofs:method_offset rbx) (reg rbx) ++
      call_star (reg rbx) ++
      (* Clean up stack *)
      addq (imm ((List.length args + 1) * 8)) (reg rsp) ++
      popq rbx

  | Ecast (c, e1) ->
      let lok_null = new_label () in
      let lok = new_label () in
      let lcheck = new_label () in
      let lfail = new_label () in
      compile_expr env e1 ++
      (* Check for null *)
      testq (reg rax) (reg rax) ++
      jz lok_null ++  (* Jump to separate label for null case *)
      (* Check class *)
      pushq (reg rax) ++
      movq (ind rax) (reg rbx) ++
      leaq (lab ("class_" ^ c.class_name)) rcx ++
      label lcheck ++
      (* Check if reached end of class hierarchy (null) *)
      testq (reg rbx) (reg rbx) ++
      jz lfail ++
      (* Compare current class with target class *)
      cmpq (reg rcx) (reg rbx) ++
      je lok ++
      (* Move to parent class *)
      movq (ind rbx) (reg rbx) ++
      jmp lcheck ++
      label lfail ++
      (* Cast failed *)
      leaq (lab "cast_error") rdi ++
      call "my_puts" ++
      movq (imm 1) (reg rdi) ++
      call "exit" ++
      label lok ++
      popq rax ++
      label lok_null  (* Null value ends up here without popping *)

  | Einstanceof (e1, classname) ->
      let ltrue = new_label () in
      let lfalse = new_label () in
      let lend = new_label () in
      let lcheck = new_label () in
      compile_expr env e1 ++
      (* Check for null *)
      testq (reg rax) (reg rax) ++
      jz lfalse ++
      (* Check class *)
      movq (ind rax) (reg rbx) ++
      leaq (lab ("class_" ^ classname)) rcx ++
      label lcheck ++
      (* Check if reached end of class hierarchy (null) *)
      testq (reg rbx) (reg rbx) ++
      jz lfalse ++
      (* Compare current class with target class *)
      cmpq (reg rcx) (reg rbx) ++
      je ltrue ++
      (* Move to parent class *)
      movq (ind rbx) (reg rbx) ++
      jmp lcheck ++
      label lfalse ++
      xorq (reg rax) (reg rax) ++
      jmp lend ++
      label ltrue ++
      movq (imm 1) (reg rax) ++
      label lend

  | Eprint e1 ->
      compile_expr env e1 ++
      leaq (ind ~ofs:8 rax) rsi ++  (* string -> %rsi (second arg) *)
      leaq (lab "string_format") rdi ++  (* "%s" -> %rdi (first arg) *)
      xorq (reg rax) (reg rax) ++  (* no vector registers used *)
      call "my_printf"

(* Compile a statement *)
let rec compile_stmt env s =
  match s with
  | Sexpr e ->
      compile_expr env e

  | Svar (v, e) ->
      let ofs = alloc_var env v.var_name in
      v.var_ofs <- ofs;
      compile_expr env e ++
      movq (reg rax) (ind ~ofs rbp)

  | Sif (e, s1, s2) ->
      let lelse = new_label () in
      let lend = new_label () in
      compile_expr env e ++
      testq (reg rax) (reg rax) ++
      jz lelse ++
      compile_stmt env s1 ++
      jmp lend ++
      label lelse ++
      compile_stmt env s2 ++
      label lend

  | Sreturn None ->
      movq (reg rbp) (reg rsp) ++
      popq rbp ++
      ret

  | Sreturn (Some e) ->
      compile_expr env e ++
      movq (reg rbp) (reg rsp) ++
      popq rbp ++
      ret

  | Sblock stmts ->
      List.fold_left (fun code s ->
        code ++ compile_stmt env s
      ) nop stmts

  | Sfor (init, cond, incr, body) ->
      let lstart = new_label () in
      let lend = new_label () in
      compile_stmt env init ++
      label lstart ++
      compile_expr env cond ++
      testq (reg rax) (reg rax) ++
      jz lend ++
      compile_stmt env body ++
      compile_stmt env incr ++
      jmp lstart ++
      label lend

(* Compile a method or constructor *)
let compile_method class_name method_name is_constructor params body =
  let env = create_compile_env () in

  (* Set up parameter offsets (they are on the stack) *)
  (* 'this' is at 16(%rbp), explicit parameters start at 24(%rbp) *)
  let param_ofs = ref 24 in  (* Skip return address, saved %rbp, and implicit 'this' *)
  List.iter (fun v ->
    v.var_ofs <- !param_ofs;
    Hashtbl.add env.local_vars v.var_name !param_ofs;
    param_ofs := !param_ofs + 8
  ) params;

  let full_method_name =
    if is_constructor then class_name ^ "_constructor"
    else class_name ^ "_" ^ method_name
  in

  (* Compile body first to know how much stack space we need *)
  let body_code = compile_stmt env body in
  let stack_size = -(env.stack_offset + 8) in  (* Total space needed for local vars *)

  label full_method_name ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  (if stack_size > 0 then subq (imm stack_size) (reg rsp) else nop) ++
  body_code ++
  (* Default return for void methods *)
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret

(* Compile class descriptor *)
let compile_class_descriptor c =
  let desc_name = "class_" ^ c.class_name in

  (* Recursively collect all methods from class hierarchy *)
  let rec collect_methods cls =
    let parent_methods =
      if cls.class_name = "Object" then []
      else collect_methods cls.class_extends
    in

    (* Add/override methods from current class *)
    let current_methods = Hashtbl.fold (fun name meth acc ->
      (name, meth, cls.class_name) :: acc
    ) cls.class_methods [] in

    (* Merge: current class methods override parent methods *)
    let merged = List.fold_left (fun acc (name, meth, cls_name) ->
      (* Remove any existing method with this name from acc *)
      let acc' = List.filter (fun (n, _, _) -> n <> name) acc in
      (* Add this method *)
      (name, meth, cls_name) :: acc'
    ) parent_methods current_methods in

    merged
  in

  let all_methods = collect_methods c in
  (* Sort by offset *)
  let sorted_methods = List.sort (fun (_, m1, _) (_, m2, _) ->
    compare m1.meth_ofs m2.meth_ofs
  ) all_methods in

  label desc_name ++
  (* Parent descriptor *)
  (if c.class_name = "Object" then
    inline "\t.quad 0\n"
  else
    inline (sprintf "\t.quad class_%s\n" c.class_extends.class_name)) ++
  (* Method table *)
  List.fold_left (fun code (name, _, cls_name) ->
    code ++ inline (sprintf "\t.quad %s_%s\n" cls_name name)
  ) nop sorted_methods

(* Generate library wrappers *)
let generate_wrappers () =
  (* malloc wrapper *)
  label "my_malloc" ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  andq (imm (-16)) (reg rsp) ++
  call "malloc" ++
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret ++

  (* puts wrapper *)
  label "my_puts" ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  andq (imm (-16)) (reg rsp) ++
  call "puts" ++
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret ++

  (* printf wrapper *)
  label "my_printf" ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  andq (imm (-16)) (reg rsp) ++
  call "printf" ++
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret ++

  (* sprintf wrapper *)
  label "my_sprintf" ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  andq (imm (-16)) (reg rsp) ++
  call "sprintf" ++
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret ++

  (* strcat wrapper *)
  label "my_strcat" ++
  pushq (reg rbp) ++
  movq (reg rsp) (reg rbp) ++
  pushq (reg rdi) ++
  pushq (reg rsi) ++
  (* Calculate total length *)
  leaq (ind ~ofs:8 rdi) rdi ++
  call "strlen" ++
  movq (reg rax) (reg r12) ++
  movq (ind ~ofs:(-16) rbp) (reg rdi) ++
  leaq (ind ~ofs:8 rdi) rdi ++
  call "strlen" ++
  addq (reg r12) (reg rax) ++
  addq (imm 9) (reg rax) ++
  movq (reg rax) (reg rdi) ++
  call "malloc" ++
  (* Copy strings *)
  movq (reg rax) (reg r13) ++
  leaq (lab "class_String") r12 ++
  movq (reg r12) (ind rax) ++
  leaq (ind ~ofs:8 rax) rdi ++
  movq (ind ~ofs:(-8) rbp) (reg rsi) ++
  leaq (ind ~ofs:8 rsi) rsi ++
  call "strcpy" ++
  leaq (ind ~ofs:8 r13) rdi ++
  call "strlen" ++
  addq (reg r13) (reg rax) ++
  addq (imm 8) (reg rax) ++
  movq (reg rax) (reg rdi) ++
  movq (ind ~ofs:(-16) rbp) (reg rsi) ++
  leaq (ind ~ofs:8 rsi) rsi ++
  call "strcat" ++
  movq (reg r13) (reg rax) ++
  movq (reg rbp) (reg rsp) ++
  popq rbp ++
  ret

(* Main compilation function *)
let file ?debug:(b=false) (p: Ast.tfile) : X86_64.program =
  debug := b;

  (* Set up predefined String.equals method offset *)
  (* String is predefined and needs manual offset setup *)
  List.iter (fun (c, _) ->
    if c.class_name = "String" then begin
      try
        let equals_method = Hashtbl.find c.class_methods "equals" in
        equals_method.meth_ofs <- 8
      with Not_found -> ()
    end
  ) p;

  (* Compute offsets *)
  List.iter (fun (c, _) ->
    ignore (compute_attribute_offsets c);
    ignore (compute_method_offsets c)
  ) p;

  (* Generate code for all methods *)
  let text_code = List.fold_left (fun code (c, decls) ->
    let class_code = List.fold_left (fun code decl ->
      match decl with
      | Dconstructor (params, body) ->
          code ++ compile_method c.class_name "" true params body
      | Dmethod (meth, body) ->
          code ++ compile_method c.class_name meth.meth_name false meth.meth_params body
    ) code decls in
    (* Check if constructor exists; if not, generate empty one *)
    let has_constructor = List.exists (function Dconstructor _ -> true | _ -> false) decls in
    if has_constructor || c.class_name = "Object" || c.class_name = "String" then
      class_code
    else
      (* Generate empty constructor *)
      class_code ++
      label (c.class_name ^ "_constructor") ++
      pushq (reg rbp) ++
      movq (reg rsp) (reg rbp) ++
      movq (reg rbp) (reg rsp) ++
      popq rbp ++
      ret
  ) nop p in

  (* Generate Main entry point *)
  let main_code =
    globl "main" ++
    label "main" ++
    pushq (reg rbp) ++
    movq (reg rsp) (reg rbp) ++
    call "Main_main" ++
    xorq (reg rax) (reg rax) ++
    movq (reg rbp) (reg rsp) ++
    popq rbp ++
    ret
  in

  (* Generate predefined class descriptors *)
  let predefined_classes =
    label "class_Object" ++
    inline "\t.quad 0\n" ++
    label "class_String" ++
    inline "\t.quad class_Object\n" ++
    inline "\t.quad String_equals\n"
  in

  (* Generate class descriptors *)
  let data_code = List.fold_left (fun code (c, _) ->
    code ++ compile_class_descriptor c
  ) nop p in

  (* Generate string constants *)
  let string_data = Hashtbl.fold (fun str lbl code ->
    code ++
    label lbl ++
    inline "\t.quad class_String\n" ++
    string str
  ) string_table nop in

  (* Additional data *)
  let extra_data =
    label "int_format" ++
    string "%ld" ++
    label "string_format" ++
    string "%s" ++
    label "cast_error" ++
    string "cast failure"
  in

  (* String.equals implementation *)
  let string_equals =
    label "String_equals" ++
    pushq (reg rbp) ++
    movq (reg rsp) (reg rbp) ++
    (* this is at 16(%rbp), arg is at 24(%rbp) *)
    movq (ind ~ofs:16 rbp) (reg rdi) ++
    leaq (ind ~ofs:8 rdi) rdi ++
    movq (ind ~ofs:24 rbp) (reg rsi) ++
    leaq (ind ~ofs:8 rsi) rsi ++
    call "strcmp" ++
    testq (reg rax) (reg rax) ++
    sete (reg (register8 rax)) ++
    movzbq (reg (register8 rax)) rax ++
    movq (reg rbp) (reg rsp) ++
    popq rbp ++
    ret
  in

  { text = generate_wrappers () ++ text_code ++ main_code ++ string_equals;
    data = predefined_classes ++ data_code ++ string_data ++ extra_data; }
