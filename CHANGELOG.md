# Changelog

## v1.0.4

- Hit and last-hit sounds are off (`tf_dingalingaling 0`), set after `user.cfg` so an old config cannot turn them back on.
- `budhud.bat` writes a self-contained `overrides/user.cfg`: every `exec` of a file in `tf/cfg`, such as a cfg.tf `exec binds`, is replaced by that file's lines, and `tf_dingalingaling` and `ds_enable` lines are dropped.
- Mouse 5 is `+context_action` (extra action), not `+attack3`; Mouse 3 keeps `+attack3`.
- Automatic demo recording is off (`ds_enable 0`), and `ds_enable` lines are dropped from `user.cfg`.
- Nightly builds retry when the GitHub API fails.

## v1.0.3

- `overrides/binds.cfg` runs after `overrides/user.cfg`, so an old config that rebinds the mouse wheel to `invnext` no longer undoes the wheel jump.

## v1.0.2

- Eyes are back: `characters=low` instead of the Low preset's `characters=very_low`.
- `overrides/binds.cfg` adds binds and removes none: console on F9, jump on the mouse wheel down as well as Space, action slot item on Mouse 4, special attack on Mouse 5.
- `budhud.bat` merges every autoexec it moves aside into `overrides/user.cfg` instead of keeping only the first, and keeps class configs such as `overrides/scout.cfg`.

## v1.0.1

- `budhud.bat` skips a `budhud.zip` next to it that is not a tf2-config zip, such as the official budhud one, and downloads the right one instead of stopping.

## v1.0.0

- budhud `a1b348d` (Scream Fortress XVIII HUD files) and mastercomfig 9.100.1 on the Low preset.
- No frame rate cap, shadows off, cheapest water, no sheens or killstreak effects.
- `budhud.bat` finds TF2, backs up the old HUD and config, and keeps your settings in `overrides/user.cfg`.
