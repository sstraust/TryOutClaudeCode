;;; cider-format-maps.el --- Format Clojure maps in CIDER output -*- lexical-binding: t; -*-

(require 'cider-eval)

(defvar cider-format-maps--inserting nil
  "Non-nil when result is being inserted into buffer (C-u C-x C-e).")

(defun cider-format-map (str prefix-length)
  "Format map string STR with :type keys first and aligned indentation.
PREFIX-LENGTH is the length of any prefix like '=>' to align with."
  (if (and (stringp str) (string-match-p "^{.*}$" str))
      (cider-format-map--format-string str prefix-length)
    str))

(defun cider-format-map--format-string (str base-indent)
  "Format map STR with BASE-INDENT."
  (let ((entries (cider-format-map--parse-map str)))
    (if (not entries)
        str
      ;; Separate :type entries from others, preserving order
      (let* ((type-entries (seq-filter (lambda (e) (string-prefix-p ":type" (car e))) entries))
             (other-entries (seq-filter (lambda (e) (not (string-prefix-p ":type" (car e)))) entries))
             (sorted-entries (append type-entries other-entries))
             (col (1+ base-indent))
             (result (list "{")))

        ;; Format each entry
        (let ((first t))
          (dolist (entry sorted-entries)
            (unless first
              (push ",\n" result)
              (push (make-string col ?\s) result))
            (setq first nil)

            (let* ((key (car entry))
                   (val (cdr entry))
                   ;; Recursively format nested maps
                   (formatted-val (if (string-prefix-p "{" val)
                                      (cider-format-map--format-string val (+ col (length key) 1))
                                    val)))
              ;; Push in reverse order: key, space, val
              (push key result)
              (push " " result)
              (push formatted-val result))))

        (push "}" result)
        (apply #'concat (nreverse result))))))

(defun cider-format-map--parse-map (str)
  "Parse map string STR into list of (key . value) cons cells."
  (when (and (stringp str) (string-prefix-p "{" str) (string-suffix-p "}" str))
    (with-temp-buffer
      (insert str)
      (goto-char (+ (point-min) 1))  ; Skip opening {
      (let ((entries '()))
        (while (and (not (eobp))
                    (not (looking-at "}")))
          (skip-chars-forward " \t\n")
          (when (not (looking-at "}"))
            (let* ((key (cider-format-map--read-token))
                   (val (cider-format-map--read-value)))
              (when (and key val)
                (push (cons key val) entries))
              ;; Skip comma and whitespace
              (skip-chars-forward " \t\n")
              (when (looking-at ",")
                (forward-char 1)
                (skip-chars-forward " \t\n")))))
        (nreverse entries)))))

(defun cider-format-map--read-token ()
  "Read a keyword or symbol token and return as string."
  (skip-chars-forward " \t\n")
  (let ((start (point)))
    (skip-chars-forward "^] \t\n,{}\"")
    (when (> (point) start)
      (buffer-substring-no-properties start (point)))))

(defun cider-format-map--read-value ()
  "Read a value (string, map, or simple value) and return as string."
  (skip-chars-forward " \t\n")
  (let ((start (point)))
    (cond
     ;; String value
     ((looking-at "\"")
      (forward-char 1)
      (when (re-search-forward "\"" nil t)
        (buffer-substring-no-properties start (point))))

     ;; Nested map
     ((looking-at "{")
      (let ((depth 1))
        (forward-char 1)
        (while (and (> depth 0) (not (eobp)))
          (cond
           ;; Skip strings
           ((looking-at "\"")
            (forward-char 1)
            (re-search-forward "\"" nil t))
           ((looking-at "{")
            (setq depth (1+ depth))
            (forward-char 1))
           ((looking-at "}")
            (setq depth (1- depth))
            (forward-char 1))
           (t
            (forward-char 1))))
        (buffer-substring-no-properties start (point))))

     ;; Simple value
     (t
      (skip-chars-forward "^] \t\n,{}")
      (when (> (point) start)
        (buffer-substring-no-properties start (point)))))))

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
