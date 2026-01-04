;;; cider-format-maps.el --- Format Clojure maps in CIDER output -*- lexical-binding: t; -*-

(require 'cider-eval)

(defun cider-format-map (str)
  "Format map string STR by adding newlines and indentation after commas."
  (when (and (stringp str) (string-match-p "^{.*}$" str))
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (let ((depth 0))
        (while (re-search-forward "[{},]" nil t)
          (let ((char (char-before)))
            (cond
             ((eq char ?{) (setq depth (1+ depth)))
             ((eq char ?}) (setq depth (1- depth)))
             ((eq char ?,)
              (when (looking-at " +")
                (replace-match ""))
              (unless (looking-at "}")
                (insert "\n" (make-string (* 2 depth) ?\s)))))))
        (buffer-string)))))

(defun cider-format-result (orig-fun value &rest args)
  "Format VALUE if it's a map, then call ORIG-FUN with ARGS."
  (apply orig-fun (or (cider-format-map value) value) args))

(advice-add 'cider--display-interactive-eval-result :around #'cider-format-result)

(provide 'cider-format-maps)
;;; cider-format-maps.el ends here
