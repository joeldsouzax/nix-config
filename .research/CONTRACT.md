# Immutable contract

Refresh flake inputs, pinned tools and CI actions; remove Finder metadata and prevent it returning to Git. Preserve both hosts, shared Home Manager ownership, agent integrations, secrets handling and unrelated Orca changes.

Use Nix and existing package builders. Add no project tooling or Python files. Do not apply a sudo rebuild, commit unrelated edits, decrypt secrets or remove files beyond requested Finder metadata. Avoid a full system build on the Mac with 11 GB free. Evaluate both hosts and build updated standalone tools where practical; report unavailable Linux checks honestly.

Owner amendment, 2026-10-25: commit all pending changes to main, including Orca
and the dependency refresh, alongside the merged desktop runner. This authorizes
their integration; it does not request system activation or publication.

Owner amendment, 2026-10-25: add Codex CLI to the desktop runner host. Use the
runner's locked nixpkgs package if it supports Linux and preserves the CLI
helpers. Keep authentication under the administrator's account. This addition
does not require a new package builder, a lock update or CI automation.

Owner amendment, 2026-10-25: commit this Mac's public SSH key and push main.
Authorize that key for Joel on both profiles of the same desktop. Keep the
private key off Git and preserve existing access. Publishing the configuration
does not activate it on the desktop.

Owner amendment, 2026-10-25: repair current package and module compatibility
failures, starting with the removed `grip` package. Check the desktop, runner
and Mac configurations against their locked inputs. Preserve current features
where supported; remove obsolete entries instead of reviving removed packages
or weakening checks. Keep existing pins unless a verified upstream fix requires
an update. Commit and publish the corrections through the established main
workflow. Do not claim live activation or a Linux build from Mac evaluation.
