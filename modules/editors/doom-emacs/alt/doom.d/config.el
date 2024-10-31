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
  (setq
   ;; lsp-inlay-hint-enable t
   rustic-format-on-save t
   lsp-eldoc-render-all t
   lsp-rust-analyzer-closing-brace-hints t
   lsp-rust-analyzer-binding-mode-hints t
   lsp-rust-analyzer-diagnostics-warnings-as-info t
   lsp-rust-analyzer-display-chaining-hints t
   lsp-rust-analyzer-display-lifetime-elision-hints-enable t
   lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names "skip_trivial"
   ;; lsp-rust-analyzer-display-closure-return-type-hints t
   lsp-rust-analyzer-display-reborrow-hints t
   lsp-rust-analyzer-display-parameter-hints t))


(use-package! nginx-mode
  :defer t)

;; -------------------- org -------------------- ;
(use-package mermaid-mode
  :defer
  :config
  (setq mermaid-mmdc-location "~/node_modules/.bin/mmdc"
        ob-mermaid-cli-path "~/node_modules/.bin/mmdc"))

;;-------------------- mail server stuffd --------------------;;
;;

(after! mu4e
  (setq sendmail-program (executable-find "msmtp")
        send-mail-function #'smtpmail-send-it
        message-sendmail-f-is-evil t
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-send-mail-function #'message-send-mail-with-sendmail))


(set-email-account! "Devrandom.co"
                    '((mu4e-sent-folder       . "/devrandom/sent")
                      (mu4e-drafts-folder     . "/devrandom/drafts")
                      (mu4e-trash-folder      . "/devrandom/trash")
                      (mu4e-refile-folder     . "/devrandom/all_mail")
                      (smtpmail-smtp-user     . "joel@devrandom.co")
                      (user-mail-address      . "joel@devrandom.co")    ;; only needed for mu < 1.4
                      (mu4e-compose-signature . "---\nJoel DSouza "))
                    t)

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
