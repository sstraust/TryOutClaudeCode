# Manual Test of cider-format-map

## Test 1: Simple Map
**Input:** `{:a 1, :b 2}`
**Prefix-length:** 3

### Trace:
1. Start at position 0: `{:a 1, :b 2}`
2. skip-chars-forward finds `{` at position 0
3. char = `{`, depth = 1, forward-char → position 1
4. skip-chars-forward finds `,` at position 5
5. char = `,`, forward-char → position 6
6. Remove space after comma: " " → ""
7. Next char is `:` (not `}`), insert `\n` + 5 spaces (3 + 2*1)
8. Buffer now: `{:a 1,\n     :b 2}`
9. skip-chars-forward finds no more special chars
10. Return buffer string

**Expected:** `{:a 1,\n   :b 2}` (3 + 2*1 = 5 spaces) ✗ **ISSUE: Should be 3 spaces, not 5**

Wait, let me re-check the indentation logic:
- base-indent = 3
- After first `{`, depth = 1
- For comma at depth 1: indent = base-indent + 2*depth = 3 + 2*1 = 5

But the expected output shows 3 spaces. Let me reconsider what the requirement is.

Looking at the original requirement:
```
{:deft.deft-test/side1 1,
  :deft.deft-test/side2 3,
  :deft.deft-test/pos {:deft.deft-test/x 1,
                                              :deft.deft-test/y 2,
```

The first level shows 2 spaces of indentation, and nested levels show more. So:
- After first `{`, the content should be at +2 spaces from base
- base-indent is for aligning with "=> " which is 3 chars

Actually, I think the indentation calculation has an off-by-one error. Let me trace more carefully:

## Indentation Analysis

For `{:a 1, :b 2}`:
- At the opening `{`, depth becomes 1
- At the comma, we're at depth 1
- Indentation = 3 + 2*1 = 5 spaces
- But we want 2 spaces for first level content

The issue is: after seeing `{`, depth is incremented to 1, but the content inside should be at depth 0 indentation (plus base).

## Test 2: Critical Bug - String with Comma
**Input:** `{:a "hello, world", :b 2}`
**Prefix-length:** 3

### Trace:
1. skip-chars-forward finds `{` at position 0
2. char = `{`, depth = 1, forward to position 1
3. skip-chars-forward finds `"` at position 4
4. char = `"`, forward-char, re-search-forward for closing `"`
5. Finds closing `"` at position 17, moves to position 18
6. skip-chars-forward finds `,` at position 18
7. char = `,`, processes normally without breaking the string ✓

This should work correctly!

## Test 3: Empty Map
**Input:** `{}`

### Trace:
1. skip-chars-forward finds `{` at position 0
2. char = `{`, depth = 1, forward to position 1
3. skip-chars-forward finds `}` at position 1
4. char = `}`, depth = max(0, 0) = 0, forward to position 2
5. eobp = true, exit loop
6. Return `{}`

This works correctly! ✓

## Issues Found

### Indentation Bug
The indentation is calculated as `base-indent + 2*depth`, where depth is incremented AFTER seeing `{`.

For the first level:
- Current: depth=1, indent = 3 + 2*1 = 5 spaces
- Wanted: indent = 3 + 2 = 5 spaces (maybe this is correct?)

Wait, for "=> {", the content should align like:
```
=> {:a 1,
   ^--- this is position 3 (after "=> ")
```

So for first-level content after a comma:
```
=> {:a 1,
   :b 2}
   ^--- this should be at position 3
```

That's 3 spaces total, not 5. So the formula should be:
- `base-indent + 2*(depth-1)` when depth >= 1

Or we should increment depth AFTER processing the opening brace content.

Let me check the nested case:
```
{:a {:b 1,
     ^--- nested content
       :c 2}}
```

After first `{`: depth=1
After second `{`: depth=2
At comma inside nested map: indent = 3 + 2*2 = 7

But we want alignment at 5 spaces (3 for "=> " + 2 for first level):
```
=> {:a {:b 1,
       :c 2}}
       ^--- 5 spaces from start
```

Actually no, looking at the original desired output:
```
{:deft.deft-test/side1 1,
  :deft.deft-test/side2 3,
  :deft.deft-test/pos {:deft.deft-test/x 1,
                                              :deft.deft-test/y 2,
```

Wait, the nested content is heavily indented to align with the opening character position. That's not what our simple formula does.

Let me re-read the original requirement more carefully.
