# Flatpaks

**Source:** `custom/flatpaks/*.preinstall` (first boot),
`flatpak "<app-id>"` lines in `custom/brew/*.Brewfile` (app groups),
`custom/files/usr/libexec/ampersand/flatpak-group.sh` (group behavior)

## Purpose

GUI applications. A curated set installs for everyone on first boot; the rest
come in opt-in groups a user installs with `ujust`.

## Current state

### First boot — `default.preinstall` (Flathub)

| Item | Why it is here |
|---|---|
| `org.gnome.Calculator` | Calculator. GNOME core app. |
| `org.gnome.Calendar` | Calendar. GNOME core app. |
| `org.gnome.Snapshot` | Camera. GNOME core app. |
| `org.gnome.Characters` | Characters. GNOME core app. |
| `org.gnome.clocks` | Clocks. GNOME core app. |
| `org.gnome.Connections` | Connections: remote desktop. GNOME core app. |
| `org.gnome.Contacts` | Contacts. GNOME core app. |
| `org.gnome.DejaDup` | Déjà Dup: backups. GNOME core app. |
| `org.gnome.baobab` | Disk Usage Analyzer. GNOME core app. |
| `org.gnome.SimpleScan` | Document Scanner. GNOME core app. |
| `org.gnome.Papers` | Document Viewer. GNOME core app. |
| `org.gnome.FileRoller` | File Roller: archives. GNOME core app. |
| `org.gnome.Firmware` | Firmware updates. GNOME core app. |
| `org.gnome.font-viewer` | Fonts. GNOME core app. |
| `org.gnome.Loupe` | Image Viewer. GNOME core app. |
| `org.gnome.Logs` | Logs. GNOME core app. |
| `org.gnome.Maps` | Maps. GNOME core app. |
| `org.gnome.NautilusPreviewer` | Sushi: file previews in Files. GNOME core app. |
| `org.gnome.TextEditor` | Text Editor. GNOME core app. |
| `org.gnome.Showtime` | Video Player. GNOME core app. |
| `org.gnome.Weather` | Weather. GNOME core app. |
| `io.github.kolunmi.Bazaar` | Bazaar: app store. |
| `com.github.tchx84.Flatseal` | Flatseal: audit and restrict Flatpak permissions. |
| `com.mattjakeman.ExtensionManager` | Extension Manager: browse and install GNOME Shell extensions. |
| `io.github.flattool.Warehouse` | Warehouse: manage installed Flatpaks. |
| `io.github.flattool.Ignition` | Ignition: manage startup apps. |
| `page.tesk.Refine` | Refine: advanced GNOME settings. |
| `io.missioncenter.MissionCenter` | Mission Center: system monitor. |
| `com.ranfdev.DistroShelf` | DistroShelf: manage Distrobox containers. |
| `org.fedoraproject.MediaWriter` | Fedora Media Writer: write install media. |
| `app.zen_browser.zen` | Zen: browser. |
| `com.vivaldi.Vivaldi` | Vivaldi: browser. |
| `io.gitlab.news_flash.NewsFlash` | Newsflash: RSS reader. |
| `org.localsend.localsend_app` | LocalSend: file transfer between devices. |
| `com.github.zocker_160.SyncThingy` | SyncThingy: Syncthing in the tray. |
| `io.github.giantpinkrobots.varia` | Varia: download manager. |
| `org.gnome.gitlab.somas.Apostrophe` | Apostrophe: Markdown editor. |
| `io.github.alainm23.planify` | Planify: tasks. |
| `com.jgraph.drawio.desktop` | draw.io: diagrams. |
| `be.alexandervanhee.gradia` | Gradia: screenshot editing. |
| `com.github.PintaProject.Pinta` | Pinta: image editing. |
| `io.gitlab.adhami3310.Impression` | Impression: write disk images. |
| `com.github.neithern.g4music` | Gapless: music player. |
| `com.github.wwmm.easyeffects` | Easy Effects: audio effects. |
| `com.usebottles.bottles` | Bottles: run Windows software. |
| `io.github.tanaybhomia.DeepDive` | Deep Dive. |
| `io.github.tanaybhomia.Whisp` | Whisp. |
| `io.speedofsound.SpeedOfSound` | Speed of Sound. |

### First boot — `flatpark.preinstall` (FlatPark)

| Item | Why it is here |
|---|---|
| `org.eurooffice.desktopeditors` | Euro-Office: office suite. |

### Group `ai-assistant` — `ujust install-ai-assistant`

| Item | Why it is here |
|---|---|
| `io.github.qwersyk.Newelle` | Newelle: AI assistant. |

### Group `dev-apps` — `ujust install-dev-apps`

| Item | Why it is here |
|---|---|
| `org.freedesktop.Bustle` | Bustle: D-Bus activity. |
| `org.gnome.dspy` | D-Spy: D-Bus explorer. |
| `com.github.marhkb.Pods` | Pods: Podman containers. |
| `org.flatpak.Builder` | Flatpak Builder. |
| `io.github.ronniedroid.concessio` | Concessio: file permissions calculator. |

