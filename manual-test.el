;;; manual-test.el --- Manual validation

(defun manual-test ()
  "Manual test of parsing logic."
  (with-temp-buffer
    (insert "{:deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :deft.deft-test/x 1,
        :deft.deft-test/y 2,
        :type :deft.deft-test/Position},
    :type :deft.deft-test/Rectangle}")

    (let ((start 1)
          (end (point-max)))

      (message "Buffer content:\n%s" (buffer-string))
      (message "\nStart: %d, End: %d" start end)

      ;; Test forward-sexp
      (goto-char start)
      (message "\nAt position %d, char: %c" (point) (char-after))
      (forward-sexp)
      (message "After forward-sexp, at position %d" (point))

      ;; Test finding nested map
      (goto-char start)
      (when (search-forward ":deft.deft-test/pos" nil t)
        (message "\nFound :deft.deft-test/pos at %d" (point))
        (skip-chars-forward " \t\n")
        (message "After whitespace, at %d, char: %c" (point) (char-after))
        (when (eq (char-after) ?{)
          (let ((nested-start (point)))
            (forward-sexp)
            (let ((nested-end (point)))
              (message "Nested map from %d to %d" nested-start nested-end)
              (message "Nested content:\n%s"
                      (buffer-substring-no-properties nested-start nested-end))))))

      ;; Test entry parsing
      (goto-char (1+ start))
      (message "\n\nParsing entries:")
      (let ((entries nil))
        (while (< (point) (1- end))
          (skip-chars-forward " \t\n,")
          (when (and (< (point) (1- end))
                    (looking-at ":\\([^ \t\n,{}()]+\\)"))
            (let ((key (match-string 0)))
              (goto-char (match-end 0))
              (skip-chars-forward " \t\n")
              (let ((val-start (point)))
                (cond
                 ((looking-at "[{([]")
                  (forward-sexp)
                  (let ((value (buffer-substring-no-properties val-start (point))))
                    (message "  %s -> %s" key (replace-regexp-in-string "\n" "\\\\n" value))
                    (push (cons key value) entries)))
                 (t
                  (when (search-forward-regexp "[,}]" end t)
                    (backward-char)
                    (let ((value (string-trim (buffer-substring-no-properties val-start (point)))))
                      (message "  %s -> %s" key value)
                      (push (cons key value) entries)))))))))

        (message "\nTotal entries: %d" (length entries))
        (message "Entries (in order): %S" (nreverse entries))))))

(manual-test)
