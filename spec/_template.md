# <Domain name>

<!--
Copy this file to spec/<domain>.md and fill every section. Delete these
comments. Keep it short: a reader should finish a domain file in a minute.
-->

**Source:** `<path(s) in the repository this domain covers>`

## Purpose

<!-- One or two sentences: what this domain is for on Ampersand. -->

## Current state

<!--
One row per item that ships, identified exactly as the code spells it (an app
ID, a package name, a recipe name, a unit name, a file path). The contract test
matches on the identifier in backticks, so keep it verbatim.
-->

| Item | Why it is here |
|---|---|
| `<identifier>` | <reason> |

## Decisions

<!--
Choices a future change might undo without knowing the reason: why this
mechanism rather than another, ordering, pinning, scope. One bullet each,
stating the choice and the reason.
-->

- **<choice>** — <reason>

## Not included

<!--
Things someone would reasonably expect or propose, and why they are absent.
This section stops the same idea from being re-added later.
-->

- `<identifier>` — <why not>

## Inherited

<!--
What this domain receives from the base image, projectbluefin/common or
ublue-os/brew without Ampersand doing anything. Name it and link the upstream
source; do not copy its contents.
-->

- <what> — from <upstream, linked>
