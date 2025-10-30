# 編譯器作業 3
## 從正規表達式構造 DFA
**337883 Compiler - 114-1**

---

## 作業說明

在本作業中，我們研究一種從正規表達式直接構造確定性有限自動機的方法。這是一個高效的演算法，特別用於 ocamllex 中。

基本思想如下：如果一個有限自動機識別與正規表達式 r 對應的語言，那麼被識別的字詞中的任何字母都可以與出現在 r 中的字母進行匹配。為了區分 r 中相同字母的不同出現位置，我們將用整數對它們進行索引。

例如，考慮正規表達式 `(a|b)* a (a|b)`，它定義了字母表 {a, b} 中倒數第二個字母是 a 的字詞。如果我們對字元進行索引，我們得到：

```
(a₁|b₁)* a₂(a₃|b₂)
```

如果我們考慮字詞 `aabaab`，那麼它以以下方式匹配正規表達式：

```
a₁a₁b₁a₁a₂b₂
```

其想法是建構一個自動機，其狀態是索引字母的集合，對應於一次可以讀取的出現位置。因此，初始狀態包含被識別字詞的第一個可能字母。在我們的例子中，這是 a₁, b₁, a₂。為了建構轉換，只需計算每個字母的出現位置，可以跟隨它的出現位置集合就足夠了。在我們的例子中，如果我們剛讀取了 a₁，那麼接下來可能的字元是 a₁, b₁, a₂；如果我們剛讀取了 a₂，那麼這些是 a₃, b₂。

---

## 1. 正規表達式的空性（Nullity）

我們考慮以下 Caml 類型來表示正規表達式，其字母由整數索引（ichar 類型）。

```ocaml
type ichar = char * int

type regexp =
  | Epsilon
  | Character of ichar
  | Union of regexp * regexp
  | Concat of regexp * regexp
  | Star of regexp
```

### Question 1
撰寫一個函數

```ocaml
val null : regexp -> bool
```

該函數確定 epsilon（空字詞）是否屬於正規表達式所識別的語言。

**測試：**
```ocaml
let () =
  let a = Character ('a', 0) in
  assert (not (null a));
  assert (null (Star a));
  assert (null (Concat (Epsilon, Star Epsilon)));
  assert (null (Union (Epsilon, a)));
  assert (not (null (Concat (a, Star a))))
```

---

## 2. 首字母和尾字母（The first and the last）

為了表示索引字母的集合，我們使用以下 OCaml 類型：

```ocaml
module Cset = Set.Make(struct type t = ichar let compare = Stdlib.compare end)
```

### Question 2
撰寫一個函數

```ocaml
val first : regexp -> Cset.t
```

該函數計算正規表達式所識別的字詞的第一個字母的集合。（您必須使用 `null`。）

同樣地，撰寫一個函數

```ocaml
val last : regexp -> Cset.t
```

該函數計算被識別字詞的最後一個字母的集合。

**測試：**
```ocaml
let () =
  let ca = ('a', 0) and cb = ('b', 0) in
  let a = Character ca and b = Character cb in
  let ab = Concat (a, b) in
  let eq = Cset.equal in
  assert (eq (first a) (Cset.singleton ca));
  assert (eq (first ab) (Cset.singleton ca));
  assert (eq (first (Star ab)) (Cset.singleton ca));
  assert (eq (last b) (Cset.singleton cb));
  assert (eq (last ab) (Cset.singleton cb));
  assert (Cset.cardinal (first (Union (a, b))) = 2);
  assert (Cset.cardinal (first (Concat (Star a, b))) = 2);
  assert (Cset.cardinal (last (Concat (a, Star b))) = 2)
```

---

## 3. 後續字母（The follow）

### Question 3
使用 `first` 和 `last` 函數，撰寫一個函數

```ocaml
val follow : ichar -> regexp -> Cset.t
```

該函數計算在被識別字詞集合中可以跟隨給定字母的字母集合。

注意，字母 d 屬於集合 `follow c r` 當且僅當：
- 存在 r 的子表達式形式為 r₁ r₂，其中 d 是 first r₂ 的元素且 c 是 last r₁ 的元素；
- 或者存在 r 的子表達式形式為 r₁*，其中 d 是 first r₁ 的元素且 c 是 last r₁ 的元素。

**測試：**
```ocaml
let () =
  let ca = ('a', 0) and cb = ('b', 0) in
  let a = Character ca and b = Character cb in
  let ab = Concat (a, b) in
  assert (Cset.equal (follow ca ab) (Cset.singleton cb));
  assert (Cset.is_empty (follow cb ab));
  let r = Star (Union (a, b)) in
  assert (Cset.cardinal (follow ca r) = 2);
  assert (Cset.cardinal (follow cb r) = 2);
  let r2 = Star (Concat (a, Star b)) in
  assert (Cset.cardinal (follow cb r2) = 2);
  let r3 = Concat (Star a, b) in
  assert (Cset.cardinal (follow ca r3) = 2)
```

