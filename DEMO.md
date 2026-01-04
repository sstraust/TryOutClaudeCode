# CIDER Format Maps - Output Examples

## Features

✓ `:type` keys appear first at every level
✓ Nested content aligns with column after opening `{`
✓ Clean, readable formatting
✓ Only formats with `C-u C-x C-e` (insert at point)

---

## Example Outputs

### Simple Map
```clojure
=> {:a 1,
    :b 2}
```

### Map with :type (moved to front)
```clojure
=> {:type :Foo,
    :a 1,
    :b 2}
```

### Nested Maps with :type
```clojure
=> {:type :Outer,
    :a 1,
    :b {:type :Inner,
        :c 2}}
```

### Complex Example (from requirements)

**Input:**
```clojure
{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}
```

**Output:**
```clojure
=> {:type :deft.deft-test/Rectangle,
    :deft.deft-test/pos {:type :deft.deft-test/Position,
                         :deft.deft-test/x 1,
                         :deft.deft-test/y 2},
    :deft.deft-test/side1 1,
    :deft.deft-test/side2 3}
```

Notice:
- `:type` is first at both the outer and nested map levels
- Nested map content (`:deft.deft-test/x`, `:deft.deft-test/y`) aligns perfectly
- Much more readable than the original single-line format

---

## Column Alignment

The formatter calculates column positions dynamically:

```clojure
=> {:key {:nested-key value,
          ^^^^^^^^^^^ aligns here (column after nested opening brace)
          :another 123}}
```

This creates clean, visually aligned output that's easy to scan.
