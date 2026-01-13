;;; standalone-test.el --- Test just the core formatting functions

;; Copy of the core formatting functions without CIDER dependencies

(defun cider-format-map (str prefix-length)
  "Format map string STR with :type keys first and aligned indentation."
  (if (and (stringp str) (string-match-p "^{.*}$" str))
      (cider-format-map--format-string str prefix-length)
    str))

(defun cider-format-map--format-string (str base-indent)
  "Format map STR with BASE-INDENT."
  (let ((entries (cider-format-map--parse-map str)))
    (if (not entries)
        str
      (let* ((type-entries (seq-filter (lambda (e) (string-prefix-p ":type" (car e))) entries))
             (other-entries (seq-filter (lambda (e) (not (string-prefix-p ":type" (car e)))) entries))
             (sorted-entries (append type-entries other-entries))
             (col (1+ base-indent))
             (result '("{")))
        (let ((first t))
          (dolist (entry sorted-entries)
            (unless first
              (push ",\n" result)
              (push (make-string col ?\s) result))
            (setq first nil)
            (let* ((key (car entry))
                   (val (cdr entry))
                   (formatted-val (if (string-prefix-p "{" val)
                                      (cider-format-map--format-string val (+ col (length key) 1))
                                    val)))
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
      (goto-char (+ (point-min) 1))
      (let ((entries '()))
        (while (and (not (eobp))
                    (not (looking-at "}")))
          (skip-chars-forward " \t\n")
          (when (not (looking-at "}"))
            (let* ((key (cider-format-map--read-token))
                   (val (cider-format-map--read-value)))
              (when (and key val)
                (push (cons key val) entries))
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
     ((looking-at "\"")
      (forward-char 1)
      (when (re-search-forward "\"" nil t)
        (buffer-substring-no-properties start (point))))
     ((looking-at "{")
      (let ((depth 1))
        (forward-char 1)
        (while (and (> depth 0) (not (eobp)))
          (cond
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
     (t
      (skip-chars-forward "^] \t\n,{}")
      (when (> (point) start)
        (buffer-substring-no-properties start (point)))))))

;; Run tests
(princ "\nFormatter Tests:\n")
(princ "================\n\n")

(let ((r1 (cider-format-map "{:a 1, :b 2}" 3)))
  (princ "Test 1: {:a 1, :b 2}\n")
  (princ (format "Result:\n%s\n\n" r1)))

(let ((r2 (cider-format-map "{:a 1, :type :Foo, :b 2}" 3)))
  (princ "Test 2: {:a 1, :type :Foo, :b 2}\n")
  (princ (format "Result:\n%s\n\n" r2)))

(let ((r3 (cider-format-map "{:x {:a 1, :type :A}, :type :Root}" 3)))
  (princ "Test 3: {:x {:a 1, :type :A}, :type :Root}\n")
  (princ (format "Result:\n%s\n\n" r3)))

(princ "All tests completed!\n")
(kill-emacs 0)
