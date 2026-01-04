;;; cider-format-maps.el --- Format Clojure maps in CIDER output -*- lexical-binding: t; -*-

(require 'cider-eval)

(defvar cider-format-maps--inserting nil
  "Non-nil when result is being inserted into buffer (C-u C-x C-e).")

(defun cider-format-map (str prefix-length)
  "Format map string STR by adding newlines and indentation after commas.
PREFIX-LENGTH is the length of any prefix like '=>' to align with."
  (when (and (stringp str) (string-match-p "^{.*}$" str))
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (let ((depth 0)
            (base-indent prefix-length))
        (while (re-search-forward "[{},]" nil t)
          (let ((char (char-before)))
            (cond
             ((eq char ?{) (setq depth (1+ depth)))
             ((eq char ?}) (setq depth (1- depth)))
             ((eq char ?,)
              (when (looking-at " +")
                (replace-match ""))
              (unless (looking-at "}")
                (insert "\n" (make-string (+ base-indent (* 2 depth)) ?\s)))))))
        (buffer-string)))))

(defun cider-format-result (orig-fun value &rest args)
  "Format VALUE if it's a map and inserting, then call ORIG-FUN with ARGS."
  (let* ((formatted (when cider-format-maps--inserting
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
