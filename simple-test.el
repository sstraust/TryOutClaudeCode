;;; simple-test.el --- Direct test without framework

(load-file "test-core.el")

(princ "\n\nDirect function call test:\n")
(princ "==========================\n\n")

(let ((input "{:a 1, :type :Foo, :b 2}")
      (result nil))
  (princ (format "Input: %s\n" input))
  (setq result (cider-format-map input 3))
  (princ (format "\nResult:\n%s\n" result))
  (princ (format "\nResult length: %d\n" (length result)))
  (princ (format "First char: %S\n" (substring result 0 1))))

(kill-emacs 0)
