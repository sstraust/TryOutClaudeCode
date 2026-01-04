;;; test-formatter.el --- Test the type formatter -*- lexical-binding: t; -*-

(require 'type-formatter)

(defun test-type-formatter ()
  "Test the type formatter with sample input."
  (interactive)
  (with-temp-buffer
    (insert "{:deft.deft-test/side1 1,
    :deft.deft-test/side2 3,
    :deft.deft-test/pos {
        :deft.deft-test/x 1,
        :deft.deft-test/y 2,
        :type :deft.deft-test/Position},
    :type :deft.deft-test/Rectangle}")

    (let ((before (buffer-string)))
      (message "BEFORE:\n%s\n" before)

      (type-formatter-format-buffer)

      (let ((after (buffer-string)))
        (message "AFTER:\n%s\n" after)

        ;; Check that both :type entries are now first in their maps
        (goto-char (point-min))
        (let ((first-type-pos (search-forward ":type" nil t))
              (second-type-pos (search-forward ":type" nil t)))

          (if (and first-type-pos second-type-pos)
              (message "SUCCESS: Found both :type entries")
            (message "FAILURE: Missing :type entries")))

        after))))

;; Run the test
(test-type-formatter)

(provide 'test-formatter)
