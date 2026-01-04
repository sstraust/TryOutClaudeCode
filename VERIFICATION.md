# Code Verification - Type Formatter

## Input
```clojure
{:deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :deft.deft-test/x 1,
        :deft.deft-test/y 2,
        :type :deft.deft-test/Position},
    :type :deft.deft-test/Rectangle}
```

## Expected Output
```clojure
{
    :type :deft.deft-test/Rectangle,
    :deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :type :deft.deft-test/Position,
        :deft.deft-test/x 1,
        :deft.deft-test/y 2
    }
}
```

## Logic Trace

### Step 1: Find All Maps
Using `forward-sexp` to match braces:
1. Outer map: position 0 to end
2. Inner map: position after `:deft.deft-test/pos ` to closing `}`

### Step 2: Process Inner Map First (Innermost to Outermost)

**Input:**
```clojure
{
    :deft.deft-test/x 1,
    :deft.deft-test/y 2,
    :type :deft.deft-test/Position}
```

**Parse Entries:**
- Parse character by character
- Skip `{` and whitespace
- Find `:deft.deft-test/x` → value `1` (stops at `,`)
- Find `:deft.deft-test/y` → value `2` (stops at `,`)
- Find `:type` → value `:deft.deft-test/Position` (stops at `}`)

**Entries:**
```
[(:deft.deft-test/x . "1"),
 (:deft.deft-test/y . "2"),
 (:type . ":deft.deft-test/Position")]
```

**Has :type?** Yes

**Base Indent:** 4 (indentation of line with `{`)
**Inner Indent:** 8 (base + 4)

**Rebuild:**
```
    {
        :type :deft.deft-test/Position,
        :deft.deft-test/x 1,
        :deft.deft-test/y 2
    }
```

### Step 3: Process Outer Map

After inner map is reformatted, parse outer map:

**Parse Entries:**
- `:deft.deft-test/side1` → `"1"`
- `:deft.deft-test/side2` → `"3"`
- `:deft.deft-test/pos` → `"    {\n        :type :deft.deft-test/Position,\n        :deft.deft-test/x 1,\n        :deft.deft-test/y 2\n    }"` (multiline string)
- `:type` → `":deft.deft-test/Rectangle"`

**Has :type?** Yes

**Base Indent:** 0
**Inner Indent:** 4

**Rebuild:**
```
{
    :type :deft.deft-test/Rectangle,
    :deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :type :deft.deft-test/Position,
        :deft.deft-test/x 1,
        :deft.deft-test/y 2
    }
}
```

## Key Algorithm Components

### 1. `type-formatter--find-value-end`
Correctly handles:
- Nested braces `{}`
- Nested parentheses `()`
- String literals with `"`
- Stops at `,` or `}` when at depth 0

### 2. `type-formatter--parse-map-entries`
- Character-by-character parsing
- Tracks brace depth via `find-value-end`
- Handles multiline values
- Strips trailing commas

### 3. `type-formatter--rebuild-map`
- Places `:type` entry first
- Preserves other entry order
- Maintains proper indentation (base + 4 for content)
- Adds commas between entries (except last)

## Verification Result

✅ **Logic is correct**

The algorithm will:
1. Find nested maps using `forward-sexp`
2. Process from innermost to outermost
3. Parse each map into key-value pairs
4. Rebuild with `:type` first
5. Preserve nested structure with proper indentation

Both `:type` entries will be moved to the top of their respective maps.
