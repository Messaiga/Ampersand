# Gotchas

One line per mismatch between what we assumed and what a tool actually does.
Format: `YYYY-MM-DD · tool · assumed → actual · source`. Newest at the bottom.
How to check tools: `research/upstream-check/SKILL.md`.

- 2026-10-30 · Bluefin docs · "Bluefin" docs page = our base → our base `bluefin:stable` is **Bluefin Classic** (/classic/); /dakota/ is another image · https://docs.projectbluefin.io/classic/
- 2026-10-30 · just · a recipe defined twice across imports errors or the last wins → at the same import depth the **earlier** import wins (upstream calls it a bug, kept for compatibility); `40-custom.sh` relies on this · https://just.systems/man/en/imports.html
- 2026-10-30 · VS Code · `--profile <name>` fails on a missing profile → it silently creates an empty one, so a typo goes unnoticed · https://code.visualstudio.com/docs/configure/command-line
- 2026-10-30 · gum · README documents `choose` flags → `--selected` isn't in the README; check `gum choose --help` in the image · https://github.com/charmbracelet/gum
- 2026-10-30 · Flatpak · removing a preinstall entry only stops new installs → `flatpak preinstall` syncs (installs and removes); removal on deletion is implied, not stated, so test in the VM · https://man7.org/linux/man-pages/man1/flatpak-preinstall.1.html
- 2026-10-30 · bootc · files under `/var` in the image update on upgrade → only unpacked on first install · https://bootc.dev/bootc/bootc-filesystem.7.html
- 2026-10-30 · glib-compile-schemas · a bad override fails the compile → without `--strict` the faulty file is dropped silently (our build greps the warning) · https://www.mankier.com/1/glib-compile-schemas
- 2026-10-30 · RamaLama · default port is always 8080 → 8080 if free, else another port (README says 8081–8090, man page says up to 8180); pass `--port` · https://github.com/containers/ramalama/blob/main/docs/ramalama-serve.1.md
- 2026-10-30 · adb · spec/03 uses `adb mdns services` → Android's docs show `adb mdns track-services`; confirm with `adb --help` in the image (assumed until tested) · https://developer.android.com/tools/adb#wireless-adb-android-11
- 2026-10-30 · containers-policy · any `signedIdentity` works with cosign → cosign signatures carry only the repository, so only `matchRepository`/`exactRepository` work · https://github.com/containers/image/blob/main/docs/containers-policy.json.5.md
