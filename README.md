# CIDER Format Maps

Formats Clojure maps in CIDER output when using `C-x C-e`.

## Installation

Add to your `init.el`:

```elisp
(add-to-list 'load-path "/path/to/cider-format-maps")
(require 'cider-format-maps)
```

That's it. No configuration needed.

## Example

**Before:**
```clojure
{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}
```

**After:**
```clojure
{
  :deft.deft-test/side1 1,
  :deft.deft-test/side2 3,
  :deft.deft-test/pos {
    :deft.deft-test/x 1,
    :deft.deft-test/y 2,
    :type :deft.deft-test/Position},
  :type :deft.deft-test/Rectangle}
```

## How It Works

Advises `cider--display-interactive-eval-result` to format maps before display. Adds newlines and indentation after commas based on nesting depth.

## Disable

```elisp
(advice-remove 'cider--display-interactive-eval-result #'cider-format-result)
```
