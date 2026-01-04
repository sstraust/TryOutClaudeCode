;;; cider-format-maps.el --- Format Clojure maps in CIDER output -*- lexical-binding: t; -*-

(require 'cider-eval)

(defvar cider-format-maps--inserting nil
  "Non-nil when result is being inserted into buffer (C-u C-x C-e).")

(defun cider-format-map (str prefix-length)
  "Format map string STR with :type keys first and aligned indentation.
PREFIX-LENGTH is the length of any prefix like '=>' to align with."
  (if (and (stringp str) (string-match-p "^{.*}$" str))
      (with-temp-buffer
        (insert str)
        (goto-char (point-min))
        (cider-format-map--format-region (point-min) (point-max) prefix-length)
        (buffer-string))
    str))

(defun cider-format-map--format-region (start end base-indent)
  "Format map in region from START to END with BASE-INDENT."
  (goto-char start)
  (when (looking-at "{")
    (let* ((map-start (point))
           (entries (cider-format-map--parse-map-entries))
           (open-brace-col (+ base-indent (current-column))))
      (when entries
        ;; Delete the old map content (keep braces)
        (delete-region (1+ map-start) (1- (point)))
        (goto-char (1+ map-start))

        ;; Sort entries: :type first, then others
        (setq entries (sort entries
                           (lambda (a b)
                             (let ((a-type (string-prefix-p ":type" (car a)))
                                   (b-type (string-prefix-p ":type" (car b))))
                               (cond
                                ((and a-type (not b-type)) t)
                                ((and b-type (not a-type)) nil)
                                (t nil))))))

        ;; Insert formatted entries
        (let ((first t))
          (dolist (entry entries)
            (unless first
              (insert ",\n" (make-string open-brace-col ?\s)))
            (setq first nil)
            (insert (car entry) " " (cdr entry))))))))

(defun cider-format-map--parse-map-entries ()
  "Parse map entries from current position. Returns list of (key . value) strings."
  (let ((entries nil)
        (start (point)))
    (forward-char 1)  ; Skip opening {
    (skip-chars-forward " \t\n")

    (while (and (not (eobp)) (not (looking-at "}")))
      (let* ((key-start (point))
             (key (cider-format-map--read-token))
             (val-start (point))
             (val (cider-format-map--read-value)))
        (when (and key val)
          (push (cons key val) entries))

        ;; Skip comma and whitespace
        (skip-chars-forward " \t\n")
        (when (looking-at ",")
          (forward-char 1)
          (skip-chars-forward " \t\n"))))

    (forward-char 1)  ; Skip closing }
    (nreverse entries)))

(defun cider-format-map--read-token ()
  "Read a single token (keyword, symbol, etc) and return as string."
  (skip-chars-forward " \t\n")
  (let ((start (point)))
    (skip-chars-forward "^] \t\n,{}\"")
    (buffer-substring-no-properties start (point))))

(defun cider-format-map--read-value ()
  "Read a value (could be map, string, or simple value) and return as string."
  (skip-chars-forward " \t\n")
  (let ((start (point)))
    (cond
     ;; String
     ((looking-at "\"")
      (forward-char 1)
      (re-search-forward "\"" nil t)
      (buffer-substring-no-properties start (point)))

     ;; Nested map
     ((looking-at "{")
      (let ((map-start (point))
            (depth 1))
        (forward-char 1)
        (while (and (> depth 0) (not (eobp)))
          (skip-chars-forward "^{}\"")
          (cond
           ((looking-at "\"")
            (forward-char 1)
            (re-search-forward "\"" nil t))
           ((looking-at "{")
            (setq depth (1+ depth))
            (forward-char 1))
           ((looking-at "}")
            (setq depth (1- depth))
            (forward-char 1))))
        (buffer-substring-no-properties map-start (point))))

     ;; Simple value
     (t
      (skip-chars-forward "^] \t\n,{}")
      (buffer-substring-no-properties start (point))))))

(defun cider-format-result (orig-fun value &rest args)
  "Format VALUE if it's a map and inserting, then call ORIG-FUN with ARGS."
  (let ((formatted (when cider-format-maps--inserting
                     (cider-format-map value 3))))  ; 3 for "=> "
    (apply orig-fun (or formatted value) args)))

(defun cider-format-track-insert (orig-fun &rest args)
  "Track when CIDER is inserting results with ORIG-FUN and ARGS."
  (let ((cider-format-maps--inserting current-prefix-arg))
    (apply orig-fun args)))

(advice-add 'cider--display-interactive-eval-result :around #'cider-format-result)
(advice-add 'cider-eval-last-sexp :around #'cider-format-track-insert)

(provide 'cider-format-maps)
;;; cider-format-maps.el ends here
