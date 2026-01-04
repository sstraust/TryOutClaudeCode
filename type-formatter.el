;;; type-formatter.el --- Reformat maps to put :type keys at the top -*- lexical-binding: t; -*-

;;; Commentary:
;; This package provides functionality to reformat Clojure-like map output
;; so that :type key-value pairs appear at the top of their respective maps.

;;; Code:

(require 'cl-lib)

(defun type-formatter-format-region (start end)
  "Reformat region between START and END to move :type keys to the top of maps."
  (interactive "r")
  (save-excursion
    (save-restriction
      (narrow-to-region start end)
      (goto-char (point-min))
      (type-formatter--process-all-maps))))

(defun type-formatter--process-all-maps ()
  "Process all maps in the buffer, moving :type to the top."
  ;; Process from end to beginning to avoid position shifts
  (let ((positions nil))
    ;; First, find all map positions
    (goto-char (point-min))
    (while (re-search-forward "{" nil t)
      (let ((start (1- (point))))
        (goto-char start)
        (condition-case nil
            (progn
              (forward-sexp)
              (push (cons start (point)) positions))
          (error nil))))
    ;; Process maps from end to beginning
    (dolist (pos (sort positions (lambda (a b) (> (car a) (car b)))))
      (type-formatter--reformat-map-at (car pos) (cdr pos)))))

(defun type-formatter--reformat-map-at (start end)
  "Reformat the map between START and END."
  (let* ((content (buffer-substring-no-properties start end))
         (entries (type-formatter--parse-map content))
         (type-entry (cl-find-if (lambda (e) (string-match "^:type\\s-" (car e))) entries))
         (other-entries (cl-remove-if (lambda (e) (string-match "^:type\\s-" (car e))) entries)))
    (when type-entry
      (let* ((indent (save-excursion
                      (goto-char start)
                      (current-indentation)))
             (reformatted (type-formatter--build-map type-entry other-entries indent)))
        (delete-region start end)
        (goto-char start)
        (insert reformatted)))))

(defun type-formatter--parse-map (map-str)
  "Parse MAP-STR into a list of (key . value) pairs, preserving formatting."
  (let ((entries nil)
        (current-key nil)
        (current-value nil)
        (in-nested 0)
        (lines (split-string map-str "\n" t)))

    (dolist (line lines)
      ;; Skip opening and closing braces on their own lines
      (unless (string-match "^\\s-*{\\s-*$\\|^\\s-*}\\s-*$" line)
        (let ((trimmed (string-trim line)))
          (cond
           ;; Check for key-value on same line
           ((and (string-match "^\\(:[-a-zA-Z0-9._/]+\\)\\s-+\\(.+?\\),?\\s-*$" trimmed)
                 (= in-nested 0))
            (when current-key
              (push (cons current-key (string-trim current-value)) entries))
            (setq current-key (match-string 1 trimmed))
            (setq current-value (match-string 2 trimmed)))
           ;; Just a key
           ((and (string-match "^\\(:[-a-zA-Z0-9._/]+\\)\\s-*$" trimmed)
                 (= in-nested 0))
            (when current-key
              (push (cons current-key (string-trim current-value)) entries))
            (setq current-key trimmed)
            (setq current-value ""))
           ;; Continuation of value
           (current-key
            (setq current-value (concat current-value " " trimmed))
            (setq in-nested (+ in-nested
                              (- (cl-count ?{ trimmed)
                                 (cl-count ?} trimmed)))))))))

    ;; Add last entry
    (when current-key
      (push (cons current-key (string-trim current-value)) entries))

    (reverse entries)))

(defun type-formatter--build-map (type-entry other-entries indent)
  "Build a formatted map string with TYPE-ENTRY first, then OTHER-ENTRIES."
  (let ((inner-indent (+ indent 4))
        (lines nil))

    ;; Opening brace
    (push (concat (make-string indent ?\s) "{") lines)

    ;; Type entry
    (push (type-formatter--format-entry type-entry inner-indent t) lines)

    ;; Other entries
    (let ((remaining (length other-entries)))
      (dolist (entry other-entries)
        (setq remaining (1- remaining))
        (push (type-formatter--format-entry entry inner-indent (> remaining 0)) lines)))

    ;; Closing brace
    (push (concat (make-string indent ?\s) "}") lines)

    (mapconcat 'identity (reverse lines) "\n")))

(defun type-formatter--format-entry (entry indent add-comma)
  "Format an ENTRY (key . value) with INDENT, adding comma if ADD-COMMA is non-nil."
  (let* ((key (car entry))
         (value (cdr entry))
         (comma (if add-comma "," "")))
    (concat (make-string indent ?\s)
            key
            " "
            value
            comma)))

(defun type-formatter-format-buffer ()
  "Reformat entire buffer to move :type keys to the top of maps."
  (interactive)
  (type-formatter-format-region (point-min) (point-max)))

(defun type-formatter-format-at-point ()
  "Reformat the map at point to move :type key to the top."
  (interactive)
  (save-excursion
    (let* ((start (or (search-backward "{" nil t)
                     (point)))
           (end (save-excursion
                  (goto-char start)
                  (condition-case nil
                      (progn (forward-sexp) (point))
                    (error (point))))))
      (when (< start end)
        (type-formatter--reformat-map-at start end)))))

(provide 'type-formatter)
;;; type-formatter.el ends here
