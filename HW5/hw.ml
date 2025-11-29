(* Compiler HW5: LL(1) Parser Generator *)

(* ==========================================
   Type Definitions
   ========================================== *)

type terminal = string
type non_terminal = string

type symbol =
  | Terminal of terminal
  | NonTerminal of non_terminal

type production = symbol list
type rule = non_terminal * production

type grammar = {
  start : non_terminal;
  rules : rule list;
}

(* ==========================================
   1. Fixed-point Calculation
   ========================================== *)

(* 1.1: fixpoint function *)
let rec fixpoint f x =
  let (x', changed) = f x in
  if changed then fixpoint f x' else x'

(* ==========================================
   2. Calculating the Nulls
   ========================================== *)

module Ntset = Set.Make(String)
type nulls = Ntset.t

(* 2.1: is_null_production *)
let is_null_production nulls prod =
  List.for_all (fun sym ->
    match sym with
    | Terminal _ -> false
    | NonTerminal nt -> Ntset.mem nt nulls
  ) prod

(* 2.2: null - calculate nullable non-terminals *)
let null g =
  let step nulls =
    let (new_nulls, changed) =
      List.fold_left (fun (acc_nulls, acc_changed) (nt, prod) ->
        if Ntset.mem nt acc_nulls then
          (acc_nulls, acc_changed)
        else if is_null_production acc_nulls prod then
          (Ntset.add nt acc_nulls, true)
        else
          (acc_nulls, acc_changed)
      ) (nulls, false) g.rules
    in
    (new_nulls, changed)
  in
  fixpoint step Ntset.empty

(* ==========================================
   3. Calculating the Firsts
   ========================================== *)

module Ntmap = Map.Make(String)
module Tset = Set.Make(String)

type firsts = Tset.t Ntmap.t

(* 3.1: empty_map - create empty map for all non-terminals *)
let empty_map g =
  List.fold_left (fun acc (nt, _) ->
    if Ntmap.mem nt acc then acc
    else Ntmap.add nt Tset.empty acc
  ) Ntmap.empty g.rules

(* 3.2: first_production_step - calculate FIRST of a production *)
let rec first_production_step nulls firsts = function
  | [] -> Tset.empty
  | (Terminal t) :: _ -> Tset.singleton t
  | (NonTerminal nt) :: rest ->
      let first_nt =
        try Ntmap.find nt firsts
        with Not_found -> Tset.empty
      in
      if Ntset.mem nt nulls then
        Tset.union first_nt (first_production_step nulls firsts rest)
      else
        first_nt

(* first - calculate FIRST sets for all non-terminals *)
let first g nulls =
  let step firsts =
    let (new_firsts, changed) =
      List.fold_left (fun (acc_firsts, acc_changed) (nt, prod) ->
        let old_first = Ntmap.find nt acc_firsts in
        let prod_first = first_production_step nulls acc_firsts prod in
        let new_first = Tset.union old_first prod_first in
        if Tset.subset new_first old_first then
          (acc_firsts, acc_changed)
        else
          (Ntmap.add nt new_first acc_firsts, true)
      ) (firsts, false) g.rules
    in
    (new_firsts, changed)
  in
  fixpoint step (empty_map g)

(* ==========================================
   4. Calculating the Follows
   ========================================== *)

type follows = Tset.t Ntmap.t

(* follows - calculate FOLLOW sets *)
let follow g nulls firsts =
  let update (follows, b) nt follow_set =
    let old_follow =
      try Ntmap.find nt follows
      with Not_found -> Tset.empty
    in
    let new_follow = Tset.union old_follow follow_set in
    if Tset.subset new_follow old_follow then
      (follows, b)
    else
      (Ntmap.add nt new_follow follows, true)
  in

  let rec update_prod ((follows, b) as acc) lhs = function
    | [] -> acc
    | (Terminal _) :: rest -> update_prod acc lhs rest
    | (NonTerminal x) :: rest ->
        let first_rest = first_production_step nulls firsts rest in
        let (follows', b') = update (follows, b) x first_rest in
        let acc' =
          if is_null_production nulls rest then
            let lhs_follow =
              try Ntmap.find lhs follows'
              with Not_found -> Tset.empty
            in
            update (follows', b') x lhs_follow
          else
            (follows', b')
        in
        update_prod acc' lhs rest
  in

  let step follows =
    List.fold_left
      (fun acc (nt, p) -> update_prod acc nt p)
      (follows, false) g.rules
  in

  fixpoint step (empty_map g)

(* ==========================================
   5. Construction of the LL(1) Table
   ========================================== *)

module Tmap = Map.Make(String)
module Pset = Set.Make(struct type t = production let compare = compare end)

type expansion_table = Pset.t Tmap.t Ntmap.t

(* 5.1: add_entry - add entry to expansion table *)
let add_entry table nt t prod =
  let row =
    try Ntmap.find nt table
    with Not_found -> Tmap.empty
  in
  let prods =
    try Tmap.find t row
    with Not_found -> Pset.empty
  in
  let new_prods = Pset.add prod prods in
  let new_row = Tmap.add t new_prods row in
  Ntmap.add nt new_row table

(* 5.2: expansions - build LL(1) parsing table *)
let expansions g =
  let nulls = null g in
  let firsts = first g nulls in
  let follows = follow g nulls firsts in

  List.fold_left (fun table (nt, prod) ->
    let first_prod = first_production_step nulls firsts prod in
    let table' = Tset.fold (fun t acc ->
      add_entry acc nt t prod
    ) first_prod table in

    if is_null_production nulls prod then
      let follow_nt =
        try Ntmap.find nt follows
        with Not_found -> Tset.empty
      in
      Tset.fold (fun t acc ->
        add_entry acc nt t prod
      ) follow_nt table'
    else
      table'
  ) Ntmap.empty g.rules

