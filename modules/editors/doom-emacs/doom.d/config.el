;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-


(setq user-full-name "Joel DSouza"
      user-mail-address "joeldsouzax@gmail.com"
      doom-theme 'doom-one
      display-line-numbers-type t
      org-directory "~/org"
      doom-themes-padded-modeline t
      treemacs-project-follow-cleanup t
      treemacs-project-follow-mode t
      treemacs-peek-mode t
      treemacs-fringe-indicator-mode t
      treemacs-show-cursor t
      treemacs-space-between-root-nodes nil
      doom-modeline-enable-word-count t
      doom-modeline-battery t
      org-ellipsis " ▼ ")

(add-to-list 'default-frame-alist '(undecorated-round . t))


(after! lsp-ui
  (setq lsp-ui-doc-enable t
        lsp-ui-doc-position 'top-right-corner
        lsp-ui-doc--highlight-ov t
        lsp-ui-peek-show-directory t
        lsp-ui-imenu-enable t
        lsp-ui-imenu-buffer-mode t
        lsp-ui-imenu-buffer-position 'top-edge
        lsp-ui-imenu-auto-refresh t
        lsp-ui-peek-always-show t
        lsp-ui-sideline-show-symbol t
        lsp-ui-sideline-show-code-actions t
        lsp-ui-sideline-show-hover t))


(use-package treemacs-projectile
  :after (treemacs projectile))

(after! (treemacs projectile)
  (treemacs-indent-guide-mode 1))
(use-package treemacs-nerd-icons
  :after treemacs
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package lsp-treemacs :after treemacs)


(after! rust-mode
  (setq rust-format-on-save t))

(after! rustic
  (setq rustic-lsp-server 'rust-analyzer)
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  (setq lsp-signature-auto-activate t)
  (setq lsp-signature-doc-lines 5)  ; Limit hover doc lines
  (setq lsp-eldoc-enable-hover t)
  (setq lsp-ui-doc-enable t)
  (setq lsp-ui-doc-show-with-cursor t)
  (setq lsp-ui-doc-position 'at-point)
  (setq lsp-ui-doc-max-height 160)
  (setq lsp-ui-doc-max-width 80)
  (setq rustic-format-on-save t)
  (setq lsp-rust-analyzer-display-reborrow-hints t)
  (setq lsp-rust-analyzer-server-display-inlay-hints t)
  (setq lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (setq lsp-rust-analyzer-display-chaining-hints t)
  (setq lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names t)
  (setq lsp-rust-analyzer-display-closure-return-type-hints t)
  (setq lsp-rust-analyzer-display-parameter-hints t))


(use-package! nginx-mode
  :defer t)

;; -------------------- org -------------------- ;
(use-package! mermaid-ts-mode)
(use-package! ob-mermaid)

;; -------------------- astrojs --------------------;
;; https://edmundmiller.dev/posts/emacs-astro/

(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist '(astro)))

;; (use-package! astro-ts-mode
;;   :after treesit-auto
;;   :init
;;   :config
;;   (let ((astro-recipe (make-treesit-auto-recipe
;;                        :lang 'astro
;;                        :ts-mode 'astro-ts-mode
;;                        :url "https://github.com/virchau13/tree-sitter-astro"
;;                        :revision "master"
;;                        :source-dir "src")))
;;     (add-to-list 'treesit-auto-recipe-list astro-recipe)))


;; (set-formatter! 'prettier-astro
;;   '("npx" "prettier" "--parser=astro"
;;     (apheleia-formatters-indent "--use-tabs" "--tab-width" 'astro-ts-mode-indent-offset))
;;   :modes '(astro-ts-mode))

;; (use-package! lsp-tailwindcss
;;   :when (modulep! +lsp)
;;   :init
;;   (setq! lsp-tailwindcss-add-on-mode t)
;;   :config
;;   (add-to-list 'lsp-tailwindcss-major-modes 'astro-ts-mode))

;; MDX Support
(add-to-list 'auto-mode-alist '("\\.\\(mdx\\)$" . markdown-mode))
(when (modulep! +lsp)
  (add-hook 'markdown-mode-local-vars-hook #'lsp! 'append))


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
