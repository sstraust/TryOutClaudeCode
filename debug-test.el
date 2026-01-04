;;; debug-test.el --- Debug the formatter

(load-file "standalone-test.el")

(princ "\n\nDebug Test:\n")
(princ "===========\n\n")

(let* ((input "{:a 1, :type :Foo, :b 2}")
       (result (cider-format-map input 3)))
  (princ (format "Input: %s\n" input))
  (princ (format "Result length: %d\n" (length result)))
  (princ (format "Result chars: %S\n" result))
  (princ (format "\nFirst 20 chars: %S\n" (substring result 0 (min 20 (length result)))))
  (princ (format "Last 20 chars: %S\n" (substring result (max 0 (- (length result) 20))))))

(kill-emacs 0)
