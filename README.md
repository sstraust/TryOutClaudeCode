# CIDER Format Maps

An Emacs Lisp package that automatically formats Clojure maps in CIDER output for better readability.

## Features

- Automatically formats map output when using `C-x C-e` (eval-last-sexp) in CIDER
- Preserves syntax highlighting
- Handles nested maps with proper indentation
- Can be toggled on/off
- Works seamlessly with existing CIDER functionality

## Installation

### Manual Installation

1. Copy `cider-format-maps.el` to your Emacs load path
2. Add to your `init.el` or `.emacs`:

```elisp
(require 'cider-format-maps)
(cider-format-maps-mode 1)
```

### Using use-package

```elisp
(use-package cider-format-maps
  :load-path "/path/to/cider-format-maps"
  :after cider
  :config
  (cider-format-maps-mode 1))
```

## Usage

Once enabled, the package automatically formats map output when you evaluate Clojure expressions.

### Example

**Before formatting:**
```clojure
{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}
```

**After formatting:**
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

### Commands

- `M-x cider-format-maps-mode` - Toggle formatting mode globally
- `M-x cider-format-maps-enable` - Enable formatting
- `M-x cider-format-maps-disable` - Disable formatting

### Customization

You can customize the behavior by setting:

```elisp
(setq cider-format-maps-enabled t)  ; Enable/disable formatting
```

## How It Works

The package advises CIDER's result display function to format maps before they're shown in the echo area or overlay. It:

1. Detects when the evaluation result is a Clojure map
2. Parses the map structure
3. Reformats with proper indentation
4. Preserves all syntax highlighting and CIDER features

## Testing

A test Clojure file is provided in `test-maps.clj`. Open it in Emacs with CIDER running and use `C-x C-e` after each expression to see the formatted output.

## Requirements

- Emacs 25.1 or later
- CIDER 1.0 or later

## License

Free to use and modify.
