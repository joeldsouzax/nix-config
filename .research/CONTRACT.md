# Immutable contract

Refresh flake inputs, pinned tools and CI actions; remove Finder metadata and prevent it returning to Git. Preserve both hosts, shared Home Manager ownership, agent integrations, secrets handling and unrelated Orca changes.

Use Nix and existing package builders. Add no project tooling or Python files. Do not apply a sudo rebuild, commit unrelated edits, decrypt secrets or remove files beyond requested Finder metadata. Avoid a full system build on the Mac with 11 GB free. Evaluate both hosts and build updated standalone tools where practical; report unavailable Linux checks honestly.

Owner amendment, 2026-10-25: commit all pending changes to main, including Orca
and the dependency refresh, alongside the merged desktop runner. This authorizes
their integration; it does not request system activation or publication.
