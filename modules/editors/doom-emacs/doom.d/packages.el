;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
;; (package! some-package)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
;; (package! another-package
;;   :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
;; (package! this-package
;;   :recipe (:host github :repo "username/repo"
;;            :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
;; (package! builtin-package :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
;; (package! builtin-package :recipe (:nonrecursive t))
;; (package! builtin-package-2 :recipe (:repo "myfork/package"))

;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
;; (package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
;; (package! builtin-package :pin "1a2b3c4d5e")


;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
;; (unpin! pinned-package)
;; ...or multiple packages
;; (unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
;; (unpin! t)

;; github-only packages: nix-doom-emacs-unstraightened builds each from its
;; :recipe, but it needs an explicit :pin (a commit) to derive a reproducible
;; revision — without one it errors "not in nixpkgs or emacs-overlay, not
;; pinned". So every custom-recipe package below carries a :pin.
(package! mermaid-ts-mode
  :recipe (:host github
           :repo "JonathanHope/mermaid-ts-mode"
           :branch "main"
           :files ("mermaid-ts-mode.el"))
  :pin "973e442cbed980cf51afc256c90ef133c4d02141")
(package! ob-mermaid)
(package! nginx-mode)
(package! treesit-auto)


;; Tailwind CSS: the external lsp-tailwindcss package is deprecated — lsp-mode
;; now ships a built-in tailwindcss client. Nothing to declare here; configured
;; in config.el under `after! lsp-tailwindcss`.

(package! prisma-mode
  :recipe (:host github :repo "pimeys/emacs-prisma-mode" :branch "main")
  :pin "f7744a995e84b8cf51265930ce18f6a6b26dade7")

;; Jest/Vitest testing
(package! jest-test-mode)

(package! just-mode)
;; apheleia and transient are already provided by Doom (:editor format +onsave
;; and :tools magit respectively). Declaring them again pulls unpinned MELPA
;; versions that can desync from Doom's pins — so we rely on Doom's.
(package! slack)
(package! alert)
(package! gptel)