(* ==========================================
   6. LL(1) Characterization
   ========================================== *)

(* 6.1: is_ll1 - check if grammar is LL(1) *)
let is_ll1 table =
  Ntmap.for_all (fun _ row ->
    Tmap.for_all (fun _ prods ->
      Pset.cardinal prods <= 1
    ) row
  ) table

(* ==========================================
   7. String Recognition
   ========================================== *)

(* 7.1: analyze - table-driven parser *)
let analyze start table input =
  let input_with_end = input @ ["#"] in

  let rec parse stack input =
    match (stack, input) with
    | ([], []) -> true
    | ([], _) | (_, []) -> false
    | (Terminal t :: stack_rest, h :: input_rest) ->
        if t = h then parse stack_rest input_rest
        else false
    | (NonTerminal nt :: stack_rest, h :: _) ->
        (try
          let row = Ntmap.find nt table in
          let prods = Tmap.find h row in
          if Pset.is_empty prods then false
          else
            let prod = Pset.choose prods in
            parse (prod @ stack_rest) input
        with Not_found -> false)
  in

  parse [NonTerminal start] input_with_end

(* ==========================================
   Pretty Printers
   ========================================== *)

let pp_non_terminal fmt s = Format.fprintf fmt "%s" s

let pp_iter iter pp_elt fmt =
  let first = ref true in
  iter (fun elt ->
    if not !first then Format.fprintf fmt ",@ " else first := false;
    pp_elt fmt elt)

let pp_nulls fmt nulls =
  Format.fprintf fmt "@[%a@]" (pp_iter Ntset.iter pp_non_terminal) nulls

let pp_iter_bindings iter pp_binding fmt =
  let first = ref true in
  iter (fun key elt ->
    if not !first then Format.fprintf fmt "@\n" else first := false;
    pp_binding fmt key elt)

let pp_terminal fmt s = Format.fprintf fmt "%s" s