---

## 4. 自動機的構造

要構造與正規表達式 r 對應的確定性有限狀態自動機，我們按以下步驟進行：

1. 我們在 r 的末尾添加一個新字元 #；
2. 起始狀態是集合 first r；
3. 當讀取字元 c（這是一個非索引字母）時，我們有一個從狀態 q 到狀態 q' 的轉換，如果 q' 是所有 follow cᵢ r 的聯集，其中 cᵢ 是 q 的所有元素且 fst cᵢ = c；
4. 接受狀態是包含 # 字元的狀態。

### Question 4.1
撰寫一個函數

```ocaml
val next_state : regexp -> Cset.t -> char -> Cset.t
```

該函數計算轉換的結果狀態。

為了表示有限自動機，我們使用以下 autom 類型：

```ocaml
type state = Cset.t (* 狀態是一組字元 *)

module Cmap = Map.Make(Char) (* 鍵為字元的字典 *)
module Smap = Map.Make(Cset) (* 鍵為狀態的字典 *)

type autom = {
  start : state;
  trans : state Cmap.t Smap.t (* 狀態字典 -> (字元字典 -> 狀態) *)
}
```

我們可以選擇以這種方式表示 # 字元：

```ocaml
let eof = ('#', -1)
```

### Question 4.2
撰寫一個函數

```ocaml
val make_dfa : regexp -> autom
```

該函數構造與正規表達式對應的自動機。其想法是根據需要構造狀態，從初始狀態開始。例如，我們可以採用以下方法：

```ocaml
let make_dfa r =
  let r = Concat (r, Character eof) in
  (* 正在構造的轉換 *)
  let trans = ref Smap.empty in
  let rec transitions q =
    (* transitions 函數構造狀態 q 的所有轉換，
       如果這是第一次訪問 q *)
    ...
  in
  let q0 = first r in
  transitions q0;
  { start = q0; trans = !trans }
```

**注意：** 當然可以最終構造一個狀態不是集合而是整數的自動機，以在執行自動機時獲得更高的效率。這也可以在構造期間或事後完成。但這不是我們這裡感興趣的。

### 使用 dot 工具視覺化

以下是一些程式碼，用於以 dot 工具的輸入格式列印自動機：

```ocaml
let fprint_state fmt q =
  Cset.iter (fun (c,i) ->
    if c = '#' then Format.fprintf fmt "# "
    else Format.fprintf fmt "%c%i " c i) q

let fprint_transition fmt q c q' =
  Format.fprintf fmt "\"%a\" -> \"%a\" [label=\"%c\"];@\n"
    fprint_state q
    fprint_state q'
    c

let fprint_autom fmt a =
  Format.fprintf fmt "digraph A {@\n";
  Format.fprintf fmt " @[\"%a\" [ shape = \"rect\"];@\n" fprint_state a.start;
  Smap.iter
    (fun q t -> Cmap.iter (fun c q' -> fprint_transition fmt q c q') t)
    a.trans;
  Format.fprintf fmt "@]@\n}@."

let save_autom file a =
  let ch = open_out file in
  Format.fprintf (Format.formatter_of_out_channel ch) "%a" fprint_autom a;
  close_out ch
```

為了測試，我們採用上面的例子：

```ocaml
(* (a|b)*a(a|b) *)
let r = Concat (Star (Union (Character ('a', 1), Character ('b', 1))),
                Concat (Character ('a', 2),
                        Union (Character ('a', 3), Character ('b', 2))))

let a = make_dfa r
let () = save_autom "autom.dot" a
```

執行會產生一個 autom.dot 檔案，然後可以使用 Unix 命令查看：

```bash
dotty autom.dot
```

或使用以下兩個命令之一：

```bash
dot -Tps autom.dot | gv -
dot -Tpdf autom.dot > autom.pdf && evince autom.pdf
```

我們應該得到類似下圖的結果（見 PDF 第 6 頁的圖）。

---

## 5. 字詞識別

### Question 5
撰寫一個函數

```ocaml
val recognize : autom -> string -> bool
```

該函數確定一個字詞是否被自動機識別。

以下是一些正面測試：

```ocaml
let () = assert (recognize a "aa")
let () = assert (recognize a "ab")
let () = assert (recognize a "abababaab")
let () = assert (recognize a "babababab")
let () = assert (recognize a (String.make 1000 'b' ^ "ab"))
```

以及一些負面測試：

```ocaml
let () = assert (not (recognize a ""))
let () = assert (not (recognize a "a"))
let () = assert (not (recognize a "b"))
let () = assert (not (recognize a "ba"))
let () = assert (not (recognize a "aba"))
let () = assert (not (recognize a "abababaaba"))
```

以下是另一個測試，使用一個表示偶數個 b 的正規表達式：

```ocaml
let r = Star (Union (Star (Character ('a', 1)),
                     Concat (Character ('b', 1),
                             Concat (Star (Character ('a',2)),
                                     Character ('b', 2)))))
let a = make_dfa r
let () = save_autom "autom2.dot" a
```

