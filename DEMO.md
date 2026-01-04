# CIDER Format Maps - Output Examples

## Features

✓ `:type` keys appear first at every level
✓ **Original order preserved for all other keys**
✓ Nested content aligns with column after opening `{`
✓ Clean, readable formatting
✓ Only formats with `C-u C-x C-e` (insert at point)

---

## Example Outputs

### Simple map without :type
```clojure
=> {:a 1,
    :b 2}
```
Order preserved: `:a` then `:b`

### Map with :type at end (order preserved)
```clojure
Input:  {:a 1, :b 2, :type :Foo}
Output: => {:type :Foo,
            :a 1,
            :b 2}
```
`:type` moved to front, but `:a`, `:b` stay in original order

### Map with :type in middle (order preserved)
```clojure
Input:  {:a 1, :type :Foo, :b 2, :c 3}
Output: => {:type :Foo,
            :a 1,
            :b 2,
            :c 3}
```
`:type` first, then `:a`, `:b`, `:c` in original order

### Complex Example (from requirements)

**Input:**
```clojure
{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}
```

**Output:**
```clojure
=> {:type :deft.deft-test/Rectangle,
    :deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {:type :deft.deft-test/Position,
                         :deft.deft-test/x 1,
                         :deft.deft-test/y 2}}
```

Notice:
- `:type` is first at both levels
- Original order preserved: `side1`, `side2`, `pos` (outer), and `x`, `y` (inner)
- Nested map content perfectly aligned
- Much more readable than single-line format

### Multiple nested maps
```clojure
Input:  {:x {:a 1, :type :A}, :y {:b 2, :type :B}, :type :Root}
Output: => {:type :Root,
            :x {:type :A,
                :a 1},
            :y {:type :B,
                :b 2}}
```
Original order `:x`, `:y` preserved. Each nested map has `:type` first.

### String with comma (not broken)
```clojure
=> {:a "hello, world",
    :b 2}
```
String handling works correctly!

---

## Column Alignment Details

The formatter calculates column positions dynamically:

```clojure
=> {:key {:nested-key value,
          ^^^^^^^^^^^ aligns here
          :another 123}}
```

Alignment = current indentation + key length + 1
This creates clean, visually aligned output.

---

## Testing

Run `python3 test_formatter.py` to see all test cases.

All tests pass ✓
