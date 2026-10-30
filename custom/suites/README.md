# Suites

One Brewfile per suite. Each app is one line with a comment that the menu shows:

    flatpak "com.valvesoftware.Steam" # Steam: game store and launcher (recommended)

- The comment is `Name: description` (no commas: the menu uses them as separators).
- `(recommended)` at the end puts the app in the set that "Install the recommended set" installs.
- `tap` lines are always added. Lines without a comment are not shown.
