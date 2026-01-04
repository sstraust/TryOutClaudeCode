;;; type-formatter-new.el --- Reformat maps to put :type keys at the top -*- lexical-binding: t; -*-

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-buffer ()
  "Reformat buffer to move :type keys to the top of maps."
  (interactive)
  (save-excursion
    ;; Find all maps and process from innermost to outermost
    (let ((map-positions nil))
      (goto-char (point-min))
      (while (search-forward "{" nil t)
        (backward-char)
        (let ((start (point)))
          (ignore-errors
            (forward-sexp)
            (push (cons start (point)) map-positions)))
        (forward-char))

      ;; Sort by start position descending (process innermost first)
      (setq map-positions (sort map-positions (lambda (a b) (> (car a) (car b)))))

      ;; Process each map
      (dolist (pos map-positions)
        (type-formatter--process-map (car pos) (cdr pos))))))

(defun type-formatter--process-map (start end)
  "Process map between START and END."
  (let* ((map-text (buffer-substring-no-properties start end))
         (lines (split-string map-text "\n"))
         (entries nil)
         (base-indent nil)
         (first-line-has-entry nil))

    ;; Parse the map
    (dolist (line lines)
      (cond
       ;; Opening brace line
       ((string-match "^\\([ \t]*\\){\\(.*\\)$" line)
        (setq base-indent (match-string 1 line))
        (let ((rest (match-string 2 line)))
          (when (string-match "^\\(:[^ \t,]+\\)[ \t]+\\([^,]+\\),?[ \t]*$" rest)
            (setq first-line-has-entry t)
            (push (cons (match-string 1 rest) (match-string 2 rest)) entries))))

       ;; Closing brace line - skip
       ((string-match "^[ \t]*}[ \t]*$" line)
        nil)

       ;; Entry line
       ((string-match "^[ \t]*\\(:[^ \t,]+\\)[ \t]+\\(.*?\\)[ \t]*,?[ \t]*$" line)
        (let ((key (match-string 1 line))
              (value (match-string 2 line)))
          (push (cons key value) entries)))))

    ;; Reverse to get original order
    (setq entries (nreverse entries))

    ;; Check if we have a :type entry
    (let ((type-entry (cl-find-if (lambda (e) (string-match "^:type\\b" (car e))) entries)))
      (when type-entry
        ;; Reorder with :type first
        (setq entries (cons type-entry
                           (cl-remove-if (lambda (e) (string-match "^:type\\b" (car e))) entries)))

        ;; Rebuild the map
        (let ((new-text (type-formatter--build-map entries base-indent first-line-has-entry)))
          (delete-region start end)
          (goto-char start)
          (insert new-text))))))

(defun type-formatter--build-map (entries base-indent same-line)
  "Build map text from ENTRIES."
  (let ((lines nil)
        (item-indent (concat base-indent "    ")))

    (if same-line
        ;; First entry on same line as {
        (progn
          (let ((first (car entries))
                (rest (cdr entries)))
            ;; Opening with first entry
            (push (format "%s{%s %s%s"
                         base-indent
                         (car first)
                         (cdr first)
                         (if rest "," ""))
                 lines)

            ;; Remaining entries
            (let ((remaining (length rest)))
              (dolist (entry rest)
                (setq remaining (1- remaining))
                (push (format "%s%s %s%s"
                             item-indent
                             (car entry)
                             (cdr entry)
                             (if (> remaining 0) "," ""))
                     lines))))

          ;; Closing brace
          (push (concat base-indent "}") lines))

      ;; Traditional format
      (progn
        (push (concat base-indent "{") lines)

        (let ((remaining (length entries)))
          (dolist (entry entries)
            (setq remaining (1- remaining))
            (push (format "%s%s %s%s"
                         item-indent
                         (car entry)
                         (cdr entry)
                         (if (> remaining 0) "," ""))
                 lines)))

        (push (concat base-indent "}") lines)))

    (mapconcat #'identity (nreverse lines) "\n")))

(provide 'type-formatter-new)
;;; type-formatter-new.el ends here