let pp_firsts fmt firsts =
  Format.fprintf fmt "@[%a@]"
    (pp_iter_bindings Ntmap.iter (fun fmt nt ts ->
      Format.fprintf fmt "@[%a -> {%a}@]" pp_non_terminal nt
        (pp_iter Tset.iter pp_terminal) ts))
    firsts

let pp_follows = pp_firsts

let pp_symbol fmt = function
  | Terminal s -> Format.fprintf fmt "\"%s\"" s
  | NonTerminal s -> Format.fprintf fmt "%s" s

let rec pp_production fmt = function
  | [] -> ()
  | [x] -> pp_symbol fmt x
  | x :: l -> Format.fprintf fmt "%a %a" pp_symbol x pp_production l

let pp_table fmt t =
  let print_entry c p =
    Format.fprintf fmt " %s: @[%a@]@\n" c pp_production p in
  let print_row nt m =
    Format.fprintf fmt "@[Expansions for %s:@\n" nt;
    Tmap.iter (fun c rs -> Pset.iter (print_entry c) rs) m;
    Format.fprintf fmt "@]" in
  Ntmap.iter print_row t

(* ==========================================
   Test Cases
   ========================================== *)

(* Example grammar from class *)
let g_arith =
  { start = "S'";
    rules = [ "S'", [ NonTerminal "E"; Terminal "#" ];
              "E", [ NonTerminal "T"; NonTerminal "E'" ];
              "E'", [Terminal "+"; NonTerminal "T"; NonTerminal "E'" ];
              "E'", [ ];
              "T", [ NonTerminal "F"; NonTerminal "T'" ];
              "T'", [Terminal "*"; NonTerminal "F"; NonTerminal "T'" ];
              "T'", [ ];
              "F", [Terminal "("; NonTerminal "E"; Terminal ")" ];
              "F", [ Terminal "int" ]; ] }

(* Test grammar g1 *)
let g1 = {
  start = "S'";
  rules = ["S'", [NonTerminal "S"; Terminal "#"];
           "S", [];
           "S", [Terminal "a"; NonTerminal "A"; NonTerminal "S"];
           "S", [Terminal "b"; NonTerminal "B"; NonTerminal "S"];
           "A", [Terminal "a"; NonTerminal "A"; NonTerminal "A"];
           "A", [Terminal "b"];
           "B", [Terminal "b"; NonTerminal "B"; NonTerminal "B"];
           "B", [Terminal "a"];
          ] }

(* Helper function to explode string *)
let explode s =
  let n = String.length s in
  let rec make i =
    if i = n then []
    else String.make 1 s.[i] :: make (i+1)
  in
  make 0

