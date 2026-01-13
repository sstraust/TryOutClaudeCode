;;; type-formatter.el --- Reformat maps to put :type keys at the top -*- lexical-binding: t; -*-

;;; Commentary:
;; Reformats Clojure-style maps so :type key-value pairs appear first

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-buffer ()
  "Reformat buffer to move :type keys to the top of maps."
  (interactive)
  (save-excursion
    (let ((positions nil))
      ;; Find all maps
      (goto-char (point-min))
      (while (search-forward "{" nil t)
        (backward-char)
        (let ((start (point)))
          (ignore-errors
            (forward-sexp)
            (push (cons start (point)) positions)))
        (forward-char))

      ;; Process from innermost to outermost (highest position first)
      (dolist (pos (sort positions (lambda (a b) (> (car a) (car b)))))
        (type-formatter--process-map (car pos) (cdr pos))))))

(defun type-formatter--process-map (start end)
  "Process a single map between START and END."
  (save-excursion
    (goto-char start)
    (let ((base-indent (current-indentation))
          (entries nil)
          (has-type nil)
          (compact nil))

      ;; Check if first entry is on same line as opening brace
      (save-excursion
        (forward-char) ; skip {
        (skip-chars-forward " \t")
        (setq compact (not (looking-at "\n"))))

      ;; Parse all entries
      (goto-char (1+ start)) ; skip {
      (while (< (point) (1- end))
        (skip-chars-forward " \t\n,")

        (when (and (< (point) (1- end))
                  (not (looking-at "}"))
                  (looking-at ":\\([^ \t\n,{}()\\[\\]]+\\)"))
          (let* ((key (match-string 0))
                 (key-end (match-end 0)))

            ;; Check if this is :type
            (when (string-match "^:type\\b" key)
              (setq has-type t))

            ;; Move past key and whitespace
            (goto-char key-end)
            (skip-chars-forward " \t\n")

            ;; Extract value
            (let ((val-start (point))
                  (val-end (point)))

              (cond
               ;; Nested structure - use forward-sexp
               ((looking-at "[{(\\[]")
                (ignore-errors
                  (forward-sexp)
                  (setq val-end (point))))

               ;; Simple value - find next comma or closing brace
               (t
                (if (re-search-forward "[,}]" end t)
                    (progn
                      (backward-char)
                      (setq val-end (point)))
                  (setq val-end (1- end)))))

              ;; Store entry
              (let ((value (string-trim
                           (buffer-substring-no-properties val-start val-end))))
                (push (cons key value) entries))

              (goto-char val-end)))))

      ;; Reformat if we found :type
      (when has-type
        (setq entries (nreverse entries))

        (let* ((type-entry (cl-find-if
                           (lambda (e) (string-match "^:type\\b" (car e)))
                           entries))
               (other-entries (cl-remove-if
                              (lambda (e) (string-match "^:type\\b" (car e)))
                              entries))
               (ordered (cons type-entry other-entries))
               (new-text (type-formatter--build-map ordered base-indent compact)))

          (delete-region start end)
          (goto-char start)
          (insert new-text))))))

(defun type-formatter--build-map (entries indent compact)
  "Build map text from ENTRIES with base INDENT.
If COMPACT is non-nil, put first entry on same line as opening brace."
  (let ((base (make-string indent ?\s))
        (item (make-string (+ indent 4) ?\s))
        (lines nil))

    (if compact
        ;; Compact format: {key val,
        (let ((first (car entries))
              (rest (cdr entries))
              (count (length entries)))
          ;; Opening brace with first entry
          (if (= count 1)
              ;; Single entry: {key val}
              (push (format "%s{%s %s}" base (car first) (cdr first)) lines)
            ;; Multiple entries
            (progn
              (push (format "%s{%s %s," base (car first) (cdr first)) lines)
              ;; Remaining entries (last one gets })
              (let ((remaining (length rest)))
                (dolist (entry rest)
                  (setq remaining (1- remaining))
                  (push (format "%s%s %s%s"
                               item
                               (car entry)
                               (cdr entry)
                               (if (> remaining 0) "," "}"))
                       lines))))))

      ;; Standard format: { on own line
      (push (concat base "{") lines)
      (let ((remaining (length entries)))
        (dolist (entry entries)
          (setq remaining (1- remaining))
          (push (format "%s%s %s%s"
                       item
                       (car entry)
                       (cdr entry)
                       (if (> remaining 0) "," "}"))
               lines))))

    (mapconcat #'identity (nreverse lines) "\n")))

(provide 'type-formatter)
;;; type-formatter.el ends here
