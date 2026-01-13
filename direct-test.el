;;; direct-test.el --- Test formatter directly

;; Load only the formatter, not the test framework
(load-file "cider-format-maps.el")

(princ "\nDirect test of cider-format-map:\n")
(princ "================================\n\n")

(let* ((input1 "{:a 1, :b 2}")
       (result1 (cider-format-map input1 3)))
  (princ (format "Test 1: %s\n" input1))
  (princ (format "Result: %s\n\n" result1)))

(let* ((input2 "{:a 1, :type :Foo, :b 2}")
       (result2 (cider-format-map input2 3)))
  (princ (format "Test 2: %s\n" input2))
  (princ (format "Result: %s\n\n" result2)))

(let* ((input3 "{:x {:a 1, :type :A}, :type :Root}")
       (result3 (cider-format-map input3 3)))
  (princ (format "Test 3: %s\n" input3))
  (princ (format "Result: %s\n\n" result3)))

(kill-emacs 0)
