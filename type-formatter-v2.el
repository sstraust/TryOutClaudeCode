;;; type-formatter-v2.el --- Reformat maps to put :type keys at the top (v2) -*- lexical-binding: t; -*-

;;; Commentary:
;; Simplified version that directly manipulates buffer text

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-buffer ()
  "Reformat buffer to move :type keys to the top of maps."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    ;; Process all maps from innermost to outermost
    (type-formatter--process-all-maps)))

(defun type-formatter--process-all-maps ()
  "Find and process all maps in buffer."
  (let ((map-ranges nil))
    ;; Find all map positions
    (goto-char (point-min))
    (while (search-forward "{" nil t)
      (backward-char)
      (let ((start (point)))
        (condition-case nil
            (progn
              (forward-sexp)
              (push (list start (point)) map-ranges))
          (scan-error nil)))
      (forward-char))

    ;; Process from end to beginning to avoid position shifts
    (dolist (range (sort map-ranges (lambda (a b) (> (car a) (car b)))))
      (apply #'type-formatter--process-map range))))

(defun type-formatter--process-map (start end)
  "Process a single map between START and END."
  (save-excursion
    (let* ((map-text (buffer-substring-no-properties start end))
           (map-indent (progn (goto-char start) (current-indentation)))
           (entries (type-formatter--extract-entries map-text)))

      ;; Only reformat if there's a :type key
      (when (cl-some (lambda (e) (string-match-p "^:type\\b" (car e))) entries)
        (let ((new-text (type-formatter--build-map entries map-indent)))
          (delete-region start end)
          (goto-char start)
          (insert new-text))))))

(defun type-formatter--extract-entries (map-text)
  "Extract key-value pairs from MAP-TEXT.
Returns list of (key . value) cons cells."
  (let ((entries nil)
        (lines (split-string map-text "\n")))

    (dolist (line lines)
      ;; Skip lines that are just braces
      (unless (string-match-p "^[ \t]*[{}][ \t]*$" line)
        ;; Try to match :key value pattern
        (when (string-match "^[ \t]*\\(:[^ \t\n,]+\\)[ \t]+\\(.*?\\)[ \t]*,?[ \t]*$" line)
          (let ((key (match-string 1 line))
                (value (match-string 2 line)))
            ;; Handle multiline values (values containing {)
            (when (and (string-match-p "{" value)
                      (not (string-match-p "}" value)))
              ;; This is the start of a nested map, need to capture more lines
              ;; For now, keep the value as-is
              )
            (push (cons key value) entries)))))

    (reverse entries)))

(defun type-formatter--build-map (entries indent)
  "Build map text from ENTRIES with :type first, using INDENT."
  (let* ((type-entries (cl-remove-if-not
                        (lambda (e) (string-match-p "^:type\\b" (car e)))
                        entries))
         (other-entries (cl-remove-if
                         (lambda (e) (string-match-p "^:type\\b" (car e)))
                         entries))
         (all-entries (append type-entries other-entries))
         (lines nil)
         (item-indent (+ indent 4)))

    ;; Opening brace
    (push (concat (make-string indent ?\s) "{") lines)

    ;; Add all entries
    (let ((remaining (length all-entries)))
      (dolist (entry all-entries)
        (let ((comma (if (> remaining 1) "," "")))
          (push (format "%s%s %s%s"
                       (make-string item-indent ?\s)
                       (car entry)
                       (cdr entry)
                       comma)
               lines)
          (setq remaining (1- remaining)))))

    ;; Closing brace
    (push (concat (make-string indent ?\s) "}") lines)

    (mapconcat #'identity (reverse lines) "\n")))

(provide 'type-formatter-v2)
;;; type-formatter-v2.el ends here
