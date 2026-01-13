# Type Formatter for Emacs

An Emacs Lisp program that reformats Clojure-style map output to move `:type` key-value pairs to the top of their respective maps.

## Features

- Moves `:type` keys to the top of maps for better readability
- Handles nested maps recursively
- Preserves formatting and indentation
- Works on regions, buffers, or individual maps

## Installation

1. Save `type-formatter.el` to your Emacs load path
2. Add to your `.emacs` or `init.el`:

```elisp
(require 'type-formatter)
```

Or load it manually:

```elisp
(load-file "/path/to/type-formatter.el")
```

## Usage

### Interactive Commands

- `M-x type-formatter-format-buffer` - Format the entire buffer
- `M-x type-formatter-format-region` - Format the selected region
- `M-x type-formatter-format-at-point` - Format the map at point

### Example

**Before:**
```clojure
{:deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :deft.deft-test/x 1,
        :deft.deft-test/y 2,
        :type :deft.deft-test/Position},
    :type :deft.deft-test/Rectangle}
```

**After:**
```clojure
{
    :type :deft.deft-test/Rectangle,
    :deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :type :deft.deft-test/Position,
        :deft.deft-test/x 1,
        :deft.deft-test/y 2}
}
```

### Key Bindings (Optional)

You can add custom key bindings to your configuration:

```elisp
(global-set-key (kbd "C-c t f") 'type-formatter-format-buffer)
(global-set-key (kbd "C-c t r") 'type-formatter-format-region)
(global-set-key (kbd "C-c t p") 'type-formatter-format-at-point)
```

## How It Works

1. Parses map structures looking for `{...}` delimited regions
2. Identifies `:type` key-value pairs within each map
3. Reorders entries to place `:type` at the top
4. Preserves original indentation and formatting style
5. Handles nested maps recursively

## Testing

A test file `test-data.txt` is included with sample input. To test:

1. Open `test-data.txt` in Emacs
2. Run `M-x type-formatter-format-buffer`
3. Observe the reformatted output

## License

This is free and unencumbered software released into the public domain.
