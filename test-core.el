;;; test-core.el --- Test core formatter functions without CIDER -*- lexical-binding: t; -*-

;; Load just the formatting functions (not the advice part that requires CIDER)
(defvar cider-format-maps--inserting nil)

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
              ;; Push in reverse order since we'll nreverse later
              ;; Want: key val → push val, space, key
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

;; Test function
(defun test-format (input expected description)
  "Test formatting INPUT against EXPECTED."
  (let* ((result (cider-format-map input 3))
         (pass (string= result expected)))
    (princ (format "\n%s\n" (make-string 70 ?=)))
    (princ (format "TEST: %s\n" description))
    (princ (format "INPUT: %s\n" input))
    (princ "\nEXPECTED:\n")
    (dolist (line (split-string expected "\n"))
      (princ (format "=> %s\n" line)))
    (princ "\nACTUAL:\n")
    (dolist (line (split-string result "\n"))
      (princ (format "=> %s\n" line)))
    (princ (format "\nRESULT: %s\n" (if pass "✓ PASS" "✗ FAIL")))
    pass))

;; Run tests
(let ((passed 0) (failed 0))
  (if (test-format
       "{:a 1, :b 2}"
       "{:a 1,\n    :b 2}"
       "Simple map - order preserved")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{:a 1, :b 2, :type :Foo}"
       "{:type :Foo,\n    :a 1,\n    :b 2}"
       ":type at end - moves to front, others in order")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{:a 1, :type :Foo, :b 2, :c 3}"
       "{:type :Foo,\n    :a 1,\n    :b 2,\n    :c 3}"
       ":type in middle - preserves a,b,c order")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{}"
       "{}"
       "Empty map")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{:a \"hello, world\", :b 2}"
       "{:a \"hello, world\",\n    :b 2}"
       "String with comma")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{:x {:a 1, :type :A}, :y {:b 2, :type :B}, :type :Root}"
       "{:type :Root,\n    :x {:type :A,\n        :a 1},\n    :y {:type :B,\n        :b 2}}"
       "Multiple nested maps")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (if (test-format
       "{:deft.deft-test/side1 1, :deft.deft-test/side2 3, :deft.deft-test/pos {:deft.deft-test/x 1, :deft.deft-test/y 2, :type :deft.deft-test/Position}, :type :deft.deft-test/Rectangle}"
       "{:type :deft.deft-test/Rectangle,\n    :deft.deft-test/side1 1,\n    :deft.deft-test/side2 3,\n    :deft.deft-test/pos {:type :deft.deft-test/Position,\n                         :deft.deft-test/x 1,\n                         :deft.deft-test/y 2}}"
       "Complex example")
      (setq passed (1+ passed))
    (setq failed (1+ failed)))

  (princ (format "\n%s\n" (make-string 70 ?=)))
  (princ (format "SUMMARY: %d passed, %d failed\n" passed failed))
  (princ (format "%s\n" (make-string 70 ?=)))

  (if (= failed 0)
      (progn
        (princ "\n✓ ALL TESTS PASSED!\n")
        (kill-emacs 0))
    (progn
      (princ "\n✗ SOME TESTS FAILED!\n")
      (kill-emacs 1))))
