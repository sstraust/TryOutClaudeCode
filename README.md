# CIDER Format Maps

Formats Clojure maps in CIDER output when using `C-u C-x C-e` (insert at point).

## Installation

Add to your `init.el`:

```elisp
(add-to-list 'load-path "/path/to/cider-format-maps")
(require 'cider-format-maps)
```

## Usage

- `C-x C-e` - Normal evaluation, shows result in overlay (not formatted)
- `C-u C-x C-e` - Insert result at point (formatted if it's a map)

## Example

When you use `C-u C-x C-e` on a map expression:

**Before:**
```clojure
{:a 1, :b 2}
;; => {:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}
```

**After:**
```clojure
{:a 1, :b 2}
;; => {
;;   :deft.deft-test/side1 1,
;;   :deft.deft-test/side2 3,
;;   :deft.deft-test/pos {
;;     :deft.deft-test/x 1,
;;     :deft.deft-test/y 2,
;;     :type :deft.deft-test/Position},
;;   :type :deft.deft-test/Rectangle}
```

Note: Indentation aligns with the `=> ` prefix.

## How It Works

Advises CIDER to format maps only when inserting into buffer (C-u prefix). Adds newlines after commas with proper indentation based on nesting depth and aligns with the `=> ` prefix.

## Disable

```elisp
(advice-remove 'cider--display-interactive-eval-result #'cider-format-result)
(advice-remove 'cider-eval-last-sexp #'cider-format-track-insert)
```
