;;; type-formatter.el --- Reformat maps to put :type keys at the top -*- lexical-binding: t; -*-

;;; Commentary:
;; This package provides functionality to reformat Clojure-like map output
;; so that :type key-value pairs appear at the top of their respective maps.

;;; Code:

(require 'cl-lib)

(defvar type-formatter-debug nil
  "If non-nil, print debug messages during formatting.")

(defun type-formatter-format-buffer ()
  "Reformat buffer to move :type keys to the top of maps."
  (interactive)
  (save-excursion
    (let ((positions nil))
      ;; Collect all map positions
      (goto-char (point-min))
      (while (re-search-forward "{" nil t)
        (backward-char)
        (let ((start (point)))
          (condition-case err
              (progn
                (forward-sexp)
                (push (cons start (point)) positions))
            (error
             (when type-formatter-debug
               (message "Scan error at %d: %s" start err)))))
        (goto-char (min (1+ (point)) (point-max))))

      (when type-formatter-debug
        (message "Found %d maps" (length positions)))

      ;; Process from last to first
      (dolist (pos (sort positions (lambda (a b) (> (car a) (car b)))))
        (type-formatter--reformat-one-map (car pos) (cdr pos))))))

(defun type-formatter--reformat-one-map (start end)
  "Reformat the map between START and END if it contains :type."
  (save-excursion
    (goto-char start)
    (let ((indent (current-indentation))
          (entries nil)
          (has-type nil))

      (when type-formatter-debug
        (message "Processing map at %d-%d, indent=%d" start end indent))

      ;; Parse entries
      (forward-char) ; Skip {
      (while (and (< (point) (1- end))
                 (not (eobp)))
        (skip-chars-forward " \t\n,")

        (when (and (< (point) (1- end))
                  (not (looking-at "}")))
          (if (looking-at ":\\([^ \t\n,{}]+\\)")
              (let* ((key (match-string 0))
                     (key-end (match-end 0)))

                (when (string-match-p "^:type\\b" key)
                  (setq has-type t)
                  (when type-formatter-debug
                    (message "Found :type at %d" (point))))

                (goto-char key-end)
                (skip-chars-forward " \t\n")
                (let ((value-start (point))
                      (value-end (point)))

                  ;; Find value end
                  (cond
                   ((looking-at "[{([]")
                    (condition-case nil
                        (progn
                          (forward-sexp)
                          (setq value-end (point)))
                      (error
                       (goto-char (1- end)))))
                   (t
                    (when (re-search-forward "[,}]" end t)
                      (backward-char)
                      (setq value-end (point)))))

                  (let ((value (string-trim
                               (buffer-substring-no-properties value-start value-end))))
                    (when type-formatter-debug
                      (message "Entry: %s -> %s" key value))
                    (push (cons key value) entries))

                  (goto-char value-end)))

            ;; Not a keyword, skip forward
            (forward-char))))

      ;; Reformat if has :type
      (when has-type
        (when type-formatter-debug
          (message "Reformatting map with %d entries" (length entries)))

        (setq entries (reverse entries))
        (let ((new-content (type-formatter--rebuild entries indent)))
          (delete-region start end)
          (goto-char start)
          (insert new-content))))))

(defun type-formatter--rebuild (entries indent)
  "Rebuild map from ENTRIES with :type first."
  (let* ((type-entry (cl-find-if
                      (lambda (e) (string-match-p "^:type\\b" (car e)))
                      entries))
         (other-entries (cl-remove-if
                        (lambda (e) (string-match-p "^:type\\b" (car e)))
                        entries))
         (ordered (if type-entry
                     (cons type-entry other-entries)
                   other-entries))
         (lines nil)
         (item-indent (make-string (+ indent 4) ?\s))
         (base-indent (make-string indent ?\s)))

    ;; Opening brace
    (push (concat base-indent "{") lines)

    ;; Entries
    (let ((count (length ordered))
          (i 0))
      (dolist (entry ordered)
        (setq i (1+ i))
        (push (format "%s%s %s%s"
                     item-indent
                     (car entry)
                     (cdr entry)
                     (if (< i count) "," ""))
             lines)))

    ;; Closing brace
    (push (concat base-indent "}") lines)

    (mapconcat #'identity (reverse lines) "\n")))

(provide 'type-formatter)
;;; type-formatter.el ends here
