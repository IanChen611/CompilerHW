# 編譯器作業 6 - Algorithm W

## 作業目標

本作業的目標是為 mini-ML 實作 **Algorithm W（型別推導演算法）**。我們將使用破壞性統一（destructive unification）的版本。

---

## 第 1 部分：正規化（Normalization）

### 1.1 實作 `head` 函數

```ocaml
val head: typ -> typ
```

**功能**：正規化型別的頭部，即 `head t` 返回一個等價於 `t` 的型別，但不是 `Tvar { def = Some _}` 的形式。換句話說，`head t` 會持續追蹤型別變數的定義，直到找到最終型別。

### 1.2 實作 `canon` 函數

```ocaml
val canon: typ -> typ
```

**功能**：完整地正規化一個型別，即對型別進行深度的 `head` 函數應用。此函數用於顯示型別（在型別檢查結果或錯誤訊息中）。

---

## 第 2 部分：統一（Unification）

### 2.1 實作 `occurs` 函數

```ocaml
val occurs: tvar -> typ -> bool
```

**功能**：測試一個型別變數是否出現在一個型別中（occur-check）。假設變數是未定義的，但型別可能包含已定義的變數，需要先對型別應用 `head` 函數。

### 2.2 實作 `unify` 函數

```ocaml
val unify: typ -> typ -> unit
```

**功能**：對兩個型別進行統一。同樣需要先對傳入的型別參數使用 `head` 函數後再檢查。

**錯誤處理**：統一失敗時拋出 `UnificationFailure` 例外。

---

## 第 3 部分：型別的自由變數

### 3.1 實作 `fvars` 函數

```ocaml
val fvars : typ -> Vset.t
```

**功能**：計算一個型別的自由變數集合。需要謹慎使用 `head` 函數，只考慮未定義的變數。

---

## 第 4 部分：型別環境（Typing Environment）

### 4.1 實作 `add` 函數

```ocaml
val add: string -> typ -> env -> env
```

**功能**：不經過泛化（generalization）直接將元素加入型別環境（用於函數的型別推導）。記得更新環境的 `fvars` 欄位。

### 4.2 實作 `add_gen` 函數

```ocaml
val add_gen: string -> typ -> env -> env
```

**功能**：將元素加入型別環境，並對其型別進行泛化，將所有不在環境中的自由型別變數進行泛化（用於 `let` 的型別推導）。

### 4.3 實作 `find` 函數

```ocaml
val find: string -> env -> typ
```

**功能**：從環境中返回與識別符關聯的型別，並將對應 schema 中的所有變數替換為新鮮的型別變數。

**注意**：同一個變數在型別中可能有多次出現，必須將它們全部替換為同一個新鮮變數。

**提示**：可以使用 `Vmap = Map.Make(V)` 模組，並用 `tvar Vmap.t` 型別的值來表示這個替換。

---

## 第 5 部分：Algorithm W

### 5.1 實作 `w` 函數

```ocaml
val w: env -> expression -> typ
```

**功能**：實作 Algorithm W 型別推導演算法。

**運算子處理**：對於運算子（`Op`），可以簡單地使用 `Op "+"` 並賦予其型別 `int * int -> int`。

---

## 測試要求

作業提供了多個測試案例：

### 正面測試（應該成功推導型別）
- `1 : int`
- `fun x -> x : 'a -> 'a`
- `fun x -> x+1 : int -> int`
- `let id = fun x -> x in id id 1 : int`
- `let id = fun x -> x in (id 1, id (1,2)) : int * (int * int)`
- 等等...

### 負面測試（應該失敗並拋出 UnificationFailure）
- `1 2`（將整數當作函數呼叫）
- `fun x -> x x`（自我應用）
- `fun x -> (x 1, x (1,2))`（同一變數用於不相容的型別）
- 等等...

---

## 型別定義

### Mini-ML 的型別表示

```ocaml
type typ =
  | Tint
  | Tarrow of typ * typ
  | Tproduct of typ * typ
  | Tvar of tvar

and tvar =
  { id : int;
    mutable def : typ option }
```

### Mini-ML 的表達式

```ocaml
type expression =
  | Var of string
  | Const of int
  | Op of string
  | Fun of string * expression
  | App of expression * expression
  | Pair of expression * expression
  | Let of string * expression * expression
```

---

## 重要概念

1. **破壞性統一**：直接修改型別變數的定義欄位（`def`）
2. **型別正規化**：追蹤型別變數的定義鏈
3. **occur-check**：防止無限型別（如 `'a = 'a -> int`）
4. **泛化**：在 `let` 表達式中將型別變數提升為多型
5. **實例化**：使用新鮮變數替換 schema 中的變數

---

## 開發建議

1. 依序完成各部分，每部分都使用提供的測試案例驗證
2. 仔細處理型別變數的定義狀態
3. 在統一和正規化時正確使用 `head` 函數
4. 注意區分 `add`（用於函數參數）和 `add_gen`（用於 let 綁定）
5. 在 `find` 中確保同一變數的多次出現被替換為同一個新鮮變數
