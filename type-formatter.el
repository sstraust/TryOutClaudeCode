;;; type-formatter.el --- Reformat maps to put :type keys at the top -*- lexical-binding: t; -*-

;;; Commentary:
;; This package provides functionality to reformat Clojure-like map output
;; so that :type key-value pairs appear at the top of their respective maps.

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-region (start end)
  "Reformat region between START and END to move :type keys to the top of maps."
  (interactive "r")
  (let ((text (buffer-substring-no-properties start end)))
    (let ((result (type-formatter--process-text text)))
      (delete-region start end)
      (goto-char start)
      (insert result))))

(defun type-formatter--process-text (text)
  "Process TEXT to reorder :type keys to the top of maps."
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    ;; Find and process each top-level and nested map
    (type-formatter--reformat-maps)
    (buffer-string)))

(defun type-formatter--reformat-maps ()
  "Find and reformat all maps in the current buffer."
  (let ((map-positions nil))
    ;; Find all map positions (from innermost to outermost)
    (goto-char (point-min))
    (while (re-search-forward "{" nil t)
      (backward-char)
      (let ((start (point)))
        (condition-case nil
            (progn
              (forward-sexp)
              (push (cons start (point)) map-positions))
          (scan-error nil)))
      (forward-char))

    ;; Process from innermost to outermost (largest start position first for same depth)
    (dolist (pos (sort map-positions (lambda (a b) (> (car a) (car b)))))
      (type-formatter--reformat-map-region (car pos) (cdr pos)))))

(defun type-formatter--reformat-map-region (start end)
  "Reformat a single map between START and END positions."
  (save-excursion
    (let* ((content (buffer-substring-no-properties start end))
           (parsed (type-formatter--parse-map-entries content)))
      (when (assoc ":type" parsed)
        (let ((base-indent (save-excursion
                            (goto-char start)
                            (current-indentation)))
              (reformatted (type-formatter--rebuild-map parsed base-indent)))
          (delete-region start end)
          (goto-char start)
          (insert reformatted))))))

(defun type-formatter--parse-map-entries (map-string)
  "Parse MAP-STRING and return an alist of (key . value-string) pairs."
  (let ((entries nil)
        (pos 0)
        (len (length map-string)))

    ;; Skip opening brace
    (when (string-match "^{" map-string)
      (setq pos 1))

    (while (< pos len)
      ;; Skip whitespace and commas
      (while (and (< pos len)
                  (memq (aref map-string pos) '(?\s ?\t ?\n ?, ?})))
        (setq pos (1+ pos)))

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

            ;; Skip whitespace after key
            (while (and (< pos len)
                       (memq (aref map-string pos) '(?\s ?\t ?\n)))
              (setq pos (1+ pos)))

            (setq value-start pos)

            ;; Find end of value
            (setq value-end (type-formatter--find-value-end map-string pos))
            (setq pos value-end)

            ;; Extract and store key-value pair
            (let ((key (substring map-string key-start key-end))
                  (value (string-trim (substring map-string value-start value-end))))
              ;; Remove trailing comma from value
              (when (string-suffix-p "," value)
                (setq value (substring value 0 -1))
                (setq value (string-trim value)))
              (push (cons key value) entries))))))

    (reverse entries)))

(defun type-formatter--find-value-end (str pos)
  "Find the end position of a value in STR starting at POS."
  (let ((len (length str))
        (depth 0)
        (in-string nil))

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

    pos))

(defun type-formatter--rebuild-map (entries base-indent)
  "Rebuild a map from ENTRIES with :type first, using BASE-INDENT."
  (let* ((type-entry (assoc ":type" entries))
         (other-entries (cl-remove ":type" entries :key #'car :test #'string=))
         (inner-indent (+ base-indent 4))
         (lines nil))

    ;; Opening brace
    (push "{" lines)

    ;; Add :type entry first if it exists
    (when type-entry
      (push (format "\n%s%s %s,"
                   (make-string inner-indent ?\s)
                   (car type-entry)
                   (cdr type-entry))
           lines))

    ;; Add other entries
    (let ((remaining (length other-entries)))
      (dolist (entry other-entries)
        (setq remaining (1- remaining))
        (push (format "\n%s%s %s%s"
                     (make-string inner-indent ?\s)
                     (car entry)
                     (cdr entry)
                     (if (> remaining 0) "," ""))
             lines)))

    ;; Closing brace
    (push (format "\n%s}" (make-string base-indent ?\s)) lines)

    (concat (make-string base-indent ?\s)
            (mapconcat #'identity (reverse lines) ""))))

(defun type-formatter-format-buffer ()
  "Reformat entire buffer to move :type keys to the top of maps."
  (interactive)
  (type-formatter-format-region (point-min) (point-max)))

(defun type-formatter-format-at-point ()
  "Reformat the map at point to move :type key to the top."
  (interactive)
  (save-excursion
    (let* ((start (progn
                   (while (and (not (bobp))
                              (not (looking-at "{")))
                     (backward-char))
                   (point)))
           (end (progn
                  (goto-char start)
                  (condition-case nil
                      (progn (forward-sexp) (point))
                    (error (point))))))
      (when (< start end)
        (type-formatter-format-region start end)))))

(provide 'type-formatter)
;;; type-formatter.el ends here
