(* 此程式是我用claude code 生成出來要填的部分 *)
(* 並請他解釋給我聽 *)
(* 注意事項：test.exp裡面沒有for windows的shadow space，所以有修改 *)

(* Code production for the language Arith *)

open Format
open X86_64
open Ast


(* Raise exception when a variable (local or global) is misused *)
exception VarUndef of string

(* Size of the frame, in bytes (each local variable occupies 8 bytes) *)
let frame_size = ref 0

(* Global variables are stored in a hash table *)
let (genv : (string, unit) Hashtbl.t) = Hashtbl.create 17

(* We use an association table whose keys are local variables
   (strings) and whose associated value is the position
   relative to %rbp (in bytes) *)
module StrMap = Map.Make(String)


(* Compilation of an expression *)
let compile_expr =
  (* Recursive local function to generate the machine code
     for the abstract syntax tree associated with a value of type
     Ast.expr ; at the end of the execution of this code, the value must be
     on top of the stack *)
  let rec comprec env next = function
    | Cst i ->
        (* 將整數常數 i 推入堆疊頂端 *)
        (* pushq $i: 將立即數 i 壓入堆疊 *)
        pushq (imm i)
    | Var x ->
        (* 讀取變數 x 的值並推入堆疊 *)
        if StrMap.mem x env then
          (* 情況1: x 是局部變數 (存在於環境 env 中) *)
          (* 從堆疊框架中讀取，位置相對於 %rbp *)
          let offset = StrMap.find x env in  (* 取得變數在堆疊中的偏移量 *)
          pushq (ind ~ofs:offset rbp)        (* pushq offset(%rbp): 將該位置的值推入堆疊 *)
        else if Hashtbl.mem genv x then
          (* 情況2: x 是全局變數 (存在於全局表 genv 中) *)
          (* 從全局記憶體區讀取 *)
          movq (lab x) !%rax ++              (* movq x(%rip), %rax: 將全局變數 x 的值載入 %rax *)
          pushq !%rax                        (* pushq %rax: 將 %rax 的值推入堆疊 *)
        else
          (* 情況3: 變數未定義，拋出異常 *)
          raise (VarUndef x)
    | Binop (o, e1, e2)->
        (* 編譯二元運算: e1 op e2 *)
        (* 注意: 先編譯 e2，再編譯 e1，這樣彈出時順序才正確 *)
        comprec env next e2 ++      (* 遞迴編譯 e2，結果在堆疊頂端 *)
        comprec env next e1 ++      (* 遞迴編譯 e1，結果在堆疊頂端 (在 e2 上方) *)
        popq rax ++                 (* popq %rax: 彈出 e1 的值到 %rax *)
        popq rbx ++                 (* popq %rbx: 彈出 e2 的值到 %rbx *)
        (match o with
         | Add -> addq !%rbx !%rax  (* addq %rbx, %rax: %rax = %rax + %rbx *)
         | Sub -> subq !%rbx !%rax  (* subq %rbx, %rax: %rax = %rax - %rbx *)
         | Mul -> imulq !%rbx !%rax (* imulq %rbx, %rax: %rax = %rax * %rbx (有號乘法) *)
         | Div ->
             (* 除法需要特殊處理: 先將 %rax 符號擴展到 %rdx:%rax *)
             cqto ++                (* cqto: 將 %rax 符號擴展到 %rdx:%rax (128位元) *)
             idivq !%rbx            (* idivq %rbx: %rax = %rdx:%rax / %rbx (有號除法，商存在 %rax) *)
        ) ++
        pushq !%rax                 (* pushq %rax: 將運算結果推入堆疊 *)
    | Letin (x, e1, e2) ->
        (* 編譯 let x = e1 in e2 *)
        (* 這會建立一個新的局部變數 x，其值為 e1，然後在 e2 中可以使用 x *)
        if !frame_size = next then frame_size := 8 + !frame_size;  (* 需要時擴展堆疊框架大小 *)
        comprec env next e1 ++                    (* 遞迴編譯 e1，結果在堆疊頂端 *)
        let new_env = StrMap.add x (-next-8) env in  (* 建立新環境: 將 x 綁定到堆疊位置 -next-8(%rbp) *)
        comprec new_env (next+8) e2 ++            (* 在新環境中遞迴編譯 e2，結果在堆疊頂端 *)
        popq rax ++                               (* popq %rax: 彈出 e2 的結果到 %rax *)
        movq !%rax (ind ~ofs:(-next-8) rbp) ++    (* movq %rax, -next-8(%rbp): 暫時存放 e2 的結果 *)
        popq rbx ++                               (* popq %rbx: 彈出並丟棄 e1 的值 (清理堆疊) *)
        pushq (ind ~ofs:(-next-8) rbp)            (* pushq -next-8(%rbp): 將 e2 的結果推回堆疊頂端 *)
  in
  comprec StrMap.empty 0