### Group `media` — `ujust install-media-apps`

| Item | Why it is here |
|---|---|
| `com.github.huluti.Curtail` | Curtail: compress images. |
| `io.gitlab.adhami3310.Converter` | Switcheroo: convert images. |
| `io.gitlab.theevilskeleton.Upscaler` | Upscaler: upscale images. |
| `org.videolan.VLC` | VLC: media player. |

### Group `media-production` — `ujust install-media-production`

| Item | Why it is here |
|---|---|
| `org.kde.kdenlive` | Kdenlive: video editing. |
| `com.obsproject.Studio` | OBS Studio: recording and streaming. |
| `fr.natron.Natron` | Natron: compositing. |
| `org.rncbc.qpwgraph` | qpwgraph: PipeWire routing. |
| `fm.reaper.Reaper` | Reaper: DAW. |
| `io.lmms.LMMS` | LMMS: music production. |
| `org.musescore.MuseScore` | MuseScore: notation. |
| `io.github.revisto.drum-machine` | Drum Machine. |
| `com.adrienplazas.Metronome` | Metronome. |

### Group `gaming` — `ujust install-gaming`

| Item | Why it is here |
|---|---|
| `com.valvesoftware.Steam` | Steam. |
| `com.vysp3r.ProtonPlus` | ProtonPlus: manage Proton versions. |

## Decisions

- **First boot or opt-in** — first boot is for what every user of this image
  wants; anything narrower is a group.
- **Groups are Brewfiles of `flatpak` lines** — the same mechanism Bluefin uses
  for its app sets. `brew bundle` installs them system-wide
  (`flatpak install --system flathub`), the same scope as the first-boot list.
- **Every group recipe behaves the same** — `flatpak-group.sh` decides from
  what is installed system-wide:

  | State | Behavior |
  |---|---|
  | None installed | Install all of them. |
  | Some installed | List both, then offer **Install the rest** / **Uninstall what remains** / **No**. |
  | All installed | Say so, then offer **Uninstall them** / **No**. |

  **No**, or dismissing the prompt, changes nothing.
- **Bluefin's developer-experience apps stay upstream** — `install-dx-apps`
  uses Bluefin's `system-dx-flatpaks.Brewfile`, copied unchanged from Common,
  so Renovate's Common bumps keep it current. Our `dev-apps` group holds only
  what that list lacks.
- **Flathub first; FlatPark only by name** — preinstall files cannot name a
  remote, so FlatPark apps live in `flatpark.preinstall`, which the validator
  checks against FlatPark's pinned descriptor instead of Flathub.
- **Every ID is validated before merge** — `just validate-flatpaks` resolves
  preinstall entries at their branch and Brewfile entries unbranched, as
  `brew bundle` installs them. A Brewfile `flatpak` line with options fails.
- **Installed on first boot, not at build time** — keeps the image small and
  apps updatable on their own. First boot needs a network connection.

## Not included

- `org.mozilla.firefox` — Zen and Vivaldi are the browsers.
- `org.mozilla.Thunderbird` — The template's default. Ampersand ships no mail client: none was good enough to include.
- `org.mozilla.thunderbird_esr` — No mail client, as above.
- `me.proton.Mail` — No mail client, as above.
- `org.gnome.NetworkDisplays`
- `io.github.vikdevelop.SaveDesktop`
- `dev.vencord.Vesktop`
- `com.stremio.Stremio`
- `org.angryip.ipscan`
- `io.anytype.anytype`
- `com.vixalien.sticky`
- `org.nickvision.money`
- `tv.kodi.Kodi`
- `org.pipewire.Helvum` — qpwgraph covers PipeWire routing.
- `net.audiorelay.AudioRelay`
- `com.pocoguy.Muse` — Not on Flathub.
- `org.ardour.Ardour`
- `com.bitwig.BitwigStudio` — Not on Flathub.
- `studio.kx.carla`
- `org.tildearrow.furnace`
- `org.hydrogenmusic.Hydrogen`
- `org.rncbc.qtractor`
- `org.zrythm.Zrythm`
- `com.behringer.XAirEdit`
- `io.github.Faugus.faugus-launcher`
- `net.kuribo64.melonDS`
- `com.github.k4zmu2a.spacecadetpinball`
- `io.github.IshuSinghSE.aurynk`
- `com.somaxa8.earx`

## Inherited

- Bluefin's developer-experience group, installed by `ujust install-dx-apps`
  from [projectbluefin/common](https://github.com/projectbluefin/common)'s
  `bluefin/usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile`: Builder,
  Dev Toolbox, Clapgrep, Embellish and Podman Desktop at the time of writing.
  The upstream file is the list; this one does not track it.
- The FlatPark remote and its deny filter — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
- `ujust install-ai-tools` (CLI AI agents and the Jan Flatpak) — from
  [projectbluefin/common](https://github.com/projectbluefin/common). Not to be
  confused with `install-ai-assistant`.
- The `flatpak-preinstall.service` unit — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
