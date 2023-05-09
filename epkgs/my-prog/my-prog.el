;;; my-prog.el --- General programming code and configuration  -*- lexical-binding: t; -*-

;;  Copyright (c) 2023 Paul Stadig

;;  Version: 0.0.0

;;; Commentary:

;; None

;;; Code:

(use-package magit
  :bind ("C-x g" . magit-status))
(use-package magit-extras)

(deftheme my-prog)

(custom-theme-set-variables
 'my-prog
 '(display-line-numbers-minor-tick 10)
 '(display-line-numbers-width-start t)
 '(emacs-lisp-docstring-fill-column 80)
 '(emacs-lisp-mode-hook '(eldoc-mode imenu-add-menubar-index checkdoc-minor-mode paredit-mode))
 '(fill-column 100)
 '(prog-mode-hook '(flyspell-prog-mode display-line-numbers-mode))
 '(sh-basic-offset 2))

(provide-theme 'my-prog)
(enable-theme 'my-prog)

(provide 'my-prog)
;;; my-prog.el ends here