(* Compilation of an instruction *)
let compile_instr = function
  | Set (x, e) ->
      (* 編譯 set x = e 指令 *)
      (* 將表達式 e 的值賦給全局變數 x *)
      Hashtbl.replace genv x ();    (* 將 x 註冊為全局變數 (如果已存在則更新) *)
      compile_expr e ++             (* 編譯表達式 e，結果在堆疊頂端 *)
      popq rax ++                   (* popq %rax: 彈出 e 的值到 %rax *)
      movq !%rax (lab x)            (* movq %rax, x(%rip): 將 %rax 的值存入全局變數 x *)
  | Print e ->
      (* 編譯 print e 指令 *)
      (* 印出表達式 e 的值 *)
      compile_expr e ++    (* 編譯表達式 e，結果在堆疊頂端 *)
      popq rdi ++          (* popq %rdi: 彈出 e 的值到 %rdi (函數呼叫的第一個參數) *)
      movq (imm 0) !%rax ++  (* movq $0, %rax: 清空 %rax (printf 需要) *)
      call "print_int"     (* call print_int: 呼叫 print_int 函數印出 %rdi 的值 *)


(* Compilation of the program p and saving the code in the file ofile *)
let compile_program p ofile =
  let code = List.map compile_instr p in
  let code = List.fold_right (++) code nop in
  if !frame_size mod 16 = 8 then frame_size := 8 + !frame_size;
  let p =
    { text =
        globl "main" ++ label "main" ++
        (* === 函數序言 (Function Prologue) === *)
        pushq !%rbp ++                    (* pushq %rbp: 保存舊的 base pointer *)
        movq !%rsp !%rbp ++               (* movq %rsp, %rbp: 設置新的 base pointer *)
        subq (imm !frame_size) !%rsp ++   (* subq $frame_size, %rsp: 為局部變數分配堆疊空間 *)
        code ++
        (* === 函數結尾 (Function Epilogue) === *)
        movq !%rbp !%rsp ++               (* movq %rbp, %rsp: 恢復堆疊指針 (清理局部變數) *)
        popq rbp ++                       (* popq %rbp: 恢復舊的 base pointer *)
        movq (imm 0) !%rax ++             (* movq $0, %rax: 設置返回值為 0 *)
        ret ++                            (* ret: 返回 *)
        label "print_int" ++
        (* print_int 函數：印出整數到 stdout *)
        pushq !%rbp ++                      (* pushq %rbp: 保存 %rbp *)
        movq !%rsp !%rbp ++                 (* movq %rsp, %rbp: 設置新的 %rbp *)
        movq !%rdi !%rsi ++                 (* movq %rdi, %rsi: 將參數移到第二個參數位置 *)
        leaq (lab ".Sprint_int") rdi ++     (* leaq .Sprint_int(%rip), %rdi: 載入格式字串 *)
        movq (imm 0) !%rax ++               (* movq $0, %rax: 設置浮點參數數量為 0 *)
        call "printf" ++                    (* call printf: 呼叫 printf *)
        popq rbp ++                         (* popq %rbp: 恢復 %rbp *)
        ret;
      data =
        Hashtbl.fold (fun x _ l -> label x ++ dquad [1] ++ l) genv
          (label ".Sprint_int" ++ string "%d\n")
    }
  in
  let f = open_out ofile in
  let fmt = formatter_of_out_channel f in
  X86_64.print_program fmt p;
  (* flush the buffer to ensure everything is written before closing *)
  fprintf fmt "@?";
  close_out f
