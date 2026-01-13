;;; simple-test.el --- Simple direct test

(load-file "/home/user/TryOutClaudeCode/type-formatter-final.el")

(defun test-simple ()
  (with-temp-buffer
    (insert "{:a 1, :b 2, :type :Foo}")
    (message "BEFORE: %s" (buffer-string))
    (type-formatter-format-buffer)
    (message "AFTER: %s" (buffer-string))))

(defun test-nested ()
  (with-temp-buffer
    (insert "{:deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :deft.deft-test/x 1,
        :deft.deft-test/y 2,
        :type :deft.deft-test/Position},
    :type :deft.deft-test/Rectangle}")
    (message "\n\nNESTED TEST")
    (message "BEFORE:\n%s" (buffer-string))
    (type-formatter-format-buffer)
    (message "\nAFTER:\n%s" (buffer-string))))

(test-simple)
(test-nested)
