;;; type-formatter-v3.el --- Reformat maps to put :type keys at the top (v3) -*- lexical-binding: t; -*-

;;; Commentary:
;; Uses Emacs sexp navigation for robust parsing

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-buffer ()
  "Reformat buffer to move :type keys to the top of maps."
  (interactive)
  (save-excursion
    (let ((positions nil))
      ;; Collect all map positions first
      (goto-char (point-min))
      (while (re-search-forward "{" nil t)
        (backward-char)
        (let ((start (point)))
          (condition-case nil
              (progn
                (forward-sexp)
                (push (cons start (point)) positions))
            (error nil)))
        (forward-char))

      ;; Process from last to first to avoid position shifts
      (dolist (pos (sort positions (lambda (a b) (> (car a) (car b)))))
        (type-formatter--reformat-one-map (car pos) (cdr pos))))))

(defun type-formatter--reformat-one-map (start end)
  "Reformat the map between START and END if it contains :type."
  (save-excursion
    (goto-char start)
    (let ((indent (current-indentation))
          (entries nil)
          (has-type nil))

      ;; Parse entries in this map
      (forward-char) ; Skip opening {
      (while (< (point) (1- end))
        ;; Skip whitespace
        (skip-chars-forward " \t\n")
        (when (< (point) (1- end))
          ;; Check if we're at a keyword
          (if (looking-at ":\\([^ \t\n,]+\\)")
              (let* ((key (match-string 0))
                     (key-end (match-end 0))
                     (value-start nil)
                     (value-end nil))

                ;; Mark if this is :type
                (when (string-match-p "^:type\\b" key)
                  (setq has-type t))

                ;; Skip whitespace after key
                (goto-char key-end)
                (skip-chars-forward " \t\n")
                (setq value-start (point))

                ;; Find value end
                (cond
                 ;; Nested map or list
                 ((looking-at "[{([]")
                  (forward-sexp)
                  (setq value-end (point)))
                 ;; Simple value (up to comma or closing brace)
                 (t
                  (if (re-search-forward "[,}]" end t)
                      (progn
                        (backward-char)
                        (setq value-end (point))
                        (skip-chars-forward " \t\n,"))
                    (setq value-end (1- end)))))

                ;; Store entry
                (push (cons key (string-trim (buffer-substring-no-properties value-start value-end)))
                      entries))

            ;; Not a keyword, skip it
            (forward-char))))

      ;; Reformat if we found :type
      (when has-type
        (setq entries (reverse entries))
        (let ((new-content (type-formatter--rebuild entries indent)))
          (delete-region start end)
          (goto-char start)
          (insert new-content))))))

(defun type-formatter--rebuild (entries indent)
  "Rebuild map from ENTRIES with :type first."
  (let* ((type-entry (cl-find-if (lambda (e) (string-match-p "^:type\\b" (car e))) entries))
         (other-entries (cl-remove-if (lambda (e) (string-match-p "^:type\\b" (car e))) entries))
         (ordered (if type-entry
                     (cons type-entry other-entries)
                   other-entries))
         (lines nil)
         (item-indent (make-string (+ indent 4) ?\s)))

    ;; Build output
    (push (concat (make-string indent ?\s) "{") lines)

    (let ((count (length ordered)))
      (cl-loop for entry in ordered
               for i from 1
               do (push (format "%s%s %s%s"
                               item-indent
                               (car entry)
                               (cdr entry)
                               (if (< i count) "," ""))
                       lines)))

    (push (concat (make-string indent ?\s) "}") lines)

    (mapconcat #'identity (reverse lines) "\n")))

(provide 'type-formatter-v3)
;;; type-formatter-v3.el ends here
