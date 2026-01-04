# CIDER Format Maps

Formats Clojure maps in CIDER output with `:type` keys first and column-aligned indentation.

## Installation

Add to your `init.el`:

```elisp
(add-to-list 'load-path "/path/to/cider-format-maps")
(require 'cider-format-maps)
```

## Usage

- `C-x C-e` - Normal evaluation (no formatting)
- `C-u C-x C-e` - Insert result at point (formatted if it's a map)

## Features

- **:type keys first** - Automatically moves `:type` keys to the beginning of maps
- **Column alignment** - Nested content aligns with the column after `{`
- **Recursive** - Formats nested maps properly
- **Non-invasive** - Only formats when using `C-u C-x C-e`

## Example

**Before:**
```clojure
{:side1 1, :side2 3, :pos {:x 1, :y 2, :type :Position}, :type :Rectangle}
```

**After (C-u C-x C-e):**
```clojure
=> {:type :Rectangle,
    :pos {:type :Position,
          :x 1,
          :y 2},
    :side1 1,
    :side2 3}
```

See `DEMO.md` for more examples.

## How It Works

1. Parses the map into key-value pairs
2. Sorts entries (`:type` keys first)
3. Formats with column-aware indentation
4. Recursively formats nested maps

## Disable

```elisp
(advice-remove 'cider--display-interactive-eval-result #'cider-format-result)
(advice-remove 'cider-eval-last-sexp #'cider-format-track-insert)
```
