# steamos-cec-assist

Keeps your **TV remote** working on SteamOS over **HDMI-CEC**, and lets you remap its buttons
(for example, make the remote control media playback in Waydroid/Android apps).

SteamOS ships Valve's CEC daemon, `cecd`, which turns TV-remote button presses into a virtual
keyboard. That works until the TV stops sending the presses to your Steam Machine, which
happens a lot:

| Symptom | Cause | Fixed by |
|---|---|---|
| Remote dead after switching TV inputs away and back | Your Steam Machine is behind an **HDMI switch / AV receiver** that doesn't pass CEC routing messages along. The TV announces "HDMI 2 is active" (`2.0.0.0`) but the device is at `2.2.0.0`, so nobody answers, and the TV keeps the remote for itself. | `cec-assist daemon` answers for any route on the path to your device |
| Remote dead after the TV turns on | Same as above, made worse by a cable box grabbing the TV on wake | `cec-assist daemon` (waits for the TV's routing burst to finish, never fights other devices) |
| Remote dead after using a **built-in TV app** (Netflix etc.) and coming back | Some TVs (seen on Samsung) switch from a built-in app back to HDMI **without any CEC message**, so the device can't know | Optional **controller trigger**: pressing a Steam Controller button claims the remote back |
| Media keys don't work, or Play/Pause acts as Enter | Some TVs send CEC "Select" for both OK and Play/Pause, and `cecd` maps Select to Enter | `cec-assist remap` |

Requires no root and doesn't touch the read-only system partition: everything is installed
in your home directory, so it survives SteamOS updates.

## Install

```sh
git clone https://github.com/geekexile/steamos-cec-assist.git
cd steamos-cec-assist
./install.sh
```

This installs `~/.local/bin/cec-assist` and a systemd **user** service, `cec-assist`, which starts
with your session (Gaming Mode or Desktop Mode).

Uninstall with `./uninstall.sh` (add `--purge` to also remove button remaps and config).

## Commands

```sh
cec-assist status          # cecd state, physical address, remaps, service state
cec-assist claim           # get the remote back right now (restarts cecd if needed)
cec-assist monitor         # watch CEC routing + remote button presses live
cec-assist monitor -a      # ...every CEC message
cec-assist remap ...       # see below
```

`claim` is handy as a non-Steam shortcut: in Desktop Mode, add `~/.local/bin/cec-assist` to Steam
with launch option `claim`, and it's one press away in Gaming Mode.

## Remapping remote buttons

```sh
cec-assist remap --list-buttons          # CEC button names and their default keys
cec-assist remap --list-keys             # key names you can map to
cec-assist remap select=KEY_PLAYPAUSE left=KEY_PREVIOUSSONG right=KEY_NEXTSONG
cec-assist remap                         # show current overrides
cec-assist remap select=KEY_ENTER        # map back to the default = drop that override
cec-assist remap --reset                 # back to cecd's defaults
```

Watch out: in `cecd` a `[mappings]` table **replaces** the whole default table instead of
adding to it. So if you write a mapping file by hand with only the buttons you want to change,
every other button stops working. `remap` always writes the full default table plus your
overrides, to `~/.config/cecd/config.d/50-cec-assist-mappings.toml`. If `cecd` rejects the new file,
it is rolled back automatically.

To find out which CEC code a remote button sends, run `cec-assist monitor` and press it. If two
physical buttons show the same code (common: OK and Play/Pause both send `select`), the TV is
merging them, and remapping one remaps both.

## Configuration

Optional: copy `config.example.ini` to `~/.config/cec-assist/config.ini`, then
`systemctl --user restart cec-assist`.

| Setting | Default | Meaning |
|---|---|---|
| `settle_seconds` | `1.0` | Quiet time after the TV's last routing message before claiming |
| `controller_trigger` | `true` | Claim the remote when a Steam Controller button / D-pad is pressed |
| `controller_cooldown_seconds` | `30` | At most one controller-triggered claim per this many seconds |
| `controller_names` | `Steam Controller, X-Box 360 pad, Steam Deck` | Input devices that count as the controller |
| `log_routing` | `true` | Log CEC routing messages to the journal |

**Controller trigger side effect:** pressing a controller button while the TV shows another
source switches the TV to the Steam Machine, the same way game consoles behave. Stick and
trackpad movement doesn't count. Turn it off with `controller_trigger = false` if you don't
want that.

## How it works

* `cecd` exposes CEC on the session D-Bus (`com.steampowered.CecDaemon1`). `cec-assist`
  listens to its `ReceivedMessage` signal and calls `SetActiveSource`.
* When the TV broadcasts `<Routing Change>` / `<Set Stream Path>` to your device's physical
  address *or any parent of it*, `cec-assist` waits until the TV's burst of messages ends, then
  sends `<Active Source>`. It never reacts to routes to other inputs. If another device becomes
  active source during the wait, it backs off.
* The controller trigger reads the controller's evdev devices **read-only** (never grabbed), so
  Steam and games still get all input.

## Troubleshooting

```sh
cec-assist status
journalctl --user -u cec-assist --since "-1h"     # what the TV and other devices said
journalctl --user -u cecd --since "-1h"
```

If the remote stops working, look in the log for the last `Active Source` / `Routing Change`
before it broke. That tells you which device took over. Please include that log when you open
an issue.

## Compatibility

Tested on a Steam Machine (SteamOS, `cecd` 0.3.0) with a Samsung QN77S90F (Anynet+), behind an
HDMI switch, alongside an Xfinity X1 box and a Samsung soundbar. It should work on any SteamOS
device that runs `cecd` with CEC hardware. Reports from other TVs are welcome.

## License

MIT
