;;; debug-formatter.el --- Debug the type formatter -*- lexical-binding: t; -*-

(require 'cl-lib)

;; Test the parse function directly
(defun debug-parse-test ()
  "Test parsing a simple map."
  (let* ((test-input "{:a 1, :b 2, :type :Foo}")
         (result (debug-parse-map-entries test-input)))
    (message "Input: %s" test-input)
    (message "Parsed: %S" result)
    result))

(defun debug-parse-map-entries (map-string)
  "Parse MAP-STRING and return an alist of (key . value-string) pairs."
  (let ((entries nil)
        (pos 0)
        (len (length map-string)))

    ;; Skip opening brace
    (when (string-match "^{" map-string)
      (setq pos 1)
      (message "Skipped opening brace, pos=%d" pos))

    (while (< pos len)
      ;; Skip whitespace and commas
      (while (and (< pos len)
                  (memq (aref map-string pos) '(?\s ?\t ?\n ?, ?})))
        (setq pos (1+ pos)))

      (message "After skipping whitespace, pos=%d, char=%c" pos (if (< pos len) (aref map-string pos) ?X))

      (when (< pos len)
        ;; Look for a keyword
        (when (eq (aref map-string pos) ?:)
          (let ((key-start pos)
                (key-end nil)
                (value-start nil)
                (value-end nil))

            ;; Find end of key (keyword followed by whitespace)
            (while (and (< pos len)
                       (not (memq (aref map-string pos) '(?\s ?\t ?\n))))
              (setq pos (1+ pos)))
            (setq key-end pos)

            (let ((key (substring map-string key-start key-end)))
              (message "Found key: %s (pos %d to %d)" key key-start key-end)

              ;; Skip whitespace after key
              (while (and (< pos len)
                         (memq (aref map-string pos) '(?\s ?\t ?\n)))
                (setq pos (1+ pos)))

              (setq value-start pos)
              (message "Value starts at pos=%d" value-start)

              ;; Find end of value
              (setq value-end (debug-find-value-end map-string pos))
              (message "Value ends at pos=%d" value-end)
              (setq pos value-end)

              ;; Extract and store key-value pair
              (let ((value (string-trim (substring map-string value-start value-end))))
                ;; Remove trailing comma from value
                (when (string-suffix-p "," value)
                  (setq value (substring value 0 -1))
                  (setq value (string-trim value)))
                (message "Storing: %s -> %s" key value)
                (push (cons key value) entries)))))))

    (message "Final entries (reversed): %S" (reverse entries))
    (reverse entries)))

(defun debug-find-value-end (str pos)
  "Find the end position of a value in STR starting at POS."
  (let ((len (length str))
        (depth 0)
        (in-string nil)
        (start-pos pos))

    (while (and (< pos len)
                (or (> depth 0)
                    in-string
                    (not (memq (aref str pos) '(?, ?})))))
      (let ((ch (aref str pos)))
        (cond
         ;; Handle string literals
         ((eq ch ?\")
          (setq in-string (not in-string)))
         ;; Track nesting depth (not in strings)
         ((and (not in-string) (memq ch '(?{ ?\()))
          (setq depth (1+ depth)))
         ((and (not in-string) (memq ch '(?} ?\))))
          (setq depth (1- depth)))))
      (setq pos (1+ pos)))

    (message "find-value-end: from %d to %d (depth=%d, in-string=%s)" start-pos pos depth in-string)
    pos))

;; Run tests
(debug-parse-test)

(provide 'debug-formatter)
