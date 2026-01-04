;;; type-formatter-final.el --- Move :type to top of maps -*- lexical-binding: t; -*-

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

      ;; Process from last to first
      (dolist (pos (sort positions (lambda (a b) (> (car a) (car b)))))
        (tf--process-map (car pos) (cdr pos))))))

(defun tf--process-map (start end)
  "Process a single map."
  (save-excursion
    (goto-char start)
    (let ((base-indent (current-indentation))
          (entries nil)
          (has-type nil)
          (same-line nil))

      ;; Check if first entry on same line
      (save-excursion
        (forward-char) ; skip {
        (skip-chars-forward " \t")
        (setq same-line (not (looking-at "\n"))))

      ;; Parse entries
      (goto-char (1+ start)) ; skip {
      (while (< (point) (1- end))
        (skip-chars-forward " \t\n,")

        (when (and (< (point) (1- end))
                  (looking-at ":\\([^ \t\n,{}()]+\\)"))
          (let* ((key (match-string 0))
                 (key-end (match-end 0)))

            (when (string-match "^:type\\b" key)
              (setq has-type t))

            ;; Move past key and whitespace
            (goto-char key-end)
            (skip-chars-forward " \t\n")

            ;; Get value
            (let ((val-start (point))
                  (val-end (point)))

              (cond
               ;; Nested structure
               ((looking-at "[{([]")
                (ignore-errors
                  (forward-sexp)
                  (setq val-end (point))))

               ;; Simple value - find comma or }
               (t
                (if (search-forward-regexp "[,}]" end t)
                    (progn
                      (backward-char)
                      (setq val-end (point)))
                  (setq val-end (1- end)))))

              (let ((value (string-trim
                           (buffer-substring-no-properties val-start val-end))))
                (push (cons key value) entries))

              (goto-char val-end)))))

      ;; Reformat if has :type
      (when has-type
        (setq entries (nreverse entries))
        (let* ((type-entry (cl-find-if
                           (lambda (e) (string-match "^:type\\b" (car e)))
                           entries))
               (other-entries (cl-remove-if
                              (lambda (e) (string-match "^:type\\b" (car e)))
                              entries))
               (ordered (cons type-entry other-entries))
               (new-text (tf--build-map ordered base-indent same-line)))

          (delete-region start end)
          (goto-char start)
          (insert new-text))))))

(defun tf--build-map (entries indent same-line)
  "Build map from ENTRIES."
  (let ((base (make-string indent ?\s))
        (item (make-string (+ indent 4) ?\s))
        (lines nil))

    (if same-line
        ;; Compact: {key val,
        (let ((first (car entries))
              (rest (cdr entries)))
          (push (format "%s{%s %s%s"
                       base
                       (car first)
                       (cdr first)
                       (if rest "," ""))
               lines)
          (let ((n (length rest)))
            (dolist (e rest)
              (setq n (1- n))
              (push (format "%s%s %s%s"
                           item
                           (car e)
                           (cdr e)
                           (if (> n 0) "," ""))
                   lines)))
          (push (concat base "}") lines))

      ;; Standard: {\n  key val,
      (push (concat base "{") lines)
      (let ((n (length entries)))
        (dolist (e entries)
          (setq n (1- n))
          (push (format "%s%s %s%s"
                       item
                       (car e)
                       (cdr e)
                       (if (> n 0) "," ""))
               lines)))
      (push (concat base "}") lines))

    (mapconcat #'identity (nreverse lines) "\n")))

(provide 'type-formatter-final)
