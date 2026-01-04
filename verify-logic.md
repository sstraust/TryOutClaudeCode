# Logic Verification

## Test Case: `{:a 1, :type :Foo, :b 2}`

### Step 1: Parse
Entries (in order):
1. `:a` → `1`
2. `:type` → `:Foo`
3. `:b` → `2`

### Step 2: Separate type entries
- type_entries: `[(:type . :Foo)]`
- other_entries: `[(:a . 1), (:b . 2)]`  ← **Order preserved!**
- sorted_entries: `[(:type . :Foo), (:a . 1), (:b . 2)]`

### Step 3: Format with base-indent=3
- col = 3 + 1 = 4
- Result:
  ```
  {
  :type :Foo,
      :a 1,
      :b 2}
  ```

Which with "=> " prefix becomes:
```
=> {:type :Foo,
=>     :a 1,
=>     :b 2}
```

✓ Order of :a and :b preserved!
✓ :type moved to front!

## Test Case: Complex nested map

Input:
```
{:side1 1, :side2 3, :pos {:x 1, :y 2, :type :Position}, :type :Rectangle}
```

### Outer map parse (in order):
1. `:side1` → `1`
2. `:side2` → `3`
3. `:pos` → `{:x 1, :y 2, :type :Position}` (raw string)
4. `:type` → `:Rectangle`

### Outer map reorder:
- type: `[(:type . :Rectangle)]`
- other: `[(:side1 . 1), (:side2 . 3), (:pos . {...})]`  ← **Order preserved!**
- result: `[(:type . :Rectangle), (:side1 . 1), (:side2 . 3), (:pos . {...})]`

### Format outer (base-indent=3, col=4):
```
{:type :Rectangle,
    :side1 1,
    :side2 3,
    :pos <recursive format>}
```

### Recursive format for `:pos` value
- Value: `{:x 1, :y 2, :type :Position}`
- New indent: col + len(":pos") + 1 = 4 + 4 + 1 = 9
- New col: 9 + 1 = 10

Parse nested map (in order):
1. `:x` → `1`
2. `:y` → `2`
3. `:type` → `:Position`

Reorder:
- type: `[(:type . :Position)]`
- other: `[(:x . 1), (:y . 2)]`  ← **Order preserved!**

Format (col=10):
```
{:type :Position,
          :x 1,
          :y 2}
```

### Final output:
```
=> {:type :Rectangle,
    :side1 1,
    :side2 3,
    :pos {:type :Position,
          :x 1,
          :y 2}}
```

✓ All original ordering preserved (except :type moved to front)
✓ Nested maps formatted recursively
✓ Column alignment correct
