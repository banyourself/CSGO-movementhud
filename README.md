# movementhud (fork)

Speed, keys and movement indicator HUD for CS:GO. My fork of **MovementHUD** by Sikarii.

This is a maintenance fork rather than a feature one. The main file actually got **smaller**,
189 lines upstream down to 105 here, because most of the change was removing dead code.

## Install

Drop the `addons` folder into your `csgo` folder:

```
addons/sourcemod/plugins/movementhud.smx          the compiled plugin
addons/sourcemod/scripting/movementhud.sp         source
addons/sourcemod/scripting/movementhud/           sub-modules, needed to compile
```

The sub-modules matter. `movementhud.sp` is just the entry point, and the actual HUD elements
live in `movementhud/elements/`, so you need the whole folder to build it.

## What changed

**3.0.7** accepts a normal Windows UTF-8 BOM in the defaults configuration, which the original
choked on.

**3.0.8** is the useful one. It stops re-sending unchanged HUD messages every tick, which is
the real performance fix: a HudMsg that has not changed does not need sending, and on a full
server that traffic competes with the entity snapshot.

It also drops some dead arguments (`sourcelen` and `is_array`) in `base64.inc` and
`json/helpers/decode.inc` that were producing compiler warning 217s. Removing the arguments is
better than suppressing them with `#pragma unused`, because an in-body pragma desyncs spcomp's
indent tracker and causes its own problems. Upstream sm-json had already dropped `is_array`
from that signature anyway.

`MHUD_VERSION` lives in `include/movementhud.inc`, so that file has to be touched when the
version changes or a timestamp-driven build skips it.

## Works alongside

My speclist fork deliberately avoids MHUD's screen space. MHUD owns the center column and the
0.72 to 0.80 vertical band (speed, indicators, keys), so speclist stops at 0.62 and skips the
center entirely.

Both use SourceMod HUD synchronizers rather than fixed channels, so they arbitrate for the six
available channels instead of overwriting each other.

## Credits

Original **MovementHUD** by **Sikarii**:
[bitbucket.org/Sikarii/movementhud](https://bitbucket.org/Sikarii/movementhud)

`myinfo` credits Sikari alongside me.

## License

GPL-3.0, see `LICENSE`.
