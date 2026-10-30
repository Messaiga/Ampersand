---
name: troubleshooting
description: >-
  Symptom to cause to fix for build, CI, and runtime failures, plus the
  pre-commit checklist. Use when something is broken or before opening a
  pull request.
---

# Troubleshooting

## Before a pull request

- [ ] Conventional Commit message.
- [ ] `just lint` — shellcheck on every tracked script.
- [ ] `just check` — Justfile syntax.
- [ ] `just test-unit` — the suite.
- [ ] `just validate-brewfiles` / `just validate-flatpaks` if those changed.
- [ ] `just build` if the image changed.

CI runs the same checks; running them locally only makes the pull request quiet.

## Build

| Symptom | Cause | Fix |
|---|---|---|
| `bootc container lint` fails on a nonempty `/run` | a script wrote to `/run` into an image layer | remove it in `90-cleanup.sh`; that phase deliberately does not mount `/run` as tmpfs |
| a third-party repository is live in the final image | a script enabled it and did not disable it | use `copr_install_isolated`, or disable it explicitly |
| the package layer rebuilds on every overlay edit | packages drifted into the overlay phase | keep packages in `20-packages-and-services.sh` |
| hadolint flags the Containerfile | a rule in `.github/hadolint.yaml` | fix it, or add a suppression with a reason |
| `40-gnome-extensions.sh` fails on one extension | no release for this GNOME on extensions.gnome.org, or EGO unreachable | re-run if EGO was down; otherwise wait for the extension, patch it, or hold the base (spec/06) |

## CI

| Symptom | Cause | Fix |
|---|---|---|
| `validate` never runs | branch protection names a check no workflow produces | the context must be exactly `validate` |
| Renovate logs a skip and opens nothing | `RENOVATE_TOKEN` is not set | expected; set the secret to turn Renovate on |
| Renovate fails on `Validate RENOVATE_TOKEN` | the token is expired or lacks the `workflow` scope | recreate the token |
| the promotion PR never opens | `stable` does not exist | create the branch |
| the promotion PR will not merge | `stable` requires an approval | set required approvals to 0 |
| a Renovate PR waits forever | auto-merge is off | enable it in Settings |

## Runtime

The two most common first-boot surprises — no Flatpaks, and no `brew` — are in
the README's Troubleshooting section.

| Symptom | Cause | Fix |
|---|---|---|
| `ujust` shows no custom commands | `60-custom.just` was not written or imported | check that `10-overlay.sh` copied the recipes |
| `ujust <name>` runs Common's recipe, not Ampersand's | `60-custom.just` imported after Common's files (just keeps the first definition) | `44-ampersand.sh` moves the import to the top; check `00-entry.just` still imports `60-custom.just` |
| An extension shows ERROR in Extensions | a `schemas/` folder without `gschemas.compiled`, or files not world-readable | `40-gnome-extensions.sh` removes `schemas/` and fixes permissions; see `research/gotchas.md` |
| Ampersand's GNOME defaults don't apply | dconf profile lacks `system-db:distro`, or the user already changed the key | `43-gnome-defaults.sh` writes the profile; on an existing account run `ujust reset-desktop` |
| `bootc upgrade` refuses the image | signature missing or policy scope wrong | `cosign verify --key cosign.pub <image>`; check the "Sign with the Ampersand key" step ran |
| Build fails `/ctx/build/NN-*.sh: Permission denied` (exit 126) | the phase script was committed 100644 (renaming a `.example` keeps its mode) | `git update-index --chmod=+x build/NN-*.sh`; `tests/contract/build-phases_test.bats` checks every phase |

## Capturing what you learned

When a fix here was non-obvious, put it in the skill that owns the area, in the
same pull request. That is the only home for durable learning.
