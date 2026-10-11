# tf2-config

[budhud](https://github.com/rbjaxter/budhud) and [mastercomfig](https://github.com/mastercomfig/mastercomfig) on the Low preset, tuned for frame rate, with an installer for Windows.

## Install

Download [`budhud.bat`](https://github.com/m-this/tf2-config/releases/latest/download/budhud.bat) and run it. It:

- finds TF2 through the Steam registry keys and every Steam library in `libraryfolders.vdf`, or takes the path as its first argument;
- waits for TF2 to close;
- moves every HUD in `tf/custom`, the old mastercomfig VPKs and `tf/cfg/overrides` to `Team Fortress 2/tf2-config-backup/<date>`;
- installs budhud, mastercomfig and the overrides;
- keeps your own settings in `tf/cfg/overrides/user.cfg`, taken from the previous `user.cfg`, the previous mastercomfig `overrides/autoexec.cfg`, or `tf/cfg/autoexec.cfg`, in that order.

If a tf2-config `budhud.zip` sits next to `budhud.bat`, the installer uses it instead of downloading. Any other `budhud.zip`, like the official budhud one, is skipped.

Launch options: `-novid -nojoy -nosteamcontroller -nohltv -particles 1 -precachefontchars`.

## What the config changes

mastercomfig runs the `low` preset (`cfg/overrides/setup_hook.cfg`), then these modules (`cfg/overrides/modules.cfg`):

| Module | Why |
| --- | --- |
| `fpscap=unlimited` | mastercomfig caps at 400 by default. |
| `shadows=off`, `water=very_low` | The two costliest things Low still draws. |
| `sheens_speed=off`, `killstreaks=off` | Effects with no gameplay value. |

Addons: `flat-mouse`, `no-pyroland`, `no-soundscapes`, `no-tutorial`.

`cfg/overrides/autoexec.cfg` runs `user.cfg`, then sets `fps_max 0` and `cl_showfps 1`, so a cap in an old autoexec does not survive the install.

Wallbugs are gone from Valve servers since the Scream Fortress XVIII update. A community server brings them back with `sv_wallbug 1`.

## Releases

A `v*` tag builds budhud and mastercomfig at the pins in `versions.env`, checks the VPKs against `mastercomfig.sha256`, and publishes `budhud.zip`, `budhud.bat` and `SHA256SUMS`. The section for that tag in `CHANGELOG.md` becomes the notes.

[`nightly`](https://github.com/m-this/tf2-config/releases/tag/nightly) is rebuilt every day and on every push to `main`, from budhud master and the latest mastercomfig release.

## Build

```sh
make dist                       # pinned versions, into dist/
make dist BUILD_CHANNEL=nightly # budhud master, latest mastercomfig
make serve                      # builds, copies dist/ to serve/, serves it on http://192.168.50.133/
```