一些正面測試：

```ocaml
let () = assert (recognize a "")
let () = assert (recognize a "bb")
let () = assert (recognize a "aaa")
let () = assert (recognize a "aaabbaaababaaa")
let () = assert (recognize a "bbbbbbbbbbbbbb")
let () = assert (recognize a "bbbbabbbbabbbabbb")
```

以及一些負面測試：

```ocaml
let () = assert (not (recognize a "b"))
let () = assert (not (recognize a "ba"))
let () = assert (not (recognize a "ab"))
let () = assert (not (recognize a "aaabbaaaaabaaa"))
let () = assert (not (recognize a "bbbbbbbbbbbbb"))
let () = assert (not (recognize a "bbbbabbbbabbbabbbb"))
```

---

## 6. 生成詞法分析器

在這最後一個問題中，我們建議從對應於正規表達式的自動機自動構造 OCaml 程式碼，該程式碼執行詞法分析，即將字元字串切割成盡可能長的 token。

更確切地說，我們將產生以下形式的程式碼：

```ocaml
type buffer = { text: string; mutable current: int; mutable last: int }

let next_char b =
  if b.current = String.length b.text then raise End_of_file;
  let c = b.text.[b.current] in
  b.current <- b.current + 1;
  c

let rec state1 b =
  ...
and state2 b =
  ...
and state3 b =
  ...
```

類型 buffer 包含要分析的字串（text 欄位）、要檢查的下一個字元的位置（current 欄位）以及最後識別的 token 之後的位置（last 欄位）。

函數 next_char 返回要分析的下一個字元並遞增 current 欄位。如果到達字串末尾，它會引發 End_of_file 異常。

自動機的每個狀態對應於一個函數 statei，其參數 b 的類型為 buffer。此函數執行以下工作：

1. 如果狀態是接受狀態，則將 b.last 設置為 b.current 的值。
2. 然後我們調用 next_char b 並檢查其結果。如果它是一個存在轉換的字元，則我們調用相應的函數。否則，我們引發異常（例如，使用 `failwith "lexical error"`）。

注意 statei 函數不返回任何內容。它們只能在異常上終止（End_of_file 表示已到達字串末尾，或 Failure 表示詞法錯誤）。

### Question 6.1
撰寫一個函數

```ocaml
val generate: string -> autom -> unit
```

該函數以檔案名稱和自動機作為參數，並根據上述形式在此檔案中產生對應於此自動機的 OCaml 程式碼。

**提示：**
- 我們可以從對所有狀態編號開始，例如通過構造一個類型為 `int Smap.t` 的字典，該字典將唯一編號與每個狀態關聯。
- 我們可以從上面給出的 save_autom 函數的程式碼中獲得靈感，特別是關於在檔案中顯示的部分。

**注意：** 在產生的程式碼中添加以下形式的最後一行將很有用：

```ocaml
let start = state42
```

對應於自動機的初始狀態。

### Question 6.2
為了測試，撰寫一個程式（在另一個 lexer.ml 檔案中，這次是手寫的），該程式使用自動產生的程式碼（通過固定檔案名稱，例如 a.ml）將字串切割成 token。原理是執行以下操作的循環：

1. 我們將 last 欄位設置為 -1；
2. 我們調用 start 函數並捕獲它拋出的異常 e；
3. 如果 last 欄位仍然是 -1，則沒有識別到 token，我們通過重新拋出異常 e 結束；
4. 否則，我們顯示識別到的 token，並將 last 欄位的值分配給 current 欄位。

請注意正確處理程式終止。

我們可以例如使用正規表達式 a*b 進行測試，執行：

```ocaml
let r3 = Concat (Star (Character ('a', 1)), Character ('b', 1))
let a = make_dfa r3
let () = generate "a.ml" a
```

然後將產生的程式碼與 lexer.ml 檔案連結：

```bash
% ocamlopt a.ml lexer.ml
```

對於字串 `abbaaab`，分析必須產生三個 token 並成功：

```
--> "ab"
--> "b"
--> "aaab"
```

對於字串 `aba`，分析應該產生第一個 token 然後失敗：

```
--> "ab"
exception End_of_file
```

最後，對於字串 `aac`，分析應該在詞法錯誤上失敗：

```
exception Failure("lexical error")
```

我們還可以使用正規表達式 `(b|epsilon)(ab)*(a|epsilon)` 測試字母 a 和 b 交替的字詞。對於字串 `abbac`，我們應該獲得三個 token：

```
--> "ab"
--> "ba"
--> ""
would now loop
```

最後一個 token 是空字串，程式停止，這意味著我們現在會無限期地獲得這個空 token。

---

**備註：** 此演算法稱為 Berry-Sethi 演算法。它特別在 Dragon (Aho, Sethi, Ullman, Compilers ...) 第 3.9 節中描述。