(* Main tests *)
let () =
  Printf.printf "=== Testing LL(1) Parser Generator ===\n\n";

  (* Test nulls *)
  Printf.printf "Testing NULL calculation:\n";
  let nulls_arith = null g_arith in
  Format.printf "null: %a@." pp_nulls nulls_arith;

  (* Test firsts *)
  Printf.printf "\nTesting FIRST calculation:\n";
  let firsts_arith = first g_arith nulls_arith in
  Format.printf "first: %a@." pp_firsts firsts_arith;

  (* Test follows *)
  Printf.printf "\nTesting FOLLOW calculation:\n";
  let follows_arith = follow g_arith nulls_arith firsts_arith in
  Format.printf "follow: %a@." pp_follows follows_arith;

  (* Test expansion table *)
  Printf.printf "\nTesting LL(1) table construction:\n";
  let table_arith = expansions g_arith in
  Format.printf "%a@." pp_table table_arith;

  (* Test LL(1) property *)
  Printf.printf "\nTesting LL(1) property:\n";
  assert (is_ll1 table_arith);
  Printf.printf "g_arith is LL(1): true\n";

  (* Test g1 *)
  Printf.printf "\nTesting g1 grammar:\n";
  let table1 = expansions g1 in
  Format.printf "%a@." pp_table table1;
  assert (is_ll1 table1);
  Printf.printf "g1 is LL(1): true\n";

  (* Test string recognition *)
  Printf.printf "\nTesting string recognition with g1:\n";
  let test1 s =
    let result = analyze g1.start table1 (explode s) in
    Printf.printf "  \"%s\": %b\n" s result;
    result
  in
  assert (test1 "");
  assert (test1 "ab");
  assert (test1 "ba");
  assert (test1 "abab");
  assert (test1 "aaabbb");
  assert (test1 "aaabababbbababab");
  assert (not (test1 "a"));
  assert (not (test1 "b"));
  assert (not (test1 "aab"));
  assert (not (test1 "aaabbba"));

  Printf.printf "\n=== All tests passed! ===\n";

  (* ==========================================
     8. Bootstrap: Grammar of Grammars
     ========================================== *)

  Printf.printf "\n=== Section 8: Grammar of Grammars ===\n\n";

  (* Original grammar (not LL(1)) *)
  let g_gram =
    { start = "S'";
      rules = [ "S'", [ NonTerminal "S"; Terminal "#" ];
                "S", [ NonTerminal "R" ];
                "S", [NonTerminal "R"; Terminal ";"; NonTerminal "S" ];
                "R", [Terminal "ident"; Terminal "::="; NonTerminal "P"];
                "P", [ NonTerminal "W" ];
                "P", [ NonTerminal "W"; Terminal "|"; NonTerminal "P" ];
                "W", [ ];
                "W", [ NonTerminal "C"; NonTerminal "W"];
                "C", [Terminal "ident"];
                "C", [Terminal "string"];
              ] } in

  Printf.printf "Testing g_gram (original grammar):\n";
  let table_gram = expansions g_gram in
  Format.printf "%a@." pp_table table_gram;
  Printf.printf "g_gram is LL(1): %b\n\n" (is_ll1 table_gram);

  (* LL(1) version using right recursion with prime notation *)
  let g_gram_ll1 =
    { start = "S'";
      rules = [ "S'", [ NonTerminal "S"; Terminal "#" ];
                (* S -> R S' where S' handles optional ; S *)
                "S", [NonTerminal "R"; NonTerminal "S1"];
                "S1", [];  (* epsilon *)
                "S1", [Terminal ";"; NonTerminal "S"];
                (* R unchanged *)
                "R", [Terminal "ident"; Terminal "::="; NonTerminal "P"];
                (* P -> W P' where P' handles optional | P *)
                "P", [ NonTerminal "W"; NonTerminal "P1" ];
                "P1", [];  (* epsilon *)
                "P1", [ Terminal "|"; NonTerminal "P" ];
                (* W -> C W' where W' handles optional C W *)
                "W", [ NonTerminal "W1" ];
                "W1", [];  (* epsilon *)
                "W1", [ NonTerminal "C"; NonTerminal "W1"];
                (* C unchanged *)
                "C", [Terminal "ident"];
                "C", [Terminal "string"];
              ] } in

  Printf.printf "Testing g_gram_ll1 (proposed LL(1) grammar):\n";
  let table_gram_ll1 = expansions g_gram_ll1 in
  Format.printf "%a@." pp_table table_gram_ll1;
  Printf.printf "g_gram_ll1 is LL(1): %b\n" (is_ll1 table_gram_ll1);

  Printf.printf "\n=== LL(1) Grammar Proposal ===\n";
  Printf.printf "To convert the grammar to LL(1), we eliminate left recursion:\n";
  Printf.printf "1. S  -> R S1      where S1  -> ; S | ε\n";
  Printf.printf "2. P  -> W P1      where P1  -> | P | ε\n";
  Printf.printf "3. W  -> W1        where W1  -> C W1 | ε\n";
  Printf.printf "4. C  -> ident | string (unchanged)\n";
  Printf.printf "5. R  -> ident ::= P (unchanged)\n"
