;;; init.el --- init script  -*- lexical-binding: t; -*-

;; Copyright (c) 2023 Paul Stadig

;;; Commentary:

;; None

;;; Code:


(require 'use-package)
(use-package my
  :demand t
  :bind (("C-x b" . my-switch-buffer)
         ("C-x C-b" . my-switch-buffer)))
(use-package my-completion)
(use-package my-prog)

(provide 'init)
;;; init.el ends here
